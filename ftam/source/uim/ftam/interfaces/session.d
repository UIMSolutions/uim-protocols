/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.ftam.interfaces.session;

@safe:

enum FTAMSecurity : ubyte {
  none = 0,
  tls = 1
}

enum FTAMTransferMode : ubyte {
  stream = 0,
  block = 1,
  compressed = 2
}

struct FTAMConfig {
  string host;
  ushort port = 102;
  FTAMSecurity security = FTAMSecurity.none;
  FTAMTransferMode transferMode = FTAMTransferMode.stream;
  string username;
  string password;
  string remoteRoot = "/";
  uint connectTimeoutMs = 5_000;
  uint commandTimeoutMs = 5_000;
}

struct FTAMFileEntry {
  string path;
  bool isDirectory;
  ulong sizeBytes;
  string modifiedAt;
}

struct FTAMTransferResult {
  bool success;
  string message;
  string remotePath;
  ulong bytesTransferred;
}

struct FTAMReadResult {
  FTAMTransferResult status;
  string content;
}

alias FTAMListHandler = void delegate(FTAMFileEntry[] entries) @safe;
alias FTAMReadHandler = void delegate(FTAMReadResult result) @safe;
alias FTAMTransferHandler = void delegate(FTAMTransferResult result) @safe;

alias FTAMListDelegate = FTAMFileEntry[] delegate(FTAMConfig config, string directory) @safe;
alias FTAMReadDelegate = FTAMReadResult delegate(FTAMConfig config, string filePath) @safe;
alias FTAMWriteDelegate = FTAMTransferResult delegate(FTAMConfig config, string filePath, string content) @safe;
alias FTAMDeleteDelegate = FTAMTransferResult delegate(FTAMConfig config, string filePath) @safe;
alias FTAMCreateDirectoryDelegate = FTAMTransferResult delegate(FTAMConfig config, string directoryPath) @safe;

interface IFTAMService {
  bool configure(FTAMConfig config);
  FTAMConfig config() const;

  bool setListProvider(FTAMListDelegate provider);
  bool setReadProvider(FTAMReadDelegate provider);
  bool setWriteProvider(FTAMWriteDelegate provider);
  bool setDeleteProvider(FTAMDeleteDelegate provider);
  bool setCreateDirectoryProvider(FTAMCreateDirectoryDelegate provider);

  FTAMFileEntry[] list(string directory = "/");
  FTAMReadResult readFile(string filePath);
  FTAMTransferResult writeFile(string filePath, string content);
  FTAMTransferResult deleteFile(string filePath);
  FTAMTransferResult createDirectory(string directoryPath);

  bool listAsync(string directory, FTAMListHandler handler);
  bool readFileAsync(string filePath, FTAMReadHandler handler);
  bool writeFileAsync(string filePath, string content, FTAMTransferHandler handler);
  bool deleteFileAsync(string filePath, FTAMTransferHandler handler);

  FTAMFileEntry parseDirectoryLine(string line);
  string normalizePath(string path);
}
