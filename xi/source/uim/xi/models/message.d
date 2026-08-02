/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.xi.models.message;

import std.conv : to;
import std.datetime : Clock, UTC;

import uim.xi;

mixin(ShowModule!());

@safe:

XIHeader XIHeaderOf(string key, string value) {
  XIHeader header;
  header.key = key;
  header.value = value;
  return header;
}

XIAddress XIAddressOf(string party, string service) {
  XIAddress address;
  address.party = party;
  address.service = service;
  return address;
}

XIMessage XIMessageOf(
  string payload,
  string senderService = "",
  string receiverService = "",
  string interfaceName = ""
) {
  XIMessage message;
  message.payload = payload;
  message.sender.service = senderService;
  message.receiver.service = receiverService;
  message.interfaceName = interfaceName;
  auto now = Clock.currTime(UTC()).toUnixTime().to!string;
  message.messageId = "XI-" ~ now;
  message.conversationId = "CONV-" ~ now;
  return message;
}

XIResult XIResultOk(ushort statusCode = 200, string message = "ok", string messageId = "") {
  XIResult result;
  result.success = true;
  result.statusCode = statusCode;
  result.message = message;
  result.messageId = messageId;
  result.acknowledgement.accepted = true;
  result.acknowledgement.code = "XI_OK";
  return result;
}

XIResult XIResultErr(ushort statusCode = 500, string message = "error", string messageId = "") {
  XIResult result;
  result.success = false;
  result.statusCode = statusCode;
  result.message = message;
  result.messageId = messageId;
  result.acknowledgement.accepted = false;
  result.acknowledgement.code = "XI_ERROR";
  return result;
}

XIMessage XIMessageEmpty() {
  XIMessage message;
  return message;
}

unittest {
  auto message = XIMessageOf("<Order/>", "ERP", "CLOUD", "OrderSync");
  assert(message.messageId.length > 0);

  message.headers ~= XIHeaderOf("SAP-MessageType", "Application");
  assert(message.headers.length == 1);

  auto ok = XIResultOk(202, "queued", message.messageId);
  assert(ok.success);
}
