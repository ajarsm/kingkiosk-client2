// This file provides backward compatibility for SettingsControllerFixed usage
// It adds compatibility methods to work with existing views

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import '../../../services/person_detection_service.dart';
import '../../../services/media_device_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/permissions_manager.dart';
import 'settings_controller.dart';

export 'settings_controller.dart' show SettingsController;

class SettingsControllerFixed extends SettingsController {
  // Person Detection settings
  final RxBool personDetectionEnabled = false.obs;

  // Background settings
  final RxString backgroundType = 'default'.obs; // default, image, webview
  final RxString backgroundImagePath = ''.obs;
  final RxString backgroundWebUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // Load person detection setting from storage
    personDetectionEnabled.value = Get.find<StorageService>()
            .read<bool>(AppConstants.keyPersonDetectionEnabled) ??
        false;

    // Load background settings from storage
    final storageService = Get.find<StorageService>();
    backgroundType.value =
        storageService.read<String>('backgroundType') ?? 'default';
    backgroundImagePath.value =
        storageService.read<String>('backgroundImagePath') ?? '';
    backgroundWebUrl.value =
        storageService.read<String>('backgroundWebUrl') ?? '';

    // Listen for changes and save to storage
    ever(backgroundType, (String type) {
      storageService.write('backgroundType', type);
      print('✅ Background type saved: $type');
    });

    ever(backgroundImagePath, (String path) {
      storageService.write('backgroundImagePath', path);
      print('✅ Background image path saved: $path');
    });

    ever(backgroundWebUrl, (String url) {
      storageService.write('backgroundWebUrl', url);
      print('✅ Background web URL saved: $url');
    });

    // Listen for changes, sync with PersonDetectionService and save to storage
    ever(personDetectionEnabled, (bool enabled) {
      try {
        final personDetectionService = Get.find<PersonDetectionService>();
        personDetectionService.isEnabled.value = enabled;
      } catch (e) {
        print('PersonDetectionService not available for sync: $e');
      }

      // Save to storage whenever the value changes
      try {
        final storageService = Get.find<StorageService>();
        storageService.write(AppConstants.keyPersonDetectionEnabled, enabled);
        storageService.flush();
        print('✅ Person detection setting saved: $enabled');
      } catch (e) {
        print('❌ Error saving person detection setting: $e');
      }
    });
  }

  // Additional compatibility methods needed by views
  void toggleMqttEnabled(bool value) {
    mqttEnabled.value = value;
    if (!value && mqttConnected.value) {
      disconnectMqtt();
    }

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttEnabled, value);
  }

  void saveMqttBrokerUrl(String url) {
    print('🔧 SettingsControllerFixed.saveMqttBrokerUrl called with: $url');
    mqttBrokerUrl.value = url;
    mqttBrokerUrlController.text = url;

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttBrokerUrl, url);
  }

  void saveMqttBrokerPort(int port) {
    print('🔧 SettingsControllerFixed.saveMqttBrokerPort called with: $port');
    mqttBrokerPort.value = port;

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttBrokerPort, port);
  }

  void saveMqttUsername(String username) {
    print('🔧 SettingsControllerFixed.saveMqttUsername called with: $username');
    mqttUsername.value = username;
    mqttUsernameController.text = username;

    // Save to secure storage if available, fallback to regular storage
    final storageService = Get.find<StorageService>();
    Future.microtask(() async {
      if (storageService.secureStorage != null) {
        try {
          await storageService.secureStorage!.saveMqttUsername(username);
          // Remove from regular storage if it exists
          storageService.remove(AppConstants.keyMqttUsername);
          print('✅ MQTT username saved to secure storage');
        } catch (e) {
          print('❌ Failed to save MQTT username to secure storage: $e');
          // Fallback to regular storage
          storageService.write(AppConstants.keyMqttUsername, username);
        }
      } else {
        // Fallback to regular storage
        storageService.write(AppConstants.keyMqttUsername, username);
      }
    });
  }

  void saveMqttPassword(String password) {
    print(
        '🔧 SettingsControllerFixed.saveMqttPassword called with: ${password.isEmpty ? "empty" : "[REDACTED]"}');
    mqttPassword.value = password;
    mqttPasswordController.text = password;

    // Save to secure storage if available, fallback to regular storage
    final storageService = Get.find<StorageService>();
    Future.microtask(() async {
      if (storageService.secureStorage != null) {
        try {
          await storageService.secureStorage!.saveMqttPassword(password);
          // Remove from regular storage if it exists
          storageService.remove(AppConstants.keyMqttPassword);
          print('✅ MQTT password saved to secure storage');
        } catch (e) {
          print('❌ Failed to save MQTT password to secure storage: $e');
          // Fallback to regular storage
          storageService.write(AppConstants.keyMqttPassword, password);
        }
      } else {
        // Fallback to regular storage
        storageService.write(AppConstants.keyMqttPassword, password);
      }
    });
  }

  void saveDeviceName(String name) {
    print('🔧 SettingsControllerFixed.saveDeviceName called with: $name');
    deviceName.value = name;
    deviceNameController.text = name;

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyDeviceName, name);
  }

  void toggleMqttHaDiscovery(bool value) {
    mqttHaDiscovery.value = value;

    // Reconnect if already connected
    if (value && mqttConnected.value) {
      disconnectMqtt();
      Future.delayed(Duration(milliseconds: 300), () {
        connectMqtt();
      });
    }

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttHaDiscovery, value);
  }

  void saveKioskStartUrl(String url) {
    print('🔧 SettingsControllerFixed.saveKioskStartUrl called with: $url');
    kioskStartUrl.value = url;
    kioskStartUrlController.text = url;

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyKioskStartUrl, url);
  }

  // Additional methods required to fix compilation errors
  @override
  Future<void> setSettingsPin(String pin) async {
    settingsPin.value = pin;
    // Store the PIN in secure storage
    await Get.find<StorageService>().writeSecure('settingsPin', pin);
  }

  Future<void> resetAllSettings() async {
    // Reset all settings to their default values
    isDarkMode.value = false;
    kioskMode.value = true;
    showSystemInfo.value = true;
    kioskStartUrl.value = '';
    kioskStartUrlController.text = '';

    // Reset MQTT settings
    mqttEnabled.value = false;
    mqttBrokerUrl.value = '';
    mqttBrokerUrlController.text = '';
    mqttBrokerPort.value = 1883;
    mqttUsername.value = '';
    mqttUsernameController.text = '';
    mqttPassword.value = '';
    mqttPasswordController.text = '';
    deviceName.value = '';
    deviceNameController.text = '';
    mqttHaDiscovery.value = false; // Reset SIP settings
    sipEnabled.value = false;
    sipServerHost.value = '';
    sipServerHostController.text = '';

    // Reset person detection settings
    personDetectionEnabled.value = false;

    // Disconnect from any active connections
    if (mqttConnected.value) {
      await disconnectMqtt();
    }

    // Unregister from SIP if registered
    if (sipRegistered.value) {
      await unregisterSip();
    } // Save the updated settings to storage
    final storageService = Get.find<StorageService>();
    storageService.write('isDarkMode', isDarkMode.value);
    storageService.write('kioskMode', kioskMode.value);
    storageService.write('showSystemInfo', showSystemInfo.value);
    storageService.write(
        AppConstants.keyPersonDetectionEnabled, personDetectionEnabled.value);
    // Add other settings to be saved here

    Get.snackbar(
        'Settings Reset', 'All settings have been reset to default values');
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

  @override
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
      duration: Duration(seconds: 3),
    );
  }

  void saveSipServerHost(String host) {
    print('🔧 SettingsControllerFixed.saveSipServerHost called with: $host');
    sipServerHost.value = host;
    sipServerHostController.text = host;

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keySipServerHost, host);
    storageService.flush(); // Force flush for Windows persistence
  }

  // Add missing toggleSipEnabled method
  void toggleSipEnabled(bool value) {
    print('🔧 SettingsControllerFixed.toggleSipEnabled called with: $value');
    sipEnabled.value = value;

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keySipEnabled, value);
    storageService.flush(); // Force flush for Windows persistence

    if (!value && sipRegistered.value) {
      unregisterSip();
    }
  } // Add person detection toggle method

  Future<void> togglePersonDetection() async {
    print('🔧 SettingsControllerFixed.togglePersonDetection called');
    personDetectionEnabled.value = !personDetectionEnabled.value;

    // Save the setting
    final storageService = Get.find<StorageService>();
    storageService.write(
        AppConstants.keyPersonDetectionEnabled, personDetectionEnabled.value);
    storageService.flush(); // Force flush for Windows persistence

    // Handle PersonDetectionService registration and management
    PersonDetectionService? personDetectionService;

    try {
      // Try to find existing service
      personDetectionService = Get.find<PersonDetectionService>();
      print('👤 Found existing PersonDetectionService');
    } catch (e) {
      // Service not registered yet
      if (personDetectionEnabled.value) {
        // If we're enabling person detection, register the service
        print(
            '👤 PersonDetectionService not found, registering new service...');
        Get.lazyPut<PersonDetectionService>(() {
          final service = PersonDetectionService();
          return service;
        }, fenix: true);

        // Get the newly registered service
        try {
          personDetectionService = Get.find<PersonDetectionService>();
          print('✅ PersonDetectionService registered and ready');
        } catch (registerError) {
          print('❌ Failed to register PersonDetectionService: $registerError');
          Get.snackbar(
            'Person Detection',
            'Failed to initialize person detection service',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          return;
        }
      } else {
        print(
            '👤 PersonDetectionService not found, but that\'s OK since we\'re disabling');
      }
    }

    // Update the service if available
    if (personDetectionService != null) {
      personDetectionService.isEnabled.value = personDetectionEnabled
          .value; // If enabling, check permissions first, then start detection with the selected camera from MediaDeviceService
      if (personDetectionEnabled.value) {
        // Request camera permission for person detection (no microphone needed)
        final cameraPermissionResult =
            await PermissionsManager.requestCameraPermission();
        if (!cameraPermissionResult.granted) {
          // Revert the toggle if permissions are denied
          personDetectionEnabled.value = false;
          storageService.write(AppConstants.keyPersonDetectionEnabled, false);
          storageService.flush();

          if (cameraPermissionResult.permanentlyDenied) {
            // Show dialog to open settings for permanently denied permissions
            if (Get.context != null) {
              showDialog(
                context: Get.context!,
                builder: (context) => AlertDialog(
                  title: const Text('Permission Required'),
                  content: const Text(
                      'Camera access is permanently denied. Please enable camera permissions in your device settings to use person detection.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await PermissionsManager.openAppSettings();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
            }
          }

          Get.snackbar(
            'Permission Required',
            'Camera and microphone permissions are required for person detection. Please enable them in Settings.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 4),
            mainButton: TextButton(
              onPressed: () {
                PermissionsManager.openAppSettings();
              },
              child:
                  Text('Open Settings', style: TextStyle(color: Colors.white)),
            ),
          );
          return;
        }

        String? selectedCameraId;
        try {
          final mediaDeviceService = Get.find<MediaDeviceService>();
          if (mediaDeviceService.selectedVideoInput.value != null) {
            selectedCameraId =
                mediaDeviceService.selectedVideoInput.value!.deviceId;
            print(
                '👤 Using camera from MediaDeviceService: ${mediaDeviceService.selectedVideoInput.value!.label}');
          }
        } catch (e) {
          print('⚠️ Could not get selected camera from MediaDeviceService: $e');
        }

        // Start detection with selected camera
        personDetectionService
            .startDetection(deviceId: selectedCameraId)
            .then((success) {
          if (success) {
            print('✅ Person detection started successfully');
          } else {
            print('❌ Failed to start person detection');
            Get.snackbar(
              'Person Detection',
              'Failed to start camera for person detection',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.withOpacity(0.8),
              colorText: Colors.white,
              duration: Duration(seconds: 3),
            );
          }
        });
      }
    }

    // Show feedback to user
    Get.snackbar(
      'Person Detection',
      personDetectionEnabled.value
          ? 'Person detection enabled'
          : 'Person detection disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 2),
    );
  }

  // Add SIP protocol selection method
  void setSipProtocol(String protocol) {
    if (protocol != 'ws' && protocol != 'wss') {
      print('Invalid SIP protocol: $protocol. Must be "ws" or "wss"');
      return;
    }

    print('🔧 SettingsControllerFixed.setSipProtocol called with: $protocol');
    sipProtocol.value = protocol;

    // Update SIP service if available and save the setting
    if (sipService != null) {
      sipService!.setProtocol(protocol);
    }

    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keySipProtocol, protocol);
    storageService.flush(); // Force flush for Windows persistence
  }

  @override
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

  // Hardware acceleration compatibility methods
  void loadHardwareAccelerationSettings() {
    super.loadHardwareAccelerationSettings();
  }

  Future<void> toggleHardwareAcceleration(bool enabled) async {
    await super.toggleHardwareAcceleration(enabled);
  }

  /// Force refresh MQTT connection status
  void refreshMqttConnectionStatus() {
    if (mqttService != null) {
      final actualStatus = mqttService!.isConnected.value;
      if (actualStatus != mqttConnected.value) {
        print(
            '🔄 Force refreshing MQTT status: was ${mqttConnected.value}, now $actualStatus');
        mqttConnected.value = actualStatus;
      }
    }
  }

  // Background settings methods
  void setBackgroundType(String type) {
    if (['default', 'image', 'webview'].contains(type)) {
      backgroundType.value = type;
    }
  }

  void setBackgroundImagePath(String path) {
    backgroundImagePath.value = path;
  }

  void setBackgroundWebUrl(String url) {
    backgroundWebUrl.value = url;
  }
}
