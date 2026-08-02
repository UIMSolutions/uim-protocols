# Library uim-amqp

Updated on 02. August 2026

uim-amqp is a lightweight D library to work with AMQP (Advanced Message Queuing Protocol) messaging flows using vibe.d runtime patterns. It provides typed message contracts, routing/binding helpers, frame encode/decode utilities, validation, and asynchronous publish orchestration.

## Features

- Typed AMQP contracts (`IAMQPService`)
- Config model for broker endpoint, exchange/queue defaults, and strict validation mode
- Message validation for exchange, queue, routing key, and payload rules
- Deterministic frame encode/decode helpers for integration testing and adapters
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in real AMQP clients (RabbitMQ, Qpid, etc.)

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-framework:amqp" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.amqp;

void main() {
  auto service = AMQPService();

  AMQPConfig config;
  config.host = "localhost";
  config.port = 5672;
  config.virtualHost = "/";
  config.exchangeName = "orders";
  config.queueName = "orders.service";
  config.routingKey = "orders.created";
  config.strictMode = true;

  assert(service.configure(config));

  auto message = AMQPMessageOf(
    "{\"orderId\":\"A-100\"}",
    "orders",
    "orders.created",
    "orders.service"
  );
  message.headers ~= AMQPHeaderOf("content-type", "application/json");

  auto result = service.publish(message);
  writeln("published=", result.success, " status=", result.statusCode);

  auto frame = service.encodeFrame(message);
  auto decoded = service.decodeFrame(frame);
  writeln("decoded body=", decoded.body);
}
```

## Modules

- `uim.amqp`: package entrypoint and re-exports
- `uim.amqp.interfaces`: service contracts, config, message, and result DTOs
- `uim.amqp.models`: helper constructors and result factories
- `uim.amqp.helpers`: routing, binding, validation, and frame codec helpers
- `uim.amqp.service`: orchestration for validation, publish, encode/decode, and async APIs

## Notes

- The default publish path is in-memory orchestration; it does not open a broker socket by itself.
- Use `setPublishProvider` to inject a concrete AMQP adapter implementation.
- Routing keys are normalized to lowercase dotted tokens by default.
