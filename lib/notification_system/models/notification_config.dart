// lib/notification_system/models/notification_config.dart

enum NotificationTier {
  basic,    // Only 1 notification
  standard, // Up to 20 notifications
  premium,  // Up to 100 notifications
  unlimited // No limit
}

class NotificationConfig {
  final NotificationTier tier;
  final int maxNotifications;
  
  const NotificationConfig({
    this.tier = NotificationTier.standard,
    this.maxNotifications = 20,
  });
  
  factory NotificationConfig.forTier(NotificationTier tier) {
    switch (tier) {
      case NotificationTier.basic:
        return const NotificationConfig(tier: NotificationTier.basic, maxNotifications: 1);
      case NotificationTier.standard:
        return const NotificationConfig(tier: NotificationTier.standard, maxNotifications: 20);
      case NotificationTier.premium:
        return const NotificationConfig(tier: NotificationTier.premium, maxNotifications: 100);
      case NotificationTier.unlimited:
        return const NotificationConfig(tier: NotificationTier.unlimited, maxNotifications: -1); // -1 means unlimited
    }
  }
  
  bool get isLimited => maxNotifications > 0;
  
  NotificationConfig copyWith({
    NotificationTier? tier,
    int? maxNotifications,
  }) {
    return NotificationConfig(
      tier: tier ?? this.tier,
      maxNotifications: maxNotifications ?? this.maxNotifications,
    );
  }
}