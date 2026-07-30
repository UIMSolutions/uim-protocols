/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.ftam.models.transfer;

import uim.ftam;

mixin(ShowModule!());

@safe:

FTAMFileEntry FTAMDirectoryEntry(string path) {
  FTAMFileEntry entry;
  entry.path = path;
  entry.isDirectory = true;
  entry.modifiedAt = "1970-01-01T00:00:00Z";
  return entry;
}

FTAMFileEntry FTAMFileEntryOf(string path, ulong sizeBytes, string modifiedAt = "") {
  FTAMFileEntry entry;
  entry.path = path;
  entry.isDirectory = false;
  entry.sizeBytes = sizeBytes;
  entry.modifiedAt = modifiedAt.length > 0 ? modifiedAt : "1970-01-01T00:00:00Z";
  return entry;
}

FTAMTransferResult FTAMTransferOk(string remotePath, ulong bytesTransferred = 0, string message = "ok") {
  FTAMTransferResult result;
  result.success = true;
  result.message = message;
  result.remotePath = remotePath;
  result.bytesTransferred = bytesTransferred;
  return result;
}

FTAMTransferResult FTAMTransferErr(string remotePath, string message = "error") {
  FTAMTransferResult result;
  result.success = false;
  result.message = message;
  result.remotePath = remotePath;
  return result;
}

FTAMReadResult FTAMReadOk(string remotePath, string content) {
  FTAMReadResult result;
  result.status = FTAMTransferOk(remotePath, cast(ulong) content.length, "read ok");
  result.content = content;
  return result;
}

FTAMReadResult FTAMReadErr(string remotePath, string message = "read error") {
  FTAMReadResult result;
  result.status = FTAMTransferErr(remotePath, message);
  result.content = "";
  return result;
}

unittest {
  auto dirEntry = FTAMDirectoryEntry("/docs");
  assert(dirEntry.isDirectory);

  auto ok = FTAMTransferOk("/docs/readme.txt", 123);
  assert(ok.success);

  auto read = FTAMReadOk("/a", "hello");
  assert(read.status.bytesTransferred == 5);
}
