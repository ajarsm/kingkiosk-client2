import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  final RxBool isConnected = false.obs;
  final RxString lastMessage = ''.obs;
  
  WebSocketService init() {
    return this;
  }

  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      isConnected.value = true;
      
      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          lastMessage.value = message.toString();
          // You can handle specific message types here
        },
        onDone: () {
          isConnected.value = false;
        },
        onError: (error) {
          isConnected.value = false;
        },
      );
    } catch (e) {
      isConnected.value = false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    isConnected.value = false;
  }

  void send(dynamic data) {
    if (_channel != null && isConnected.value) {
      if (data is! String) {
        data = jsonEncode(data);
      }
      _channel!.sink.add(data);
    }
  }
}