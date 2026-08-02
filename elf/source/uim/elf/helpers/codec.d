/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.elf.helpers.codec;

import std.array : appender;
import std.string : indexOf, split, strip;

import uim.elf.interfaces;
import uim.elf.models;

@safe:

string elfNormalizeDirective(string value) {
  auto trimmed = value.strip();
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

ELFDocument elfParseDocument(string payload, ELFConfig config) {
  ELFDocument document;
  string[] fields;

  foreach (line; payload.split("\n")) {
    auto trimmed = line.strip();

    if (trimmed.length == 0) {
      continue;
    }

    if (trimmed[0] == '#') {
      auto directive = parseDirectiveLine(trimmed);
      if (directive.name.length > 0) {
        document.directives ~= directive;

        if (directive.name == "FIELDS") {
          fields = directive.values.dup;
        }
      } else if (config.preserveCommentLines) {
        document.comments ~= trimmed;
      }

      continue;
    }

    if (fields.length == 0) {
      if (config.strictMode) {
        return ELFDocumentEmpty();
      }
      continue;
    }

    auto values = trimmed.split(" ");
    if (values.length != fields.length) {
      if (config.strictMode) {
        return ELFDocumentEmpty();
      }

      continue;
    }

    ELFRecord record;
    foreach (index, fieldName; fields) {
      record.fields[fieldName] = values[index];
    }

    document.records ~= record;
  }

  return document;
}

ELFRecord[] elfParseRecords(string payload, ELFConfig config) {
  return elfParseDocument(payload, config).records;
}

string elfSerializeDirective(const(ELFDirective) directive) {
  auto buffer = appender!string();
  buffer.put("#");
  buffer.put(directive.name);

  foreach (value; directive.values) {
    buffer.put(" ");
    buffer.put(value);
  }

  return buffer.data;
}

string elfSerializeDocument(ELFDocument document, ELFConfig config) {
  auto buffer = appender!string();
  string[] fields = extractFields(document.directives);

  if (config.includeHeader) {
    if (!hasDirective(document.directives, "VERSION")) {
      buffer.put("#Version: ");
      buffer.put(config.elfVersion.length > 0 ? config.elfVersion : "1.0");
      buffer.put("\n");
    }

    foreach (directive; document.directives) {
      buffer.put(elfSerializeDirective(directive));
      buffer.put("\n");
    }

    foreach (comment; document.comments) {
      if (comment.length > 0 && comment[0] == '#') {
        buffer.put(comment);
      } else {
        buffer.put("#");
        buffer.put(comment);
      }
      buffer.put("\n");
    }
  }

  if (fields.length == 0 && document.records.length > 0) {
    fields = inferFields(document.records[0]);
    if (fields.length > 0) {
      buffer.put("#Fields");
      foreach (fieldName; fields) {
        buffer.put(" ");
        buffer.put(fieldName);
      }
      buffer.put("\n");
    }
  }

  foreach (record; document.records) {
    buffer.put(serializeRecord(record, fields));
    buffer.put("\n");
  }

  return buffer.data;
}

ELFResult elfValidateDocument(ELFDocument document, ELFConfig config) {
  if (document.records.length == 0) {
    return ELFResultErr(422, "ELF document does not contain records.");
  }

  auto fields = extractFields(document.directives);
  if (fields.length == 0) {
    return ELFResultErr(422, "ELF document is missing #Fields directive.");
  }

  ulong fieldCount;

  foreach (recordIndex, record; document.records) {
    if (record.fields.length == 0) {
      return ELFResultErr(422, "ELF record has no values.", cast(ulong) (recordIndex + 1), fieldCount);
    }

    foreach (fieldName; fields) {
      fieldCount++;
      if (!(fieldName in record.fields)) {
        return ELFResultErr(422, "ELF record is missing required field " ~ fieldName ~ ".", cast(ulong) (recordIndex + 1), fieldCount);
      }
    }

    if (config.strictMode && !allFieldKeysAllowed(record.fields, fields)) {
      return ELFResultErr(422, "ELF record contains fields not declared in #Fields.", cast(ulong) (recordIndex + 1), fieldCount);
    }
  }

  return ELFResultOk(200, "validated", cast(ulong) document.records.length, fieldCount);
}

private ELFDirective parseDirectiveLine(string line) {
  ELFDirective directive;

  auto content = line[1 .. $].strip();
  if (content.length == 0) {
    return directive;
  }

  auto separator = content.indexOf(":");
  if (separator >= 0) {
    directive.name = elfNormalizeDirective(content[0 .. separator]);
    auto values = content[separator + 1 .. $].strip();
    if (values.length > 0) {
      directive.values = values.split(" ");
    }
    return directive;
  }

  auto parts = content.split(" ");
  if (parts.length == 0) {
    return directive;
  }

  directive.name = elfNormalizeDirective(parts[0]);
  foreach (index; 1 .. parts.length) {
    auto part = parts[index].strip();
    if (part.length > 0) {
      directive.values ~= part;
    }
  }

  return directive;
}

private string[] extractFields(const(ELFDirective)[] directives) {
  foreach (directive; directives) {
    if (directive.name == "FIELDS") {
      return directive.values.dup;
    }
  }

  return [];
}

private bool hasDirective(const(ELFDirective)[] directives, string name) {
  auto normalized = elfNormalizeDirective(name);
  foreach (directive; directives) {
    if (directive.name == normalized) {
      return true;
    }
  }

  return false;
}

private string[] inferFields(const(ELFRecord) record) {
  string[] result;
  foreach (key, _; record.fields) {
    result ~= key;
  }
  return result;
}

private string serializeRecord(const(ELFRecord) record, const(string)[] orderedFields) {
  auto buffer = appender!string();
  bool first = true;

  if (orderedFields.length > 0) {
    foreach (fieldName; orderedFields) {
      auto value = ELFRecordValue(record, fieldName, "-");
      if (!first) {
        buffer.put(" ");
      }
      buffer.put(value);
      first = false;
    }
    return buffer.data;
  }

  foreach (_, value; record.fields) {
    if (!first) {
      buffer.put(" ");
    }
    buffer.put(value);
    first = false;
  }

  return buffer.data;
}

private bool allFieldKeysAllowed(string[string] fieldMap, const(string)[] allowedFields) {
  foreach (key, _; fieldMap) {
    bool found;
    foreach (allowed; allowedFields) {
      if (key == allowed) {
        found = true;
        break;
      }
    }

    if (!found) {
      return false;
    }
  }

  return true;
}

unittest {
  auto payload = "#Version: 1.0\n#Fields date time c-ip cs-method cs-uri\n2026-07-30 12:00:00 127.0.0.1 GET /index.html\n";
  ELFConfig config;

  auto document = elfParseDocument(payload, config);
  assert(document.records.length == 1);

  auto result = elfValidateDocument(document, config);
  assert(result.success);

  auto encoded = elfSerializeDocument(document, config);
  assert(encoded.indexOf("#Fields") >= 0);
}