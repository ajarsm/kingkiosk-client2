import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/halo_effect_controller.dart';
import 'halo_effect_overlay.dart';

/// A specialized wrapper for applying the halo effect to the app
/// This avoids duplicate GlobalKeys by using a different approach than AnimatedHaloEffect
/// while still supporting animations
class AppHaloWrapper extends StatefulWidget {
  final Widget child;
  final HaloEffectControllerGetx controller;

  const AppHaloWrapper({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  State<AppHaloWrapper> createState() => _AppHaloWrapperState();
}

class _AppHaloWrapperState extends State<AppHaloWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _hasPreviouslyEnabled = false;

  @override
  void initState() {
    super.initState();

    // Create animation controller with default duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Default value
    );

    // Setup initial animation
    _setupPulseAnimation();

    // Listen for controller changes
    ever(widget.controller.enabled, _handleEnabledChange);
    ever(widget.controller.pulseMode, _handlePulseModeChange);
    ever(widget.controller.pulseDuration, _handleDurationChange);

    // Start animation if needed
    _checkAnimationState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleEnabledChange(bool enabled) {
    _checkAnimationState();
  }

  void _handlePulseModeChange(HaloPulseMode pulseMode) {
    _setupPulseAnimation();
    _checkAnimationState();
  }

  void _handleDurationChange(Duration duration) {
    _animationController.duration = duration;
    _checkAnimationState();
  }

  void _setupPulseAnimation() {
    try {
      // Get intensity with safe fallback (default to 0.7 if there are issues)
      double intensity = widget.controller.intensity.value;
      if (intensity.isNaN || intensity < 0 || intensity > 1.0) {
        print('⚠️ Invalid intensity value: $intensity, using default 0.7');
        intensity = 0.7;
      }

      final pulseMode = widget.controller.pulseMode.value;

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
      _pulseAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: intensity, end: pulseMin),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: pulseMin, end: intensity),
          weight: 50,
        ),
      ]).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      // Update animation duration with validation
      Duration pulseDuration = widget.controller.pulseDuration.value;
      if (pulseDuration.inMilliseconds < 100) {
        print(
            '⚠️ Pulse duration too short: ${pulseDuration.inMilliseconds}ms, using default 2000ms');
        pulseDuration = const Duration(milliseconds: 2000);
      } else if (pulseDuration.inMilliseconds > 10000) {
        print(
            '⚠️ Pulse duration too long: ${pulseDuration.inMilliseconds}ms, using maximum 10000ms');
        pulseDuration = const Duration(milliseconds: 10000);
      }

      _animationController.duration = pulseDuration;
      print(
          '✅ Pulse animation setup complete: intensity=$intensity, pulseMin=$pulseMin, duration=${pulseDuration.inMilliseconds}ms');
    } catch (e) {
      print('❌ Error setting up pulse animation: $e');
      // Create a default animation as fallback
      _pulseAnimation =
          Tween<double>(begin: 0.5, end: 0.7).animate(_animationController);
      _animationController.duration = const Duration(milliseconds: 2000);
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
    final bool enabled = widget.controller.enabled.value;
    final pulseMode = widget.controller.pulseMode.value;

    if (enabled) {
      // Store that we've been enabled
      _hasPreviouslyEnabled = true;

      // Update the animation duration if it changed
      if (_animationController.duration !=
          widget.controller.pulseDuration.value) {
        _animationController.duration = widget.controller.pulseDuration.value;
      }

      // Start the animation based on pulse mode
      if (pulseMode != HaloPulseMode.none) {
        if (!_animationController.isAnimating) {
          _animationController.repeat();
          print('🌟 Starting repeating pulse animation in AppHaloWrapper');
        }
      } else {
        _animationController.forward();
        print('🌟 Starting forward animation in AppHaloWrapper');
      }
    } else if (_hasPreviouslyEnabled) {
      // Stop animation when disabled
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      try {
        // Get the current halo configuration
        final bool enabled = widget.controller.enabled.value;

        if (!enabled) {
          return widget.child;
        }

        // Get color with safe fallback
        Color color = Colors.red;
        try {
          color = widget.controller.color.value;
        } catch (e) {
          print('⚠️ Error getting color: $e, using default red');
        }

        // Get width with safe fallback (default 60.0)
        double width = 60.0;
        try {
          width = widget.controller.width.value;
          if (width <= 0 || width.isNaN) {
            width = 60.0;
          }
        } catch (e) {
          print('⚠️ Error getting width: $e, using default 60.0');
        }

        // Calculate opacity with safe fallback
        double opacity = 0.7;
        try {
          if (widget.controller.pulseMode.value != HaloPulseMode.none) {
            // Use the animated value for pulse with safety check
            opacity = _pulseAnimation.value.isNaN ? 0.7 : _pulseAnimation.value;
          } else {
            // Static intensity
            opacity = widget.controller.intensity.value;
            if (opacity.isNaN || opacity < 0 || opacity > 1.0) {
              opacity = 0.7;
            }
          }
        } catch (e) {
          print('⚠️ Error calculating opacity: $e, using default 0.7');
        }

        // Apply a Stack with CustomPaint for the halo effect
        return Material(
          // This Material widget doesn't create another Scaffold/ScaffoldMessenger
          type: MaterialType.transparency,
          child: Stack(
            textDirection:
                TextDirection.ltr, // Explicitly provide text direction
            alignment: Alignment.center, // Use non-directional alignment
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: HaloEffectPainter(
                      color: color,
                      width: width,
                      opacity: opacity,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        print('❌ Fatal error in AppHaloWrapper build: $e');
        // Return the child without any halo effect in case of errors
        return widget.child;
      }
    });
  }
}
