// This file provides backward compatibility for SettingsControllerFixed usage
// It adds compatibility methods to work with existing views

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import 'settings_controller.dart';

export 'settings_controller.dart' show SettingsController;

class SettingsControllerFixed extends SettingsController {
  // Additional compatibility methods needed by views

  void toggleMqttEnabled(bool value) {
    mqttEnabled.value = value;
    if (!value && mqttConnected.value) {
      disconnectMqtt();
    }
  }

  void saveMqttBrokerUrl(String url) {
    mqttBrokerUrl.value = url;
    mqttBrokerUrlController.text = url;
  }

  void saveMqttBrokerPort(int port) {
    mqttBrokerPort.value = port;
  }

  void saveMqttUsername(String username) {
    mqttUsername.value = username;
    mqttUsernameController.text = username;
  }

  void saveMqttPassword(String password) {
    mqttPassword.value = password;
    mqttPasswordController.text = password;
  }

  void saveDeviceName(String name) {
    deviceName.value = name;
    deviceNameController.text = name;
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
  }

  void saveKioskStartUrl(String url) {
    kioskStartUrl.value = url;
    kioskStartUrlController.text = url;
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
    );
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
}
