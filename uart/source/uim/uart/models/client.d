/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.uart.models.client;

import std.datetime : Clock, UTC;

import uim.uart;

mixin(ShowModule!());

@safe:

UARTFrame UARTFrameOf(string payloadText, string portName = "") {
  UARTFrame frame;
  frame.portName = portName;
  frame.timestampUnix = cast(ulong) Clock.currTime(UTC()).toUnixTime();

  foreach (ch; payloadText) {
    frame.payload ~= cast(ubyte) ch;
  }

  return frame;
}

UARTFrame UARTFrameBytesOf(const(ubyte)[] payload, string portName = "") {
  UARTFrame frame;
  frame.portName = portName;
  frame.timestampUnix = cast(ulong) Clock.currTime(UTC()).toUnixTime();
  frame.payload = uartCloneBytes(payload);
  return frame;
}

string UARTPayloadText(const(UARTFrame) frame) {
  auto text = "";
  foreach (value; frame.payload) {
    text ~= cast(char) value;
  }

  return text;
}

UARTResult UARTResultOk(
  ushort statusCode = 200,
  string message = "ok",
  string portName = "",
  size_t bytesTransferred = 0,
  string correlationId = ""
) {
  UARTResult result;
  result.success = true;
  result.statusCode = statusCode;
  result.message = message;
  result.portName = portName;
  result.bytesTransferred = bytesTransferred;
  result.correlationId = correlationId;
  return result;
}

UARTResult UARTResultErr(
  ushort statusCode = 500,
  string message = "error",
  string portName = "",
  size_t bytesTransferred = 0,
  string correlationId = ""
) {
  UARTResult result;
  result.success = false;
  result.statusCode = statusCode;
  result.message = message;
  result.portName = portName;
  result.bytesTransferred = bytesTransferred;
  result.correlationId = correlationId;
  return result;
}

UARTFrame UARTFrameEmpty() {
  UARTFrame frame;
  return frame;
}

ubyte[] uartCloneBytes(const(ubyte)[] payload) {
  ubyte[] cloned;
  cloned.length = payload.length;

  foreach (index, value; payload) {
    cloned[index] = value;
  }

  return cloned;
}

unittest {
  auto frame = UARTFrameOf("PING", "/dev/ttyUSB0");
  assert(frame.timestampUnix > 0);
  assert(UARTPayloadText(frame) == "PING");

  auto ok = UARTResultOk(202, "queued", frame.portName, frame.payload.length, "job-1");
  assert(ok.success);

  auto bytesFrame = UARTFrameBytesOf([cast(ubyte) 0x50, cast(ubyte) 0x4F], frame.portName);
  assert(bytesFrame.payload.length == 2);
}