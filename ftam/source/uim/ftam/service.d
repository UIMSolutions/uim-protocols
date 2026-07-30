/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.ftam.service;

import std.algorithm.searching : canFind, startsWith;
import std.array : array;
import std.string : split;

import vibe.d : runTask;

import uim.ftam;

mixin(ShowModule!());

@safe:

class UIMFTAMService : UIMObject, IFTAMService {
  private FTAMConfig _config;
  private bool _configured;

  private FTAMListDelegate _listProvider;
  private FTAMReadDelegate _readProvider;
  private FTAMWriteDelegate _writeProvider;
  private FTAMDeleteDelegate _deleteProvider;
  private FTAMCreateDirectoryDelegate _createDirectoryProvider;

  private string[string] _files;
  private string[] _directories = ["/"];

  bool configure(FTAMConfig config) {
    if (config.host.length == 0 || config.port == 0) {
      _configured = false;
      return false;
    }

    _config = config;
    _config.remoteRoot = ftamNormalizePath(config.remoteRoot);
    _configured = true;
    return true;
  }

  FTAMConfig config() const {
    return _config;
  }

  bool setListProvider(FTAMListDelegate provider) {
    _listProvider = provider;
    return true;
  }

  bool setReadProvider(FTAMReadDelegate provider) {
    _readProvider = provider;
    return true;
  }

  bool setWriteProvider(FTAMWriteDelegate provider) {
    _writeProvider = provider;
    return true;
  }

  bool setDeleteProvider(FTAMDeleteDelegate provider) {
    _deleteProvider = provider;
    return true;
  }

  bool setCreateDirectoryProvider(FTAMCreateDirectoryDelegate provider) {
    _createDirectoryProvider = provider;
    return true;
  }

  FTAMFileEntry[] list(string directory = "/") {
    FTAMFileEntry[] result;
    if (!_configured) {
      return result;
    }

    auto normalizedDirectory = normalizePath(directory);

    if (_listProvider !is null) {
      try {
        return _listProvider(_config, normalizedDirectory);
      } catch (Exception) {
        return result;
      }
    }

    foreach (entryDirectory; _directories) {
      if (entryDirectory == normalizedDirectory) {
        continue;
      }

      if (isDirectChild(normalizedDirectory, entryDirectory)) {
        result ~= FTAMDirectoryEntry(entryDirectory);
      }
    }

    foreach (path, content; _files) {
      if (isDirectChild(normalizedDirectory, path)) {
        result ~= FTAMFileEntryOf(path, cast(ulong) content.length, "2026-07-30T00:00:00Z");
      }
    }

    return result;
  }

  FTAMReadResult readFile(string filePath) {
    auto normalizedFilePath = normalizePath(filePath);

    if (!_configured || normalizedFilePath == "/") {
      return FTAMReadErr(normalizedFilePath, "FTAM service is not configured or path is invalid.");
    }

    if (_readProvider !is null) {
      try {
        return _readProvider(_config, normalizedFilePath);
      } catch (Exception ex) {
        return FTAMReadErr(normalizedFilePath, ex.msg);
      }
    }

    if (normalizedFilePath in _files) {
      return FTAMReadOk(normalizedFilePath, _files[normalizedFilePath]);
    }

    return FTAMReadErr(normalizedFilePath, "file not found");
  }

  FTAMTransferResult writeFile(string filePath, string content) {
    auto normalizedFilePath = normalizePath(filePath);

    if (!_configured || normalizedFilePath == "/") {
      return FTAMTransferErr(normalizedFilePath, "FTAM service is not configured or path is invalid.");
    }

    if (_writeProvider !is null) {
      try {
        return _writeProvider(_config, normalizedFilePath, content);
      } catch (Exception ex) {
        return FTAMTransferErr(normalizedFilePath, ex.msg);
      }
    }

    auto parent = parentDirectory(normalizedFilePath);
    ensureDirectory(parent);
    _files[normalizedFilePath] = content;

    return FTAMTransferOk(normalizedFilePath, cast(ulong) content.length, "write ok");
  }

  FTAMTransferResult deleteFile(string filePath) {
    auto normalizedFilePath = normalizePath(filePath);

    if (!_configured || normalizedFilePath == "/") {
      return FTAMTransferErr(normalizedFilePath, "FTAM service is not configured or path is invalid.");
    }

    if (_deleteProvider !is null) {
      try {
        return _deleteProvider(_config, normalizedFilePath);
      } catch (Exception ex) {
        return FTAMTransferErr(normalizedFilePath, ex.msg);
      }
    }

    if (!(normalizedFilePath in _files)) {
      return FTAMTransferErr(normalizedFilePath, "file not found");
    }

    _files.remove(normalizedFilePath);
    return FTAMTransferOk(normalizedFilePath, 0, "delete ok");
  }

  FTAMTransferResult createDirectory(string directoryPath) {
    auto normalizedDirectoryPath = normalizePath(directoryPath);

    if (!_configured || normalizedDirectoryPath.length == 0) {
      return FTAMTransferErr(normalizedDirectoryPath, "FTAM service is not configured or path is invalid.");
    }

    if (_createDirectoryProvider !is null) {
      try {
        return _createDirectoryProvider(_config, normalizedDirectoryPath);
      } catch (Exception ex) {
        return FTAMTransferErr(normalizedDirectoryPath, ex.msg);
      }
    }

    ensureDirectory(normalizedDirectoryPath);
    return FTAMTransferOk(normalizedDirectoryPath, 0, "directory created");
  }

  bool listAsync(string directory, FTAMListHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localDirectory = directory;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(list(localDirectory));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool readFileAsync(string filePath, FTAMReadHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localFilePath = filePath;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(readFile(localFilePath));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool writeFileAsync(string filePath, string content, FTAMTransferHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localFilePath = filePath;
    auto localContent = content;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(writeFile(localFilePath, localContent));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool deleteFileAsync(string filePath, FTAMTransferHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localFilePath = filePath;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(deleteFile(localFilePath));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  FTAMFileEntry parseDirectoryLine(string line) {
    return ftamParseDirectoryLine(line);
  }

  string normalizePath(string path) {
    return ftamNormalizePath(path);
  }

  private void ensureDirectory(string directoryPath) {
    if (!containsDirectory(directoryPath)) {
      _directories ~= directoryPath;
    }
  }

  private bool containsDirectory(string directoryPath) const {
    foreach (entry; _directories) {
      if (entry == directoryPath) {
        return true;
      }
    }

    return false;
  }

  private bool isDirectChild(string parentPath, string candidatePath) const {
    if (!candidatePath.startsWith(parentPath)) {
      return false;
    }

    auto parent = parentPath;
    if (parent.length > 1 && parent[$ - 1] == '/') {
      parent = parent[0 .. $ - 1];
    }

    if (candidatePath == parent) {
      return false;
    }

    auto remainder = candidatePath[parent.length .. $];
    if (remainder.length == 0) {
      return false;
    }

    if (remainder[0] == '/') {
      remainder = remainder[1 .. $];
    }

    if (remainder.length == 0) {
      return false;
    }

    return !remainder[1 .. $].canFind("/");
  }

  private string parentDirectory(string filePath) const {
    if (filePath.length == 0 || filePath == "/") {
      return "/";
    }

    auto parts = filePath.split("/").array;
    if (parts.length <= 2) {
      return "/";
    }

    auto lastIndex = parts.length;
    string parent = "";
    foreach (idx, part; parts) {
      if (idx == 0 || idx + 1 == lastIndex || part.length == 0) {
        continue;
      }
      parent ~= "/" ~ part;
    }

    return parent.length > 0 ? parent : "/";
  }
}

IFTAMService FTAMService() {
  return new UIMFTAMService();
}

unittest {
  auto service = FTAMService();

  FTAMConfig config;
  config.host = "ftam.example.org";
  config.port = 102;
  assert(service.configure(config));

  auto created = service.createDirectory("/docs");
  assert(created.success);

  auto written = service.writeFile("/docs/readme.txt", "ftam content");
  assert(written.success);

  auto listing = service.list("/docs");
  assert(listing.length == 1);

  auto read = service.readFile("/docs/readme.txt");
  assert(read.status.success);
  assert(read.content == "ftam content");

  auto deleted = service.deleteFile("/docs/readme.txt");
  assert(deleted.success);
}
