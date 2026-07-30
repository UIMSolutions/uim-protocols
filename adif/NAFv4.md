# NAF v4 Architecture - UIM-ADIF

This document maps uim-adif capabilities to NATO Architecture Framework v4 viewpoints.

## AV - All Views

### AV-1 Overview

| Attribute | Value |
| --- | --- |
| Architecture Name | UIM ADIF Library |
| Version | 26.x |
| Date | 30 July 2026 |
| Language | D (dlang) |
| Runtime | vibe.d |
| Domain | Amateur Data Interchange Format parsing, serialization, and validation |
| License | Apache-2.0 |
| Status | Initial Release |

### AV-2 Integrated Dictionary

| Term | Definition |
| --- | --- |
| ADIF Service | Service that orchestrates parse, serialize, and validation workflows |
| ADIF Field | `<FIELD:length[:type]>value` encoded element |
| ADIF Record | Collection of ADIF fields terminated by `<EOR>` |
| ADIF Header | Metadata section terminated by `<EOH>` |
| Async Operation | Non-blocking callback execution via runTask |

## CV - Capability View

### CV-1 Capability Taxonomy

```text
ADIF Integration Capability
|- Header Management
|  |- adif version metadata
|  |- program identifier metadata
|- Logbook Parsing
|  |- parse ADIF header tags
|  |- parse record fields
|- Logbook Serialization
|  |- serialize typed fields
|  |- emit EOH and EOR delimiters
|- Validation
|  |- record presence checks
|  |- strict-mode CALL and QSO_DATE checks
|- Async Processing
   |- async parse callback
   |- async serialize callback
```

### CV-2 Capability Dependencies

| Capability | Depends On |
| --- | --- |
| Async operations | vibe.d runTask |
| Tag conversion | codec helper functions |
| Default integration mode | in-memory parse and validation behavior |
| External processing engine | injected provider delegates |

## OV - Operational View

### OV-1 Operational Concept

1. Application configures ADIF version and program metadata.
2. Service parses the ADIF payload into typed header and record structures.
3. Service validates records for structural completeness.
4. Service serializes typed records back into ADIF text.
5. Async APIs expose non-blocking parse and serialize paths.

### OV-5 Activity Model

| Step | Activity | Input | Output |
| --- | --- | --- | --- |
| 1 | Configure service | ADIFConfig | ready state |
| 2 | Parse document | ADIF payload | ADIFDocument |
| 3 | Validate document | ADIFDocument | ADIFResult |
| 4 | Serialize document | ADIFDocument | ADIF payload |
| 5 | Normalize field name | field name | upper-case ADIF key |

## SV - Systems View

### SV-1 Systems Interface Description

```text
+---------------------------+
| Application Layer         |
| - ham radio logbook apps  |
+-------------+-------------+
              |
              v
+---------------------------+
| uim.adif                  |
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
| uim.adif.interfaces.logbook | ADIF contracts and value types |
| uim.adif.models.logbook | helper factories and lookup helpers |
| uim.adif.helpers.codec | tag parsing and serialization helpers |
| uim.adif.service | parse/serialize/validate orchestration |

## TV - Technical View

### TV-1 Standards Profile

| Standard / Technology | Version | Use |
| --- | --- | --- |
| D Language | 2.x | implementation language |
| vibe.d | 0.10.x | async task scheduling |
| ADIF | 3.x | amateur radio logbook exchange syntax |

### TV-2 Technical Roadmap

| Item | Status | Description |
| --- | --- | --- |
| Typed ADIF API model | Implemented | parse/serialize/validate contracts |
| ADIF tag parser helper | Implemented | field and record conversion |
| Async operation API | Implemented | callback-based parse/serialize |
| In-memory provider defaults | Implemented | integration without external engine |
| Full ADIF schema validation | Planned | enumerated field and datatype validation |

## L - Logical Model

### L-1 Logical Data Model

```text
ADIFConfig
  |- adifVersion: string
  |- programId: string
  |- programVersion: string
  |- includeHeader: bool

ADIFField
  |- name: string
  |- value: string
  |- dataType: string
  |- declaredLength: size_t

ADIFRecord
  |- fields: ADIFField[]

ADIFDocument
  |- header: string[string]
  |- records: ADIFRecord[]

ADIFResult
  |- success: bool
  |- statusCode: ushort
  |- message: string
  |- recordCount: ulong
  |- fieldCount: ulong
```

### L-2 Constraints

- Parsing expects ADIF markers such as `<EOH>` and `<EOR>`.
- Serialization computes field lengths from current field values.
- Strict-mode validation requires `CALL` and `QSO_DATE` in every record.
- Async callback invocation is exception-isolated.