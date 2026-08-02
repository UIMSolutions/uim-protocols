/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.as2.service;

import std.conv : to;
import std.datetime : Clock, UTC;

import vibe.d : runTask;

import uim.as2;

mixin(ShowModule!());

@safe:

class UIMAS2Service : UIMObject, IAS2Service {
  private AS2Config _config;
  private bool _configured;

  private AS2SendDelegate _sendProvider;
  private AS2EncodeDelegate _encodeProvider;
  private AS2DecodeDelegate _decodeProvider;
  private AS2MdnDelegate _mdnProvider;

  bool configure(AS2Config config) {
    if (config.localAs2Id.length == 0 || config.remoteAs2Id.length == 0) {
      _configured = false;
      return false;
    }

    _config = config;
    _configured = true;
    return true;
  }

  AS2Config config() const {
    return _config;
  }

  bool setSendProvider(AS2SendDelegate provider) {
    _sendProvider = provider;
    return true;
  }

  bool setEncodeProvider(AS2EncodeDelegate provider) {
    _encodeProvider = provider;
    return true;
  }

  bool setDecodeProvider(AS2DecodeDelegate provider) {
    _decodeProvider = provider;
    return true;
  }

  bool setMdnProvider(AS2MdnDelegate provider) {
    _mdnProvider = provider;
    return true;
  }

  AS2Result validateMessage(AS2Message message) {
    if (!_configured) {
      return AS2ResultErr(412, "AS2 service is not configured.");
    }

    auto normalized = normalizeMessage(message);
    return as2ValidateMessage(_config, normalized);
  }

  AS2Result sendMessage(AS2Message message) {
    if (!_configured) {
      return AS2ResultErr(412, "AS2 service is not configured.");
    }

    auto normalized = normalizeMessage(message);
    auto validation = as2ValidateMessage(_config, normalized);
    if (!validation.success) {
      return validation;
    }

    if (_sendProvider !is null) {
      try {
        return _sendProvider(_config, normalized);
      } catch (Exception ex) {
        return AS2ResultErr(500, ex.msg, normalized.messageId, normalized.mic);
      }
    }

    auto encoded = encodeMimePayload(normalized);
    if (encoded.length == 0) {
      return AS2ResultErr(500, "AS2 MIME encoding failed.", normalized.messageId, normalized.mic);
    }

    if (_config.requestMdn) {
      auto mdn = buildMdn(normalized, true, "Message accepted");
      return AS2ResultOk(202, "sent with mdn", normalized.messageId, mdn.mic);
    }

    return AS2ResultOk(202, "sent", normalized.messageId, normalized.mic);
  }

  string encodeMimePayload(AS2Message message) {
    if (!_configured) {
      return "";
    }

    auto normalized = normalizeMessage(message);

    if (_encodeProvider !is null) {
      try {
        return _encodeProvider(_config, normalized);
      } catch (Exception) {
        return "";
      }
    }

    return as2EncodeMimePayload(_config, normalized);
  }

  AS2Message decodeMimePayload(string mimePayload) {
    if (!_configured || mimePayload.length == 0) {
      return AS2MessageEmpty();
    }

    if (_decodeProvider !is null) {
      try {
        return _decodeProvider(_config, mimePayload);
      } catch (Exception) {
        return AS2MessageEmpty();
      }
    }

    return as2DecodeMimePayload(mimePayload);
  }

  AS2Result buildMdn(AS2Message original, bool accepted, string details = "") {
    if (!_configured) {
      return AS2ResultErr(412, "AS2 service is not configured.");
    }

    auto normalized = normalizeMessage(original);

    if (_mdnProvider !is null) {
      try {
        return _mdnProvider(_config, normalized, accepted, details);
      } catch (Exception ex) {
        return AS2ResultErr(500, ex.msg, normalized.messageId, normalized.mic);
      }
    }

    return as2BuildMdn(_config, normalized, accepted, details);
  }

  string normalizeAs2Id(string value) {
    return as2NormalizeAs2Id(value);
  }

  bool sendMessageAsync(AS2Message message, AS2ResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localMessage = message;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(sendMessage(localMessage));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool encodeMimePayloadAsync(AS2Message message, AS2ResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localMessage = message;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          auto encoded = encodeMimePayload(localMessage);
          if (encoded.length > 0) {
            auto normalized = normalizeMessage(localMessage);
            localHandler(AS2ResultOk(200, "encoded", normalized.messageId, normalized.mic));
          } else {
            localHandler(AS2ResultErr(400, "encoding failed"));
          }
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  private AS2Message normalizeMessage(AS2Message message) {
    if (message.fromAs2Id.length == 0) {
      message.fromAs2Id = _config.localAs2Id;
    }

    if (message.toAs2Id.length == 0) {
      message.toAs2Id = _config.remoteAs2Id;
    }

    message.fromAs2Id = as2NormalizeAs2Id(message.fromAs2Id);
    message.toAs2Id = as2NormalizeAs2Id(message.toAs2Id);

    if (message.messageId.length == 0) {
      message.messageId = defaultMessageId();
    }

    if (message.subject.length == 0) {
      message.subject = "AS2 message";
    }

    if (message.contentType.length == 0) {
      message.contentType = "application/edi-x12";
    }

    if (message.mic.length == 0) {
      message.mic = as2CalculateMic(_config, message);
    }

    if (_config.signMessages && !message.signed) {
      message.signed = true;
    }

    if (_config.encryptMessages && !message.encrypted) {
      message.encrypted = true;
    }

    if (_config.compressMessages && !message.compressed) {
      message.compressed = true;
    }

    return message;
  }

  private string defaultMessageId() const {
    return "AS2-" ~ Clock.currTime(UTC()).toUnixTime().to!string;
  }
}

IAS2Service AS2Service() {
  return new UIMAS2Service();
}

unittest {
  auto service = AS2Service();

  AS2Config config;
  config.localAs2Id = "my-as2";
  config.remoteAs2Id = "partner-as2";
  config.endpointUrl = "https://partner.example.com/as2";
  assert(service.configure(config));

  auto message = AS2MessageOf("ISA*00*", "my-as2", "partner-as2", "PO-100");
  message.headers ~= AS2HeaderOf("Disposition-Notification-To", "mailto:edi@example.com");

  auto validation = service.validateMessage(message);
  assert(validation.success);

  auto mimePayload = service.encodeMimePayload(message);
  assert(mimePayload.length > 0);

  auto decoded = service.decodeMimePayload(mimePayload);
  assert(decoded.payload.length > 0);

  auto sent = service.sendMessage(message);
  assert(sent.success);

  auto mdn = service.buildMdn(message, true, "Message accepted");
  assert(mdn.success);
}
