import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io' show exit;
import '../../services/app_lifecycle_service.dart';
import '../../services/sip_service.dart';
import '../../services/mqtt_service_consolidated.dart';

class PlatformUtils {
  /// Checks if the current platform is a desktop platform (Windows, macOS, Linux)
  static bool get isDesktop => GetPlatform.isDesktop;

  /// Checks if the current platform is a mobile platform (Android, iOS)
  static bool get isMobile => GetPlatform.isMobile;

  /// Checks if the current platform is web
  static bool get isWeb => kIsWeb;

  /// Gets a user-friendly name for the current platform
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (GetPlatform.isAndroid) return 'Android';
    if (GetPlatform.isIOS) return 'iOS';
    if (GetPlatform.isWindows) return 'Windows';
    if (GetPlatform.isMacOS) return 'macOS';
    if (GetPlatform.isLinux) return 'Linux';
    if (GetPlatform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }

  /// Determines if the current platform can run in kiosk mode
  static bool get canRunInKioskMode => GetPlatform.isDesktop;

  /// Determines if the current platform supports fullscreen
  static bool get supportsFullscreen =>
      !kIsWeb || kIsWeb; // All platforms support some form of fullscreen

  /// Returns true if the platform can support receiving sensor data
  static bool get supportsSensors =>
      GetPlatform.isMobile || GetPlatform.isDesktop;

  /// Returns true if the platform can support WebRTC
  static bool get supportsWebRTC =>
      GetPlatform.isMobile || GetPlatform.isDesktop || kIsWeb;

  /// Call this early in main() for desktop to initialize window_manager
  static Future<void> ensureWindowManagerInitialized() async {
    if (isDesktop) {
      await windowManager.ensureInitialized();
    }
  }

  /// Enable kiosk/fullscreen mode (mobile: immersive, desktop: fullscreen+always-on-top)
  static Future<void> enableKioskMode() async {
    if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (isDesktop) {
      if (GetPlatform.isWindows) {
        await windowManager.setFullScreen(true);
        await windowManager.setPreventClose(true);
        // Do NOT call setAlwaysOnTop(true) on Windows when in fullscreen (causes crash)
        //await windowManager.setSkipTaskbar(true); //this crashes windows with the other options
        await windowManager.setClosable(false);
      } else {
        await windowManager.setFullScreen(true);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setPreventClose(true);
        if (GetPlatform.isLinux) {
          await windowManager.setSkipTaskbar(true);
        }
        if (GetPlatform.isMacOS) {
          await windowManager.setClosable(false);
        }
      }
    }
    // Enable wakelock when kiosk mode is enabled
    await WakelockPlus.enable();
  }

  /// Disable kiosk/fullscreen mode (mobile: restore UI, desktop: exit fullscreen)
  static Future<void> disableKioskMode() async {
    if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else if (isDesktop) {
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setPreventClose(false);
      if (GetPlatform.isWindows || GetPlatform.isLinux) {
        await windowManager.setSkipTaskbar(false);
      }
    }
    // Disable wakelock when kiosk mode is disabled
    await WakelockPlus.disable();
  }

  /// Exit the application
  static Future<void> exitApplication() async {
    try {
      // First unregister from all services for clean shutdown
      if (Get.isRegistered<AppLifecycleService>()) {
        // Use the lifecycle service to perform clean disconnection
        final lifecycleService = Get.find<AppLifecycleService>();
        await lifecycleService.performCleanShutdown();
      } else {
        // Direct service cleanup if lifecycle service is not available
        await _cleanupServices();
      }

      // Then disable kiosk mode
      await disableKioskMode();
    } catch (e) {
      print('Error during shutdown: $e');
      // Continue with exit even if cleanup fails
    }

    // Close the app using the appropriate method for each platform
    if (isDesktop) {
      await windowManager.destroy();
    } else if (GetPlatform.isAndroid) {
      SystemNavigator.pop();
    } else if (GetPlatform.isIOS) {
      exit(
          0); // This is a hard exit, generally discouraged on iOS but necessary for kiosk apps
    } else if (!kIsWeb) {
      exit(0); // Fallback for other platforms
    }
    // Web can't be exited programmatically
  }

  /// Helper method to clean up services when exiting
  static Future<void> _cleanupServices() async {
    // Enhanced for more thorough cleanup
    print('Performing comprehensive cleanup of all services before exit');

    // Unregister SIP if available
    if (Get.isRegistered<SipService>()) {
      try {
        final sipService = Get.find<SipService>();
        print('Unregistering SIP service before exit');
        await sipService.unregister();
      } catch (e) {
        print('Error unregistering SIP: $e');
      }
    }

    // Disconnect MQTT if available
    if (Get.isRegistered<MqttService>()) {
      try {
        final mqttService = Get.find<MqttService>();
        print('Disconnecting MQTT service before exit');
        await mqttService.disconnect();
      } catch (e) {
        print('Error disconnecting MQTT: $e');
      }
    }

    // Give a small delay to ensure all cleanup operations complete
    await Future.delayed(Duration(milliseconds: 300));
  }
}
