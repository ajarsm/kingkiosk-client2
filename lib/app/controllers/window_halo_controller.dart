import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/halo_effect/halo_effect_overlay.dart';
import '../controllers/halo_effect_controller.dart';

/// Controller for managing per-window Halo Effects
/// Similar to HaloEffectControllerGetx but includes window ID management
class WindowHaloController extends GetxController {
  // Map of window IDs to their halo effect controllers
  final _windowControllers = <String, HaloEffectControllerGetx>{}.obs;

  // Main app halo controller (for backward compatibility)
  final _mainController = Get.find<HaloEffectControllerGetx>();

  @override
  void onInit() {
    super.onInit();
    print('💫 WindowHaloController initialized');
  }

  /// Get the halo controller for a specific window
  /// Creates a new controller if one doesn't exist
  HaloEffectControllerGetx getControllerForWindow(String windowId) {
    if (!_windowControllers.containsKey(windowId)) {
      print('💫 Creating new halo controller for window: $windowId');
      final controller = HaloEffectControllerGetx();
      _windowControllers[windowId] = controller;
    }
    return _windowControllers[windowId]!;
  }

  /// Check if a window has an active halo effect
  bool hasActiveHalo(String windowId) {
    return _windowControllers.containsKey(windowId) &&
        _windowControllers[windowId]!.enabled.value;
  }

  /// Enable halo effect for a specific window
  void enableHaloForWindow({
    required String windowId,
    required Color color,
    double? width,
    double? intensity,
    HaloPulseMode? pulseMode,
    Duration? pulseDuration,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
  }) {
    final controller = getControllerForWindow(windowId);
    controller.enableHaloEffect(
      color: color,
      width: width,
      intensity: intensity,
      pulseMode: pulseMode,
      pulseDuration: pulseDuration,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
    print(
        '💫 Enabled halo effect for window: $windowId with color: ${_colorToHex(color)}');
  }

  /// Disable halo effect for a specific window
  void disableHaloForWindow(String windowId) {
    if (_windowControllers.containsKey(windowId)) {
      _windowControllers[windowId]!.disableHaloEffect();
      print('💫 Disabled halo effect for window: $windowId');
    }
  }

  /// Enable halo effect for the main application (backward compatibility)
  void enableMainHalo({
    required Color color,
    double? width,
    double? intensity,
    HaloPulseMode? pulseMode,
    Duration? pulseDuration,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
  }) {
    _mainController.enableHaloEffect(
      color: color,
      width: width,
      intensity: intensity,
      pulseMode: pulseMode,
      pulseDuration: pulseDuration,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
    print('💫 Enabled main halo effect with color: ${_colorToHex(color)}');
  }

  /// Disable halo effect for the main application
  void disableMainHalo() {
    _mainController.disableHaloEffect();
    print('💫 Disabled main halo effect');
  }

  /// Clean up controller for a window when it's closed
  void removeWindow(String windowId) {
    if (_windowControllers.containsKey(windowId)) {
      _windowControllers.remove(windowId);
      print('💫 Removed halo controller for window: $windowId');
    }
  }

  /// Get all window IDs with active halo effects
  List<String> getActiveHaloWindows() {
    return _windowControllers.keys
        .where((id) => _windowControllers[id]!.enabled.value)
        .toList();
  }

  /// Helper method to convert color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
