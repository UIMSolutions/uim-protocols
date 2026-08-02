/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.xi.helpers.codec;

import std.array : appender;
import std.conv : to;
import std.string : indexOf, split, strip;

import uim.xi.interfaces;
import uim.xi.models;

@safe:

string xiNormalizeIdentifier(string value) {
  auto trimmed = value.strip();
  auto buffer = appender!string();

  foreach (ch; trimmed) {
    if (ch == ' ') {
      continue;
    }

    if (ch >= 'a' && ch <= 'z') {
      buffer.put(cast(char) (ch - 32));
    } else {
      buffer.put(ch);
    }
  }

  return buffer.data;
}

string xiQosName(XIQualityOfService qos) {
  final switch (qos) {
    case XIQualityOfService.be:
      return "BE";
    case XIQualityOfService.eo:
      return "EO";
    case XIQualityOfService.eoio:
      return "EOIO";
  }
}

XIResult xiValidateMessage(XIConfig config, XIMessage message) {
  auto senderService = xiNormalizeIdentifier(
    message.sender.service.length > 0 ? message.sender.service : config.senderService
  );
  auto receiverService = xiNormalizeIdentifier(
    message.receiver.service.length > 0 ? message.receiver.service : config.receiverService
  );

  if (message.payload.length == 0) {
    return XIResultErr(422, "XI payload is empty.", message.messageId);
  }

  if (config.strictMode && senderService.length == 0) {
    return XIResultErr(422, "XI sender service is required in strict mode.", message.messageId);
  }

  if (config.strictMode && receiverService.length == 0) {
    return XIResultErr(422, "XI receiver service is required in strict mode.", message.messageId);
  }

  auto iface = message.interfaceName.length > 0 ? message.interfaceName : config.interfaceName;
  if (config.strictMode && iface.length == 0) {
    return XIResultErr(422, "XI interface name is required in strict mode.", message.messageId);
  }

  return XIResultOk(200, "validated", message.messageId);
}

string xiBuildAction(const(XIMessage) message) {
  if (message.action.length > 0) {
    return message.action;
  }

  if (message.interfaceName.length > 0 && message.interfaceNamespace.length > 0) {
    return message.interfaceNamespace ~ "/" ~ message.interfaceName;
  }

  return "XI/Message";
}

string xiEncodeSoapEnvelope(XIConfig config, XIMessage message) {
  auto buffer = appender!string();
  auto qos = xiQosName(config.qos);

  buffer.put("<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n");
  buffer.put("  <soap:Header>\n");
  buffer.put("    <xi:Main xmlns:xi=\"http://sap.com/xi/XI/System\">\n");
  buffer.put("      <xi:MessageId>");
  buffer.put(message.messageId);
  buffer.put("</xi:MessageId>\n");

  buffer.put("      <xi:ConversationId>");
  buffer.put(message.conversationId);
  buffer.put("</xi:ConversationId>\n");

  buffer.put("      <xi:SenderService>");
  buffer.put(xiNormalizeIdentifier(message.sender.service));
  buffer.put("</xi:SenderService>\n");

  buffer.put("      <xi:ReceiverService>");
  buffer.put(xiNormalizeIdentifier(message.receiver.service));
  buffer.put("</xi:ReceiverService>\n");

  buffer.put("      <xi:Interface>");
  buffer.put(message.interfaceName);
  buffer.put("</xi:Interface>\n");

  buffer.put("      <xi:Namespace>");
  buffer.put(message.interfaceNamespace);
  buffer.put("</xi:Namespace>\n");

  buffer.put("      <xi:Action>");
  buffer.put(xiBuildAction(message));
  buffer.put("</xi:Action>\n");

  buffer.put("      <xi:QoS>");
  buffer.put(qos);
  buffer.put("</xi:QoS>\n");
  buffer.put("    </xi:Main>\n");

  foreach (header; message.headers) {
    buffer.put("    <xi:Header name=\"");
    buffer.put(header.key);
    buffer.put("\">\n      ");
    buffer.put(header.value);
    buffer.put("\n    </xi:Header>\n");
  }

  buffer.put("  </soap:Header>\n");
  buffer.put("  <soap:Body>\n");
  buffer.put(message.payload);
  buffer.put("\n  </soap:Body>\n");
  buffer.put("</soap:Envelope>");

  return buffer.data;
}

XIMessage xiDecodeSoapEnvelope(string soapEnvelope) {
  auto trimmed = soapEnvelope.strip();
  if (trimmed.length == 0) {
    return XIMessageEmpty();
  }

  XIMessage message;

  message.messageId = extractTag(trimmed, "xi:MessageId");
  message.conversationId = extractTag(trimmed, "xi:ConversationId");
  message.sender.service = xiNormalizeIdentifier(extractTag(trimmed, "xi:SenderService"));
  message.receiver.service = xiNormalizeIdentifier(extractTag(trimmed, "xi:ReceiverService"));
  message.interfaceName = extractTag(trimmed, "xi:Interface");
  message.interfaceNamespace = extractTag(trimmed, "xi:Namespace");
  message.action = extractTag(trimmed, "xi:Action");

  auto bodyOpen = trimmed.indexOf("<soap:Body>");
  auto bodyClose = trimmed.indexOf("</soap:Body>");
  if (bodyOpen >= 0 && bodyClose > bodyOpen) {
    auto start = bodyOpen + cast(int) "<soap:Body>".length;
    message.payload = trimmed[start .. bodyClose].strip();
  }

  return message;
}

XIResult xiBuildAcknowledgement(XIMessage original, bool accepted, string details) {
  auto result = accepted
    ? XIResultOk(200, "acknowledged", original.messageId)
    : XIResultErr(422, "rejected", original.messageId);

  result.acknowledgement.accepted = accepted;
  result.acknowledgement.code = accepted ? "XI_ACK" : "XI_NACK";
  result.acknowledgement.description = details;

  return result;
}

private string extractTag(string source, string tagName) {
  auto openTag = "<" ~ tagName ~ ">";
  auto closeTag = "</" ~ tagName ~ ">";

  auto start = source.indexOf(openTag);
  auto stop = source.indexOf(closeTag);
  if (start < 0 || stop <= start) {
    return "";
  }

  auto valueStart = start + cast(int) openTag.length;
  return source[valueStart .. stop].strip();
}

unittest {
  XIConfig config;
  config.senderService = "erp";
  config.receiverService = "cloud";
  config.interfaceName = "OrderSync";

  auto message = XIMessageOf("<Order id=\"1\"/>", "erp", "cloud", "OrderSync");
  message.interfaceNamespace = "urn:example:orders";

  auto validated = xiValidateMessage(config, message);
  assert(validated.success);

  auto envelope = xiEncodeSoapEnvelope(config, message);
  assert(envelope.indexOf("<soap:Envelope") == 0);

  auto decoded = xiDecodeSoapEnvelope(envelope);
  assert(decoded.payload.length > 0);

  auto ack = xiBuildAcknowledgement(decoded, true, "Processed");
  assert(ack.success);
}
