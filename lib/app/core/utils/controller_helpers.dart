import 'package:get/get.dart';
import '../../controllers/app_state_controller.dart';

/// Extension to safely get controllers
extension ControllerExtension on GetInterface {
  /// Get AppStateController safely, creating it if needed
  AppStateController getAppState() {
    if (!Get.isRegistered<AppStateController>()) {
      Get.put(AppStateController(), permanent: true);
    }
    return Get.find<AppStateController>();
  }
}