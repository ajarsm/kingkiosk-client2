import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../services/platform_sensor_service.dart';
import '../../services/theme_service.dart';
import '../../services/mqtt_service_consolidated.dart';
import '../../services/app_lifecycle_service.dart';
import '../../services/navigation_service.dart';
import '../../controllers/app_state_controller.dart';
import '../../services/background_media_service.dart';
import '../../modules/settings/controllers/settings_controller.dart';
import '../../services/window_manager_service.dart';
import '../../services/websocket_service.dart';
import '../../services/screenshot_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services first - order matters!
    Get.put<StorageService>(StorageService().init(), permanent: true);
    Get.put<ThemeService>(ThemeService().init(), permanent: true);
    Get.put<PlatformSensorService>(PlatformSensorService().init(),
        permanent: true);

    // Core controllers
    Get.put(AppStateController(), permanent: true);
    // Register SettingsController after StorageService is ready
    Get.put(SettingsController(), permanent: true);
    // Additional services
    Get.put<WebSocketService>(WebSocketService().init(), permanent: true);
    Get.put<AppLifecycleService>(AppLifecycleService().init(), permanent: true);
    Get.put<NavigationService>(NavigationService().init(), permanent: true);
    Get.put<BackgroundMediaService>(BackgroundMediaService(), permanent: true);

    // Add ScreenshotService after StorageService is initialized
    Get.put<ScreenshotService>(ScreenshotService(), permanent: true);
    Get.put<WindowManagerService>(WindowManagerService(), permanent: true);

    // Eagerly register MQTT service after dependencies are ready
    final storageService = Get.find<StorageService>();
    final sensorService = Get.find<PlatformSensorService>();
    final mqttService = MqttService(storageService, sensorService);
    mqttService.init().then((service) {
      Get.put<MqttService>(service, permanent: true);
      print('MQTT service initialized successfully');
    });
  }
}
