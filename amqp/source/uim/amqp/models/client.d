/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.amqp.models.client;

import std.datetime : Clock, UTC;

import uim.amqp;

mixin(ShowModule!());

@safe:

AMQPHeader AMQPHeaderOf(string key, string value) {
  AMQPHeader header;
  header.key = key;
  header.value = value;
  return header;
}

AMQPMessage AMQPMessageOf(string body, string exchange = "", string routingKey = "", string queue = "") {
  AMQPMessage message;
  message.body = body;
  message.exchange = exchange;
  message.routingKey = routingKey;
  message.queue = queue;
  message.timestampUnix = cast(ulong) Clock.currTime(UTC()).toUnixTime();
  return message;
}

string AMQPHeaderValue(const(AMQPMessage) message, string key, string fallback = "") {
  foreach (header; message.headers) {
    if (header.key == key) {
      return header.value;
    }
  }

  return fallback;
}

AMQPPublishResult AMQPPublishResultOk(
  ushort statusCode = 200,
  string message = "ok",
  string exchange = "",
  string routingKey = "",
  string queue = "",
  string messageId = ""
) {
  AMQPPublishResult result;
  result.success = true;
  result.statusCode = statusCode;
  result.message = message;
  result.exchange = exchange;
  result.routingKey = routingKey;
  result.queue = queue;
  result.messageId = messageId;
  return result;
}

AMQPPublishResult AMQPPublishResultErr(
  ushort statusCode = 500,
  string message = "error",
  string exchange = "",
  string routingKey = "",
  string queue = "",
  string messageId = ""
) {
  AMQPPublishResult result;
  result.success = false;
  result.statusCode = statusCode;
  result.message = message;
  result.exchange = exchange;
  result.routingKey = routingKey;
  result.queue = queue;
  result.messageId = messageId;
  return result;
}

AMQPMessage AMQPMessageEmpty() {
  AMQPMessage message;
  return message;
}

unittest {
  auto message = AMQPMessageOf("hello", "orders", "orders.created");
  assert(message.timestampUnix > 0);

  message.headers ~= AMQPHeaderOf("content-type", "application/json");
  assert(AMQPHeaderValue(message, "content-type") == "application/json");

  auto ok = AMQPPublishResultOk(202, "queued", "orders", "orders.created", "", "m-1");
  assert(ok.success);
}
