import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../../../services/storage_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../core/utils/app_constants.dart';

/// This is an alias to SettingsController for backward compatibility
class CombinedSettingsController extends GetxController {
  // Services
  final StorageService _storageService = Get.find<StorageService>();
  MqttService? _mqttService;
  
  // Theme settings
  final RxBool isDarkMode = false.obs;
  
  // Web URL settings
  final RxString kioskStartUrl = AppConstants.defaultKioskStartUrl.obs;
  
  // MQTT settings
  final RxBool mqttEnabled = false.obs;
  final RxString mqttBrokerUrl = AppConstants.defaultMqttBrokerUrl.obs;
  final RxInt mqttBrokerPort = AppConstants.defaultMqttBrokerPort.obs;
  final RxString mqttUsername = ''.obs;
  final RxString mqttPassword = ''.obs;
  final RxString deviceName = ''.obs;
  final RxBool mqttHaDiscovery = false.obs;
  final RxBool mqttConnected = false.obs;
  
  // WebSocket settings
  final RxString websocketUrl = AppConstants.defaultWebsocketUrl.obs;
  
  // WebRTC settings
  final RxString mediaServerUrl = AppConstants.defaultMediaServerUrl.obs;
  
  // App settings
  final RxBool kioskMode = true.obs;
  final RxBool showSystemInfo = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Load all settings
    _loadSettings();
    
    // Try to initialize MQTT connection status
    _initMqttStatus();
    
    // Listen for kioskMode changes to enable/disable wakelock
    ever(kioskMode, (bool enabled) {
      if (enabled) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });
    
    // Set initial wakelock state
    if (kioskMode.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }
    /// Load settings from storage
  void _loadSettings() {
    print('🔄 Loading settings from storage...');
    _printStorageLocation();
    _storageService.debugStorageStatus();
    
    // Load theme settings
    isDarkMode.value = _storageService.read<bool>(AppConstants.keyIsDarkMode) ?? false;
    
    // Load web URL settings
    kioskStartUrl.value = _storageService.read<String>(AppConstants.keyKioskStartUrl) ?? AppConstants.defaultKioskStartUrl;
    
    // Load MQTT settings
    mqttEnabled.value = _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
    mqttBrokerUrl.value = _storageService.read<String>(AppConstants.keyMqttBrokerUrl) ?? AppConstants.defaultMqttBrokerUrl;
    mqttBrokerPort.value = _storageService.read<int>(AppConstants.keyMqttBrokerPort) ?? AppConstants.defaultMqttBrokerPort;
    mqttUsername.value = _storageService.read<String>(AppConstants.keyMqttUsername) ?? '';
    mqttPassword.value = _storageService.read<String>(AppConstants.keyMqttPassword) ?? '';
    deviceName.value = _storageService.read<String>(AppConstants.keyDeviceName) ?? '';
    mqttHaDiscovery.value = _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;
    
    // Load WebSocket settings
    websocketUrl.value = _storageService.read<String>(AppConstants.keyWebsocketUrl) ?? websocketUrl.value;
    
    // Load WebRTC settings
    mediaServerUrl.value = _storageService.read<String>(AppConstants.keyMediaServerUrl) ?? mediaServerUrl.value;
    
    // Load app settings
    kioskMode.value = _storageService.read<bool>(AppConstants.keyKioskMode) ?? true;
    showSystemInfo.value = _storageService.read<bool>(AppConstants.keyShowSystemInfo) ?? true;
    
    // Apply theme
    _applyTheme();
  }
  void _printStorageLocation() {
    try {
      final box = GetStorage();
      print('📁 GetStorage has data: ${box.hasData('isDarkMode')}');
      print('📁 GetStorage keys: ${box.getKeys()}');
      print('📁 GetStorage values count: ${box.getValues().length}');
      
      // Print all current values
      final keys = box.getKeys();
      for (final key in keys) {
        final value = box.read(key);
        print('📁 Storage: $key = $value');
      }
    } catch (e) {
      print('❌ Error getting storage info: $e');
    }
  }
    void _initMqttStatus() {
    try {
      if (Get.isRegistered<MqttService>()) {
        _mqttService = Get.find<MqttService>();
        mqttConnected.value = _mqttService?.isConnected.value ?? false;
        
        if (_mqttService != null) {
          // Listen for connection status changes
          ever(_mqttService!.isConnected, (bool connected) {
            mqttConnected.value = connected;
            print('🔄 MQTT connection status updated in combined settings controller: $connected');
          });
          
          // Add retry logic for timing synchronization issues
          Timer.periodic(Duration(seconds: 1), (timer) {
            if (timer.tick > 10) {
              timer.cancel(); // Stop checking after 10 seconds
              return;
            }
            
            final currentServiceStatus = _mqttService!.isConnected.value;
            if (currentServiceStatus != mqttConnected.value) {
              print('🔄 MQTT status sync correction in combined controller: service=$currentServiceStatus, controller=${mqttConnected.value}');
              mqttConnected.value = currentServiceStatus;
            }
          });
          
          // Update device name if available
          if (_mqttService!.deviceName.value.isNotEmpty && deviceName.value.isEmpty) {
            deviceName.value = _mqttService!.deviceName.value;
          }
        }
      } else {
        // Service not registered yet, retry finding it
        Timer.periodic(Duration(seconds: 2), (timer) {
          if (timer.tick > 5) {
            timer.cancel(); // Stop trying after 10 seconds
            return;
          }
          
          try {
            if (Get.isRegistered<MqttService>()) {
              _mqttService = Get.find<MqttService>();
              print('🔄 Found MQTT service on retry in combined controller, initializing status');
              _initMqttStatus(); // Recursively call to set up properly
              timer.cancel();
            }
          } catch (e) {
            print('🔄 MQTT service still not available on retry in combined controller: $e');
          }
        });
      }
    } catch (e) {
      print('MqttService not available: $e');
      _mqttService = null;
    }
  }
  
  // Theme methods
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    _applyTheme();
  }
  
  void _applyTheme() {    final themeService = Get.find<ThemeService>();
    themeService.setDarkMode(isDarkMode.value);
  }
  
  // Web URL methods
  void saveKioskStartUrl(String url) {
    print('💾 Saving kiosk start URL: $url');
    kioskStartUrl.value = url;
    _storageService.write(AppConstants.keyKioskStartUrl, url);
    _storageService.debugStorageStatus();
    
    Get.snackbar(
      'Setting Saved',
      'Kiosk start URL updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  // WebSocket methods
  void saveWebsocketUrl(String url) {
    websocketUrl.value = url;
    _storageService.write(AppConstants.keyWebsocketUrl, url);
  }
  
  // WebRTC methods
  void saveMediaServerUrl(String url) {
    mediaServerUrl.value = url;
    _storageService.write(AppConstants.keyMediaServerUrl, url);
  }
  
  // App settings methods
  void toggleKioskMode() {
    kioskMode.value = !kioskMode.value;
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
  }
  
  void toggleShowSystemInfo() {
    showSystemInfo.value = !showSystemInfo.value;
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
  }
    // MQTT methods
  void toggleMqttEnabled(bool value) {
    print('💾 Saving MQTT enabled: $value');
    mqttEnabled.value = value;
    _storageService.write(AppConstants.keyMqttEnabled, value);
    
    // If disabling, disconnect
    if (!value && mqttConnected.value && _mqttService != null) {
      disconnectMqtt();
    }
  }
  void saveMqttBrokerUrl(String url) {
    print('💾 Saving MQTT broker URL: $url');
    mqttBrokerUrl.value = url;
    _storageService.write(AppConstants.keyMqttBrokerUrl, url);
    
    Get.snackbar(
      'Setting Saved',
      'MQTT broker URL updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
    void saveMqttBrokerPort(int port) {
    mqttBrokerPort.value = port;
    _storageService.write(AppConstants.keyMqttBrokerPort, port);
    
    Get.snackbar(
      'Setting Saved',
      'MQTT broker port updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
    void saveMqttUsername(String username) {
    mqttUsername.value = username;
    _storageService.write(AppConstants.keyMqttUsername, username);
    
    Get.snackbar(
      'Setting Saved',
      'MQTT username updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
    void saveMqttPassword(String password) {
    mqttPassword.value = password;
    _storageService.write(AppConstants.keyMqttPassword, password);
    
    Get.snackbar(
      'Setting Saved',
      'MQTT password updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
    void saveDeviceName(String name) {
    deviceName.value = name;
    _storageService.write(AppConstants.keyDeviceName, name);
    
    // Update device name in MQTT service if available
    if (_mqttService != null) {
      _mqttService!.deviceName.value = name;
    }
    
    Get.snackbar(
      'Setting Saved',
      'Device name updated to: $name',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void toggleMqttHaDiscovery(bool value) {
    mqttHaDiscovery.value = value;
    _storageService.write(AppConstants.keyMqttHaDiscovery, value);
    
    // Reconnect if already connected
    if (value && mqttConnected.value && _mqttService != null) {
      disconnectMqtt();
      connectMqtt();
    }
  }
  
  // MQTT connection methods
  Future<void> connectMqtt() async {
    if (!mqttEnabled.value) {
      Get.snackbar('MQTT Disabled', 'Please enable MQTT first');
      return;
    }
    
    try {
      // Check if service already registered
      if (Get.isRegistered<MqttService>()) {
        _mqttService = Get.find<MqttService>();
        
        // Disconnect first if already connected
        if (_mqttService!.isConnected.value) {
          await _mqttService!.disconnect();
          await Future.delayed(Duration(milliseconds: 300));
        }
      } else {
        // Create a new instance
        final storageService = Get.find<StorageService>();
        final sensorService = Get.find<PlatformSensorService>();
        
        _mqttService = MqttService(storageService, sensorService);
        Get.put<MqttService>(_mqttService!, permanent: true);
        
        await _mqttService!.init();
      }
      
      // Update device name
      if (deviceName.value.isNotEmpty) {
        _mqttService!.deviceName.value = deviceName.value;
      }
      
      // Connect
      await _mqttService!.connect(
        brokerUrl: mqttBrokerUrl.value,
        port: mqttBrokerPort.value,
        username: mqttUsername.value.isNotEmpty ? mqttUsername.value : null,
        password: mqttPassword.value.isNotEmpty ? mqttPassword.value : null
      );
      
      // Show feedback
      Get.snackbar(
        'MQTT Connection',
        'Connecting to ${mqttBrokerUrl.value}:${mqttBrokerPort.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.3),
      );
      
    } catch (e) {
      print('Error connecting to MQTT: $e');
      Get.snackbar(
        'MQTT Connection Failed',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.3),
      );
    }
  }
  
  void disconnectMqtt() {
    try {
      if (_mqttService != null) {
        _mqttService!.disconnect();
        
        Get.snackbar(
          'MQTT Disconnected',
          'Successfully disconnected from MQTT broker',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.3),
        );
      }
    } catch (e) {
      print('Error disconnecting from MQTT: $e');
    }
  }
  
  /// Force refresh MQTT connection status
  void refreshMqttConnectionStatus() {
    if (_mqttService != null) {
      final actualStatus = _mqttService!.isConnected.value;
      if (actualStatus != mqttConnected.value) {
        print('🔄 Force refreshing MQTT status in combined controller: was ${mqttConnected.value}, now $actualStatus');
        mqttConnected.value = actualStatus;
      }
    } else {
      // Try to re-initialize MQTT service
      _initMqttStatus();
    }
  }
  
  // Reset all settings
  void resetAllSettings() {
    // First disconnect MQTT if connected
    if (mqttConnected.value && _mqttService != null) {
      disconnectMqtt();
    }
    
    // Reset theme
    isDarkMode.value = false;
    
    // Reset Web URL
    kioskStartUrl.value = AppConstants.defaultKioskStartUrl;
    
    // Reset MQTT
    mqttEnabled.value = false;
    mqttBrokerUrl.value = AppConstants.defaultMqttBrokerUrl;
    mqttBrokerPort.value = AppConstants.defaultMqttBrokerPort;
    mqttUsername.value = '';
    mqttPassword.value = '';
    mqttHaDiscovery.value = false;
    
    // Reset WebSocket
    websocketUrl.value = AppConstants.defaultWebsocketUrl;
    
    // Reset WebRTC
    mediaServerUrl.value = AppConstants.defaultMediaServerUrl;
    
    // Reset app settings
    kioskMode.value = true;
    showSystemInfo.value = true;
    
    // Save all settings
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    _storageService.write(AppConstants.keyKioskStartUrl, kioskStartUrl.value);
    _storageService.write(AppConstants.keyMqttEnabled, mqttEnabled.value);
    _storageService.write(AppConstants.keyMqttBrokerUrl, mqttBrokerUrl.value);
    _storageService.write(AppConstants.keyMqttBrokerPort, mqttBrokerPort.value);
    _storageService.write(AppConstants.keyMqttUsername, mqttUsername.value);
    _storageService.write(AppConstants.keyMqttPassword, mqttPassword.value);
    _storageService.write(AppConstants.keyMqttHaDiscovery, mqttHaDiscovery.value);
    _storageService.write(AppConstants.keyWebsocketUrl, websocketUrl.value);
    _storageService.write(AppConstants.keyMediaServerUrl, mediaServerUrl.value);
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
    
    // Apply theme
    _applyTheme();
    
    Get.snackbar(
      'Settings Reset',
      'All settings have been reset to defaults',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}