import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../services/notification_system.dart';

/// Controller for auto-hiding toolbar to replace StatefulWidget state management
class AutoHidingToolbarController extends GetxController {
  // Reactive state for toolbar visibility
  final isVisible = true.obs;

  Timer? _hideTimer;
  late final NotificationService _notificationService;

  @override
  void onInit() {
    super.onInit();
    _notificationService = Get.find<NotificationService>();
    _setupNotificationListener();
  }

  @override
  void onClose() {
    _hideTimer?.cancel();
    super.onClose();
  }

  /// Setup notification center listener for reactive updates
  void _setupNotificationListener() {
    _notificationService.notificationCenterVisibilityStream
        .listen((bool isOpen) {
      if (isOpen && !isVisible.value) {
        // If notification center opens but toolbar is hidden, show the toolbar
        showToolbar();
      }
    });
  }

  /// Show the toolbar reactively
  void showToolbar() {
    isVisible.value = true; // Reactive update instead of setState
    _startHideTimer();
  }

  /// Hide the toolbar reactively
  void hideToolbar() {
    // When hiding toolbar, also close notification center if it's open
    if (_notificationService.isNotificationCenterOpen) {
      _notificationService.toggleNotificationCenter();
    }
    isVisible.value = false; // Reactive update instead of setState
  }

  /// Start the auto-hide timer
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 6), () {
      hideToolbar();
    });
  }

  /// Cancel the hide timer
  void cancelHideTimer() {
    _hideTimer?.cancel();
  }
}
