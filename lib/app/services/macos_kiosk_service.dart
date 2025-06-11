import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'storage_service.dart';

/// macOS-specific kiosk mode service
/// Handles fullscreen mode, dock/menu hiding, and system restrictions
class MacOSKioskService extends GetxService {
  static const MethodChannel _channel = MethodChannel(
    'com.ki.king_kiosk/macos_kiosk',
  );

  late final StorageService _storage;
  static const String _kioskStateKey = 'macos_kiosk_enabled';

  final RxBool _isKioskModeActive = false.obs;
  final RxBool _isFullscreen = false.obs;
  final RxBool _isDockHidden = false.obs;
  final RxBool _isMenuBarHidden = false.obs;

  bool get isKioskModeActive => _isKioskModeActive.value;
  bool get isFullscreen => _isFullscreen.value;
  bool get isDockHidden => _isDockHidden.value;
  bool get isMenuBarHidden => _isMenuBarHidden.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (Platform.isMacOS) {
      await _initializeStorage();
      await _autoRestoreKioskState();
    }
  }

  Future<void> _initializeStorage() async {
    _storage = Get.find<StorageService>();
  }

  /// Enable macOS kiosk mode
  Future<bool> enableKioskMode() async {
    if (!Platform.isMacOS) return false;

    try {
      // 1. Set fullscreen mode
      await windowManager.setFullScreen(true);
      await windowManager.setAlwaysOnTop(true);

      // 2. Hide dock and menu bar (requires native implementation)
      await _channel.invokeMethod('hideDockAndMenuBar');

      // 3. Block Command+Tab and other shortcuts
      await _channel.invokeMethod('blockKeyboardShortcuts');

      // 4. Disable Force Quit dialog
      await _channel.invokeMethod('disableForceQuit');

      // 5. Hide cursor (optional)
      await _channel.invokeMethod('hideCursor');

      _isKioskModeActive.value = true;
      _isFullscreen.value = true;
      _isDockHidden.value = true;
      _isMenuBarHidden.value = true;

      _storage.write(_kioskStateKey, true);

      return true;
    } catch (e) {
      print('Failed to enable macOS kiosk mode: $e');
      return false;
    }
  }

  /// Disable macOS kiosk mode
  Future<bool> disableKioskMode() async {
    if (!Platform.isMacOS) return false;

    try {
      // 1. Exit fullscreen
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);

      // 2. Show dock and menu bar
      await _channel.invokeMethod('showDockAndMenuBar');

      // 3. Unblock keyboard shortcuts
      await _channel.invokeMethod('unblockKeyboardShortcuts');

      // 4. Enable Force Quit dialog
      await _channel.invokeMethod('enableForceQuit');

      // 5. Show cursor
      await _channel.invokeMethod('showCursor');

      _isKioskModeActive.value = false;
      _isFullscreen.value = false;
      _isDockHidden.value = false;
      _isMenuBarHidden.value = false;

      _storage.write(_kioskStateKey, false);

      return true;
    } catch (e) {
      print('Failed to disable macOS kiosk mode: $e');
      return false;
    }
  }

  Future<void> _autoRestoreKioskState() async {
    final wasKioskEnabled = _storage.read(_kioskStateKey) ?? false;
    if (wasKioskEnabled) {
      await enableKioskMode();
    }
  }
}
