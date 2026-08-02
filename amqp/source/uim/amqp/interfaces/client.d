/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.amqp.interfaces.client;

@safe:

enum AMQPDeliveryMode : ubyte {
  transient_ = 1,
  persistent = 2
}

struct AMQPConfig {
  string host = "localhost";
  ushort port = 5672;
  string virtualHost = "/";
  string username = "guest";
  string password = "guest";

  string exchangeName = "";
  string queueName = "";
  string routingKey = "";

  bool durableQueue = true;
  bool autoDeleteQueue;
  bool tlsEnabled;
  bool strictMode = true;
  ushort heartbeatSeconds = 60;
}

struct AMQPHeader {
  string key;
  string value;
}

struct AMQPBinding {
  string exchange;
  string queue;
  string routingKey;
  bool durable = true;
  bool autoDelete;
}

struct AMQPMessage {
  string exchange;
  string routingKey;
  string queue;
  string body;

  string messageId;
  string correlationId;
  ulong timestampUnix;

  AMQPDeliveryMode deliveryMode = AMQPDeliveryMode.persistent;
  AMQPHeader[] headers;
}

struct AMQPPublishResult {
  bool success;
  ushort statusCode;
  string message;

  string exchange;
  string routingKey;
  string queue;
  string messageId;
}

alias AMQPMessageHandler = void delegate(AMQPMessage message) @safe;
alias AMQPPublishResultHandler = void delegate(AMQPPublishResult result) @safe;
alias AMQPBindingHandler = void delegate(AMQPBinding binding) @safe;

alias AMQPPublishDelegate = AMQPPublishResult delegate(AMQPConfig config, AMQPMessage message) @safe;
alias AMQPEncodeDelegate = string delegate(AMQPConfig config, AMQPMessage message) @safe;
alias AMQPDecodeDelegate = AMQPMessage delegate(AMQPConfig config, string frame) @safe;

interface IAMQPService {
  bool configure(AMQPConfig config);
  AMQPConfig config() const;

  bool setPublishProvider(AMQPPublishDelegate provider);
  bool setEncodeProvider(AMQPEncodeDelegate provider);
  bool setDecodeProvider(AMQPDecodeDelegate provider);

  AMQPPublishResult publish(AMQPMessage message);
  AMQPPublishResult validateMessage(AMQPMessage message);

  string encodeFrame(AMQPMessage message);
  AMQPMessage decodeFrame(string frame);

  AMQPBinding bindingFromConfig();
  string normalizeRoutingKey(string value);

  bool publishAsync(AMQPMessage message, AMQPPublishResultHandler handler);
  bool encodeFrameAsync(AMQPMessage message, AMQPPublishResultHandler handler);
}
