/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.adif.models.logbook;

import uim.adif;

mixin(ShowModule!());

@safe:

ADIFField ADIFFieldOf(string name, string value, string dataType = "") {
  ADIFField field;
  field.name = adifNormalizeFieldName(name);
  field.value = value;
  field.dataType = dataType;
  field.declaredLength = cast(size_t) value.length;
  return field;
}

ADIFRecord ADIFRecordOf(ADIFField[] fields...) {
  ADIFRecord record;
  foreach (field; fields) {
    record.fields ~= field;
  }
  return record;
}

string ADIFRecordValue(const(ADIFRecord) record, string fieldName, string fallback = "") {
  auto normalized = adifNormalizeFieldName(fieldName);

  foreach (field; record.fields) {
    if (adifNormalizeFieldName(field.name) == normalized) {
      return field.value;
    }
  }

  return fallback;
}

ADIFResult ADIFResultOk(
  ushort statusCode = 200,
  string message = "ok",
  ulong recordCount = 0,
  ulong fieldCount = 0
) {
  ADIFResult result;
  result.success = true;
  result.statusCode = statusCode;
  result.message = message;
  result.recordCount = recordCount;
  result.fieldCount = fieldCount;
  return result;
}

ADIFResult ADIFResultErr(
  ushort statusCode = 500,
  string message = "error",
  ulong recordCount = 0,
  ulong fieldCount = 0
) {
  ADIFResult result;
  result.success = false;
  result.statusCode = statusCode;
  result.message = message;
  result.recordCount = recordCount;
  result.fieldCount = fieldCount;
  return result;
}

ADIFDocument ADIFDocumentEmpty() {
  ADIFDocument document;
  return document;
}

unittest {
  auto record = ADIFRecordOf(
    ADIFFieldOf("CALL", "DL1ABC"),
    ADIFFieldOf("BAND", "20M")
  );

  assert(ADIFRecordValue(record, "call") == "DL1ABC");

  auto ok = ADIFResultOk(200, "validated", 1, 2);
  assert(ok.success);
  assert(ok.recordCount == 1);
}