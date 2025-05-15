import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'wyoming_messages.dart';

/// Wyoming Satellite protocol client (pure Dart, cross-platform)
class WyomingClient {
  final String host;
  final int port;
  Socket? _socket;
  StreamController<WyomingMessage> _messageController = StreamController.broadcast();
  final List<int> _buffer = [];

  WyomingClient({required this.host, required this.port});

  Stream<WyomingMessage> get messages => _messageController.stream;

  Future<void> connect() async {
    _socket = await Socket.connect(host, port);
    _socket!.listen(_onData, onDone: disconnect, onError: (e) => disconnect());
  }

  void _onData(List<int> data) {
    // Wyoming protocol: 4-byte length prefix, then JSON or binary message
    _buffer.addAll(data);
    while (_buffer.length >= 4) {
      // Read 4-byte big-endian length
      final lengthBytes = _buffer.sublist(0, 4);
      final length = (lengthBytes[0] << 24) |
          (lengthBytes[1] << 16) |
          (lengthBytes[2] << 8) |
          (lengthBytes[3]);
      if (_buffer.length < 4 + length) {
        // Wait for more data
        break;
      }
      final messageBytes = _buffer.sublist(4, 4 + length);
      _buffer.removeRange(0, 4 + length);
      try {
        // Try to decode as JSON first
        final messageString = utf8.decode(messageBytes, allowMalformed: true);
        if (messageString.trim().startsWith('{')) {
          final json = jsonDecode(messageString);
          // Wyoming event/session message type dispatch
          final type = json['type']?.toString();
          switch (type) {
            case 'audio_start':
              _messageController.add(WyomingAudioStart(sessionId: json['sessionId'] ?? ''));
              break;
            case 'audio_stop':
              _messageController.add(WyomingAudioStop(sessionId: json['sessionId'] ?? ''));
              break;
            case 'vad':
              _messageController.add(WyomingVad(sessionId: json['sessionId'] ?? '', active: json['active'] ?? false));
              break;
            case 'hotword':
              _messageController.add(WyomingHotword(sessionId: json['sessionId'] ?? '', hotword: json['hotword'] ?? ''));
              break;
            case 'transcript':
              _messageController.add(WyomingTranscript(sessionId: json['sessionId'] ?? '', text: json['text'] ?? ''));
              break;
            case 'session':
              _messageController.add(WyomingSession(sessionId: json['sessionId'] ?? '', state: json['state'] ?? ''));
              break;
            default:
              _messageController.add(WyomingJsonMessage.fromJson(json));
          }
        } else {
          // Binary message (audio, etc.)
          final msg = WyomingBinaryMessage(messageBytes);
          _messageController.add(msg);
        }
      } catch (e) {
        // If not JSON, treat as binary
        final msg = WyomingBinaryMessage(messageBytes);
        _messageController.add(msg);
      }
    }
  }

  Future<void> send(WyomingMessage message) async {
    if (_socket == null) throw Exception('Not connected');
    final bytes = message.toBytes();
    _socket!.add(bytes);
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }
}
