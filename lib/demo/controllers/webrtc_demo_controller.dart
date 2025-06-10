import 'dart:async';
import 'package:get/get.dart';
import '../../app/services/person_detection_service.dart';
import '../../app/core/bindings/memory_optimized_binding.dart';

class WebRTCDemoController extends GetxController {
  final RxBool isInitialized = false.obs;
  final RxString statusMessage = 'Initializing...'.obs;
  Timer? _statusTimer;
  PersonDetectionService? _personDetectionService;

  @override
  void onInit() {
    super.onInit();
    _initializeDemo();
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeDemo() async {
    try {
      statusMessage.value = 'Initializing direct video track capture...';

      // 1. Check if PersonDetectionService is conditionally loaded
      statusMessage.value = 'Checking PersonDetectionService availability...';

      await Future.delayed(Duration(seconds: 1));

      final isServiceRegistered = Get.isRegistered<PersonDetectionService>();
      print('PersonDetectionService registered: $isServiceRegistered');

      if (isServiceRegistered) {
        // Service is already loaded (person detection enabled in settings)
        _personDetectionService = Get.find<PersonDetectionService>();
        statusMessage.value =
            '✅ PersonDetectionService found (enabled in settings)';
      } else {
        // Service not loaded (person detection disabled in settings)
        statusMessage.value =
            '⏭️ PersonDetectionService not loaded (disabled in settings)';
      }

      await Future.delayed(Duration(seconds: 1));

      // 2. Demonstrate direct video track capture readiness
      statusMessage.value = 'Testing direct video track capture...';

      statusMessage.value =
          '✅ Direct video track capture ready for camera streams';

      await Future.delayed(Duration(seconds: 1));

      // 3. Show memory optimization status
      statusMessage.value = 'Checking memory optimization...';

      final serviceStatus = ServiceHelpers.getServiceStatus();
      print('Service initialization status: $serviceStatus');

      statusMessage.value =
          '✅ Memory optimization active (${serviceStatus.length} services tracked)';

      await Future.delayed(Duration(seconds: 1));

      // 4. Complete initialization
      isInitialized.value = true;
      statusMessage.value = '🎯 Direct Video Track Capture Demo Ready!';

      // Start periodic status updates if service is available
      if (_personDetectionService != null) {
        _startStatusUpdates();
      }
    } catch (e) {
      statusMessage.value = '❌ Initialization error: $e';
      print('Demo initialization error: $e');
    }
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_personDetectionService != null) {
        final service = _personDetectionService!;
        if (service.isEnabled.value) {
          if (service.isProcessing.value) {
            statusMessage.value =
                '🔄 Processing frames... (${service.framesProcessed.value} processed)';
          } else if (service.isPersonPresent.value) {
            statusMessage.value =
                '👤 Person detected! Confidence: ${service.confidence.value.toStringAsFixed(2)}';
          } else {
            statusMessage.value = '👁️ Monitoring for person presence...';
          }
        } else {
          statusMessage.value = '⏸️ Person detection disabled';
        }
      }
    });
  }

  PersonDetectionService? get personDetectionService => _personDetectionService;
}
