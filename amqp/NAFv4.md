# NAF v4 Architecture - UIM-AMQP

This document maps uim-amqp capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM AMQP Library |
| Version | 26.x |
| Date | 02 August 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | AMQP message validation, frame codec, and publish orchestration |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| AMQP Service | Service orchestrating validate, encode/decode, and publish workflows |
| Binding | Mapping between exchange, queue, and routing key |
| Routing Key | Dot-separated key used by direct/topic exchange routing |
| Delivery Mode | Message persistence level (transient or persistent) |
| Async Operation | Non-blocking callback execution via runTask |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
AMQP Integration Capability
|- Broker Configuration
|  |- host, port, vhost, credentials
|  |- default exchange, queue, and routing key
|- Message Lifecycle
|  |- validate publish payloads
|  |- normalize routing keys
|  |- publish orchestration
|- Codec Operations
|  |- encode structured message into frame
|  |- decode frame back into typed message
|- Async Processing
   |- async publish callback
   |- async encode callback
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| Routing and binding conversion | codec helper functions |
| Default publish workflow | in-memory validation + frame encoding |
| Broker transport integration | injected publish provider delegate |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures broker and default routing behavior.
2. Service normalizes message routing keys and validates the payload.
3. Service encodes message metadata and body into a deterministic frame.
4. Service returns a queued publish result or adapter-specific provider result.
5. Async APIs expose non-blocking publish and encode paths.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | AMQPConfig | ready state |
| 2 | Validate message | AMQPMessage | AMQPPublishResult |
| 3 | Encode frame | AMQPMessage | encoded frame string |
| 4 | Decode frame | AMQP frame | AMQPMessage |
| 5 | Publish message | AMQPMessage | queued / error result |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - producers / consumers   |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.amqp                  |
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
| uim.amqp.interfaces.client | AMQP contracts and value types |
| uim.amqp.models.client | helper factories and result constructors |
| uim.amqp.helpers.codec | routing normalization, binding/validation, frame codec |
| uim.amqp.service | configure, validate, publish, and async orchestration |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| AMQP | 0-9-1 / 1.0 conceptual model | queueing semantics and metadata model |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed AMQP API model | Implemented | configure, publish, encode/decode, validation contracts |
| Routing and binding helpers | Implemented | normalization and binding construction |
| Async operation API | Implemented | callback-based publish and encode |
| In-memory provider defaults | Implemented | integration without broker client dependency |
| Broker protocol adapter package | Planned | RabbitMQ/Qpid provider implementation |

## L - Logical Model

### L-1 Logical Data Model

```text
AMQPConfig
  |- host: string
  |- port: ushort
  |- virtualHost: string
  |- exchangeName: string
  |- queueName: string
  |- routingKey: string
  |- strictMode: bool

AMQPHeader
  |- key: string
  |- value: string

AMQPBinding
  |- exchange: string
  |- queue: string
  |- routingKey: string

AMQPMessage
  |- exchange: string
  |- routingKey: string
  |- queue: string
  |- body: string
  |- messageId: string
  |- correlationId: string
  |- timestampUnix: ulong
  |- headers: AMQPHeader[]

AMQPPublishResult
  |- success: bool
  |- statusCode: ushort
  |- message: string
  |- exchange: string
  |- routingKey: string
  |- queue: string
  |- messageId: string
```

### L-2 Constraints

- Strict mode requires body content and a route target (exchange or queue).
- Routing keys are normalized before validation and encoding.
- Delivery mode defaults to persistent when unspecified.
- Async callback invocation is exception-isolated.
