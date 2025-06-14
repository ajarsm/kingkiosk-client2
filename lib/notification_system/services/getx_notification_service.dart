// lib/notification_system/services/getx_notification_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:media_kit/media_kit.dart';
import '../models/notification_models.dart';
import '../utils/html_sanitizer.dart';
import '../utils/platform_helper.dart';
import '../widgets/notification_toast.dart';
import 'notification_service.dart';
import '../../app/core/utils/audio_utils.dart';
import '../../app/services/audio_service.dart';
import '../../app/services/storage_service.dart';

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
  // Storage keys - using prefixed keys to avoid conflicts in shared storage
  static const String _notificationsKey = 'notification_system_notifications';
  static const String _configKey = 'notification_system_config';

  // Storage instance - use the unified storage service
  StorageService get _storage => Get.find<StorageService>();

  // Constructor with optional initialization
  GetXNotificationService() {
    // Initialize counts
    _updateUnreadCount();

    // Load saved data if available
    loadFromStorage();
  }
  // Static initialization method - call this before using the service
  static Future<void> init() async {
    // Storage is handled by the unified StorageService

    // Make sure AudioService is initialized before notifications arrive
    try {
      if (!Get.isRegistered<AudioService>()) {
        print('Initializing AudioService during notification system startup');
        final audioService = AudioService();
        await audioService.init();
        Get.put(audioService);
      } else {
        print('AudioService already registered');
      }

      // Pre-load notification sound to ensure it works when needed
      await AudioService.playNotification();
    } catch (e) {
      print(
          'Warning: Could not initialize AudioService during notification system startup: $e');
    }
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
  Future<void> addNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationThumbnail? thumbnail,
    bool isHtml = false,
  }) async {
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
      print('📢 Playing notification sound for new notification');

      // Use enhanced audio compatibility layer
      await AudioPlayerCompat.playNotification();
    } catch (e) {
      print('⚠️ Error playing notification sound: $e');

      // Try direct static method as backup with more logging
      try {
        print(
            '📢 Trying backup notification sound via AudioService.playNotification()');
        await AudioService.playNotification();
        print('✅ Backup notification sound succeeded');
      } catch (e2) {
        print('❌ Backup notification sound also failed: $e2');
        print('📢 Creating one-time player as final attempt');

        // One final attempt with direct player creation
        try {
          // Create a Player instance directly from media_kit
          final player = Player();
          try {
            await player.open(Media('asset:///assets/sounds/notification.wav'));
            await player.play();
            print('✅ Final attempt notification sound succeeded');

            // Dispose after a delay
            Future.delayed(Duration(seconds: 2), () {
              player.dispose();
            });
          } catch (e3) {
            print('❌ All notification sound methods failed: $e3');
            player.dispose();
          }
        } catch (e3) {
          print('❌ Failed to create player: $e3');
        }
      }
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

  // Persistence methods using StorageService
  @override
  Future<void> loadFromStorage() async {
    try {
      // Load configuration
      final configData = _storage.read<Map<String, dynamic>>(_configKey);
      if (configData != null) {
        _config.value = NotificationConfig(
          tier: NotificationTier.values[configData['tier']],
          maxNotifications: configData['maxNotifications'],
        );
      }

      // Load notifications
      final notificationsData = _storage.read<List<dynamic>>(_notificationsKey);
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
