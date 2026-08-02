# UIM-UART UML Description

## Overview

The UIM-UART library provides a compact architecture for UART communication workflows in D. It combines typed serial configuration, byte-oriented frame models, validation helpers, deterministic codecs, and vibe.d-based asynchronous orchestration.

## Core Types

```plantuml
@startuml UART_Core

enum UARTParity {
  none
  even
  odd
  mark
  space
}

enum UARTStopBits {
  one
  oneHalf
  two
}

struct UARTConfig {
  + portName: string
  + baudRate: uint
  + dataBits: ubyte
  + parity: UARTParity
  + stopBits: UARTStopBits
  + hardwareFlowControl: bool
  + softwareFlowControl: bool
  + readChunkSize: size_t
  + strictMode: bool
  + lineEnding: string
}

struct UARTFrame {
  + portName: string
  + payload: ubyte[]
  + timestampUnix: ulong
  + terminated: bool
  + correlationId: string
}

struct UARTResult {
  + success: bool
  + statusCode: ushort
  + message: string
  + portName: string
  + bytesTransferred: size_t
  + correlationId: string
}

interface IUARTService {
  + configure(config: UARTConfig): bool
  + transmit(frame: UARTFrame): UARTResult
  + receive(maxBytes: size_t): UARTFrame
  + validateFrame(frame: UARTFrame): UARTResult
  + encodeFrame(frame: UARTFrame): string
  + decodeFrame(encodedFrame: string): UARTFrame
  + transmitAsync(frame: UARTFrame, handler: UARTResultHandler): bool
  + receiveAsync(maxBytes: size_t, handler: UARTFrameHandler): bool
}

class UIMUARTService

UIMUARTService ..|> IUARTService

@enduml
```

## Helper Layer

```plantuml
@startuml UART_Helpers

class CodecHelpers {
  + uartNormalizeFrame(config: UARTConfig, frame: UARTFrame): UARTFrame
  + uartValidateConfig(config: UARTConfig): UARTResult
  + uartValidateFrame(config: UARTConfig, frame: UARTFrame): UARTResult
  + uartEncodeFrame(config: UARTConfig, frame: UARTFrame): string
  + uartDecodeFrame(encodedFrame: string): UARTFrame
}

UIMUARTService --> CodecHelpers : normalize, validate, encode, decode

@enduml
```

## Sequence

```plantuml
@startuml UART_Sequence

actor Application
participant Service as "UIMUARTService"
participant Helpers as "CodecHelpers"
participant Task as "vibe.d runTask"
participant Handler as "UARTResultHandler"

Application -> Service: configure(uartConfig)
Application -> Service: transmit(frame)
Service -> Helpers: normalize + validate frame
Helpers --> Service: validation result
Service --> Application: UARTResult(transmitted)

Application -> Service: transmitAsync(frame, handler)
Service -> Task: runTask(callback)
Task -> Service: transmit(frame)
Service -> Handler: callback(result)

Application -> Service: receiveAsync(maxBytes, handler)
Service -> Task: runTask(callback)
Task -> Service: receive(maxBytes)
Service -> Handler: callback(frame)

@enduml
```