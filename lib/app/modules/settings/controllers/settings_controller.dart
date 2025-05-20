// filepath: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/settings/controllers/settings_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/storage_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../../services/theme_service.dart';
import '../../../services/sip_service.dart';
import '../../../services/ai_assistant_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../widgets/settings_pin_dialog.dart';

/// Consolidated settings controller that incorporates all fixes
class SettingsController extends GetxController {
  // Services
  final StorageService _storageService = Get.find<StorageService>();
  late MqttService? _mqttService;
  late SipService? _sipService;

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

  // Getter for SipService
  SipService? get sipService {
    if (_sipService == null) {
      try {
        _sipService = Get.find<SipService>();
      } catch (_) {
        // Still not available
      }
    }
    return _sipService;
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

  // SIP settings
  final RxBool sipEnabled = false.obs;
  final RxString sipServerHost = AppConstants.defaultSipServerHost.obs;
  final RxString sipProtocol =
      'wss'.obs; // Default to wss for secure connection
  final RxBool sipRegistered = false.obs;

  // AI settings
  final RxBool aiEnabled = false.obs;
  final RxString aiProviderHost = ''.obs;

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

  // Show PIN dialog for settings access
  void showSettingsPinDialog({required VoidCallback onSuccess}) {
    Get.dialog(
      SettingsPinDialog(
        correctPin: settingsPin.value,
        title: 'Settings Access',
        onSuccess: onSuccess,
        onCancel: () => {}, // No action needed on cancel
      ),
    );
  }

  // Form controllers for proper text direction
  final TextEditingController mqttBrokerUrlController = TextEditingController();
  final TextEditingController mqttUsernameController = TextEditingController();
  final TextEditingController mqttPasswordController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();
  final TextEditingController kioskStartUrlController = TextEditingController();
  final TextEditingController sipServerHostController = TextEditingController();
  final TextEditingController aiProviderHostController =
      TextEditingController();

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

    // Try to find SIP service (may not be available during tests)
    try {
      _sipService = Get.find<SipService>();
    } catch (e) {
      print('SIP Service not available: $e');
      _sipService = null;
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

    // Ensure sipRegistered stays in sync with the actual service
    if (sipService != null) {
      sipRegistered.value = sipService!.isRegistered.value;
      ever(sipService!.isRegistered, (bool registered) {
        sipRegistered.value = registered;
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
    kioskStartUrlController.dispose();
    sipServerHostController.dispose();
    aiProviderHostController.dispose();
    super.onClose();
  }

  Future<void> _loadSettingsWithHostname() async {
    // Load theme settings
    isDarkMode.value =
        _storageService.read<bool>(AppConstants.keyIsDarkMode) ?? false;

    // Load app settings
    kioskMode.value =
        _storageService.read<bool>(AppConstants.keyKioskMode) ?? true;
    showSystemInfo.value =
        _storageService.read<bool>(AppConstants.keyShowSystemInfo) ?? true;

    // Load web URL settings
    kioskStartUrl.value =
        _storageService.read<String>(AppConstants.keyKioskStartUrl) ??
            AppConstants.defaultKioskStartUrl;

    // Load MQTT settings
    mqttEnabled.value =
        _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
    mqttBrokerUrl.value =
        _storageService.read<String>(AppConstants.keyMqttBrokerUrl) ??
            AppConstants.defaultMqttBrokerUrl;
    mqttBrokerPort.value =
        _storageService.read<int>(AppConstants.keyMqttBrokerPort) ??
            AppConstants.defaultMqttBrokerPort;
    mqttUsername.value =
        _storageService.read<String>(AppConstants.keyMqttUsername) ?? '';
    mqttPassword.value =
        _storageService.read<String>(AppConstants.keyMqttPassword) ?? '';
    mqttHaDiscovery.value =
        _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;

    // Load SIP settings
    sipEnabled.value =
        _storageService.read<bool>(AppConstants.keySipEnabled) ?? false;
    sipServerHost.value =
        _storageService.read<String>(AppConstants.keySipServerHost) ??
            AppConstants.defaultSipServerHost;
    sipProtocol.value =
        _storageService.read<String>(AppConstants.keySipProtocol) ?? 'wss';

    // Load AI settings
    aiEnabled.value =
        _storageService.read<bool>(AppConstants.keyAiEnabled) ?? false;
    aiProviderHost.value =
        _storageService.read<String>(AppConstants.keyAiProviderHost) ?? '';

    // Device name: if not set, use hostname
    String? storedDeviceName =
        _storageService.read<String>(AppConstants.keyDeviceName);
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

    // Initialize SIP registration status
    _initSipStatus();
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

    kioskStartUrlController.text = kioskStartUrl.value;
    kioskStartUrlController.selection = TextSelection.fromPosition(
      TextPosition(offset: kioskStartUrlController.text.length),
    );

    sipServerHostController.text = sipServerHost.value;
    sipServerHostController.selection = TextSelection.fromPosition(
      TextPosition(offset: sipServerHostController.text.length),
    );

    aiProviderHostController.text = aiProviderHost.value;
    aiProviderHostController.selection = TextSelection.fromPosition(
      TextPosition(offset: aiProviderHostController.text.length),
    );
  }

  void autoConnectMqttIfEnabled() {
    // Check if MQTT should auto-connect
    if (mqttEnabled.value &&
        mqttService != null &&
        !mqttService!.isConnected.value) {
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

  void _initSipStatus() {
    // Initialize SIP registration status
    if (sipService != null) {
      // Set device name in SIP service (critical for registration)
      sipService!.deviceName.value = deviceName.value;

      // Set initial registration status
      sipRegistered.value = sipService!.isRegistered.value;

      // Listen to registration status changes
      ever(sipService!.isRegistered, (bool registered) {
        sipRegistered.value = registered;
      });

      // Listen to device name changes to update SIP service
      ever(deviceName, (String name) {
        sipService!.deviceName.value = name;
        print('Updated SIP device name to: $name');
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
    _storageService.write(
        AppConstants.keyMqttHaDiscovery, mqttHaDiscovery.value);

    Get.snackbar(
      'Settings Saved',
      'MQTT settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );

    // Handle connection changes with async operations safely
    Future.microtask(() async {
      // Connect if enabled or disconnect if disabled
      if (mqttEnabled.value) {
        connectMqtt();
      } else {
        await disconnectMqtt();
      }
    });
  }

  void setSipProtocol(String protocol) {
    if (protocol != 'ws' && protocol != 'wss') {
      print('Invalid SIP protocol: $protocol. Must be "ws" or "wss"');
      return;
    }

    sipProtocol.value = protocol;
    _storageService.write(AppConstants.keySipProtocol, protocol);

    // Update SIP service if available
    if (sipService != null) {
      sipService!.protocol.value = protocol;

      // Re-register if already registered
      if (sipRegistered.value) {
        sipService!.unregister();
        Future.delayed(Duration(milliseconds: 500), () {
          sipService!.register();
        });
      }
    }
  }

  void saveSipSettings() {
    // Get values from text controllers
    sipServerHost.value = sipServerHostController.text;

    // Save SIP settings
    _storageService.write(AppConstants.keySipEnabled, sipEnabled.value);
    _storageService.write(AppConstants.keySipServerHost, sipServerHost.value);
    _storageService.write(AppConstants.keySipProtocol, sipProtocol.value);

    Get.snackbar(
      'Settings Saved',
      'SIP settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );

    // Register if enabled
    if (sipEnabled.value) {
      registerSip();
    } else {
      unregisterSip();
    }
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

    // Update MQTT service if available
    if (mqttService != null) {
      mqttService!.deviceName.value = sanitized;
    }

    // Update SIP service if available
    if (sipService != null) {
      sipService!.deviceName.value = sanitized;
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
    print(
        'Attempting to connect to MQTT broker: ${mqttBrokerUrl.value}:${mqttBrokerPort.value}');
    mqttService!
        .connect(
      brokerUrl: mqttBrokerUrl.value,
      port: mqttBrokerPort.value,
      username: mqttUsername.value.isNotEmpty ? mqttUsername.value : null,
      password: mqttPassword.value.isNotEmpty ? mqttPassword.value : null,
    )
        .then((success) {
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

  Future<void> disconnectMqtt() async {
    if (mqttService != null) {
      try {
        await mqttService!.disconnect();
        mqttConnected.value = false;
        Get.snackbar(
          'MQTT Disconnected',
          'Disconnected from MQTT broker',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        print('Error disconnecting from MQTT: $e');
        Get.snackbar(
          'MQTT Disconnection Error',
          'Error disconnecting from MQTT: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  void registerSip() {
    if (sipService == null) {
      print('SIP Service not available');
      return;
    }
    // Only attempt to register if not already registered
    if (sipService!.isRegistered.value) {
      print('SIP already registered, skipping registration attempt');
      return;
    }

    // Update SIP service settings
    sipService!.serverHost.value = sipServerHost.value;
    sipService!.deviceName.value = deviceName.value;
    sipService!.protocol.value = sipProtocol.value;

    print(
        'Attempting to register SIP server: ${sipProtocol.value}://${sipServerHost.value}');
    sipService!.register().then((success) {
      if (success) {
        sipRegistered.value = true;
        Get.snackbar(
          'SIP Registered',
          'Registered to SIP server: ${sipProtocol.value}://${sipServerHost.value}',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      } else {
        sipRegistered.value = false;
        Get.snackbar(
          'SIP Error',
          'Failed to register to SIP server, check settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    });
  }

  Future<void> unregisterSip() async {
    if (sipService != null) {
      try {
        await sipService!.unregister();
        sipRegistered.value = false;
        Get.snackbar(
          'SIP Unregistered',
          'Unregistered from SIP server',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        print('Error unregistering SIP: $e');
        Get.snackbar(
          'SIP Error',
          'Error unregistering from SIP server: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
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
    // Create an async task to handle services disconnection
    Future<void> disconnectServices() async {
      // First disconnect MQTT if connected
      if (mqttConnected.value && mqttService != null) {
        await disconnectMqtt();
        print('MQTT disconnected during settings reset');
      }

      // Then unregister SIP if registered
      if (sipRegistered.value && sipService != null) {
        await unregisterSip();
        print('SIP unregistered during settings reset');
      }
    }

    // Start the async operation but don't wait for it
    disconnectServices();

    // Reset theme
    isDarkMode.value = false;

    // Reset MQTT
    mqttEnabled.value = false;
    mqttBrokerUrl.value = AppConstants.defaultMqttBrokerUrl;
    mqttBrokerPort.value = AppConstants.defaultMqttBrokerPort;
    mqttUsername.value = '';
    mqttPassword.value = '';
    mqttHaDiscovery.value = false;

    // Reset SIP
    sipEnabled.value = false;
    sipServerHost.value = AppConstants.defaultSipServerHost;

    // Reset AI settings
    aiEnabled.value = false;
    aiProviderHost.value = '';

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
    _storageService.write(
        AppConstants.keyMqttHaDiscovery, mqttHaDiscovery.value);
    _storageService.write(AppConstants.keySipEnabled, sipEnabled.value);
    _storageService.write(AppConstants.keySipServerHost, sipServerHost.value);
    _storageService.write(AppConstants.keyAiEnabled, aiEnabled.value);
    _storageService.write(AppConstants.keyAiProviderHost, aiProviderHost.value);
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
      // Handle disconnect in a fire-and-forget way, but with proper async
      Future.microtask(() async {
        await disconnectMqtt();
      });
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

  void toggleSipEnabled(bool value) {
    sipEnabled.value = value;
    _storageService.write(AppConstants.keySipEnabled, value);
    if (!value && sipRegistered.value) {
      unregisterSip();
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

  void saveSipServerHost(String host) {
    sipServerHost.value = host;
    sipServerHostController.text = host;
    _storageService.write(AppConstants.keySipServerHost, host);
  }

  void saveKioskStartUrl(String url) {
    kioskStartUrl.value = url;
    kioskStartUrlController.text = url;
    _storageService.write(AppConstants.keyKioskStartUrl, url);
  }

  void saveAiSettings() {
    // Get value from text controller
    aiProviderHost.value = aiProviderHostController.text;

    // Save AI settings
    _storageService.write(AppConstants.keyAiEnabled, aiEnabled.value);
    _storageService.write(AppConstants.keyAiProviderHost, aiProviderHost.value);

    // Also reload settings in the AI assistant service if available
    try {
      final aiService = Get.find<AiAssistantService>();
      aiService.reloadSettings();
    } catch (_) {
      // Service may not be available yet; ignore
    }

    Get.snackbar(
      'Settings Saved',
      'AI settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void toggleAiEnabled(bool value) {
    aiEnabled.value = value;
    _storageService.write(AppConstants.keyAiEnabled, value);
  }

  void saveAiProviderHost(String host) {
    aiProviderHost.value = host;
    aiProviderHostController.text = host;
    _storageService.write(AppConstants.keyAiProviderHost, host);
  }
}
