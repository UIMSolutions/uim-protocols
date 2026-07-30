# NAF v4 Architecture - UIM-FTAM

This document maps uim-ftam capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM FTAM Library |
| Version | 26.x |
| Date | 30 July 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | FTAM-oriented file transfer orchestration |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| FTAM Service | Service that orchestrates list/read/write/delete operations |
| File Entry | Metadata item representing a file or directory |
| Read Result | Composite read payload and transfer status |
| Transfer Result | Common operation result for write/delete/create-directory |
| Async Operation | Non-blocking callback execution via runTask |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
FTAM Integration Capability
|- Session Configuration
|  |- host, port, security, transfer mode, credentials
|- Path and Metadata Handling
|  |- path normalization
|  |- listing line parsing
|- File Operations
|  |- list directory
|  |- read file
|  |- write file
|  |- delete file
|  |- create directory
|- Async Processing
   |- async list/read/write/delete callbacks
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| Path and line parsing | codec helper functions |
| Default integration mode | in-memory store in service |
| Real FTAM communication | injected provider delegates |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures FTAM endpoint and credentials.
2. Service creates or discovers target directories.
3. Service performs read and write operations on remote paths.
4. Service lists and deletes files as requested.
5. Service can expose async callbacks for non-blocking flows.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | FTAMConfig | ready state |
| 2 | Create directory | directory path | FTAMTransferResult |
| 3 | Write file | path + content | FTAMTransferResult |
| 4 | List directory | directory path | FTAMFileEntry[] |
| 5 | Read/Delete file | file path | FTAMReadResult / FTAMTransferResult |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - transfer orchestration  |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.ftam                  |
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
| uim.ftam.interfaces.session | FTAM contracts, enums, and value types |
| uim.ftam.models.transfer | transfer/result helper constructors |
| uim.ftam.helpers.codec | path normalization and listing line parsing |
| uim.ftam.service | list/read/write/delete/create-directory orchestration |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| FTAM (ISO 8571 family) | reference | conceptual transfer semantics |
| TLS | contemporary | optional transport security model |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed FTAM model and service API | Implemented | core transfer and metadata operations |
| Path/line helper layer | Implemented | normalization and parser support |
| Async operations | Implemented | callback-based list/read/write/delete |
| In-memory provider defaults | Implemented | immediate integration without server |
| Full FTAM transport binding | Planned | session negotiation and remote exchange |

## L - Logical Model

### L-1 Logical Data Model

```text
FTAMConfig
  |- host: string
  |- port: ushort
  |- security: FTAMSecurity
  |- transferMode: FTAMTransferMode
  |- username: string
  |- password: string
  |- remoteRoot: string

FTAMFileEntry
  |- path: string
  |- isDirectory: bool
  |- sizeBytes: ulong
  |- modifiedAt: string

FTAMTransferResult
  |- success: bool
  |- message: string
  |- remotePath: string
  |- bytesTransferred: ulong

FTAMReadResult
  |- status: FTAMTransferResult
  |- content: string
```

### L-2 Constraints

- Service operations require configured host and non-zero port.
- File operations require normalized absolute paths.
- Root path cannot be used as a file target.
- Async callback invocation is exception-isolated.
