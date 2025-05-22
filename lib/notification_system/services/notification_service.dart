// lib/notification_system/services/notification_service.dart

import '../models/notification_models.dart';
import '../models/notification_config.dart';

abstract class NotificationService {
  // Streams for reactive updates
  Stream<List<AppNotification>> get notificationsStream;
  Stream<int> get unreadCountStream;
  Stream<bool> get notificationCenterVisibilityStream;
  Stream<NotificationConfig> get configStream;

  // Getters for simpler widget access
  List<AppNotification> get notifications;
  int get unreadCount;
  bool get isNotificationCenterOpen;
  NotificationConfig get config;

  // Methods for adding and managing notifications
  Future<void> addNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationThumbnail? thumbnail,
    bool isHtml = false,
  });

  // Methods for notification actions
  void markAsRead(String id);
  void markAllAsRead();
  void removeNotification(String id);
  void clearAll();
  void toggleNotificationCenter();

  // Methods for configuration management
  void setTier(NotificationTier tier);
  void setMaxNotifications(int maxNotifications);

  // Optional: Methods for persistence (can be implemented in concrete classes)
  Future<void> loadFromStorage();
  Future<void> saveToStorage();
}
