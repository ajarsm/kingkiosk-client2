// lib/notification_system/widgets/notification_item.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/notification_models.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final Function(String) onMarkAsRead;
  final Function(String) onRemove;
  final bool isDesktop;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onMarkAsRead,
    required this.onRemove,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMd().add_jm();

    return isDesktop
        ? _buildDesktopItem(context, formatter)
        : _buildMobileItem(context, formatter);
  }

  Widget _buildDesktopItem(BuildContext context, DateFormat formatter) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.transparent,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => onMarkAsRead(notification.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(isSmall: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildContent(context),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(notification.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRemove(notification.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileItem(BuildContext context, DateFormat formatter) {
    return InkWell(
      onTap: () => onMarkAsRead(notification.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(isSmall: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildContent(context),
                  const SizedBox(height: 6),
                  Text(
                    formatter.format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              padding: const EdgeInsets.all(12),
              onPressed: () => onRemove(notification.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (notification.isHtml) {
      // Basic HTML rendering with only essential parameters
      return Html(
        data: notification.message,
        onAnchorTap: (url, _, __) {
          if (url != null) {
            launchUrlString(url);
          }
        },
      );
    } else {
      return Text(
        notification.message,
        style: TextStyle(fontSize: isDesktop ? 14 : 15),
      );
    }
  }

  Widget _buildThumbnail({required bool isSmall}) {
    final double size = isSmall ? 40 : 48;

    if (notification.thumbnail == null) {
      // Default icon based on priority
      IconData iconData;
      Color iconColor;

      switch (notification.priority) {
        case NotificationPriority.high:
          iconData = Icons.priority_high;
          iconColor = Colors.red;
          break;
        case NotificationPriority.normal:
          iconData = Icons.notifications;
          iconColor = Colors.blue;
          break;
        case NotificationPriority.low:
          iconData = Icons.info_outline;
          iconColor = Colors.grey;
          break;
      }

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor, size: isSmall ? 20 : 24),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildThumbnailImage(),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    final thumbnail = notification.thumbnail!;

    switch (thumbnail.type) {
      case NotificationThumbnailType.network:
        return Image.network(
          thumbnail.source,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, _) =>
              const Icon(Icons.broken_image, color: Colors.grey),
          loadingBuilder: (ctx, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        );

      case NotificationThumbnailType.asset:
        return Image.asset(
          thumbnail.source,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, _) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );

      case NotificationThumbnailType.file:
        return Image.file(
          File(thumbnail.source),
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, _) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
    }
  }
}
