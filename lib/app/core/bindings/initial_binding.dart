import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
import '../../services/media_recovery_service.dart';
import '../../controllers/call_settings_controller.dart';
import '../../controllers/mediasoup_controller.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    // Register GetStorage first
    Get.put<GetStorage>(GetStorage(), permanent: true);

    // Core services first - order matters!
    Get.put<StorageService>(await StorageService().init(), permanent: true);
    Get.put<ThemeService>(await ThemeService().init(), permanent: true);
    Get.put<PlatformSensorService>(await PlatformSensorService().init(),
        permanent: true);

    // Core controllers
    Get.put(AppStateController(), permanent: true);
    Get.put(SettingsController(), permanent: true);

    // Services that don't need async init
    Get.put<AppLifecycleService>(AppLifecycleService().init(), permanent: true);
    Get.put<NavigationService>(NavigationService().init(), permanent: true);
    Get.put<BackgroundMediaService>(BackgroundMediaService(), permanent: true);
    Get.put<ScreenshotService>(ScreenshotService(), permanent: true);
    Get.put<WindowManagerService>(WindowManagerService(), permanent: true);

    // Register signaling and call settings
    Get.putAsync<SignalingService>(
      () => SignalingService(serverUrl: 'wss://your-mediasoup-server.com/ws')
          .init(),
      permanent: true,
    );
    Get.put(CallSettingsController(), permanent: true);

    // Register media recovery service
    Get.put<MediaRecoveryService>(await MediaRecoveryService().init(),
        permanent: true);

    // Register MediasoupController
    Get.lazyPut(() => MediasoupController());

    // Eagerly register MQTT service after dependencies are ready
    final storageService = Get.find<StorageService>();
    final sensorService = Get.find<PlatformSensorService>();
    final mqttService = MqttService(storageService, sensorService);
    final initializedMqttService = await mqttService.init();
    Get.put<MqttService>(initializedMqttService, permanent: true);
    print('MQTT service initialized successfully');
  }
}
