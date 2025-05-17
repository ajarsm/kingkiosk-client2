// lib/app/modules/home/controllers/notification_test_controller.dart

import 'dart:async';
import 'package:get/get.dart';
import 'package:king_kiosk/notification_system/services/notification_service.dart';
import 'package:king_kiosk/notification_system/models/notification_models.dart';

/// A simple controller to test the notification system functionality
class NotificationTestController extends GetxController {
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  Timer? _periodicTestTimer;

  // Demo notification content
  final List<Map<String, dynamic>> _demoNotifications = [
    {
      'title': 'System Information',
      'message': 'System is running normally.',
      'priority': NotificationPriority.low,
    },
    {
      'title': 'New Update Available',
      'message':
          'King Kiosk has an update available. <a href="https://example.com">Click here</a> to learn more.',
      'priority': NotificationPriority.normal,
      'isHtml': true,
    },
    {
      'title': 'Alert: Memory Usage High',
      'message':
          'Memory usage has exceeded 80%. Consider closing some applications.',
      'priority': NotificationPriority.high,
    },
  ];

  /// Sends a single test notification
  void sendTestNotification() {
    final notification =
        _demoNotifications[DateTime.now().second % _demoNotifications.length];

    _notificationService.addNotification(
      title: notification['title'],
      message: notification['message'],
      priority: notification['priority'],
      isHtml: notification['isHtml'] ?? false,
    );
  }

  /// Starts sending periodic test notifications
  void startPeriodicNotifications() {
    stopPeriodicNotifications(); // Stop any existing timer

    // Send an immediate notification
    sendTestNotification();

    // Set up timer to send notifications periodically
    _periodicTestTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      sendTestNotification();
    });
  }

  /// Stops sending periodic test notifications
  void stopPeriodicNotifications() {
    _periodicTestTimer?.cancel();
    _periodicTestTimer = null;
  }

  @override
  void onClose() {
    stopPeriodicNotifications();
    super.onClose();
  }
}
