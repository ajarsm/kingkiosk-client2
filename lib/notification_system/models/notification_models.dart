// lib/notification_system/models/notification_models.dart

import 'dart:io';

// Export the notification config models for convenience
export 'notification_config.dart';

enum NotificationPriority { low, normal, high }

class NotificationThumbnail {
  final String source;
  final NotificationThumbnailType type;
  
  const NotificationThumbnail.network(String url) 
    : source = url, 
      type = NotificationThumbnailType.network;
  
  const NotificationThumbnail.asset(String path) 
    : source = path, 
      type = NotificationThumbnailType.asset;
      
  const NotificationThumbnail.file(String path) 
    : source = path, 
      type = NotificationThumbnailType.file;
}

enum NotificationThumbnailType { network, asset, file }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationPriority priority;
  final NotificationThumbnail? thumbnail;
  final bool isHtml;
  bool isRead;
  
  AppNotification({
    required this.id,
    required this.title, 
    required this.message,
    required this.timestamp,
    this.priority = NotificationPriority.normal,
    this.thumbnail,
    this.isHtml = false,
    this.isRead = false,
  });
  
  // Add a method to create a copy with modified fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationPriority? priority,
    NotificationThumbnail? thumbnail,
    bool? isHtml,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      thumbnail: thumbnail ?? this.thumbnail,
      isHtml: isHtml ?? this.isHtml,
      isRead: isRead ?? this.isRead,
    );
  }
  
  // Add a method to convert to Map (useful for storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'priority': priority.index,
      'isHtml': isHtml,
      'isRead': isRead,
      'thumbnail': thumbnail != null ? {
        'source': thumbnail!.source,
        'type': thumbnail!.type.index,
      } : null,
    };
  }
  
  // Add a factory method to create from Map (useful for storage)
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      priority: NotificationPriority.values[map['priority']],
      isHtml: map['isHtml'],
      isRead: map['isRead'],
      thumbnail: map['thumbnail'] != null ? 
        _createThumbnailFromMap(map['thumbnail']) : null,
    );
  }
  
  // Helper method to create thumbnail from map
  static NotificationThumbnail? _createThumbnailFromMap(Map<String, dynamic> map) {
    final type = NotificationThumbnailType.values[map['type']];
    final source = map['source'];
    
    switch (type) {
      case NotificationThumbnailType.network:
        return NotificationThumbnail.network(source);
      case NotificationThumbnailType.asset:
        return NotificationThumbnail.asset(source);
      case NotificationThumbnailType.file:
        return NotificationThumbnail.file(source);
    }
  }
}