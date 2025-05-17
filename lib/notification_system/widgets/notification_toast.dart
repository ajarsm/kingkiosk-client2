// lib/notification_system/widgets/notification_toast.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/notification_models.dart';

class NotificationToast extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final bool isDesktop;

  const NotificationToast({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isDesktop
            ? 320
            : MediaQuery.of(context).size.width > 450
                ? 320
                : MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (notification.thumbnail != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: isDesktop ? 36 : 40,
                  height: isDesktop ? 36 : 40,
                  child: _buildThumbnailImage(),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildContent(context),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.all(isDesktop ? 4 : 8),
              constraints: BoxConstraints(
                minHeight: isDesktop ? 32 : 40,
                minWidth: isDesktop ? 32 : 40,
              ),
              onPressed: () => Get.closeCurrentSnackbar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (notification.isHtml) {
      return SizedBox(
        width: double.infinity,
        // Minimal HTML rendering with only essential parameters
        child: Html(
          data: notification.message,
          onAnchorTap: (url, _, __) {
            if (url != null) {
              launchUrlString(url);
            }
          },
        ),
      );
    } else {
      return Text(
        notification.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: isDesktop ? 13 : 15),
      );
    }
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
