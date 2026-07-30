/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.adif.service;

import vibe.d : runTask;

import uim.adif;

mixin(ShowModule!());

@safe:

class UIMADIFService : UIMObject, IADIFService {
  private ADIFConfig _config;
  private bool _configured;

  private ADIFParseDelegate _parseProvider;
  private ADIFSerializeDelegate _serializeProvider;
  private ADIFValidateDelegate _validateProvider;

  bool configure(ADIFConfig config) {
    if (config.adifVersion.length == 0) {
      _configured = false;
      return false;
    }

    _config = config;
    _configured = true;
    return true;
  }

  ADIFConfig config() const {
    return _config;
  }

  bool setParseProvider(ADIFParseDelegate provider) {
    _parseProvider = provider;
    return true;
  }

  bool setSerializeProvider(ADIFSerializeDelegate provider) {
    _serializeProvider = provider;
    return true;
  }

  bool setValidateProvider(ADIFValidateDelegate provider) {
    _validateProvider = provider;
    return true;
  }

  ADIFDocument parseDocument(string payload) {
    if (!_configured || payload.length == 0) {
      return ADIFDocumentEmpty();
    }

    if (_parseProvider !is null) {
      try {
        return _parseProvider(_config, payload);
      } catch (Exception) {
        return ADIFDocumentEmpty();
      }
    }

    return adifParseDocument(payload, _config.strictMode);
  }

  string serializeDocument(ADIFDocument document) {
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

    return adifSerializeDocument(document, _config);
  }

  ADIFResult validateDocument(ADIFDocument document) {
    if (!_configured) {
      return ADIFResultErr(412, "ADIF service is not configured.");
    }

    if (_validateProvider !is null) {
      try {
        return _validateProvider(_config, document);
      } catch (Exception ex) {
        return ADIFResultErr(500, ex.msg);
      }
    }

    if (document.records.length == 0) {
      return ADIFResultErr(422, "ADIF document does not contain any records.");
    }

    ulong fieldCount;

    foreach (index, record; document.records) {
      fieldCount += cast(ulong) record.fields.length;

      if (record.fields.length == 0) {
        return ADIFResultErr(422, "ADIF record has no fields.", cast(ulong) index, fieldCount);
      }

      if (_config.strictMode) {
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

  bool parseDocumentAsync(string payload, ADIFDocumentHandler handler) {
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

  bool serializeDocumentAsync(ADIFDocument document, ADIFResultHandler handler) {
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
            localHandler(ADIFResultOk(200, "serialized", cast(ulong) localDocument.records.length));
          } else {
            localHandler(ADIFResultErr(400, "serialization failed"));
          }
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  ADIFRecord[] parseRecords(string payload) {
    return adifParseRecords(payload, _config.strictMode);
  }

  string normalizeFieldName(string fieldName) {
    return adifNormalizeFieldName(fieldName);
  }
}

IADIFService ADIFService() {
  return new UIMADIFService();
}

unittest {
  auto service = ADIFService();

  ADIFConfig config;
  config.programId = "uim-adif";
  assert(service.configure(config));

  auto payload = "<ADIF_VER:5>3.1.4<PROGRAMID:8>uim-adif<EOH><CALL:6>DL1ABC<QSO_DATE:8:D>20260730<BAND:3>20M<MODE:2>CW<EOR>";
  auto document = service.parseDocument(payload);
  assert(document.records.length == 1);

  auto result = service.validateDocument(document);
  assert(result.success);

  auto serialized = service.serializeDocument(document);
  assert(serialized.length > 0);
}