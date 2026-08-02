# UIM-XI UML Description

## Overview

The UIM-XI library provides a compact architecture for SAP XI message protocol workflows in D. It combines typed contracts, SOAP codec helpers, acknowledgement helpers, and asynchronous orchestration with vibe.d.

## Core Types

```plantuml
@startuml XI_Core

enum XIQualityOfService {
  be
  eo
  eoio
}

struct XIConfig {
  + senderService: string
  + receiverService: string
  + interfaceName: string
  + interfaceNamespace: string
  + adapterType: string
  + endpointUrl: string
  + strictMode: bool
  + qos: XIQualityOfService
  + synchronousMode: bool
}

struct XIHeader {
  + key: string
  + value: string
}

struct XIAddress {
  + party: string
  + service: string
}

struct XIMessage {
  + messageId: string
  + conversationId: string
  + sender: XIAddress
  + receiver: XIAddress
  + interfaceName: string
  + interfaceNamespace: string
  + action: string
  + contentType: string
  + payload: string
  + headers: XIHeader[]
}

struct XIAck {
  + accepted: bool
  + code: string
  + description: string
}

struct XIResult {
  + success: bool
  + statusCode: ushort
  + message: string
  + messageId: string
  + acknowledgement: XIAck
}

interface IXIService {
  + configure(config: XIConfig): bool
  + validateMessage(message: XIMessage): XIResult
  + sendMessage(message: XIMessage): XIResult
  + encodeSoapEnvelope(message: XIMessage): string
  + decodeSoapEnvelope(soapEnvelope: string): XIMessage
  + buildAcknowledgement(original: XIMessage, accepted: bool, details: string): XIResult
}

class UIMXIService

UIMXIService ..|> IXIService

@enduml
```

## Helper Layer

```plantuml
@startuml XI_Helpers

class CodecHelpers {
  + xiNormalizeIdentifier(value: string): string
  + xiValidateMessage(config: XIConfig, message: XIMessage): XIResult
  + xiBuildAction(message: XIMessage): string
  + xiEncodeSoapEnvelope(config: XIConfig, message: XIMessage): string
  + xiDecodeSoapEnvelope(soapEnvelope: string): XIMessage
  + xiBuildAcknowledgement(original: XIMessage, accepted: bool, details: string): XIResult
}

UIMXIService --> CodecHelpers : validate, encode, decode, acknowledge

@enduml
```

## Sequence

```plantuml
@startuml XI_Sequence

actor Application
participant Service as "UIMXIService"
participant Helpers as "CodecHelpers"
participant Task as "vibe.d runTask"
participant Handler as "XIResultHandler"

Application -> Service: configure(xiConfig)
Application -> Service: sendMessage(message)
Service -> Helpers: normalize + validate
Helpers --> Service: XIResult(validated)
Service -> Helpers: encode SOAP envelope
Helpers --> Service: envelope
Service -> Helpers: build acknowledgement
Helpers --> Service: XIResult(ack)
Service --> Application: XIResult(queued)

Application -> Service: sendMessageAsync(message, handler)
Service -> Task: runTask(callback)
Task -> Service: sendMessage(message)
Service -> Handler: callback(result)

@enduml
```
