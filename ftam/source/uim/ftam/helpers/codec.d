/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.ftam.helpers.codec;

import std.algorithm.searching : canFind;
import std.conv : to;
import std.string : replace, split, strip;

import uim.ftam.interfaces.session;

@safe:

string ftamNormalizePath(string path) {
  auto normalized = path.strip();
  if (normalized.length == 0) {
    return "/";
  }

  normalized = normalized.replace("\\", "/");

  if (normalized[0] != '/') {
    normalized = "/" ~ normalized;
  }

  while (normalized.length > 1 && normalized[$ - 1] == '/') {
    normalized = normalized[0 .. $ - 1];
  }

  while (normalized.canFind("//")) {
    normalized = normalized.replace("//", "/");
  }

  return normalized;
}

FTAMFileEntry ftamParseDirectoryLine(string line) {
  // Expected format: T|/path|size|isoTimestamp
  auto tokens = line.strip().split("|");
  if (tokens.length < 4) {
    return FTAMFileEntry.init;
  }

  FTAMFileEntry entry;
  entry.isDirectory = (tokens[0] == "D");
  entry.path = ftamNormalizePath(tokens[1]);
  entry.modifiedAt = tokens[3];

  try {
    entry.sizeBytes = tokens[2].to!ulong;
  } catch (Exception) {
    entry.sizeBytes = 0;
  }

  return entry;
}

unittest {
  assert(ftamNormalizePath("docs/manual.txt") == "/docs/manual.txt");
  assert(ftamNormalizePath("//docs///") == "/docs");

  auto fileEntry = ftamParseDirectoryLine("F|/docs/manual.txt|2048|2026-05-30T00:00:00Z");
  assert(!fileEntry.isDirectory);
  assert(fileEntry.sizeBytes == 2048);
}
