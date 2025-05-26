import 'package:get/get.dart';

import '../controllers/settings_controller_compat.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut to avoid registration during build
    Get.lazyPut<SettingsControllerFixed>(
      () => SettingsControllerFixed(),
      fenix: true, // Keep the controller in memory
    );
  }
}