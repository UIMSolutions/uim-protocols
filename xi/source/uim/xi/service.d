/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.xi.service;

import std.conv : to;
import std.datetime : Clock, UTC;

import vibe.d : runTask;

import uim.xi;

mixin(ShowModule!());

@safe:

class UIMXIService : UIMObject, IXIService {
  private XIConfig _config;
  private bool _configured;

  private XISendDelegate _sendProvider;
  private XIEncodeDelegate _encodeProvider;
  private XIDecodeDelegate _decodeProvider;
  private XIAckDelegate _ackProvider;

  bool configure(XIConfig config) {
    if (config.senderService.length == 0 || config.receiverService.length == 0) {
      _configured = false;
      return false;
    }

    _config = config;
    _configured = true;
    return true;
  }

  XIConfig config() const {
    return _config;
  }

  bool setSendProvider(XISendDelegate provider) {
    _sendProvider = provider;
    return true;
  }

  bool setEncodeProvider(XIEncodeDelegate provider) {
    _encodeProvider = provider;
    return true;
  }

  bool setDecodeProvider(XIDecodeDelegate provider) {
    _decodeProvider = provider;
    return true;
  }

  bool setAckProvider(XIAckDelegate provider) {
    _ackProvider = provider;
    return true;
  }

  XIResult validateMessage(XIMessage message) {
    if (!_configured) {
      return XIResultErr(412, "XI service is not configured.");
    }

    auto normalized = normalizeMessage(message);
    return xiValidateMessage(_config, normalized);
  }

  XIResult sendMessage(XIMessage message) {
    if (!_configured) {
      return XIResultErr(412, "XI service is not configured.");
    }

    auto normalized = normalizeMessage(message);
    auto validation = xiValidateMessage(_config, normalized);
    if (!validation.success) {
      return validation;
    }

    if (_sendProvider !is null) {
      try {
        return _sendProvider(_config, normalized);
      } catch (Exception ex) {
        return XIResultErr(500, ex.msg, normalized.messageId);
      }
    }

    auto encoded = encodeSoapEnvelope(normalized);
    if (encoded.length == 0) {
      return XIResultErr(500, "XI SOAP encoding failed.", normalized.messageId);
    }

    auto ack = buildAcknowledgement(normalized, true, "Processed by default XI flow");
    return XIResultOk(202, "queued", ack.messageId);
  }

  string encodeSoapEnvelope(XIMessage message) {
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

    return xiEncodeSoapEnvelope(_config, normalized);
  }

  XIMessage decodeSoapEnvelope(string soapEnvelope) {
    if (!_configured || soapEnvelope.length == 0) {
      return XIMessageEmpty();
    }

    if (_decodeProvider !is null) {
      try {
        return _decodeProvider(_config, soapEnvelope);
      } catch (Exception) {
        return XIMessageEmpty();
      }
    }

    return xiDecodeSoapEnvelope(soapEnvelope);
  }

  XIResult buildAcknowledgement(XIMessage original, bool accepted, string details = "") {
    if (!_configured) {
      return XIResultErr(412, "XI service is not configured.");
    }

    auto normalized = normalizeMessage(original);

    if (_ackProvider !is null) {
      try {
        return _ackProvider(_config, normalized, accepted, details);
      } catch (Exception ex) {
        return XIResultErr(500, ex.msg, normalized.messageId);
      }
    }

    return xiBuildAcknowledgement(normalized, accepted, details);
  }

  string normalizeIdentifier(string value) {
    return xiNormalizeIdentifier(value);
  }

  bool sendMessageAsync(XIMessage message, XIResultHandler handler) {
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

  bool encodeSoapEnvelopeAsync(XIMessage message, XIResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localMessage = message;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          auto encoded = encodeSoapEnvelope(localMessage);
          if (encoded.length > 0) {
            auto normalized = normalizeMessage(localMessage);
            localHandler(XIResultOk(200, "encoded", normalized.messageId));
          } else {
            localHandler(XIResultErr(400, "encoding failed"));
          }
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  private XIMessage normalizeMessage(XIMessage message) {
    if (message.sender.service.length == 0) {
      message.sender.service = _config.senderService;
    }

    if (message.receiver.service.length == 0) {
      message.receiver.service = _config.receiverService;
    }

    message.sender.service = xiNormalizeIdentifier(message.sender.service);
    message.receiver.service = xiNormalizeIdentifier(message.receiver.service);

    if (message.interfaceName.length == 0) {
      message.interfaceName = _config.interfaceName;
    }

    if (message.interfaceNamespace.length == 0) {
      message.interfaceNamespace = _config.interfaceNamespace;
    }

    if (message.action.length == 0) {
      message.action = xiBuildAction(message);
    }

    if (message.messageId.length == 0) {
      message.messageId = defaultMessageId();
    }

    if (message.conversationId.length == 0) {
      message.conversationId = defaultConversationId();
    }

    if (message.contentType.length == 0) {
      message.contentType = "application/xml";
    }

    return message;
  }

  private string defaultMessageId() const {
    return "XI-" ~ Clock.currTime(UTC()).toUnixTime().to!string;
  }

  private string defaultConversationId() const {
    return "CONV-" ~ Clock.currTime(UTC()).toUnixTime().to!string;
  }
}

IXIService XIService() {
  return new UIMXIService();
}

unittest {
  auto service = XIService();

  XIConfig config;
  config.senderService = "ERP";
  config.receiverService = "CLOUD";
  config.interfaceName = "OrderSync";
  config.interfaceNamespace = "urn:example:orders";
  config.endpointUrl = "https://integration.example.com/xi";
  assert(service.configure(config));

  auto message = XIMessageOf("<Order id=\"1\"/>", "ERP", "CLOUD", "OrderSync");
  message.interfaceNamespace = "urn:example:orders";
  message.headers ~= XIHeaderOf("SAP-MessageType", "Application");

  auto validated = service.validateMessage(message);
  assert(validated.success);

  auto envelope = service.encodeSoapEnvelope(message);
  assert(envelope.length > 0);

  auto decoded = service.decodeSoapEnvelope(envelope);
  assert(decoded.payload.length > 0);

  auto sent = service.sendMessage(message);
  assert(sent.success);

  auto ack = service.buildAcknowledgement(message, true, "OK");
  assert(ack.success);
}
