import 'dart:async';
import 'package:get/get.dart';
import '../../../../notification_system/notification_system.dart';

/// Controller for auto-hiding toolbar to replace StatefulWidget state management
class AutoHidingToolbarController extends GetxController {
  // Reactive state for toolbar visibility
  final isVisible = true.obs;

  Timer? _hideTimer;
  late final NotificationService _notificationService;

  @override
  void onInit() {
    super.onInit();
    try {
      _notificationService = Get.find<NotificationService>();
      _setupNotificationListener();
    } catch (e) {
      // Handle case where NotificationService might not be available
      print('Warning: NotificationService not found: $e');
    }
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
    try {
      if (_notificationService.isNotificationCenterOpen) {
        _notificationService.toggleNotificationCenter();
      }
    } catch (e) {
      // Handle case where notification service is not available
      print('Warning: Could not access notification service: $e');
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
