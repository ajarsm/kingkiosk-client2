import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../notification_system/notification_system.dart';
import 'storage_service.dart';
import 'platform_sensor_service.dart';
import '../core/utils/app_constants.dart';
import 'background_media_service.dart';
import '../services/window_manager_service.dart';
import '../modules/home/controllers/tiling_window_controller.dart';
import '../modules/calendar/controllers/calendar_controller.dart';
import 'mqtt_notification_handler.dart';
import 'media_recovery_service.dart';
import 'tts_service.dart';
import 'media_control_service.dart'; // Import the MediaControlService
import 'screenshot_service.dart';
import 'audio_service.dart'; // Import the AudioService
import 'person_detection_service.dart';
import '../controllers/halo_effect_controller.dart';
import '../controllers/window_halo_controller.dart';
import '../widgets/halo_effect/halo_effect_overlay.dart'; // Import for HaloPulseMode enum
import '../modules/home/widgets/youtube_player_tile.dart'; // Import for YouTubePlayerManager
import 'media_hardware_detection.dart';
import '../modules/settings/controllers/settings_controller_compat.dart';

/// MQTT service with proper statistics reporting (consolidated from multiple versions)
/// Fixed to properly report all sensor values to Home Assistant
class MqttService extends GetxService {
  /// Helper function to strip JavaScript-style comments from JSON strings
  /// This allows users to include comments in their MQTT JSON payloads for better readability
  String _stripJsonComments(String jsonString) {
    // More sophisticated comment removal that preserves URLs
    // Only remove // comments that are not inside quoted strings

    List<String> lines = jsonString.split('\n');
    List<String> cleanedLines = [];

    for (String line in lines) {
      String cleanedLine = _removeLineComment(line);
      cleanedLines.add(cleanedLine);
    }

    String result = cleanedLines.join('\n');

    // Remove multi-line comments (/* comment */)
    // Use a more careful regex that handles nested comments and strings
    result = result.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Clean up any trailing commas that might be left after comment removal
    result = result.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');

    return result.trim();
  }

  /// Remove line comments while preserving URLs in quoted strings
  String _removeLineComment(String line) {
    bool inString = false;
    bool escapeNext = false;

    for (int i = 0; i < line.length - 1; i++) {
      if (escapeNext) {
        escapeNext = false;
        continue;
      }

      if (line[i] == '\\') {
        escapeNext = true;
        continue;
      }

      if (line[i] == '"') {
        inString = !inString;
        continue;
      }

      // Only remove // comments if we're not inside a quoted string
      if (!inString && line[i] == '/' && line[i + 1] == '/') {
        return line.substring(0, i).trimRight();
      }
    }

    return line;
  }

  // Utility: Parse a color to hex string
  // (moved below, keep only one definition)
  /// Subscribe to a custom MQTT topic
  void subscribe(String topic, Function(String, String) onMessage) {
    print('Subscribing to topic: $topic');
    _client?.subscribe(topic, MqttQos.atLeastOnce);
    _client?.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      if (messages == null || messages.isEmpty) return;
      for (final message in messages) {
        if (message.payload is MqttPublishMessage) {
          final publishMessage = message.payload as MqttPublishMessage;
          final payloadString = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message,
          );
          onMessage(message.topic, payloadString);
        }
      }
    });
  }

  /// Publish Home Assistant MQTT Discovery config for windows diagnostic entity
  void publishWindowsDiscoveryConfig({String? friendlyNameOverride}) {
    final deviceNameStr = deviceName.value;
    final deviceFriendlyName = friendlyNameOverride ?? deviceNameStr;
    final discoveryTopic =
        'homeassistant/sensor/${deviceNameStr}_windows/config';
    final stateTopic = 'kiosk/$deviceNameStr/diagnostics/windows';
    final availabilityTopic = 'kingkiosk/$deviceNameStr/status';
    final payload = {
      "name": "Kiosk Windows",
      "unique_id": "${deviceNameStr}_windows",
      "state_topic": stateTopic,
      "icon": "mdi:window-restore",
      "entity_category": "diagnostic",
      "device_class": "none",
      "value_template": "{{ value_json.windows | length }}",
      "json_attributes_topic": stateTopic,
      "availability_topic": availabilityTopic,
      "payload_available": "online",
      "payload_not_available": "offline",
      "device": {
        "identifiers": ["kiosk_$deviceNameStr"],
        "name": deviceFriendlyName,
        "model": "Flutter GetX Kiosk",
        "manufacturer": "KingKiosk"
      }
    };
    print(
        'MQTT DEBUG: Discovery payload for windows: \\${jsonEncode(payload)}');
    print('MQTT DEBUG: Publishing to topic: $discoveryTopic');
    publishJsonToTopic(discoveryTopic, payload, retain: true);
    print('MQTT DEBUG: Published discovery config for windows');
  }

  // Required dependencies
  final StorageService _storageService;
  final PlatformSensorService _sensorService;

  // MQTT client
  MqttServerClient? _client;

  // Observable properties
  final RxBool isConnected = false.obs;
  final RxString deviceName = ''.obs;
  final RxBool haDiscovery = false.obs;
  final RxBool isOnline = true.obs; // Track online status

  // Stats update timer
  Timer? _statsUpdateTimer;
  // Update interval - 30 seconds for more responsive updates
  final int _updateIntervalSeconds = 30;

  // Batch script management
  bool _batchScriptRunning = false;
  String? _currentBatchId;
  // Timer? _batchTimeoutTimer; // Unused, commented out
  // Utility: Parse a hex string to color with robust error handling
  Color _hexToColor(String hexString) {
    if (hexString.isEmpty) {
      print('⚠️ Empty color string, defaulting to red');
      return Color(0xFFFF0000);
    }
    switch (hexString.toLowerCase()) {
      case 'red':
        return Color(0xFFFF0000);
      case 'green':
        return Color(0xFF4CAF50);
      case 'blue':
        return Color(0xFF2196F3);
      case 'yellow':
        return Color(0xFFFFEB3B);
      case 'orange':
        return Color(0xFFFF9800);
      case 'purple':
        return Color(0xFF9C27B0);
      case 'pink':
        return Color(0xFFE91E63);
      case 'cyan':
        return Color(0xFF00BCD4);
      case 'teal':
        return Color(0xFF009688);
      case 'amber':
        return Color(0xFFFFC107);
      case 'lime':
        return Color(0xFFCDDC39);
      case 'indigo':
        return Color(0xFF3F51B5);
      case 'white':
        return Color(0xFFFFFFFF);
      case 'black':
        return Color(0xFF000000);
      case 'grey':
      case 'gray':
        return Color(0xFF9E9E9E);
    }
    try {
      String hexCode = hexString.replaceAll('#', '').trim();
      if (hexCode.length == 3) {
        hexCode = hexCode.split('').map((c) => '$c$c').join('');
      }
      if (hexCode.length != 6 && hexCode.length != 8) {
        print(
            '⚠️ Invalid hex color length: [33m${hexCode.length}[0m, defaulting to red');
        return Color(0xFFFF0000);
      }
      final colorValue =
          int.tryParse(hexCode.length == 6 ? '0xFF$hexCode' : '0x$hexCode');
      if (colorValue == null) {
        print('⚠️ Failed to parse hex color: $hexString, defaulting to red');
        return Color(0xFFFF0000);
      }
      return Color(colorValue);
    } catch (e) {
      print('⚠️ Error parsing hex color "$hexString": $e, defaulting to red');
      return Color(0xFFFF0000);
    }
  }

  // Utility: Parse a color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  // Batch script management: process a managed batch (fully implemented)
  Future<void> _processManagedBatch(dynamic cmdObj) async {
    // Parse commands array
    final List<dynamic>? commands = cmdObj['commands'] as List<dynamic>?;
    if (commands == null || commands.isEmpty) {
      print('[BATCH] No commands provided in batch');
      batchStatus.value = 'idle';
      return;
    }

    _batchScriptRunning = true;
    _batchKillRequested = false;
    _currentBatchId = DateTime.now().millisecondsSinceEpoch.toString();
    batchStatus.value = 'running';
    batchProgress.value = 0;
    batchTotal.value = commands.length;

    print('[BATCH] Starting batch script with ${commands.length} commands');

    for (int i = 0; i < commands.length; i++) {
      if (_batchKillRequested) {
        print('[BATCH] Batch kill requested, stopping at command $i');
        batchStatus.value = 'killed';
        break;
      }

      final dynamic command = commands[i];
      batchProgress.value = i + 1;

      print('[BATCH] Executing command ${i + 1}/${commands.length}: $command');

      try {
        // Simulate command processing: if it's a wait, actually wait
        if (command is Map &&
            command['command']?.toString().toLowerCase() == 'wait') {
          // Perform wait in increments to allow kill checks
          final seconds =
              double.tryParse(command['seconds']?.toString() ?? '1') ?? 1.0;
          final int totalMs = (seconds * 1000).clamp(0, 300000).toInt();
          print('[BATCH] Waiting for $seconds seconds');
          int elapsed = 0;
          const int chunkMs = 200;
          while (elapsed < totalMs && !_batchKillRequested) {
            final int waitMs =
                (totalMs - elapsed) >= chunkMs ? chunkMs : (totalMs - elapsed);
            await Future.delayed(Duration(milliseconds: waitMs));
            elapsed += waitMs;
          }
          if (_batchKillRequested) {
            print('[BATCH] Batch killed during wait');
            batchStatus.value = 'killed';
            break;
          }
        } else if (command is Map && command['command'] != null) {
          // Recursively process as a single command (await async handling)
          await _processCommand(jsonEncode(command));
        } else if (command is String) {
          // If it's a string, treat as a simple command
          await _processCommand(command);
        } else {
          print('[BATCH] Unknown command format: $command');
        }
      } catch (e, st) {
        print('[BATCH] Error processing command $i: $e\n$st');
        // Optionally, you could break or continue on error
      }
    }

    if (_batchKillRequested) {
      print('[BATCH] Batch script was killed');
      batchStatus.value = 'killed';
    } else {
      print('[BATCH] Batch script completed');
      batchStatus.value = 'idle';
    }
    _batchScriptRunning = false;
    _currentBatchId = null;
    _batchKillRequested = false;
    batchProgress.value = 0;
    batchTotal.value = 0;
  }

  // Batch script management: kill batch script (stub)
  Map<String, dynamic> _killBatchScript() {
    // TODO: Implement batch kill logic
    if (_batchScriptRunning) {
      _batchKillRequested = true;
      _batchScriptRunning = false;
      final killedId = _currentBatchId;
      _currentBatchId = null;
      batchStatus.value = 'killed';
      return {
        'success': true,
        'message': 'Batch script killed',
        'killed_batch_id': killedId,
      };
    } else {
      return {
        'success': false,
        'message': 'No batch script running',
        'killed_batch_id': null,
      };
    }
  }

  bool _batchKillRequested = false;
  final RxString batchStatus = 'idle'.obs; // idle, running, killed
  final RxInt batchProgress = 0.obs; // Current command index
  final RxInt batchTotal = 0.obs; // Total commands in batch

  // Constructor
  MqttService(this._storageService, this._sensorService);

  @override
  void onInit() {
    super.onInit();
    final device = deviceName.value;
    final topic = 'kiosk/$device/window/+/command';

    // 1️⃣ Subscribe once to per-window commands
    subscribe(topic, (String topic, String payload) {
      final parts = topic.split('/');
      if (parts.length < 4) return;
      final windowName = parts[3];

      try {
        final cleanPayload = _stripJsonComments(payload);
        final data = json.decode(cleanPayload) as Map<String, dynamic>;
        final action = data['action'] as String?;
        if (action != null) {
          final wm = Get.find<WindowManagerService>();
          wm.handleWindowCommand(windowName, action, data);
        }
      } catch (e) {
        print('Failed to parse window command payload: $e');
      }
    });

    // 2️⃣ Warm-up NotificationService (if present)
    if (Get.isRegistered<NotificationService>()) {
      print('✅ [MQTT] NotificationService is ready for MQTT notifications');
    }

    // 3️⃣ Clear legacy object-detection discovery configs
    _clearLegacyObjectDetectionConfigs();

    // 4️⃣ Re-publish window discovery
    publishWindowsDiscoveryConfig();
  }

  // Connection callbacks
  void onConnected() {
    print('MQTT client connected');
    isConnected.value = true;
    if (_client != null && _client!.updates != null) {
      print('✅ MQTT client updates stream is available - setting up listener');
      _client!.updates!.listen(
        (List<MqttReceivedMessage<MqttMessage?>>? messages) {
          if (messages == null || messages.isEmpty) return;
          for (final message in messages) {
            try {
              print('🔍 Processing message on topic: ${message.topic}');
              if (message.payload is MqttPublishMessage) {
                final publishMessage = message.payload as MqttPublishMessage;
                final payloadString = MqttPublishPayload.bytesToStringAsString(
                  publishMessage.payload.message,
                );
                print('✅ Received MQTT message - Topic: ${message.topic}');
                print('✅ Message content: "$payloadString"');
                // Process command if topic matches
                if (message.topic.endsWith('/command') ||
                    message.topic.endsWith('/commands')) {
                  print(
                      '🎯 Processing as command message on topic: ${message.topic}');
                  _processCommand(payloadString);
                }
              }
            } catch (e) {
              print('❌ Error processing MQTT message: ${e.toString()}');
            }
          }
        },
        onError: (error) {
          print('❌ MQTT message listener error: ${error.toString()}');
        },
        onDone: () {
          print('MQTT message listener stream closed');
        },
      );
    } else {
      print(
          '❌ ERROR: MQTT client updates stream is null - cannot listen for messages');
    }
  }

  void onDisconnected() {
    print('MQTT client disconnected');
    isConnected.value = false;
  }

  void onSubscribed(String topic) {
    print('MQTT subscription confirmed for topic $topic');
  }

  /// Initialize the service
  Future<MqttService> init() async {
    // Load saved settings
    deviceName.value =
        _storageService.read<String>(AppConstants.keyDeviceName) ?? '';
    haDiscovery.value =
        _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;

    // If device name is not set, generate a unique one
    if (deviceName.value.isEmpty) {
      // Generate device name without "kiosk" prefix
      deviceName.value =
          'device-${DateTime.now().millisecondsSinceEpoch % 100000}';
      // Save the generated device name
      _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    }

    // Check for and remove "kiosk" prefix if it exists in the device name
    if (deviceName.value.startsWith('kiosk-') ||
        deviceName.value.startsWith('kiosk ')) {
      print(
          'MQTT INFO: Removing kiosk prefix from device name: ${deviceName.value}');
      final oldName = deviceName.value;
      deviceName.value =
          deviceName.value.replaceFirst(RegExp(r'^kiosk[\s-]'), '');
      print('MQTT INFO: Name changed from "$oldName" to "${deviceName.value}"');
      // Save the updated device name
      _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    }

    // Sanitize the device name to be MQTT friendly (no spaces, special chars)
    if (deviceName.value.contains(RegExp(r'[^\w-]'))) {
      print(
          'MQTT INFO: Sanitizing device name for MQTT compatibility: ${deviceName.value}');
      final oldName = deviceName.value;
      deviceName.value = deviceName.value.replaceAll(RegExp(r'[^\w-]'), '_');
      print(
          'MQTT INFO: Name sanitized from "$oldName" to "${deviceName.value}"');
      // Save the sanitized device name
      _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    }

    return this;
  }

  /// Connect to the MQTT broker
  Future<bool> connect({
    required String brokerUrl,
    required int port,
    String? username,
    String? password,
  }) async {
    // Prevent multiple simultaneous connection attempts
    if (_client != null &&
        (_client!.connectionStatus?.state == MqttConnectionState.connecting ||
            _client!.connectionStatus?.state ==
                MqttConnectionState.connected)) {
      print(
          'MQTT already connected or connecting, skipping new connect attempt');
      return isConnected.value;
    }

    // Check if already connecting or connected
    if (_client != null &&
        _client!.connectionStatus!.state != MqttConnectionState.disconnected) {
      print('MQTT already connected or connecting, disconnecting first');
      await disconnect();
    }

    print('Connecting to MQTT broker: $brokerUrl:$port');

    try {
      // Initialize client with a unique client ID
      final String clientId = '${deviceName.value}_${Random().nextInt(100000)}';
      _client = MqttServerClient.withPort(brokerUrl, clientId, port);

      // Set keep alive interval - more frequent to detect connection issues earlier
      _client!.keepAlivePeriod = 30; // Reduced from 60 to 30 seconds

      // Enable auto reconnect for better reliability
      _client!.autoReconnect = true;
      _client!.resubscribeOnAutoReconnect =
          true; // Auto resubscribe on reconnect

      // Configure client
      _client!.logging(on: false);
      _client!.setProtocolV311();

      _client!.onConnected = onConnected;
      _client!.onDisconnected = onDisconnected;
      _client!.onSubscribed = onSubscribed;
      _client!.onAutoReconnect = () {
        print('📡 MQTT auto reconnect triggered');
      };

      print('📡 Setting up MQTT connection status monitor');
      MqttConnectionState? lastState;

      Timer.periodic(Duration(seconds: 3), (timer) {
        if (_client == null) {
          timer.cancel();
          return;
        }

        final currentState = _client!.connectionStatus!.state;

        // Only log when the state changes
        if (lastState != currentState) {
          print('📡 MQTT connection state changed to: $currentState');
          lastState = currentState;

          // Update local connection state
          isConnected.value = (currentState == MqttConnectionState.connected);

          // If reconnected, resubscribe to topics
          if (currentState == MqttConnectionState.connected) {
            print(
                '📡 Connected to MQTT broker, ensuring topics are subscribed');
            _subscribeToCommands();
          }
        }
      });

      // Set connection message
      final connMess = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('kingkiosk/${deviceName.value}/status')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .startClean();

      // Add authentication if provided
      if (username != null && username.isNotEmpty) {
        print('Using MQTT authentication with username: $username');
        connMess.authenticateAs(username, password);
      } else {
        print('MQTT connecting without authentication');
      }

      _client!.connectionMessage = connMess;

      // Connect to the broker
      print('Attempting to connect to MQTT broker $brokerUrl:$port...');
      await _client!.connect();

      // Check connection result
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT Connected successfully to: $brokerUrl:$port');
        isConnected.value = true;

        // Publish online status
        publishStatus('online');

        // Subscribe to command topics
        _subscribeToCommands();

        // Set up Home Assistant discovery if enabled
        if (haDiscovery.value) {
          print('Setting up Home Assistant discovery');

          // Use the debug flow to ensure all sensors are published correctly
          print('Using debug flow to ensure all sensors are registered');
          forcePublishAllSensors();
        } else {
          print('Home Assistant discovery disabled');
        }

        // Start updating stats
        _startStatsUpdate();

        return true;
      } else {
        print(
            'MQTT Connection failed: ${_client!.connectionStatus!.state.toString()}');
        isConnected.value = false;
        return false;
      }
    } catch (e) {
      print('MQTT Connection error: $e');

      // Try to get more details about the error
      String errorDetails = '';
      if (_client != null && _client!.connectionStatus != null) {
        errorDetails = 'Return code: ${_client!.connectionStatus!.returnCode}';
      }

      print('MQTT connection failure details: $errorDetails');
      isConnected.value = false;
      return false;
    }
  }

  /// Disconnect from the MQTT broker with improved error handling
  Future<void> disconnect() async {
    if (_client != null) {
      try {
        // Publish offline status before disconnecting
        publishStatus('offline');
        debugPrint('MQTT offline status published');

        // Stop stats update timer
        _stopStatsUpdate();
        debugPrint('MQTT stats update timer stopped');

        // Short delay to ensure offline status is sent
        await Future.delayed(Duration(milliseconds: 100));

        // Disconnect
        _client!.disconnect();
        isConnected.value = false;
        debugPrint('MQTT Disconnected successfully');
      } catch (e) {
        debugPrint('MQTT Disconnect error: $e');
        // Still mark as disconnected even if there was an error
        isConnected.value = false;
      }
    } else {
      debugPrint('MQTT Disconnect: No active client');
    }
  }

  /// Publish the device status (online/offline)
  void publishStatus(String status) {
    if (_client != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(status);

      _client!.publishMessage(
        'kingkiosk/${deviceName.value}/status',
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
    }
  }

  /// Publish a JSON payload to an MQTT topic
  void publishJsonToTopic(String topic, Map<String, dynamic> payload,
      {bool retain = false}) {
    if (_client != null &&
        _client!.connectionStatus != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      try {
        final builder = MqttClientPayloadBuilder();
        final jsonString = jsonEncode(payload);
        builder.addString(jsonString);

        _client!.publishMessage(
          topic,
          MqttQos.atLeastOnce,
          builder.payload!,
          retain: retain,
        );

        debugPrint(
            'Published JSON to $topic: ${jsonString.substring(0, min(100, jsonString.length))}${jsonString.length > 100 ? '...' : ''}');
      } catch (e) {
        debugPrint('Error publishing JSON to topic $topic: $e');
      }
    } else {
      debugPrint('Cannot publish to $topic: MQTT client not connected');
    }
  }

  /// Clean up resources when service is closed
  @override
  void onClose() {
    debugPrint('MQTT service onClose called - performing clean shutdown');

    try {
      // First publish offline status if connected
      if (_client != null &&
          _client!.connectionStatus != null &&
          _client!.connectionStatus!.state == MqttConnectionState.connected) {
        publishStatus('offline');
        debugPrint('Published offline status before disconnect');
      }

      // Ensure proper disconnection when service is destroyed
      disconnect();

      // Cancel any active timer
      _stopStatsUpdate();

      debugPrint('MQTT service shutdown completed');
    } catch (e) {
      debugPrint('Error during MQTT service shutdown: $e');
    }

    super.onClose();
  }

  /// Start timer to periodically update device stats
  void _startStatsUpdate() {
    // Cancel existing timer if any
    _stopStatsUpdate();

    // Create new timer
    _statsUpdateTimer = Timer.periodic(
      Duration(seconds: _updateIntervalSeconds),
      (_) => _publishSensorValues(),
    );

    // Publish stats immediately
    _publishSensorValues();
  }

  /// Stop stats update timer
  void _stopStatsUpdate() {
    _statsUpdateTimer?.cancel();
    _statsUpdateTimer = null;
  }

  /// Publish all sensor values via MQTT
  void _publishSensorValues() {
    if (!isConnected.value) return;

    try {
      // Get current values
      final batteryLevel = _sensorService.batteryLevel.value;
      final batteryState = _sensorService.batteryState.value;
      final cpuUsage = _sensorService.cpuUsage.value;
      final memoryUsage = _sensorService.memoryUsage.value;

      // Publish battery level - format as integer
      _publishDirectValue('battery', batteryLevel.toString());

      // Publish battery status
      _publishDirectValue('battery_status', batteryState);

      // Publish CPU usage - format as percentage with 1 decimal place
      _publishDirectValue('cpu_usage', (cpuUsage * 100).toStringAsFixed(1));

      // Publish memory usage - format as percentage with 1 decimal place
      _publishDirectValue(
          'memory_usage', (memoryUsage * 100).toStringAsFixed(1));

      // Get platform info
      String platform = 'unknown';
      if (Platform.isAndroid)
        platform = 'Android';
      else if (Platform.isIOS)
        platform = 'iOS';
      else if (Platform.isMacOS)
        platform = 'macOS';
      else if (Platform.isWindows)
        platform = 'Windows';
      else if (Platform.isLinux)
        platform = 'Linux';
      else if (kIsWeb) platform = 'Web'; // Publish platform info
      _publishDirectValue('platform', platform);

      // Get location values
      final latitude = _sensorService.latitude.value;
      final longitude = _sensorService.longitude.value;
      final altitude = _sensorService.altitude.value;
      final accuracy = _sensorService.accuracy.value;
      final locationStatus = _sensorService.locationStatus.value;

      // Publish location sensors
      _publishDirectValue('latitude', latitude.toStringAsFixed(6));
      _publishDirectValue('longitude', longitude.toStringAsFixed(6));
      _publishDirectValue('altitude', altitude.toStringAsFixed(2));
      _publishDirectValue('location_accuracy', accuracy.toStringAsFixed(2));
      _publishDirectValue('location_status', locationStatus);
    } catch (e) {
      print('Error publishing sensor values: $e');
    }
  }

  /// Subscribe to command topics
  void _subscribeToCommands() {
    if (!isConnected.value) {
      print('⚠️ Cannot subscribe to commands: MQTT not connected');
      return;
    }
    final commandTopic = 'kingkiosk/${deviceName.value}/command';
    final commandsTopic = 'kingkiosk/${deviceName.value}/commands';
    try {
      print('🔄 Subscribing to command topic: ${commandTopic}');
      _client!.subscribe(commandTopic, MqttQos.atMostOnce);
      print('🔄 Subscribing to commands topic: ${commandsTopic}');
      _client!.subscribe(commandsTopic, MqttQos.atMostOnce);
      print(
          '✅ Successfully requested subscription to command topics: ${commandTopic}, ${commandsTopic}');
      print('ℹ️ Device name being used: ${deviceName.value}');
      try {
        print('ℹ️ Attempting to list active subscriptions:');
        final connectionStatus = _client!.connectionStatus;
        print('   - Connection state: ${connectionStatus?.state}');
        print('   - Return code: ${connectionStatus?.returnCode}');
        print('   - Keep alive interval: ${_client!.keepAlivePeriod}');
      } catch (e) {
        print('⚠️ Cannot list subscriptions: ${e.toString()}');
      }
    } catch (e) {
      print('❌ Error subscribing to command topics: ${e.toString()}');
    }
  }

  /// Process received commands
  Future<void> _processCommand(String command) async {
    print('🎯 Processing command: "$command"');
    // Clean and strip comments from JSON
    var cleaned = _stripJsonComments(command);

    // Debug the raw payload
    print('📝 [MQTT] Raw payload after stripping comments: "$cleaned"');

    // Check if it looks like a quoted JSON string
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      try {
        // This could be a string-encoded JSON - decode to string first
        final decodedString = jsonDecode(cleaned);
        if (decodedString is String) {
          print('🔄 [MQTT] Detected quoted JSON string, unwrapping it');
          cleaned = decodedString;
          print('📝 [MQTT] Unwrapped payload: "$cleaned"');
        }
      } catch (e) {
        print('⚠️ [MQTT] Error unwrapping quoted string: $e');
        // Continue with original cleaned string
      }
    }

    // Now try parsing the actual JSON command
    dynamic cmdObj;
    try {
      cmdObj = jsonDecode(cleaned);
      if (cmdObj is String) {
        print('🔄 [MQTT] Detected nested JSON string, parsing inner JSON');
        final nestedClean = _stripJsonComments(cmdObj);
        cmdObj = jsonDecode(nestedClean);
      }
    } catch (e) {
      print('⚠️ [MQTT] JSON decode error: $e');
      cmdObj = null;
    } // Enhanced logging for better debugging
    print('🔄 [MQTT] Parsed cmdObj: $cmdObj (type: ${cmdObj?.runtimeType})');

    if (cmdObj == null) {
      print('❌ [MQTT] Failed to parse command JSON. Command will be ignored.');
      return;
    }

    if (cmdObj is Map) {
      print('🔄 [MQTT] cmdObj["command"]: ${cmdObj['command']}');
    } else {
      print('⚠️ [MQTT] cmdObj is not a Map, but ${cmdObj.runtimeType}');
      // Try to convert to Map if it's a valid JSON string
      if (cmdObj is String &&
          cmdObj.trim().startsWith('{') &&
          cmdObj.trim().endsWith('}')) {
        try {
          final jsonMap = jsonDecode(cmdObj) as Map<String, dynamic>;
          print('🔄 [MQTT] Successfully converted string to Map: $jsonMap');
          cmdObj = jsonMap;
        } catch (e) {
          print('❌ [MQTT] Failed to convert string to Map: $e');
          return;
        }
      } else {
        return; // Not a valid command, exit
      }
    }
    // --- Handle batch commands array first ---
    if (cmdObj['commands'] is List ||
        cmdObj['command']?.toString().toLowerCase() == 'batch') {
      // Check if another batch script is already running
      if (_batchScriptRunning) {
        final errorMsg =
            'Cannot start new batch script: another batch script is already running (ID: $_currentBatchId)';
        print('❌ [MQTT] $errorMsg');

        // Publish error to response topic if specified
        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(
              cmdObj['response_topic'],
              {
                'success': false,
                'error': errorMsg,
                'current_batch_id': _currentBatchId,
                'batch_status': batchStatus.value,
              },
              retain: false);
        }
        return;
      }

      // Start managed batch processing
      await _processManagedBatch(cmdObj);
      return;
    } // --- Only handle commands that are JSON with a 'command' key ---
    if (!cmdObj.containsKey('command')) {
      print('🎯 Ignoring non-command MQTT message (missing "command" field)');
      return;
    } // --- play_media command via {"command": "play_media", ...} ---
    if (cmdObj['command']?.toString().toLowerCase() == 'play_media') {
      String? type = cmdObj['type']?.toString();
      String? url = cmdObj['url']?.toString();
      String? style = cmdObj['style']?.toString();
      final bool loop =
          cmdObj['loop'] == true || cmdObj['loop']?.toString() == 'true';
      // Get the custom window ID if provided
      final String? windowId = cmdObj['window_id']?.toString();

      // Get hardware acceleration preference if provided
      bool? hardwareAccel;
      if (cmdObj.containsKey('hardware_accel')) {
        final hardwareAccelValue = cmdObj['hardware_accel'];
        if (hardwareAccelValue is bool) {
          hardwareAccel = hardwareAccelValue;
        } else if (hardwareAccelValue is String) {
          hardwareAccel = hardwareAccelValue.toLowerCase() == 'true';
        }
      }

      print(
          '🎬 play_media command received: type=$type, url=$url, style=$style, loop=$loop, hardwareAccel=$hardwareAccel' +
              (windowId != null ? ', id=$windowId' : ''));
      if (type == null) {
        // Try to infer type from url
        if (url != null && (url.endsWith('.mp4') || url.endsWith('.webm'))) {
          type = 'video';
        } else if (url != null &&
            (url.endsWith('.mp3') || url.endsWith('.wav'))) {
          type = 'audio';
        } else if (url != null &&
            (url.endsWith('.jpg') ||
                url.endsWith('.jpeg') ||
                url.endsWith('.png') ||
                url.endsWith('.gif') ||
                url.endsWith('.webp') ||
                url.endsWith('.bmp'))) {
          type = 'image';
        }
      }
      if (url == null || url.isEmpty) {
        print('⚠️ play_media command missing url');
        return;
      }
      try {
        final mediaService = Get.find<BackgroundMediaService>();

        // Set hardware acceleration preference if specified
        if (hardwareAccel != null) {
          try {
            final hardwareDetectionService =
                Get.find<MediaHardwareDetectionService>();
            hardwareDetectionService
                .setTemporaryHardwareAcceleration(hardwareAccel);
            print(
                '🎬 Setting hardware acceleration to: ${hardwareAccel ? 'enabled' : 'disabled'} for this media request');
          } catch (e) {
            print('⚠️ Error setting hardware acceleration preference: $e');
          }
        }
        if (type == 'audio') {
          final title = cmdObj['title']?.toString() ?? 'Kiosk Audio';
          if (style == 'window') {
            print(
                '🔊 [MQTT] Playing audio in window via BackgroundMediaService: $url, title=$title, loop=$loop' +
                    (windowId != null ? ', id=$windowId' : ''));
            final controller = Get.find<TilingWindowController>();
            // Use custom ID if provided, otherwise auto-generate
            if (windowId != null && windowId.isNotEmpty) {
              controller.addAudioTileWithId(windowId, title, url);
            } else {
              controller.addAudioTile(title, url);
            }
          } else if (style == 'visualizer') {
            print(
                '🎵 [MQTT] Playing audio with visualizer overlay: $url, title=$title, loop=$loop' +
                    (windowId != null ? ', id=$windowId' : ''));
            final controller = Get.find<TilingWindowController>();
            // Use custom ID if provided, otherwise auto-generate
            if (windowId != null && windowId.isNotEmpty) {
              controller.addAudioVisualizerTileWithId(windowId, title, url);
            } else {
              controller.addAudioVisualizerTile(title, url);
            }
          } else {
            // Try to use AudioService first for background audio (with caching support)
            try {
              print(
                  '🔊 [MQTT] Playing audio in background via AudioService with caching: $url, loop=$loop');
              final audioService = Get.find<AudioService>();
              audioService.playRemoteAudio(url, looping: loop);
            } catch (e) {
              print(
                  '❌ Error playing audio with AudioService: $e, falling back to BackgroundMediaService');
              // Fallback to MediaKit via BackgroundMediaService if AudioService fails
              print(
                  '🔊 [MQTT] Falling back to BackgroundMediaService for audio: $url, loop=$loop');
              mediaService.playAudio(url, loop: loop);
            }
          }
        } else if (type == 'video') {
          final title = cmdObj['title']?.toString() ?? 'Kiosk Video';
          if (style == 'fullscreen') {
            print(
                '🎥 [MQTT] Playing video fullscreen via BackgroundMediaService: $url, loop=$loop');
            mediaService.playVideoFullscreen(url, loop: loop);
          } else if (style == 'window') {
            print(
                '🎥 [MQTT] Playing video in window via BackgroundMediaService: $url, title=$title, loop=$loop' +
                    (windowId != null ? ', id=$windowId' : ''));
            mediaService.playVideoWindowed(url,
                loop: loop, title: title, windowId: windowId);
          } else {
            print(
                '🎥 [MQTT] Playing video (background/window) via BackgroundMediaService: $url, style=background, loop=$loop');
            mediaService.playVideo(url, loop: loop);
          }
        } else if (type == 'image') {
          final title = cmdObj['title']?.toString() ?? 'MQTT Image';
          final urlData = cmdObj['url'];
          if (urlData == null) {
            print('⚠️ Missing URL for image display');
            return;
          }
          if (windowId != null && windowId.isNotEmpty) {
            // Always create a window tile if windowId is provided
            final controller = Get.find<TilingWindowController>();
            controller.addImageTileWithId(windowId, title, urlData);
            print('🖼️ [MQTT] Displaying image in window with ID: $windowId');
          } else if (style == 'fullscreen') {
            mediaService.displayImageFullscreen(urlData);
          } else {
            mediaService.displayImageWindowed(urlData, title: title);
          }
        } else if (type == 'web') {
          // Not standard, but if you add web type, handle here
        } else {
          print('⚠️ Unknown play_media type or missing url');
        }
      } catch (e) {
        print('❌ Error calling BackgroundMediaService: $e');
      }
      return;
    }
    // --- open_browser command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'open_browser' &&
        cmdObj['url'] is String) {
      final url = cmdObj['url'] as String;
      final title = cmdObj['title']?.toString() ?? 'MQTT Web';
      final String? windowId = cmdObj['window_id']?.toString();
      try {
        final controller = Get.find<TilingWindowController>();
        // Use custom ID if provided, otherwise auto-generate
        if (windowId != null && windowId.isNotEmpty) {
          controller.addWebViewTileWithId(windowId, title, url);
        } else {
          controller.addWebViewTile(title, url);
        }
        print('🌐 [MQTT] Opened browser window for URL: $url, title=$title' +
            (windowId != null ? ', id=$windowId' : ''));
      } catch (e) {
        print('❌ Error opening browser window: $e');
      }
      return;
    }

    // --- youtube command via {"command": "youtube", ...} ---
    if (cmdObj['command']?.toString().toLowerCase() == 'youtube' &&
        cmdObj['url'] is String) {
      final url = cmdObj['url'] as String;
      final title = cmdObj['title']?.toString() ?? 'YouTube';
      final String? windowId = cmdObj['window_id']?.toString();
      try {
        final controller = Get.find<TilingWindowController>();
        // Extract YouTube video ID from URL
        final videoId = YouTubePlayerManager.extractVideoId(url);
        if (videoId == null) {
          print(
              '⚠️ [MQTT] Invalid YouTube URL: $url - could not extract video ID');
          return;
        }

        // Use custom ID if provided, otherwise auto-generate
        if (windowId != null && windowId.isNotEmpty) {
          controller.addYouTubeTileWithId(windowId, title, url, videoId);
        } else {
          controller.addYouTubeTile(title, url, videoId);
        }
        print('🎬 [MQTT] Opened YouTube player for URL: $url, title=$title' +
            (windowId != null ? ', id=$windowId' : ''));
      } catch (e) {
        print('❌ Error opening YouTube player: $e');
      }
      return;
    }

    // --- close_window command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'close_window') {
      final windowId = cmdObj['window_id'] as String?;
      if (windowId != null && windowId.isNotEmpty) {
        try {
          final controller = Get.find<TilingWindowController>();
          final tile =
              controller.tiles.firstWhereOrNull((t) => t.id == windowId);
          if (tile != null) {
            controller.closeTile(tile);
            print('🪟 [MQTT] Closed window with ID: $windowId');
          } else {
            print('⚠️ No window found with ID: $windowId');
          }
        } catch (e) {
          print('❌ Error closing window: $e');
        }
      } else {
        print('⚠️ close_window command missing window_id');
      }
      return;
    }
    // --- maximize_window command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'maximize_window') {
      final windowId = cmdObj['window_id'] as String?;
      if (windowId != null && windowId.isNotEmpty) {
        try {
          final controller = Get.find<TilingWindowController>();
          final tile =
              controller.tiles.firstWhereOrNull((t) => t.id == windowId);
          if (tile != null) {
            controller.maximizeTile(tile);
            print('🪟 [MQTT] Maximized window with ID: $windowId');
          } else {
            print('⚠️ No window found with ID: $windowId');
          }
        } catch (e) {
          print('❌ Error maximizing window: $e');
        }
      } else {
        print('⚠️ maximize_window command missing window_id');
      }
      return;
    } // --- minimize_window command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'minimize_window') {
      final windowId = cmdObj['window_id'] as String?;
      if (windowId != null && windowId.isNotEmpty) {
        try {
          final controller = Get.find<TilingWindowController>();
          final tile =
              controller.tiles.firstWhereOrNull((t) => t.id == windowId);
          if (tile != null) {
            controller.minimizeTile(tile);
            print('🪟 [MQTT] Minimized window with ID: $windowId');
          } else {
            print('⚠️ No window found with ID: $windowId');
          }
        } catch (e) {
          print('❌ Error minimizing window: $e');
        }
      } else {
        print('⚠️ minimize_window command missing window_id');
      }
      return;
    }

    // --- open_pdf command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'open_pdf' &&
        cmdObj['url'] is String) {
      final url = cmdObj['url'] as String;
      final title = cmdObj['title']?.toString() ?? 'PDF Document';
      final String? windowId = cmdObj['window_id']?.toString();
      try {
        final controller = Get.find<TilingWindowController>();
        // Use custom ID if provided, otherwise auto-generate
        if (windowId != null && windowId.isNotEmpty) {
          controller.addPdfTileWithId(windowId, title, url);
        } else {
          controller.addPdfTile(title, url);
        }
        print('📄 [MQTT] Opened PDF viewer for URL: $url, title=$title' +
            (windowId != null ? ', id=$windowId' : ''));
      } catch (e) {
        print('❌ Error opening PDF viewer: $e');
      }
      return;
    }

    // --- alert command for center-screen alerts ---
    if (cmdObj['command']?.toString().toLowerCase() == 'alert') {
      MqttNotificationHandler.processAlertCommand(cmdObj);
      return;
    }

    // --- notify command for sending notifications ---
    if (cmdObj['command']?.toString().toLowerCase() == 'notify') {
      MqttNotificationHandler.processNotifyCommand(cmdObj);
      return;
    }
    // Notification handling is delegated to MqttNotificationHandler

    // --- halo_effect command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'halo_effect') {
      _processHaloEffectCommand(cmdObj);
      return;
    }

    // --- person_detection command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'person_detection') {
      _processPersonDetectionCommand(cmdObj);
      return;
    }

    // --- screenshot command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'screenshot') {
      _processScreenshotCommand(cmdObj);
      return;
    }
    // --- play, pause, close for media windows via {command:..., window_id:...} ---
    final mediaWindowCommands = ['play', 'pause', 'close'];
    if (mediaWindowCommands
        .contains(cmdObj['command']?.toString().toLowerCase())) {
      final windowId =
          cmdObj['window_id']?.toString() ?? cmdObj['windowid']?.toString();
      final action = cmdObj['command']?.toString().toLowerCase();
      if (windowId != null && windowId.isNotEmpty && action != null) {
        try {
          final wm = Get.find<WindowManagerService>();
          final win = wm.getWindow(windowId);
          if (win != null && win.windowType == KioskWindowType.media) {
            print(
                '[MQTT] Routing "$action" to MediaWindowController for window_id: $windowId');
            win.handleCommand(action,
                cmdObj.map((key, value) => MapEntry(key.toString(), value)));
            print('[MQTT] Sent "$action" to media window with ID: $windowId');
          } else if (win == null) {
            print('[MQTT] No media window found with ID: $windowId');
          } else {
            print(
                '[MQTT] Window with ID $windowId is not a media window (type: [33m${win.windowType}[0m)');
          }
        } catch (e) {
          print(
              '[MQTT] Error processing $action command for media window ID $windowId: $e');
        }
      } else {
        print('[MQTT] $action command missing window_id');
      }
      return;
    }
    // --- pause_media command (legacy, DEPRECATED) ---
    if (cmdObj['command']?.toString().toLowerCase() == 'pause_media') {
      print(
          '[MQTT] WARNING: pause_media command is deprecated. Use {command: "pause", window_id: ...} instead.');
      final windowId = cmdObj['window_id'] as String?;
      if (windowId != null && windowId.isNotEmpty) {
        try {
          final wm = Get.find<WindowManagerService>();
          final win = wm.getWindow(windowId);
          if (win != null && win.windowType == KioskWindowType.media) {
            win.handleCommand('pause', null);
            print('⏸️ [MQTT] Paused media for window ID: $windowId');
          } else {
            print('⚠️ No media window found with ID: $windowId');
          }
        } catch (e) {
          print('❌ Error pausing media window: $e');
        }
      } else {
        print('⚠️ pause_media command missing window_id');
      }
      return;
    }
    // --- web window commands: refresh, restart, evaljs, loadurl ---
    final webWindowCommands = ['refresh', 'restart', 'evaljs', 'loadurl'];
    if (webWindowCommands
        .contains(cmdObj['command']?.toString().toLowerCase())) {
      final windowId =
          cmdObj['window_id']?.toString() ?? cmdObj['windowid']?.toString();
      final action = cmdObj['command']?.toString().toLowerCase();
      if (windowId != null && windowId.isNotEmpty && action != null) {
        try {
          final wm = Get.find<WindowManagerService>();
          final win = wm.getWindow(windowId);
          if (win != null && win.windowType == KioskWindowType.web) {
            print(
                '[MQTT] Routing "$action" to WebWindowController for window_id: $windowId');
            win.handleCommand(
              action,
              cmdObj.map((key, value) => MapEntry(key.toString(), value)),
            );
            print('[MQTT] Sent "$action" to web window with ID: $windowId');
          } else if (win == null) {
            print('[MQTT] No window found with ID: $windowId');
          } else {
            print(
                '[MQTT] Window with ID $windowId is not a web window (type: ${win.windowType})');
          }
        } catch (e) {
          print(
              '[MQTT] Error processing $action command for window ID $windowId: $e');
        }
      } else {
        print('[MQTT] $action command missing window_id');
      }
      return;
    }
    // --- System volume control via MQTT ---
    if (cmdObj['command']?.toString().toLowerCase() == 'set_volume') {
      final volume = double.tryParse(cmdObj['value']?.toString() ?? '');
      if (volume != null && volume >= 0.0 && volume <= 1.0) {
        try {
          // Set system volume using flutter_volume_controller
          await FlutterVolumeController.setVolume(volume);
          print('[MQTT] Set system volume to $volume');
        } catch (e) {
          print('[MQTT] Error setting system volume: $e');
        }
      } else {
        print('[MQTT] Invalid set_volume value: ${cmdObj['value']}');
      }
      return;
    }
    if (cmdObj['command']?.toString().toLowerCase() == 'mute') {
      try {
        await FlutterVolumeController.setMute(true);
        print('[MQTT] System volume muted');
      } catch (e) {
        print('[MQTT] Error muting system volume: $e');
      }
      return;
    }
    if (cmdObj['command']?.toString().toLowerCase() == 'unmute') {
      try {
        await FlutterVolumeController.setMute(false);
        print('[MQTT] System volume unmuted');
      } catch (e) {
        print('[MQTT] Error unmuting system volume: $e');
      }
      return;
    }
    // --- System brightness control via MQTT ---
    if (cmdObj['command']?.toString().toLowerCase() == 'set_brightness') {
      final brightness = double.tryParse(cmdObj['value']?.toString() ?? '');
      if (brightness != null && brightness >= 0.0 && brightness <= 1.0) {
        try {
          // Set system brightness using screen_brightness
          await ScreenBrightness().setScreenBrightness(brightness);
          print('[MQTT] Set system brightness to $brightness');
        } catch (e) {
          print('[MQTT] Error setting system brightness: $e');
        }
      } else {
        print('[MQTT] Invalid set_brightness value: [33m${cmdObj['value']}[0m');
      }
      return;
    }
    if (cmdObj['command']?.toString().toLowerCase() == 'get_brightness') {
      try {
        final currentBrightness = await ScreenBrightness().current;
        print('[MQTT] Current system brightness: $currentBrightness');
        // Optionally publish to a response topic
        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(
              cmdObj['response_topic'], {'brightness': currentBrightness},
              retain: false);
        }
      } catch (e) {
        print('[MQTT] Error getting system brightness: $e');
      }
      return;
    }
    if (cmdObj['command']?.toString().toLowerCase() == 'restore_brightness') {
      try {
        // If you have a saved brightness value, restore it here. For now, just set to 1.0 (max)
        await ScreenBrightness().setScreenBrightness(1.0);
        print('[MQTT] Restored system brightness to 1.0');
      } catch (e) {
        print('[MQTT] Error restoring system brightness: $e');
      }
      return;
    } // --- Emergency reset command for fixing media black screens ---
    if (cmdObj['command']?.toString().toLowerCase() == 'reset_media') {
      print('⚠️ [MQTT] Received emergency media reset command');

      // Parse optional parameters
      final bool forceReset = cmdObj['force'] == true ||
          cmdObj['force']?.toString().toLowerCase() == 'true';

      // Check if this is a test request
      final bool testOnly = cmdObj['test'] == true ||
          cmdObj['test']?.toString().toLowerCase() == 'true';

      try {
        final mediaRecoveryService = Get.find<MediaRecoveryService>();

        // Get media health status before reset
        final healthStatus = mediaRecoveryService.getMediaHealthStatus();
        print('📊 [MQTT] Media health status: $healthStatus');

        // If test-only mode, run the test but don't do a reset
        if (testOnly) {
          print('🧪 [MQTT] Running media health check test (no reset)');

          // Publish health status report
          if (isConnected.value && _client != null) {
            publishJsonToTopic(
              'kingkiosk/${deviceName.value}/status/media_health',
              healthStatus,
            );
          }
          return;
        }

        // Capture background audio state before reset
        final backgroundAudioState =
            await mediaRecoveryService.captureBackgroundAudioState();
        print('📝 [MQTT] Captured background audio state before reset');

        // Not a test, perform actual reset
        final result = await mediaRecoveryService.resetAllMediaResources(
            force: forceReset);

        // Report result
        if (result) {
          print('✅ [MQTT] Media reset completed successfully');

          // Restore background audio if it was playing
          if (backgroundAudioState['url'] != null) {
            try {
              await Future.delayed(Duration(milliseconds: 500));
              await mediaRecoveryService
                  .restoreBackgroundAudio(backgroundAudioState);
              print('✅ [MQTT] Background audio restored after reset');
            } catch (e) {
              print('❌ [MQTT] Error restoring background audio: $e');
            }
          }

          // Send status report back to MQTT if enabled
          try {
            if (isConnected.value && _client != null) {
              final topic = 'kingkiosk/${deviceName.value}/status/media_reset';

              // Create report payload
              final reportPayload = {
                'success': true,
                'timestamp': DateTime.now().toIso8601String(),
                'resetCount': mediaRecoveryService.recoveryCount.value,
                'forced': forceReset,
                'audioRestored': backgroundAudioState['url'] != null,
                'audioUrl': backgroundAudioState['url'],
              };

              // Publish using the existing method
              publishJsonToTopic(topic, reportPayload);
            }
          } catch (reportError) {
            print('⚠️ [MQTT] Error sending reset status report: $reportError');
          }
        } else {
          print(
              '⚠️ [MQTT] Media reset was not performed (cooldown or already in progress)');
        }
      } catch (e) {
        print('❌ [MQTT] Error during media reset: $e');
      }
      return;
    }

    // --- Media control for background audio commands ---
    final backgroundAudioCommands = [
      'play_audio',
      'pause_audio',
      'stop_audio',
      'seek_audio'
    ];
    if (backgroundAudioCommands
        .contains(cmdObj['command']?.toString().toLowerCase())) {
      final action = cmdObj['command']?.toString().toLowerCase();

      try {
        final mediaControlService = Get.find<MediaControlService>();
        bool success = false;

        if (action == 'play_audio') {
          print('▶️ [MQTT] Playing background audio');
          success = await mediaControlService.playBackgroundAudio();
        } else if (action == 'pause_audio') {
          print('⏸️ [MQTT] Pausing background audio');
          success = await mediaControlService.pauseBackgroundAudio();
        } else if (action == 'stop_audio') {
          print('⏹️ [MQTT] Stopping background audio');
          success = await mediaControlService.stopBackgroundAudio();
        } else if (action == 'seek_audio') {
          final position =
              double.tryParse(cmdObj['position']?.toString() ?? '0');
          if (position != null) {
            print('⏩ [MQTT] Seeking background audio to position $position');
            success = await mediaControlService.seekBackgroundAudio(position);
          } else {
            print('❌ [MQTT] Invalid seek position: ${cmdObj['position']}');
          }
        }

        if (success) {
          print('✅ [MQTT] Successfully performed $action on background audio');
        } else {
          print(
              '⚠️ [MQTT] Failed to perform $action on background audio - no audio playing or service error');
        }
      } catch (e) {
        print('❌ [MQTT] Error processing $action command: $e');
      }

      return;
    } // --- provision command for remote settings configuration ---

    if (cmdObj['command']?.toString().toLowerCase() == 'get_config') {
      _processGetConfigCommand(cmdObj);
      return;
    }
    if (cmdObj['command']?.toString().toLowerCase() == 'provision') {
      _processProvisionCommand(cmdObj);
      return;
    }
    // --- TTS (Text-to-Speech) command handling ---

    if (cmdObj['command']?.toString().toLowerCase() == 'tts' ||
        cmdObj['command']?.toString().toLowerCase() == 'speak' ||
        cmdObj['command']?.toString().toLowerCase() == 'say') {
      try {
        // Check if TTS service is available and initialized before using it
        if (!Get.isRegistered<TtsService>()) {
          print(
              '⚠️ [MQTT] TTS service not yet registered, cannot process TTS command');
          if (cmdObj['response_topic'] != null) {
            publishJsonToTopic(
                cmdObj['response_topic'],
                {
                  'error': 'TTS service not available',
                  'command': cmdObj['command'],
                  'timestamp': DateTime.now().toIso8601String(),
                },
                retain: false);
          }
          return;
        }

        final ttsService = Get.find<TtsService>();
        if (!ttsService.isInitialized.value) {
          print(
              '⚠️ [MQTT] TTS service not yet initialized, cannot process TTS command');
          if (cmdObj['response_topic'] != null) {
            publishJsonToTopic(
                cmdObj['response_topic'],
                {
                  'error': 'TTS service not initialized',
                  'command': cmdObj['command'],
                  'timestamp': DateTime.now().toIso8601String(),
                },
                retain: false);
          }
          return;
        }
        // Cast to proper type for TTS service
        final ttsCommand = Map<String, dynamic>.from(cmdObj);
        final result = await ttsService.handleMqttCommand(ttsCommand);
        print('🔊 [MQTT] TTS command result: $result');

        // Optionally publish result to response topic if specified
        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(cmdObj['response_topic'], result, retain: false);
        }
      } catch (e) {
        print('❌ [MQTT] Error processing TTS command: $e');
        // Optionally publish error to response topic
        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(cmdObj['response_topic'],
              {'success': false, 'error': 'TTS service not available: $e'},
              retain: false);
        }
      }
      return;
    }

    // --- open_clock command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'open_clock') {
      final title = cmdObj['title']?.toString() ?? 'Analog Clock';
      final String? windowId = cmdObj['window_id']?.toString();

      try {
        final controller = Get.find<TilingWindowController>();

        // Build configuration from MQTT parameters
        final Map<String, dynamic> config = {};

        // Mode configuration (analog/digital)
        final mode = cmdObj['mode']?.toString();
        if (mode != null) {
          config['mode'] = mode;
        }

        // Network image URL for clock background/decoration
        final imageUrl = cmdObj['image_url']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          config['image_url'] = imageUrl;
        }

        // Theme configuration
        final theme = cmdObj['theme']?.toString();
        if (theme != null) {
          config['theme'] = theme;
        }

        // Additional styling options
        final showNumbers = cmdObj['show_numbers'];
        if (showNumbers != null) {
          config['show_numbers'] = showNumbers == true ||
              showNumbers.toString().toLowerCase() == 'true';
        }

        final showSecondHand = cmdObj['show_second_hand'];
        if (showSecondHand != null) {
          config['show_second_hand'] = showSecondHand == true ||
              showSecondHand.toString().toLowerCase() == 'true';
        }

        // Use custom ID if provided, otherwise auto-generate
        if (windowId != null && windowId.isNotEmpty) {
          controller.addClockTileWithId(windowId, title, config: config);
        } else {
          controller.addClockTile(title, config: config);
        }

        print('🕐 [MQTT] Opened clock window: $title' +
            (windowId != null ? ', id=$windowId' : '') +
            ', config=$config');
      } catch (e) {
        print('❌ Error opening clock window: $e');
      }
      return;
    } // --- alarmo_widget command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'alarmo_widget') {
      final name = cmdObj['name']?.toString() ?? 'Alarmo';
      final String? windowId = cmdObj['window_id']?.toString();

      // Extract configuration parameters
      final Map<String, dynamic> config = {};
      if (cmdObj['entity'] != null) config['entity'] = cmdObj['entity'];
      if (cmdObj['require_code'] != null)
        config['require_code'] = cmdObj['require_code'];
      if (cmdObj['code_length'] != null)
        config['code_length'] = cmdObj['code_length'];
      if (cmdObj['state_topic'] != null)
        config['state_topic'] = cmdObj['state_topic'];
      if (cmdObj['command_topic'] != null)
        config['command_topic'] = cmdObj['command_topic'];
      if (cmdObj['event_topic'] != null)
        config['event_topic'] = cmdObj['event_topic'];
      if (cmdObj['available_modes'] != null)
        config['available_modes'] = cmdObj['available_modes'];

      try {
        final controller = Get.find<TilingWindowController>();
        // Use custom ID if provided, otherwise auto-generate
        if (windowId != null && windowId.isNotEmpty) {
          controller.addAlarmoTileWithId(windowId, name,
              config: config.isNotEmpty ? config : null);
        } else {
          controller.addAlarmoTile(name,
              config: config.isNotEmpty ? config : null);
        }
        print('🚨 [MQTT] Created Alarmo widget: $name' +
            (windowId != null ? ', id=$windowId' : '') +
            (config.isNotEmpty ? ', config=$config' : ''));
      } catch (e) {
        print('❌ Error creating Alarmo widget: $e');
      }
      return;
    }

    // --- open_weather_client command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'open_weather_client') {
      final name = cmdObj['name']?.toString() ?? 'Weather';
      final String? windowId = cmdObj['window_id']?.toString();

      // Extract configuration parameters
      final Map<String, dynamic> config = {};
      if (cmdObj['api_key'] != null) config['api_key'] = cmdObj['api_key'];
      if (cmdObj['location'] != null) config['location'] = cmdObj['location'];
      if (cmdObj['units'] != null) config['units'] = cmdObj['units'];
      if (cmdObj['language'] != null) config['language'] = cmdObj['language'];
      if (cmdObj['show_forecast'] != null)
        config['show_forecast'] = cmdObj['show_forecast'];
      if (cmdObj['auto_refresh'] != null)
        config['auto_refresh'] = cmdObj['auto_refresh'];

      try {
        final controller = Get.find<TilingWindowController>();
        // Use custom ID if provided, otherwise auto-generate
        if (windowId != null && windowId.isNotEmpty) {
          controller.addWeatherTileWithId(windowId, name,
              config: config.isNotEmpty ? config : null);
        } else {
          controller.addWeatherTile(name,
              config: config.isNotEmpty ? config : null);
        }
        print('🌤️ [MQTT] Created Weather widget: $name' +
            (windowId != null ? ', id=$windowId' : '') +
            (config.isNotEmpty ? ', config=$config' : ''));
      } catch (e) {
        print('❌ Error creating Weather widget: $e');
      }
      return;
    } // --- calendar command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'calendar') {
      final action = cmdObj['action']?.toString().toLowerCase();
      final name = cmdObj['name']?.toString() ?? 'Calendar';
      final String? windowId = cmdObj['window_id']?.toString();

      try {
        // Handle calendar widget management (show/hide)
        if (action == 'show' || action == 'create' || action == 'hide') {
          final controller = Get.find<TilingWindowController>();

          if (action == 'show' || action == 'create') {
            // Create or show calendar tile
            if (windowId != null && windowId.isNotEmpty) {
              controller.addCalendarTileWithId(windowId, name);
            } else {
              controller.addCalendarTile(name);
            }
            print('📅 [MQTT] Created Calendar widget: $name' +
                (windowId != null ? ', id=$windowId' : ''));
          } else if (action == 'hide' && windowId != null) {
            // Hide specific calendar tile
            final tile = controller.tiles.firstWhere(
                (tile) => tile.id == windowId,
                orElse: () =>
                    throw Exception('Calendar tile not found: $windowId'));
            controller.closeTile(tile);
            print('📅 [MQTT] Removed Calendar widget: $windowId');
          }
        } // Handle calendar event management
        else if (action == 'add_event' ||
            action == 'remove_event' ||
            action == 'clear_events' ||
            action == 'go_to_date' ||
            action == 'format') {
          try {
            final calendarController = Get.find<CalendarController>();
            calendarController
                .handleMqttCalendarCommand(Map<String, dynamic>.from(cmdObj));
            print('📅 [MQTT] Calendar event command processed: $action');
          } catch (e) {
            print(
                '❌ [MQTT] CalendarController not found, attempting to register...');
            // Try to register calendar controller if not found
            final calendarController = Get.put(CalendarController());
            calendarController
                .handleMqttCalendarCommand(Map<String, dynamic>.from(cmdObj));
            print(
                '📅 [MQTT] Calendar event command processed after registration: $action');
          }
        } else {
          print('❌ [MQTT] Unknown calendar action: $action');
        }
      } catch (e) {
        print('❌ Error processing calendar command: $e');
      }
      return;
    }

    // --- kill_batch_script command to stop running batch script ---
    if (cmdObj['command']?.toString().toLowerCase() == 'kill_batch_script') {
      final result = _killBatchScript();
      print('🛑 [MQTT] Kill batch script result: $result');

      // Publish result to response topic if specified
      if (cmdObj['response_topic'] != null) {
        publishJsonToTopic(
            cmdObj['response_topic'],
            {
              'success': result['success'],
              'message': result['message'],
              'killed_batch_id': result['killed_batch_id'],
              'command': 'kill_batch_script',
              'timestamp': DateTime.now().toIso8601String(),
            },
            retain: false);
      }
      return;
    }

    // --- batch_status command to check current batch status ---
    if (cmdObj['command']?.toString().toLowerCase() == 'batch_status') {
      final status = {
        'success': true,
        'batch_running': _batchScriptRunning,
        'batch_id': _currentBatchId,
        'status': batchStatus.value,
        'progress': batchProgress.value,
        'total': batchTotal.value,
        'kill_requested': _batchKillRequested,
        'command': 'batch_status',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📊 [MQTT] Batch status: $status');

      // Publish status to response topic if specified
      if (cmdObj['response_topic'] != null) {
        publishJsonToTopic(cmdObj['response_topic'], status, retain: false);
      }
      return;
    }

    // --- wait command for batch script delays ---
    if (cmdObj['command']?.toString().toLowerCase() == 'wait') {
      final seconds = double.tryParse(cmdObj['seconds']?.toString() ?? '1');
      if (seconds != null && seconds > 0 && seconds <= 300) {
        // Max 5 minutes
        print('⏱️ [MQTT] Wait command: pausing script for ${seconds} seconds');

        // Use Future.delayed to pause without blocking other operations
        await Future.delayed(Duration(milliseconds: (seconds * 1000).round()));

        print('✅ [MQTT] Wait completed after ${seconds} seconds');

        // Optionally publish completion to response topic
        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(
              cmdObj['response_topic'],
              {
                'success': true,
                'waited_seconds': seconds,
                'command': 'wait',
                'timestamp': DateTime.now().toIso8601String(),
              },
              retain: false);
        }
      } else {
        final errorMsg = seconds == null
            ? 'Invalid wait seconds value: ${cmdObj['seconds']}'
            : 'Wait seconds must be between 0 and 300, got: $seconds';
        print('❌ [MQTT] $errorMsg');

        // Publish error to response topic if specified
        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(
              cmdObj['response_topic'],
              {
                'success': false,
                'error': errorMsg,
                'command': 'wait',
                'timestamp': DateTime.now().toIso8601String(),
              },
              retain: false);
        }
      }
      return;
    }

    // --- Background control commands ---
    if (cmdObj['command']?.toString().toLowerCase() == 'set_background') {
      final type = cmdObj['type']?.toString(); // 'default', 'image', 'webview'
      final imagePath =
          cmdObj['image_path']?.toString() ?? cmdObj['image_url']?.toString();
      final webUrl = cmdObj['web_url']?.toString() ?? cmdObj['url']?.toString();

      try {
        final settingsController = Get.find<SettingsControllerFixed>();

        if (type != null && ['default', 'image', 'webview'].contains(type)) {
          settingsController.setBackgroundType(type);
          print('[MQTT] Set background type to: $type');

          if (type == 'image' && imagePath != null && imagePath.isNotEmpty) {
            settingsController.setBackgroundImagePath(imagePath);
            print('[MQTT] Set background image path to: $imagePath');
          } else if (type == 'webview' && webUrl != null && webUrl.isNotEmpty) {
            settingsController.setBackgroundWebUrl(webUrl);
            print('[MQTT] Set background web URL to: $webUrl');
          }

          // Publish success response if response_topic is provided
          if (cmdObj['response_topic'] != null) {
            publishJsonToTopic(
                cmdObj['response_topic'],
                {
                  'success': true,
                  'message': 'Background settings updated',
                  'type': type,
                  'image_path': imagePath,
                  'web_url': webUrl,
                },
                retain: false);
          }
        } else {
          final errorMsg =
              'Invalid background type. Must be: default, image, or webview';
          print('[MQTT] $errorMsg');

          if (cmdObj['response_topic'] != null) {
            publishJsonToTopic(
                cmdObj['response_topic'],
                {
                  'success': false,
                  'error': errorMsg,
                  'provided_type': type,
                },
                retain: false);
          }
        }
      } catch (e) {
        print('[MQTT] Error setting background: $e');

        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(
              cmdObj['response_topic'],
              {
                'success': false,
                'error': 'Error setting background: $e',
              },
              retain: false);
        }
      }
      return;
    }

    // --- Get background status command ---
    if (cmdObj['command']?.toString().toLowerCase() == 'get_background') {
      try {
        final settingsController = Get.find<SettingsControllerFixed>();
        final backgroundInfo = {
          'type': settingsController.backgroundType.value,
          'image_path': settingsController.backgroundImagePath.value,
          'web_url': settingsController.backgroundWebUrl.value,
        };

        print('[MQTT] Background status requested');

        // Publish to response topic if provided, otherwise to default status topic
        final responseTopic = cmdObj['response_topic']?.toString() ??
            'kiosk/${deviceName.value}/status/background';
        publishJsonToTopic(
            responseTopic,
            {
              'success': true,
              'background': backgroundInfo,
            },
            retain: false);
      } catch (e) {
        print('[MQTT] Error getting background status: $e');

        if (cmdObj['response_topic'] != null) {
          publishJsonToTopic(
              cmdObj['response_topic'],
              {
                'success': false,
                'error': 'Error getting background status: $e',
              },
              retain: false);
        }
      }
      return;
    }

    // ...existing code...
  }

  /// Process get_config command to return all current settings
  Future<void> _processGetConfigCommand(Map<dynamic, dynamic> cmdObj) async {
    print('🛠️ [MQTT] Processing get_config command');
    try {
      final storageService = Get.find<StorageService>();

      final keys = [
        AppConstants.keyIsDarkMode,
        AppConstants.keyKioskMode,
        AppConstants.keyShowSystemInfo,
        AppConstants.keyKioskStartUrl,
        AppConstants.keyPersonDetectionEnabled,
        AppConstants.keyMqttEnabled,
        AppConstants.keyMqttBrokerUrl,
        AppConstants.keyMqttBrokerPort,
        AppConstants.keyMqttUsername,
        AppConstants.keyMqttPassword,
        AppConstants.keyDeviceName,
        AppConstants.keyMqttHaDiscovery,
        AppConstants.keySipEnabled,
        AppConstants.keySipServerHost,
        AppConstants.keySipProtocol,
        AppConstants.keySelectedAudioInput,
        AppConstants.keySelectedVideoInput,
        AppConstants.keySelectedAudioOutput,
        AppConstants.keyWyomingHost,
        AppConstants.keyWyomingPort,
        AppConstants.keyWyomingEnabled,
        AppConstants.keyAiProviderHost,
        AppConstants.keyAiEnabled,
        AppConstants.keyLatestScreenshot,
        AppConstants.keyWebsocketUrl,
        AppConstants.keyMediaServerUrl,
      ];

      final config = {for (final k in keys) k: storageService.read(k)};

      final response = {
        'command': 'get_config',
        'status': 'success',
        'device_name': deviceName.value,
        'config': config,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final respTopic = cmdObj['response_topic']?.toString() ??
          'kingkiosk/${deviceName.value}/config/response';
      publishJsonToTopic(respTopic, response, retain: false);
      print('🛠️ [MQTT] Sent current config to $respTopic');
    } catch (e) {
      print('❌ [MQTT] Error processing get_config: $e');
    }
  }

  /// Publish a direct value to a sensor topic without wrapping it in JSON
  void _publishDirectValue(String name, String value) {
    if (!isConnected.value) return;

    final topic = 'kingkiosk/${deviceName.value}/$name';
    final builder = MqttClientPayloadBuilder();

    // Directly publish the value as a string - Home Assistant expects this format
    builder.addString(value);

    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }

  /// Force publish all sensors immediately - used for debugging
  void forcePublishAllSensors() {
    if (!isConnected.value) {
      print('MQTT DEBUG: Not connected, cannot force publish');
      return;
    }

    try {
      print('MQTT DEBUG: Force publishing all sensors with detailed logging');

      // Enhancing with more device info logging
      print('MQTT DEBUG: Current device information:');
      print('MQTT DEBUG: Device name: ${deviceName.value}');
      print(
          'MQTT DEBUG: Connection state: ${_client!.connectionStatus!.state}');
      print('MQTT DEBUG: Client ID: ${_client!.clientIdentifier}');

      // List all client properties
      print('MQTT DEBUG: Client properties:');
      print('MQTT DEBUG: - Keep alive: ${_client!.keepAlivePeriod}');
      print('MQTT DEBUG: - Auto reconnect: ${_client!.autoReconnect}');

      // Try to get connection message details safely
      try {
        print(
            'MQTT DEBUG: - Connection message: ${_client!.connectionMessage.toString()}');
      } catch (e) {
        print('MQTT DEBUG: - Connection message not available: $e');
      }

      // First delete existing discovery configs
      _deleteAllDiscoveryConfigs();

      // Wait briefly
      Future.delayed(Duration(milliseconds: 300), () {
        // Then re-create all discovery configs with debug logging
        _setupHomeAssistantDiscoveryWithDebug();

        // Wait for discovery to be processed, then publish values
        Future.delayed(Duration(milliseconds: 500), () {
          _publishSensorValuesWithDebug();

          // Run MQTT messaging tests to verify functionality with longer delays
          print('MQTT DEBUG: Running MQTT messaging tests after 2 seconds...');
          Future.delayed(Duration(seconds: 2), () {
            // First, re-subscribe to important topics
            _subscribeToCommands();
            // Then run the test (removed testCommandProcessing call)
          });
        });
      });
    } catch (e) {
      print('MQTT DEBUG: Error in force publish: $e');
    }
  }

  /// Delete all existing discovery configs - helps with troubleshooting
  void _deleteAllDiscoveryConfigs() {
    if (!isConnected.value) return;

    try {
      print('MQTT DEBUG: Deleting all existing discovery configs');
      final sensors = [
        'battery',
        'battery_status',
        'cpu_usage',
        'memory_usage',
        'platform',
        'latitude',
        'longitude',
        'altitude',
        'location_accuracy',
        'location_status',
        'object_detection',
        'person_presence',
        'person_confidence'
      ];

      for (final sensor in sensors) {
        final topic = 'homeassistant/sensor/${deviceName.value}_$sensor/config';
        // To delete a retained message, publish an empty message
        _client!.publishMessage(
            topic, MqttQos.atLeastOnce, MqttClientPayloadBuilder().payload!,
            retain: true);
        print('MQTT DEBUG: Deleted discovery config for $sensor');
      }
    } catch (e) {
      print('MQTT DEBUG: Error deleting configs: $e');
    }
  }

  /// Set up discovery with additional debug logging
  void _setupHomeAssistantDiscoveryWithDebug() {
    if (!isConnected.value || !haDiscovery.value) return;

    try {
      print('MQTT DEBUG: Setting up all discovery sensors with debug logging');

      // Set up the key sensors one by one with debug logging
      print('MQTT DEBUG: Setting up battery level sensor');
      _setupDiscoverySensorWithDebug(
          'battery', 'Battery Level', 'battery', '%', 'mdi:battery');
      print('MQTT DEBUG: Setting up battery status sensor');
      _setupDiscoverySensorWithDebug(
          'battery_status', 'Battery Status', 'enum', '', 'mdi:battery-alert');

      // Location sensors
      print('MQTT DEBUG: Setting up location sensors');
      _setupDiscoverySensorWithDebug(
          'latitude', 'Latitude', 'none', '°', 'mdi:map-marker');
      _setupDiscoverySensorWithDebug(
          'longitude', 'Longitude', 'none', '°', 'mdi:map-marker');
      _setupDiscoverySensorWithDebug(
          'altitude', 'Altitude', 'distance', 'm', 'mdi:elevation-rise');
      _setupDiscoverySensorWithDebug('location_accuracy', 'Location Accuracy',
          'distance', 'm', 'mdi:crosshairs-gps');
      _setupDiscoverySensorWithDebug(
          'location_status', 'Location Status', 'enum', '', 'mdi:map-check');

      // Person Detection Sensors
      print('MQTT DEBUG: Setting up person detection sensors');
      _setupPersonDetectionDiscovery();
    } catch (e) {
      print('MQTT DEBUG: Error setting up discovery: $e');
    }
  }

  /// Set up person detection discovery sensors with JSON value templates
  void _setupPersonDetectionDiscovery() {
    // Object Detection sensor (JSON payload)
    _setupJsonDiscoverySensor(
      'object_detection',
      'Object Detection',
      'kingkiosk/${deviceName.value}/object_detection',
      '{{ value_json.total_objects }}',
      icon: 'mdi:eye',
      attributes: true,
    );

    // Person Presence sensor (JSON payload)
    _setupJsonDiscoverySensor(
      'person_presence',
      'Person Presence',
      'kingkiosk/${deviceName.value}/person_presence',
      '{{ "ON" if value_json.person_present else "OFF" }}',
      deviceClass: 'occupancy',
      icon: 'mdi:human',
      attributes: true,
    );

    // Person Confidence sensor (JSON payload from person_presence topic)
    _setupJsonDiscoverySensor(
      'person_confidence',
      'Person Confidence',
      'kingkiosk/${deviceName.value}/person_presence',
      '{{ (value_json.confidence * 100) | round(1) }}',
      unit: '%',
      icon: 'mdi:percent',
    );
  }

  /// Set up a JSON-based discovery sensor with value templates
  void _setupJsonDiscoverySensor(
    String name,
    String displayName,
    String stateTopic,
    String valueTemplate, {
    String? deviceClass,
    String? unit,
    String? icon,
    bool attributes = false,
  }) {
    final discoveryTopic =
        'homeassistant/sensor/${deviceName.value}_$name/config';

    final Map<String, dynamic> payloadMap = {
      "name": displayName,
      "unique_id": "${deviceName.value}_$name",
      "state_topic": stateTopic,
      "value_template": valueTemplate,
      "icon": icon ?? "mdi:information-outline",
      "device": {
        "identifiers": ["${deviceName.value}"],
        "name": deviceName.value,
        "model": "King Kiosk",
        "manufacturer": "King Kiosk"
      },
      "availability_topic": "kingkiosk/${deviceName.value}/status",
      "payload_available": "online",
      "payload_not_available": "offline"
    };

    // Add device class if specified
    if (deviceClass != null && deviceClass.isNotEmpty) {
      payloadMap["device_class"] = deviceClass;
    }

    // Add unit if specified
    if (unit != null && unit.isNotEmpty) {
      payloadMap["unit_of_measurement"] = unit;
    }

    // Add JSON attributes topic if requested
    if (attributes) {
      payloadMap["json_attributes_topic"] = stateTopic;
    }

    final payload = jsonEncode(payloadMap);
    print('MQTT DEBUG: Discovery payload for $name: $payload');
    print('MQTT DEBUG: Publishing to topic: $discoveryTopic');

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(
      discoveryTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
    print('MQTT DEBUG: Published discovery config for $name');
  }

  /// Set up a single discovery sensor with detailed logging
  void _setupDiscoverySensorWithDebug(
      String name, String displayName, String deviceClass, String unit,
      [String? icon]) {
    final discoveryTopic =
        'homeassistant/sensor/${deviceName.value}_$name/config'; // Use valid Home Assistant device_class values
    // See https://www.home-assistant.io/integrations/sensor/#device-class
    String validDeviceClass = deviceClass;
    if (deviceClass == 'cpu') {
      // CPU is not a valid device class in Home Assistant
      validDeviceClass = ''; // empty will use default sensor
    } else if (deviceClass == 'memory') {
      // Memory is not a valid device class in Home Assistant
      validDeviceClass = ''; // empty will use default sensor
    } else if (deviceClass == 'location') {
      // Location is not a valid device class in Home Assistant
      validDeviceClass = ''; // empty will use default sensor
    }

    // Create a proper JSON structure as a map
    final Map<String, dynamic> payloadMap = {
      "name": displayName,
      "unique_id": "${deviceName.value}_$name",
      "state_topic": "kingkiosk/${deviceName.value}/$name",
      "value_template": "{{ value }}", // Important for direct value parsing
      "icon": icon ??
          "mdi:${deviceClass == 'battery' ? 'battery' : deviceClass == 'memory' ? 'memory' : deviceClass == 'cpu' ? 'cpu-64-bit' : 'information-outline'}",
      "device": {
        "identifiers": ["${deviceName.value}"],
        "name": deviceName.value,
        "model": "King Kiosk",
        "manufacturer": "King Kiosk"
      },
      "availability_topic": "kingkiosk/${deviceName.value}/status",
      "payload_available": "online",
      "payload_not_available": "offline"
    };

    // Only add device_class if it's valid and not empty
    if (validDeviceClass.isNotEmpty) {
      payloadMap["device_class"] = validDeviceClass;
    }

    // Add unit of measurement if not empty
    if (unit.isNotEmpty) {
      payloadMap["unit_of_measurement"] = unit;
    }

    // Convert to JSON string
    final payload = jsonEncode(payloadMap);

    // Log the formatted payload for debugging
    print('MQTT DEBUG: Discovery payload for $name: $payload');
    print('MQTT DEBUG: Publishing to topic: $discoveryTopic');

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(
      discoveryTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
    print('MQTT DEBUG: Published discovery config for $name');
  }

  /// Publish sensor values with detailed debug info
  void _publishSensorValuesWithDebug() {
    if (!isConnected.value) return;

    try {
      print('MQTT DEBUG: Publishing all sensor values with debug info');

      // Get current values
      final batteryLevel = _sensorService.batteryLevel.value;
      final batteryState = _sensorService.batteryState.value;
      final cpuUsage = _sensorService.cpuUsage.value;
      final memoryUsage = _sensorService.memoryUsage.value;

      print('MQTT DEBUG: Current sensor values:');
      print('MQTT DEBUG: Battery level: $batteryLevel');
      print('MQTT DEBUG: Battery status: $batteryState');
      print('MQTT DEBUG: CPU usage: ${(cpuUsage * 100).toStringAsFixed(1)}%');
      print(
          'MQTT DEBUG: Memory usage: ${(memoryUsage * 100).toStringAsFixed(1)}%');

      // Publish battery level
      _publishDirectValueWithDebug('battery', batteryLevel.toString());
      // Publish battery status
      _publishDirectValueWithDebug('battery_status', batteryState);

      // Publish CPU usage - format as percentage with 1 decimal place
      _publishDirectValueWithDebug(
          'cpu_usage', (cpuUsage * 100).toStringAsFixed(1));

      // Publish memory usage - format as percentage with 1 decimal place
      _publishDirectValueWithDebug(
          'memory_usage', (memoryUsage * 100).toStringAsFixed(1));

      // Get platform info
      String platform = 'unknown';
      if (Platform.isAndroid)
        platform = 'Android';
      else if (Platform.isIOS)
        platform = 'iOS';
      else if (Platform.isMacOS)
        platform = 'macOS';
      else if (Platform.isWindows)
        platform = 'Windows';
      else if (Platform.isLinux)
        platform = 'Linux';
      else if (kIsWeb) platform = 'Web'; // Publish platform info
      _publishDirectValueWithDebug('platform', platform);

      // Get location values
      final latitude = _sensorService.latitude.value;
      final longitude = _sensorService.longitude.value;
      final altitude = _sensorService.altitude.value;
      final accuracy = _sensorService.accuracy.value;
      final locationStatus = _sensorService.locationStatus.value;

      print('MQTT DEBUG: Location values:');
      print('MQTT DEBUG: Latitude: ${latitude.toStringAsFixed(6)}');
      print('MQTT DEBUG: Longitude: ${longitude.toStringAsFixed(6)}');
      print('MQTT DEBUG: Altitude: ${altitude.toStringAsFixed(2)}m');
      print('MQTT DEBUG: Accuracy: ${accuracy.toStringAsFixed(2)}m');
      print('MQTT DEBUG: Location status: $locationStatus');

      // Publish location sensors
      _publishDirectValueWithDebug('latitude', latitude.toStringAsFixed(6));
      _publishDirectValueWithDebug('longitude', longitude.toStringAsFixed(6));
      _publishDirectValueWithDebug('altitude', altitude.toStringAsFixed(2));
      _publishDirectValueWithDebug(
          'location_accuracy', accuracy.toStringAsFixed(2));
      _publishDirectValueWithDebug('location_status', locationStatus);

      print('MQTT DEBUG: Finished publishing all sensor values');
    } catch (e) {
      print('MQTT DEBUG: Error publishing sensor values: $e');
    }
  }

  /// Publish a direct value to a sensor topic with debug info
  void _publishDirectValueWithDebug(String name, String value) {
    if (!isConnected.value) return;

    final topic = 'kingkiosk/${deviceName.value}/$name';
    final builder = MqttClientPayloadBuilder();

    // Directly publish the value as a string
    builder.addString(value);

    print('MQTT DEBUG: Publishing to topic $topic: "$value"');

    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
    print('MQTT DEBUG: Published value for $name');
  }

  /// Process person detection command
  void _processPersonDetectionCommand(Map<dynamic, dynamic> cmdObj) {
    print('👤 [MQTT] Processing person detection command');
    try {
      // Check if action is specified (enable/disable/toggle/status)
      final action = cmdObj['action']?.toString().toLowerCase() ?? 'toggle';

      // Try to find the PersonDetectionService
      try {
        final personDetectionService = Get.find<PersonDetectionService>();

        switch (action) {
          case 'enable':
            personDetectionService.isEnabled.value = true;
            print('👤 [MQTT] Person detection enabled via MQTT');
            break;
          case 'disable':
            personDetectionService.isEnabled.value = false;
            print('👤 [MQTT] Person detection disabled via MQTT');
            break;
          case 'toggle':
            personDetectionService.toggleEnabled();
            print('👤 [MQTT] Person detection toggled via MQTT');
            break;
          case 'status':
            // Just send status, don't change anything
            print('👤 [MQTT] Person detection status requested via MQTT');
            break;
          default:
            print('⚠️ [MQTT] Unknown person detection action: $action');
            return;
        }

        // Get current status for response
        final status = personDetectionService.getStatus();

        // Send confirmation message if requested
        if (cmdObj['confirm'] == true) {
          try {
            final confirmTopic =
                'kingkiosk/${deviceName.value}/person_detection/status';
            final builder = MqttClientPayloadBuilder();
            builder.addString(jsonEncode({
              'status': 'success',
              'action': action,
              'person_detection': status,
              'timestamp': DateTime.now().toIso8601String(),
            }));
            _client?.publishMessage(
                confirmTopic, MqttQos.atLeastOnce, builder.payload!);
            print('👤 [MQTT] Sent person detection confirmation message');
          } catch (e) {
            print('❌ Error sending person detection confirmation message: $e');
          }
        }

        // Always publish current status to dedicated topic
        try {
          final statusTopic = 'kingkiosk/${deviceName.value}/person_presence';
          publishJsonToTopic(statusTopic, status);
          print('👤 [MQTT] Published person detection status');
        } catch (e) {
          print('❌ Error publishing person detection status: $e');
        }
      } catch (e) {
        print('❌ PersonDetectionService not available: $e');

        // Send error response if confirmation was requested
        if (cmdObj['confirm'] == true) {
          try {
            final confirmTopic =
                'kingkiosk/${deviceName.value}/person_detection/status';
            final builder = MqttClientPayloadBuilder();
            builder.addString(jsonEncode({
              'status': 'error',
              'action': action,
              'error': 'PersonDetectionService not available',
              'timestamp': DateTime.now().toIso8601String(),
            }));
            _client?.publishMessage(
                confirmTopic, MqttQos.atLeastOnce, builder.payload!);
            print('👤 [MQTT] Sent person detection error message');
          } catch (e) {
            print('❌ Error sending person detection error message: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error processing person detection command: $e');
    }
  }

  /// Process screenshot command
  Future<void> _processScreenshotCommand(Map<dynamic, dynamic> cmdObj) async {
    print('📸 [MQTT] Processing screenshot command');
    try {
      // Try to find or create the screenshot service
      ScreenshotService? screenshotService;
      try {
        screenshotService = Get.find<ScreenshotService>();
        print('✅ Found existing ScreenshotService');
      } catch (e) {
        print('⚠️ ScreenshotService not found, creating a new instance');
        screenshotService = ScreenshotService();
        Get.put(screenshotService, permanent: true);
      }

      // Show a snackbar notification to indicate a screenshot is being taken (optional)
      if (cmdObj['notify'] == true) {
        Get.snackbar(
          'Taking Screenshot',
          'A screenshot was requested remotely',
          duration: Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Capture the screenshot
      final bytes = await screenshotService.captureScreenshot();
      if (bytes == null) {
        print('❌ Failed to capture screenshot');
        return;
      }

      // Get the file path for the screenshot
      final path = screenshotService.latestScreenshotPath.value;
      if (path.isEmpty) {
        print('❌ Screenshot path is empty');
        return;
      }

      print('📸 [MQTT] Screenshot taken and saved to: $path');

      // Convert image to base64 for MQTT transmission if Home Assistant discovery is enabled
      if (haDiscovery.value) {
        final base64Image = screenshotService.imageToBase64(bytes);
        if (base64Image.isNotEmpty) {
          // Publish to Home Assistant
          _publishScreenshotToHomeAssistant(base64Image);
          print('📸 [MQTT] Screenshot published to Home Assistant');

          // Send confirmation message if requested
          if (cmdObj['confirm'] == true) {
            final confirmTopic =
                'kingkiosk/${deviceName.value}/screenshot/status';
            final builder = MqttClientPayloadBuilder();
            builder.addString(jsonEncode({
              'status': 'success',
              'timestamp': DateTime.now().toIso8601String(),
              'path': path
            }));
            _client?.publishMessage(
                confirmTopic, MqttQos.atLeastOnce, builder.payload!,
                retain: false);
            print('📸 [MQTT] Screenshot confirmation published');
          }
        }
      }
    } catch (e) {
      print('❌ Error processing screenshot command: $e');

      // Send error message if confirm was requested
      if (cmdObj['confirm'] == true) {
        try {
          final confirmTopic =
              'kingkiosk/${deviceName.value}/screenshot/status';
          final builder = MqttClientPayloadBuilder();
          builder.addString(jsonEncode({
            'status': 'error',
            'timestamp': DateTime.now().toIso8601String(),
            'error': e.toString()
          }));
          _client?.publishMessage(
              confirmTopic, MqttQos.atLeastOnce, builder.payload!,
              retain: false);
        } catch (_) {
          // Ignore errors in error handling
        }
      }
    }
  }

  /// Publish screenshot to Home Assistant
  void _publishScreenshotToHomeAssistant(String base64Image) {
    try {
      // First setup discovery config if not already done
      _setupScreenshotSensorDiscovery();
      // Then publish the actual image data
      final topic = 'kingkiosk/${deviceName.value}/screenshot';
      final builder = MqttClientPayloadBuilder();
      builder.addString(base64Image);
      _client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
          retain: true);
      print('📤 Published screenshot to Home Assistant');
    } catch (e) {
      print('❌ Error publishing screenshot to Home Assistant: $e');
    }
  }

  /// Setup Home Assistant discovery for the screenshot sensor
  void _setupScreenshotSensorDiscovery() {
    if (!isConnected.value || !haDiscovery.value) return;

    try {
      final deviceNameStr = deviceName.value;
      final discoveryTopic =
          'homeassistant/camera/${deviceNameStr}_screenshot/config';

      // Create discovery config
      final Map<String, dynamic> discoveryConfig = {
        "name": "${deviceNameStr} Screenshot",
        "unique_id": "${deviceNameStr}_screenshot",
        "topic": "kingkiosk/${deviceNameStr}/screenshot",
        "device": {
          "identifiers": ["${deviceNameStr}"],
          "name": deviceNameStr,
          "model": "King Kiosk",
          "manufacturer": "King Kiosk"
        },
        "availability_topic": "kingkiosk/${deviceNameStr}/status",
        "payload_available": "online",
        "payload_not_available": "offline"
      };
      // Convert to JSON and publish
      final payload = jsonEncode(discoveryConfig);
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      _client?.publishMessage(
          discoveryTopic, MqttQos.atLeastOnce, builder.payload!,
          retain: true);
      print('✅ Setup Home Assistant discovery for screenshot sensor');
    } catch (e) {
      print('❌ Error setting up screenshot sensor discovery: $e');
    }
  }

  /// Process provision command for remote settings configuration
  void _processProvisionCommand(Map<dynamic, dynamic> cmdObj) async {
    print('🔧 [MQTT] Processing provision command: ${jsonEncode(cmdObj)}');

    try {
      final Map<String, dynamic> response = {
        'command': 'provision',
        'status': 'processing',
        'timestamp': DateTime.now().toIso8601String(),
        'applied_settings': <String>[],
        'failed_settings': <String, String>{},
      };

      // Get settings payload - can be under 'settings' or direct in command
      Map<String, dynamic>? settings;
      if (cmdObj.containsKey('settings') && cmdObj['settings'] is Map) {
        settings = Map<String, dynamic>.from(cmdObj['settings']);
      } else {
        // Filter out command-specific keys and treat the rest as settings
        settings = Map<String, dynamic>.from(cmdObj);
        settings.remove('command');
        settings.remove('response_topic');
        settings.remove('confirm');
      }

      if (settings.isEmpty) {
        print('⚠️ [MQTT] No settings provided in provision command');
        response['status'] = 'error';
        response['error'] = 'No settings provided';
        _sendProvisionResponse(cmdObj, response);
        return;
      }

      print('🔧 [MQTT] Provisioning ${settings.length} settings...');

      // Try to get settings controller
      SettingsController? settingsController;
      try {
        if (Get.isRegistered<SettingsController>()) {
          settingsController = Get.find<SettingsController>();
        } else if (Get.isRegistered<SettingsControllerFixed>()) {
          settingsController = Get.find<SettingsControllerFixed>();
        }
      } catch (e) {
        print('⚠️ [MQTT] Could not get settings controller: $e');
      }

      // Process each setting
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        try {
          bool applied = await _applySetting(key, value, settingsController);

          if (applied) {
            (response['applied_settings'] as List<String>).add(key);
            print('✅ [MQTT] Applied setting: $key = $value');
          } else {
            (response['failed_settings'] as Map<String, String>)[key] =
                'Setting not recognized or could not be applied';
            print('⚠️ [MQTT] Failed to apply setting: $key = $value');
          }
        } catch (e) {
          (response['failed_settings'] as Map<String, String>)[key] =
              e.toString();
          print('❌ [MQTT] Error applying setting $key: $e');
        }
      }

      // Determine overall status
      final appliedCount = (response['applied_settings'] as List).length;
      final failedCount = (response['failed_settings'] as Map).length;

      if (appliedCount > 0 && failedCount == 0) {
        response['status'] = 'success';
        response['message'] = 'All $appliedCount settings applied successfully';
      } else if (appliedCount > 0 && failedCount > 0) {
        response['status'] = 'partial';
        response['message'] =
            '$appliedCount settings applied, $failedCount failed';
      } else {
        response['status'] = 'error';
        response['message'] = 'No settings could be applied';
      }

      print(
          '🔧 [MQTT] Provision completed: ${response['status']} - ${response['message']}');

      // Send response
      _sendProvisionResponse(cmdObj, response);
    } catch (e) {
      print('❌ [MQTT] Error processing provision command: $e');

      final errorResponse = {
        'command': 'provision',
        'status': 'error',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'applied_settings': <String>[],
        'failed_settings': <String, String>{},
      };

      _sendProvisionResponse(cmdObj, errorResponse);
    }
  }

  /// Apply a single setting during provisioning
  Future<bool> _applySetting(
      String key, dynamic value, SettingsController? controller) async {
    try {
      final storageService = Get.find<StorageService>();

      switch (key.toLowerCase()) {
        // Theme settings
        case 'isdarkmode':
        case 'darkmode':
        case 'dark_mode':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyIsDarkMode, boolValue);
            controller?.isDarkMode.value = boolValue;
            controller?.toggleTheme();
            return true;
          }
          break;

        // App settings
        case 'kioskmode':
        case 'kiosk_mode':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyKioskMode, boolValue);
            controller?.kioskMode.value = boolValue;
            controller?.toggleKioskMode();
            return true;
          }
          break;

        case 'showsysteminfo':
        case 'show_system_info':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyShowSystemInfo, boolValue);
            controller?.showSystemInfo.value = boolValue;
            return true;
          }
          break;

        case 'kioskstarturl':
        case 'kiosk_start_url':
        case 'starturl':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write(AppConstants.keyKioskStartUrl, stringValue);
            controller?.kioskStartUrl.value = stringValue;
            controller?.kioskStartUrlController.text = stringValue;
            return true;
          }
          break;

        // MQTT settings
        case 'mqttenabled':
        case 'mqtt_enabled':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyMqttEnabled, boolValue);
            controller?.mqttEnabled.value = boolValue;
            return true;
          }
          break;

        case 'mqttbrokerurl':
        case 'mqtt_broker_url':
        case 'brokerurl':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write(AppConstants.keyMqttBrokerUrl, stringValue);
            controller?.mqttBrokerUrl.value = stringValue;
            controller?.mqttBrokerUrlController.text = stringValue;
            return true;
          }
          break;

        case 'mqttbrokerport':
        case 'mqtt_broker_port':
        case 'brokerport':
          final intValue = _parseInt(value);
          if (intValue != null && intValue > 0 && intValue <= 65535) {
            storageService.write(AppConstants.keyMqttBrokerPort, intValue);
            controller?.mqttBrokerPort.value = intValue;
            return true;
          }
          break;

        case 'mqttusername':
        case 'mqtt_username':
          final stringValue = value?.toString() ?? '';
          storageService.write(AppConstants.keyMqttUsername, stringValue);
          controller?.mqttUsername.value = stringValue;
          controller?.mqttUsernameController.text = stringValue;
          return true;

        case 'mqttpassword':
        case 'mqtt_password':
          final stringValue = value?.toString() ?? '';
          storageService.write(AppConstants.keyMqttPassword, stringValue);
          controller?.mqttPassword.value = stringValue;
          controller?.mqttPasswordController.text = stringValue;
          return true;

        case 'devicename':
        case 'device_name':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            // Sanitize device name
            String sanitized = stringValue
                .replaceAll(RegExp(r'\s+'), '-')
                .replaceAll('_', '')
                .replaceAll(RegExp(r'[^A-Za-z0-9-]'), '')
                .replaceAll(RegExp(r'-+'), '-')
                .replaceAll(RegExp(r'^-+|-+$'), '')
                .toLowerCase();

            storageService.write(AppConstants.keyDeviceName, sanitized);
            controller?.deviceName.value = sanitized;
            controller?.deviceNameController.text = sanitized;

            // Update MQTT service device name
            deviceName.value = sanitized;

            return true;
          }
          break;

        case 'mqtthadiscovery':
        case 'mqtt_ha_discovery':
        case 'hadiscovery':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyMqttHaDiscovery, boolValue);
            controller?.mqttHaDiscovery.value = boolValue;
            haDiscovery.value = boolValue;
            return true;
          }
          break;

        // SIP settings
        case 'sipenabled':
        case 'sip_enabled':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keySipEnabled, boolValue);
            controller?.sipEnabled.value = boolValue;
            return true;
          }
          break;

        case 'sipserverhost':
        case 'sip_server_host':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write(AppConstants.keySipServerHost, stringValue);
            controller?.sipServerHost.value = stringValue;
            controller?.sipServerHostController.text = stringValue;
            return true;
          }
          break;
        case 'sipprotocol':
        case 'sip_protocol':
          final stringValue = value?.toString();
          if (stringValue != null &&
              (stringValue == 'ws' || stringValue == 'wss')) {
            storageService.write(AppConstants.keySipProtocol, stringValue);
            controller?.sipProtocol.value = stringValue;
            return true;
          }
          break;

        // AI settings
        case 'aienabled':
        case 'ai_enabled':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyAiEnabled, boolValue);
            controller?.aiEnabled.value = boolValue;
            return true;
          }
          break;

        case 'aiproviderhost':
        case 'ai_provider_host':
          final stringValue = value?.toString() ?? '';
          storageService.write(AppConstants.keyAiProviderHost, stringValue);
          controller?.aiProviderHost.value = stringValue;
          controller?.aiProviderHostController.text = stringValue;
          return true;

        // Security settings
        case 'settingspin':
        case 'settings_pin':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write('settingsPin', stringValue);
            controller?.settingsPin.value = stringValue;
            return true;
          }
          break; // Person Detection settings
        case 'persondetectionenabled':
        case 'person_detection_enabled':
        case 'persondetection':
        case 'person_detection':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(
                AppConstants.keyPersonDetectionEnabled, boolValue);
            // Update controller if it's the SettingsControllerFixed type
            if (controller is SettingsControllerFixed) {
              controller.personDetectionEnabled.value = boolValue;
            }

            // Also update the PersonDetectionService if available
            try {
              final personDetectionService = Get.find<PersonDetectionService>();
              personDetectionService.isEnabled.value = boolValue;
              print(
                  '✅ [MQTT] PersonDetectionService state updated to: $boolValue');
            } catch (e) {
              print(
                  '⚠️ [MQTT] PersonDetectionService not available for sync: $e');
            }
            return true;
          }
          break;

        // Wyoming Satellite settings
        case 'wyominghost':
        case 'wyoming_host':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write(AppConstants.keyWyomingHost, stringValue);
            // Update controller if it has Wyoming settings
            try {
              final method =
                  controller?.runtimeType.toString().contains('wyomingHost');
              if (method == true) {
                // Dynamic update if controller supports it
                print('✅ [MQTT] Wyoming host updated to: $stringValue');
              }
            } catch (e) {
              print('⚠️ [MQTT] Wyoming host controller update failed: $e');
            }
            return true;
          }
          break;

        case 'wyomingport':
        case 'wyoming_port':
          final intValue = _parseInt(value);
          if (intValue != null && intValue > 0 && intValue <= 65535) {
            storageService.write(AppConstants.keyWyomingPort, intValue);
            return true;
          }
          break;

        case 'wyomingenabled':
        case 'wyoming_enabled':
          final boolValue = _parseBool(value);
          if (boolValue != null) {
            storageService.write(AppConstants.keyWyomingEnabled, boolValue);
            return true;
          }
          break;

        // Media Device settings
        case 'selectedaudioinput':
        case 'selected_audio_input':
          final stringValue = value?.toString() ?? '';
          storageService.write(AppConstants.keySelectedAudioInput, stringValue);
          return true;

        case 'selectedvideoinput':
        case 'selected_video_input':
          final stringValue = value?.toString() ?? '';
          storageService.write(AppConstants.keySelectedVideoInput, stringValue);
          return true;

        case 'selectedaudiooutput':
        case 'selected_audio_output':
          final stringValue = value?.toString() ?? '';
          storageService.write(
              AppConstants.keySelectedAudioOutput, stringValue);
          return true;

        // Screenshot settings
        case 'latestscreenshot':
        case 'latest_screenshot':
          final stringValue = value?.toString() ?? '';
          storageService.write(AppConstants.keyLatestScreenshot, stringValue);
          return true; // WebSocket and Media Server settings (storage only)
        case 'websocketurl':
        case 'websocket_url':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write(AppConstants.keyWebsocketUrl, stringValue);
            return true;
          }
          break;

        case 'mediaserverurl':
        case 'media_server_url':
          final stringValue = value?.toString();
          if (stringValue != null && stringValue.isNotEmpty) {
            storageService.write(AppConstants.keyMediaServerUrl, stringValue);
            return true;
          }
          break;
        default:
          print('⚠️ [MQTT] Unknown setting key: $key');
          return false;
      }

      return false;
    } catch (e) {
      print('❌ [MQTT] Error applying setting $key: $e');
      return false;
    }
  }

  /// Send provision command response
  void _sendProvisionResponse(
      Map<dynamic, dynamic> cmdObj, Map<String, dynamic> response) {
    try {
      // Check if response topic is specified
      String? responseTopic = cmdObj['response_topic']?.toString();

      // Use default response topic if none specified
      responseTopic ??= 'kingkiosk/${deviceName.value}/provision/response';

      // Add device name to response
      response['device_name'] = deviceName.value;

      // Publish response
      publishJsonToTopic(responseTopic, response, retain: false);

      print('📤 [MQTT] Sent provision response to: $responseTopic');

      // Also show snackbar if there's a UI
      if (Get.context != null) {
        final status = response['status'];
        final message = response['message'] ?? 'Provision command processed';

        Color backgroundColor;
        switch (status) {
          case 'success':
            backgroundColor = Colors.green.withOpacity(0.8);
            break;
          case 'partial':
            backgroundColor = Colors.orange.withOpacity(0.8);
            break;
          case 'error':
            backgroundColor = Colors.red.withOpacity(0.8);
            break;
          default:
            backgroundColor = Colors.blue.withOpacity(0.8);
        }

        Get.snackbar(
          'MQTT Provision',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: backgroundColor,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('❌ [MQTT] Error sending provision response: $e');
    }
  }

  /// Parse boolean value from various formats
  bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') {
        return true;
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off') {
        return false;
      }
    }
    if (value is int) {
      return value != 0;
    }
    return null;
  }

  /// Parse integer value from various formats
  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Process halo effect command with improved error handling
  void _processHaloEffectCommand(Map<dynamic, dynamic> cmdObj) {
    print('🌟 [MQTT] Processing halo effect command: ${jsonEncode(cmdObj)}');
    try {
      // Check if this is a window-specific halo effect
      final windowId = cmdObj['window_id'] as String?;

      // Get the appropriate controller based on whether window_id is provided
      if (windowId != null && windowId.isNotEmpty) {
        print(
            '🌟 [MQTT] Processing window-specific halo effect for window: $windowId');
        // Get the window halo controller
        WindowHaloController windowHaloController;
        if (Get.isRegistered<WindowHaloController>()) {
          windowHaloController = Get.find<WindowHaloController>();
          print('✅ Found existing WindowHaloController');
        } else {
          print('⚠️ WindowHaloController not found, creating a new instance');
          windowHaloController = WindowHaloController();
          Get.put(windowHaloController, permanent: true);
        }

        // Process the command for the specific window
        _processWindowHaloEffect(cmdObj, windowId, windowHaloController);
        return;
      }

      // If no window_id, process for the main app halo
      // Get the controller - using safe registration pattern
      HaloEffectControllerGetx haloController;
      if (Get.isRegistered<HaloEffectControllerGetx>()) {
        haloController = Get.find<HaloEffectControllerGetx>();
        print('✅ Found existing HaloEffectControllerGetx');
      } else {
        print('⚠️ HaloEffectControllerGetx not found, creating a new instance');
        haloController = HaloEffectControllerGetx();
        Get.put(haloController, permanent: true);
      }

      // Check if the effect should be enabled or disabled
      final bool enabled =
          cmdObj['enabled'] != null ? cmdObj['enabled'] == true : true;
      if (enabled) {
        try {
          // Get the color with improved validation
          Color color;
          final dynamic colorValue = cmdObj['color'];
          if (colorValue == null) {
            // No color provided, use default red
            print(
                '🌟 [MQTT] No color provided in halo effect command, using default red');
            color = Color(0xFFFF0000); // Pure red color
          } else if (colorValue is String) {
            // Process color string (both hex and named colors handled by _hexToColor)
            final String colorStr = colorValue.trim();
            color = _hexToColor(colorStr);
          } else if (colorValue is int) {
            // Handle direct color int value with error handling
            try {
              // Ensure valid int range for Color constructor
              if (colorValue < 0) {
                // Negative numbers are used for some system colors, allow them
                color = Color(colorValue);
              } else if (colorValue <= 0xFFFFFFFF) {
                color = Color(colorValue);
              } else {
                print(
                    '⚠️ Color int value out of range: $colorValue, defaulting to red');
                color = Color(0xFFFF0000); // Pure red color
              }
            } catch (e) {
              print(
                  '⚠️ Invalid color int value: $colorValue, defaulting to red');
              color = Color(0xFFFF0000); // Pure red color
            }
          } else {
            // Unknown color format
            print(
                '🌟 [MQTT] Unsupported color format: ${colorValue.runtimeType}, using default red');
            color = Color(0xFFFF0000); // Pure red color
          } // Get optional parameters with improved validation
          double? width;
          if (cmdObj['width'] != null) {
            try {
              final dynamic rawValue = cmdObj['width'];

              if (rawValue is int) {
                width = rawValue.toDouble();
              } else if (rawValue is double) {
                width = rawValue;
              } else if (rawValue is String) {
                width = double.tryParse(rawValue);
              }

              // Validate ranges and apply reasonable limits
              if (width != null) {
                if (width <= 0) {
                  print(
                      '⚠️ Width too small ($width), using minimum value of 1.0');
                  width = 1.0;
                } else if (width > 200) {
                  print(
                      '⚠️ Width too large ($width), using maximum value of 200.0');
                  width = 200.0;
                }
                print('✅ Using width: $width pixels');
              }
            } catch (e) {
              print('⚠️ Error parsing width: $e, using default');
              width = null; // Use default from controller
            }
          }

          double? intensity;
          if (cmdObj['intensity'] != null) {
            try {
              final dynamic rawValue = cmdObj['intensity'];

              if (rawValue is int) {
                intensity = rawValue.toDouble();
              } else if (rawValue is double) {
                intensity = rawValue;
              } else if (rawValue is String) {
                intensity = double.tryParse(rawValue);
              }

              // Validate ranges and apply reasonable limits
              if (intensity != null) {
                if (intensity < 0) {
                  print(
                      '⚠️ Intensity too small ($intensity), using minimum of 0.0');
                  intensity = 0.0;
                } else if (intensity > 1.0) {
                  print(
                      '⚠️ Intensity too large ($intensity), using maximum of 1.0');
                  intensity = 1.0;
                }
                print('✅ Using intensity: $intensity');
              }
            } catch (e) {
              print('⚠️ Error parsing intensity: $e, using default');
              intensity = null; // Use default from controller
            }
          } // Animation parameters
          final String pulseModeStr =
              cmdObj['pulse_mode']?.toString().toLowerCase() ?? 'none';
          HaloPulseMode pulseMode = HaloPulseMode.none;

          // Parse pulse mode from string with enhanced error protection
          try {
            switch (pulseModeStr) {
              case 'gentle':
                pulseMode = HaloPulseMode.gentle;
                print('✅ Setting pulse mode to gentle');
                break;
              case 'moderate':
                pulseMode = HaloPulseMode.moderate;
                print('✅ Setting pulse mode to moderate');
                break;
              case 'alert':
                pulseMode = HaloPulseMode.alert;
                print('✅ Setting pulse mode to alert');
                break;
              default:
                pulseMode = HaloPulseMode.none;
                print('ℹ️ Using default pulse mode: none');
            }
          } catch (e) {
            print('⚠️ Error setting pulse mode, defaulting to none: $e');
            pulseMode = HaloPulseMode.none;
          } // Get animation durations with improved validation
          Duration? pulseDuration;
          if (cmdObj['pulse_duration'] != null) {
            try {
              final dynamic rawValue = cmdObj['pulse_duration'];
              int milliseconds = 2000; // Default value

              if (rawValue is int) {
                milliseconds = rawValue;
              } else if (rawValue is double) {
                milliseconds = rawValue.toInt();
              } else if (rawValue is String) {
                milliseconds = int.tryParse(rawValue) ?? 2000;
              }

              // Validate ranges and apply reasonable limits
              if (milliseconds < 100) {
                print(
                    '⚠️ pulse_duration too small ($milliseconds ms), using minimum of 100ms');
                milliseconds = 100;
              } else if (milliseconds > 10000) {
                print(
                    '⚠️ pulse_duration too large ($milliseconds ms), using maximum of 10000ms');
                milliseconds = 10000;
              }

              pulseDuration = Duration(milliseconds: milliseconds);
              print('✅ Using pulse_duration: $milliseconds ms');
            } catch (e) {
              print(
                  '⚠️ Error parsing pulse_duration: $e, using default 2000ms');
              pulseDuration = const Duration(milliseconds: 2000);
            }
          }
          Duration? fadeInDuration;
          if (cmdObj['fade_in_duration'] != null) {
            try {
              final dynamic rawValue = cmdObj['fade_in_duration'];
              int milliseconds = 800; // Default value

              if (rawValue is int) {
                milliseconds = rawValue;
              } else if (rawValue is double) {
                milliseconds = rawValue.toInt();
              } else if (rawValue is String) {
                milliseconds = int.tryParse(rawValue) ?? 800;
              }

              // Validate ranges and apply reasonable limits
              if (milliseconds < 50) {
                print(
                    '⚠️ fade_in_duration too small ($milliseconds ms), using minimum of 50ms');
                milliseconds = 50;
              } else if (milliseconds > 5000) {
                print(
                    '⚠️ fade_in_duration too large ($milliseconds ms), using maximum of 5000ms');
                milliseconds = 5000;
              }

              fadeInDuration = Duration(milliseconds: milliseconds);
              print('✅ Using fade_in_duration: $milliseconds ms');
            } catch (e) {
              print(
                  '⚠️ Error parsing fade_in_duration: $e, using default 800ms');
              fadeInDuration = const Duration(milliseconds: 800);
            }
          }

          Duration? fadeOutDuration;
          if (cmdObj['fade_out_duration'] != null) {
            try {
              final dynamic rawValue = cmdObj['fade_out_duration'];
              int milliseconds = 1000; // Default value

              if (rawValue is int) {
                milliseconds = rawValue;
              } else if (rawValue is double) {
                milliseconds = rawValue.toInt();
              } else if (rawValue is String) {
                milliseconds = int.tryParse(rawValue) ?? 1000;
              }

              // Validate ranges and apply reasonable limits
              if (milliseconds < 50) {
                print(
                    '⚠️ fade_out_duration too small ($milliseconds ms), using minimum of 50ms');
                milliseconds = 50;
              } else if (milliseconds > 5000) {
                print(
                    '⚠️ fade_out_duration too large ($milliseconds ms), using maximum of 5000ms');
                milliseconds = 5000;
              }

              fadeOutDuration = Duration(milliseconds: milliseconds);
              print('✅ Using fade_out_duration: $milliseconds ms');
            } catch (e) {
              print(
                  '⚠️ Error parsing fade_out_duration: $e, using default 1000ms');
              fadeOutDuration = const Duration(milliseconds: 1000);
            }
          }
          try {
            // Enable the halo effect with the specified parameters
            // First convert the color to a simple Color to avoid MaterialColor issues
            final safeColor = Color(color.value);

            haloController.enableHaloEffect(
              color: safeColor,
              width: width,
              intensity: intensity,
              pulseMode: pulseMode,
              pulseDuration: pulseDuration,
              fadeInDuration: fadeInDuration,
              fadeOutDuration: fadeOutDuration,
            );
            print(
                '🌟 [MQTT] Successfully enabled halo effect with color: ${_colorToHex(safeColor)}, pulse mode: $pulseMode');
          } catch (e) {
            print('❌ Error processing halo effect parameters: $e');
            // Fall back to simple red halo effect with no pulse
            // Using direct Color constructor instead of Colors.red
            try {
              haloController.enableHaloEffect(
                color: Color(0xFFFF0000), // Pure red color
                pulseMode: HaloPulseMode.none,
              );
              print('🌟 [MQTT] Enabled fallback halo effect');
            } catch (fallbackError) {
              print('❌ Fallback halo effect failed: $fallbackError');
            }
          }

          print(
              '🌟 [MQTT] Enabled halo effect with color: ${_colorToHex(color)}, pulse mode: $pulseModeStr');
        } catch (e) {
          print('❌ Error processing halo effect parameters: $e');
          // Try with minimal parameters as fallback
          try {
            haloController.enableHaloEffect(
                color: Color(0xFFFF0000)); // Using direct Color constructor
            print('🌟 [MQTT] Enabled fallback halo effect');
          } catch (fallbackError) {
            print('❌ Fallback halo effect failed: $fallbackError');
          }
        }
      } else {
        // Disable the halo effect
        haloController.disableHaloEffect();
        print('🌟 [MQTT] Disabled halo effect');
      }

      // Send confirmation message if requested
      if (cmdObj['confirm'] == true) {
        try {
          final confirmTopic =
              'kingkiosk/${deviceName.value}/halo_effect/status';
          final builder = MqttClientPayloadBuilder();
          builder.addString(jsonEncode({
            'status': 'success',
            'enabled': enabled,
            'timestamp': DateTime.now().toIso8601String(),
          }));
          _client?.publishMessage(
              confirmTopic, MqttQos.atLeastOnce, builder.payload!);
          print('🌟 [MQTT] Sent halo effect confirmation message');
        } catch (e) {
          print('❌ Error sending confirmation message: $e');
        }
      }
    } catch (e) {
      print('❌ Error processing halo effect command: $e');
    }
  }

  /// Process halo effect for a specific window
  void _processWindowHaloEffect(Map<dynamic, dynamic> cmdObj, String windowId,
      WindowHaloController windowHaloController) {
    print(
        '🌟 [MQTT] Processing window-specific halo effect for window: $windowId');

    // Check if the effect should be enabled or disabled
    final bool enabled =
        cmdObj['enabled'] != null ? cmdObj['enabled'] == true : true;

    if (enabled) {
      // Get the color with improved validation (reusing existing _hexToColor method)
      Color color;
      final dynamic colorValue = cmdObj['color'];
      if (colorValue == null) {
        print(
            '🌟 [MQTT] No color provided in window halo effect command, using default red');
        color = Color(0xFFFF0000); // Pure red color
      } else if (colorValue is String) {
        final String colorStr = colorValue.trim();
        color = _hexToColor(colorStr);
      } else if (colorValue is int) {
        if (colorValue < 0 || colorValue > 0xFFFFFFFF) {
          print(
              '⚠️ Color int value out of range: $colorValue, defaulting to red');
          color = Color(0xFFFF0000);
        } else {
          color = Color(colorValue);
        }
      } else {
        print(
            '🌟 [MQTT] Unsupported color format: ${colorValue.runtimeType}, using default red');
        color = Color(0xFFFF0000); // Pure red color
      }

      // Extract optional parameters with validation (similar to main halo effect logic)
      double? width;
      if (cmdObj['width'] != null) {
        final dynamic rawValue = cmdObj['width'];
        if (rawValue is int) {
          width = rawValue.toDouble();
        } else if (rawValue is double) {
          width = rawValue;
        } else if (rawValue is String) {
          width = double.tryParse(rawValue);
        }
        if (width != null) {
          if (width <= 0) {
            width = 1.0;
          } else if (width > 200) {
            width = 200.0;
          }
        }
      }

      double? intensity;
      if (cmdObj['intensity'] != null) {
        final dynamic rawValue = cmdObj['intensity'];
        if (rawValue is int) {
          intensity = rawValue.toDouble();
        } else if (rawValue is double) {
          intensity = rawValue;
        } else if (rawValue is String) {
          intensity = double.tryParse(rawValue);
        }
        if (intensity != null) {
          if (intensity < 0) {
            intensity = 0.0;
          } else if (intensity > 1.0) {
            intensity = 1.0;
          }
        }
      }

      // Animation parameters
      HaloPulseMode pulseMode = HaloPulseMode.none;
      Duration? pulseDuration;
      if (cmdObj['pulse_duration'] != null) {
        final dynamic rawValue = cmdObj['pulse_duration'];
        int milliseconds = 2000; // Default value
        if (rawValue is int) {
          milliseconds = rawValue;
        } else if (rawValue is double) {
          milliseconds = rawValue.toInt();
        } else if (rawValue is String) {
          milliseconds = int.tryParse(rawValue) ?? 2000;
        }
        if (milliseconds < 100) {
          milliseconds = 100;
        } else if (milliseconds > 10000) {
          milliseconds = 10000;
        }
        pulseDuration = Duration(milliseconds: milliseconds);
      }
      Duration? fadeInDuration;
      if (cmdObj['fade_in_duration'] != null) {
        final dynamic rawValue = cmdObj['fade_in_duration'];
        int milliseconds = 800; // Default value
        if (rawValue is int) {
          milliseconds = rawValue;
        } else if (rawValue is double) {
          milliseconds = rawValue.toInt();
        } else if (rawValue is String) {
          milliseconds = int.tryParse(rawValue) ?? 800;
        }
        if (milliseconds < 50) {
          milliseconds = 50;
        } else if (milliseconds > 5000) {
          milliseconds = 5000;
        }
        fadeInDuration = Duration(milliseconds: milliseconds);
      }
      Duration? fadeOutDuration;
      if (cmdObj['fade_out_duration'] != null) {
        final dynamic rawValue = cmdObj['fade_out_duration'];
        int milliseconds = 1000; // Default value
        if (rawValue is int) {
          milliseconds = rawValue;
        } else if (rawValue is double) {
          milliseconds = rawValue.toInt();
        } else if (rawValue is String) {
          milliseconds = int.tryParse(rawValue) ?? 1000;
        }
        if (milliseconds < 50) {
          milliseconds = 50;
        } else if (milliseconds > 5000) {
          milliseconds = 5000;
        }
        fadeOutDuration = Duration(milliseconds: milliseconds);
      }

      // Make color safe
      final safeColor = Color(color.value);
      // Apply halo effect to the specific window
      windowHaloController.enableHaloForWindow(
        windowId: windowId,
        color: safeColor,
        width: width,
        intensity: intensity,
        pulseMode: pulseMode,
        pulseDuration: pulseDuration,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
      );
      print(
          '🌟 [MQTT] Enabled halo effect for window $windowId with color: ${_colorToHex(safeColor)}, pulse mode: $pulseMode');
    } else {
      // Disable the halo effect for this window
      windowHaloController.disableHaloForWindow(windowId);
      print('🌟 [MQTT] Disabled halo effect for window: $windowId');
    }

    // Send confirmation message if requested
    if (cmdObj['confirm'] == true) {
      final confirmTopic =
          'kingkiosk/${deviceName.value}/window/$windowId/halo_effect/status';
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode({
        'status': 'success',
        'window_id': windowId,
        'enabled': enabled,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      _client?.publishMessage(
          confirmTopic, MqttQos.atLeastOnce, builder.payload!);
      print('🌟 [MQTT] Sent window halo effect confirmation message');
    }
  }

  /// Delete retained object-detection discovery topics that use an old device name
  void _clearLegacyObjectDetectionConfigs() {
    final dn = deviceName.value;
    const suffixes = [
      'object_detection',
      'person_presence',
      'object_count',
      'person_confidence',
    ];
    for (final suff in suffixes) {
      final topic = 'homeassistant/sensor/${dn}_$suff/config';
      publishJsonToTopic(topic, {}, retain: true);
      print('MQTT DEBUG: Deleted old discovery config: $topic');
    }
  }
}
