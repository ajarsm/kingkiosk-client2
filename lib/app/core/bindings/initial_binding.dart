import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import '../../services/storage_service.dart';
import '../../services/platform_sensor_service.dart';
import '../../services/theme_service.dart';
import '../../services/mqtt_service_consolidated.dart';
import '../../services/sip_service.dart';
import '../../services/app_lifecycle_service.dart';
import '../../services/navigation_service.dart';
import '../../controllers/app_state_controller.dart';
import '../../services/background_media_service.dart';
import '../../modules/settings/controllers/settings_controller_compat.dart';
import '../../services/window_manager_service.dart';
import '../../services/screenshot_service.dart';
import '../../services/audio_service.dart';
import '../../services/window_close_handler.dart';
import '../../services/media_control_service.dart';
import '../../services/ai_assistant_service.dart';
import '../../controllers/halo_effect_controller.dart';
import '../../controllers/window_halo_controller.dart';
import '../../services/media_hardware_detection.dart';
import '../../services/android_kiosk_service.dart';
import 'package:king_kiosk/notification_system/services/alert_service.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    // Core services first - order matters!
    Get.put<StorageService>(await StorageService().init(), permanent: true);
    Get.put<ThemeService>(await ThemeService().init(), permanent: true);
    Get.put<PlatformSensorService>(await PlatformSensorService().init(),
        permanent: true); // Core controllers
    Get.put(AppStateController(), permanent: true);
    Get.put(SettingsControllerFixed(), permanent: true);

    // Services that don't need async init
    Get.put<AppLifecycleService>(AppLifecycleService().init(), permanent: true);
    Get.put<NavigationService>(NavigationService().init(), permanent: true);
    Get.put<BackgroundMediaService>(BackgroundMediaService(), permanent: true);
    Get.put<ScreenshotService>(ScreenshotService(), permanent: true);
    Get.put<WindowManagerService>(WindowManagerService(),
        permanent: true); // Initialize audio service for sound effects
    Get.putAsync<AudioService>(() => AudioService().init(),
        permanent:
            true); // Register media recovery service    Get.put<MediaRecoveryService>(await MediaRecoveryService().init(),
    Get.put<WindowCloseHandler>(await WindowCloseHandler().init(),
        permanent: true);

    // Register media control service for handling media playback commands
    Get.put<MediaControlService>(await MediaControlService().init(),
        permanent: true);

    // Register hardware acceleration detection service for media playback
    Get.put<MediaHardwareDetectionService>(
        await MediaHardwareDetectionService().init(),
        permanent:
            true); // Register halo effect controller for status visualization
    if (Get.isRegistered<HaloEffectControllerGetx>()) {
      print(
          '✅ HaloEffectControllerGetx already registered, skipping registration');
    } else {
      print(
          '📝 Registering new HaloEffectControllerGetx instance in InitialBinding');
      Get.put<HaloEffectControllerGetx>(HaloEffectControllerGetx(),
          permanent: true);
    }

    // Register window halo controller for window-specific halo effects
    if (Get.isRegistered<WindowHaloController>()) {
      print('✅ WindowHaloController already registered, skipping registration');
    } else {
      print(
          '📝 Registering new WindowHaloController instance in InitialBinding');
      Get.put<WindowHaloController>(WindowHaloController(), permanent: true);
    }

    // Eagerly register MQTT service after dependencies are ready
    final storageService = Get.find<StorageService>();
    final sensorService = Get.find<PlatformSensorService>();
    final mqttService = MqttService(storageService, sensorService);
    final initializedMqttService = await mqttService
        .init(); // Initialize SIP UA service for communications
    final sipService = SipService(storageService);
    Get.putAsync<SipService>(() => sipService.init(), permanent: true);
    Get.put<MqttService>(initializedMqttService, permanent: true);
    print(
        'MQTT service initialized successfully'); // Register Alert service for center-screen alerts
    Get.put<AlertService>(AlertService(), permanent: true);
    print('Alert service initialized successfully');

    // Register Android Kiosk Service (Android only)
    if (Platform.isAndroid) {
      Get.put<AndroidKioskService>(AndroidKioskService(), permanent: true);
      print('Android Kiosk service initialized successfully');
    }

    // Initialize AI Assistant service
    Future.delayed(Duration(seconds: 2), () {
      // Delay AI service initialization to ensure SIP service is ready
      try {
        final aiAssistantService =
            AiAssistantService(Get.find<SipService>(), storageService);
        Get.putAsync<AiAssistantService>(() => aiAssistantService.init(),
            permanent: true);
        print('AI Assistant service initialized successfully');
      } catch (e) {
        print('Error initializing AI Assistant service: $e');
      }
    });
  }
}
