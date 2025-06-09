import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/clock_window_controller.dart';

/// Clock widget that displays either analog or digital clocks with MQTT configuration support
class ClockWidget extends StatelessWidget {
  final String windowId;
  final bool showControls;
  final VoidCallback? onClose;

  const ClockWidget({
    Key? key,
    required this.windowId,
    this.showControls = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to get existing controller first, create if not found
    ClockWindowController controller;
    try {
      controller = Get.find<ClockWindowController>(tag: windowId);
    } catch (e) {
      // Controller not found, create a new one
      controller = Get.put(
        ClockWindowController(windowName: windowId),
        tag: windowId,
      );
    }

    return Obx(() {
      if (!controller.isVisible) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Window title bar with controls
            if (showControls) _buildTitleBar(context, controller),

            // Clock content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _buildClockContent(context, controller),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTitleBar(
      BuildContext context, ClockWindowController controller) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Window title
          Expanded(
            child: Text(
              'Clock - $windowId',
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Mode toggle button
          IconButton(
            onPressed: controller.toggleMode,
            icon: Icon(
              controller.clockMode == ClockMode.analog
                  ? Icons.access_time
                  : Icons.schedule,
              size: 18,
            ),
            tooltip: controller.clockMode == ClockMode.analog
                ? 'Switch to Digital'
                : 'Switch to Analog',
          ),

          // Minimize button
          IconButton(
            onPressed: controller.minimize,
            icon: const Icon(Icons.minimize, size: 18),
            tooltip: 'Minimize',
          ),

          // Close button
          IconButton(
            onPressed: onClose ?? controller.close,
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildClockContent(
      BuildContext context, ClockWindowController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: controller.clockMode == ClockMode.analog
          ? _buildAnalogClock(context, controller, isDark)
          : _buildDigitalClock(context, controller, isDark),
    );
  }

  Widget _buildAnalogClock(
      BuildContext context, ClockWindowController controller, bool isDark) {
    return Obx(() {
      // Get network image URL from controller configuration
      final imageUrl = controller.networkImageUrl;

      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate the size based on available space with safe bounds
          final maxWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
          final maxHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;

          // Use the smaller dimension for a square clock
          double availableSize = (maxWidth < maxHeight ? maxWidth : maxHeight);

          // Ensure we have reasonable bounds
          if (!availableSize.isFinite || availableSize <= 0) {
            availableSize = 200.0;
          }

          // Scale clock size based on available space with reasonable limits
          double clockSize;
          if (availableSize <= 400) {
            // Small containers: use most of the space
            clockSize = availableSize * 0.9;
          } else if (availableSize <= 800) {
            // Medium containers: scale proportionally but cap growth
            clockSize = 400 + (availableSize - 400) * 0.5;
          } else {
            // Large containers (fullscreen): cap at reasonable size
            clockSize = 600.0; // Max size for very large screens
          }

          // Apply final bounds check
          clockSize = clockSize.clamp(100.0, 800.0);

          return Center(
            child: SizedBox(
              width: clockSize,
              height: clockSize,
              child: _buildAnalogClockWidget(
                  imageUrl, isDark, controller, clockSize),
            ),
          );
        },
      );
    });
  }

  Widget _buildDigitalClock(
      BuildContext context, ClockWindowController controller, bool isDark) {
    return Obx(() {
      // Get network image URL from controller configuration
      final imageUrl = controller.networkImageUrl;

      return Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: (imageUrl != null && imageUrl.isNotEmpty)
              ? Colors.transparent
              : (isDark ? Colors.black : Colors.white),
          border: Border.all(
            width: 2.0,
            color: isDark ? Colors.white : Colors.black,
          ),
          borderRadius: BorderRadius.circular(8),
          image: (imageUrl != null && imageUrl.isNotEmpty)
              ? DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: StreamBuilder<DateTime>(
          stream: Stream.periodic(
              const Duration(seconds: 1), (_) => DateTime.now()),
          builder: (context, snapshot) {
            final now = snapshot.data ?? DateTime.now();
            final timeString =
                "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
            return Center(
              child: Text(
                timeString,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildAnalogClockWidget(String? imageUrl, bool isDark,
      ClockWindowController controller, double clockSize) {
    try {
      final bool hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;

      // Create the AnimatedAnalogClock with conditional parameters
      if (hasImageUrl) {
        return AnimatedAnalogClock(
          // Set explicit size for proper scaling
          size: clockSize,
          // Use background image only
          backgroundImage: CachedNetworkImageProvider(imageUrl),
          hourHandColor: isDark ? Colors.lightBlueAccent : Colors.blue,
          minuteHandColor: isDark ? Colors.lightBlueAccent : Colors.blue,
          secondHandColor: controller.showSecondHand
              ? (isDark ? Colors.amber : Colors.red)
              : Colors.transparent,
          centerDotColor: isDark ? Colors.amber : Colors.red,
          hourDashColor: isDark ? Colors.lightBlue : Colors.black,
          minuteDashColor: isDark ? Colors.blueAccent : Colors.grey,
          numberColor: isDark ? Colors.white : Colors.black,
          // Dial type based on showNumbers setting
          dialType: controller.showNumbers ? DialType.numbers : DialType.dashes,
          // Extend hands for better visibility on larger clocks
          extendHourHand: true,
          extendMinuteHand: true,
          extendSecondHand: true,
        );
      } else {
        return AnimatedAnalogClock(
          // Set explicit size for proper scaling
          size: clockSize,
          // Use background color only
          backgroundColor: isDark ? const Color(0xff1E1E26) : Colors.white,
          hourHandColor: isDark ? Colors.lightBlueAccent : Colors.blue,
          minuteHandColor: isDark ? Colors.lightBlueAccent : Colors.blue,
          secondHandColor: controller.showSecondHand
              ? (isDark ? Colors.amber : Colors.red)
              : Colors.transparent,
          centerDotColor: isDark ? Colors.amber : Colors.red,
          hourDashColor: isDark ? Colors.lightBlue : Colors.black,
          minuteDashColor: isDark ? Colors.blueAccent : Colors.grey,
          numberColor: isDark ? Colors.white : Colors.black,
          // Dial type based on showNumbers setting
          dialType: controller.showNumbers ? DialType.numbers : DialType.dashes,
          // Extend hands for better visibility on larger clocks
          extendHourHand: true,
          extendMinuteHand: true,
          extendSecondHand: true,
        );
      }
    } catch (e) {
      // Fallback to a simple error widget if AnimatedAnalogClock fails
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 40,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 8),
              Text(
                'Clock Error',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
              Text(
                'Tap mode button to switch',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
