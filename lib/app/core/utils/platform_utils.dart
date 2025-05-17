import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  static bool get supportsFullscreen => !kIsWeb || kIsWeb; // All platforms support some form of fullscreen
  
  /// Returns true if the platform can support receiving sensor data
  static bool get supportsSensors => GetPlatform.isMobile || GetPlatform.isDesktop;
  
  /// Returns true if the platform can support WebRTC
  static bool get supportsWebRTC => GetPlatform.isMobile || GetPlatform.isDesktop || kIsWeb;

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
}