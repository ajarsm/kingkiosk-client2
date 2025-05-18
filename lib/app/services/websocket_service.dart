import 'package:get/get.dart';
import 'dart:convert';

class WebSocketService extends GetxService {
  GetSocket? _socket;
  final RxBool isConnected = false.obs;
  final RxString lastMessage = ''.obs;

  WebSocketService init() {
    return this;
  }

  void connect(String url) {
    disconnect(); // Clean up any previous connection
    _socket = GetSocket(url);
    _socket!.onOpen(() {
      isConnected.value = true;
    });
    _socket!.onClose((_) {
      isConnected.value = false;
    });
    _socket!.onError((err) {
      isConnected.value = false;
    });
    _socket!.onMessage((message) {
      lastMessage.value = message.toString();
      // You can handle specific message types here
    });
  }

  void disconnect() {
    _socket?.close();
    isConnected.value = false;
    _socket = null;
  }

  void send(dynamic data) {
    if (_socket != null && isConnected.value) {
      if (data is! String) {
        data = jsonEncode(data);
      }
      _socket!.send(data);
    }
  }
}
