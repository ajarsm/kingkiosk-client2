import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../../services/theme_service.dart';
import '../../../core/utils/app_constants.dart';

/// Consolidated settings controller that incorporates all fixes
class SettingsController extends GetxController {
  // Services
  final StorageService _storageService = Get.find<StorageService>();
  late MqttService? _mqttService;
  
  // Theme settings
  final RxBool isDarkMode = false.obs;
  
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
  
  // Web URL settings
  final RxString kioskStartUrl = AppConstants.defaultKioskStartUrl.obs;
  
  // Form controllers for proper text direction
  final TextEditingController mqttBrokerUrlController = TextEditingController();
  final TextEditingController mqttUsernameController = TextEditingController();
  final TextEditingController mqttPasswordController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();
  final TextEditingController websocketUrlController = TextEditingController();
  final TextEditingController mediaServerUrlController = TextEditingController();
  final TextEditingController kioskStartUrlController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    
    // Try to find MQTT service (may not be available during tests)
    try {
      _mqttService = Get.find<MqttService>();
    } catch (e) {
      print('MQTT Service not available: $e');
      _mqttService = null;
    }
    
    // Safely load settings on the next event loop
    Future.microtask(() {
      _loadSettings();
      _initControllerValues();
      
      // Auto-connect to MQTT if it was enabled (after a short delay)
      Future.delayed(Duration(seconds: 1), () => autoConnectMqttIfEnabled());
    });
  }
  
  @override
  void onClose() {
    // Dispose text controllers
    mqttBrokerUrlController.dispose();
    mqttUsernameController.dispose();
    mqttPasswordController.dispose();
    deviceNameController.dispose();
    websocketUrlController.dispose();
    mediaServerUrlController.dispose();
    kioskStartUrlController.dispose();
    super.onClose();
  }

  void _loadSettings() {
    // Load theme settings
    isDarkMode.value = _storageService.read<bool>(AppConstants.keyIsDarkMode) ?? false;
    
    // Load WebSocket settings
    websocketUrl.value = _storageService.read<String>(AppConstants.keyWebsocketUrl) ?? websocketUrl.value;
    
    // Load WebRTC settings
    mediaServerUrl.value = _storageService.read<String>(AppConstants.keyMediaServerUrl) ?? mediaServerUrl.value;
    
    // Load app settings
    kioskMode.value = _storageService.read<bool>(AppConstants.keyKioskMode) ?? true;
    showSystemInfo.value = _storageService.read<bool>(AppConstants.keyShowSystemInfo) ?? true;
    
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
    
    // Apply theme
    _applyTheme();
    
    // Initialize MQTT connection status
    _initMqttStatus();
  }

  void _initControllerValues() {
    // Initialize text controllers with current values and cursor position at end
    mqttBrokerUrlController.text = mqttBrokerUrl.value;
    mqttBrokerUrlController.selection = TextSelection.fromPosition(
      TextPosition(offset: mqttBrokerUrlController.text.length),
    );
    
    mqttUsernameController.text = mqttUsername.value;
    mqttUsernameController.selection = TextSelection.fromPosition(
      TextPosition(offset: mqttUsernameController.text.length),
    );
    
    mqttPasswordController.text = mqttPassword.value;
    mqttPasswordController.selection = TextSelection.fromPosition(
      TextPosition(offset: mqttPasswordController.text.length),
    );
    
    deviceNameController.text = deviceName.value;
    deviceNameController.selection = TextSelection.fromPosition(
      TextPosition(offset: deviceNameController.text.length),
    );
    
    websocketUrlController.text = websocketUrl.value;
    websocketUrlController.selection = TextSelection.fromPosition(
      TextPosition(offset: websocketUrlController.text.length),
    );
    
    mediaServerUrlController.text = mediaServerUrl.value;
    mediaServerUrlController.selection = TextSelection.fromPosition(
      TextPosition(offset: mediaServerUrlController.text.length),
    );
    
    kioskStartUrlController.text = kioskStartUrl.value;
    kioskStartUrlController.selection = TextSelection.fromPosition(
      TextPosition(offset: kioskStartUrlController.text.length),
    );
  }

  void autoConnectMqttIfEnabled() {
    // Check if MQTT should auto-connect
    if (mqttEnabled.value && _mqttService != null && !_mqttService!.isConnected.value) {
      print('MQTT is enabled and not connected, auto-connecting...');
      // Use a short delay to ensure all dependencies are ready
      Future.delayed(Duration(milliseconds: 500), () {
        connectMqtt();
      });
    } else if (_mqttService != null && _mqttService!.isConnected.value) {
      print('MQTT is already connected, skipping auto-connect');
    }
  }

  void _initMqttStatus() {
    // Initialize MQTT connection status
    if (_mqttService != null) {
      mqttConnected.value = _mqttService!.isConnected.value;
      
      // Listen to connection status changes
      ever(_mqttService!.isConnected, (bool connected) {
        mqttConnected.value = connected;
      });
    }
  }

  void _applyTheme() {
    final themeService = Get.find<ThemeService>();
    themeService.setDarkMode(isDarkMode.value);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    _applyTheme();
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    _applyTheme();
  }

  void toggleKioskMode() {
    kioskMode.value = !kioskMode.value;
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
  }

  void toggleShowSystemInfo() {
    showSystemInfo.value = !showSystemInfo.value;
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
  }

  void saveAppSettings() {
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
    
    Get.snackbar(
      'Settings Saved',
      'App settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void saveMqttSettings() {
    // Get values from text controllers
    mqttBrokerUrl.value = mqttBrokerUrlController.text;
    mqttUsername.value = mqttUsernameController.text;
    mqttPassword.value = mqttPasswordController.text;
    deviceName.value = deviceNameController.text;
    
    // Save MQTT settings
    _storageService.write(AppConstants.keyMqttEnabled, mqttEnabled.value);
    _storageService.write(AppConstants.keyMqttBrokerUrl, mqttBrokerUrl.value);
    _storageService.write(AppConstants.keyMqttBrokerPort, mqttBrokerPort.value);
    _storageService.write(AppConstants.keyMqttUsername, mqttUsername.value);
    _storageService.write(AppConstants.keyMqttPassword, mqttPassword.value);
    _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    _storageService.write(AppConstants.keyMqttHaDiscovery, mqttHaDiscovery.value);
    
    Get.snackbar(
      'Settings Saved',
      'MQTT settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    // Connect if enabled
    if (mqttEnabled.value) {
      connectMqtt();
    } else {
      disconnectMqtt();
    }
  }

  void saveWebSocketSettings() {
    // Get values from text controllers
    websocketUrl.value = websocketUrlController.text;
    
    // Save WebSocket settings
    _storageService.write(AppConstants.keyWebsocketUrl, websocketUrl.value);
    
    Get.snackbar(
      'Settings Saved',
      'WebSocket settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void saveWebsocketUrl(String url) {
    websocketUrl.value = url;
    _storageService.write(AppConstants.keyWebsocketUrl, url);
  }

  void saveWebRtcSettings() {
    // Get values from text controllers
    mediaServerUrl.value = mediaServerUrlController.text;
    
    // Save WebRTC settings
    _storageService.write(AppConstants.keyMediaServerUrl, mediaServerUrl.value);
    
    Get.snackbar(
      'Settings Saved',
      'WebRTC settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void saveMediaServerUrl(String url) {
    mediaServerUrl.value = url;
    _storageService.write(AppConstants.keyMediaServerUrl, url);
  }

  void saveWebUrlSettings() {
    // Get values from text controllers
    kioskStartUrl.value = kioskStartUrlController.text;
    
    // Save Web URL settings
    _storageService.write(AppConstants.keyKioskStartUrl, kioskStartUrl.value);
    
    Get.snackbar(
      'Settings Saved',
      'Web URL settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void connectMqtt() {
    if (_mqttService == null) {
      print('MQTT Service not available');
      return;
    }
    
    // Only attempt to connect if not already connected
    if (_mqttService!.isConnected.value) {
      print('MQTT already connected, skipping connection attempt');
      return;
    }
    
    print('Attempting to connect to MQTT broker: ${mqttBrokerUrl.value}:${mqttBrokerPort.value}');
    
    _mqttService!.connect(
      brokerUrl: mqttBrokerUrl.value,
      port: mqttBrokerPort.value,
      username: mqttUsername.value.isNotEmpty ? mqttUsername.value : null,
      password: mqttPassword.value.isNotEmpty ? mqttPassword.value : null,
    ).then((success) {
      if (success) {
        mqttConnected.value = true;
        Get.snackbar(
          'MQTT Connected',
          'Connected to ${mqttBrokerUrl.value}:${mqttBrokerPort.value}',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else {
        mqttConnected.value = false;
        Get.snackbar(
          'MQTT Error',
          'Failed to connect to MQTT broker, check credentials',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    });
  }

  void disconnectMqtt() {
    if (_mqttService != null) {
      _mqttService!.disconnect().then((_) {
        mqttConnected.value = false;
        Get.snackbar(
          'MQTT Disconnected',
          'Disconnected from MQTT broker',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  /// Force republish all sensors to Home Assistant
  void forceRepublishSensors() {
    if (_mqttService == null) {
      print('MQTT Service not available');
      Get.snackbar(
        'MQTT Error',
        'MQTT service is not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    if (!_mqttService!.isConnected.value) {
      print('MQTT not connected');
      Get.snackbar(
        'MQTT Error',
        'Not connected to MQTT broker',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // Call the debug function to force republish all sensors
    _mqttService!.forcePublishAllSensors();
    
    Get.snackbar(
      'MQTT Sensors',
      'Force republishing all sensors to Home Assistant',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  void resetAllSettings() {
    // First disconnect MQTT if connected
    if (mqttConnected.value && _mqttService != null) {
      disconnectMqtt();
    }
    
    // Reset theme
    isDarkMode.value = false;
    
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
