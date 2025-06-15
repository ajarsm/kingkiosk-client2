import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_pages.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/controllers/app_state_controller.dart';
import '../../widgets/user_interaction_tracker.dart';

/// Main widget for the application
/// Used as a wrapper around GetMaterialApp
class MainWidget extends StatelessWidget {
  const MainWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the app state controller if it exists, otherwise we're in tests
    final AppStateController? appState = Get.isRegistered<AppStateController>()
        ? Get.find<AppStateController>()
        : null;

    return GetMaterialApp(
      title: 'Flutter GetX Kiosk',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          appState?.isDarkMode.value == true ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      // Add explicit text direction to fix directionality issues
      textDirection: TextDirection.ltr,
      // Ensure overlays and dialogs have proper context
      builder: (context, child) {
        return UserInteractionTracker(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );
  }
}
