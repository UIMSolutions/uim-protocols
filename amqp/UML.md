# UIM-AMQP UML Description

## Overview

The UIM-AMQP library provides a compact architecture for AMQP messaging workflows in D. It combines typed contracts, message and binding models, routing/codec helpers, and asynchronous orchestration with vibe.d.

## Core Types

```plantuml
@startuml AMQP_Core

enum AMQPDeliveryMode {
  transient_ = 1
  persistent = 2
}

struct AMQPConfig {
  + host: string
  + port: ushort
  + virtualHost: string
  + username: string
  + password: string
  + exchangeName: string
  + queueName: string
  + routingKey: string
  + durableQueue: bool
  + autoDeleteQueue: bool
  + tlsEnabled: bool
  + strictMode: bool
  + heartbeatSeconds: ushort
}

struct AMQPHeader {
  + key: string
  + value: string
}

struct AMQPBinding {
  + exchange: string
  + queue: string
  + routingKey: string
  + durable: bool
  + autoDelete: bool
}

struct AMQPMessage {
  + exchange: string
  + routingKey: string
  + queue: string
  + body: string
  + messageId: string
  + correlationId: string
  + timestampUnix: ulong
  + deliveryMode: AMQPDeliveryMode
  + headers: AMQPHeader[]
}

struct AMQPPublishResult {
  + success: bool
  + statusCode: ushort
  + message: string
  + exchange: string
  + routingKey: string
  + queue: string
  + messageId: string
}

interface IAMQPService {
  + configure(config: AMQPConfig): bool
  + publish(message: AMQPMessage): AMQPPublishResult
  + validateMessage(message: AMQPMessage): AMQPPublishResult
  + encodeFrame(message: AMQPMessage): string
  + decodeFrame(frame: string): AMQPMessage
  + bindingFromConfig(): AMQPBinding
  + publishAsync(message: AMQPMessage, handler: AMQPPublishResultHandler): bool
}

class UIMAMQPService

UIMAMQPService ..|> IAMQPService

@enduml
```

## Helper Layer

```plantuml
@startuml AMQP_Helpers

class CodecHelpers {
  + amqpNormalizeRoutingKey(value: string): string
  + amqpBuildBinding(config: AMQPConfig): AMQPBinding
  + amqpValidateMessage(config: AMQPConfig, message: AMQPMessage): AMQPPublishResult
  + amqpEncodeFrame(message: AMQPMessage): string
  + amqpDecodeFrame(frame: string): AMQPMessage
}

UIMAMQPService --> CodecHelpers : validate, encode, decode

@enduml
```

## Sequence

```plantuml
@startuml AMQP_Sequence

actor Application
participant Service as "UIMAMQPService"
participant Helpers as "CodecHelpers"
participant Task as "vibe.d runTask"
participant Handler as "AMQPPublishResultHandler"

Application -> Service: configure(amqpConfig)
Application -> Service: publish(message)
Service -> Helpers: normalize + validate message
Helpers --> Service: validation result
Service -> Helpers: encode frame
Helpers --> Service: frame
Service --> Application: AMQPPublishResult(queued)

Application -> Service: publishAsync(message, handler)
Service -> Task: runTask(callback)
Task -> Service: publish(message)
Service -> Handler: callback(result)

@enduml
```
