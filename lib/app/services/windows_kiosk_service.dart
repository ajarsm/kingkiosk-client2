import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'storage_service.dart';

/// Security levels for Windows kiosk mode
enum KioskSecurityLevel { demo, business, enterprise, totalLockdown }

/// Windows-specific kiosk mode service (Simplified version)
/// Provides basic kiosk functionality without complex C++ plugins
/// Focuses on window management and basic restrictions
class WindowsKioskService extends GetxService {
  late final StorageService _storage;
  static const String _kioskStateKey = 'windows_kiosk_enabled';
  static const String _kioskConfigKey = 'windows_kiosk_config';

  // Observable states for basic monitoring
  final RxBool _isKioskModeActive = false.obs;
  final RxBool _isFullscreen = false.obs;
  final RxBool _isAlwaysOnTop = false.obs;
  final RxBool _isRestoring = false.obs;

  // Security level tracking
  final Rx<KioskSecurityLevel> _currentSecurityLevel = KioskSecurityLevel.demo.obs;

  // Getters for state monitoring
  bool get isKioskModeActive => _isKioskModeActive.value;
  bool get isFullscreen => _isFullscreen.value;
  bool get isAlwaysOnTop => _isAlwaysOnTop.value;
  bool get isRestoring => _isRestoring.value;
  KioskSecurityLevel get currentSecurityLevel => _currentSecurityLevel.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (Platform.isWindows) {
      await _initializeStorage();
      await _initializeKioskService();
      await _autoRestoreKioskState();
    }
  }

  /// Initialize storage for persistent state
  Future<void> _initializeStorage() async {
    try {
      _storage = Get.find<StorageService>();
      print('🔒 Windows kiosk storage initialized');
    } catch (e) {
      print('🔒 Failed to initialize Windows kiosk storage: $e');
    }
  }

  /// Initialize Windows kiosk service
  Future<void> _initializeKioskService() async {
    try {
      print('🔒 Initializing Windows kiosk service...');
      
      // Check if window manager is available
      if (await windowManager.isPreventClose()) {
        print('🔒 Window manager is available');
      }
      
      print('✅ Windows kiosk service initialized');
    } catch (e) {
      print('❌ Failed to initialize Windows kiosk service: $e');
    }
  }

  /// Auto-restore kiosk state if enabled
  Future<void> _autoRestoreKioskState() async {
    try {
      final wasKioskEnabled = _storage.read<bool>(_kioskStateKey) ?? false;
      if (wasKioskEnabled) {
        print('🔄 Auto-restoring kiosk state...');
        _isRestoring.value = true;
        await enableKioskMode();
        _isRestoring.value = false;
        print('✅ Kiosk state auto-restored');
      }
    } catch (e) {
      print('❌ Failed to auto-restore kiosk state: $e');
      _isRestoring.value = false;
    }
  }

  /// Enable kiosk mode with specified security level
  Future<bool> enableKioskMode([KioskSecurityLevel level = KioskSecurityLevel.business]) async {
    if (!Platform.isWindows) {
      print('⚠️ Windows kiosk service only works on Windows');
      return false;
    }

    try {
      print('🔒 Enabling Windows kiosk mode (level: $level)...');
      _currentSecurityLevel.value = level;

      bool success = false;
      switch (level) {
        case KioskSecurityLevel.demo:
          success = await _enableDemoMode();
          break;
        case KioskSecurityLevel.business:
          success = await _enableBusinessMode();
          break;
        case KioskSecurityLevel.enterprise:
          success = await _enableEnterpriseMode();
          break;
        case KioskSecurityLevel.totalLockdown:
          success = await _enableTotalLockdownMode();
          break;
      }

      if (success) {
        _isKioskModeActive.value = true;
        await _saveKioskState(true);
        print('✅ Windows kiosk mode enabled successfully');
        
        Get.snackbar(
          'Kiosk Mode Enabled',
          'Windows kiosk mode is now active',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white,
        );
      }

      return success;
    } catch (e) {
      print('❌ Failed to enable Windows kiosk mode: $e');
      Get.snackbar(
        'Kiosk Mode Error',
        'Failed to enable kiosk mode: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Disable kiosk mode
  Future<bool> disableKioskMode() async {
    if (!Platform.isWindows) {
      print('⚠️ Windows kiosk service only works on Windows');
      return false;
    }

    try {
      print('🔓 Disabling Windows kiosk mode...');      bool success = true;
      
      // Restore window to normal state
      final restoreResult = await _restoreWindowState();
      success = success && restoreResult;
      
      if (success) {
        _isKioskModeActive.value = false;
        _isFullscreen.value = false;
        _isAlwaysOnTop.value = false;
        _currentSecurityLevel.value = KioskSecurityLevel.demo;
        await _saveKioskState(false);
        
        print('✅ Windows kiosk mode disabled successfully');
        
        Get.snackbar(
          'Kiosk Mode Disabled',
          'Windows kiosk mode has been disabled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.7),
          colorText: Colors.white,
        );
      }

      return success;
    } catch (e) {
      print('❌ Failed to disable Windows kiosk mode: $e');
      Get.snackbar(
        'Kiosk Mode Error',
        'Failed to disable kiosk mode: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Enable demo mode (basic fullscreen)
  Future<bool> _enableDemoMode() async {
    try {
      await windowManager.setFullScreen(true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setPreventClose(true);
      
      _isFullscreen.value = true;
      _isAlwaysOnTop.value = true;
      
      return true;
    } catch (e) {
      print('❌ Error enabling demo mode: $e');
      return false;
    }
  }

  /// Enable business mode (fullscreen + window restrictions)
  Future<bool> _enableBusinessMode() async {
    try {
      // Demo mode features
      await _enableDemoMode();
      
      // Additional business restrictions
      await windowManager.setSkipTaskbar(true);
      await windowManager.setMinimizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setResizable(false);
      
      return true;
    } catch (e) {
      print('❌ Error enabling business mode: $e');
      return false;
    }
  }

  /// Enable enterprise mode (business + additional security)
  Future<bool> _enableEnterpriseMode() async {
    try {
      // Business mode features
      await _enableBusinessMode();
      
      // Additional enterprise restrictions
      await windowManager.setMovable(false);
      await windowManager.setClosable(false);
      
      return true;
    } catch (e) {
      print('❌ Error enabling enterprise mode: $e');
      return false;
    }
  }

  /// Enable total lockdown mode (maximum security)
  Future<bool> _enableTotalLockdownMode() async {
    try {
      // Enterprise mode features
      await _enableEnterpriseMode();
      
      // Maximum lockdown
      await windowManager.setHasShadow(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      
      print('🔒 Total lockdown mode activated');
      return true;
    } catch (e) {
      print('❌ Error enabling total lockdown mode: $e');
      return false;
    }
  }

  /// Restore window to normal state
  Future<bool> _restoreWindowState() async {
    try {
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setPreventClose(false);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setMinimizable(true);
      await windowManager.setMaximizable(true);
      await windowManager.setResizable(true);
      await windowManager.setMovable(true);
      await windowManager.setClosable(true);
      await windowManager.setHasShadow(true);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      
      return true;
    } catch (e) {
      print('❌ Error restoring window state: $e');
      return false;
    }
  }
  /// Save kiosk state to storage
  Future<void> _saveKioskState(bool enabled) async {
    try {
      _storage.write(_kioskStateKey, enabled);
      _storage.write(_kioskConfigKey, {
        'enabled': enabled,
        'level': _currentSecurityLevel.value.index,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('❌ Failed to save kiosk state: $e');
    }
  }

  /// Emergency disable - force disable all kiosk features
  Future<bool> emergencyDisable() async {
    try {
      print('🚨 Emergency disable activated');
      
      // Force restore window state
      await _restoreWindowState();
      
      // Reset all state
      _isKioskModeActive.value = false;
      _isFullscreen.value = false;
      _isAlwaysOnTop.value = false;
      _currentSecurityLevel.value = KioskSecurityLevel.demo;
        // Clear saved state
      _storage.write(_kioskStateKey, false);
      
      print('✅ Emergency disable completed');
      
      Get.snackbar(
        'Emergency Disable',
        'Kiosk mode has been emergency disabled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.7),
        colorText: Colors.white,
      );
      
      return true;
    } catch (e) {
      print('❌ Emergency disable failed: $e');
      return false;
    }
  }

  /// Check if kiosk mode is supported
  bool isSupported() {
    return Platform.isWindows;
  }

  /// Get kiosk mode status summary
  Map<String, dynamic> getStatusSummary() {
    return {
      'isActive': isKioskModeActive,
      'securityLevel': currentSecurityLevel.toString(),
      'isFullscreen': isFullscreen,
      'isAlwaysOnTop': isAlwaysOnTop,
      'isSupported': isSupported(),
      'platform': Platform.operatingSystem,
    };
  }
}
