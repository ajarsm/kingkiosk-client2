import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:screenshot/screenshot.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/bindings/initial_binding.dart';
import 'app/routes/app_pages_fixed.dart';
import 'app/core/utils/platform_utils.dart';
import 'app/services/screenshot_service.dart';
import 'app/services/audio_service.dart';

import 'package:king_kiosk/notification_system/services/notification_service.dart';
import 'package:king_kiosk/notification_system/services/getx_notification_service.dart';
import 'package:king_kiosk/notification_system/models/notification_models.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for persistent settings
  await GetStorage.init(); // Initialize MediaKit for media playback
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
  // Remove ScreenshotService from here - it will be initialized in InitialBinding

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

    // Schedule a microtask to ensure this runs after InitialBinding has registered the services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Update the ScreenshotService with our controller
        final screenshotService = Get.find<ScreenshotService>();
        screenshotService.updateController(_screenshotController);
      } catch (e) {
        print('❌ Error updating screenshot controller: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: GetMaterialApp(
        title: 'Flutter GetX Kiosk',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialBinding: InitialBinding(),
        initialRoute: AppPagesFixed.INITIAL,
        getPages: AppPagesFixed.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
