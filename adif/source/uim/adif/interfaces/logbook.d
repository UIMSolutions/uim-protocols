/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.adif.interfaces.logbook;

@safe:

struct ADIFConfig {
  string adifVersion = "3.1.4";
  string programId = "uim-adif";
  string programVersion = "26.x";
  bool includeHeader = true;
  bool strictMode;
  bool upperCaseFieldNames = true;
}

struct ADIFField {
  string name;
  string value;
  string dataType;
  size_t declaredLength;
}

struct ADIFRecord {
  ADIFField[] fields;
}

struct ADIFDocument {
  string[string] header;
  ADIFRecord[] records;
}

struct ADIFResult {
  bool success;
  ushort statusCode;
  string message;
  ulong recordCount;
  ulong fieldCount;
}

alias ADIFDocumentHandler = void delegate(ADIFDocument document) @safe;
alias ADIFResultHandler = void delegate(ADIFResult result) @safe;

alias ADIFParseDelegate = ADIFDocument delegate(
  ADIFConfig config,
  string payload
) @safe;

alias ADIFSerializeDelegate = string delegate(
  ADIFConfig config,
  ADIFDocument document
) @safe;

alias ADIFValidateDelegate = ADIFResult delegate(
  ADIFConfig config,
  ADIFDocument document
) @safe;

interface IADIFService {
  bool configure(ADIFConfig config);
  ADIFConfig config() const;

  bool setParseProvider(ADIFParseDelegate provider);
  bool setSerializeProvider(ADIFSerializeDelegate provider);
  bool setValidateProvider(ADIFValidateDelegate provider);

  ADIFDocument parseDocument(string payload);
  string serializeDocument(ADIFDocument document);
  ADIFResult validateDocument(ADIFDocument document);

  bool parseDocumentAsync(string payload, ADIFDocumentHandler handler);
  bool serializeDocumentAsync(ADIFDocument document, ADIFResultHandler handler);

  ADIFRecord[] parseRecords(string payload);
  string normalizeFieldName(string fieldName);
}