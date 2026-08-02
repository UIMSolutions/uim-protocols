/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.as2.models.client;

import std.conv : to;
import std.datetime : Clock, UTC;

import uim.as2;

mixin(ShowModule!());

@safe:

AS2Header AS2HeaderOf(string key, string value) {
  AS2Header header;
  header.key = key;
  header.value = value;
  return header;
}

AS2Message AS2MessageOf(
  string payload,
  string fromAs2Id = "",
  string toAs2Id = "",
  string subject = "AS2 message"
) {
  AS2Message message;
  message.payload = payload;
  message.fromAs2Id = fromAs2Id;
  message.toAs2Id = toAs2Id;
  message.subject = subject;
  message.messageId = "AS2-" ~ Clock.currTime(UTC()).toUnixTime().to!string;
  return message;
}

string AS2HeaderValue(const(AS2Message) message, string key, string fallback = "") {
  foreach (header; message.headers) {
    if (header.key == key) {
      return header.value;
    }
  }

  return fallback;
}

AS2Result AS2ResultOk(
  ushort statusCode = 200,
  string message = "ok",
  string messageId = "",
  string mic = ""
) {
  AS2Result result;
  result.success = true;
  result.statusCode = statusCode;
  result.message = message;
  result.messageId = messageId;
  result.mic = mic;
  result.disposition.mode = "automatic-action";
  result.disposition.type = "processed";
  result.disposition.modifier = "warning";
  return result;
}

AS2Result AS2ResultErr(
  ushort statusCode = 500,
  string message = "error",
  string messageId = "",
  string mic = ""
) {
  AS2Result result;
  result.success = false;
  result.statusCode = statusCode;
  result.message = message;
  result.messageId = messageId;
  result.mic = mic;
  result.disposition.mode = "automatic-action";
  result.disposition.type = "failed";
  result.disposition.modifier = "error";
  return result;
}

AS2Message AS2MessageEmpty() {
  AS2Message message;
  return message;
}

unittest {
  auto message = AS2MessageOf("ISA*00*", "MY-AS2", "PARTNER-AS2");
  assert(message.payload.length > 0);

  message.headers ~= AS2HeaderOf("AS2-Version", "1.2");
  assert(AS2HeaderValue(message, "AS2-Version") == "1.2");

  auto ok = AS2ResultOk(200, "sent", message.messageId, "sha256:abc");
  assert(ok.success);
}
