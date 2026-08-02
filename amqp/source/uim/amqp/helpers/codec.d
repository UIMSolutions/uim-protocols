/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.amqp.helpers.codec;

import std.array : appender;
import std.conv : to;
import std.string : indexOf, split, strip;

import uim.amqp.interfaces;
import uim.amqp.models;

@safe:

string amqpNormalizeRoutingKey(string value) {
  auto trimmed = value.strip();
  if (trimmed.length == 0) {
    return "";
  }

  auto parts = split(trimmed, ".");
  auto buffer = appender!string();

  bool first = true;
  foreach (part; parts) {
    auto token = part.strip();
    if (token.length == 0) {
      continue;
    }

    if (!first) {
      buffer.put('.');
    }

    foreach (ch; token) {
      if (ch >= 'A' && ch <= 'Z') {
        buffer.put(cast(char) (ch + 32));
      } else if (ch == ' ') {
        buffer.put('_');
      } else {
        buffer.put(ch);
      }
    }

    first = false;
  }

  return buffer.data;
}

AMQPBinding amqpBuildBinding(AMQPConfig config) {
  AMQPBinding binding;
  binding.exchange = config.exchangeName;
  binding.queue = config.queueName;
  binding.routingKey = amqpNormalizeRoutingKey(config.routingKey);
  binding.durable = config.durableQueue;
  binding.autoDelete = config.autoDeleteQueue;
  return binding;
}

AMQPPublishResult amqpValidateMessage(AMQPConfig config, AMQPMessage message) {
  auto exchange = message.exchange.length > 0 ? message.exchange : config.exchangeName;
  auto queue = message.queue.length > 0 ? message.queue : config.queueName;
  auto routingKey = amqpNormalizeRoutingKey(
    message.routingKey.length > 0 ? message.routingKey : config.routingKey
  );

  if (message.body.length == 0) {
    return AMQPPublishResultErr(422, "AMQP payload body is empty.", exchange, routingKey, queue, message.messageId);
  }

  if (config.strictMode && exchange.length == 0 && queue.length == 0) {
    return AMQPPublishResultErr(
      422,
      "AMQP requires either exchange or queue in strict mode.",
      exchange,
      routingKey,
      queue,
      message.messageId
    );
  }

  if (config.strictMode && exchange.length > 0 && routingKey.length == 0 && queue.length == 0) {
    return AMQPPublishResultErr(
      422,
      "AMQP publish to exchange requires routing key or queue in strict mode.",
      exchange,
      routingKey,
      queue,
      message.messageId
    );
  }

  return AMQPPublishResultOk(200, "validated", exchange, routingKey, queue, message.messageId);
}

string amqpEncodeFrame(AMQPMessage message) {
  auto buffer = appender!string();
  buffer.put("AMQP/1.0\n");

  buffer.put("exchange=");
  buffer.put(message.exchange);
  buffer.put("\n");

  buffer.put("routing_key=");
  buffer.put(amqpNormalizeRoutingKey(message.routingKey));
  buffer.put("\n");

  buffer.put("queue=");
  buffer.put(message.queue);
  buffer.put("\n");

  buffer.put("message_id=");
  buffer.put(message.messageId);
  buffer.put("\n");

  buffer.put("correlation_id=");
  buffer.put(message.correlationId);
  buffer.put("\n");

  buffer.put("timestamp=");
  buffer.put(message.timestampUnix.to!string);
  buffer.put("\n");

  buffer.put("delivery_mode=");
  buffer.put(cast(ubyte) message.deliveryMode == 2 ? "2" : "1");
  buffer.put("\n");

  foreach (header; message.headers) {
    buffer.put("header:");
    buffer.put(header.key);
    buffer.put("=");
    buffer.put(header.value);
    buffer.put("\n");
  }

  buffer.put("\n");
  buffer.put(message.body);
  return buffer.data;
}

AMQPMessage amqpDecodeFrame(string frame) {
  auto chunks = split(frame, "\n\n");
  if (chunks.length == 0) {
    return AMQPMessageEmpty();
  }

  auto meta = chunks[0];
  auto lines = split(meta, "\n");

  AMQPMessage message;

  if (chunks.length > 1) {
    message.body = chunks[1];
  }

  foreach (line; lines) {
    auto trimmed = line.strip();
    if (trimmed.length == 0 || trimmed == "AMQP/1.0") {
      continue;
    }

    if (trimmed.indexOf("header:") == 0) {
      auto raw = trimmed[7 .. $];
      auto sep = raw.indexOf("=");
      if (sep > 0) {
        AMQPHeader header;
        header.key = raw[0 .. sep].strip();
        header.value = raw[sep + 1 .. $].strip();
        if (header.key.length > 0) {
          message.headers ~= header;
        }
      }
      continue;
    }

    auto separator = trimmed.indexOf("=");
    if (separator <= 0) {
      continue;
    }

    auto key = trimmed[0 .. separator].strip();
    auto value = trimmed[separator + 1 .. $].strip();

    switch (key) {
      case "exchange":
        message.exchange = value;
        break;
      case "routing_key":
        message.routingKey = value;
        break;
      case "queue":
        message.queue = value;
        break;
      case "message_id":
        message.messageId = value;
        break;
      case "correlation_id":
        message.correlationId = value;
        break;
      case "timestamp":
        if (value.length > 0) {
          message.timestampUnix = value.to!ulong;
        }
        break;
      case "delivery_mode":
        message.deliveryMode = value == "2"
          ? AMQPDeliveryMode.persistent
          : AMQPDeliveryMode.transient_;
        break;
      default:
        break;
    }
  }

  return message;
}

unittest {
  AMQPMessage message;
  message.exchange = "orders";
  message.routingKey = "orders.Created";
  message.body = "{\"id\":\"A-100\"}";
  message.timestampUnix = 100;
  message.deliveryMode = AMQPDeliveryMode.persistent;
  message.headers ~= AMQPHeaderOf("content-type", "application/json");

  auto frame = amqpEncodeFrame(message);
  assert(frame.indexOf("AMQP/1.0") == 0);

  auto decoded = amqpDecodeFrame(frame);
  assert(decoded.exchange == "orders");
  assert(decoded.routingKey == "orders.created");
  assert(decoded.body.length > 0);

  AMQPConfig config;
  config.exchangeName = "orders";
  config.routingKey = "orders.created";
  auto result = amqpValidateMessage(config, decoded);
  assert(result.success);
}
