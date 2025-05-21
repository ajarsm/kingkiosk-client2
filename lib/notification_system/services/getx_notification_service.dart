// lib/notification_system/services/getx_notification_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_models.dart';
import '../models/notification_config.dart';
import '../utils/html_sanitizer.dart';
import '../utils/platform_helper.dart';
import '../widgets/notification_toast.dart';
import 'notification_service.dart';
import '../../app/core/utils/audio_utils.dart';

class GetXNotificationService extends GetxController
    implements NotificationService {
  static GetXNotificationService get instance =>
      Get.find<NotificationService>() as GetXNotificationService;

  // Reactive state variables
  final RxList<AppNotification> _notifications = <AppNotification>[].obs;
  final RxBool _isNotificationCenterOpen = false.obs;
  final RxInt _unreadCount = 0.obs;
  final Rx<NotificationConfig> _config =
      NotificationConfig.forTier(NotificationTier.standard).obs;

  // Storage keys
  static const String _storageBox = 'notificationSystem';
  static const String _notificationsKey = 'notifications';
  static const String _configKey = 'config';

  // Storage instance
  final _storage = GetStorage(_storageBox);

  // Constructor with optional initialization
  GetXNotificationService() {
    // Initialize counts
    _updateUnreadCount();

    // Load saved data if available
    loadFromStorage();
  }

  // Static initialization method - call this before using the service
  static Future<void> init() async {
    await GetStorage.init(_storageBox);
  }

  // Stream getters
  @override
  Stream<List<AppNotification>> get notificationsStream =>
      _notifications.stream;

  @override
  Stream<int> get unreadCountStream => _unreadCount.stream;

  @override
  Stream<bool> get notificationCenterVisibilityStream =>
      _isNotificationCenterOpen.stream;

  @override
  Stream<NotificationConfig> get configStream => _config.stream;

  // Regular getters
  @override
  List<AppNotification> get notifications => _notifications;

  @override
  int get unreadCount => _unreadCount.value;

  @override
  bool get isNotificationCenterOpen => _isNotificationCenterOpen.value;

  @override
  NotificationConfig get config => _config.value;

  // Configuration methods
  @override
  void setTier(NotificationTier tier) {
    final newConfig = NotificationConfig.forTier(tier);
    _config.value = newConfig;
    _enforceHistoryLimit();
    saveToStorage();
  }

  @override
  void setMaxNotifications(int maxNotifications) {
    // Custom limit (not tied to a specific tier)
    _config.value = _config.value.copyWith(
      tier: NotificationTier.standard, // Default to standard for custom limits
      maxNotifications: maxNotifications,
    );
    _enforceHistoryLimit();
    saveToStorage();
  }

  // Notification management methods
  @override
  void addNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationThumbnail? thumbnail,
    bool isHtml = false,
  }) {
    // Sanitize HTML if needed
    final sanitizedMessage = isHtml ? HtmlSanitizer.sanitize(message) : message;

    final notification = AppNotification(
      id: const Uuid().v4(),
      title: title,
      message: sanitizedMessage,
      timestamp: DateTime.now(),
      priority: priority,
      thumbnail: thumbnail,
      isHtml: isHtml,
    );

    // Add to the list
    _notifications.add(notification);

    // Play notification sound
    try {
      // Use AudioPlayerCompat to play notification sound (just_audio, cached)
      AudioPlayerCompat.playNotification();
    } catch (e) {
      print('Error playing notification sound: $e');
    }

    // Enforce the history limit
    _enforceHistoryLimit();

    // Update unread count
    _updateUnreadCount();

    // Show a toast notification
    _showToast(notification);

    // Save to storage
    saveToStorage();
  }

  @override
  void markAsRead(String id) {
    final index =
        _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _notifications.refresh(); // Trigger UI update
      _updateUnreadCount();
      saveToStorage();
    }
  }

  @override
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _notifications.refresh();
    _updateUnreadCount();
    saveToStorage();
  }

  @override
  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    _updateUnreadCount();
    saveToStorage();
  }

  @override
  void clearAll() {
    _notifications.clear();
    _updateUnreadCount();
    saveToStorage();
  }

  @override
  void toggleNotificationCenter() {
    _isNotificationCenterOpen.value = !_isNotificationCenterOpen.value;
  }

  // Persistence methods using GetStorage
  @override
  Future<void> loadFromStorage() async {
    try {
      // Load configuration
      final configData = _storage.read(_configKey);
      if (configData != null) {
        final configMap = Map<String, dynamic>.from(configData);
        _config.value = NotificationConfig(
          tier: NotificationTier.values[configMap['tier']],
          maxNotifications: configMap['maxNotifications'],
        );
      }

      // Load notifications
      final notificationsData = _storage.read(_notificationsKey);
      if (notificationsData != null) {
        final notificationsList =
            List<Map<String, dynamic>>.from(notificationsData);
        _notifications.value = notificationsList
            .map((map) => AppNotification.fromMap(map))
            .toList();

        // Enforce limit on load
        _enforceHistoryLimit();

        // Update unread count
        _updateUnreadCount();
      }
    } catch (e) {
      print('Error loading notification data: $e');
    }
  }

  @override
  Future<void> saveToStorage() async {
    try {
      // Save configuration
      final configMap = {
        'tier': _config.value.tier.index,
        'maxNotifications': _config.value.maxNotifications,
      };
      _storage.write(_configKey, configMap);

      // Save notifications
      final notificationsList = _notifications.map((n) => n.toMap()).toList();
      _storage.write(_notificationsKey, notificationsList);
    } catch (e) {
      print('Error saving notification data: $e');
    }
  }

  // Internal helper methods
  void _updateUnreadCount() {
    _unreadCount.value =
        _notifications.where((notification) => !notification.isRead).length;
  }

  void _enforceHistoryLimit() {
    if (_config.value.isLimited) {
      final maxAllowed = _config.value.maxNotifications;

      if (_notifications.length > maxAllowed) {
        // Sort by timestamp (newest first) before trimming
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Keep only the most recent n notifications
        _notifications.value = _notifications.take(maxAllowed).toList();
      }
    }
  }

  void _showToast(AppNotification notification) {
    // Determine if desktop based on screen width
    final isDesktop = PlatformHelper.isDesktop;

    final customContent = NotificationToast(
      notification: notification,
      onTap: () {
        markAsRead(notification.id);
        toggleNotificationCenter();
        Get.closeCurrentSnackbar();
      },
      isDesktop: isDesktop,
    );

    Get.rawSnackbar(
      duration: const Duration(seconds: 3),
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: Colors.transparent,
      messageText: customContent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.only(
        top: isDesktop ? 16 : 8,
        right: isDesktop ? 16 : 8,
        left: isDesktop ? Get.width - 352 : 8, // Position from right on desktop
      ),
      borderRadius: 8,
      snackPosition: SnackPosition.TOP,
    );
  }
}
