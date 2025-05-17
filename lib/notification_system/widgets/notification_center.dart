// lib/notification_system/widgets/notification_center.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_config.dart'; // For NotificationTier enum

import '../services/notification_service.dart';
import '../utils/platform_helper.dart';
import 'notification_item.dart';

class NotificationCenter extends StatelessWidget {
  const NotificationCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();
    final isDesktop = PlatformHelper.isDesktopScreen(context);

    return Obx(() {
      if (!notificationService.isNotificationCenterOpen) {
        return const SizedBox.shrink();
      }

      return Material(
        elevation: 8,
        color: Theme.of(context).cardColor,
        borderRadius: isDesktop
            ? const BorderRadius.only(
                topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
            : null,
        child: Container(
          // Responsive width - narrower on desktop, full width on small mobile
          width: isDesktop
              ? 380
              : MediaQuery.of(context).size.width > 450
                  ? 380
                  : MediaQuery.of(context).size.width * 0.95,
          // Responsive height - full height on mobile, limited on desktop
          height: isDesktop
              ? MediaQuery.of(context).size.height * 0.7
              : MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Flexible(
                    child: _buildActionButtons(
                        context, notificationService, isDesktop),
                  ),
                ],
              ),
              _buildTierInfoBanner(context, notificationService),
              const Divider(),
              Expanded(
                child: _buildNotificationList(notificationService, isDesktop),
              ),
            ],
          ),
        ),
      );
    });
  }

  // This method was missing or not correctly defined
  Widget _buildActionButtons(
      BuildContext context, NotificationService service, bool isDesktop) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      children: [
        if (isDesktop) ...[
          // Desktop - show full buttons
          TextButton.icon(
            onPressed: service.markAllAsRead,
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Mark all read'),
          ),
          TextButton.icon(
            onPressed: service.clearAll,
            icon: const Icon(Icons.delete_sweep_outlined, size: 16),
            label: const Text('Clear all'),
          ),
        ] else ...[
          // Mobile - show icon buttons only to save space
          IconButton(
            iconSize: 20,
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Mark all as read',
            onPressed: service.markAllAsRead,
          ),
          IconButton(
            iconSize: 20,
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: service.clearAll,
          ),
        ],
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          icon: const Icon(Icons.close),
          onPressed: service.toggleNotificationCenter,
        ),
      ],
    );
  }

  Widget _buildTierInfoBanner(
      BuildContext context, NotificationService service) {
    return Obx(() {
      final config = service.config;

      // Don't show banner for unlimited tier
      if (config.tier == NotificationTier.unlimited) {
        return const SizedBox.shrink();
      }

      final currentCount = service.notifications.length;
      final maxCount = config.maxNotifications;
      final isAtLimit = currentCount >= maxCount;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isAtLimit
              ? Colors.amber.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isAtLimit ? Colors.amber : Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAtLimit ? Icons.warning_amber : Icons.info_outline,
              size: 16,
              color: isAtLimit ? Colors.amber[800] : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAtLimit
                    ? 'You\'ve reached the limit of $maxCount notifications (${_getTierName(config.tier)} tier)'
                    : 'Showing $currentCount of $maxCount notifications (${_getTierName(config.tier)} tier)',
                style: TextStyle(
                  fontSize: 12,
                  color: isAtLimit ? Colors.amber[800] : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getTierName(NotificationTier tier) {
    switch (tier) {
      case NotificationTier.basic:
        return 'Basic';
      case NotificationTier.standard:
        return 'Standard';
      case NotificationTier.premium:
        return 'Premium';
      case NotificationTier.unlimited:
        return 'Unlimited';
    }
  }

  Widget _buildNotificationList(NotificationService service, bool isDesktop) {
    return Obx(() {
      final notifications = service.notifications;

      if (notifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text('No notifications'),
            ],
          ),
        );
      }

      // Sort by priority and then by timestamp (newest first)
      final sortedNotifications = notifications.toList()
        ..sort((a, b) {
          final priorityComparison =
              b.priority.index.compareTo(a.priority.index);
          if (priorityComparison != 0) return priorityComparison;
          return b.timestamp.compareTo(a.timestamp);
        });

      return ListView.separated(
        itemCount: sortedNotifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = sortedNotifications[index];

          return NotificationItem(
            notification: notification,
            onMarkAsRead: service.markAsRead,
            onRemove: service.removeNotification,
            isDesktop: isDesktop,
          );
        },
      );
    });
  }
}
