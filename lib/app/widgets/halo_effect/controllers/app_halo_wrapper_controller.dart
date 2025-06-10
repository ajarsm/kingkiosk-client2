import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/halo_effect_controller.dart';

class AppHaloWrapperController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> pulseAnimation;

  final HaloEffectControllerGetx haloController;
  final RxBool hasPreviouslyEnabled = false.obs;

  AppHaloWrapperController({required this.haloController});

  @override
  void onInit() {
    super.onInit();

    // Create animation controller with default duration
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Default value
    );

    // Setup initial animation
    _setupPulseAnimation();

    // Listen for controller changes
    ever(haloController.enabled, _handleEnabledChange);
    ever(haloController.pulseMode, _handlePulseModeChange);
    ever(haloController.pulseDuration, _handleDurationChange);

    // Start animation if needed
    _checkAnimationState();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void _handleEnabledChange(bool enabled) {
    _checkAnimationState();
  }

  void _handlePulseModeChange(HaloPulseMode pulseMode) {
    _setupPulseAnimation();
    _checkAnimationState();
  }

  void _handleDurationChange(Duration duration) {
    animationController.duration = duration;
    _checkAnimationState();
  }

  void _setupPulseAnimation() {
    try {
      // Get intensity with safe fallback (default to 0.7 if there are issues)
      double intensity = haloController.intensity.value;
      if (intensity.isNaN || intensity < 0 || intensity > 1.0) {
        print('⚠️ Invalid intensity value: $intensity, using default 0.7');
        intensity = 0.7;
      }

      final pulseMode = haloController.pulseMode.value;

      // Calculate minimum opacity based on pulse mode with safe calculation
      double pulseMin = pulseMode == HaloPulseMode.none
          ? intensity
          : intensity * _getPulseMinFactor(pulseMode);

      // Ensure pulseMin is valid (avoid NaN or negative values)
      if (pulseMin.isNaN || pulseMin < 0) {
        print('⚠️ Invalid pulseMin value: $pulseMin, using half of intensity');
        pulseMin = intensity * 0.5;
      }

      // Create the pulse animation with safe values
      pulseAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: intensity, end: pulseMin),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: pulseMin, end: intensity),
          weight: 50,
        ),
      ]).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ));

      // Update animation duration with validation
      Duration pulseDuration = haloController.pulseDuration.value;
      if (pulseDuration.inMilliseconds < 100) {
        print(
            '⚠️ Pulse duration too short: ${pulseDuration.inMilliseconds}ms, using default 2000ms');
        pulseDuration = const Duration(milliseconds: 2000);
      } else if (pulseDuration.inMilliseconds > 10000) {
        print(
            '⚠️ Pulse duration too long: ${pulseDuration.inMilliseconds}ms, using maximum 10000ms');
        pulseDuration = const Duration(milliseconds: 10000);
      }

      animationController.duration = pulseDuration;
      print(
          '✅ Pulse animation setup complete: intensity=$intensity, pulseMin=$pulseMin, duration=${pulseDuration.inMilliseconds}ms');
    } catch (e) {
      print('❌ Error setting up pulse animation: $e');
      // Create a default animation as fallback
      pulseAnimation =
          Tween<double>(begin: 0.5, end: 0.7).animate(animationController);
      animationController.duration = const Duration(milliseconds: 2000);
    }
  }

  double _getPulseMinFactor(HaloPulseMode mode) {
    switch (mode) {
      case HaloPulseMode.gentle:
        return 0.7; // 30% reduction at minimum
      case HaloPulseMode.moderate:
        return 0.5; // 50% reduction at minimum
      case HaloPulseMode.alert:
        return 0.3; // 70% reduction at minimum
      case HaloPulseMode.none:
      default:
        return 1.0; // No reduction
    }
  }

  void _checkAnimationState() {
    if (!haloController.enabled.value) {
      // Disabled - stop and reset animation
      if (animationController.isAnimating) {
        animationController.stop();
        animationController.reset();
        print('🔄 Animation stopped (halo disabled)');
      }
      hasPreviouslyEnabled.value = false;
      return;
    }

    // Enabled
    final pulseMode = haloController.pulseMode.value;

    if (pulseMode == HaloPulseMode.none) {
      // No pulsing - stop animation and use static intensity
      if (animationController.isAnimating) {
        animationController.stop();
        animationController.reset();
        print('🔄 Animation stopped (pulse mode: none)');
      }
    } else {
      // Pulsing enabled - start or restart animation
      if (!animationController.isAnimating) {
        animationController.repeat();
        print('🔄 Animation started (pulse mode: $pulseMode)');
      }
    }

    hasPreviouslyEnabled.value = true;
  }
}
