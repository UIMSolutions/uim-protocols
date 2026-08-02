# Library uim-uart

Updated on 02. August 2026

uim-uart is a lightweight D library to work with UART (Universal Asynchronous Receiver-Transmitter) messaging flows using vibe.d runtime patterns. It provides typed serial configuration models, UART frame validation, deterministic frame encode/decode helpers, and asynchronous transmit/receive orchestration.

## Features

- Typed UART contracts (`IUARTService`)
- Config model for serial port, baud rate, parity, stop bits, and flow control
- Validation for serial settings and UART payload frames
- Deterministic frame encode/decode helpers for tests and adapter boundaries
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in real serial drivers

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-protocols:uart" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.uart;

void main() {
  auto service = UARTService();

  UARTConfig config;
  config.portName = "/dev/ttyUSB0";
  config.baudRate = 115200;
  config.dataBits = 8;
  config.parity = UARTParity.none;
  config.stopBits = UARTStopBits.one;
  config.lineEnding = "\r\n";

  assert(service.configure(config));

  auto frame = UARTFrameOf("AT+GMR", config.portName);
  frame.terminated = true;
  frame.correlationId = "probe-1";

  auto result = service.transmit(frame);
  writeln("transmitted=", result.success, " bytes=", result.bytesTransferred);

  auto encoded = service.encodeFrame(frame);
  auto decoded = service.decodeFrame(encoded);
  writeln("decoded payload=", UARTPayloadText(decoded));
}
```

## Modules

- `uim.uart`: package entrypoint and re-exports
- `uim.uart.interfaces`: service contracts, enums, config, frame, and result DTOs
- `uim.uart.models`: helper constructors and result factories
- `uim.uart.helpers`: frame normalization, validation, and codec helpers
- `uim.uart.service`: orchestration for validation, transmit, receive, encode/decode, and async APIs

## Notes

- The default service path is in-memory orchestration; it does not open a serial device by itself.
- Use `setTransmitProvider` and `setReceiveProvider` to inject a concrete UART or tty adapter implementation.
- When `terminated` is set on a frame, the configured line ending is appended during normalization if it is not already present.