import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/bindings/initial_binding.dart';
import 'app/routes/app_pages_fixed.dart';
import 'app/core/utils/platform_utils.dart';
import 'app/services/wyoming_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GetStorage for persistent settings
  await GetStorage.init();
  
  // Initialize MediaKit for media playback
  MediaKit.ensureInitialized();

  // Initialize window_manager for desktop
  await PlatformUtils.ensureWindowManagerInitialized();
  
  // Register WyomingService
  Get.put(WyomingService());
  
  runApp(const KioskApp());
}

class KioskApp extends StatelessWidget {
  const KioskApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter GetX Kiosk',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPagesFixed.INITIAL,
      getPages: AppPagesFixed.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}