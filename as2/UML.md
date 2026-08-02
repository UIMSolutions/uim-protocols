# UIM-AS2 UML Description

## Overview

The UIM-AS2 library provides a compact architecture for AS2 message exchange workflows in D. It combines typed contracts, MIME/MDN helper functions, and asynchronous orchestration with vibe.d.

## Core Types

```plantuml
@startuml AS2_Core

enum AS2MICAlgorithm {
  sha1
  sha256
  sha512
}

enum AS2TransferEncoding {
  binary
  base64
}

struct AS2Config {
  + localAs2Id: string
  + remoteAs2Id: string
  + endpointUrl: string
  + signMessages: bool
  + encryptMessages: bool
  + compressMessages: bool
  + requestMdn: bool
  + synchronousMdn: bool
  + strictMode: bool
  + micAlgorithm: AS2MICAlgorithm
  + transferEncoding: AS2TransferEncoding
}

struct AS2Header {
  + key: string
  + value: string
}

struct AS2Message {
  + messageId: string
  + fromAs2Id: string
  + toAs2Id: string
  + subject: string
  + contentType: string
  + payload: string
  + headers: AS2Header[]
  + signed: bool
  + encrypted: bool
  + compressed: bool
  + mic: string
}

struct AS2Disposition {
  + mode: string
  + type: string
  + modifier: string
  + description: string
}

struct AS2Result {
  + success: bool
  + statusCode: ushort
  + message: string
  + messageId: string
  + mic: string
  + disposition: AS2Disposition
}

interface IAS2Service {
  + configure(config: AS2Config): bool
  + validateMessage(message: AS2Message): AS2Result
  + sendMessage(message: AS2Message): AS2Result
  + encodeMimePayload(message: AS2Message): string
  + decodeMimePayload(mimePayload: string): AS2Message
  + buildMdn(original: AS2Message, accepted: bool, details: string): AS2Result
}

class UIMAS2Service

UIMAS2Service ..|> IAS2Service

@enduml
```

## Helper Layer

```plantuml
@startuml AS2_Helpers

class CodecHelpers {
  + as2NormalizeAs2Id(value: string): string
  + as2ValidateMessage(config: AS2Config, message: AS2Message): AS2Result
  + as2CalculateMic(config: AS2Config, message: AS2Message): string
  + as2EncodeMimePayload(config: AS2Config, message: AS2Message): string
  + as2DecodeMimePayload(mimePayload: string): AS2Message
  + as2BuildMdn(config: AS2Config, original: AS2Message, accepted: bool, details: string): AS2Result
}

UIMAS2Service --> CodecHelpers : validate, encode, decode, mdn

@enduml
```

## Sequence

```plantuml
@startuml AS2_Sequence

actor Application
participant Service as "UIMAS2Service"
participant Helpers as "CodecHelpers"
participant Task as "vibe.d runTask"
participant Handler as "AS2ResultHandler"

Application -> Service: configure(as2Config)
Application -> Service: sendMessage(message)
Service -> Helpers: normalize + validate
Helpers --> Service: AS2Result(validated)
Service -> Helpers: encode MIME payload
Helpers --> Service: MIME payload
Service -> Helpers: build MDN (optional)
Helpers --> Service: AS2Result(mdn)
Service --> Application: AS2Result(sent)

Application -> Service: sendMessageAsync(message, handler)
Service -> Task: runTask(callback)
Task -> Service: sendMessage(message)
Service -> Handler: callback(result)

@enduml
```
