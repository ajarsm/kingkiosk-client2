import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import '../services/app_lifecycle_service.dart';
import '../services/sip_service.dart';
import '../services/mqtt_service_consolidated.dart';
import '../core/utils/platform_utils.dart';

/// Service that handles application window close events
class WindowCloseHandler extends GetxService with WindowListener {
  /// Initialize the service
  Future<WindowCloseHandler> init() async {
    // Only setup window close handling on desktop platforms
    if (PlatformUtils.isDesktop) {
      // Set onclose handler
      windowManager.addListener(this);

      // Set prevent close to true to allow our handler to run
      await windowManager.setPreventClose(true);
      debugPrint('Window close handler initialized');
    }

    return this;
  }

  @override
  void onClose() {
    // Remove listener when service is closed
    if (PlatformUtils.isDesktop) {
      windowManager.removeListener(this);
    }
    super.onClose();
  }

  /// Handle window close request
  @override
  void onWindowClose() async {
    debugPrint('Window close requested - performing clean shutdown');

    // Clean up services before allowing window to close
    await _performCleanShutdown();

    // Allow the window to close
    await windowManager.destroy();
  }

  /// Perform clean shutdown of services
  Future<void> _performCleanShutdown() async {
    try {
      debugPrint('Starting clean shutdown sequence for window close');

      // Check if lifecycle service is available
      if (Get.isRegistered<AppLifecycleService>()) {
        final lifecycleService = Get.find<AppLifecycleService>();
        debugPrint('Using AppLifecycleService for clean shutdown');
        await lifecycleService.performCleanShutdown();
        debugPrint('AppLifecycleService.performCleanShutdown completed');
        return;
      }

      debugPrint(
          'AppLifecycleService not found, falling back to direct cleanup');
      // Fallback to direct service cleanup

      // Unregister SIP if available
      if (Get.isRegistered<SipService>()) {
        try {
          final sipService = Get.find<SipService>();
          debugPrint('Unregistering SIP service before close');
          await sipService.unregister();
          debugPrint('SIP unregistration completed');
        } catch (e) {
          debugPrint('Error unregistering SIP: $e');
        }
      }

      // Disconnect MQTT if available
      if (Get.isRegistered<MqttService>()) {
        try {
          final mqttService = Get.find<MqttService>();
          debugPrint('Disconnecting MQTT service before close');
          await mqttService.disconnect();
          debugPrint('MQTT disconnection completed');
        } catch (e) {
          debugPrint('Error disconnecting MQTT: $e');
        }
      }

      // Small delay to ensure cleanup completes
      await Future.delayed(Duration(milliseconds: 200));
      debugPrint('Direct service cleanup completed');
    } catch (e) {
      debugPrint('Error during shutdown: $e');
    }
  }
}
