import 'package:flutter_getx_kiosk/app/services/websocket_service.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../services/platform_sensor_service.dart';
import '../../services/theme_service.dart';
import '../../services/mqtt_service_consolidated.dart';
import '../../services/app_lifecycle_service.dart';
import '../../services/navigation_service.dart';
import '../../controllers/app_state_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services first - order matters!
    Get.put<StorageService>(StorageService().init(), permanent: true);
    Get.put<ThemeService>(ThemeService().init(), permanent: true);
    Get.put<PlatformSensorService>(PlatformSensorService().init(), permanent: true);
    
    // Core controllers
    Get.put(AppStateController(), permanent: true);
    
    // Additional services
    Get.put<WebSocketService>(WebSocketService().init(), permanent: true);
    Get.put<AppLifecycleService>(AppLifecycleService().init(), permanent: true);
    Get.put<NavigationService>(NavigationService().init(), permanent: true);

    // MQTT service with 60-second update interval and proper stats
    _initMqttService();
  }
  
  /// Initialize the MQTT service with the proper dependencies
  void _initMqttService() {
    try {
      final storageService = Get.find<StorageService>();
      final sensorService = Get.find<PlatformSensorService>();
      
      // Create and register the consolidated MQTT service
      final mqttService = MqttService(storageService, sensorService);
      // Initialize and make service available to the app
      mqttService.init().then((service) {
        Get.put<MqttService>(service, permanent: true);
        print('MQTT service initialized successfully');
        
        // We don't connect here - we let the AppLifecycleService handle the connection
        // based on the user's settings
      });
    } catch (e) {
      print('Error initializing MQTT service: $e');
    }
  }
}