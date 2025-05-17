// lib/notification_system/widgets/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/notification_service.dart';

/// A notification badge that shows the number of unread notifications
/// and opens the notification center when tapped.
class NotificationBadge extends StatelessWidget {
  final Color? badgeColor;
  final Color? textColor;
  final double size;

  const NotificationBadge({
    Key? key,
    this.badgeColor,
    this.textColor,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();
    final defaultBadgeColor = Theme.of(context).colorScheme.error;
    final defaultTextColor = Theme.of(context).colorScheme.onError;

    return Obx(() {
      // Get the current unread count
      final unreadCount = notificationService.unreadCount;

      return IconButton(
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(
            unreadCount > 99 ? '99+' : unreadCount.toString(),
            style: TextStyle(
              fontSize: 10,
              color: textColor ?? defaultTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: badgeColor ?? defaultBadgeColor,
          child: Icon(
            Icons.notifications_outlined,
            size: size,
          ),
        ),
        onPressed: () => notificationService.toggleNotificationCenter(),
        tooltip: 'Notifications',
      );
    });
  }
}
