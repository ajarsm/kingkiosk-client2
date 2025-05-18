// lib/services/signaling_service.dart
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService extends GetxService {
  late GetSocket _socket;
  final String serverUrl;

  // Request tracking
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestId = 0;

  // Observable events for reactive programming
  final Rx<Function(Map<String, dynamic>)?> onNewConsumer =
      Rx<Function(Map<String, dynamic>)?>(null);
  final Rx<Function(Map<String, dynamic>)?> onNewDataConsumer =
      Rx<Function(Map<String, dynamic>)?>(null); // Add this line
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
    // Use GetX's socket implementation
    _socket = GetSocket(serverUrl);

    // Set up message handling
    _socket.onMessage(_handleMessage);

    // Handle connection events
    _socket.onOpen(() {
      isConnected.value = true;
      print('Connected to signaling server at $serverUrl');
    });

    _socket.onClose((_) {
      isConnected.value = false;
      print('Disconnected from signaling server');
      // Automatic reconnection
      Future.delayed(Duration(seconds: 2), _connect);
    });

    _socket.onError((error) {
      print('Signaling server error: $error');
    });

    // Connect to the server
    _socket.connect();
  }

  void _handleMessage(dynamic message) {
    // Parse the message
    final Map<String, dynamic> data =
        message is String ? jsonDecode(message) : message;

    if (data.containsKey('id')) {
      // Response to a previous request
      final int id = data['id'];
      if (_pendingRequests.containsKey(id)) {
        if (data.containsKey('error')) {
          _pendingRequests[id]!.completeError(data['error']);
        } else {
          _pendingRequests[id]!.complete(data['data']);
        }
        _pendingRequests.remove(id);
      }
    } else if (data.containsKey('method')) {
      // Notification from server
      switch (data['method']) {
        case 'newConsumer':
          if (onNewConsumer.value != null) {
            onNewConsumer.value!(data['data']);
          }
          break;
        case 'newDataConsumer': // Add this case
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
    _socket.send(jsonEncode(request));
    return completer.future;
  }

  void close() {
    _socket.close();
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}
