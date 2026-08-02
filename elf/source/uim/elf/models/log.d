/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.elf.models.log;

import uim.elf;

mixin(ShowModule!());

@safe:

ELFDirective ELFDirectiveOf(string name, string[] values...) {
  ELFDirective directive;
  directive.name = elfNormalizeDirective(name);
  foreach (item; values) {
    directive.values ~= item;
  }
  return directive;
}

ELFRecord ELFRecordOf(string[string] fields) {
  ELFRecord record;
  foreach (key, value; fields) {
    record.fields[key] = value;
  }
  return record;
}

string ELFRecordValue(const(ELFRecord) record, string fieldName, string fallback = "") {
  if (auto value = fieldName in record.fields) {
    return *value;
  }

  return fallback;
}

ELFResult ELFResultOk(
  ushort statusCode = 200,
  string message = "ok",
  ulong recordCount = 0,
  ulong fieldCount = 0
) {
  ELFResult result;
  result.success = true;
  result.statusCode = statusCode;
  result.message = message;
  result.recordCount = recordCount;
  result.fieldCount = fieldCount;
  return result;
}

ELFResult ELFResultErr(
  ushort statusCode = 500,
  string message = "error",
  ulong recordCount = 0,
  ulong fieldCount = 0
) {
  ELFResult result;
  result.success = false;
  result.statusCode = statusCode;
  result.message = message;
  result.recordCount = recordCount;
  result.fieldCount = fieldCount;
  return result;
}

ELFDocument ELFDocumentEmpty() {
  ELFDocument document;
  return document;
}

unittest {
  auto directive = ELFDirectiveOf("Fields", "date", "time", "c-ip");
  assert(directive.name == "FIELDS");

  string[string] data;
  data["date"] = "2026-07-30";
  data["time"] = "12:00:00";
  auto record = ELFRecordOf(data);
  assert(ELFRecordValue(record, "date") == "2026-07-30");
}