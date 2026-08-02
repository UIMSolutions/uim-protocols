# NAF v4 Architecture - UIM-ELF

This document maps uim-elf capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM ELF Library |
| Version | 26.x |
| Date | 30 July 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | Extended Log Format parsing, serialization, and validation |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| ELF Service | Service that orchestrates parse, serialize, and validation workflows |
| Directive | Header line beginning with `#` defining metadata such as fields |
| Field Schema | Ordered field list from `#Fields` directive |
| Log Record | Single data line mapped to field schema |
| Async Operation | Non-blocking callback execution via runTask |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
ELF Integration Capability
|- Header Directive Management
|  |- parse #Version and #Fields
|  |- preserve additional directive lines
|- Record Processing
|  |- map record tokens to directive fields
|  |- infer fields when serializing ad-hoc records
|- Validation
|  |- schema presence checks
|  |- record-to-field alignment checks
|- Async Processing
   |- async parse callback
   |- async serialize callback
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| Directive and record conversion | codec helper functions |
| Default integration mode | in-memory parse/serialize/validate behavior |
| External processing engine | injected provider delegates |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures strictness and header behavior.
2. Service parses directives and builds field schema.
3. Service parses records according to the schema.
4. Service validates records for required field mappings.
5. Service serializes records back into ELF text.
6. Async APIs expose non-blocking parse and serialize paths.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | ELFConfig | ready state |
| 2 | Parse document | ELF payload | ELFDocument |
| 3 | Validate document | ELFDocument | ELFResult |
| 4 | Serialize document | ELFDocument | ELF payload |
| 5 | Normalize directive | directive keyword | normalized directive |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - web and service logging |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.elf                   |
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
| uim.elf.interfaces.log | ELF contracts and value types |
| uim.elf.models.log | helper factories and lookup helpers |
| uim.elf.helpers.codec | directive/record parsing, serialization, and validation helpers |
| uim.elf.service | parse/serialize/validate orchestration |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| W3C Extended Log File Format | Working Draft | structured log syntax |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed ELF API model | Implemented | parse/serialize/validate contracts |
| Directive and record parser helper | Implemented | schema and record conversion |
| Async operation API | Implemented | callback-based parse/serialize |
| In-memory provider defaults | Implemented | integration without external engine |
| Quoted field and escape handling | Planned | robust parser for complex tokenization |

## L - Logical Model

### L-1 Logical Data Model

```text
ELFConfig
  |- elfVersion: string
  |- strictMode: bool
  |- includeHeader: bool
  |- preserveCommentLines: bool

ELFDirective
  |- name: string
  |- values: string[]

ELFRecord
  |- fields: string[string]

ELFDocument
  |- directives: ELFDirective[]
  |- records: ELFRecord[]
  |- comments: string[]

ELFResult
  |- success: bool
  |- statusCode: ushort
  |- message: string
  |- recordCount: ulong
  |- fieldCount: ulong
```

### L-2 Constraints

- Parsing expects header directives prefixed with `#`.
- Validation requires `#Fields` and aligned record values.
- Strict mode rejects malformed records with mismatched field counts.
- Async callback invocation is exception-isolated.