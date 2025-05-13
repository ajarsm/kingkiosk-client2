import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

/// Binding class that makes sure both original and fixed controllers are properly registered
class FixedSettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Register the fixed controller
    Get.put<SettingsController>(SettingsController(), permanent: true);
    
    // If the original controller is needed, make sure it's registered too
    if (!Get.isRegistered<SettingsController>()) {
      try {
        // Try to register the original controller
        Get.put(SettingsController(), permanent: false);
      } catch (e) {
        print('Could not register original SettingsController: $e');
        // This is expected if there are constructor parameter issues
      }
    }
  }
}