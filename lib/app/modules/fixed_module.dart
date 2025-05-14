import 'package:get/get.dart';
import 'settings/controllers/settings_controller.dart';

/// Helper class to easily initialize fixed components
class FixedModules {
  /// Initialize the fixed components - call this in your app's main.dart
  static void init() {
    // Register the fixed settings controller for global access
    if (!Get.isRegistered<SettingsController>()) {
      Get.put<SettingsController>(SettingsController(), permanent: true);
    }
  }
}