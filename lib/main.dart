import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:screenshot/screenshot.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/bindings/memory_optimized_binding.dart';
import 'app/routes/app_pages_fixed.dart';
import 'app/core/utils/platform_utils.dart';
import 'app/services/screenshot_service.dart';
import 'app/services/audio_service.dart';
import 'app/controllers/halo_effect_controller.dart';
import 'app/widgets/halo_effect/app_halo_wrapper.dart';

import 'package:king_kiosk/notification_system/services/notification_service.dart';
import 'package:king_kiosk/notification_system/services/getx_notification_service.dart';
import 'package:king_kiosk/notification_system/services/alert_service.dart';
import 'app/services/tts_service.dart';
import 'package:king_kiosk/notification_system/models/notification_models.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Note: Isar storage initialization moved to MemoryOptimizedBinding
  print('🔧 Initializing application...');

  // Initialize MediaKit for media playbook
  MediaKit.ensureInitialized();

  // Initialize AudioService first to ensure sounds work
  print('📱 Initializing AudioService at app startup');
  final audioService = AudioService();
  await audioService.init();
  Get.put(audioService, permanent: true);

  // Test notification sound if enabled
  if (const bool.fromEnvironment('TEST_NOTIFICATION_SOUND',
      defaultValue: false)) {
    print('📱 Testing notification sound playback...');
    await AudioService.playNotification();
  }

  // Initialize notification system
  await GetXNotificationService.init();

  // Register and initialize TTS service at app startup to ensure it's ready before MQTT
  print('🟢 [Main] Registering and initializing TTS service...');
  final ttsService = TtsService();
  await ttsService.onInit();
  Get.put<TtsService>(ttsService, permanent: true);
  print('🟢 [Main] TTS service registered and ready');

  // Auto-test notification if enabled
  if (const bool.fromEnvironment('SHOW_TEST_NOTIFICATION',
      defaultValue: false)) {
    print('📱 Auto-testing notification with sound...');
    final notificationService = Get.find<NotificationService>();
    await notificationService.addNotification(
      title: 'Test Notification',
      message: 'This is a test notification with sound!',
      priority: NotificationPriority.high,
    );
  }

  // Initialize window_manager for desktop
  await PlatformUtils.ensureWindowManagerInitialized();
  // Register services
  Get.put<NotificationService>(GetXNotificationService(), permanent: true);
  Get.put<AlertService>(AlertService(), permanent: true);

  runApp(const KioskApp());
}

class KioskApp extends StatefulWidget {
  const KioskApp({Key? key}) : super(key: key);

  @override
  State<KioskApp> createState() => _KioskAppState();
}

class _KioskAppState extends State<KioskApp> {
  late final ScreenshotController _screenshotController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller immediately
    _screenshotController = ScreenshotController();

    // Initialize the HaloEffectControllerGetx early
    try {
      // First try to find an existing instance
      Get.find<HaloEffectControllerGetx>();
      print('✅ Found existing HaloEffectControllerGetx instance');
    } catch (_) {
      // If not found, create a new instance
      print('⚠️ Creating new HaloEffectControllerGetx instance');
      Get.put(HaloEffectControllerGetx(), permanent: true);
    }

    // Schedule a microtask to ensure this runs after InitialBinding has registered the services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Ensure ScreenshotService is registered and update the controller
        if (Get.isRegistered<ScreenshotService>()) {
          print('📸 Updating screenshot controller in existing service');
          final screenshotService = Get.find<ScreenshotService>();
          screenshotService.updateController(_screenshotController);
        } else {
          print('⚠️ ScreenshotService not registered, using ensureInitialized');
          final screenshotService = ScreenshotService.ensureInitialized();
          screenshotService.updateController(_screenshotController);
        }
      } catch (e) {
        print('❌ Error updating screenshot controller: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safely get the controller instance
    HaloEffectControllerGetx? haloController;
    try {
      haloController = Get.find<HaloEffectControllerGetx>();
    } catch (e) {
      print(
          '⚠️ HaloEffectControllerGetx not available in build, creating temporary instance');
      haloController = HaloEffectControllerGetx();
      Get.put(haloController, permanent: true);
    }

    return Screenshot(
      controller: _screenshotController,
      // Use the new AppHaloWrapper instead of AnimatedHaloEffect to avoid duplicate GlobalKeys
      child: GetMaterialApp(
        title: 'Flutter GetX Kiosk',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialBinding: MemoryOptimizedBinding(),
        initialRoute: AppPagesFixed.INITIAL,
        getPages: AppPagesFixed.routes,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Apply halo effect after the MaterialApp is built, inside the builder
          // This prevents duplicate keys and allows proper directionality
          final Widget appWithHalo = AppHaloWrapper(
            controller: haloController!,
            child: child ?? const SizedBox(),
          );
          return appWithHalo;
        },
      ),
    );
  }
}
