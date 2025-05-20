import 'package:get/get.dart';
import '../controllers/settings_controller_compat.dart';

class SettingsCompatBinding extends Bindings {
  @override
  void dependencies() {
    // Create and register a SettingsControllerFixed instance
    // Only register if it's not already registered
    if (!Get.isRegistered<SettingsControllerFixed>()) {
      // First check if we have a SettingsController
      if (Get.isRegistered<SettingsController>()) {
        // Convert the existing controller to the fixed version
        final existingController = Get.find<SettingsController>();
        Get.put<SettingsControllerFixed>(SettingsControllerFixed()
              ..isDarkMode.value = existingController.isDarkMode.value
              ..kioskMode.value = existingController.kioskMode.value
            // Copy other properties as needed
            );
      } else {
        // Just create a new instance
        Get.put<SettingsControllerFixed>(SettingsControllerFixed());
      }
    }
  }
}
