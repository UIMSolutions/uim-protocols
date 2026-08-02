# UIM-ELF UML Description

## Overview

The UIM-ELF library provides a compact architecture for Extended Log Format workflows in D. It combines typed contracts, directive/record parser helpers, result model constructors, and asynchronous orchestration with vibe.d.

## Core Types

```plantuml
@startuml ELF_Core

struct ELFConfig {
  + elfVersion: string
  + strictMode: bool
  + includeHeader: bool
  + preserveCommentLines: bool
  + allowUnknownDirective: bool
}

struct ELFDirective {
  + name: string
  + values: string[]
}

struct ELFRecord {
  + fields: string[string]
}

struct ELFDocument {
  + directives: ELFDirective[]
  + records: ELFRecord[]
  + comments: string[]
}

struct ELFResult {
  + success: bool
  + statusCode: ushort
  + message: string
  + recordCount: ulong
  + fieldCount: ulong
}

interface IELFService {
  + configure(config: ELFConfig): bool
  + parseDocument(payload: string): ELFDocument
  + serializeDocument(document: ELFDocument): string
  + validateDocument(document: ELFDocument): ELFResult
  + parseDocumentAsync(payload: string, handler: ELFDocumentHandler): bool
  + serializeDocumentAsync(document: ELFDocument, handler: ELFResultHandler): bool
}

class UIMELFService

UIMELFService ..|> IELFService

@enduml
```

## Helper Layer

```plantuml
@startuml ELF_Helpers

class CodecHelpers {
  + elfNormalizeDirective(value: string): string
  + elfParseDocument(payload: string, config: ELFConfig): ELFDocument
  + elfParseRecords(payload: string, config: ELFConfig): ELFRecord[]
  + elfSerializeDocument(document: ELFDocument, config: ELFConfig): string
  + elfValidateDocument(document: ELFDocument, config: ELFConfig): ELFResult
}

UIMELFService --> CodecHelpers : parse, validate, serialize

@enduml
```

## Sequence

```plantuml
@startuml ELF_Sequence

actor Application
participant Service as "UIMELFService"
participant Helpers as "CodecHelpers"
participant Task as "vibe.d runTask"
participant Handler as "ELFDocumentHandler"

Application -> Service: configure(elfConfig)
Application -> Service: parseDocument(payload)
Service -> Helpers: parse directives and records
Helpers --> Service: ELFDocument
Service --> Application: ELFDocument

Application -> Service: validateDocument(document)
Service --> Application: ELFResult

Application -> Service: serializeDocumentAsync(document, handler)
Service -> Task: runTask(callback)
Task -> Handler: callback(result)

@enduml
```