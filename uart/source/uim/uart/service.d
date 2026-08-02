/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.uart.service;

import std.datetime : Clock, UTC;

import vibe.d : runTask;

import uim.uart;

mixin(ShowModule!());

@safe:

class UIMUARTService : UIMObject, IUARTService {
  private UARTConfig _config;
  private bool _configured;

  private UARTTransmitDelegate _transmitProvider;
  private UARTReceiveDelegate _receiveProvider;
  private UARTEncodeDelegate _encodeProvider;
  private UARTDecodeDelegate _decodeProvider;

  bool configure(UARTConfig config) {
    auto validation = uartValidateConfig(config);
    if (!validation.success) {
      _configured = false;
      return false;
    }

    _config = config;
    _config.portName = uartNormalizePortName(_config.portName);
    _configured = true;
    return true;
  }

  UARTConfig config() const {
    return _config;
  }

  bool setTransmitProvider(UARTTransmitDelegate provider) {
    _transmitProvider = provider;
    return true;
  }

  bool setReceiveProvider(UARTReceiveDelegate provider) {
    _receiveProvider = provider;
    return true;
  }

  bool setEncodeProvider(UARTEncodeDelegate provider) {
    _encodeProvider = provider;
    return true;
  }

  bool setDecodeProvider(UARTDecodeDelegate provider) {
    _decodeProvider = provider;
    return true;
  }

  UARTResult validateFrame(UARTFrame frame) {
    if (!_configured) {
      return UARTResultErr(412, "UART service is not configured.");
    }

    auto normalized = normalizeFrame(frame);
    return uartValidateFrame(_config, normalized);
  }

  UARTResult transmit(UARTFrame frame) {
    if (!_configured) {
      return UARTResultErr(412, "UART service is not configured.");
    }

    auto normalized = normalizeFrame(frame);
    auto validation = uartValidateFrame(_config, normalized);
    if (!validation.success) {
      return validation;
    }

    if (_transmitProvider !is null) {
      try {
        return _transmitProvider(_config, normalized);
      } catch (Exception ex) {
        return UARTResultErr(500, ex.msg, normalized.portName, 0, normalized.correlationId);
      }
    }

    return UARTResultOk(
      202,
      "transmitted",
      normalized.portName,
      normalized.payload.length,
      normalized.correlationId
    );
  }

  UARTFrame receive(size_t maxBytes = 0) {
    if (!_configured) {
      return UARTFrameEmpty();
    }

    auto chunkSize = maxBytes > 0 ? maxBytes : _config.readChunkSize;

    if (_receiveProvider !is null) {
      try {
        auto frame = _receiveProvider(_config, chunkSize);
        return normalizeReceivedFrame(frame, chunkSize);
      } catch (Exception) {
        return UARTFrameEmpty();
      }
    }

    UARTFrame frame;
    frame.portName = _config.portName;
    frame.timestampUnix = cast(ulong) Clock.currTime(UTC()).toUnixTime();
    return frame;
  }

  string encodeFrame(UARTFrame frame) {
    if (!_configured) {
      return "";
    }

    auto normalized = normalizeFrame(frame);

    if (_encodeProvider !is null) {
      try {
        return _encodeProvider(_config, normalized);
      } catch (Exception) {
        return "";
      }
    }

    return uartEncodeFrame(_config, normalized);
  }

  UARTFrame decodeFrame(string encodedFrame) {
    if (!_configured || encodedFrame.length == 0) {
      return UARTFrameEmpty();
    }

    if (_decodeProvider !is null) {
      try {
        return normalizeFrame(_decodeProvider(_config, encodedFrame));
      } catch (Exception) {
        return UARTFrameEmpty();
      }
    }

    return normalizeFrame(uartDecodeFrame(encodedFrame));
  }

  bool transmitAsync(UARTFrame frame, UARTResultHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localFrame = frame;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(transmit(localFrame));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  bool receiveAsync(size_t maxBytes, UARTFrameHandler handler) {
    if (handler is null) {
      return false;
    }

    auto localMaxBytes = maxBytes;
    auto localHandler = handler;

    (() @trusted {
      runTask(() nothrow {
        try {
          localHandler(receive(localMaxBytes));
        } catch (Exception) {
        }
      });
    })();

    return true;
  }

  private UARTFrame normalizeFrame(UARTFrame frame) const {
    auto normalized = uartNormalizeFrame(_config, frame);
    if (normalized.timestampUnix == 1) {
      normalized.timestampUnix = cast(ulong) Clock.currTime(UTC()).toUnixTime();
    }

    return normalized;
  }

  private UARTFrame normalizeReceivedFrame(UARTFrame frame, size_t maxBytes) const {
    auto normalized = normalizeFrame(frame);
    if (maxBytes > 0 && normalized.payload.length > maxBytes) {
      normalized.payload.length = maxBytes;
    }

    return normalized;
  }
}

IUARTService UARTService() {
  return new UIMUARTService();
}

unittest {
  auto service = UARTService();

  UARTConfig config;
  config.portName = "/dev/ttyUSB0";
  config.baudRate = 9600;
  config.lineEnding = "\n";

  assert(service.configure(config));

  auto frame = UARTFrameOf("PING");
  frame.terminated = true;
  frame.correlationId = "ping-1";

  auto result = service.transmit(frame);
  assert(result.success);
  assert(result.bytesTransferred == 5);

  auto encoded = service.encodeFrame(frame);
  assert(encoded.length > 0);

  auto decoded = service.decodeFrame(encoded);
  assert(decoded.portName == config.portName);
  assert(UARTPayloadText(decoded) == "PING\n");
}