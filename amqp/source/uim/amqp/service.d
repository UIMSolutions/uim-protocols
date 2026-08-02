/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.amqp.service;

import std.conv : to;
import std.datetime : Clock, UTC;

import vibe.d : runTask;

import uim.amqp;

mixin(ShowModule!());

@safe:

class UIMAMQPService : UIMObject, IAMQPService {
  private AMQPConfig _config;
  private bool _configured;

  private AMQPPublishDelegate _publishProvider;
  private AMQPEncodeDelegate _encodeProvider;
  private AMQPDecodeDelegate _decodeProvider;

  bool configure(AMQPConfig config) {
    if (config.host.length == 0 || config.port == 0) {
      _configured = false;
      return false;
    }

    _config = config;
    _configured = true;
    return true;
  }

  AMQPConfig config() const {
    return _config;
  }

  bool setPublishProvider(AMQPPublishDelegate provider) {
    _publishProvider = provider;
    return true;
  }

  bool setEncodeProvider(AMQPEncodeDelegate provider) {
    _encodeProvider = provider;
    return true;
  }

  bool setDecodeProvider(AMQPDecodeDelegate provider) {
    _decodeProvider = provider;
    return true;
  }

  AMQPPublishResult publish(AMQPMessage message) {
    if (!_configured) {
      return AMQPPublishResultErr(412, "AMQP service is not configured.");
    }

    auto normalized = normalizeMessage(message);
    auto validation = validateMessage(normalized);
    if (!validation.success) {
      return validation;
    }

    if (_publishProvider !is null) {
      try {
        return _publishProvider(_config, normalized);
      } catch (Exception ex) {
        return AMQPPublishResultErr(
          500,
          ex.msg,
          validation.exchange,
          validation.routingKey,
          validation.queue,
          validation.messageId
        );
      }
    }

    auto encoded = encodeFrame(normalized);
    if (encoded.length == 0) {
      return AMQPPublishResultErr(
        500,
        "AMQP frame encoding failed.",
        validation.exchange,
        validation.routingKey,
        validation.queue,
        validation.messageId
      );
    }

    return AMQPPublishResultOk(
      202,
      "queued",
      validation.exchange,
      validation.routingKey,
      validation.queue,
      validation.messageId
    );
  }

  AMQPPublishResult validateMessage(AMQPMessage message) {
    if (!_configured) {
      return AMQPPublishResultErr(412, "AMQP service is not configured.");
    }

    auto normalized = normalizeMessage(message);
    return amqpValidateMessage(_config, normalized);
  }

  string encodeFrame(AMQPMessage message) {
    if (!_configured) {
      return "";
    }

    auto normalized = normalizeMessage(message);

    if (_encodeProvider !is null) {
      try {
        return _encodeProvider(_config, normalized);
      } catch (Exception) {
        return "";
      }
    }

    return amqpEncodeFrame(normalized);
  }

  AMQPMessage decodeFrame(string frame) {
    if (!_configured || frame.length == 0) {
      return AMQPMessageEmpty();
    }

    if (_decodeProvider !is null) {
      try {
        return _decodeProvider(_config, frame);
      } catch (Exception) {
        return AMQPMessageEmpty();
      }
    }

    return amqpDecodeFrame(frame);
  }

  AMQPBinding bindingFromConfig() {
    if (!_configured) {
      AMQPBinding empty;
      return empty;
    }

    return amqpBuildBinding(_config);
  }

  string normalizeRoutingKey(string value) {
    return amqpNormalizeRoutingKey(value);
  }

  bool publishAsync(AMQPMessage message, AMQPPublishResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localMessage = message;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(publish(localMessage));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool encodeFrameAsync(AMQPMessage message, AMQPPublishResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localMessage = message;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          auto encoded = encodeFrame(localMessage);
          if (encoded.length > 0) {
            auto normalized = normalizeMessage(localMessage);
            localHandler(AMQPPublishResultOk(
              200,
              "encoded",
              normalized.exchange,
              normalized.routingKey,
              normalized.queue,
              normalized.messageId
            ));
          } else {
            localHandler(AMQPPublishResultErr(400, "encoding failed"));
          }
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  private AMQPMessage normalizeMessage(AMQPMessage message) {
    if (message.exchange.length == 0) {
      message.exchange = _config.exchangeName;
    }

    if (message.queue.length == 0) {
      message.queue = _config.queueName;
    }

    if (message.routingKey.length == 0) {
      message.routingKey = _config.routingKey;
    }

    message.routingKey = amqpNormalizeRoutingKey(message.routingKey);

    if (message.timestampUnix == 0) {
      message.timestampUnix = cast(ulong) Clock.currTime(UTC()).toUnixTime();
    }

    if (message.messageId.length == 0) {
      message.messageId = defaultMessageId(message);
    }

    if (message.deliveryMode == AMQPDeliveryMode.init) {
      message.deliveryMode = AMQPDeliveryMode.persistent;
    }

    return message;
  }

  private string defaultMessageId(const(AMQPMessage) message) const {
    return message.exchange ~ ":" ~ message.routingKey ~ ":" ~ message.timestampUnix.to!string;
  }
}

IAMQPService AMQPService() {
  return new UIMAMQPService();
}

unittest {
  auto service = AMQPService();

  AMQPConfig config;
  config.host = "localhost";
  config.port = 5672;
  config.exchangeName = "orders";
  config.routingKey = "orders.created";
  config.queueName = "orders.service";
  assert(service.configure(config));

  auto message = AMQPMessageOf("{\"orderId\":\"A-100\"}", "orders", "orders.created", "orders.service");
  message.headers ~= AMQPHeaderOf("content-type", "application/json");

  auto validated = service.validateMessage(message);
  assert(validated.success);

  auto frame = service.encodeFrame(message);
  assert(frame.length > 0);

  auto decoded = service.decodeFrame(frame);
  assert(decoded.body.length > 0);

  auto published = service.publish(message);
  assert(published.success);
}
