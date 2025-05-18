import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../wyoming_satellite/wyoming_satellite.dart';
import '../../notification_system/notification_system.dart';
import 'storage_service.dart';
import 'platform_sensor_service.dart';
import '../core/utils/app_constants.dart';
import 'background_media_service.dart';
import '../services/window_manager_service.dart';
import '../modules/home/controllers/tiling_window_controller.dart';
import '../modules/home/controllers/media_window_controller.dart';
import 'wyoming_service.dart';
import 'mqtt_notification_handler.dart';
import 'media_recovery_service.dart';
import 'screenshot_service.dart';

/// MQTT service with proper statistics reporting (consolidated from multiple versions)
/// Fixed to properly report all sensor values to Home Assistant
class MqttService extends GetxService {
  // Required dependencies
  final StorageService _storageService;
  final PlatformSensorService _sensorService;
  final WyomingService _wyomingService = Get.find();

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

  // Constructor
  MqttService(this._storageService, this._sensorService);
  @override
  void onInit() {
    super.onInit();
    // Subscribe to window command topics
    final device = deviceName.value;
    final topic = 'kiosk/$device/window/+/command';
    subscribe(topic, (String topic, String payload) {
      // Parse window name from topic
      final parts = topic.split('/');
      final windowName = parts.length > 3 ? parts[3] : null;
      if (windowName != null) {
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          final action = data['action'] as String?;
          if (action != null) {
            final wm = Get.find<WindowManagerService>();
            wm.handleWindowCommand(windowName, action, data);
          }
        } catch (e) {
          print('Failed to parse window command payload: $e');
        }
      }
    });

    // Ensure notification system is available
    try {
      Get.find<NotificationService>();
      print('✅ [MQTT] NotificationService is ready for MQTT notifications');
    } catch (e) {
      print('⚠️ [MQTT] NotificationService not available: $e');
    }

    // Clean up old windows discovery config on startup
    ever(isConnected, (connected) {
      if (connected == true) {
        final deviceNameStr = deviceName.value;
        final discoveryTopic =
            'homeassistant/sensor/${deviceNameStr}_windows/config';
        // Publish empty payload to delete old config
        publishJsonToTopic(discoveryTopic, {}, retain: true);
        print('MQTT DEBUG: Deleted discovery config for windows');
        // Republish config
        publishWindowsDiscoveryConfig();
      }
    });

    // Listen for Wyoming events/audio and publish to Home Assistant if enabled
    ever(_wyomingService.enabled, (enabled) {
      if (enabled == true) {
        _wyomingService.isConnected.listen((connected) {
          if (connected) {
            _wyomingService.messageStream.listen((msg) {
              if (msg is WyomingJsonMessage) {
                publishJsonToTopic('homeassistant/wyoming/event', msg.json);
              } else if (msg is WyomingBinaryMessage) {
                publishJsonToTopic(
                    'homeassistant/wyoming/audio', {'audio': msg.data});
              }
            });
          }
        });
      }
    });
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

  /// Disconnect from the MQTT broker
  Future<void> disconnect() async {
    if (_client != null) {
      try {
        // Publish offline status before disconnecting
        publishStatus('offline');

        // Stop stats update timer
        _stopStatsUpdate();

        // Disconnect
        _client!.disconnect();
        isConnected.value = false;
        print('MQTT Disconnected');
      } catch (e) {
        print('MQTT Disconnect error: $e');
      }
    }
  }

  /// Publish device status (online/offline)
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

  /// Publish a JSON payload to an arbitrary topic (for diagnostics, etc.)
  void publishJsonToTopic(String topic, Map<String, dynamic> payload,
      {bool retain = true}) {
    if (!isConnected.value || _client == null) {
      print('MQTT not connected, cannot publish to $topic');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );
    print(
        'MQTT: Published JSON to $topic: ${jsonEncode(payload)} (retain=$retain)');
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
      else if (kIsWeb) platform = 'Web';

      // Publish platform info
      _publishDirectValue('platform', platform);
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
  void _processCommand(String command) async {
    print('🎯 Processing command: "$command"');
    dynamic cmdObj;
    try {
      cmdObj = jsonDecode(command);
      if (cmdObj is String) {
        print('🔄 [MQTT] Detected nested JSON string, parsing inner JSON');
        cmdObj = jsonDecode(cmdObj);
      }
    } catch (_) {
      cmdObj = null;
    }

    print('🔄 [MQTT] Parsed cmdObj: $cmdObj');
    if (cmdObj is Map) {
      print('🔄 [MQTT] cmdObj["command"]: ${cmdObj['command']}');
    } // --- Handle batch commands array first ---
    if (cmdObj is Map &&
        (cmdObj['commands'] is List ||
            cmdObj['command']?.toString().toLowerCase() == 'batch')) {
      // Support both batch format styles: {commands: [...]} and {command: 'batch', commands: [...]}
      print('🎯 Processing batch command');
      final List commandList = cmdObj['commands'] as List;
      print('🎯 Processing batch of ${commandList.length} commands');

      for (final cmd in commandList) {
        if (cmd is Map) {
          try {
            // Check specifically for notify command to use optimized path
            if (cmd['command']?.toString().toLowerCase() == 'notify') {
              MqttNotificationHandler.processNotifyCommand(cmd);
              continue;
            }

            // Process each other command in the batch
            final cmdString = jsonEncode(cmd);
            print('🎯 Processing batch command: $cmdString');
            _processCommand(cmdString);
          } catch (e) {
            print('❌ Error processing batch command: $e');
          }
        }
      }
      return;
    }

    // --- Only handle commands that are JSON with a 'command' key ---
    if (cmdObj is! Map || !cmdObj.containsKey('command')) {
      print(
          '🎯 Ignoring non-command MQTT message (cmdObj type: ${cmdObj.runtimeType})');
      return;
    }
    // --- play_media command via {"command": "play_media", ...} ---
    if (cmdObj['command']?.toString().toLowerCase() == 'play_media') {
      String? type = cmdObj['type']?.toString();
      String? url = cmdObj['url']?.toString();
      String? style = cmdObj['style']?.toString();
      final bool loop =
          cmdObj['loop'] == true || cmdObj['loop']?.toString() == 'true';
      // Get the custom window ID if provided
      final String? windowId = cmdObj['window_id']?.toString();
      print(
          '🎬 play_media command received (command key): type=$type, url=$url, style=$style, loop=$loop' +
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
          } else {
            print(
                '🔊 [MQTT] Playing audio in background via BackgroundMediaService: $url, loop=$loop');
            mediaService.playAudio(url, loop: loop);
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
    }
    // --- minimize_window command ---
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
    } // --- notify command for sending notifications ---
    if (cmdObj['command']?.toString().toLowerCase() == 'notify') {
      MqttNotificationHandler.processNotifyCommand(cmdObj);
      return;
    }
    // Notification handling is delegated to MqttNotificationHandler

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
                '[MQTT] Window with ID $windowId is not a media window (type: [33m${win.windowType}[0m)');
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
        print(
            '[MQTT] Invalid set_brightness value: [33m${cmdObj['value']}[0m');
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

          // If you have a MediaHealthCheckTester class, call it directly here.
          // Otherwise, comment out or implement the test logic as needed.
          // Example (uncomment if available):
          // MediaHealthCheckTester.runTest();

          // Publish health status report
          if (isConnected.value && _client != null) {
            publishJsonToTopic(
              'kingkiosk/${deviceName.value}/status/media_health',
              healthStatus,
            );
          }
          return;
        }

        // Not a test, perform actual reset
        final result = await mediaRecoveryService.resetAllMediaResources(
            force: forceReset);

        // Report result
        if (result) {
          print('✅ [MQTT] Media reset completed successfully');

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

    // ...existing fallback string command logic...
    print('🎯 Unknown command received: "$command"');
    return;
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
        'platform'
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
      _setupDiscoverySensorWithDebug('battery_status', 'Battery Status',
          'battery', '', 'mdi:battery-charging');

      print('MQTT DEBUG: Setting up CPU usage sensor');
      _setupDiscoverySensorWithDebug(
          'cpu_usage', 'CPU Usage', 'cpu', '%', 'mdi:cpu-64-bit');

      print('MQTT DEBUG: Setting up memory usage sensor');
      _setupDiscoverySensorWithDebug(
          'memory_usage', 'Memory Usage', 'memory', '%', 'mdi:memory');

      print('MQTT DEBUG: Setting up platform sensor');
      _setupDiscoverySensorWithDebug(
          'platform', 'Platform', 'text', '', 'mdi:laptop');

      print('MQTT DEBUG: Home Assistant discovery setup complete');
    } catch (e) {
      print('MQTT DEBUG: Error setting up discovery: $e');
    }
  }

  /// Set up a single discovery sensor with detailed logging
  void _setupDiscoverySensorWithDebug(
      String name, String displayName, String deviceClass, String unit,
      [String? icon]) {
    final discoveryTopic =
        'homeassistant/sensor/${deviceName.value}_$name/config';

    // Use valid Home Assistant device_class values
    // See https://www.home-assistant.io/integrations/sensor/#device-class
    String validDeviceClass = deviceClass;
    if (deviceClass == 'cpu') {
      // CPU is not a valid device class in Home Assistant
      validDeviceClass = ''; // empty will use default sensor
    } else if (deviceClass == 'memory') {
      // Memory is not a valid device class in Home Assistant
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
      else if (kIsWeb) platform = 'Web';

      // Publish platform info
      _publishDirectValueWithDebug('platform', platform);

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

  /// Check if MQTT service is connected
  bool isConnectedToBroker() {
    return isConnected.value;
  }

  /// Get current update interval
  int getUpdateInterval() {
    return _updateIntervalSeconds;
  }

  /// Force a manual reconnection to the MQTT broker
  Future<bool> forceReconnect() async {
    print('⚙️ Force reconnecting to MQTT broker...');

    if (_client == null) {
      print('❌ Cannot reconnect: MQTT client is null');
      return false;
    }

    try {
      // Disconnect but keep client settings
      print('⚙️ Disconnecting from broker...');
      _client!.disconnect();
      isConnected.value = false;

      // Wait a moment
      await Future.delayed(Duration(milliseconds: 1000));

      // Reconnect using existing client settings
      print('⚙️ Attempting to reconnect...');
      await _client!.connect();

      // Check if reconnection was successful
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ MQTT Reconnected successfully');
        isConnected.value = true;

        // Resubscribe to topics
        print('⚙️ Resubscribing to topics...');
        _subscribeToCommands();

        // Republish online status
        publishStatus('online');

        return true;
      } else {
        print(
            '❌ MQTT Reconnection failed: ${_client!.connectionStatus!.state}');
        isConnected.value = false;
        return false;
      }
    } catch (e) {
      print('❌ Error during MQTT reconnection: $e');
      isConnected.value = false;
      return false;
    }
  }

  /// Subscribe to a custom MQTT topic
  void subscribe(String topic, Function(String, String) onMessage) {
    if (!isConnected.value || _client == null) return;

    try {
      print('Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _client!.updates!
          .listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
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
    } catch (e) {
      print('Error subscribing to $topic: $e');
    }
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
    print('MQTT DEBUG: Discovery payload for windows: ${jsonEncode(payload)}');
    print('MQTT DEBUG: Publishing to topic: $discoveryTopic');
    publishJsonToTopic(discoveryTopic, payload, retain: true);
    print('MQTT DEBUG: Published discovery config for windows');
  }
}
