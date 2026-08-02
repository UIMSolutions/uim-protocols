# Library uim-as2

Updated on 02. August 2026

uim-as2 is a lightweight D library to work with Applicability Statement 2 (AS2) message exchange flows using vibe.d runtime patterns. It provides typed AS2 contracts, validation, MIME payload codec helpers, MDN generation, and asynchronous send orchestration.

## Features

- Typed AS2 contracts (`IAS2Service`)
- Config model for partner IDs, security defaults, transfer encoding, and MDN behavior
- Message validation for sender, receiver, payload, and strict mode checks
- Deterministic MIME payload encode/decode helpers for adapters and tests
- MDN generation helper for processed/failed dispositions
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in real HTTP/SMIME AS2 connectors

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-framework:as2" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.as2;

void main() {
  auto service = AS2Service();

  AS2Config config;
  config.localAs2Id = "MY-AS2";
  config.remoteAs2Id = "PARTNER-AS2";
  config.endpointUrl = "https://partner.example.com/as2";
  config.requestMdn = true;
  config.strictMode = true;

  assert(service.configure(config));

  auto message = AS2MessageOf("ISA*00*", "MY-AS2", "PARTNER-AS2", "PO-100");
  message.headers ~= AS2HeaderOf("Disposition-Notification-To", "mailto:edi@example.com");

  auto result = service.sendMessage(message);
  writeln("sent=", result.success, " status=", result.statusCode);

  auto payload = service.encodeMimePayload(message);
  auto decoded = service.decodeMimePayload(payload);
  writeln("decoded from=", decoded.fromAs2Id, " to=", decoded.toAs2Id);
}
```

## Modules

- `uim.as2`: package entrypoint and re-exports
- `uim.as2.interfaces`: contracts, config, DTOs, delegates
- `uim.as2.models`: helper constructors and result factories
- `uim.as2.helpers`: AS2 id normalization, validation, MIC, MIME codec, MDN builder
- `uim.as2.service`: orchestration for validate/send/encode/decode/MDN and async APIs

## Notes

- The default send path is in-memory orchestration; it does not perform real HTTP transport.
- Use `setSendProvider` to inject an adapter with actual AS2 over HTTP + SMIME handling.
- AS2 IDs are normalized to uppercase without spaces.
