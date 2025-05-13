// This file provides backward compatibility for SettingsControllerFixed usage
// It adds compatibility methods to work with existing views

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
}
