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
  + validateDeclaredLengths: bool
  + validateFieldDataTypes: bool
  + allowUnknownFields: bool
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
  + importLoTW(payload: string): ADIFDocument
  + exportLoTW(document: ADIFDocument): string
  + exportCabrillo(document: ADIFDocument, contestName: string, operatorCall: string): string
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
  + adifValidateDocument(document: ADIFDocument, config: ADIFConfig): ADIFResult
  + adifSerializeField(field: ADIFField, upperCaseFieldNames: bool): string
  + adifSerializeDocument(document: ADIFDocument, config: ADIFConfig): string
}

class ExchangeHelpers {
  + adifImportLoTW(payload: string, strictMode: bool): ADIFDocument
  + adifExportLoTW(document: ADIFDocument, config: ADIFConfig): string
  + adifExportCabrillo(document: ADIFDocument, contestName: string, operatorCall: string): string
}

UIMADIFService --> CodecHelpers : parse, validate, serialize
UIMADIFService --> ExchangeHelpers : import/export

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

Application -> Service: exportCabrillo(document, contestName, operatorCall)
Service --> Application: Cabrillo text

Application -> Service: serializeDocumentAsync(document, handler)
Service -> Task: runTask(callback)
Task -> Handler: callback(result)

@enduml
```