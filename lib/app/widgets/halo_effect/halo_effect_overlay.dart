import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Defines the intensity of the pulsing animation for the halo effect
enum HaloPulseMode {
  none, // No pulsing animation
  gentle, // Subtle breathing effect
  moderate, // More noticeable pulsing
  alert // Attention-grabbing rapid pulse
}

/// Controller for the Halo Effect properties and animation settings
class HaloEffectController {
  // Core properties
  final Color color;
  final double width;
  final double intensity;

  // Animation properties
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final HaloPulseMode pulseMode;
  final Duration pulseDuration;

  const HaloEffectController({
    required this.color,
    this.width = 60.0,
    this.intensity = 0.7,
    this.fadeInDuration = const Duration(milliseconds: 800),
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.pulseMode = HaloPulseMode.none,
    this.pulseDuration = const Duration(milliseconds: 2000),
  });
}

/// A widget that displays an animated halo effect around its child
class AnimatedHaloEffect extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final HaloEffectController controller;

  const AnimatedHaloEffect({
    Key? key,
    required this.child,
    required this.enabled,
    required this.controller,
  }) : super(key: key);

  @override
  State<AnimatedHaloEffect> createState() => _AnimatedHaloEffectState();
}

class _AnimatedHaloEffectState extends State<AnimatedHaloEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Create the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: widget.controller.pulseDuration,
    );

    // Setup the initial animations
    _setupAnimations();

    // Start animations if enabled
    if (widget.enabled) {
      _startAnimations();
    }
  }

  void _setupAnimations() {
    try {
      // Use safe intensity value (default to 0.7 if there are issues)
      final safeIntensity =
          widget.controller.intensity.isNaN ? 0.7 : widget.controller.intensity;

      // Basic fade animation
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: safeIntensity,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ));

      // Pulse animation based on mode
      double pulseMin = widget.controller.pulseMode == HaloPulseMode.none
          ? safeIntensity
          : safeIntensity * _getPulseMinFactor();

      _pulseAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: safeIntensity, end: pulseMin),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: pulseMin, end: safeIntensity),
          weight: 50,
        ),
      ]).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      print('✅ Animations setup successfully for HaloEffect');
    } catch (e) {
      print('❌ Error setting up animations for HaloEffect: $e');

      // Set default animations in case of error
      _fadeAnimation =
          Tween<double>(begin: 0.0, end: 0.7).animate(_animationController);
      _pulseAnimation =
          Tween<double>(begin: 0.5, end: 0.7).animate(_animationController);
    }
  }

  double _getPulseMinFactor() {
    switch (widget.controller.pulseMode) {
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

  void _startAnimations() {
    if (!mounted) return;

    try {
      // Reset controller state first to avoid issues
      if (_animationController.status == AnimationStatus.forward ||
          _animationController.status == AnimationStatus.completed) {
        _animationController.reset();
      }

      // Ensure the controller has a valid duration
      if (_animationController.duration == null ||
          _animationController.duration!.inMilliseconds < 100) {
        print('⚠️ Animation duration too short, adjusting to 1000ms');
        _animationController.duration = const Duration(milliseconds: 1000);
      }

      // Different behaviors based on pulse mode
      if (widget.controller.pulseMode != HaloPulseMode.none) {
        // For pulse animations, first ensure the controller is reset
        _animationController.value = 0.0;
        // Then start repeating animation
        _animationController.repeat();
        print(
            '🌟 Starting repeating pulse animation: ${widget.controller.pulseMode}');
        print(
            '🌟 Pulse duration: ${_animationController.duration!.inMilliseconds}ms');
      } else {
        // For non-pulsing, simply forward once
        _animationController.forward();
        print('🌟 Starting forward animation (non-pulsing)');
      }
    } catch (e) {
      print('❌ Error starting animations: $e');
      // Try a simpler animation as fallback
      try {
        _animationController.reset();
        _animationController.forward();
      } catch (e2) {
        print('💥 Critical animation error: $e2');
      }
    }
  }

  void _stopAnimations() {
    if (!mounted) return;

    try {
      // Handle stopping more gracefully
      if (_animationController.isAnimating) {
        _animationController.stop();
      }

      if (_animationController.value > 0) {
        _animationController.reverse();
        print('🌟 Reversing animation to remove halo effect');
      }
    } catch (e) {
      print('❌ Error stopping animations: $e');
    }
  }

  @override
  void didUpdateWidget(AnimatedHaloEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    try {
      // Handle changes in enabled state
      if (widget.enabled != oldWidget.enabled) {
        print('🌟 HaloEffect enabled state changed: ${widget.enabled}');
        if (widget.enabled) {
          _startAnimations();
        } else {
          _stopAnimations();
        }
      }

      // Check if any controller properties have changed
      bool controllerChanged = widget.controller.pulseDuration !=
              oldWidget.controller.pulseDuration ||
          widget.controller.pulseMode != oldWidget.controller.pulseMode ||
          widget.controller.color != oldWidget.controller.color ||
          widget.controller.intensity != oldWidget.controller.intensity ||
          widget.controller.width != oldWidget.controller.width;

      if (controllerChanged) {
        print(
            '🌟 HaloEffect controller properties changed, updating animations');
        print(
            '   - Color: #${widget.controller.color.value.toRadixString(16).toUpperCase()}');
        print('   - Pulse Mode: ${widget.controller.pulseMode}');
        print(
            '   - Pulse Duration: ${widget.controller.pulseDuration.inMilliseconds}ms');

        // Check if pulse mode or duration has changed
        bool pulseModeChanged =
            widget.controller.pulseMode != oldWidget.controller.pulseMode;
        bool durationChanged = widget.controller.pulseDuration !=
            oldWidget.controller.pulseDuration;

        // Always stop current animation to avoid conflicts
        if (_animationController.isAnimating) {
          _animationController.stop();
        }

        if (pulseModeChanged || durationChanged) {
          // Update animation duration
          _animationController.duration = widget.controller.pulseDuration;
        }

        // Reset and rebuild animations
        _setupAnimations();

        // Restart animations if enabled
        if (widget.enabled) {
          _startAnimations();
        }
      }
    } catch (e) {
      print('❌ Error in didUpdateWidget for HaloEffect: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Protection against widget being disposed
    if (!mounted) return widget.child;

    // Use safe durations in case the controller is not fully initialized
    final Duration fadeInDuration = widget.controller.fadeInDuration;
    final Duration fadeOutDuration = widget.controller.fadeOutDuration;

    return AnimatedSwitcher(
      duration: widget.enabled ? fadeInDuration : fadeOutDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: widget.enabled
          ? Stack(
              key: const ValueKey('halo_active'),
              alignment: Alignment.center, // Use non-directional alignment
              textDirection:
                  TextDirection.ltr, // Explicitly provide text direction
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HaloEffectPainter(
                        color: widget.controller.color,
                        width: widget.controller.width,
                        opacity:
                            widget.controller.pulseMode != HaloPulseMode.none
                                ? _pulseAnimation.value
                                : _fadeAnimation.value,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : widget.child,
    );
  }
}

/// Custom painter for rendering the halo effect gradient
class HaloEffectPainter extends CustomPainter {
  final Color color;
  final double width;
  final double opacity;

  HaloEffectPainter({
    required this.color,
    required this.width,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // Early return if size is invalid
      if (size.isEmpty || size.width <= 0 || size.height <= 0) {
        print('⚠️ Invalid size in HaloEffectPainter: $size');
        return;
      }

      // Ensure valid parameters with fallbacks
      final safeColor = color == Colors.transparent ? Colors.red : color;

      // Validate opacity is within range
      final safeOpacity =
          opacity.isNaN || opacity < 0 || opacity > 1 ? 0.7 : opacity;

      // Validate width is positive and reasonable
      final safeWidth =
          width.isNaN || width <= 0 ? 60.0 : (width > 200 ? 200.0 : width);

      // Calculate safe width based on canvas dimensions
      final double effectiveWidth =
          math.min(safeWidth, math.min(size.width, size.height) / 2);

      final adjustedColor = safeColor.withOpacity(safeOpacity);

      // Top edge gradient
      final topGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [adjustedColor, Colors.transparent],
        stops: const [0.0, 1.0],
      );

      // Right edge gradient
      final rightGradient = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [adjustedColor, Colors.transparent],
        stops: const [0.0, 1.0],
      );

      // Bottom edge gradient
      final bottomGradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [adjustedColor, Colors.transparent],
        stops: const [0.0, 1.0],
      );

      // Left edge gradient
      final leftGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [adjustedColor, Colors.transparent],
        stops: const [0.0, 1.0],
      );

      // Draw top edge
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, width),
        Paint()
          ..shader =
              topGradient.createShader(Rect.fromLTWH(0, 0, size.width, width)),
      );

      // Draw right edge
      canvas.drawRect(
        Rect.fromLTWH(size.width - width, 0, width, size.height),
        Paint()
          ..shader = rightGradient.createShader(
              Rect.fromLTWH(size.width - width, 0, width, size.height)),
      );

      // Draw bottom edge
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - width, size.width, width),
        Paint()
          ..shader = bottomGradient.createShader(
              Rect.fromLTWH(0, size.height - width, size.width, width)),
      );

      // Draw left edge
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, size.height),
        Paint()
          ..shader = leftGradient
              .createShader(Rect.fromLTWH(0, 0, width, size.height)),
      );

      // Add corner blending for smoother appearance
      try {
        _paintCorners(canvas, size, adjustedColor);
      } catch (e) {
        print('⚠️ Error painting halo effect corners: $e');
        // No need to rethrow, we'll continue without corners if there's an error
      }
    } catch (e) {
      print('❌ Error painting halo effect: $e');
      // If painting fails completely, paint a simple red border as fallback
      _paintEmergencyFallback(canvas, size);
    }
  }

  /// Emergency fallback to ensure at least something is drawn if main painting fails
  void _paintEmergencyFallback(Canvas canvas, Size size) {
    try {
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0;

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } catch (e) {
      // At this point, we've done all we can
      print('💥 Critical error in halo effect emergency fallback: $e');
    }
  }

  void _paintCorners(Canvas canvas, Size size, Color color) {
    try {
      // Ensure valid parameters for corner painting
      if (width <= 0 || width.isNaN || size.isEmpty) {
        print('⚠️ Invalid parameters for corner painting, skipping corners');
        return;
      }

      // Use a modified color with slightly reduced opacity to better blend with edges
      final cornerColor = color.withOpacity(color.opacity * 0.85);

      // Calculate the optimal corner radius (less than width to avoid sharp visible edges)
      final cornerRadius = width * 0.9;

      // Draw the four corners using arcs instead of rectangles with gradients
      // This creates a smoother blend between the horizontal and vertical edges
      final paint = Paint()
        ..color = cornerColor
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width / 3);

      // Top-left corner
      final topLeftPath = Path()
        ..moveTo(0, cornerRadius)
        ..arcTo(Rect.fromLTWH(0, 0, cornerRadius * 2, cornerRadius * 2),
            math.pi, math.pi / 2, false)
        ..lineTo(0, 0)
        ..close();
      canvas.drawPath(topLeftPath, paint);

      // Top-right corner
      final topRightPath = Path()
        ..moveTo(size.width - cornerRadius, 0)
        ..arcTo(
            Rect.fromLTWH(size.width - cornerRadius * 2, 0, cornerRadius * 2,
                cornerRadius * 2),
            math.pi * 3 / 2,
            math.pi / 2,
            false)
        ..lineTo(size.width, 0)
        ..close();
      canvas.drawPath(topRightPath, paint);

      // Bottom-right corner
      final bottomRightPath = Path()
        ..moveTo(size.width, size.height - cornerRadius)
        ..arcTo(
            Rect.fromLTWH(
                size.width - cornerRadius * 2,
                size.height - cornerRadius * 2,
                cornerRadius * 2,
                cornerRadius * 2),
            0,
            math.pi / 2,
            false)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(bottomRightPath, paint);

      // Bottom-left corner
      final bottomLeftPath = Path()
        ..moveTo(cornerRadius, size.height)
        ..arcTo(
            Rect.fromLTWH(0, size.height - cornerRadius * 2, cornerRadius * 2,
                cornerRadius * 2),
            math.pi / 2,
            math.pi / 2,
            false)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(bottomLeftPath, paint);
    } catch (e) {
      print('⚠️ Error painting corners in halo effect: $e');
      // If corner painting fails, continue without corners
    }
  }

  @override
  bool shouldRepaint(covariant HaloEffectPainter oldDelegate) {
    try {
      return oldDelegate.color != color ||
          oldDelegate.width != width ||
          oldDelegate.opacity != opacity;
    } catch (e) {
      print('⚠️ Error in shouldRepaint: $e');
      return true; // When in doubt, repaint
    }
  }
}
