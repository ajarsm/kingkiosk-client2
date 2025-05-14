import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';

import '../../../routes/app_pages_fixed.dart';
import '../../../services/app_lifecycle_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/app_constants.dart';

class SplashController extends GetxController {
  final RxBool isInitialized = false.obs;
  final RxString initStatus = 'Starting...'.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    // Setup initialization sequence with status messages
    initStatus.value = 'Loading services...';
    
    try {
      // Ensure core services are fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if MQTT is configured and enabled
      _checkMqttSettings();
      
      initStatus.value = 'Services loaded successfully';
      await Future.delayed(const Duration(milliseconds: 500));
      
      isInitialized.value = true;
      
      // Navigate to home screen
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      developer.log('Error during initialization: $e', error: e);
      initStatus.value = 'Error during initialization: $e';
      await Future.delayed(const Duration(seconds: 2));
      
      // Still navigate to home even on error
      Get.offAllNamed(Routes.HOME);
    }
  }
  
  // Verify MQTT settings and ensure connectivity if enabled
  void _checkMqttSettings() {
    try {
      final storageService = Get.find<StorageService>();
      final enabled = storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
      
      if (enabled) {
        initStatus.value = 'Checking MQTT connection...';
        
        // Use AppLifecycleService to handle MQTT connection
        if (Get.isRegistered<AppLifecycleService>()) {
          final lifecycleService = Get.find<AppLifecycleService>();
          lifecycleService.connectMqttIfAvailable();
          developer.log('MQTT connection requested during splash screen');
        } else {
          developer.log('AppLifecycleService not found during splash');
        }
      }
    } catch (e) {
      developer.log('Error checking MQTT settings: $e', error: e);
    }
  }
}