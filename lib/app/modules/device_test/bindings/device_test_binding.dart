import 'package:get/get.dart';
import '../controllers/device_test_controller.dart';
import '../../../services/performance_monitor_service.dart';

class DeviceTestBinding extends Bindings {
  @override
  void dependencies() {
    // Register the performance monitor service if not already registered
    if (!Get.isRegistered<PerformanceMonitorService>()) {
      Get.put<PerformanceMonitorService>(PerformanceMonitorService().init(), permanent: true);
    }
    
    // Register the device test controller
    Get.lazyPut<DeviceTestController>(
      () => DeviceTestController(),
      fenix: true,
    );
  }
}