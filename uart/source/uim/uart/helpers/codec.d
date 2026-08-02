/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.uart.helpers.codec;

import std.array : appender;
import std.conv : to;
import std.string : indexOf, split, strip;

import uim.uart.interfaces;
import uim.uart.models;

@safe:

string uartNormalizePortName(string value) {
  return value.strip();
}

string uartParityName(UARTParity value) {
  final switch (value) {
    case UARTParity.none:
      return "none";
    case UARTParity.even:
      return "even";
    case UARTParity.odd:
      return "odd";
    case UARTParity.mark:
      return "mark";
    case UARTParity.space:
      return "space";
  }
}

string uartStopBitsName(UARTStopBits value) {
  final switch (value) {
    case UARTStopBits.one:
      return "1";
    case UARTStopBits.oneHalf:
      return "1.5";
    case UARTStopBits.two:
      return "2";
  }
}

UARTParity uartParseParity(string value) {
  auto normalized = value.strip();

  switch (normalized) {
    case "even":
      return UARTParity.even;
    case "odd":
      return UARTParity.odd;
    case "mark":
      return UARTParity.mark;
    case "space":
      return UARTParity.space;
    default:
      return UARTParity.none;
  }
}

UARTStopBits uartParseStopBits(string value) {
  auto normalized = value.strip();

  switch (normalized) {
    case "1.5":
      return UARTStopBits.oneHalf;
    case "2":
      return UARTStopBits.two;
    default:
      return UARTStopBits.one;
  }
}

UARTResult uartValidateConfig(UARTConfig config) {
  auto portName = uartNormalizePortName(config.portName);
  if (portName.length == 0) {
    return UARTResultErr(422, "UART port name is empty.");
  }

  if (config.baudRate == 0) {
    return UARTResultErr(422, "UART baud rate must be greater than zero.", portName);
  }

  if (config.dataBits < 5 || config.dataBits > 8) {
    return UARTResultErr(422, "UART data bits must be between 5 and 8.", portName);
  }

  if (config.readChunkSize == 0) {
    return UARTResultErr(422, "UART read chunk size must be greater than zero.", portName);
  }

  return UARTResultOk(200, "validated", portName);
}

UARTFrame uartNormalizeFrame(UARTConfig config, UARTFrame frame) {
  if (frame.portName.length == 0) {
    frame.portName = config.portName;
  }

  frame.portName = uartNormalizePortName(frame.portName);

  if (frame.timestampUnix == 0) {
    frame.timestampUnix = 1;
  }

  if (frame.terminated && config.lineEnding.length > 0) {
    auto suffix = uartTextToBytes(config.lineEnding);
    if (!uartHasSuffix(frame.payload, suffix)) {
      frame.payload ~= suffix;
    }
  }

  return frame;
}

UARTResult uartValidateFrame(UARTConfig config, UARTFrame frame) {
  auto configResult = uartValidateConfig(config);
  if (!configResult.success) {
    return configResult;
  }

  auto portName = frame.portName.length > 0 ? frame.portName : config.portName;
  portName = uartNormalizePortName(portName);

  if (config.strictMode && portName.length == 0) {
    return UARTResultErr(422, "UART frame requires a port name in strict mode.");
  }

  if (config.strictMode && frame.payload.length == 0) {
    return UARTResultErr(422, "UART frame payload is empty.", portName, 0, frame.correlationId);
  }

  return UARTResultOk(200, "validated", portName, frame.payload.length, frame.correlationId);
}

string uartEncodeFrame(UARTConfig config, UARTFrame frame) {
  auto normalized = uartNormalizeFrame(config, frame);

  auto buffer = appender!string();
  buffer.put("UART/1.0\n");

  buffer.put("port=");
  buffer.put(normalized.portName);
  buffer.put("\n");

  buffer.put("baud=");
  buffer.put(config.baudRate.to!string);
  buffer.put("\n");

  buffer.put("data_bits=");
  buffer.put(config.dataBits.to!string);
  buffer.put("\n");

  buffer.put("parity=");
  buffer.put(uartParityName(config.parity));
  buffer.put("\n");

  buffer.put("stop_bits=");
  buffer.put(uartStopBitsName(config.stopBits));
  buffer.put("\n");

  buffer.put("terminated=");
  buffer.put(normalized.terminated ? "true" : "false");
  buffer.put("\n");

  buffer.put("timestamp=");
  buffer.put(normalized.timestampUnix.to!string);
  buffer.put("\n");

  buffer.put("correlation_id=");
  buffer.put(normalized.correlationId);
  buffer.put("\n\n");

  buffer.put(uartBytesToHex(normalized.payload));
  return buffer.data;
}

UARTFrame uartDecodeFrame(string encodedFrame) {
  auto chunks = split(encodedFrame, "\n\n");
  if (chunks.length == 0) {
    return UARTFrameEmpty();
  }

  auto meta = chunks[0];
  auto lines = split(meta, "\n");

  UARTFrame frame;

  if (chunks.length > 1) {
    frame.payload = uartHexToBytes(chunks[1]);
  }

  foreach (line; lines) {
    auto trimmed = line.strip();
    if (trimmed.length == 0 || trimmed == "UART/1.0") {
      continue;
    }

    auto separator = trimmed.indexOf("=");
    if (separator <= 0) {
      continue;
    }

    auto key = trimmed[0 .. separator].strip();
    auto value = trimmed[separator + 1 .. $].strip();

    switch (key) {
      case "port":
        frame.portName = value;
        break;
      case "terminated":
        frame.terminated = value == "true";
        break;
      case "timestamp":
        if (value.length > 0) {
          try {
            frame.timestampUnix = value.to!ulong;
          } catch (Exception) {
          }
        }
        break;
      case "correlation_id":
        frame.correlationId = value;
        break;
      default:
        break;
    }
  }

  return frame;
}

ubyte[] uartTextToBytes(string value) {
  ubyte[] payload;
  foreach (ch; value) {
    payload ~= cast(ubyte) ch;
  }

  return payload;
}

private bool uartHasSuffix(const(ubyte)[] payload, const(ubyte)[] suffix) {
  if (suffix.length == 0) {
    return true;
  }

  if (payload.length < suffix.length) {
    return false;
  }

  auto start = payload.length - suffix.length;
  foreach (index, value; suffix) {
    if (payload[start + index] != value) {
      return false;
    }
  }

  return true;
}

private string uartBytesToHex(const(ubyte)[] payload) {
  auto buffer = appender!string();
  foreach (value; payload) {
    buffer.put(uartHexDigit((value >> 4) & 0x0F));
    buffer.put(uartHexDigit(value & 0x0F));
  }

  return buffer.data;
}

private ubyte[] uartHexToBytes(string value) {
  auto cleaned = value.strip();
  ubyte[] payload;

  if (cleaned.length == 0 || cleaned.length % 2 != 0) {
    return payload;
  }

  for (size_t index = 0; index < cleaned.length; index += 2) {
    auto high = uartHexValue(cleaned[index]);
    auto low = uartHexValue(cleaned[index + 1]);
    if (high < 0 || low < 0) {
      ubyte[] empty;
      return empty;
    }

    payload ~= cast(ubyte) ((high << 4) | low);
  }

  return payload;
}

private char uartHexDigit(ubyte value) {
  return value < 10
    ? cast(char) ('0' + value)
    : cast(char) ('A' + (value - 10));
}

private int uartHexValue(char ch) {
  if (ch >= '0' && ch <= '9') {
    return ch - '0';
  }

  if (ch >= 'A' && ch <= 'F') {
    return ch - 'A' + 10;
  }

  if (ch >= 'a' && ch <= 'f') {
    return ch - 'a' + 10;
  }

  return -1;
}

unittest {
  UARTConfig config;
  config.portName = "/dev/ttyUSB0";
  config.lineEnding = "\r\n";

  auto frame = UARTFrameOf("AT", config.portName);
  frame.terminated = true;
  frame.correlationId = "c-1";

  auto normalized = uartNormalizeFrame(config, frame);
  assert(normalized.payload.length == 4);

  auto encoded = uartEncodeFrame(config, frame);
  assert(encoded.indexOf("UART/1.0") == 0);

  auto decoded = uartDecodeFrame(encoded);
  assert(decoded.portName == config.portName);
  assert(UARTPayloadText(decoded) == "AT\r\n");

  auto result = uartValidateFrame(config, decoded);
  assert(result.success);
}