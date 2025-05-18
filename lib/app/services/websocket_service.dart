// lib/services/signaling_service.dart
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SignalingService extends GetxService {
  late WebSocketChannel _socket;
  late final String serverUrl;
  // Request tracking
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestId = 0;

  // Observable events for reactive programming
  final Rx<Function(Map<String, dynamic>)?> onNewConsumer =
      Rx<Function(Map<String, dynamic>)?>(null);
  final Rx<Function(Map<String, dynamic>)?> onNewDataConsumer =
      Rx<Function(Map<String, dynamic>)?>(null);
  final Rx<Function(String)?> onPeerClosed = Rx<Function(String)?>(null);
  final Rx<Function(MediaStream, String)?> onRemoteStream =
      Rx<Function(MediaStream, String)?>(null);

  // Connection state
  final RxBool isConnected = false.obs;

  SignalingService({required this.serverUrl});

  Future<SignalingService> init() async {
    _connect();
    return this;
  }

  void _connect() {
    _socket = WebSocketChannel.connect(Uri.parse(serverUrl));
    isConnected.value = true;
    print('Connected to signaling server at $serverUrl');
    _socket.stream.listen(
      _handleMessage,
      onDone: () {
        isConnected.value = false;
        print('Disconnected from signaling server');
        Future.delayed(Duration(seconds: 2), _connect);
      },
      onError: (error) {
        print('Signaling server error: $error');
      },
      cancelOnError: true,
    );
  }

  void _handleMessage(dynamic message) {
    // Parse the message
    final Map<String, dynamic> data =
        message is String ? jsonDecode(message) : message;

    if (data.containsKey('id')) {
      // Response to a previous request
      final id = data['id'];
      final key = id is int ? id : int.tryParse(id.toString());
      if (_pendingRequests.containsKey(key)) {
        if (data.containsKey('error')) {
          _pendingRequests[key]!.completeError(data['error']);
        } else {
          _pendingRequests[key]!.complete(data['data']);
        }
        _pendingRequests.remove(key);
      }
    } else if (data.containsKey('method')) {
      // Notification from server
      switch (data['method']) {
        case 'newConsumer':
          if (onNewConsumer.value != null) {
            onNewConsumer.value!(data['data']);
          }
          break;
        case 'newDataConsumer':
          if (onNewDataConsumer.value != null) {
            onNewDataConsumer.value!(data['data']);
          }
          break;
        case 'peerClosed':
          if (onPeerClosed.value != null) {
            onPeerClosed.value!(data['data']['peerId']);
          }
          break;
      }
    }
  }

  Future<Map<String, dynamic>> request(
      String method, Map<String, dynamic> data) {
    final int id = _requestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final Map<String, dynamic> request = {
      'id': id,
      'method': method,
      'data': data,
    };

    // Send the request
    _socket.sink.add(jsonEncode(request));
    return completer.future;
  }

  void close() {
    try {
      _socket.sink.close(status.goingAway);
    } catch (_) {}
  }

  static Future<SignalingService> createWithUrl(String serverUrl) async {
    final service = SignalingService(serverUrl: serverUrl);
    await service.init();
    return service;
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}
