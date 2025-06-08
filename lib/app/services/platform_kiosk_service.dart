import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'android_kiosk_service.dart';
import 'windows_kiosk_service.dart';
import 'macos_kiosk_service.dart';
import 'ios_kiosk_service.dart';

/// Unified platform kiosk service
/// Automatically selects the appropriate platform-specific implementation
class PlatformKioskService extends GetxController {
  late final GetxService _platformService;

  // Unified observable states
  final RxBool _isKioskModeActive = false.obs;
  final RxString _platformName = ''.obs;
  final RxInt _controlLevel = 0.obs; // 0-100% control level

  bool get isKioskModeActive => _isKioskModeActive.value;
  String get platformName => _platformName.value;
  int get controlLevel => _controlLevel.value;
  String get controlLevelDescription {
    if (controlLevel >= 90) return 'Total Control';
    if (controlLevel >= 70) return 'High Control';
    if (controlLevel >= 50) return 'Moderate Control';
    if (controlLevel >= 30) return 'Limited Control';
    return 'Minimal Control';
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePlatformService();
  }

  Future<void> _initializePlatformService() async {
    if (Platform.isAndroid) {
      // Use existing AndroidKioskService if registered, otherwise create new one
      if (Get.isRegistered<AndroidKioskService>()) {
        _platformService = Get.find<AndroidKioskService>();
      } else {
        _platformService = AndroidKioskService();
        Get.put(_platformService);
      }
      _platformName.value = 'Android';
      _controlLevel.value = 95;
    } else if (Platform.isWindows) {
      _platformService = WindowsKioskService();
      Get.put(_platformService);
      _platformName.value = 'Windows';
      _controlLevel.value = 80;
    } else if (Platform.isMacOS) {
      _platformService = MacOSKioskService();
      Get.put(_platformService);
      _platformName.value = 'macOS';
      _controlLevel.value = 60;
    } else if (Platform.isIOS) {
      _platformService = IOSKioskService();
      Get.put(_platformService);
      _platformName.value = 'iOS';
      _controlLevel.value = 30;
    } else {
      throw UnsupportedError('Platform not supported for kiosk mode');
    }

    // Initialize the service if it hasn't been initialized
    if (_platformService.initialized == false) {
      _platformService.onInit();
    }

    // Sync states
    _syncKioskState();
  }

  /// Enable kiosk mode on current platform
  Future<bool> enableKioskMode() async {
    bool success = false;

    if (Platform.isAndroid) {
      success =
          await (_platformService as AndroidKioskService).enableKioskMode();
    } else if (Platform.isWindows) {
      success =
          await (_platformService as WindowsKioskService).enableKioskMode();
    } else if (Platform.isMacOS) {
      success = await (_platformService as MacOSKioskService).enableKioskMode();
    } else if (Platform.isIOS) {
      success = await (_platformService as IOSKioskService).enableKioskMode();
    }

    _syncKioskState();
    return success;
  }

  /// Disable kiosk mode on current platform
  Future<bool> disableKioskMode() async {
    bool success = false;

    if (Platform.isAndroid) {
      success =
          await (_platformService as AndroidKioskService).disableKioskMode();
    } else if (Platform.isWindows) {
      success =
          await (_platformService as WindowsKioskService).disableKioskMode();
    } else if (Platform.isMacOS) {
      success =
          await (_platformService as MacOSKioskService).disableKioskMode();
    } else if (Platform.isIOS) {
      success = await (_platformService as IOSKioskService).disableKioskMode();
    }

    _syncKioskState();
    return success;
  }

  /// Get platform-specific capabilities
  Map<String, dynamic> getPlatformCapabilities() {
    if (Platform.isAndroid) {
      return {
        'platform': 'Android',
        'controlLevel': 95,
        'capabilities': [
          'Home launcher replacement',
          'System UI hiding',
          'Hardware button blocking',
          'Device admin policies',
          'App exit prevention',
          'Auto-restore on boot',
          'Remote MQTT control',
        ],
        'limitations': [
          'Requires device admin permissions',
          'May require disabling some security features',
        ],
      };
    } else if (Platform.isWindows) {
      return {
        'platform': 'Windows',
        'controlLevel': 80,
        'capabilities': [
          'Fullscreen mode',
          'Taskbar hiding',
          'Keyboard shortcut blocking',
          'Task Manager disabling',
          'Registry modifications',
          'Shell replacement (admin required)',
        ],
        'limitations': [
          'Requires administrator privileges for full control',
          'Some antivirus may flag system modifications',
          'User can still use Ctrl+Alt+Del',
        ],
      };
    } else if (Platform.isMacOS) {
      return {
        'platform': 'macOS',
        'controlLevel': 60,
        'capabilities': [
          'Fullscreen mode',
          'Dock and menu bar hiding',
          'Limited keyboard shortcut blocking',
          'Cursor hiding',
        ],
        'limitations': [
          'Cannot fully block Command+Q',
          'Force Quit dialog still accessible',
          'System Integrity Protection limits access',
          'User can still access Activity Monitor',
        ],
      };
    } else if (Platform.isIOS) {
      return {
        'platform': 'iOS',
        'controlLevel': 30,
        'capabilities': [
          'Fullscreen mode',
          'Status bar hiding',
          'Orientation locking',
          'Guided Access prompts',
        ],
        'limitations': [
          'Requires manual Guided Access activation',
          'Cannot programmatically block home button',
          'App Store restrictions prevent system access',
          'User must enable restrictions manually',
        ],
      };
    }

    return {
      'platform': 'Unknown',
      'controlLevel': 0,
      'capabilities': [],
      'limitations': []
    };
  }

  /// Show platform-specific setup instructions
  void showSetupInstructions() {
    final capabilities = getPlatformCapabilities();

    Get.dialog(
      AlertDialog(
        title: Text('${capabilities['platform']} Kiosk Mode'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Control Level: ${capabilities['controlLevel']}% (${controlLevelDescription})',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Capabilities:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...((capabilities['capabilities'] as List)
                  .map((cap) => Text('• $cap'))),
              SizedBox(height: 16),
              Text('Limitations:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...((capabilities['limitations'] as List)
                  .map((lim) => Text('• $lim'))),
              if (Platform.isIOS) ...[
                SizedBox(height: 16),
                Text(
                  'iOS Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('1. Triple-click Home/Side button'),
                Text('2. Select "Guided Access"'),
                Text('3. Set a passcode'),
                Text('4. Tap "Start"'),
              ],
            ],
          ),
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

  void _syncKioskState() {
    if (Platform.isAndroid) {
      _isKioskModeActive.value =
          (_platformService as AndroidKioskService).isKioskModeActive;
    } else if (Platform.isWindows) {
      _isKioskModeActive.value =
          (_platformService as WindowsKioskService).isKioskModeActive;
    } else if (Platform.isMacOS) {
      _isKioskModeActive.value =
          (_platformService as MacOSKioskService).isKioskModeActive;
    } else if (Platform.isIOS) {
      _isKioskModeActive.value =
          (_platformService as IOSKioskService).isKioskModeActive;
    }
  }
}
