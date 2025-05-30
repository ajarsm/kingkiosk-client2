// This file provides backward compatibility for SettingsControllerFixed usage
// It adds compatibility methods to work with existing views

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/app_constants.dart';
import 'settings_controller.dart';

export 'settings_controller.dart' show SettingsController;

class SettingsControllerFixed extends SettingsController {
  // Additional compatibility methods needed by views
  void toggleMqttEnabled(bool value) {
    mqttEnabled.value = value;
    if (!value && mqttConnected.value) {
      disconnectMqtt();
    }
    
    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttEnabled, value);
  }void saveMqttBrokerUrl(String url) {
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
    
    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttUsername, username);
  }
  void saveMqttPassword(String password) {
    print('🔧 SettingsControllerFixed.saveMqttPassword called with: ${password.isEmpty ? "empty" : "[REDACTED]"}');
    mqttPassword.value = password;
    mqttPasswordController.text = password;
    
    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keyMqttPassword, password);
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
  void setSettingsPin(String pin) {
    settingsPin.value = pin;
    // Store the PIN in persistent storage
    Get.find<StorageService>().write('settingsPin', pin);
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
    mqttHaDiscovery.value = false;

    // Reset SIP settings
    sipEnabled.value = false;
    sipServerHost.value = '';
    sipServerHostController.text = '';

    // Disconnect from any active connections
    if (mqttConnected.value) {
      await disconnectMqtt();
    }

    // Unregister from SIP if registered
    if (sipRegistered.value) {
      await unregisterSip();
    }

    // Save the updated settings to storage
    final storageService = Get.find<StorageService>();
    storageService.write('isDarkMode', isDarkMode.value);
    storageService.write('kioskMode', kioskMode.value);
    storageService.write('showSystemInfo', showSystemInfo.value);
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
    );  }

  void saveSipServerHost(String host) {
    print('🔧 SettingsControllerFixed.saveSipServerHost called with: $host');
    sipServerHost.value = host;
    sipServerHostController.text = host;
    
    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keySipServerHost, host);
  }

  // Add SIP protocol selection method
  void setSipProtocol(String protocol) {
    if (protocol != 'ws' && protocol != 'wss') {
      print('Invalid SIP protocol: $protocol. Must be "ws" or "wss"');
      return;
    }

    sipProtocol.value = protocol;

    // Update SIP service if available and save the setting
    if (sipService != null) {
      sipService!.setProtocol(protocol);
    }
    
    // Add the missing storage write operation
    final storageService = Get.find<StorageService>();
    storageService.write(AppConstants.keySipProtocol, protocol);
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
}
