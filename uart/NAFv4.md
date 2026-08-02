# NAF v4 Architecture - UIM-UART

This document maps uim-uart capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM UART Library |
| Version | 26.x |
| Date | 02 August 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | UART frame validation, codec, and async transmit orchestration |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| UART Service | Service orchestrating validate, transmit, receive, and encode/decode workflows |
| UART Frame | Byte-oriented payload with serial port metadata |
| Line Ending | Optional terminator appended for line-based serial protocols |
| Async Operation | Non-blocking callback execution via runTask |
| Provider Delegate | Injectable adapter binding the service to a concrete serial implementation |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
UART Integration Capability
|- Serial Configuration
|  |- port name, baud rate, data bits
|  |- parity, stop bits, flow control
|- Frame Lifecycle
|  |- normalize outbound frames
|  |- validate payload and serial settings
|  |- transmit orchestration
|- Codec Operations
|  |- encode structured frame into deterministic text form
|  |- decode encoded frame back into typed data
|- Async Processing
   |- async transmit callback
   |- async receive callback
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| Frame normalization and validation | codec helper functions |
| Default transmit workflow | in-memory validation and byte counting |
| Concrete serial I/O | injected provider delegates |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures serial link properties for the target UART endpoint.
2. Service normalizes the outbound frame with default port metadata and line ending rules.
3. Service validates the serial configuration and UART payload.
4. Service returns an in-memory transmit result or adapter-specific provider result.
5. Async APIs expose non-blocking transmit and receive paths.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | UARTConfig | ready state |
| 2 | Validate frame | UARTFrame | UARTResult |
| 3 | Encode frame | UARTFrame | encoded frame string |
| 4 | Decode frame | encoded UART frame | UARTFrame |
| 5 | Transmit frame | UARTFrame | transmitted / error result |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - tty clients / adapters  |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.uart                  |
| - interfaces              |
| - models                  |
| - codec helpers           |
| - service orchestration   |
+-------------+-------------+
              |
              v
+---------------------------+
| vibe.d runtime            |
| - runTask callback engine |
+---------------------------+
```

### SV-4 Function Mapping

| Module | Function |
| --- | --- |
| uim.uart.interfaces.client | UART contracts and value types |
| uim.uart.models.client | helper factories and result constructors |
| uim.uart.helpers.codec | normalization, validation, and text codec |
| uim.uart.service | configure, transmit, receive, and async orchestration |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| UART | hardware interface model | byte-serial transport semantics |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed UART API model | Implemented | configure, validate, encode/decode, transmit, receive contracts |
| Frame normalization helpers | Implemented | port defaults, line ending policy, byte codec |
| Async operation API | Implemented | callback-based transmit and receive |
| In-memory provider defaults | Implemented | integration without hardware dependency |
| Serial port adapter package | Planned | POSIX tty and device-backed transport implementation |

## L - Logical Model

### L-1 Logical Data Model

```text
UARTConfig
  |- portName: string
  |- baudRate: uint
  |- dataBits: ubyte
  |- parity: UARTParity
  |- stopBits: UARTStopBits
  |- lineEnding: string

UARTFrame
  |- portName: string
  |- payload: ubyte[]
  |- timestampUnix: ulong
  |- terminated: bool
  |- correlationId: string

UARTResult
  |- success: bool
  |- statusCode: ushort
  |- message: string
  |- portName: string
  |- bytesTransferred: size_t
  |- correlationId: string
```

### L-2 Constraints

- Strict mode requires a non-empty port name and a non-empty payload for transmit.
- Data bits must remain within the supported 5 to 8 range.
- When `terminated` is enabled, the configured line ending is appended once during normalization.
- Async callback invocation is exception-isolated.