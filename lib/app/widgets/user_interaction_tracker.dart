import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/settings/controllers/settings_controller.dart';

/// Wrapper widget that tracks user interactions for auto-lock functionality
class UserInteractionTracker extends StatelessWidget {
  final Widget child;

  const UserInteractionTracker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (_) => _recordInteraction(),
      onTap: _recordInteraction,
      onTapDown: (_) => _recordInteraction(),
      onLongPress: _recordInteraction,
      onDoubleTap: _recordInteraction,
      child: Listener(
        onPointerDown: (_) => _recordInteraction(),
        onPointerMove: (_) => _recordInteraction(),
        onPointerUp: (_) => _recordInteraction(),
        child: child,
      ),
    );
  }

  void _recordInteraction() {
    if (Get.isRegistered<SettingsController>()) {
      final settingsController = Get.find<SettingsController>();
      settingsController.recordUserInteraction();
    }
  }
}
