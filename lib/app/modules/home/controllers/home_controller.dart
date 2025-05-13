import 'package:get/get.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../controllers/app_state_controller.dart';

/// Controller for the home view
class HomeController extends GetxController {
  // State for maximized web view
  final RxBool isWebViewMaximized = false.obs;
  // Platform sensor service
  late final PlatformSensorService _sensorService;
  late final AppStateController _appStateController;
  
  // Observable properties
  final RxInt batteryLevel = 0.obs;
  final RxString deviceModel = 'Unknown'.obs;
  final RxBool isSystemInfoVisible = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize with safe GetX dependency injection
    _initDependencies();
    
    print('HomeController initialized');
    _updateSystemInfo();
    _bindAppStateChanges();
  }
  
  void _initDependencies() {
    try {
      _sensorService = Get.find<PlatformSensorService>();
      _appStateController = Get.find<AppStateController>();
      
      // Sync with app state
      isSystemInfoVisible.value = _appStateController.showSystemInfo.value;
    } catch (e) {
      print('Error initializing dependencies: $e');
    }
  }
  
  void _bindAppStateChanges() {
    // Listen for changes in app state
    ever(_appStateController.showSystemInfo, (bool visible) {
      isSystemInfoVisible.value = visible;
    });
  }
  
  void _updateSystemInfo() {
    // Get battery level
    batteryLevel.value = _sensorService.batteryLevel.value;
    
    // Listen for battery level changes
    ever(_sensorService.batteryLevel, (level) {
      batteryLevel.value = level as int;
    });
    
    // Get device info
    _sensorService.getSensorData().then((data) {
      deviceModel.value = data.model ?? 'Unknown';
    });
  }
  
  /// Closes the maximized web view and returns to normal view
  void closeMaximizedWebView() {
    isWebViewMaximized.value = false;
    Get.back(); // Close the full-screen view
  }
}