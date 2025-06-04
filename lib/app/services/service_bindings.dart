import 'package:get/get.dart';
import 'dart:async';
import 'platform_sensor_service.dart';
import 'storage_service.dart';
import 'mqtt_service_consolidated.dart';
import '../core/utils/app_constants.dart';
import '../modules/settings/controllers/settings_controller.dart';
import '../modules/settings/controllers/settings_controller_compat.dart';
import '../modules/settings/controllers/combined_settings_controller.dart';

/// Helper class to provide properly configured service instances
class ServiceBindings {
  /// Initialize the consolidated MQTT service (using 60s update interval)
  static void initMqttService() {
    try {
      // Get required dependencies
      final storageService = Get.find<StorageService>();
      final sensorService = Get.find<PlatformSensorService>();
      
      // If there's an existing MQTT service, delete it
      if (Get.isRegistered<MqttService>()) {
        try {
          final existingService = Get.find<MqttService>();
          // Try to disconnect if connected
          existingService.disconnect();
          // Remove from GetX
          Get.delete<MqttService>(force: true);
        } catch (e) {
          print('Error removing existing MqttService: $e');
        }
      }
      
      // Create and register the consolidated MQTT service
      final mqttService = new MqttService(storageService, sensorService);
      mqttService.init();
      
      // Register it with GetX
      Get.put<MqttService>(mqttService, permanent: true);
      
      print('MQTT Service initialized with 60s update interval');
    } catch (e) {
      print('Error initializing MQTT service: $e');
    }
  }
    /// Check if MQTT should auto-connect and set it up
  static void setupMqttAutoConnect() {
    try {
      // Get dependencies
      final storageService = Get.find<StorageService>();
      
      // Check if MQTT is enabled
      final mqttEnabled = storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
      
      if (mqttEnabled) {
        // Get MQTT settings
        final brokerUrl = storageService.read<String>(AppConstants.keyMqttBrokerUrl) ?? 'broker.emqx.io';
        final brokerPort = storageService.read<int>(AppConstants.keyMqttBrokerPort) ?? 1883;
        
        // Get the MQTT service
        if (Get.isRegistered<MqttService>()) {
          final mqttService = Get.find<MqttService>();
          print('Auto-connecting to MQTT broker: $brokerUrl:$brokerPort');
          
          // Add a delay to ensure settings controllers have time to initialize
          Timer(Duration(milliseconds: 1500), () {
            // Connect - this will handle online status automatically
            mqttService.connect(
              brokerUrl: brokerUrl,
              port: brokerPort,
            ).then((success) {
              if (success) {
                print('✅ MQTT auto-connection successful');
                // Notify all settings controllers to update their status
                _notifySettingsControllersOfMqttConnection();
              } else {
                print('❌ MQTT auto-connection failed');
              }
            });
          });
        }
      }
    } catch (e) {
      print('Error setting up MQTT auto-connect: $e');
    }
  }

  /// Notify all settings controllers to update their MQTT connection status
  static void _notifySettingsControllersOfMqttConnection() {
    try {
      // Try to find and update SettingsController
      if (Get.isRegistered<SettingsController>()) {
        final controller = Get.find<SettingsController>();
        if (controller.mqttService != null) {
          controller.mqttConnected.value = controller.mqttService!.isConnected.value;
          print('🔄 Updated SettingsController MQTT status');
        }
      }
    } catch (e) {
      print('🔄 Could not update SettingsController: $e');
    }

    try {
      // Try to find and update SettingsControllerFixed
      if (Get.isRegistered<SettingsControllerFixed>()) {
        final controller = Get.find<SettingsControllerFixed>();
        controller.refreshMqttConnectionStatus();
        print('🔄 Updated SettingsControllerFixed MQTT status');
      }
    } catch (e) {
      print('🔄 Could not update SettingsControllerFixed: $e');
    }    try {
      // Try to find and update CombinedSettingsController
      if (Get.isRegistered<CombinedSettingsController>()) {
        final controller = Get.find<CombinedSettingsController>();
        controller.refreshMqttConnectionStatus();
        print('🔄 Updated CombinedSettingsController MQTT status');
      }
    } catch (e) {
      print('🔄 Could not update CombinedSettingsController: $e');
    }
  }
}