/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.xi.interfaces.message;

@safe:

enum XIQualityOfService : ubyte {
  be = 0,
  eo = 1,
  eoio = 2
}

struct XIConfig {
  string senderService;
  string receiverService;
  string interfaceName;
  string interfaceNamespace;

  string adapterType = "XI";
  string endpointUrl;
  bool strictMode = true;
  XIQualityOfService qos = XIQualityOfService.eo;
  bool synchronousMode;
  ushort httpTimeoutSeconds = 30;
}

struct XIHeader {
  string key;
  string value;
}

struct XIAddress {
  string party;
  string service;
}

struct XIMessage {
  string messageId;
  string conversationId;

  XIAddress sender;
  XIAddress receiver;

  string interfaceName;
  string interfaceNamespace;
  string action;

  string contentType = "application/xml";
  string payload;
  XIHeader[] headers;
}

struct XIAck {
  bool accepted;
  string code;
  string description;
}

struct XIResult {
  bool success;
  ushort statusCode;
  string message;

  string messageId;
  XIAck acknowledgement;
}

alias XIMessageHandler = void delegate(XIMessage message) @safe;
alias XIResultHandler = void delegate(XIResult result) @safe;

alias XISendDelegate = XIResult delegate(XIConfig config, XIMessage message) @safe;
alias XIEncodeDelegate = string delegate(XIConfig config, XIMessage message) @safe;
alias XIDecodeDelegate = XIMessage delegate(XIConfig config, string soapEnvelope) @safe;
alias XIAckDelegate = XIResult delegate(XIConfig config, XIMessage original, bool accepted, string details) @safe;

interface IXIService {
  bool configure(XIConfig config);
  XIConfig config() const;

  bool setSendProvider(XISendDelegate provider);
  bool setEncodeProvider(XIEncodeDelegate provider);
  bool setDecodeProvider(XIDecodeDelegate provider);
  bool setAckProvider(XIAckDelegate provider);

  XIResult validateMessage(XIMessage message);
  XIResult sendMessage(XIMessage message);

  string encodeSoapEnvelope(XIMessage message);
  XIMessage decodeSoapEnvelope(string soapEnvelope);

  XIResult buildAcknowledgement(XIMessage original, bool accepted, string details = "");
  string normalizeIdentifier(string value);

  bool sendMessageAsync(XIMessage message, XIResultHandler handler);
  bool encodeSoapEnvelopeAsync(XIMessage message, XIResultHandler handler);
}
