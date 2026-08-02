/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.as2.interfaces.client;

@safe:

enum AS2MICAlgorithm : ubyte {
  sha1 = 0,
  sha256 = 1,
  sha512 = 2
}

enum AS2TransferEncoding : ubyte {
  binary = 0,
  base64 = 1
}

struct AS2Config {
  string localAs2Id;
  string remoteAs2Id;
  string endpointUrl;

  bool signMessages = true;
  bool encryptMessages = true;
  bool compressMessages;
  bool requestMdn = true;
  bool synchronousMdn = true;

  bool strictMode = true;
  AS2MICAlgorithm micAlgorithm = AS2MICAlgorithm.sha256;
  AS2TransferEncoding transferEncoding = AS2TransferEncoding.binary;
  ushort httpTimeoutSeconds = 30;
}

struct AS2Header {
  string key;
  string value;
}

struct AS2Message {
  string messageId;
  string fromAs2Id;
  string toAs2Id;
  string subject;

  string contentType = "application/edi-x12";
  string payload;
  AS2Header[] headers;

  bool signed;
  bool encrypted;
  bool compressed;

  string mic;
}

struct AS2Disposition {
  string mode = "automatic-action";
  string type = "processed";
  string modifier = "warning";
  string description;
}

struct AS2Result {
  bool success;
  ushort statusCode;
  string message;

  string messageId;
  string mic;
  AS2Disposition disposition;
}

alias AS2MessageHandler = void delegate(AS2Message message) @safe;
alias AS2ResultHandler = void delegate(AS2Result result) @safe;

alias AS2SendDelegate = AS2Result delegate(AS2Config config, AS2Message message) @safe;
alias AS2EncodeDelegate = string delegate(AS2Config config, AS2Message message) @safe;
alias AS2DecodeDelegate = AS2Message delegate(AS2Config config, string mimePayload) @safe;
alias AS2MdnDelegate = AS2Result delegate(AS2Config config, AS2Message original, bool accepted, string details) @safe;

interface IAS2Service {
  bool configure(AS2Config config);
  AS2Config config() const;

  bool setSendProvider(AS2SendDelegate provider);
  bool setEncodeProvider(AS2EncodeDelegate provider);
  bool setDecodeProvider(AS2DecodeDelegate provider);
  bool setMdnProvider(AS2MdnDelegate provider);

  AS2Result validateMessage(AS2Message message);
  AS2Result sendMessage(AS2Message message);

  string encodeMimePayload(AS2Message message);
  AS2Message decodeMimePayload(string mimePayload);

  AS2Result buildMdn(AS2Message original, bool accepted, string details = "");
  string normalizeAs2Id(string value);

  bool sendMessageAsync(AS2Message message, AS2ResultHandler handler);
  bool encodeMimePayloadAsync(AS2Message message, AS2ResultHandler handler);
}
