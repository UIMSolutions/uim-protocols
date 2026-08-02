/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.as2.helpers.codec;

import std.array : appender;
import std.conv : to;
import std.string : indexOf, split, strip;

import uim.as2.interfaces;
import uim.as2.models;

@safe:

string as2NormalizeAs2Id(string value) {
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

string as2MicAlgorithmName(AS2MICAlgorithm algorithm) {
  final switch (algorithm) {
    case AS2MICAlgorithm.sha1:
      return "sha1";
    case AS2MICAlgorithm.sha256:
      return "sha256";
    case AS2MICAlgorithm.sha512:
      return "sha512";
  }
}

AS2Result as2ValidateMessage(AS2Config config, AS2Message message) {
  auto localId = as2NormalizeAs2Id(
    message.fromAs2Id.length > 0 ? message.fromAs2Id : config.localAs2Id
  );
  auto remoteId = as2NormalizeAs2Id(
    message.toAs2Id.length > 0 ? message.toAs2Id : config.remoteAs2Id
  );

  if (message.payload.length == 0) {
    return AS2ResultErr(422, "AS2 payload is empty.", message.messageId);
  }

  if (config.strictMode && localId.length == 0) {
    return AS2ResultErr(422, "AS2 sender id is required in strict mode.", message.messageId);
  }

  if (config.strictMode && remoteId.length == 0) {
    return AS2ResultErr(422, "AS2 receiver id is required in strict mode.", message.messageId);
  }

  if (config.requestMdn && message.messageId.length == 0) {
    return AS2ResultErr(422, "AS2 message id is required when MDN is requested.", message.messageId);
  }

  return AS2ResultOk(200, "validated", message.messageId, message.mic);
}

string as2CalculateMic(AS2Config config, AS2Message message) {
  auto sizePart = message.payload.length.to!string;
  auto algo = as2MicAlgorithmName(config.micAlgorithm);
  return algo ~ ":" ~ sizePart;
}

string as2EncodeMimePayload(AS2Config config, AS2Message message) {
  auto buffer = appender!string();

  buffer.put("AS2/1.2\n");
  buffer.put("AS2-From: ");
  buffer.put(as2NormalizeAs2Id(message.fromAs2Id));
  buffer.put("\n");

  buffer.put("AS2-To: ");
  buffer.put(as2NormalizeAs2Id(message.toAs2Id));
  buffer.put("\n");

  buffer.put("Message-Id: ");
  buffer.put(message.messageId);
  buffer.put("\n");

  buffer.put("Subject: ");
  buffer.put(message.subject);
  buffer.put("\n");

  buffer.put("Content-Type: ");
  buffer.put(message.contentType);
  buffer.put("\n");

  buffer.put("MIC: ");
  buffer.put(message.mic.length > 0 ? message.mic : as2CalculateMic(config, message));
  buffer.put("\n");

  buffer.put("Signed: ");
  buffer.put(message.signed ? "true" : "false");
  buffer.put("\n");

  buffer.put("Encrypted: ");
  buffer.put(message.encrypted ? "true" : "false");
  buffer.put("\n");

  buffer.put("Compressed: ");
  buffer.put(message.compressed ? "true" : "false");
  buffer.put("\n");

  foreach (header; message.headers) {
    buffer.put(header.key);
    buffer.put(": ");
    buffer.put(header.value);
    buffer.put("\n");
  }

  buffer.put("\n");
  buffer.put(message.payload);
  return buffer.data;
}

AS2Message as2DecodeMimePayload(string mimePayload) {
  auto chunks = split(mimePayload, "\n\n");
  if (chunks.length == 0) {
    return AS2MessageEmpty();
  }

  AS2Message message;
  if (chunks.length > 1) {
    message.payload = chunks[1];
  }

  foreach (line; split(chunks[0], "\n")) {
    auto trimmed = line.strip();
    if (trimmed.length == 0 || trimmed == "AS2/1.2") {
      continue;
    }

    auto separator = trimmed.indexOf(":");
    if (separator <= 0) {
      continue;
    }

    auto key = trimmed[0 .. separator].strip();
    auto value = trimmed[separator + 1 .. $].strip();

    switch (key) {
      case "AS2-From":
        message.fromAs2Id = as2NormalizeAs2Id(value);
        break;
      case "AS2-To":
        message.toAs2Id = as2NormalizeAs2Id(value);
        break;
      case "Message-Id":
        message.messageId = value;
        break;
      case "Subject":
        message.subject = value;
        break;
      case "Content-Type":
        message.contentType = value;
        break;
      case "MIC":
        message.mic = value;
        break;
      case "Signed":
        message.signed = value == "true";
        break;
      case "Encrypted":
        message.encrypted = value == "true";
        break;
      case "Compressed":
        message.compressed = value == "true";
        break;
      default:
        message.headers ~= AS2HeaderOf(key, value);
        break;
    }
  }

  return message;
}

AS2Result as2BuildMdn(AS2Config config, AS2Message original, bool accepted, string details) {
  auto result = accepted
    ? AS2ResultOk(200, "mdn processed", original.messageId, as2CalculateMic(config, original))
    : AS2ResultErr(422, "mdn failed", original.messageId, as2CalculateMic(config, original));

  result.disposition.mode = "automatic-action";
  result.disposition.type = accepted ? "processed" : "failed";
  result.disposition.modifier = accepted ? "warning" : "error";
  result.disposition.description = details;

  return result;
}

unittest {
  AS2Config config;
  config.localAs2Id = "my-as2";
  config.remoteAs2Id = "partner-as2";

  auto message = AS2MessageOf("ISA*00*", "my-as2", "partner-as2", "Order");
  message.signed = true;
  message.encrypted = true;
  message.headers ~= AS2HeaderOf("Disposition-Notification-To", "mailto:edi@example.com");

  auto validation = as2ValidateMessage(config, message);
  assert(validation.success);

  auto encoded = as2EncodeMimePayload(config, message);
  assert(encoded.indexOf("AS2/1.2") == 0);

  auto decoded = as2DecodeMimePayload(encoded);
  assert(decoded.payload.length > 0);
  assert(decoded.fromAs2Id == "MY-AS2");

  auto mdn = as2BuildMdn(config, decoded, true, "Message accepted");
  assert(mdn.success);
}
