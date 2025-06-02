// lib/app/services/mqtt_notification_handler.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../notification_system/notification_system.dart';
import '../../../notification_system/services/alert_service.dart';

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

  /// Process an alert command from MQTT to show a center-screen alert
  static void processAlertCommand(Map<dynamic, dynamic> cmdObj) {
    try {
      final title = cmdObj['title']?.toString() ?? 'Alert';
      final message = cmdObj['message']?.toString();

      if (message == null || message.isEmpty) {
        print('⚠️ alert command missing message content');
        return;
      }      // Get optional parameters
      final typeStr = cmdObj['type']?.toString().toLowerCase() ?? 'info';
      final priorityStr = cmdObj['priority']?.toString().toLowerCase(); 
      final isHtml = cmdObj['is_html'] == true || cmdObj['html'] == true;
      final position = cmdObj['position']?.toString() ?? 'center'; // Default to center
      final showBorder = cmdObj['show_border'] != false; // Default to true, false only if explicitly set
      final borderColorStr = cmdObj['border_color']?.toString();
      
      // Parse auto-dismiss duration if provided
      int? autoDismissSeconds;
      if (cmdObj['auto_dismiss_seconds'] != null) {
        try {
          final rawValue = cmdObj['auto_dismiss_seconds'];
          if (rawValue is int) {
            autoDismissSeconds = rawValue;
          } else if (rawValue is double) {
            autoDismissSeconds = rawValue.toInt();
          } else if (rawValue is String) {
            autoDismissSeconds = int.tryParse(rawValue);
          }
          
          // Validate range (minimum 1 second, maximum 300 seconds)
          if (autoDismissSeconds != null) {
            if (autoDismissSeconds < 1) {
              autoDismissSeconds = 1;
              print('⚠️ auto_dismiss_seconds too small, using minimum of 1 second');
            } else if (autoDismissSeconds > 300) {
              autoDismissSeconds = 300;
              print('⚠️ auto_dismiss_seconds too large, using maximum of 300 seconds');
            }
          }
        } catch (e) {
          print('⚠️ Invalid auto_dismiss_seconds format: ${cmdObj['auto_dismiss_seconds']}, ignoring');
          autoDismissSeconds = null;
        }
      }// Parse priority - prioritize explicit priority, then derive from type
      NotificationPriority priority;
      if (priorityStr != null) {
        // Explicit priority specified
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
      } else {
        // Derive priority from type for better color mapping
        switch (typeStr) {
          case 'error':
            priority = NotificationPriority.high; // Red
            break;
          case 'warning':
            priority = NotificationPriority.normal; // Orange
            break;
          case 'info':
          case 'success':
          default:
            priority = NotificationPriority.low; // Blue
            break;
        }
      }

      // Parse border color if provided
      Color? borderColor;
      if (borderColorStr != null && borderColorStr.isNotEmpty) {
        try {
          // Handle hex colors (with or without #)
          String colorStr = borderColorStr.replaceAll('#', '');
          if (colorStr.length == 6) {
            borderColor = Color(int.parse('FF$colorStr', radix: 16));
          } else if (colorStr.length == 8) {
            borderColor = Color(int.parse(colorStr, radix: 16));
          }
        } catch (e) {
          print('⚠️ Invalid border_color format: $borderColorStr, using default');
        }
      }

      // Handle thumbnail if provided
      NotificationThumbnail? thumbnail;
      if (cmdObj['thumbnail'] != null) {
        final thumbnailUrl = cmdObj['thumbnail'].toString();
        if (thumbnailUrl.isNotEmpty) {
          thumbnail = NotificationThumbnail.network(thumbnailUrl);
        }
      }      // Get the alert service and show the positioned alert
      try {
        final alertService = Get.find<AlertService>();
        alertService.showAlert(
          title: title,
          message: message,
          priority: priority,
          thumbnail: thumbnail,
          isHtml: isHtml,
          position: position,
          showBorder: showBorder,
          borderColor: borderColor,
          autoDismissSeconds: autoDismissSeconds,
        );
        print('🚨 [MQTT] Alert displayed at position "$position": "$title"${autoDismissSeconds != null ? ' (auto-dismiss: ${autoDismissSeconds}s)' : ''}');
      } catch (e) {
        print('❌ Error accessing alert service: $e');
      }
    } catch (e) {
      print('❌ Error processing alert command: $e');
    }
  }
}
