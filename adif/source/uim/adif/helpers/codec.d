/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.adif.helpers.codec;

import std.algorithm.sorting : sort;
import std.array : Appender, appender;
import std.conv : to;
import std.string : indexOf, split, strip;

import uim.adif.interfaces;
import uim.adif.models;

@safe:

private struct ADIFToken {
  string name;
  string value;
  string dataType;
  size_t declaredLength;
  bool isHeaderTerminator;
  bool isRecordTerminator;
  bool parseError;
}

string adifNormalizeFieldName(string fieldName) {
  auto trimmed = fieldName.strip();
  auto buffer = appender!string();

  foreach (ch; trimmed) {
    if (ch >= 'a' && ch <= 'z') {
      buffer.put(cast(char) (ch - 32));
    } else {
      buffer.put(ch);
    }
  }

  return buffer.data;
}

ADIFDocument adifParseDocument(string payload, bool strictMode = false) {
  ADIFDocument document;
  ADIFRecord currentRecord;
  size_t cursor;
  bool inHeader = adifAsciiUpper(payload).indexOf("<EOH>") >= 0;

  while (cursor < payload.length) {
    auto token = parseNextToken(payload, cursor, strictMode);

    if (token.parseError) {
      if (strictMode) {
        return ADIFDocumentEmpty();
      }
      break;
    }

    if (token.isHeaderTerminator) {
      inHeader = false;
      continue;
    }

    if (token.isRecordTerminator) {
      if (currentRecord.fields.length > 0) {
        document.records ~= currentRecord;
        currentRecord = ADIFRecord.init;
      }
      continue;
    }

    if (token.name.length == 0) {
      break;
    }

    ADIFField field;
    field.name = token.name;
    field.value = token.value;
    field.dataType = token.dataType;
    field.declaredLength = token.declaredLength;

    if (inHeader) {
      document.header[token.name] = token.value;
    } else {
      currentRecord.fields ~= field;
    }
  }

  if (currentRecord.fields.length > 0) {
    document.records ~= currentRecord;
  }

  return document;
}

ADIFRecord[] adifParseRecords(string payload, bool strictMode = false) {
  return adifParseDocument(payload, strictMode).records;
}

ADIFResult adifValidateDocument(ADIFDocument document, ADIFConfig config) {
  if (document.records.length == 0) {
    return ADIFResultErr(422, "ADIF document does not contain any records.");
  }

  ulong fieldCount;

  foreach (index, record; document.records) {
    if (record.fields.length == 0) {
      return ADIFResultErr(422, "ADIF record has no fields.", cast(ulong) (index + 1), fieldCount);
    }

    foreach (field; record.fields) {
      fieldCount++;
      auto issue = adifValidateField(field, config);
      if (issue.length > 0) {
        return ADIFResultErr(422, issue, cast(ulong) (index + 1), fieldCount);
      }
    }

    if (config.strictMode) {
      if (ADIFRecordValue(record, "CALL").length == 0) {
        return ADIFResultErr(422, "ADIF record is missing CALL in strict mode.", cast(ulong) (index + 1), fieldCount);
      }

      if (ADIFRecordValue(record, "QSO_DATE").length == 0) {
        return ADIFResultErr(422, "ADIF record is missing QSO_DATE in strict mode.", cast(ulong) (index + 1), fieldCount);
      }
    }
  }

  return ADIFResultOk(200, "validated", cast(ulong) document.records.length, fieldCount);
}

bool adifIsKnownField(string fieldName) {
  return containsString(adifKnownFieldNames, adifNormalizeFieldName(fieldName));
}

string adifInferDataType(string fieldName) {
  auto normalized = adifNormalizeFieldName(fieldName);

  if (normalized == "QSO_DATE") {
    return "D";
  }

  if (normalized == "TIME_ON" || normalized == "TIME_OFF") {
    return "T";
  }

  if (normalized == "FREQ" || normalized == "RST_SENT" || normalized == "RST_RCVD" || normalized == "CQZ" || normalized == "ITUZ") {
    return "N";
  }

  return "";
}

string adifSerializeField(const(ADIFField) field, bool upperCaseFieldNames = true) {
  auto normalizedName = upperCaseFieldNames ? adifNormalizeFieldName(field.name) : field.name.strip();
  auto declaredLength = cast(size_t) field.value.length;
  auto buffer = appender!string();

  buffer.put("<");
  buffer.put(normalizedName);
  buffer.put(":");
  buffer.put(to!string(declaredLength));

  if (field.dataType.length > 0) {
    buffer.put(":");
    buffer.put(field.dataType);
  }

  buffer.put(">");
  buffer.put(field.value);

  return buffer.data;
}

string adifSerializeRecord(const(ADIFRecord) record, bool upperCaseFieldNames = true) {
  auto buffer = appender!string();

  foreach (field; record.fields) {
    buffer.put(adifSerializeField(field, upperCaseFieldNames));
  }

  return buffer.data;
}

string adifSerializeDocument(ADIFDocument document, ADIFConfig config) {
  auto buffer = appender!string();

  if (config.includeHeader) {
    string[string] headerValues;
    foreach (key, value; document.header) {
      headerValues[key] = value;
    }

    if (!("ADIF_VER" in headerValues)) {
      headerValues["ADIF_VER"] = config.adifVersion;
    }

    if (!("PROGRAMID" in headerValues) && config.programId.length > 0) {
      headerValues["PROGRAMID"] = config.programId;
    }

    if (!("PROGRAMVERSION" in headerValues) && config.programVersion.length > 0) {
      headerValues["PROGRAMVERSION"] = config.programVersion;
    }

    putHeaderField(buffer, headerValues, "ADIF_VER", config.upperCaseFieldNames);
    putHeaderField(buffer, headerValues, "PROGRAMID", config.upperCaseFieldNames);
    putHeaderField(buffer, headerValues, "PROGRAMVERSION", config.upperCaseFieldNames);

    string[] extraKeys;
    foreach (key, _; headerValues) {
      if (key == "ADIF_VER" || key == "PROGRAMID" || key == "PROGRAMVERSION") {
        continue;
      }
      extraKeys ~= key;
    }

    sort(extraKeys);
    foreach (key; extraKeys) {
      putHeaderField(buffer, headerValues, key, config.upperCaseFieldNames);
    }

    buffer.put("<EOH>\n");
  }

  foreach (record; document.records) {
    buffer.put(adifSerializeRecord(record, config.upperCaseFieldNames));
    buffer.put("<EOR>\n");
  }

  return buffer.data;
}

private string adifAsciiUpper(string value) {
  auto buffer = appender!string();

  foreach (ch; value) {
    if (ch >= 'a' && ch <= 'z') {
      buffer.put(cast(char) (ch - 32));
    } else {
      buffer.put(ch);
    }
  }

  return buffer.data;
}

private string adifValidateField(const(ADIFField) field, ADIFConfig config) {
  auto normalizedName = adifNormalizeFieldName(field.name);
  if (normalizedName.length == 0) {
    return "ADIF field name is empty.";
  }

  if (config.validateDeclaredLengths && field.declaredLength != cast(size_t) field.value.length) {
    return "ADIF field " ~ normalizedName ~ " declared length does not match value length.";
  }

  auto inferredType = adifInferDataType(normalizedName);
  auto effectiveType = field.dataType.length > 0 ? adifAsciiUpper(field.dataType.strip()) : inferredType;

  if (config.validateFieldDataTypes && field.dataType.length > 0 && inferredType.length > 0 && effectiveType != inferredType) {
    return "ADIF field " ~ normalizedName ~ " uses incompatible data type " ~ effectiveType ~ ".";
  }

  if (!config.allowUnknownFields && !adifIsKnownField(normalizedName)) {
    return "ADIF field " ~ normalizedName ~ " is not in the known field catalog.";
  }

  if (config.validateFieldDataTypes && effectiveType.length > 0) {
    auto typeIssue = validateValueByType(normalizedName, field.value, effectiveType);
    if (typeIssue.length > 0) {
      return typeIssue;
    }
  }

  if (normalizedName == "CALL" && !isValidCallsign(field.value)) {
    return "ADIF CALL contains unsupported characters.";
  }

  if (normalizedName == "BAND" && !containsString(adifBandNames, adifAsciiUpper(field.value.strip()))) {
    return "ADIF BAND is not recognized.";
  }

  if (normalizedName == "MODE" && field.value.strip().length == 0) {
    return "ADIF MODE must not be empty.";
  }

  return "";
}

private string validateValueByType(string fieldName, string value, string dataType) {
  if (dataType == "D") {
    if (value.length != 8 || !isDigitsOnly(value)) {
      return "ADIF field " ~ fieldName ~ " must use YYYYMMDD date format.";
    }
    return "";
  }

  if (dataType == "T") {
    if ((value.length != 4 && value.length != 6) || !isDigitsOnly(value)) {
      return "ADIF field " ~ fieldName ~ " must use HHMM or HHMMSS time format.";
    }
    return "";
  }

  if (dataType == "N") {
    if (!isNumericValue(value)) {
      return "ADIF field " ~ fieldName ~ " must be numeric.";
    }
    return "";
  }

  if (dataType == "B") {
    auto normalized = adifAsciiUpper(value.strip());
    if (normalized != "Y" && normalized != "N" && normalized != "TRUE" && normalized != "FALSE") {
      return "ADIF field " ~ fieldName ~ " must be boolean.";
    }
  }

  return "";
}

private bool isDigitsOnly(string value) {
  if (value.length == 0) {
    return false;
  }

  foreach (ch; value) {
    if (ch < '0' || ch > '9') {
      return false;
    }
  }

  return true;
}

private bool isNumericValue(string value) {
  if (value.length == 0) {
    return false;
  }

  bool decimalSeen;

  foreach (index, ch; value) {
    if (ch >= '0' && ch <= '9') {
      continue;
    }

    if ((ch == '+' || ch == '-') && index == 0) {
      continue;
    }

    if (ch == '.' && !decimalSeen) {
      decimalSeen = true;
      continue;
    }

    return false;
  }

  return true;
}

private bool isValidCallsign(string value) {
  auto normalized = adifAsciiUpper(value.strip());
  if (normalized.length == 0) {
    return false;
  }

  foreach (ch; normalized) {
    auto isAlpha = ch >= 'A' && ch <= 'Z';
    auto isDigit = ch >= '0' && ch <= '9';
    if (!isAlpha && !isDigit && ch != '/' && ch != '-') {
      return false;
    }
  }

  return true;
}

private bool containsString(const(string)[] haystack, string needle) {
  foreach (candidate; haystack) {
    if (candidate == needle) {
      return true;
    }
  }

  return false;
}

private immutable string[] adifKnownFieldNames = [
  "ADIF_VER", "ADDRESS", "BAND", "CALL", "COMMENT", "CONTEST_ID", "CQZ",
  "DXCC", "FREQ", "GRIDSQUARE", "ITUZ", "MODE", "NAME", "OPERATOR",
  "PROGRAMID", "PROGRAMVERSION", "QSO_DATE", "QSO_DATE_OFF", "RST_RCVD",
  "RST_SENT", "STATION_CALLSIGN", "SUBMODE", "TIME_OFF", "TIME_ON"
];

private immutable string[] adifBandNames = [
  "2190M", "630M", "560M", "160M", "80M", "60M", "40M", "30M", "20M",
  "17M", "15M", "12M", "10M", "6M", "4M", "2M", "1.25M", "70CM",
  "33CM", "23CM", "13CM", "9CM", "6CM", "3CM"
];

private size_t findChar(string value, char needle, size_t startIndex) {
  foreach (index; startIndex .. value.length) {
    if (value[index] == needle) {
      return index;
    }
  }

  return value.length;
}

private ADIFToken parseNextToken(string payload, ref size_t cursor, bool strictMode) {
  ADIFToken token;

  while (cursor < payload.length && payload[cursor] != '<') {
    cursor++;
  }

  if (cursor >= payload.length) {
    return token;
  }

  auto endOfDescriptor = findChar(payload, '>', cursor + 1);
  if (endOfDescriptor >= payload.length) {
    token.parseError = strictMode;
    cursor = payload.length;
    return token;
  }

  auto descriptor = payload[cursor + 1 .. endOfDescriptor].strip();
  cursor = endOfDescriptor + 1;

  auto normalizedDescriptor = adifNormalizeFieldName(descriptor);
  if (normalizedDescriptor == "EOH") {
    token.isHeaderTerminator = true;
    return token;
  }

  if (normalizedDescriptor == "EOR") {
    token.isRecordTerminator = true;
    return token;
  }

  auto parts = descriptor.split(":");
  if (parts.length < 2) {
    token.parseError = strictMode;
    return token;
  }

  token.name = adifNormalizeFieldName(parts[0]);

  try {
    token.declaredLength = parts[1].strip().to!size_t;
  } catch (Exception) {
    token.parseError = strictMode;
    return token;
  }

  if (parts.length >= 3) {
    token.dataType = parts[2].strip();
  }

  auto endOfValue = cursor + token.declaredLength;
  if (endOfValue > payload.length) {
    if (strictMode) {
      token.parseError = true;
      cursor = payload.length;
      return token;
    }

    endOfValue = payload.length;
  }

  token.value = payload[cursor .. endOfValue];
  cursor = endOfValue;

  return token;
}

private void putHeaderField(
  ref Appender!string buffer,
  string[string] headerValues,
  string key,
  bool upperCaseFieldNames
) {
  auto valuePtr = key in headerValues;
  if (valuePtr is null) {
    return;
  }

  buffer.put(adifSerializeField(ADIFFieldOf(key, *valuePtr), upperCaseFieldNames));
}

unittest {
  auto payload = "<ADIF_VER:5>3.1.4<PROGRAMID:8>uim-adif<EOH><CALL:6>DL1ABC<BAND:3>20M<MODE:2>CW<EOR>";
  auto document = adifParseDocument(payload);

  assert(document.header["ADIF_VER"] == "3.1.4");
  assert(document.records.length == 1);
  assert(ADIFRecordValue(document.records[0], "MODE") == "CW");

  ADIFConfig config;
  auto serialized = adifSerializeDocument(document, config);
  assert(serialized.indexOf("<CALL:6>DL1ABC") >= 0);

  auto invalid = adifParseDocument("<EOH><CALL:6>DL 1AB<QSO_DATE:8:D>20260730<EOR>");
  auto validation = adifValidateDocument(invalid, config);
  assert(!validation.success);
}