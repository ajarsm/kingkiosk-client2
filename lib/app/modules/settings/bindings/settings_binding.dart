import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut to avoid registration during build
    Get.lazyPut<SettingsController>(
      () => SettingsController(),
      fenix: true, // Keep the controller in memory
    );
  }
}