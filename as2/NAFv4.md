# NAF v4 Architecture - UIM-AS2

This document maps uim-as2 capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM AS2 Library |
| Version | 26.x |
| Date | 02 August 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | AS2 validation, MIME encoding/decoding, and MDN orchestration |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| AS2 Service | Service orchestrating validate/send/codec/MDN workflows |
| AS2 ID | Trading partner identifier in AS2 headers |
| MIC | Message Integrity Check value reported in MDN |
| MDN | Message Disposition Notification receipt |
| Async Operation | Non-blocking callback execution via runTask |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
AS2 Integration Capability
|- Partner Configuration
|  |- local/remote AS2 IDs
|  |- endpoint and security defaults
|- Message Lifecycle
|  |- payload and partner validation
|  |- outbound message orchestration
|- MIME and MIC Processing
|  |- encode/decode deterministic MIME payload
|  |- calculate MIC for MDN reporting
|- MDN Handling
|  |- processed disposition
|  |- failed disposition
|- Async Processing
   |- async send callback
   |- async encode callback
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| MIME and MDN conversion | codec helper functions |
| Default send workflow | in-memory validate + encode + MDN behavior |
| Real AS2 transport | injected provider delegates |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures partner AS2 identities and runtime behavior.
2. Service normalizes AS2 IDs and validates payload and partner fields.
3. Service encodes MIME payload and computes MIC metadata.
4. Service builds MDN result when requested.
5. Async APIs expose non-blocking send and encode paths.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | AS2Config | ready state |
| 2 | Validate message | AS2Message | AS2Result |
| 3 | Encode payload | AS2Message | MIME payload string |
| 4 | Decode payload | MIME payload | AS2Message |
| 5 | Build MDN | AS2Message + acceptance | AS2Result |
| 6 | Send message | AS2Message | sent / error result |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - EDI/ERP integration     |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.as2                   |
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
| uim.as2.interfaces.client | AS2 contracts and data types |
| uim.as2.models.client | helper constructors and result builders |
| uim.as2.helpers.codec | AS2 id normalization, validation, MIME codec, MDN helper |
| uim.as2.service | configure, validate, send, encode/decode, MDN orchestration |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| AS2 (RFC 4130 profile) | conceptual implementation | B2B EDI over HTTP message exchange |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed AS2 API model | Implemented | configure, send, validate, codec, MDN contracts |
| MIME codec helper | Implemented | deterministic encode/decode support |
| MDN generation helper | Implemented | processed/failed disposition reporting |
| Async operation API | Implemented | callback-based send and encode |
| HTTP + SMIME adapter package | Planned | real-world AS2 transport and cryptography integration |

## L - Logical Model

### L-1 Logical Data Model

```text
AS2Config
  |- localAs2Id: string
  |- remoteAs2Id: string
  |- endpointUrl: string
  |- signMessages: bool
  |- encryptMessages: bool
  |- requestMdn: bool

AS2Header
  |- key: string
  |- value: string

AS2Message
  |- messageId: string
  |- fromAs2Id: string
  |- toAs2Id: string
  |- contentType: string
  |- payload: string
  |- signed: bool
  |- encrypted: bool
  |- compressed: bool
  |- mic: string

AS2Disposition
  |- mode: string
  |- type: string
  |- modifier: string
  |- description: string

AS2Result
  |- success: bool
  |- statusCode: ushort
  |- message: string
  |- messageId: string
  |- mic: string
  |- disposition: AS2Disposition
```

### L-2 Constraints

- Strict mode requires sender id, receiver id, and payload.
- AS2 IDs are normalized to uppercase without spaces.
- MDN requests require message IDs for traceability.
- Async callback invocation is exception-isolated.
