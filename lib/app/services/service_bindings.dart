import 'package:get/get.dart';
import 'platform_sensor_service.dart';
import 'storage_service.dart';
import 'mqtt_service_consolidated.dart';
import '../core/utils/app_constants.dart';

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
          
          // Connect - this will handle online status automatically
          mqttService.connect(
            brokerUrl: brokerUrl,
            port: brokerPort,
          );
        }
      }
    } catch (e) {
      print('Error setting up MQTT auto-connect: $e');
    }
  }
}