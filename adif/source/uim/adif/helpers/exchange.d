/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.adif.helpers.exchange;

import std.array : appender;
import std.string : strip;

import uim.adif.helpers.codec;
import uim.adif.interfaces;
import uim.adif.models;

@safe:

ADIFDocument adifImportLoTW(string payload, bool strictMode = true) {
  auto document = adifParseDocument(payload, strictMode);

  if (document.header.length == 0) {
    document.header["PROGRAMID"] = "LoTW";
  }

  return document;
}

string adifExportLoTW(ADIFDocument document, ADIFConfig config) {
  auto exportConfig = config;
  exportConfig.includeHeader = true;

  if (!("PROGRAMID" in document.header)) {
    document.header["PROGRAMID"] = "LoTW";
  }

  if (!("PROGRAMVERSION" in document.header) && exportConfig.programVersion.length > 0) {
    document.header["PROGRAMVERSION"] = exportConfig.programVersion;
  }

  return adifSerializeDocument(document, exportConfig);
}

string adifExportCabrillo(ADIFDocument document, string contestName = "GENERAL", string operatorCall = "") {
  auto buffer = appender!string();
  auto stationCall = operatorCall.strip();

  if (stationCall.length == 0) {
    if (auto headerCall = "STATION_CALLSIGN" in document.header) {
      stationCall = (*headerCall).strip();
    }
  }

  if (stationCall.length == 0 && document.records.length > 0) {
    stationCall = ADIFRecordValue(document.records[0], "STATION_CALLSIGN");
  }

  if (stationCall.length == 0) {
    stationCall = "N0CALL";
  }

  buffer.put("START-OF-LOG: 3.0\n");
  buffer.put("CREATED-BY: uim-adif 26.x\n");
  buffer.put("CALLSIGN: ");
  buffer.put(stationCall);
  buffer.put("\nCONTEST: ");
  buffer.put(contestName.strip().length > 0 ? contestName.strip() : "GENERAL");
  buffer.put("\nCATEGORY-OPERATOR: SINGLE-OP\n");

  foreach (record; document.records) {
    auto workedCall = ADIFRecordValue(record, "CALL", "UNKNOWN");
    auto qsoDate = ADIFRecordValue(record, "QSO_DATE", "19700101");
    auto timeOn = normalizeCabrilloTime(ADIFRecordValue(record, "TIME_ON", "0000"));
    auto mode = normalizeCabrilloMode(ADIFRecordValue(record, "MODE", "PH"));
    auto band = ADIFRecordValue(record, "BAND", "20M");
    auto frequency = adifBandToCabrilloFrequency(band);
    auto sent = ADIFRecordValue(record, "RST_SENT", "599");
    auto received = ADIFRecordValue(record, "RST_RCVD", "599");

    buffer.put("QSO: ");
    buffer.put(frequency);
    buffer.put(" ");
    buffer.put(mode);
    buffer.put(" ");
    buffer.put(formatCabrilloDate(qsoDate));
    buffer.put(" ");
    buffer.put(timeOn);
    buffer.put(" ");
    buffer.put(stationCall);
    buffer.put(" ");
    buffer.put(sent);
    buffer.put(" 001 ");
    buffer.put(workedCall);
    buffer.put(" ");
    buffer.put(received);
    buffer.put(" 001\n");
  }

  buffer.put("END-OF-LOG:\n");
  return buffer.data;
}

string adifBandToCabrilloFrequency(string band) {
  auto normalizedBand = adifNormalizeFieldName(band);

  if (normalizedBand == "160M") return "1800";
  if (normalizedBand == "80M") return "3500";
  if (normalizedBand == "60M") return "5351";
  if (normalizedBand == "40M") return "7000";
  if (normalizedBand == "30M") return "10100";
  if (normalizedBand == "20M") return "14000";
  if (normalizedBand == "17M") return "18068";
  if (normalizedBand == "15M") return "21000";
  if (normalizedBand == "12M") return "24890";
  if (normalizedBand == "10M") return "28000";
  if (normalizedBand == "6M") return "50000";
  if (normalizedBand == "2M") return "144000";

  return "14000";
}

private string normalizeCabrilloTime(string value) {
  auto trimmed = value.strip();
  if (trimmed.length >= 4) {
    return trimmed[0 .. 4];
  }
  return "0000";
}

private string normalizeCabrilloMode(string value) {
  auto normalized = adifNormalizeFieldName(value);
  if (normalized == "SSB" || normalized == "USB" || normalized == "LSB" || normalized == "FM") {
    return "PH";
  }
  return normalized.length > 0 ? normalized : "CW";
}

private string formatCabrilloDate(string value) {
  auto trimmed = value.strip();
  if (trimmed.length != 8) {
    return "1970-01-01";
  }

  return trimmed[0 .. 4] ~ "-" ~ trimmed[4 .. 6] ~ "-" ~ trimmed[6 .. 8];
}

unittest {
  auto payload = "<ADIF_VER:5>3.1.4<PROGRAMID:4>LoTW<EOH><CALL:6>DL1ABC<QSO_DATE:8:D>20260730<TIME_ON:6>183500<BAND:3>20M<MODE:3>SSB<EOR>";
  auto document = adifImportLoTW(payload);
  assert(document.records.length == 1);

  ADIFConfig config;
  auto lotw = adifExportLoTW(document, config);
  assert(lotw.length > 0);

  auto cabrillo = adifExportCabrillo(document, "TEST-CONTEST", "DL0XYZ");
  assert(cabrillo.length > 0);
}