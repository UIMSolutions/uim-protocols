# Library uim-ftam

Updated on 30. July 2026

uim-ftam is a lightweight D library to work with FTAM-style file transfer workflows using vibe.d runtime patterns. It exposes typed contracts for remote directory navigation and file transfer operations, including asynchronous callback helpers.

## Features

- Typed FTAM contracts (`IFTAMService`)
- FTAM configuration model with security and transfer mode options
- Path normalization and simple directory-line parsing helpers
- Synchronous APIs for list, read, write, delete, and create-directory operations
- Async callbacks implemented with vibe.d `runTask`
- Optional provider delegates for plugging in a real FTAM transport implementation

## Installation

Add this dependency to your `dub.sdl`:

```d
dependency "uim-framework:ftam" version="*"
```

## Quick Start

```d
import std.stdio : writeln;
import uim.ftam;

void main() {
  auto service = FTAMService();

  FTAMConfig cfg;
  cfg.host = "ftam.example.org";
  cfg.port = 102;
  cfg.username = "operator";
  cfg.password = "secret";

  assert(service.configure(cfg));

  service.createDirectory("/docs");
  service.writeFile("/docs/spec.txt", "hello ftam");

  foreach (entry; service.list("/docs")) {
    writeln(entry.path, " size=", entry.sizeBytes);
  }

  auto read = service.readFile("/docs/spec.txt");
  if (read.status.success) {
    writeln(read.content);
  }

  service.readFileAsync("/docs/spec.txt", (FTAMReadResult result) @safe {
    if (result.status.success) {
      writeln("async bytes=", result.status.bytesTransferred);
    }
  });
}
```

## Modules

- `uim.ftam`: package entrypoint and re-exports
- `uim.ftam.interfaces`: FTAM contracts, enums, and DTO structs
- `uim.ftam.models`: result and entry helper constructors
- `uim.ftam.helpers`: path and line parsing helpers
- `uim.ftam.service`: transfer orchestration and async methods

## Notes

- Default behavior is in-memory so the package is usable immediately for tests and integration wiring.
- For production FTAM exchange, inject real transport providers with `setListProvider`, `setReadProvider`, `setWriteProvider`, `setDeleteProvider`, and `setCreateDirectoryProvider`.
