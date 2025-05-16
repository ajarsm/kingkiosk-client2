import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:nsd/nsd.dart' as nsd;
import '../../wyoming_satellite/wyoming_satellite.dart';
import 'mqtt_service_consolidated.dart';

/// WyomingService: Integrates Wyoming Satellite server with the app
class WyomingService extends GetxService {
  ServerSocket? _server;
  final List<Socket> _clients = [];
  final Map<Socket, List<int>> _buffers = {};
  final RxBool isConnected = false.obs;
  final RxString host = ''.obs; // Default or loaded from storage
  final RxInt port = 10300.obs; // Default or loaded from storage
  final RxBool enabled = false.obs; // Default or loaded from storage

  // Actual IP for discovery when binding wildcard '0.0.0.0'
  final RxString _advertiseHost = ''.obs;

  // Home Assistant discovery topic base
  static const String _haDiscoveryBaseTopic = 'homeassistant/wyoming';

  final StreamController<WyomingMessage> _messageController = StreamController<WyomingMessage>.broadcast();

  nsd.Registration? _nsdRegistration;
  bool _nsdRegistered = false;

  @override
  void onInit() {
    super.onInit();
    _initializeService(); // Perform async initialization

    ever(enabled, (bool isEnabled) async {
      if (isEnabled) {
        await startServer();
      } else {
        await stopServer();
      }
    });

    ever(host, (String _) async {
      await _handleConfigChange();
    });

    ever(port, (int _) async {
      await _handleConfigChange();
    });
  }

  void _sendInfo(Socket client, String who) {
    final response = {
      'type': 'info',
      'protocol': 'wyoming',
      'version': '1.5.4',            // match client protocol version
      // Advertise our capabilities: ASR events (audio, VAD, hotword, transcript)
      'asr': ['audio_start', 'audio_stop', 'vad', 'hotword', 'transcript'],
      // No TTS command support currently
      'tts': [],
      // We support wakeword detection via hotword events
      'wake': ['hotword'],
    };

    final msg = jsonEncode(response) + '\n';
    client.add(utf8.encode(msg));
    print('[WyomingService] Sent info response to $who: $msg');
  }

  Future<void> _initializeService() async {
    // Treat empty host string as equivalent to '0.0.0.0' for initialization
    if (host.value.isEmpty || host.value == '0.0.0.0') {
      await _initAdvertiseHost();
    } else {
      _advertiseHost.value = host.value;
    }

    // If enabled was true on load, and server not yet started (e.g. due to async init)
    if (enabled.value && _server == null) {
      print("[WyomingService] Post-init: Service enabled, attempting to start server.");
      await startServer();
    }
  }

  Future<void> _handleConfigChange() async {
    if (!enabled.value) {
      return;
    }

    print("[WyomingService] Configuration changed (host/port), restarting server if enabled.");
    await stopServer();

    // Update _advertiseHost based on new host value, treating empty as '0.0.0.0'
    if (host.value.isEmpty || host.value == '0.0.0.0') {
      await _initAdvertiseHost();
    } else {
      _advertiseHost.value = host.value;
    }

    await startServer();
  }

  Future<void> startServer() async {
    if (_server != null) {
      print('[WyomingService] Server already running.');
      return;
    }

    final bool isWildcardHost = host.value.isEmpty || host.value == '0.0.0.0';
    final String actualBindHost = isWildcardHost ? '0.0.0.0' : host.value;

    // Always update _advertiseHost before announcing discovery
    if (isWildcardHost) {
      await _initAdvertiseHost();
      if (_advertiseHost.value.isEmpty ||
          _advertiseHost.value == '0.0.0.0' ||
          (InternetAddress.tryParse(_advertiseHost.value)?.isLoopback ?? true)) {
        print("[WyomingService] Advertise host for wildcard host ('${host.value}') is not suitable ('${_advertiseHost.value}'). Aborting server start.");
        return;
      }
    } else {
      if (_advertiseHost.value != host.value) {
        print("[WyomingService] Advertise host ('${_advertiseHost.value}') out of sync with specific host ('${host.value}'). Correcting.");
        _advertiseHost.value = host.value;
      }
    }

    try {
      _server = await ServerSocket.bind(actualBindHost, port.value);
      print('[WyomingService] Server listening on $actualBindHost:${port.value} (configured host: \'${host.value}\')');

      // Zeroconf (Bonjour/mDNS) advertising
      await _registerZeroconfService();

      // Announce discovery with up-to-date values
      final mqtt = Get.isRegistered<MqttService>() ? Get.find<MqttService>() : null;
      if (mqtt != null) {
        if (mqtt.isConnected.value) {
          print('[WyomingService] About to announce discovery with host=${_advertiseHost.value}, port=${port.value}');
          announceDiscovery();
        } else {
          once(mqtt.isConnected, (bool mqttConnected) {
            if (mqttConnected && _server != null) {
              print('[WyomingService] (delayed) About to announce discovery with host=${_advertiseHost.value}, port=${port.value}');
              announceDiscovery();
            }
          }, condition: () => mqtt.isConnected.value == true);
        }
      }

      _server!.listen((Socket client) {
        // Capture client details immediately upon connection
        String clientDescription = 'unknown client';
        try {
          clientDescription = '${client.remoteAddress.address}:${client.remotePort}';
        } catch (e) {
          print('[WyomingService] Error getting client description on connect: $e. Client might have disconnected immediately.');
        }
        
        print('[WyomingService] Client connected $clientDescription');
        _clients.add(client);
        isConnected.value = true;
        _buffers[client] = [];

        client.listen((data) {
          // Human-readable debug: try to decode as UTF-8 string if printable
          String dataPreview;
          try {
            dataPreview = utf8.decode(data);
          } catch (_) {
            dataPreview = data.toString();
          }
          print('[WyomingService] Received data from $clientDescription: $dataPreview (${data.length} bytes)');
          final buffer = _buffers[client]!;
          buffer.addAll(data);

          while (buffer.isNotEmpty) {
            // If raw JSON (newline-delimited) from debug/info clients, handle first
            if (buffer.isNotEmpty && buffer[0] == 123) { // '{'
              final newlineIndex = buffer.indexOf(10); // '\n'
              if (newlineIndex < 0) break; // wait for full line
              final msgBytes = buffer.sublist(0, newlineIndex);
              buffer.removeRange(0, newlineIndex + 1);
              final str = utf8.decode(msgBytes);
              try {
                final json = jsonDecode(str);
                print('[WyomingService] JSON message from $clientDescription: $str');
                final type = json['type']?.toString();
                switch (type) {
                  case 'describe':
                      _sendInfo(client, clientDescription);

                    break;
                  case 'audio_start': _messageController.add(WyomingAudioStart(sessionId: json['sessionId'] ?? '')); break;
                  case 'audio_stop': _messageController.add(WyomingAudioStop(sessionId: json['sessionId'] ?? '')); break;
                  case 'vad': _messageController.add(WyomingVad(sessionId: json['sessionId'] ?? '', active: json['active'] ?? false)); break;
                  case 'hotword': _messageController.add(WyomingHotword(sessionId: json['sessionId'] ?? '', hotword: json['hotword'] ?? '')); break;
                  case 'transcript': _messageController.add(WyomingTranscript(sessionId: json['sessionId'] ?? '', text: json['text'] ?? '')); break;
                  case 'session': _messageController.add(WyomingSession(sessionId: json['sessionId'] ?? '', state: json['state'] ?? '')); break;
                  default: _messageController.add(WyomingJsonMessage.fromJson(json));
                }
                continue;
              } catch (_) {
                // invalid JSON, fall through to prefix parsing
              }
            }
            // Length-prefixed Wyoming protocol messages
            if (buffer.length >= 4) {
              final len = (buffer[0] << 24) | (buffer[1] << 16) | (buffer[2] << 8) | buffer[3];
              if (buffer.length < 4 + len) {
                print('[WyomingService] Incomplete Wyoming message from $clientDescription: need $len bytes, have ${buffer.length - 4}');
                break;
              }
              final msgBytes = buffer.sublist(4, 4 + len);
              buffer.removeRange(0, 4 + len);
              // Try JSON content inside prefix
              try {
                final str = utf8.decode(msgBytes);
                if (str.trim().startsWith('{')) {
                  final json = jsonDecode(str);
                  final type = json['type']?.toString();
                  if (type == 'describe') {
                    _sendDescribeResponse(client, clientDescription, asJson: false);
                  } else {
                    // existing event handling
                    switch (type) {
                      case 'audio_start': _messageController.add(WyomingAudioStart(sessionId: json['sessionId'] ?? '')); break;
                      case 'audio_stop': _messageController.add(WyomingAudioStop(sessionId: json['sessionId'] ?? '')); break;
                      case 'vad': _messageController.add(WyomingVad(sessionId: json['sessionId'] ?? '', active: json['active'] ?? false)); break;
                      case 'hotword': _messageController.add(WyomingHotword(sessionId: json['sessionId'] ?? '', hotword: json['hotword'] ?? '')); break;
                      case 'transcript': _messageController.add(WyomingTranscript(sessionId: json['sessionId'] ?? '', text: json['text'] ?? '')); break;
                      case 'session': _messageController.add(WyomingSession(sessionId: json['sessionId'] ?? '', state: json['state'] ?? '')); break;
                      default: _messageController.add(WyomingJsonMessage.fromJson(json));
                    }
                  }
                  continue;
                }
              } catch (_) {}
              // treat as binary
              _messageController.add(WyomingBinaryMessage(msgBytes));
            } else {
              break;
            }
          }
        }, 
        onDone: () {
          print('[WyomingService] Client disconnected $clientDescription'); // Use captured description
          _clients.remove(client);
          _buffers.remove(client);
          if (_clients.isEmpty) isConnected.value = false;
          client.close(); // Ensure closed, though onDone implies it is.
        }, 
        onError: (error, stackTrace) { // Added stackTrace parameter
          print('[WyomingService] Client error from $clientDescription: $error'); // Use captured description
          if (stackTrace != null) {
            print('[WyomingService] Stack trace for $clientDescription error:\n$stackTrace');
          }
          _clients.remove(client);
          _buffers.remove(client);
          if (_clients.isEmpty) isConnected.value = false;
          client.close(); // Ensure closed
        });
      });
    } catch (e) {
      print('[WyomingService] Server bind error: $e');
      _server = null; // Ensure server is null on error
    }
  }

  // Zeroconf (Bonjour/mDNS) registration for Wyoming Satellite
  Future<void> _registerZeroconfService() async {
    if (_nsdRegistered) {
      print('[WyomingService] Zeroconf service already registered.');
      return;
    }
    try {
      final txtRecords = <String, Uint8List?>{
        'version': Uint8List.fromList('1.0'.codeUnits),
      };
      final service = nsd.Service(
        name: 'Wyoming Satellite',
        type: '_wyoming._tcp',
        host: _advertiseHost.value,
        port: port.value,
        txt: txtRecords,
      );
      _nsdRegistration = await nsd.register(service);
      _nsdRegistered = true;
      print('[WyomingService] Zeroconf service registered: ${service.name}');
    } catch (e) {
      print('[WyomingService] Error registering Zeroconf service: $e');
      _nsdRegistration = null;
      _nsdRegistered = false;
    }
  }

  // Unregister Zeroconf service when stopping server
  Future<void> _unregisterZeroconfService() async {
    if (!_nsdRegistered || _nsdRegistration == null) return;
    try {
      await nsd.unregister(_nsdRegistration!);
      print('[WyomingService] Zeroconf service unregistered.');
    } catch (e) {
      print('[WyomingService] Error unregistering Zeroconf service: $e');
    } finally {
      _nsdRegistered = false;
      _nsdRegistration = null;
    }
  }

  Future<void> _initAdvertiseHost() async {
    final bool isEffectivelyWildcard = host.value.isEmpty || host.value == '0.0.0.0';

    if (!isEffectivelyWildcard) {
      _advertiseHost.value = host.value;
      print("[WyomingService] Advertise host set to configured host: ${_advertiseHost.value}");
      return;
    }

    // Host is effectively wildcard ('0.0.0.0' or empty), try to find a real IP.
    _advertiseHost.value = ''; // Reset before attempting
    try {
      // Connect to a public DNS server to find the outbound IP
      final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 2));
      print('[WyomingService] DEBUG: socket.address.address (should be local): \'${socket.address.address}\', socket.remoteAddress.address (should be remote): \'${socket.remoteAddress.address}\'');
      _advertiseHost.value = socket.address.address; // This should be the local IP
      await socket.close(); // Use close for graceful shutdown
      print("[WyomingService] Resolved advertise host for wildcard host ('${host.value}'): ${_advertiseHost.value}");

      if (_advertiseHost.value == '0.0.0.0' || (InternetAddress.tryParse(_advertiseHost.value)?.isLoopback ?? true)) {
        print("[WyomingService] Warning: Resolved advertise host ('${_advertiseHost.value}') is loopback or 0.0.0.0. This may not be suitable for HA discovery from other devices.");
        _advertiseHost.value = ''; // Mark as failed to find a *good* IP
      }
    } catch (e) {
      print("[WyomingService] Failed to determine outbound IP for wildcard host ('${host.value}') via 8.8.8.8: $e");
      _advertiseHost.value = ''; // Mark as failed
    }

    if (_advertiseHost.value.isEmpty) {
        print("[WyomingService] Warning: Could not determine a specific, non-loopback IP to advertise for wildcard host ('${host.value}'). MQTT discovery may not work as expected.");
    }
  }

  Future<void> stopServer() async {
    if (_server == null && _clients.isEmpty) {
      removeDiscovery(); // Attempt removal anyway, it has guards.
      await _unregisterZeroconfService();
      return;
    }
    print('[WyomingService] Stopping server...');
    removeDiscovery(); // Remove Home Assistant discovery
    await _unregisterZeroconfService();

    for (var client in List<Socket>.from(_clients)) { // Iterate over a copy
      try {
        await client.close();
      } catch (e) {
        print("[WyomingService] Error closing client: $e");
      }
    }
    _clients.clear();
    _buffers.clear();

    try {
      await _server?.close();
    } catch (e) {
      print("[WyomingService] Error closing server socket: $e");
    }
    _server = null;
    isConnected.value = false; // Explicitly set to false
    print('[WyomingService] Server stopped');
  }

  /// Send audio (length-prefix framed) to all connected clients
  Future<void> sendAudio(List<int> audioBytes) async {
    if (!enabled.value) return;
    final msg = WyomingBinaryMessage(audioBytes).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  Stream<WyomingMessage> get messageStream => _messageController.stream;

  /// Wyoming session/event helpers
  Future<void> startSession(String sessionId) async {
    final msg = WyomingAudioStart(sessionId: sessionId).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  Future<void> stopSession(String sessionId) async {
    final msg = WyomingAudioStop(sessionId: sessionId).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  Future<void> sendVad(String sessionId, bool active) async {
    final msg = WyomingVad(sessionId: sessionId, active: active).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  Future<void> sendHotword(String sessionId, String hotword) async {
    final msg = WyomingHotword(sessionId: sessionId, hotword: hotword).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  Future<void> sendTranscript(String sessionId, String text) async {
    final msg = WyomingTranscript(sessionId: sessionId, text: text).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  Future<void> sendSessionState(String sessionId, String state) async {
    final msg = WyomingSession(sessionId: sessionId, state: state).toBytes();
    for (var client in _clients) {
      client.add(msg);
    }
  }

  /// Force re-announce discovery (for debugging or after MQTT reconnect)
  void forceAnnounceDiscovery() {
    print('[WyomingService] Forcing re-announcement of discovery.');
    announceDiscovery();
  }

  /// Announce Wyoming Satellite for Home Assistant discovery
  void announceDiscovery({String? friendlyName}) {
    String addrToAnnounce;
    final bool isEffectivelyWildcard = host.value.isEmpty || host.value == '0.0.0.0';

    if (isEffectivelyWildcard) {
      if (_advertiseHost.value.isNotEmpty &&
          _advertiseHost.value != '0.0.0.0' &&
          !(InternetAddress.tryParse(_advertiseHost.value)?.isLoopback ?? true)) {
        addrToAnnounce = _advertiseHost.value;
      } else {
        print("[WyomingService] Cannot announce discovery for wildcard host ('${host.value}'): No suitable non-loopback advertise IP found. Current _advertiseHost: '${_advertiseHost.value}'");
        return;
      }
    } else {
      addrToAnnounce = host.value;
      if (InternetAddress.tryParse(addrToAnnounce)?.isLoopback ?? false) {
        print("[WyomingService] Warning: Announcing with a loopback address '${addrToAnnounce}'. HA may only connect from the same machine.");
      }
    }

    if (addrToAnnounce.isEmpty || addrToAnnounce == '0.0.0.0') {
      print("[WyomingService] Final check: Invalid address to announce ('${addrToAnnounce}'). Aborting announcement.");
      return;
    }

    final uniqueId = '${addrToAnnounce}_${port.value}';
    final topic = '$_haDiscoveryBaseTopic/$uniqueId/config';
    final discoveryPayload = {
      'platform': 'wyoming',
      'name': friendlyName ?? 'Wyoming Satellite ($addrToAnnounce:${port.value})',
      'host': addrToAnnounce,
      'port': port.value,
      'unique_id': uniqueId,
    };

    print('[WyomingService] MQTT Discovery publish: topic=$topic, payload=${discoveryPayload.toString()}, retain=true');

    final mqtt = Get.isRegistered<MqttService>() ? Get.find<MqttService>() : null;
    if (mqtt != null && mqtt.isConnected.value) {
      mqtt.publishJsonToTopic(topic, discoveryPayload, retain: true);
      print('[WyomingService] Announced discovery to $topic');
    } else {
      print('[WyomingService] MQTT not connected, cannot announce discovery.');
    }
  }

  /// Remove Wyoming Satellite discovery config from Home Assistant
  void removeDiscovery() {
    String addrForTopic;
    final bool isEffectivelyWildcard = host.value.isEmpty || host.value == '0.0.0.0';

    if (isEffectivelyWildcard) {
      if (_advertiseHost.value.isNotEmpty &&
          _advertiseHost.value != '0.0.0.0' &&
          !(InternetAddress.tryParse(_advertiseHost.value)?.isLoopback ?? true)) {
        addrForTopic = _advertiseHost.value;
      } else {
        print("[WyomingService] Cannot reliably determine topic for removeDiscovery with wildcard host ('${host.value}') and current _advertiseHost: '${_advertiseHost.value}'. Skipping removal.");
        return;
      }
    } else {
      // If not wildcard, host.value is a specific, non-empty, non-'0.0.0.0' IP.
      addrForTopic = host.value;
    }

    if (addrForTopic.isEmpty || addrForTopic == '0.0.0.0') {
      print("[WyomingService] Final check: Invalid address for removeDiscovery topic ('${addrForTopic}'). Aborting removal.");
      return;
    }

    final uniqueId = '${addrForTopic}_${port.value}';
    final topic = '$_haDiscoveryBaseTopic/$uniqueId/config';

    final mqtt = Get.isRegistered<MqttService>() ? Get.find<MqttService>() : null;
    if (mqtt != null && mqtt.isConnected.value) {
      mqtt.publishJsonToTopic(topic, {}, retain: true); // Publish empty message to clear
      print('[WyomingService] Sent removal for discovery topic $topic');
    } else {
      print('[WyomingService] MQTT not connected, cannot remove discovery.');
    }
  }

  /// Advanced config: set all options at once
  void setConfig({required String host, required int port, required bool enabled}) {
    this.host.value = host;
    this.port.value = port;
    this.enabled.value = enabled;
  }

  /// Send describe response in JSON or Wyoming protocol format
  void _sendDescribeResponse(Socket client, String clientDescription, {bool asJson = true}) {
    final response = {
      'type': 'describe',
      'protocol': 'wyoming',
      'version': '1.0',
      'implementation': 'kingkiosk',
    };
    final responseStr = jsonEncode(response);
    if (asJson) {
      client.add(utf8.encode(responseStr + '\n'));
      print('[WyomingService] Sent describe response (raw JSON) to $clientDescription: $responseStr');
    } else {
      final respBytes = utf8.encode(responseStr);
      final respLen = respBytes.length;
      final lenPrefix = [
        (respLen >> 24) & 0xFF,
        (respLen >> 16) & 0xFF,
        (respLen >> 8) & 0xFF,
        respLen & 0xFF
      ];
      client.add(lenPrefix + respBytes);
      print('[WyomingService] Sent describe response (Wyoming protocol) to $clientDescription: $responseStr');
    }
  }

  // Add more methods as needed for Wyoming protocol events
}
