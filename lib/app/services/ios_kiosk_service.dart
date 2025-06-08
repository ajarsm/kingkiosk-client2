import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// iOS-specific kiosk mode service
/// Limited to fullscreen and guided access prompts due to iOS security
class IOSKioskService extends GetxService {
  static const MethodChannel _channel = MethodChannel(
    'com.ki.king_kiosk/ios_kiosk',
  );

  late final GetStorage _storage;
  static const String _kioskStateKey = 'ios_kiosk_enabled';

  final RxBool _isKioskModeActive = false.obs;
  final RxBool _isFullscreen = false.obs;
  final RxBool _isStatusBarHidden = false.obs;
  final RxBool _isGuidedAccessPrompted = false.obs;

  bool get isKioskModeActive => _isKioskModeActive.value;
  bool get isFullscreen => _isFullscreen.value;
  bool get isStatusBarHidden => _isStatusBarHidden.value;
  bool get isGuidedAccessPrompted => _isGuidedAccessPrompted.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (Platform.isIOS) {
      await _initializeStorage();
      await _autoRestoreKioskState();
    }
  }

  Future<void> _initializeStorage() async {
    _storage = GetStorage('ios_kiosk_service');
    await _storage.initStorage;
  }

  /// Enable iOS kiosk mode (limited capabilities)
  Future<bool> enableKioskMode() async {
    if (!Platform.isIOS) return false;

    try {
      // 1. Hide status bar
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      // 2. Lock orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // 3. Prompt user to enable Guided Access
      await _channel.invokeMethod('promptGuidedAccess');

      // 4. Disable screenshots (if possible)
      await _channel.invokeMethod('disableScreenshots');

      _isKioskModeActive.value = true;
      _isFullscreen.value = true;
      _isStatusBarHidden.value = true;
      _isGuidedAccessPrompted.value = true;

      await _storage.write(_kioskStateKey, true);

      return true;
    } catch (e) {
      print('Failed to enable iOS kiosk mode: $e');
      return false;
    }
  }

  /// Disable iOS kiosk mode
  Future<bool> disableKioskMode() async {
    if (!Platform.isIOS) return false;

    try {
      // 1. Show status bar
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // 2. Unlock orientation
      await SystemChrome.setPreferredOrientations([]);

      // 3. Enable screenshots
      await _channel.invokeMethod('enableScreenshots');

      _isKioskModeActive.value = false;
      _isFullscreen.value = false;
      _isStatusBarHidden.value = false;
      _isGuidedAccessPrompted.value = false;

      await _storage.write(_kioskStateKey, false);

      return true;
    } catch (e) {
      print('Failed to disable iOS kiosk mode: $e');
      return false;
    }
  }

  /// Show guided access instructions to user
  Future<void> showGuidedAccessInstructions() async {
    Get.dialog(
      AlertDialog(
        title: Text('Enable Guided Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To enable full kiosk mode on iOS:'),
            SizedBox(height: 16),
            Text('1. Triple-click the Home/Side button'),
            Text('2. Select "Guided Access"'),
            Text('3. Set a passcode'),
            Text('4. Tap "Start"'),
            SizedBox(height: 16),
            Text('This will prevent leaving the app.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoRestoreKioskState() async {
    final wasKioskEnabled = _storage.read(_kioskStateKey) ?? false;
    if (wasKioskEnabled) {
      await enableKioskMode();
    }
  }
}
