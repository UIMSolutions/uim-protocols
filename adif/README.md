# Library uim-adif

Updated on 30. July 2026

uim-adif is a lightweight D library to work with Amateur Data Interchange Format (ADIF) payloads using vibe.d runtime patterns. It provides typed parse, serialize, and validation workflows for ham radio logbook exchange.

## Features

- Typed ADIF contracts (`IADIFService`)
- Config model for ADIF versioning, header generation, and strict-mode validation
- Field catalog and datatype validation for common ADIF logbook attributes
- Tag parser and serializer for standard `<FIELD:length[:type]>value` ADIF records
- Synchronous APIs for parse, serialize, and validation workflows
- LoTW import/export helpers and Cabrillo contest-log export conversion
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in custom import/export or validation engines

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-framework:adif" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.adif;

void main() {
  auto service = ADIFService();

  ADIFConfig config;
  config.programId = "uim-logbook";
  config.programVersion = "1.0.0";
  config.strictMode = true;

  assert(service.configure(config));

  auto payload = "<ADIF_VER:5>3.1.4<PROGRAMID:11>uim-logbook<EOH>"
    ~ "<CALL:6>DL1ABC<QSO_DATE:8:D>20260730<TIME_ON:6>183500<BAND:3>20M<MODE:2>CW<EOR>";

  auto document = service.parseDocument(payload);
  auto result = service.validateDocument(document);
  auto lotwPayload = service.exportLoTW(document);
  auto cabrillo = service.exportCabrillo(document, "CQ-WW", "DL0XYZ");

  writeln("records=", document.records.length, " valid=", result.success);
  writeln(service.serializeDocument(document));
  writeln(lotwPayload.length, " ", cabrillo.length);
}
```

## Modules

- `uim.adif`: package entrypoint and re-exports
- `uim.adif.interfaces`: contracts and ADIF DTO structs
- `uim.adif.models`: helper constructors and result factories
- `uim.adif.helpers`: ADIF tag parser, validation, and exchange conversion helpers
- `uim.adif.service`: parse/serialize/validate orchestration, LoTW import/export, and Cabrillo export APIs

## Notes

- Header parsing supports standard ADIF markers such as `<EOH>` and record terminators such as `<EOR>`.
- Default behavior is in-memory and focused on application-level ADIF exchange rather than transport.
- In strict mode, validation requires `CALL` and `QSO_DATE` in every record.
- Additional validation checks declared length consistency, common datatype formats, supported band values, and callsign character constraints.
- Cabrillo export is intentionally lossy and derives contest defaults from available ADIF fields when a full contest exchange is not present.