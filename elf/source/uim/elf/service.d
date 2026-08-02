/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.elf.service;

import vibe.d : runTask;

import uim.elf;

mixin(ShowModule!());

@safe:

class UIMELFService : UIMObject, IELFService {
  private ELFConfig _config;
  private bool _configured;

  private ELFParseDelegate _parseProvider;
  private ELFSerializeDelegate _serializeProvider;
  private ELFValidateDelegate _validateProvider;

  bool configure(ELFConfig config) {
    if (config.elfVersion.length == 0) {
      _configured = false;
      return false;
    }

    _config = config;
    _configured = true;
    return true;
  }

  ELFConfig config() const {
    return _config;
  }

  bool setParseProvider(ELFParseDelegate provider) {
    _parseProvider = provider;
    return true;
  }

  bool setSerializeProvider(ELFSerializeDelegate provider) {
    _serializeProvider = provider;
    return true;
  }

  bool setValidateProvider(ELFValidateDelegate provider) {
    _validateProvider = provider;
    return true;
  }

  ELFDocument parseDocument(string payload) {
    if (!_configured || payload.length == 0) {
      return ELFDocumentEmpty();
    }

    if (_parseProvider !is null) {
      try {
        return _parseProvider(_config, payload);
      } catch (Exception) {
        return ELFDocumentEmpty();
      }
    }

    return elfParseDocument(payload, _config);
  }

  string serializeDocument(ELFDocument document) {
    if (!_configured || document.records.length == 0) {
      return "";
    }

    if (_serializeProvider !is null) {
      try {
        return _serializeProvider(_config, document);
      } catch (Exception) {
        return "";
      }
    }

    return elfSerializeDocument(document, _config);
  }

  ELFResult validateDocument(ELFDocument document) {
    if (!_configured) {
      return ELFResultErr(412, "ELF service is not configured.");
    }

    if (_validateProvider !is null) {
      try {
        return _validateProvider(_config, document);
      } catch (Exception ex) {
        return ELFResultErr(500, ex.msg);
      }
    }

    return elfValidateDocument(document, _config);
  }

  bool parseDocumentAsync(string payload, ELFDocumentHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localPayload = payload;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(parseDocument(localPayload));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool serializeDocumentAsync(ELFDocument document, ELFResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localDocument = document;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          auto payload = serializeDocument(localDocument);
          if (payload.length > 0) {
            localHandler(ELFResultOk(200, "serialized", cast(ulong) localDocument.records.length));
          } else {
            localHandler(ELFResultErr(400, "serialization failed"));
          }
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  ELFRecord[] parseRecords(string payload) {
    return elfParseRecords(payload, _config);
  }

  string normalizeDirective(string value) {
    return elfNormalizeDirective(value);
  }
}

IELFService ELFService() {
  return new UIMELFService();
}

unittest {
  auto service = ELFService();

  ELFConfig config;
  assert(service.configure(config));

  auto payload = "#Version: 1.0\n#Fields date time c-ip cs-method cs-uri\n2026-07-30 12:00:00 127.0.0.1 GET /index.html\n";
  auto document = service.parseDocument(payload);
  assert(document.records.length == 1);

  auto result = service.validateDocument(document);
  assert(result.success);

  auto encoded = service.serializeDocument(document);
  assert(encoded.length > 0);
}