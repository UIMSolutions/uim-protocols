/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.uart.interfaces.client;

@safe:

enum UARTParity : ubyte {
  none,
  even,
  odd,
  mark,
  space
}

enum UARTStopBits : ubyte {
  one = 1,
  oneHalf = 2,
  two = 3
}

struct UARTConfig {
  string portName = "/dev/ttyS0";
  uint baudRate = 115_200;
  ubyte dataBits = 8;
  UARTParity parity = UARTParity.none;
  UARTStopBits stopBits = UARTStopBits.one;
  bool hardwareFlowControl;
  bool softwareFlowControl;
  size_t readChunkSize = 256;
  bool strictMode = true;
  string lineEnding = "\n";
}

struct UARTFrame {
  string portName;
  ubyte[] payload;
  ulong timestampUnix;
  bool terminated;
  string correlationId;
}

struct UARTResult {
  bool success;
  ushort statusCode;
  string message;
  string portName;
  size_t bytesTransferred;
  string correlationId;
}

alias UARTFrameHandler = void delegate(UARTFrame frame) @safe;
alias UARTResultHandler = void delegate(UARTResult result) @safe;

alias UARTTransmitDelegate = UARTResult delegate(UARTConfig config, UARTFrame frame) @safe;
alias UARTReceiveDelegate = UARTFrame delegate(UARTConfig config, size_t maxBytes) @safe;
alias UARTEncodeDelegate = string delegate(UARTConfig config, UARTFrame frame) @safe;
alias UARTDecodeDelegate = UARTFrame delegate(UARTConfig config, string encodedFrame) @safe;

interface IUARTService {
  bool configure(UARTConfig config);
  UARTConfig config() const;

  bool setTransmitProvider(UARTTransmitDelegate provider);
  bool setReceiveProvider(UARTReceiveDelegate provider);
  bool setEncodeProvider(UARTEncodeDelegate provider);
  bool setDecodeProvider(UARTDecodeDelegate provider);

  UARTResult transmit(UARTFrame frame);
  UARTFrame receive(size_t maxBytes = 0);
  UARTResult validateFrame(UARTFrame frame);

  string encodeFrame(UARTFrame frame);
  UARTFrame decodeFrame(string encodedFrame);

  bool transmitAsync(UARTFrame frame, UARTResultHandler handler);
  bool receiveAsync(size_t maxBytes, UARTFrameHandler handler);
}