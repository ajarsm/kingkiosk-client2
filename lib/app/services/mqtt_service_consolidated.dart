import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'storage_service.dart';
import 'platform_sensor_service.dart';
import '../core/utils/app_constants.dart';
import 'background_media_service.dart';
import '../services/window_manager_service.dart';

/// MQTT service with proper statistics reporting (consolidated from multiple versions)
/// Fixed to properly report all sensor values to Home Assistant
class MqttService extends GetxService {
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
                if (message.topic.endsWith('/command') || message.topic.endsWith('/commands')) {
                  print('🎯 Processing as command message on topic: ${message.topic}');
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
      print('❌ ERROR: MQTT client updates stream is null - cannot listen for messages');
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
    deviceName.value = _storageService.read<String>(AppConstants.keyDeviceName) ?? '';
    haDiscovery.value = _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;
    
    // If device name is not set, generate a unique one
    if (deviceName.value.isEmpty) {
      // Generate device name without "kiosk" prefix
      deviceName.value = 'device-${DateTime.now().millisecondsSinceEpoch % 100000}';
      // Save the generated device name
      _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    }
    
    // Check for and remove "kiosk" prefix if it exists in the device name
    if (deviceName.value.startsWith('kiosk-') || deviceName.value.startsWith('kiosk ')) {
      print('MQTT INFO: Removing kiosk prefix from device name: ${deviceName.value}');
      final oldName = deviceName.value;
      deviceName.value = deviceName.value.replaceFirst(RegExp(r'^kiosk[\s-]'), '');
      print('MQTT INFO: Name changed from "$oldName" to "${deviceName.value}"');
      // Save the updated device name
      _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    }
    
    // Sanitize the device name to be MQTT friendly (no spaces, special chars)
    if (deviceName.value.contains(RegExp(r'[^\w-]'))) {
      print('MQTT INFO: Sanitizing device name for MQTT compatibility: ${deviceName.value}');
      final oldName = deviceName.value;
      deviceName.value = deviceName.value.replaceAll(RegExp(r'[^\w-]'), '_');
      print('MQTT INFO: Name sanitized from "$oldName" to "${deviceName.value}"');
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
    // Check if already connecting or connected
    if (_client != null && _client!.connectionStatus!.state != MqttConnectionState.disconnected) {
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
      _client!.resubscribeOnAutoReconnect = true; // Auto resubscribe on reconnect
      
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
            print('📡 Connected to MQTT broker, ensuring topics are subscribed');
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
        print('MQTT Connection failed: ${_client!.connectionStatus!.state.toString()}');
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
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
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
      _publishDirectValue('memory_usage', (memoryUsage * 100).toStringAsFixed(1));
      
      // Get platform info
      String platform = 'unknown';
      if (Platform.isAndroid) platform = 'Android';
      else if (Platform.isIOS) platform = 'iOS';
      else if (Platform.isMacOS) platform = 'macOS';
      else if (Platform.isWindows) platform = 'Windows';
      else if (Platform.isLinux) platform = 'Linux';
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
      print('✅ Successfully requested subscription to command topics: ${commandTopic}, ${commandsTopic}');
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
  void _processCommand(String command) {
    print('🎯 Processing command: "$command"');
    // Try to decode as JSON for play_media, else fallback to string command
    dynamic cmdObj;
    try {
      cmdObj = jsonDecode(command);
    } catch (_) {
      cmdObj = null;
    }
    if (cmdObj is Map && cmdObj.containsKey('play_media')) {
      final playMedia = cmdObj['play_media'];
      String? type;
      String? url;
      String? style;
      if (playMedia is String) {
        url = playMedia;
      } else if (playMedia is Map) {
        type = playMedia['type']?.toString();
        url = playMedia['url']?.toString();
        style = playMedia['style']?.toString();
      }
      type ??= cmdObj['type']?.toString();
      url ??= cmdObj['url']?.toString();
      style ??= cmdObj['style']?.toString();
      print('🎬 play_media command received: type=$type, url=$url, style=$style');
      if (type == null) {
        // Try to infer type from url
        if (url != null && (url.endsWith('.mp4') || url.endsWith('.webm'))) {
          type = 'video';
        } else if (url != null && (url.endsWith('.mp3') || url.endsWith('.wav'))) {
          type = 'audio';
        }
      }
      if (url == null || url.isEmpty) {
        print('⚠️ play_media command missing url');
        return;
      }
      try {
        final mediaService = Get.find<BackgroundMediaService>();
        if (type == 'audio') {
          print('🔊 [MQTT] Playing audio via BackgroundMediaService: $url');
          mediaService.playAudio(url);
        } else if (type == 'video') {
          if (style == 'fullscreen') {
            print('🎥 [MQTT] Playing video fullscreen via BackgroundMediaService: $url');
            mediaService.playVideoFullscreen(url);
          } else if (style == 'window') {
            print('🎥 [MQTT] Playing video (background/window) via BackgroundMediaService: $url, style=$style');
            mediaService.playVideoWindowed(url);
          } else {
            print('🎥 [MQTT] Playing video (background/window) via BackgroundMediaService: $url, style=background');
            mediaService.playVideo(url);
          }
        } else {
          print('⚠️ Unknown play_media type or missing url');
        }
      } catch (e) {
        print('❌ Error calling BackgroundMediaService: $e');
      }
      return;
    }
    // Fallback: handle as string command
    switch (command.trim().toLowerCase()) {
      case 'reboot':
        print('🎯 Command executed: Reboot');
        break;
      case 'refresh':
        print('🎯 Command executed: Refresh');
        break;
      case 'update_sensors':
        print('🎯 Command executing: Update Sensors - manually updating all sensors');
        _publishSensorValues();
        print('🎯 Sensor update completed');
        break;
      case 'republish_all':
        print('🎯 Command executing: Republish All - forcing rediscovery and republishing all sensors');
        forcePublishAllSensors();
        print('🎯 Force publish initiated');
        break;
      default:
        print('🎯 Unknown command received: "$command"');
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
      print('MQTT DEBUG: Connection state: ${_client!.connectionStatus!.state}');
      print('MQTT DEBUG: Client ID: ${_client!.clientIdentifier}');
      
      // List all client properties
      print('MQTT DEBUG: Client properties:');
      print('MQTT DEBUG: - Keep alive: ${_client!.keepAlivePeriod}');
      print('MQTT DEBUG: - Auto reconnect: ${_client!.autoReconnect}');
      
      // Try to get connection message details safely
      try {
        print('MQTT DEBUG: - Connection message: ${_client!.connectionMessage.toString()}');
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
      final sensors = ['battery', 'battery_status', 'cpu_usage', 'memory_usage', 'platform'];
      
      for (final sensor in sensors) {
        final topic = 'homeassistant/sensor/${deviceName.value}_$sensor/config';
        // To delete a retained message, publish an empty message
        _client!.publishMessage(
          topic,
          MqttQos.atLeastOnce,
          MqttClientPayloadBuilder().payload!,
          retain: true
        );
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
      _setupDiscoverySensorWithDebug('battery', 'Battery Level', 'battery', '%', 'mdi:battery');
      
      print('MQTT DEBUG: Setting up battery status sensor');
      _setupDiscoverySensorWithDebug('battery_status', 'Battery Status', 'battery', '', 'mdi:battery-charging');
      
      print('MQTT DEBUG: Setting up CPU usage sensor');
      _setupDiscoverySensorWithDebug('cpu_usage', 'CPU Usage', 'cpu', '%', 'mdi:cpu-64-bit');
      
      print('MQTT DEBUG: Setting up memory usage sensor');
      _setupDiscoverySensorWithDebug('memory_usage', 'Memory Usage', 'memory', '%', 'mdi:memory');
      
      print('MQTT DEBUG: Setting up platform sensor');
      _setupDiscoverySensorWithDebug('platform', 'Platform', 'text', '', 'mdi:laptop');
      
      print('MQTT DEBUG: Home Assistant discovery setup complete');
    } catch (e) {
      print('MQTT DEBUG: Error setting up discovery: $e');
    }
  }
  
  /// Set up a single discovery sensor with detailed logging
  void _setupDiscoverySensorWithDebug(String name, String displayName, String deviceClass, String unit, [String? icon]) {
    final discoveryTopic = 'homeassistant/sensor/${deviceName.value}_$name/config';
    
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
      "icon": icon ?? "mdi:${deviceClass == 'battery' ? 'battery' : 
                       deviceClass == 'memory' ? 'memory' : 
                       deviceClass == 'cpu' ? 'cpu-64-bit' : 'information-outline'}",
      "device": {
        "identifiers": ["${deviceName.value}"],
        "name": deviceName.value,
        "model": "Kiosk App",
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
      print('MQTT DEBUG: Memory usage: ${(memoryUsage * 100).toStringAsFixed(1)}%');
      
      // Publish battery level
      _publishDirectValueWithDebug('battery', batteryLevel.toString());
      
      // Publish battery status
      _publishDirectValueWithDebug('battery_status', batteryState);
      
      // Publish CPU usage - format as percentage with 1 decimal place
      _publishDirectValueWithDebug('cpu_usage', (cpuUsage * 100).toStringAsFixed(1));
      
      // Publish memory usage - format as percentage with 1 decimal place
      _publishDirectValueWithDebug('memory_usage', (memoryUsage * 100).toStringAsFixed(1));
      
      // Get platform info
      String platform = 'unknown';
      if (Platform.isAndroid) platform = 'Android';
      else if (Platform.isIOS) platform = 'iOS';
      else if (Platform.isMacOS) platform = 'macOS';
      else if (Platform.isWindows) platform = 'Windows';
      else if (Platform.isLinux) platform = 'Linux';
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
        print('❌ MQTT Reconnection failed: ${_client!.connectionStatus!.state}');
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
      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
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
}
