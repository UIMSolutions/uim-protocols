# Library uim-xi

Updated on 02. August 2026

uim-xi is a lightweight D library to work with SAP XI message protocol integration patterns using vibe.d runtime conventions. It provides typed XI contracts, message validation, SOAP envelope codec helpers, acknowledgement generation, and asynchronous send orchestration.

## Features

- Typed XI contracts (`IXIService`)
- Config model for sender/receiver services, interface metadata, QoS, and endpoint behavior
- Message validation for XI sender, receiver, interface, and payload in strict mode
- Deterministic SOAP envelope encode/decode helpers for adapter testing
- Acknowledgement (`ACK`/`NACK`) result helper model
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in real SAP integration connectors

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-framework:xi" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.xi;

void main() {
  auto service = XIService();

  XIConfig config;
  config.senderService = "ERP";
  config.receiverService = "CLOUD";
  config.interfaceName = "OrderSync";
  config.interfaceNamespace = "urn:example:orders";
  config.endpointUrl = "https://integration.example.com/xi";

  assert(service.configure(config));

  auto message = XIMessageOf("<Order id=\"1\"/>", "ERP", "CLOUD", "OrderSync");
  message.interfaceNamespace = "urn:example:orders";
  message.headers ~= XIHeaderOf("SAP-MessageType", "Application");

  auto result = service.sendMessage(message);
  writeln("sent=", result.success, " status=", result.statusCode);

  auto envelope = service.encodeSoapEnvelope(message);
  auto decoded = service.decodeSoapEnvelope(envelope);
  writeln("decoded sender=", decoded.sender.service, " receiver=", decoded.receiver.service);
}
```

## Modules

- `uim.xi`: package entrypoint and re-exports
- `uim.xi.interfaces`: XI contracts, config, message, and result DTOs
- `uim.xi.models`: helper constructors and result factories
- `uim.xi.helpers`: identifier normalization, validation, SOAP codec, acknowledgement helper
- `uim.xi.service`: orchestration for validate/send/encode/decode/ack and async APIs

## Notes

- The default send path is in-memory orchestration; it does not call a remote XI endpoint by itself.
- Use `setSendProvider` to inject a concrete adapter for SAP Cloud Integration/XI transport.
- Identifier normalization maps values to uppercase and removes spaces.
