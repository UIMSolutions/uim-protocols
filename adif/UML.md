# UIM-ADIF UML Description

## Overview

The UIM-ADIF library provides a compact architecture for ADIF logbook exchange workflows in D. It combines typed contracts, parser/serializer helpers, result model constructors, and asynchronous orchestration with vibe.d.

## Core Types

```plantuml
@startuml ADIF_Core

struct ADIFConfig {
  + adifVersion: string
  + programId: string
  + programVersion: string
  + includeHeader: bool
  + strictMode: bool
  + upperCaseFieldNames: bool
}

struct ADIFField {
  + name: string
  + value: string
  + dataType: string
  + declaredLength: size_t
}

struct ADIFRecord {
  + fields: ADIFField[]
}

struct ADIFDocument {
  + header: string[string]
  + records: ADIFRecord[]
}

struct ADIFResult {
  + success: bool
  + statusCode: ushort
  + message: string
  + recordCount: ulong
  + fieldCount: ulong
}

interface IADIFService {
  + configure(config: ADIFConfig): bool
  + parseDocument(payload: string): ADIFDocument
  + serializeDocument(document: ADIFDocument): string
  + validateDocument(document: ADIFDocument): ADIFResult
  + parseDocumentAsync(payload: string, handler: ADIFDocumentHandler): bool
  + serializeDocumentAsync(document: ADIFDocument, handler: ADIFResultHandler): bool
}

class UIMADIFService

UIMADIFService ..|> IADIFService

@enduml
```

## Helper Layer

```plantuml
@startuml ADIF_Helpers

class CodecHelpers {
  + adifNormalizeFieldName(fieldName: string): string
  + adifParseDocument(payload: string, strictMode: bool): ADIFDocument
  + adifParseRecords(payload: string, strictMode: bool): ADIFRecord[]
  + adifSerializeField(field: ADIFField, upperCaseFieldNames: bool): string
  + adifSerializeDocument(document: ADIFDocument, config: ADIFConfig): string
}

UIMADIFService --> CodecHelpers : parse, serialize

@enduml
```

## Sequence

```plantuml
@startuml ADIF_Sequence

actor Application
participant Service as "UIMADIFService"
participant Helpers as "CodecHelpers"
participant Task as "vibe.d runTask"
participant Handler as "ADIFDocumentHandler"

Application -> Service: configure(adifConfig)
Application -> Service: parseDocument(payload)
Service -> Helpers: parse ADIF tags
Helpers --> Service: ADIFDocument
Service --> Application: ADIFDocument

Application -> Service: validateDocument(document)
Service --> Application: ADIFResult

Application -> Service: serializeDocumentAsync(document, handler)
Service -> Task: runTask(callback)
Task -> Handler: callback(result)

@enduml
```