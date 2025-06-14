// filepath: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/settings/controllers/settings_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/storage_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../../services/theme_service.dart';
import '../../../services/sip_service.dart';
import '../../../services/ai_assistant_service.dart';
import '../../../services/media_hardware_detection.dart';
import '../../../services/android_kiosk_service.dart';
import '../../../services/windows_kiosk_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/permissions_manager.dart';
import '../../../widgets/settings_pin_dialog.dart';

/// Consolidated settings controller that incorporates all fixes
class SettingsController extends GetxController {  // Services
  final StorageService _storageService = Get.find<StorageService>();
  MqttService? _mqttService;
  SipService? _sipService;
  AndroidKioskService? _androidKioskService;
  WindowsKioskService? _windowsKioskService;

  // Robust getter for MqttService to handle late registration
  MqttService? get mqttService {
    if (_mqttService == null) {
      try {
        _mqttService = Get.find<MqttService>();
        print('✅ MQTT service found and cached');
      } catch (_) {
        // Still not available
        print('⏳ MQTT service not yet available');
      }
    }
    return _mqttService;
  }
  // Getter for SipService
  SipService? get sipService {
    if (_sipService == null) {
      try {
        _sipService = Get.find<SipService>();
        // If we just found the service, trigger an update to refresh UI
        if (_sipService != null) {
          update();
        }
      } catch (_) {
        // Still not available - schedule a retry
        _scheduleServiceCheck();
      }
    }
    return _sipService;
  }

  // Getter for AndroidKioskService
  AndroidKioskService? get androidKioskService {
    if (_androidKioskService == null && Platform.isAndroid) {
      try {
        _androidKioskService = Get.find<AndroidKioskService>();
        print('✅ Android kiosk service found and cached');
      } catch (_) {
        print('⏳ Android kiosk service not yet available');
      }
    }
    return _androidKioskService;
  }

  // Getter for WindowsKioskService
  WindowsKioskService? get windowsKioskService {
    if (_windowsKioskService == null && Platform.isWindows) {
      try {
        _windowsKioskService = Get.find<WindowsKioskService>();
        print('✅ Windows kiosk service found and cached');
      } catch (_) {
        print('⏳ Windows kiosk service not yet available');
      }
    }
    return _windowsKioskService;
  }

  Timer? _serviceCheckTimer;

  void _scheduleServiceCheck() {
    // Avoid multiple timers
    if (_serviceCheckTimer?.isActive == true) return;
    _serviceCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        final service = Get.find<SipService>();
        _sipService = service;
        update(); // Trigger UI update
        timer.cancel();
      } catch (_) {
        // Service still not available
      }

      // Stop checking after 30 seconds to avoid infinite polling
      if (timer.tick > 30) {
        timer.cancel();
      }
    });
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

  // Location settings
  final RxBool locationEnabled = false.obs;
  final RxBool isRequestingLocationPermission = false.obs;

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
  // MEDIA HARDWARE SETTINGS

  // Get MediaHardwareDetectionService or null if not available
  MediaHardwareDetectionService? _mediaHardwareService;

  MediaHardwareDetectionService? get mediaHardwareService {
    if (_mediaHardwareService == null) {
      try {
        _mediaHardwareService = Get.find<MediaHardwareDetectionService>();
      } catch (_) {
        // Not available
      }
    }
    return _mediaHardwareService;
  }

  // Observable for hardware acceleration status
  final isHardwareAccelerationEnabled = true.obs;
  final isProblematicDevice = false.obs;
  final lastMediaError = Rx<String?>(null);

  // Toggle hardware acceleration
  Future<void> toggleHardwareAcceleration(bool enabled) async {
    final service = mediaHardwareService;
    if (service != null) {
      await service.toggleHardwareAcceleration(enabled);
      isHardwareAccelerationEnabled.value =
          service.isHardwareAccelerationEnabled.value;
    }
  }

  // Load hardware acceleration settings
  void loadHardwareAccelerationSettings() {
    final service = mediaHardwareService;
    if (service != null) {
      isHardwareAccelerationEnabled.value =
          service.isHardwareAccelerationEnabled.value;
      isProblematicDevice.value = service.deviceInfo.value.isNotEmpty &&
          service.problemDevices.any((device) => service.deviceInfo.value.values
              .any((value) => value.toString().toLowerCase().contains(device)));
      lastMediaError.value = service.lastError.value;
    }
  }

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

    // Try to find Android Kiosk service (platform-specific)
    if (Platform.isAndroid) {
      try {
        _androidKioskService = Get.find<AndroidKioskService>();
      } catch (e) {
        print('Android Kiosk Service not available: $e');
        _androidKioskService = null;
      }
    }

    // Try to find Windows Kiosk service (platform-specific)
    if (Platform.isWindows) {
      try {
        _windowsKioskService = Get.find<WindowsKioskService>();
      } catch (e) {
        print('Windows Kiosk Service not available: $e');
        _windowsKioskService = null;
      }
    }

    // Safely load settings on the next event loop
    Future.microtask(() async {
      // Load settings PIN from secure storage
      final pin = await _storageService.readSecure<String>('settingsPin');
      settingsPin.value = pin ?? '1234';

      await _loadSettingsWithHostname();
      _initControllerValues();

      // Load hardware acceleration settings
      loadHardwareAccelerationSettings();

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
    _serviceCheckTimer?.cancel();
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
    mqttHaDiscovery.value =
        _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;

    // Load MQTT credentials from secure storage if available, fallback to regular storage
    await _loadMqttCredentials();

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

    // Load location settings
    locationEnabled.value =
        _storageService.read<bool>(AppConstants.keyLocationEnabled) ?? false;

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

    // Load hardware acceleration settings
    loadHardwareAccelerationSettings();
  }

  /// Load MQTT credentials from secure storage
  Future<void> _loadMqttCredentials() async {
    try {
      print('🔑 Loading MQTT credentials from secure storage...');

      // Load MQTT credentials from secure storage via storage service
      final username =
          await _storageService.readSecure<String>('secure_mqtt_username');
      final password =
          await _storageService.readSecure<String>('secure_mqtt_password');

      mqttUsername.value = username ?? '';
      mqttPassword.value = password ?? '';

      print('✅ MQTT credentials loaded from secure storage');
      print(
          '🔑 Username: ${username?.isNotEmpty == true ? "[SET]" : "[EMPTY]"}');
      print(
          '🔑 Password: ${password?.isNotEmpty == true ? "[SET]" : "[EMPTY]"}');
    } catch (e) {
      print('❌ Error loading MQTT credentials from secure storage: $e');
      // Set defaults on error
      mqttUsername.value = '';
      mqttPassword.value = '';
    }
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
    // Initialize MQTT connection status with retry logic for timing issues
    if (mqttService != null) {
      // Set initial status
      mqttConnected.value = mqttService!.isConnected.value;

      // Listen to connection status changes
      ever(mqttService!.isConnected, (bool connected) {
        mqttConnected.value = connected;
        print(
            '🔄 MQTT connection status updated in settings controller: $connected');
      });

      // Add retry logic for timing synchronization issues
      // Check status again after a brief delay to catch auto-connections
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (timer.tick > 10) {
          timer.cancel(); // Stop checking after 10 seconds
          return;
        }

        final currentServiceStatus = mqttService!.isConnected.value;
        if (currentServiceStatus != mqttConnected.value) {
          print(
              '🔄 MQTT status sync correction: service=$currentServiceStatus, controller=${mqttConnected.value}');
          mqttConnected.value = currentServiceStatus;
        }
      });
    } else {
      // If service not available, retry finding it
      Timer.periodic(Duration(seconds: 2), (timer) {
        if (timer.tick > 5) {
          timer.cancel(); // Stop trying after 10 seconds
          return;
        }
        try {
          if (Get.isRegistered<MqttService>()) {
            _mqttService = Get.find<MqttService>();
            print('🔄 Found MQTT service on retry, initializing status');
            _initMqttStatus(); // Recursively call to set up properly
            timer.cancel();
          }
        } catch (e) {
          print('🔄 MQTT service still not available on retry: $e');
        }
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
    _storageService.flush(); // Force flush for Windows persistence
    _applyTheme();
  }
  void toggleKioskMode() async {
    kioskMode.value = !kioskMode.value;
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
    _storageService.flush(); // Force flush for Windows persistence
    
    // Control wakelock based on kiosk mode
    if (kioskMode.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    // Call platform-specific kiosk services
    if (Platform.isAndroid && androidKioskService != null) {
      try {
        if (kioskMode.value) {
          print('🔒 Enabling Android kiosk mode...');
          await androidKioskService!.enableKioskMode();
        } else {
          print('🔓 Disabling Android kiosk mode...');
          await androidKioskService!.disableKioskMode();
        }
      } catch (e) {
        print('❌ Android kiosk mode toggle failed: $e');
        Get.snackbar(
          'Kiosk Mode Error',
          'Failed to toggle Android kiosk mode: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
        );
      }
    } else if (Platform.isWindows && windowsKioskService != null) {
      try {
        if (kioskMode.value) {
          print('🔒 Enabling Windows kiosk mode...');
          await windowsKioskService!.enableKioskMode();
        } else {
          print('🔓 Disabling Windows kiosk mode...');
          await windowsKioskService!.disableKioskMode();
        }
      } catch (e) {
        print('❌ Windows kiosk mode toggle failed: $e');
        Get.snackbar(
          'Kiosk Mode Error',
          'Failed to toggle Windows kiosk mode: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
        );
      }
    }

    // Show success message
    Get.snackbar(
      kioskMode.value ? 'Kiosk Mode Enabled' : 'Kiosk Mode Disabled',
      kioskMode.value 
        ? 'Device is now in strict kiosk mode'
        : 'Kiosk mode has been disabled',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: kioskMode.value 
        ? Colors.green.withOpacity(0.7) 
        : Colors.blue.withOpacity(0.7),
      colorText: Colors.white,
    );
  }

  void toggleShowSystemInfo() {
    showSystemInfo.value = !showSystemInfo.value;
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
    _storageService.flush(); // Force flush for Windows persistence
  }

  void saveAppSettings() {
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
    _storageService.flush(); // Force flush for Windows persistence

    Get.snackbar(
      'Settings Saved',
      'App settings have been updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void saveMqttSettings() async {
    // Get values from text controllers
    mqttBrokerUrl.value = mqttBrokerUrlController.text;
    mqttUsername.value = mqttUsernameController.text;
    mqttPassword.value = mqttPasswordController.text;
    deviceName.value = deviceNameController.text;

    // Save non-sensitive MQTT settings to regular storage
    _storageService.write(AppConstants.keyMqttEnabled, mqttEnabled.value);
    _storageService.write(AppConstants.keyMqttBrokerUrl, mqttBrokerUrl.value);
    _storageService.write(AppConstants.keyMqttBrokerPort, mqttBrokerPort.value);
    _storageService.write(AppConstants.keyDeviceName, deviceName.value);
    _storageService.write(
        AppConstants.keyMqttHaDiscovery, mqttHaDiscovery.value);

    // Save sensitive MQTT credentials to secure storage
    try {
      print('🔑 Saving MQTT credentials to secure storage...');
      print(
          '🔑 Username: ${mqttUsername.value.isNotEmpty ? "[SET]" : "[EMPTY]"}');
      print(
          '🔑 Password: ${mqttPassword.value.isNotEmpty ? "[SET]" : "[EMPTY]"}');

      await _storageService.writeSecure('mqttUsername', mqttUsername.value);
      await _storageService.writeSecure('mqttPassword', mqttPassword.value);
      print('✅ MQTT credentials saved to secure storage');
    } catch (e) {
      print('❌ Error saving MQTT credentials to secure storage: $e');
    }

    // Force flush for persistence
    _storageService.flush();

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
    _storageService.flush(); // Force flush for Windows persistence

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
    _storageService.flush(); // Force flush for Windows persistence

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
    _storageService.flush(); // Force flush for Windows persistence

    // Update MQTT service if available
    if (mqttService != null) {
      mqttService!.deviceName.value = sanitized;
    }

    // Update SIP service if available
    if (sipService != null) {
      sipService!.deviceName.value = sanitized;
    }
  }

  Future<void> setSettingsPin(String pin) async {
    settingsPin.value = pin;
    await _storageService.writeSecure('settingsPin', pin);
    // No need to flush for secure storage
  }

  /// Verify if the provided PIN matches the stored settings PIN
  Future<bool> verifySettingsPin(String pin) async {
    // First check if the current reactive value matches (fast path)
    if (settingsPin.value == pin) {
      return true;
    }

    // If not, re-read from secure storage to ensure we have the latest value
    final storedPin = await _storageService.readSecure<String>('settingsPin');
    final actualPin = storedPin ?? '1234';

    // Update the reactive value if it was stale
    if (settingsPin.value != actualPin) {
      settingsPin.value = actualPin;
    }

    return actualPin == pin;
  }

  void connectMqtt() async {
    // Try to get MQTT service with retry logic
    MqttService? service = mqttService;

    if (service == null) {
      print('⏳ MQTT Service not immediately available, waiting...');

      // Show user feedback
      Get.snackbar(
        'MQTT Connection',
        'Waiting for MQTT service to initialize...',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );

      // Wait up to 10 seconds for service to become available
      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(seconds: 1));
        service = mqttService; // Try again
        if (service != null) {
          print('✅ MQTT service became available after ${i + 1} second(s)');
          break;
        }
        print('⏳ Still waiting for MQTT service... (${i + 1}/10)');
      }

      if (service == null) {
        print('❌ MQTT Service still not available after 10 seconds');
        Get.snackbar(
          'MQTT Error',
          'MQTT service failed to initialize. Try restarting the app.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }
    }

    // Always update the MQTT service device name before connecting
    service.deviceName.value = deviceName.value;

    // Only attempt to connect if not already connected
    if (service.isConnected.value) {
      print('MQTT already connected, skipping connection attempt');
      Get.snackbar(
        'MQTT Status',
        'Already connected to MQTT broker',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return;
    }

    print(
        'Attempting to connect to MQTT broker: ${mqttBrokerUrl.value}:${mqttBrokerPort.value}');

    try {
      final success = await service.connect(
        brokerUrl: mqttBrokerUrl.value,
        port: mqttBrokerPort.value,
        username: mqttUsername.value.isNotEmpty ? mqttUsername.value : null,
        password: mqttPassword.value.isNotEmpty ? mqttPassword.value : null,
      );

      if (success) {
        mqttConnected.value = true;
        Get.snackbar(
          'MQTT Connected',
          'Successfully connected to ${mqttBrokerUrl.value}:${mqttBrokerPort.value}',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        mqttConnected.value = false;
        Get.snackbar(
          'MQTT Connection Failed',
          'Failed to connect. Check your broker settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('❌ MQTT connection error: $e');
      mqttConnected.value = false;
      Get.snackbar(
        'MQTT Error',
        'Connection error: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
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

    // Clear MQTT credentials from secure storage
    Future.microtask(() async {
      if (_storageService.secureStorage != null) {
        try {
          await _storageService.secureStorage!.saveMqttUsername('');
          await _storageService.secureStorage!.saveMqttPassword('');
          print('✅ MQTT credentials cleared from secure storage');
        } catch (e) {
          print('❌ Error clearing MQTT credentials from secure storage: $e');
        }
      }
    });

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
    _storageService.flush(); // Force flush for Windows persistence
    if (!value && sipRegistered.value) {
      unregisterSip();
    }
  }

  void toggleLocationEnabled(bool value) async {
    print('🗺️ toggleLocationEnabled called with value: $value');

    // Prevent concurrent permission requests
    if (isRequestingLocationPermission.value) {
      print('🗺️ Already requesting permission, ignoring call');
      return;
    }

    if (value) {
      // Request permission when enabling
      isRequestingLocationPermission.value = true;
      try {
        print('🗺️ Requesting location permission...');

        // Add a small delay to avoid permission conflicts
        await Future.delayed(Duration(milliseconds: 500));

        final permissionResult =
            await PermissionsManager.requestLocationPermission();
        print(
            '🗺️ Permission result: granted=${permissionResult.granted}, status=${permissionResult.status}');

        if (permissionResult.granted) {
          locationEnabled.value = true;
          _storageService.write(AppConstants.keyLocationEnabled, true);
          print('🗺️ Location services enabled and saved to storage');

          // Test location access to ensure it's working
          try {
            await _testLocationAccess();
          } catch (e) {
            print('🗺️ Warning: Location access test failed: $e');
          }

          Get.snackbar(
            'Location Services',
            'Location services enabled successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
        } else {
          // Permission denied, keep toggle off
          locationEnabled.value = false;
          _storageService.write(AppConstants.keyLocationEnabled, false);
          print('🗺️ Location permission denied, toggle set to false');

          String userMessage = permissionResult.permanentlyDenied
              ? 'Location permission permanently denied. Please enable in device settings.'
              : 'Location permission denied. Please allow location access.';

          Get.snackbar(
            'Location Permission Required',
            userMessage,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 5),
          );
        }
      } catch (e) {
        print('🗺️ Error requesting location permission: $e');
        locationEnabled.value = false;
        _storageService.write(AppConstants.keyLocationEnabled, false);
        Get.snackbar(
          'Location Error',
          'Failed to request location permission: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
      } finally {
        isRequestingLocationPermission.value = false;
      }
    } else {
      // Simply disable when turning off
      print('🗺️ Disabling location services');
      locationEnabled.value = false;
      _storageService.write(AppConstants.keyLocationEnabled, false);
      Get.snackbar(
        'Location Services',
        'Location services disabled',
        backgroundColor: Colors.grey,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    }
  }

  /// Test location access to verify permission is working
  Future<void> _testLocationAccess() async {
    try {
      // Try to get current position with a timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      );
      print(
          '🗺️ Location test successful: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('🗺️ Location test failed: $e');
      throw e;
    }
  }

  void saveMqttBrokerUrl(String url) {
    mqttBrokerUrl.value = url;
    mqttBrokerUrlController.text = url;
    _storageService.write(AppConstants.keyMqttBrokerUrl, url);
    _storageService.flush(); // Force flush for Windows persistence
  }

  void saveMqttBrokerPort(int port) {
    mqttBrokerPort.value = port;
    _storageService.write(AppConstants.keyMqttBrokerPort, port);
    _storageService.flush(); // Force flush for Windows persistence
  }

  void saveMqttUsername(String username) async {
    mqttUsername.value = username;
    mqttUsernameController.text = username;

    // Save to secure storage
    try {
      await _storageService.writeSecure('secure_mqtt_username', username);
      print('✅ MQTT username saved to secure storage');
    } catch (e) {
      print('❌ Failed to save MQTT username to secure storage: $e');
    }
  }

  void saveMqttPassword(String password) async {
    mqttPassword.value = password;
    mqttPasswordController.text = password;

    // Save to secure storage
    try {
      await _storageService.writeSecure('secure_mqtt_password', password);
      print('✅ MQTT password saved to secure storage');
    } catch (e) {
      print('❌ Failed to save MQTT password to secure storage: $e');
    }
  }

  void saveSipServerHost(String host) {
    sipServerHost.value = host;
    sipServerHostController.text = host;
    _storageService.write(AppConstants.keySipServerHost, host);
    _storageService.flush(); // Force flush for Windows persistence
  }

  void saveKioskStartUrl(String url) {
    kioskStartUrl.value = url;
    kioskStartUrlController.text = url;
    _storageService.write(AppConstants.keyKioskStartUrl, url);
    _storageService.flush(); // Force flush for Windows persistence
  }

  void saveAiSettings() {
    // Get value from text controller
    aiProviderHost.value = aiProviderHostController.text;

    // Save AI settings
    _storageService.write(AppConstants.keyAiEnabled, aiEnabled.value);
    _storageService.write(AppConstants.keyAiProviderHost, aiProviderHost.value);
    _storageService.flush(); // Force flush for Windows persistence

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
    _storageService.flush(); // Force flush for Windows persistence
  }

  void saveAiProviderHost(String host) {
    aiProviderHost.value = host;
    aiProviderHostController.text = host;
    _storageService.write(AppConstants.keyAiProviderHost, host);
    _storageService.flush(); // Force flush for Windows persistence
  }
}
