# NAF v4 Architecture - UIM-XI

This document maps uim-xi capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM XI Library |
| Version | 26.x |
| Date | 02 August 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | SAP XI validation, SOAP encoding/decoding, and acknowledgement orchestration |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| XI Service | Service orchestrating validate/send/codec/ack workflows |
| XI Message | Structured integration message including routing/interface metadata |
| SOAP Envelope | XML wrapper carrying XI header and payload body |
| QoS | Delivery behavior (`BE`, `EO`, `EOIO`) |
| ACK/NACK | Positive or negative technical acknowledgement |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
XI Integration Capability
|- Service Configuration
|  |- sender and receiver service registration
|  |- interface and namespace routing metadata
|- Message Lifecycle
|  |- payload and endpoint metadata validation
|  |- outbound message orchestration
|- SOAP Processing
|  |- encode XI SOAP envelope
|  |- decode XI SOAP envelope
|- Acknowledgement Handling
|  |- ACK generation
|  |- NACK generation
|- Async Processing
   |- async send callback
   |- async encode callback
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| SOAP and acknowledgement conversion | codec helper functions |
| Default send workflow | in-memory validate + encode + ack behavior |
| Real XI transport integration | injected provider delegates |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures sender/receiver services and XI interface metadata.
2. Service normalizes identifiers and validates XI message content.
3. Service encodes a SOAP envelope with XI protocol headers.
4. Service builds technical acknowledgement response metadata.
5. Async APIs expose non-blocking send and encoding paths.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | XIConfig | ready state |
| 2 | Validate message | XIMessage | XIResult |
| 3 | Encode envelope | XIMessage | SOAP envelope string |
| 4 | Decode envelope | SOAP envelope | XIMessage |
| 5 | Build acknowledgement | XIMessage + acceptance | XIResult |
| 6 | Send message | XIMessage | queued / error result |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - ERP and middleware      |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.xi                    |
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
| uim.xi.interfaces.message | XI contracts and message DTOs |
| uim.xi.models.message | helper constructors and result builders |
| uim.xi.helpers.codec | identifier normalization, validation, SOAP codec, ack helper |
| uim.xi.service | configure, validate, send, encode/decode, acknowledgement |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| SAP XI protocol model | conceptual implementation | enterprise integration metadata and routing |
| SOAP 1.1 envelope style | conceptual implementation | payload and header transport model |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed XI API model | Implemented | configure, send, validate, codec, acknowledgement contracts |
| SOAP envelope helper | Implemented | deterministic encode/decode support |
| ACK/NACK helper | Implemented | protocol status reporting |
| Async operation API | Implemented | callback-based send and encode |
| SAP Cloud Integration adapter package | Planned | real endpoint connectivity and security profile integration |

## L - Logical Model

### L-1 Logical Data Model

```text
XIConfig
  |- senderService: string
  |- receiverService: string
  |- interfaceName: string
  |- interfaceNamespace: string
  |- qos: XIQualityOfService
  |- strictMode: bool

XIAddress
  |- party: string
  |- service: string

XIHeader
  |- key: string
  |- value: string

XIMessage
  |- messageId: string
  |- conversationId: string
  |- sender: XIAddress
  |- receiver: XIAddress
  |- action: string
  |- payload: string
  |- headers: XIHeader[]

XIAck
  |- accepted: bool
  |- code: string
  |- description: string

XIResult
  |- success: bool
  |- statusCode: ushort
  |- message: string
  |- messageId: string
  |- acknowledgement: XIAck
```

### L-2 Constraints

- Strict mode requires sender service, receiver service, interface name, and payload.
- Identifiers are normalized to uppercase without spaces.
- SOAP envelope codec assumes XI header tags in a deterministic structure.
- Async callback invocation is exception-isolated.
