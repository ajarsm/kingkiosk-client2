import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:window_manager/window_manager.dart';

/// Windows-specific kiosk mode service
/// Handles fullscreen mode, taskbar hiding, and system restrictions
class WindowsKioskService extends GetxService {
  static const MethodChannel _channel = MethodChannel(
    'com.ki.king_kiosk/windows_kiosk',
  );

  late final GetStorage _storage;
  static const String _kioskStateKey = 'windows_kiosk_enabled';

  final RxBool _isKioskModeActive = false.obs;
  final RxBool _isFullscreen = false.obs;
  final RxBool _isTaskbarHidden = false.obs;

  bool get isKioskModeActive => _isKioskModeActive.value;
  bool get isFullscreen => _isFullscreen.value;
  bool get isTaskbarHidden => _isTaskbarHidden.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (Platform.isWindows) {
      await _initializeStorage();
      await _autoRestoreKioskState();
    }
  }

  Future<void> _initializeStorage() async {
    _storage = GetStorage('windows_kiosk_service');
    await _storage.initStorage;
  }

  /// Enable Windows kiosk mode
  Future<bool> enableKioskMode() async {
    if (!Platform.isWindows) return false;

    try {
      // 1. Set fullscreen mode
      await windowManager.setFullScreen(true);
      await windowManager.setAlwaysOnTop(true);

      // 2. Hide taskbar (requires native implementation)
      await _channel.invokeMethod('hideTaskbar');

      // 3. Block Alt+Tab and other keyboard shortcuts
      await _channel.invokeMethod('blockKeyboardShortcuts');

      // 4. Disable Task Manager
      await _channel.invokeMethod('disableTaskManager');

      _isKioskModeActive.value = true;
      _isFullscreen.value = true;
      _isTaskbarHidden.value = true;

      await _storage.write(_kioskStateKey, true);

      return true;
    } catch (e) {
      print('Failed to enable Windows kiosk mode: $e');
      return false;
    }
  }

  /// Disable Windows kiosk mode
  Future<bool> disableKioskMode() async {
    if (!Platform.isWindows) return false;

    try {
      // 1. Exit fullscreen
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);

      // 2. Show taskbar
      await _channel.invokeMethod('showTaskbar');

      // 3. Unblock keyboard shortcuts
      await _channel.invokeMethod('unblockKeyboardShortcuts');

      // 4. Enable Task Manager
      await _channel.invokeMethod('enableTaskManager');

      _isKioskModeActive.value = false;
      _isFullscreen.value = false;
      _isTaskbarHidden.value = false;

      await _storage.write(_kioskStateKey, false);

      return true;
    } catch (e) {
      print('Failed to disable Windows kiosk mode: $e');
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
