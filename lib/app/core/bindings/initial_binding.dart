import 'package:get/get.dart';

import '../../services/websocket_service.dart';
import '../../services/mediasoup_service.dart';
import '../../services/platform_sensor_service.dart';
import '../../services/storage_service.dart';
import '../../services/navigation_service.dart';
import '../../services/theme_service.dart';
import '../../services/mqtt_service.dart';
import '../../services/background_media_service.dart';
import '../../controllers/app_state_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register services as singletons
    Get.put<StorageService>(StorageService().init(), permanent: true);
    Get.put<WebSocketService>(WebSocketService().init(), permanent: true);
    Get.put<MediasoupService>(MediasoupService().init(), permanent: true);
    Get.put<PlatformSensorService>(PlatformSensorService().init(), permanent: true);
    Get.put<NavigationService>(NavigationService().init(), permanent: true);
    Get.put<ThemeService>(ThemeService().init(), permanent: true);
    // Register BackgroundMediaService
    final backgroundMediaService = BackgroundMediaService();
    backgroundMediaService.init().then((_) {
      Get.put<BackgroundMediaService>(backgroundMediaService, permanent: true);
      
      // MQTT Service needs to be initialized after other services
      final storageService = Get.find<StorageService>();
      final sensorService = Get.find<PlatformSensorService>();
      final mqttService = MqttService(storageService, sensorService);
      
      mqttService.init().then((_) {
        Get.put<MqttService>(mqttService, permanent: true);
      });
    });
    
    // Register controllers - use lazyPut to avoid build-time issues
    Get.lazyPut<AppStateController>(() => AppStateController(), fenix: true);
  }
}