import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/storage_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../../services/theme_service.dart';
import '../../../core/utils/app_constants.dart';

/// Consolidated settings controller that incorporates all fixes
class SettingsController extends GetxController {
  // Services
  final StorageService _storageService = Get.find<StorageService>();
  late MqttService? _mqttService;

  // Robust getter for MqttService to handle late registration
  MqttService? get mqttService {
    if (_mqttService == null) {
      try {
        _mqttService = Get.find<MqttService>();
      } catch (_) {
        // Still not available
      }
    }
    return _mqttService;
  }
  
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

  // Settings PIN (default 1234, persisted)
  final RxString settingsPin = '1234'.obs;

  // Settings lock state
  final RxBool isSettingsLocked = true.obs;

  void lockSettings() => isSettingsLocked.value = true;
  void unlockSettings() => isSettingsLocked.value = false;
  
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
    
    // Load settings PIN from storage
    settingsPin.value = _storageService.read<String>('settingsPin') ?? '1234';

    // Safely load settings on the next event loop
    Future.microtask(() async {
      await _loadSettingsWithHostname();
      _initControllerValues();
      
      // Auto-connect to MQTT if it was enabled (after a short delay)
      Future.delayed(Duration(seconds: 1), () => autoConnectMqttIfEnabled());
    });

    // Ensure mqttConnected stays in sync with the actual service
    if (mqttService != null) {
      mqttConnected.value = mqttService!.isConnected.value;
      ever(mqttService!.isConnected, (bool connected) {
        mqttConnected.value = connected;
      });
    }
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

  Future<void> _loadSettingsWithHostname() async {
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
    mqttHaDiscovery.value = _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;

    // Device name: if not set, use hostname
    String? storedDeviceName = _storageService.read<String>(AppConstants.keyDeviceName);
    if (storedDeviceName == null || storedDeviceName.isEmpty) {
      String hostname = await _getHostname();
      deviceName.value = hostname;
      _storageService.write(AppConstants.keyDeviceName, hostname);
    } else {
      deviceName.value = storedDeviceName;
    }
    
    // After loading kioskMode, ensure wakelock is set correctly
    if (kioskMode.value) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    
    // Apply theme
    _applyTheme();
    
    // Initialize MQTT connection status
    _initMqttStatus();
  }

  Future<String> _getHostname() async {
    try {
      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        return Platform.localHostname;
      }
    } catch (_) {}
    // Fallback for mobile/web
    return 'kiosk-device';
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
    if (mqttEnabled.value && mqttService != null && !mqttService!.isConnected.value) {
      print('MQTT is enabled and not connected, auto-connecting...');
      // Use a short delay to ensure all dependencies are ready
      Future.delayed(Duration(milliseconds: 500), () {
        connectMqtt();
      });
    } else if (mqttService != null && mqttService!.isConnected.value) {
      print('MQTT is already connected, skipping auto-connect');
    }
  }

  void _initMqttStatus() {
    // Initialize MQTT connection status
    if (mqttService != null) {
      mqttConnected.value = mqttService!.isConnected.value;
      
      // Listen to connection status changes
      ever(mqttService!.isConnected, (bool connected) {
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
    // Control wakelock based on kiosk mode
    if (kioskMode.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
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

  void saveDeviceName(String name) {
    // Sanitize: all whitespace to dashes, remove underscores, remove special chars except dash, collapse multiple dashes
    String sanitized = name
        .replaceAll(RegExp(r'\s+'), '-') // all whitespace to dash
        .replaceAll('_', '')
        .replaceAll(RegExp(r'[^A-Za-z0-9-]'), '') // only alphanum and dash
        .replaceAll(RegExp(r'-+'), '-') // collapse multiple dashes
        .replaceAll(RegExp(r'^-+|-+$'), '') // trim leading/trailing dashes
        .toLowerCase();
    deviceName.value = sanitized;
    _storageService.write(AppConstants.keyDeviceName, sanitized);
    if (mqttService != null) {
      mqttService!.deviceName.value = sanitized;
    }
  }

  void setSettingsPin(String pin) {
    settingsPin.value = pin;
    _storageService.write('settingsPin', pin);
  }

  void connectMqtt() {
    if (mqttService == null) {
      print('MQTT Service not available');
      return;
    }
    // Always update the MQTT service device name before connecting
    mqttService!.deviceName.value = deviceName.value;
    // Only attempt to connect if not already connected
    if (mqttService!.isConnected.value) {
      print('MQTT already connected, skipping connection attempt');
      return;
    }
    print('Attempting to connect to MQTT broker: ${mqttBrokerUrl.value}:${mqttBrokerPort.value}');
    mqttService!.connect(
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
    if (mqttService != null) {
      mqttService!.disconnect().then((_) {
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
    if (mqttService == null) {
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
    
    if (!mqttService!.isConnected.value) {
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
    mqttService!.forcePublishAllSensors();
    
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
    if (mqttConnected.value && mqttService != null) {
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

  // --- Methods for settings views compatibility ---
  void toggleMqttEnabled(bool value) {
    mqttEnabled.value = value;
    _storageService.write(AppConstants.keyMqttEnabled, value);
    if (!value && mqttConnected.value) {
      disconnectMqtt();
    }
  }

  void toggleMqttHaDiscovery(bool value) {
    mqttHaDiscovery.value = value;
    _storageService.write(AppConstants.keyMqttHaDiscovery, value);
    if (mqttService != null) {
      mqttService!.haDiscovery.value = value;
    }
    // Optionally reconnect if needed
    if (value && mqttConnected.value) {
      disconnectMqtt();
      Future.delayed(Duration(milliseconds: 300), () {
        connectMqtt();
      });
    }
  }

  void saveMqttBrokerUrl(String url) {
    mqttBrokerUrl.value = url;
    mqttBrokerUrlController.text = url;
    _storageService.write(AppConstants.keyMqttBrokerUrl, url);
  }

  void saveMqttBrokerPort(int port) {
    mqttBrokerPort.value = port;
    _storageService.write(AppConstants.keyMqttBrokerPort, port);
  }

  void saveMqttUsername(String username) {
    mqttUsername.value = username;
    mqttUsernameController.text = username;
    _storageService.write(AppConstants.keyMqttUsername, username);
  }

  void saveMqttPassword(String password) {
    mqttPassword.value = password;
    mqttPasswordController.text = password;
    _storageService.write(AppConstants.keyMqttPassword, password);
  }

  void saveKioskStartUrl(String url) {
    kioskStartUrl.value = url;
    kioskStartUrlController.text = url;
    _storageService.write(AppConstants.keyKioskStartUrl, url);
  }
}
