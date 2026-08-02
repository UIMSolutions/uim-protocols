# Library uim-elf

Updated on 30. July 2026

uim-elf is a lightweight D library to work with Extended Log Format (ELF) payloads based on the W3C working draft using vibe.d runtime patterns. It provides typed parse, serialize, and validation workflows for structured web and service logs.

## Features

- Typed ELF contracts (`IELFService`)
- Config model for strict parsing, comment handling, and header serialization
- Directive parser for `#Version`, `#Fields`, and additional `#` metadata lines
- Record parser and serializer aligned with `#Fields` order
- Synchronous APIs for parse, serialize, and validation workflows
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in custom parsing and validation engines

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-framework:elf" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.elf;

void main() {
  auto service = ELFService();

  ELFConfig config;
  config.elfVersion = "1.0";
  config.strictMode = true;

  assert(service.configure(config));

  auto payload = "#Version: 1.0\n"
    ~ "#Fields date time c-ip cs-method cs-uri\n"
    ~ "2026-07-30 12:00:00 127.0.0.1 GET /index.html\n";

  auto document = service.parseDocument(payload);
  auto result = service.validateDocument(document);

  writeln("records=", document.records.length, " valid=", result.success);
  writeln(service.serializeDocument(document));
}
```

## Modules

- `uim.elf`: package entrypoint and re-exports
- `uim.elf.interfaces`: contracts and ELF DTO structs
- `uim.elf.models`: helper constructors and result factories
- `uim.elf.helpers`: directive, record parse/serialize, and validation helpers
- `uim.elf.service`: parse/serialize/validate orchestration and async APIs

## Notes

- Parser expects at least one `#Fields` directive to map record values to field names.
- Strict mode enforces exact field-count alignment and fails malformed documents.
- Comments are preserved when `preserveCommentLines` is enabled.