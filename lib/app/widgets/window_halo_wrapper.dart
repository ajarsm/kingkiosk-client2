import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/window_halo_controller.dart';
import '../controllers/halo_effect_controller.dart';
import 'halo_effect/halo_effect_overlay.dart';

/// A widget that wraps a window tile and applies a halo effect
/// This is used for window-specific halo effects
class WindowHaloWrapper extends StatelessWidget {
  final String windowId;
  final Widget child;

  const WindowHaloWrapper({
    Key? key,
    required this.windowId,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find or register the controller
    WindowHaloController controller;
    if (Get.isRegistered<WindowHaloController>()) {
      controller = Get.find<WindowHaloController>();
    } else {
      controller = WindowHaloController();
      Get.put(controller, permanent: true);
    }

    // Get the specific controller for this window
    final windowController = controller.getControllerForWindow(windowId);

    // Apply the halo effect
    return Stack(
      children: [
        // The child widget (window content)
        child,

        // The halo effect overlay
        Obx(() {
          // Only show the halo effect if enabled for this window
          if (!windowController.enabled.value) {
            return const SizedBox.shrink();
          }

          return AnimatedHaloEffect(
            controller: windowController.currentController,
            enabled: windowController.enabled.value,
            child: const SizedBox.expand(),
          );
        }),
      ],
    );
  }
}
