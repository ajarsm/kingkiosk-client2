import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/platform_sensor_service.dart';
import '../services/storage_service.dart';
import '../core/utils/app_constants.dart';
import 'background_media_service.dart';

class MqttService extends GetxService {
  // MQTT Client
  MqttServerClient? _client;
  
  // Stream controllers
  final _connectionStatusController = StreamController<MqttConnectionState>.broadcast();
  final _messageController = StreamController<MqttReceivedMessage<MqttMessage>>.broadcast();
  
  // Observable values
  final isConnected = false.obs;
  final lastError = ''.obs;
  final deviceName = ''.obs;
  
  // Services
  final StorageService _storageService;
  final PlatformSensorService _sensorService;
  late final BackgroundMediaService _backgroundMediaService;
  
  // Topic constants
  static const String _topicPrefix = 'kiosk/';
  static const String _commandSuffix = '/command';
  static const String _statusSuffix = '/status';
  static const String _sensorPrefix = '/sensor/';
  static const String _configSuffix = '/config';
  static const String _stateSuffix = '/state';
  
  // Home Assistant Discovery Prefix
  static const String _haDiscoveryPrefix = 'homeassistant';
  
  // Timer for periodic data publication
  Timer? _publishTimer;

  // Stream getters
  Stream<MqttConnectionState> get connectionStatus => _connectionStatusController.stream;
  Stream<MqttReceivedMessage<MqttMessage>> get messages => _messageController.stream;
  
  MqttService(this._storageService, this._sensorService);
  
  /// Initialize the MQTT service
  Future<MqttService> init() async {
    try {
      _backgroundMediaService = Get.find<BackgroundMediaService>();
    } catch (e) {
      print('BackgroundMediaService not found, will be initialized later');
    }
    
    // Initialize device name from storage or get from platform
    await _initializeDeviceName();
    
    // Try to connect if MQTT is enabled
    final enabled = _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
    if (enabled) {
      final brokerUrl = _storageService.read<String>(AppConstants.keyMqttBrokerUrl) ?? '';
      final brokerPort = _storageService.read<int>(AppConstants.keyMqttBrokerPort) ?? 1883;
      
      if (brokerUrl.isNotEmpty) {
        await connect(brokerUrl, brokerPort);
      }
    }
    
    return this;
  }

  /// Initialize device name from storage or device info
  Future<void> _initializeDeviceName() async {
    // Try to get from storage first
    final storedName = _storageService.read<String>(AppConstants.keyDeviceName);
    
    if (storedName != null && storedName.isNotEmpty) {
      deviceName.value = storedName;
    } else {
      // Try to get from platform info
      try {
        final deviceInfo = DeviceInfoPlugin();
        String name = "kiosk";
        
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          name = androidInfo.device;
          if (name.isEmpty) name = "android-kiosk";
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          name = iosInfo.name;
          if (name.isEmpty) name = "ios-kiosk";
        } else if (defaultTargetPlatform == TargetPlatform.linux) {
          final linuxInfo = await deviceInfo.linuxInfo;
          name = linuxInfo.prettyName;
          if (name.isEmpty) name = "linux-kiosk";
        } else if (defaultTargetPlatform == TargetPlatform.macOS) {
          final macOsInfo = await deviceInfo.macOsInfo;
          name = macOsInfo.computerName;
          if (name.isEmpty) name = "macos-kiosk";
        } else if (defaultTargetPlatform == TargetPlatform.windows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          name = windowsInfo.computerName;
          if (name.isEmpty) name = "windows-kiosk";
        }
        
        // Remove spaces and special characters for MQTT topic safety
        name = name.replaceAll(RegExp(r'[^\w]'), '-').toLowerCase();
        
        // Update device name
        deviceName.value = name;
        
        // Save to storage
        _storageService.write(AppConstants.keyDeviceName, name);
      } catch (e) {
        deviceName.value = "kiosk-${DateTime.now().millisecondsSinceEpoch}";
        _storageService.write(AppConstants.keyDeviceName, deviceName.value);
      }
    }
  }
  
  /// Update the device name
  void updateDeviceName(String name) async {
    if (name.isEmpty) return;
    
    // Remove spaces and special characters for MQTT topic safety
    final safeName = name.replaceAll(RegExp(r'[^\w]'), '-').toLowerCase();
    
    // Disconnect if connected with the old name
    if (isConnected.value) {
      await disconnect();
    }
    
    // Update device name
    deviceName.value = safeName;
    
    // Save to storage
    _storageService.write(AppConstants.keyDeviceName, safeName);
    
    // Reconnect with new name if MQTT is enabled
    final enabled = _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
    if (enabled) {
      final brokerUrl = _storageService.read<String>(AppConstants.keyMqttBrokerUrl) ?? '';
      final brokerPort = _storageService.read<int>(AppConstants.keyMqttBrokerPort) ?? 1883;
      
      if (brokerUrl.isNotEmpty) {
        await connect(brokerUrl, brokerPort);
      }
    }
  }

  /// Connect to MQTT broker
  Future<void> connect(String brokerUrl, int port) async {
    try {
      // Disconnect if already connected
      await disconnect();
      
      // Create client
      final clientId = 'flutter_getx_kiosk_${deviceName.value}_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(brokerUrl, clientId, port);
      
      // Set client options
      _client!.logging(on: kDebugMode);
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = true;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      
      // Authentication if provided
      final username = _storageService.read<String>(AppConstants.keyMqttUsername);
      final password = _storageService.read<String>(AppConstants.keyMqttPassword);
      
      if (username != null && username.isNotEmpty) {
        _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('$_topicPrefix${deviceName.value}$_statusSuffix')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .startClean()
          .authenticateAs(username, password);
      } else {
        // Create connection message without auth
        _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('$_topicPrefix${deviceName.value}$_statusSuffix')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .startClean();
      }

      // Connect to the broker
      await _client!.connect();
      
      // If connected, subscribe to command topic
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        isConnected.value = true;
        
        // Subscribe to the command topic
        final commandTopic = '$_topicPrefix${deviceName.value}$_commandSuffix';
        _client!.subscribe(commandTopic, MqttQos.atLeastOnce);
        
        // Listen for messages
        _client!.updates!.listen(_onMessage);
        
        // Publish online status
        final statusTopic = '$_topicPrefix${deviceName.value}$_statusSuffix';
        _client!.publishMessage(
          statusTopic,
          MqttQos.atLeastOnce,
          MqttClientPayloadBuilder().addString('online').payload!,
          retain: true,
        );
        
        // Check if Home Assistant discovery is enabled
        final haDiscovery = _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;
        if (haDiscovery) {
          _registerHomeAssistantSensors();
        }
        
        // Start periodic data publication
        _startPeriodicPublication();
      } else {
        isConnected.value = false;
        lastError.value = 'Connection failed: ${_client!.connectionStatus!.returnCode}';
      }
    } catch (e) {
      isConnected.value = false;
      lastError.value = 'Connection exception: $e';
    }
  }
  
  /// Disconnect from the MQTT broker
  Future<void> disconnect() async {
    _stopPeriodicPublication();
    
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
      try {
        // Publish offline status
        final statusTopic = '$_topicPrefix${deviceName.value}$_statusSuffix';
        _client!.publishMessage(
          statusTopic,
          MqttQos.atLeastOnce,
          MqttClientPayloadBuilder().addString('offline').payload!,
          retain: true,
        );
        
        // Disconnect
        _client!.disconnect();
      } catch (e) {
        print('Error during MQTT disconnect: $e');
      }
    }
    
    _client = null;
    isConnected.value = false;
  }
  
  /// Handle disconnection
  void _onDisconnected() {
    isConnected.value = false;
    _stopPeriodicPublication();
    _connectionStatusController.add(MqttConnectionState.disconnected);
  }
  
  /// Handle successful connection
  void _onConnected() {
    isConnected.value = true;
    _connectionStatusController.add(MqttConnectionState.connected);
  }
  
  /// Handle successful subscription
  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }
  
  /// Handle incoming message
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (var message in messages) {
      // Forward message to stream
      _messageController.add(message);
      
      // Process command message
      if (message.topic == '$_topicPrefix${deviceName.value}$_commandSuffix') {
        _processCommand(message);
      }
    }
  }
  
  /// Process command message
  void _processCommand(MqttReceivedMessage<MqttMessage> message) {
    final recMess = message.payload as MqttPublishMessage;
    final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    
    try {
      // Make sure BackgroundMediaService is initialized
      if (!Get.isRegistered<BackgroundMediaService>()) {
        return;
      }
      
      _backgroundMediaService = Get.find<BackgroundMediaService>();
      
      final command = jsonDecode(payload);
      
      // Handle media playback commands
      if (command is Map<String, dynamic>) {
        if (command.containsKey('play_media')) {
          final url = command['play_media'] as String;
          final type = command['type'] as String? ?? 'audio';
          final style = command['style'] as String? ?? 'background';
          
          if (type == 'audio') {
            _backgroundMediaService.playAudio(url);
          } else if (type == 'video') {
            if (style == 'fullscreen') {
              _backgroundMediaService.playVideoFullscreen(url);
            } else {
              _backgroundMediaService.playVideo(url);
            }
          }
        } else if (command.containsKey('stop_media')) {
          _backgroundMediaService.stop();
        } else if (command.containsKey('pause_media')) {
          _backgroundMediaService.pause();
        } else if (command.containsKey('resume_media')) {
          _backgroundMediaService.resume();
        }
      }
    } catch (e) {
      print('Error processing command: $e');
    }
  }
  
  /// Register device sensors with Home Assistant for auto-discovery
  void _registerHomeAssistantSensors() {
    if (!isConnected.value) return;
    
    // Define the sensors to register
    final sensors = [
      {
        'name': 'Battery Level',
        'unique_id': '${deviceName.value}_battery_level',
        'state_topic': '$_topicPrefix${deviceName.value}$_sensorPrefix/battery_level$_stateSuffix',
        'device_class': 'battery',
        'unit_of_measurement': '%',
        'value_template': '{{ value_json.value }}',
        'entity_category': 'diagnostic'
      },
      {
        'name': 'Battery Status',
        'unique_id': '${deviceName.value}_battery_status',
        'state_topic': '$_topicPrefix${deviceName.value}$_sensorPrefix/battery_status$_stateSuffix',
        'device_class': 'enum',
        'value_template': '{{ value_json.value }}',
        'entity_category': 'diagnostic'
      },
      {
        'name': 'CPU Usage',
        'unique_id': '${deviceName.value}_cpu_usage',
        'state_topic': '$_topicPrefix${deviceName.value}$_sensorPrefix/cpu_usage$_stateSuffix',
        'device_class': 'power_factor',
        'unit_of_measurement': '%',
        'value_template': '{{ value_json.value }}',
        'entity_category': 'diagnostic'
      },
      {
        'name': 'Memory Usage',
        'unique_id': '${deviceName.value}_memory_usage',
        'state_topic': '$_topicPrefix${deviceName.value}$_sensorPrefix/memory_usage$_stateSuffix',
        'device_class': 'power_factor',
        'unit_of_measurement': '%',
        'value_template': '{{ value_json.value }}',
        'entity_category': 'diagnostic'
      }
    ];
    
    // Device information for Home Assistant
    final device = {
      'identifiers': ['kiosk_${deviceName.value}'],
      'name': deviceName.value,
      'sw_version': AppConstants.appVersion,
      'model': 'Flutter GetX Kiosk',
      'manufacturer': 'GetX Kiosk'
    };
    
    // Register each sensor
    for (var sensor in sensors) {
      final sensorData = Map<String, dynamic>.from(sensor);
      sensorData['device'] = device;
      
      // Create config topic for this sensor
      final configTopic = '$_haDiscoveryPrefix/sensor/${deviceName.value}/${sensor['unique_id']}$_configSuffix';
      _client!.publishMessage(
        configTopic,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(jsonEncode(sensorData)).payload!,
        retain: true,
      );
    }
  }
  
  /// Start periodic data publication
  void _startPeriodicPublication() {
    _stopPeriodicPublication();
    
    // Publish sensor data every 30 seconds
    _publishTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _publishSensorData();
    });
    
    // Publish initial data
    _publishSensorData();
  }
  
  /// Stop periodic data publication
  void _stopPeriodicPublication() {
    _publishTimer?.cancel();
    _publishTimer = null;
  }
  
  /// Publish sensor data to MQTT topics
  void _publishSensorData() {
    if (!isConnected.value) return;
    
    // Battery level
    final batteryLevel = _sensorService.batteryLevel.value;
    _publishData(
      '$_topicPrefix${deviceName.value}$_sensorPrefix/battery_level$_stateSuffix',
      {'value': batteryLevel}
    );
    
    // Battery status
    final batteryStatus = _sensorService.batteryState.value;
    _publishData(
      '$_topicPrefix${deviceName.value}$_sensorPrefix/battery_status$_stateSuffix',
      {'value': batteryStatus}
    );
    
    // CPU usage
    final cpuUsage = (_sensorService.cpuUsage.value * 100).toStringAsFixed(1);
    _publishData(
      '$_topicPrefix${deviceName.value}$_sensorPrefix/cpu_usage$_stateSuffix',
      {'value': cpuUsage}
    );
    
    // Memory usage
    final memoryUsage = (_sensorService.memoryUsage.value * 100).toStringAsFixed(1);
    _publishData(
      '$_topicPrefix${deviceName.value}$_sensorPrefix/memory_usage$_stateSuffix',
      {'value': memoryUsage}
    );
  }
  
  /// Publish data to MQTT topic as JSON
  void _publishData(String topic, Map<String, dynamic> data) {
    if (!isConnected.value) return;
    
    try {
      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(jsonEncode(data)).payload!,
      );
    } catch (e) {
      print('Error publishing to $topic: $e');
    }
  }
  
  /// Publish a message to a topic
  void publish(String topic, String message, {bool retain = false}) {
    if (!isConnected.value) return;
    
    try {
      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(message).payload!,
        retain: retain,
      );
    } catch (e) {
      print('Error publishing to $topic: $e');
    }
  }
  
  /// Clean up resources before service is destroyed
  @override
  void onClose() {
    disconnect();
    _connectionStatusController.close();
    _messageController.close();
    super.onClose();
  }
}