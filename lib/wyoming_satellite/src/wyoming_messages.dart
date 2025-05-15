import 'dart:convert';
import 'dart:typed_data';

/// Base class for Wyoming protocol messages
abstract class WyomingMessage {
  List<int> toBytes();
}

/// Example: Wyoming Text message (for protocol testing)
class WyomingTextMessage extends WyomingMessage {
  final String text;
  WyomingTextMessage(this.text);

  @override
  List<int> toBytes() {
    final payload = utf8.encode(text);
    final length = payload.length;
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming binary message (e.g., audio)
class WyomingBinaryMessage extends WyomingMessage {
  final List<int> data;
  WyomingBinaryMessage(this.data);

  @override
  List<int> toBytes() {
    final length = data.length;
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, length, Endian.big);
    return [...lengthBytes, ...data];
  }
}

/// Wyoming JSON message (for protocol events, etc.)
class WyomingJsonMessage extends WyomingMessage {
  final Map<String, dynamic> json;
  WyomingJsonMessage(this.json);

  factory WyomingJsonMessage.fromJson(Map<String, dynamic> json) => WyomingJsonMessage(json);

  @override
  List<int> toBytes() {
    final payload = utf8.encode(jsonEncode(json));
    final length = payload.length;
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming AudioStart message
class WyomingAudioStart extends WyomingMessage {
  final String sessionId;
  WyomingAudioStart({required this.sessionId});
  @override
  List<int> toBytes() {
    final json = {'type': 'audio_start', 'sessionId': sessionId};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming AudioStop message
class WyomingAudioStop extends WyomingMessage {
  final String sessionId;
  WyomingAudioStop({required this.sessionId});
  @override
  List<int> toBytes() {
    final json = {'type': 'audio_stop', 'sessionId': sessionId};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Vad (Voice Activity Detection) message
class WyomingVad extends WyomingMessage {
  final String sessionId;
  final bool active;
  WyomingVad({required this.sessionId, required this.active});
  @override
  List<int> toBytes() {
    final json = {'type': 'vad', 'sessionId': sessionId, 'active': active};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Hotword message
class WyomingHotword extends WyomingMessage {
  final String sessionId;
  final String hotword;
  WyomingHotword({required this.sessionId, required this.hotword});
  @override
  List<int> toBytes() {
    final json = {'type': 'hotword', 'sessionId': sessionId, 'hotword': hotword};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Transcript message
class WyomingTranscript extends WyomingMessage {
  final String sessionId;
  final String text;
  WyomingTranscript({required this.sessionId, required this.text});
  @override
  List<int> toBytes() {
    final json = {'type': 'transcript', 'sessionId': sessionId, 'text': text};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Session message (for session management)
class WyomingSession extends WyomingMessage {
  final String sessionId;
  final String state;
  WyomingSession({required this.sessionId, required this.state});
  @override
  List<int> toBytes() {
    final json = {'type': 'session', 'sessionId': sessionId, 'state': state};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Event message (generic event)
class WyomingEvent extends WyomingMessage {
  final String event;
  final Map<String, dynamic> data;
  WyomingEvent({required this.event, required this.data});
  @override
  List<int> toBytes() {
    final json = {'type': 'event', 'event': event, 'data': data};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Error message
class WyomingError extends WyomingMessage {
  final String error;
  WyomingError({required this.error});
  @override
  List<int> toBytes() {
    final json = {'type': 'error', 'error': error};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Ready message
class WyomingReady extends WyomingMessage {
  WyomingReady();
  @override
  List<int> toBytes() {
    final json = {'type': 'ready'};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Intent message
class WyomingIntent extends WyomingMessage {
  final String sessionId;
  final String intent;
  final Map<String, dynamic> slots;
  WyomingIntent({required this.sessionId, required this.intent, required this.slots});
  @override
  List<int> toBytes() {
    final json = {'type': 'intent', 'sessionId': sessionId, 'intent': intent, 'slots': slots};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming TTS Audio message
class WyomingTtsAudio extends WyomingMessage {
  final String sessionId;
  final List<int> audio;
  WyomingTtsAudio({required this.sessionId, required this.audio});
  @override
  List<int> toBytes() {
    final json = {'type': 'tts_audio', 'sessionId': sessionId, 'audio': audio};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming TTS End message
class WyomingTtsEnd extends WyomingMessage {
  final String sessionId;
  WyomingTtsEnd({required this.sessionId});
  @override
  List<int> toBytes() {
    final json = {'type': 'tts_end', 'sessionId': sessionId};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming TTS Mark message
class WyomingTtsMark extends WyomingMessage {
  final String sessionId;
  final String mark;
  WyomingTtsMark({required this.sessionId, required this.mark});
  @override
  List<int> toBytes() {
    final json = {'type': 'tts_mark', 'sessionId': sessionId, 'mark': mark};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming TTS Viseme message
class WyomingTtsViseme extends WyomingMessage {
  final String sessionId;
  final int viseme;
  WyomingTtsViseme({required this.sessionId, required this.viseme});
  @override
  List<int> toBytes() {
    final json = {'type': 'tts_viseme', 'sessionId': sessionId, 'viseme': viseme};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}

/// Wyoming Wake message
class WyomingWake extends WyomingMessage {
  final String sessionId;
  WyomingWake({required this.sessionId});
  @override
  List<int> toBytes() {
    final json = {'type': 'wake', 'sessionId': sessionId};
    final payload = utf8.encode(jsonEncode(json));
    final lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, payload.length, Endian.big);
    return [...lengthBytes, ...payload];
  }
}
