/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.elf.interfaces.log;

@safe:

struct ELFConfig {
  string elfVersion = "1.0";
  bool strictMode;
  bool includeHeader = true;
  bool preserveCommentLines = true;
  bool allowUnknownDirective = true;
}

struct ELFDirective {
  string name;
  string[] values;
}

struct ELFRecord {
  string[string] fields;
}

struct ELFDocument {
  ELFDirective[] directives;
  ELFRecord[] records;
  string[] comments;
}

struct ELFResult {
  bool success;
  ushort statusCode;
  string message;
  ulong recordCount;
  ulong fieldCount;
}

alias ELFDocumentHandler = void delegate(ELFDocument document) @safe;
alias ELFResultHandler = void delegate(ELFResult result) @safe;

alias ELFParseDelegate = ELFDocument delegate(ELFConfig config, string payload) @safe;
alias ELFSerializeDelegate = string delegate(ELFConfig config, ELFDocument document) @safe;
alias ELFValidateDelegate = ELFResult delegate(ELFConfig config, ELFDocument document) @safe;

interface IELFService {
  bool configure(ELFConfig config);
  ELFConfig config() const;

  bool setParseProvider(ELFParseDelegate provider);
  bool setSerializeProvider(ELFSerializeDelegate provider);
  bool setValidateProvider(ELFValidateDelegate provider);

  ELFDocument parseDocument(string payload);
  string serializeDocument(ELFDocument document);
  ELFResult validateDocument(ELFDocument document);

  bool parseDocumentAsync(string payload, ELFDocumentHandler handler);
  bool serializeDocumentAsync(ELFDocument document, ELFResultHandler handler);

  ELFRecord[] parseRecords(string payload);
  string normalizeDirective(string value);
}