import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android-specific kiosk mode service
/// Handles home launcher functionality, system UI hiding, and kiosk lockdown
/// with persistent state tracking and auto-restoration
class AndroidKioskService extends GetxService {
  static const MethodChannel _channel = MethodChannel(
    'com.ki.king_kiosk/kiosk',
  );

  // Storage for persistent kiosk state
  late final StorageService _storage;
  static const String _kioskStateKey = 'kiosk_mode_enabled';
  static const String _kioskConfigKey = 'kiosk_config';

  // Observable states
  final RxBool _isKioskModeActive = false.obs;
  final RxBool _isHomeAppSet = false.obs;
  final RxBool _hasSystemPermissions = false.obs;
  final RxBool _isRestoring = false.obs;

  // Getters
  bool get isKioskModeActive => _isKioskModeActive.value;
  bool get isHomeAppSet => _isHomeAppSet.value;
  bool get hasSystemPermissions => _hasSystemPermissions.value;
  bool get isRestoring => _isRestoring.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (Platform.isAndroid) {
      await _initializeStorage();
      await _initializeKioskService();
      await _autoRestoreKioskState();
    }
  }

  /// Initialize storage for persistent state
  Future<void> _initializeStorage() async {
    try {
      _storage = Get.find<StorageService>();
      print('🔒 Kiosk storage initialized');
    } catch (e) {
      print('🔒 Failed to initialize kiosk storage: $e');
    }
  }

  /// Initialize the kiosk service and check current state
  Future<void> _initializeKioskService() async {
    try {
      await _checkSystemPermissions();
      await _checkCurrentKioskState();
    } catch (e) {
      print('🔒 Failed to initialize kiosk service: $e');
    }
  }

  /// Auto-restore kiosk state if it was previously enabled
  Future<void> _autoRestoreKioskState() async {
    try {
      final wasKioskEnabled = _storage.read(_kioskStateKey) ?? false;
      if (wasKioskEnabled && !_isKioskModeActive.value) {
        print('🔒 Auto-restoring kiosk mode...');
        _isRestoring.value = true;

        final restored = await enableKioskMode();
        if (restored) {
          print('✅ Kiosk mode auto-restored successfully');
        } else {
          print('❌ Failed to auto-restore kiosk mode');
          // Clear the saved state if restoration failed
          _storage.remove(_kioskStateKey);
        }

        _isRestoring.value = false;
      }
    } catch (e) {
      print('🔒 Error during auto-restore: $e');
      _isRestoring.value = false;
    }
  }

  /// Check if app has necessary system permissions for kiosk mode
  Future<void> _checkSystemPermissions() async {
    try {
      // Check system alert window permission (for overlay)
      final hasOverlayPermission = await Permission.systemAlertWindow.isGranted;

      // Check device admin permission
      final hasDeviceAdminPermission =
          await _channel.invokeMethod('hasDeviceAdminPermission') ?? false;

      // Check if app is set as home launcher
      final isHomeApp = await _channel.invokeMethod('isSetAsHomeApp') ?? false;

      _hasSystemPermissions.value =
          hasOverlayPermission && hasDeviceAdminPermission;
      _isHomeAppSet.value = isHomeApp;

      print('🔒 System permissions check:');
      print('   Overlay permission: $hasOverlayPermission');
      print('   Device admin permission: $hasDeviceAdminPermission');
      print('   Set as home app: $isHomeApp');
    } catch (e) {
      print('🔒 Error checking system permissions: $e');
      _hasSystemPermissions.value = false;
    }
  }

  /// Check current kiosk state
  Future<void> _checkCurrentKioskState() async {
    try {
      final isActive =
          await _channel.invokeMethod('isKioskModeActive') ?? false;
      _isKioskModeActive.value = isActive;
      print('🔒 Current kiosk mode state: $isActive');
    } catch (e) {
      print('🔒 Error checking kiosk state: $e');
    }
  }

  /// Enable comprehensive kiosk mode with launcher functionality
  Future<bool> enableKioskMode() async {
    if (!Platform.isAndroid) {
      print('🔒 Kiosk mode is only supported on Android');
      return false;
    }

    try {
      print('🔒 Enabling comprehensive Android kiosk mode...');

      // Use the new comprehensive kiosk method
      final result =
          await _channel.invokeMethod('enableKioskWithLauncher') ?? false;

      if (result) {
        _isKioskModeActive.value = true;
        _isHomeAppSet.value = true;

        // Save kiosk state persistently
        _storage.write(_kioskStateKey, true);
        _storage.write(_kioskConfigKey, {
          'enabledAt': DateTime.now().toIso8601String(),
          'autoRestore': true,
        });

        await _checkSystemPermissions();
        print('✅ Comprehensive kiosk mode enabled successfully');
        return true;
      } else {
        print('❌ Failed to enable comprehensive kiosk mode');
        return false;
      }
    } catch (e) {
      print('❌ Failed to enable kiosk mode: $e');
      return false;
    }
  }

  /// Disable kiosk mode and restore normal functionality
  /// Performs comprehensive cleanup to ensure all restrictions are released
  Future<bool> disableKioskMode() async {
    if (!Platform.isAndroid) return false;

    try {
      print('🔒 Disabling comprehensive Android kiosk mode...');

      // Step 1: Disable comprehensive kiosk mode
      final kioskDisabled =
          await _channel.invokeMethod('disableKioskAndLauncher') ?? false;

      // Step 2: Perform additional cleanup steps to ensure full release
      await _performComprehensiveCleanup();

      // Step 3: Clear persistent state
      _storage.remove(_kioskStateKey);
      _storage.remove(_kioskConfigKey);

      // Step 4: Update local state
      _isKioskModeActive.value = false;
      _isHomeAppSet.value = false;

      if (kioskDisabled) {
        print('✅ Comprehensive kiosk mode disabled successfully');
        print('✅ All kiosk restrictions released');
        return true;
      } else {
        print('❌ Failed to disable comprehensive kiosk mode');
        return false;
      }
    } catch (e) {
      print('❌ Failed to disable kiosk mode: $e');
      return false;
    }
  }

  /// Perform comprehensive cleanup to ensure all kiosk restrictions are released
  Future<void> _performComprehensiveCleanup() async {
    try {
      print('🔒 Performing comprehensive kiosk cleanup...');

      // Unblock hardware buttons
      await unblockHardwareButtons();

      // Show system UI
      await _showSystemUI();

      // Disable task lock if active
      final taskLocked = await isTaskLocked();
      if (taskLocked) {
        await disableTaskLock();
      }

      // Clear default launcher if we're set as default
      final isDefault = await isDefaultHomeApp();
      if (isDefault) {
        await clearDefaultLauncher();
      }

      // Allow app uninstall
      await allowAppUninstall();

      // Additional platform-specific cleanup
      await _channel.invokeMethod('performFullCleanup');

      print('✅ Comprehensive cleanup completed');
    } catch (e) {
      print('❌ Error during comprehensive cleanup: $e');
    }
  }

  /// Request all necessary permissions for kiosk mode
  Future<bool> _requestKioskPermissions() async {
    try {
      // Request system alert window permission
      if (!await Permission.systemAlertWindow.isGranted) {
        final overlayPermission = await Permission.systemAlertWindow.request();
        if (!overlayPermission.isGranted) {
          print('❌ System alert window permission denied');
          return false;
        }
      }

      // Request device admin permission
      final deviceAdminGranted =
          await _channel.invokeMethod('requestDeviceAdminPermission') ?? false;
      if (!deviceAdminGranted) {
        print('❌ Device admin permission denied');
        return false;
      }

      // Request ignore battery optimization
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');

      return true;
    } catch (e) {
      print('❌ Error requesting kiosk permissions: $e');
      return false;
    }
  }

  /// Set the app as home launcher
  Future<bool> _setAsHomeLauncher() async {
    try {
      final result = await _channel.invokeMethod('setAsHomeLauncher') ?? false;
      if (result) {
        print('✅ App set as home launcher');
      }
      return result;
    } catch (e) {
      print('❌ Failed to set as home launcher: $e');
      return false;
    }
  }

  /// Remove the app as home launcher
  Future<bool> _removeAsHomeLauncher() async {
    try {
      final result =
          await _channel.invokeMethod('removeAsHomeLauncher') ?? false;
      if (result) {
        print('✅ App removed as home launcher');
      }
      return result;
    } catch (e) {
      print('❌ Failed to remove as home launcher: $e');
      return false;
    }
  }

  /// Enable system lockdown (hide navigation, status bar, etc.)
  Future<bool> _enableSystemLockdown() async {
    try {
      final result =
          await _channel.invokeMethod('enableSystemLockdown') ?? false;
      if (result) {
        print('✅ System lockdown enabled');
      }
      return result;
    } catch (e) {
      print('❌ Failed to enable system lockdown: $e');
      return false;
    }
  }

  /// Disable system lockdown
  Future<bool> _disableSystemLockdown() async {
    try {
      final result =
          await _channel.invokeMethod('disableSystemLockdown') ?? false;
      if (result) {
        print('✅ System lockdown disabled');
      }
      return result;
    } catch (e) {
      print('❌ Failed to disable system lockdown: $e');
      return false;
    }
  }

  /// Show system UI (status bar, navigation)
  Future<void> _showSystemUI() async {
    try {
      await _channel.invokeMethod('showSystemUI');
      print('✅ System UI restored');
    } catch (e) {
      print('❌ Failed to show system UI: $e');
    }
  }

  /// Get persistent kiosk state information
  Map<String, dynamic> getKioskStateInfo() {
    try {
      final isEnabled = _storage.read(_kioskStateKey) ?? false;
      final config = _storage.read(_kioskConfigKey) ?? {};

      return {
        'persistentKioskEnabled': isEnabled,
        'currentKioskActive': _isKioskModeActive.value,
        'isHomeApp': _isHomeAppSet.value,
        'hasPermissions': _hasSystemPermissions.value,
        'isRestoring': _isRestoring.value,
        'config': config,
      };
    } catch (e) {
      print('❌ Failed to get kiosk state info: $e');
      return {
        'persistentKioskEnabled': false,
        'currentKioskActive': false,
        'isHomeApp': false,
        'hasPermissions': false,
        'isRestoring': false,
        'config': {},
      };
    }
  }

  /// Force cleanup of any residual kiosk state
  /// Use this if kiosk mode gets stuck or partially disabled
  Future<bool> forceCleanupKioskState() async {
    try {
      print('🔒 Force cleaning up all kiosk state...');

      // Perform comprehensive cleanup
      await _performComprehensiveCleanup();

      // Clear all persistent state
      _storage.remove(_kioskStateKey);
      _storage.remove(_kioskConfigKey);

      // Reset all observable states
      _isKioskModeActive.value = false;
      _isHomeAppSet.value = false;
      _isRestoring.value = false;

      // Force disable any remaining native kiosk state
      await _channel.invokeMethod('forceDisableAllKioskFeatures');

      print('✅ Force cleanup completed');
      return true;
    } catch (e) {
      print('❌ Failed to force cleanup kiosk state: $e');
      return false;
    }
  }

  /// Hide system UI for immersive experience
  Future<void> hideSystemUI() async {
    try {
      await _channel.invokeMethod('hideSystemUI');
      print('🔒 System UI hidden');
    } catch (e) {
      print('❌ Failed to hide system UI: $e');
    }
  }

  /// Block hardware buttons (back, home, recent apps)
  Future<void> blockHardwareButtons() async {
    try {
      await _channel.invokeMethod('blockHardwareButtons');
      print('🔒 Hardware buttons blocked');
    } catch (e) {
      print('❌ Failed to block hardware buttons: $e');
    }
  }

  /// Unblock hardware buttons
  Future<void> unblockHardwareButtons() async {
    try {
      await _channel.invokeMethod('unblockHardwareButtons');
      print('✅ Hardware buttons unblocked');
    } catch (e) {
      print('❌ Failed to unblock hardware buttons: $e');
    }
  }

  /// Open Android settings to manually configure launcher
  Future<void> openLauncherSettings() async {
    try {
      await _channel.invokeMethod('openLauncherSettings');
      print('📱 Opened launcher settings');
    } catch (e) {
      print('❌ Failed to open launcher settings: $e');
    }
  }

  /// Check if the app is currently the default home app
  Future<bool> isDefaultHomeApp() async {
    try {
      final result = await _channel.invokeMethod('isDefaultHomeApp') ?? false;
      _isHomeAppSet.value = result;
      return result;
    } catch (e) {
      print('❌ Failed to check default home app status: $e');
      return false;
    }
  }

  /// Force set app as home launcher
  Future<bool> forceSetAsHomeLauncher() async {
    try {
      final result = await _channel.invokeMethod('forceSetAsHomeApp') ?? false;
      if (result) {
        _isHomeAppSet.value = true;
        print('✅ Forced app as home launcher');
      }
      return result;
    } catch (e) {
      print('❌ Failed to force set as home launcher: $e');
      return false;
    }
  }

  /// Clear default launcher preference
  Future<bool> clearDefaultLauncher() async {
    try {
      final result =
          await _channel.invokeMethod('clearDefaultLauncher') ?? false;
      if (result) {
        print('✅ Cleared default launcher preference');
      }
      return result;
    } catch (e) {
      print('❌ Failed to clear default launcher: $e');
      return false;
    }
  }

  /// Check if task lock (screen pinning) is active
  Future<bool> isTaskLocked() async {
    try {
      final result = await _channel.invokeMethod('isTaskLocked') ?? false;
      return result;
    } catch (e) {
      print('❌ Failed to check task lock status: $e');
      return false;
    }
  }

  /// Enable task lock (screen pinning)
  Future<bool> enableTaskLock() async {
    try {
      final result = await _channel.invokeMethod('enableTaskLock') ?? false;
      if (result) {
        print('✅ Task lock (screen pinning) enabled');
      }
      return result;
    } catch (e) {
      print('❌ Failed to enable task lock: $e');
      return false;
    }
  }

  /// Disable task lock (screen pinning)
  Future<bool> disableTaskLock() async {
    try {
      final result = await _channel.invokeMethod('disableTaskLock') ?? false;
      if (result) {
        print('✅ Task lock (screen pinning) disabled');
      }
      return result;
    } catch (e) {
      print('❌ Failed to disable task lock: $e');
      return false;
    }
  }

  /// Prevent app from being uninstalled (requires device admin)
  Future<bool> preventAppUninstall() async {
    try {
      final result =
          await _channel.invokeMethod('preventAppUninstall') ?? false;
      if (result) {
        print('✅ App uninstall blocked');
      } else {
        print('❌ Device admin permission required to block app uninstall');
      }
      return result;
    } catch (e) {
      print('❌ Failed to prevent app uninstall: $e');
      return false;
    }
  }

  /// Allow app to be uninstalled (requires device admin)
  Future<bool> allowAppUninstall() async {
    try {
      final result = await _channel.invokeMethod('allowAppUninstall') ?? false;
      if (result) {
        print('✅ App uninstall allowed');
      }
      return result;
    } catch (e) {
      print('❌ Failed to allow app uninstall: $e');
      return false;
    }
  }

  /// Reboot the device (requires device admin)
  Future<bool> rebootDevice() async {
    try {
      final result = await _channel.invokeMethod('rebootDevice') ?? false;
      if (result) {
        print('✅ Device reboot initiated');
      } else {
        print('❌ Device admin permission required to reboot device');
      }
      return result;
    } catch (e) {
      print('❌ Failed to reboot device: $e');
      return false;
    }
  }

  /// Lock the device immediately (requires device admin)
  Future<bool> lockDevice() async {
    try {
      final result = await _channel.invokeMethod('lockDevice') ?? false;
      if (result) {
        print('✅ Device locked');
      } else {
        print('❌ Device admin permission required to lock device');
      }
      return result;
    } catch (e) {
      print('❌ Failed to lock device: $e');
      return false;
    }
  }

  /// Get comprehensive kiosk status
  Future<Map<String, bool>> getKioskStatus() async {
    try {
      final isKioskActive =
          await _channel.invokeMethod('isKioskModeActive') ?? false;
      final isHomeApp =
          await _channel.invokeMethod('isDefaultHomeApp') ?? false;
      final hasDeviceAdmin =
          await _channel.invokeMethod('hasDeviceAdminPermission') ?? false;
      final isTaskLocked = await _channel.invokeMethod('isTaskLocked') ?? false;

      return {
        'isKioskActive': isKioskActive,
        'isHomeApp': isHomeApp,
        'hasDeviceAdmin': hasDeviceAdmin,
        'isTaskLocked': isTaskLocked,
      };
    } catch (e) {
      print('❌ Failed to get kiosk status: $e');
      return {
        'isKioskActive': false,
        'isHomeApp': false,
        'hasDeviceAdmin': false,
        'isTaskLocked': false,
      };
    }
  }
}
