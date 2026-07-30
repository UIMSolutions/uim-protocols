# UIM-FTAM UML Description

## Overview

The UIM-FTAM library provides a compact architecture for FTAM-oriented file transfer workflows in D. It combines typed contracts, parser helpers, model constructors, and service-level orchestration with asynchronous callback support using vibe.d.

## Core Types

```plantuml
@startuml FTAM_Core

enum FTAMSecurity {
  none
  tls
}

enum FTAMTransferMode {
  stream
  block
  compressed
}

struct FTAMConfig {
  + host: string
  + port: ushort
  + security: FTAMSecurity
  + transferMode: FTAMTransferMode
  + username: string
  + password: string
  + remoteRoot: string
}

struct FTAMFileEntry {
  + path: string
  + isDirectory: bool
  + sizeBytes: ulong
  + modifiedAt: string
}

struct FTAMTransferResult {
  + success: bool
  + message: string
  + remotePath: string
  + bytesTransferred: ulong
}

struct FTAMReadResult {
  + status: FTAMTransferResult
  + content: string
}

interface IFTAMService {
  + configure(config: FTAMConfig): bool
  + list(directory: string = "/"): FTAMFileEntry[]
  + readFile(filePath: string): FTAMReadResult
  + writeFile(filePath: string, content: string): FTAMTransferResult
  + deleteFile(filePath: string): FTAMTransferResult
  + createDirectory(directoryPath: string): FTAMTransferResult
  + listAsync(directory: string, handler: FTAMListHandler): bool
  + readFileAsync(filePath: string, handler: FTAMReadHandler): bool
  + writeFileAsync(filePath: string, content: string, handler: FTAMTransferHandler): bool
  + deleteFileAsync(filePath: string, handler: FTAMTransferHandler): bool
}

class UIMFTAMService

UIMFTAMService ..|> IFTAMService

@enduml
```

## Helper Layer

```plantuml
@startuml FTAM_Helpers

class CodecHelpers {
  + ftamNormalizePath(path: string): string
  + ftamParseDirectoryLine(line: string): FTAMFileEntry
}

UIMFTAMService --> CodecHelpers : parse and normalize

@enduml
```

## Sequence

```plantuml
@startuml FTAM_Sequence

actor Application
participant Service as "UIMFTAMService"
participant Task as "vibe.d runTask"
participant Handler as "FTAMReadHandler"

Application -> Service: configure(ftamConfig)
Application -> Service: createDirectory("/docs")
Application -> Service: writeFile("/docs/spec.txt", "payload")
Application -> Service: list("/docs")
Service --> Application: FTAMFileEntry[]

Application -> Service: readFileAsync("/docs/spec.txt", handler)
Service -> Task: runTask(callback)
Task -> Handler: callback(FTAMReadResult)

@enduml
```
