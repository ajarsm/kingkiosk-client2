import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/halo_effect/halo_effect_overlay.dart';

/// Controller for managing the Halo Effect state using GetX
class HaloEffectControllerGetx extends GetxController {
  // Observable properties - using Color(0xFFFF0000) instead of Colors.red to avoid MaterialColor issues
  final Rx<Color> color = Color(0xFFFF0000).obs; // Pure red color
  final RxDouble width = 60.0.obs;
  final RxDouble intensity = 0.7.obs;
  final RxBool enabled = false.obs;
  final Rx<HaloPulseMode> pulseMode = HaloPulseMode.none.obs;
  final Rx<Duration> pulseDuration = const Duration(milliseconds: 2000).obs;
  final Rx<Duration> fadeInDuration = const Duration(milliseconds: 800).obs;
  final Rx<Duration> fadeOutDuration = const Duration(milliseconds: 1000).obs;

  // Convenience method to get the current controller state
  HaloEffectController get currentController => HaloEffectController(
        color: color.value,
        width: width.value,
        intensity: intensity.value,
        pulseMode: pulseMode.value,
        pulseDuration: pulseDuration.value,
        fadeInDuration: fadeInDuration.value,
        fadeOutDuration: fadeOutDuration.value,
      );

  /// Enable the halo effect with specific parameters
  void enableHaloEffect({
    required Color color,
    double? width,
    double? intensity,
    HaloPulseMode? pulseMode,
    Duration? pulseDuration,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
  }) {
    try {
      // Get the raw integer color value to avoid type issues
      // This approach works for both MaterialColor and Color
      final int colorValue = color.value;
      final Color safeColor = Color(colorValue);

      // Now we're using a plain Color, not a MaterialColor
      this.color.value = safeColor;

      // Apply other parameters with null checks
      if (width != null) this.width.value = width;
      if (intensity != null) this.intensity.value = intensity;
      if (pulseMode != null) this.pulseMode.value = pulseMode;
      if (pulseDuration != null) this.pulseDuration.value = pulseDuration;
      if (fadeInDuration != null) this.fadeInDuration.value = fadeInDuration;
      if (fadeOutDuration != null) this.fadeOutDuration.value = fadeOutDuration;

      enabled.value = true;

      // Log for debugging
      print(
          '🌟 Halo Effect enabled with color: ${colorToHex(safeColor)}, pulse mode: ${pulseMode?.toString() ?? this.pulseMode.value.toString()}');
    } catch (e) {
      print('❌ Error in enableHaloEffect: $e');
      try {
        // Use fallback values for critical properties as a simpler approach
        this.color.value = Color(0xFFFF0000); // Pure red as fallback
        enabled.value = true;
        print('✅ Applied fallback color in enableHaloEffect');
      } catch (e2) {
        print('💥 Critical error in fallback handling: $e2');
      }
    }
  }

  /// Disable the halo effect
  void disableHaloEffect() {
    print('🌟 Halo Effect disabled');
    enabled.value = false;
  }

  /// Parse a color to hex string
  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Parse a hex string to color
  Color hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    return Color(int.parse('0xFF$hexCode'));
  }
}
