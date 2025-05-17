// lib/app/services/mqtt_notification_handler.dart

import 'package:get/get.dart';
import '../../../notification_system/notification_system.dart';

/// Helper class to handle MQTT notification commands
class MqttNotificationHandler {
  /// Process a notification command from MQTT
  static void processNotifyCommand(Map<dynamic, dynamic> cmdObj) {
    try {
      final title = cmdObj['title']?.toString() ?? 'MQTT Notification';
      final message = cmdObj['message']?.toString();

      if (message == null || message.isEmpty) {
        print('⚠️ notify command missing message content');
        return;
      }

      // Get optional parameters
      final priorityStr =
          cmdObj['priority']?.toString().toLowerCase() ?? 'normal';
      final isHtml = cmdObj['is_html'] == true || cmdObj['html'] == true;

      // Parse priority
      NotificationPriority priority;
      switch (priorityStr) {
        case 'high':
          priority = NotificationPriority.high;
          break;
        case 'low':
          priority = NotificationPriority.low;
          break;
        default:
          priority = NotificationPriority.normal;
      }

      // Handle thumbnail if provided
      NotificationThumbnail? thumbnail;
      if (cmdObj['thumbnail'] != null) {
        final thumbnailUrl = cmdObj['thumbnail'].toString();
        if (thumbnailUrl.isNotEmpty) {
          thumbnail = NotificationThumbnail.network(thumbnailUrl);
        }
      }

      // Get the notification service and send the notification
      try {
        final notificationService = Get.find<NotificationService>();
        notificationService.addNotification(
          title: title,
          message: message,
          priority: priority,
          thumbnail: thumbnail,
          isHtml: isHtml,
        );
        print('📣 [MQTT] Notification sent: "$title"');
      } catch (e) {
        print('❌ Error accessing notification service: $e');
      }
    } catch (e) {
      print('❌ Error processing notification command: $e');
    }
  }
}
