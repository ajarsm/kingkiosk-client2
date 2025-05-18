// lib/notification_system/widgets/translucent_notification_indicator.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/notification_service.dart';

/// A translucent notification indicator that appears in the upper right corner
/// of the screen only when there are unread notifications.
/// 
/// Designed to be minimally intrusive for kiosk applications.
class TranslucentNotificationIndicator extends StatefulWidget {
  /// The opacity level of the indicator (0.0 to 1.0)
  final double opacity;
  
  /// The size of the indicator
  final double size;
  
  /// The padding from the edge of the screen
  final EdgeInsets padding;
  
  /// Custom color for the indicator
  final Color? color;
  
  /// Animation duration for fade in/out
  final Duration animationDuration;
  
  const TranslucentNotificationIndicator({
    Key? key,
    this.opacity = 0.35,
    this.size = 24.0,
    this.padding = const EdgeInsets.only(top: 16.0, right: 16.0),
    this.color,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  State<TranslucentNotificationIndicator> createState() => _TranslucentNotificationIndicatorState();
}

class _TranslucentNotificationIndicatorState extends State<TranslucentNotificationIndicator> with SingleTickerProviderStateMixin {
  NotificationService? _notificationService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final _currentOpacity = 0.0.obs;  // Convert to observable
  final _hasShown = false.obs;      // Convert to observable
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Create a pulsing effect that goes from 0.85 to 1.15 and back
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Make the animation repeat
    _pulseController.repeat(reverse: true);
    
    // Try to find the notification service
    try {
      _notificationService = Get.find<NotificationService>();
    } catch (e) {
      print('TranslucentNotificationIndicator: NotificationService not found');
    }
      // Start with opacity 0 and fade in when notifications appear
    _currentOpacity.value = 0.0;
    
    // Check for notifications after initialization
    Future.delayed(Duration.zero, () {
      if (_notificationService != null && _notificationService!.unreadCount > 0) {
        // Use reactive approach instead of setState
        _currentOpacity.value = widget.opacity;
        _hasShown.value = true;
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    
        if (_notificationService == null) {
      return const SizedBox.shrink();
    }
    
    // Get the theme color or use provided color
    final defaultColor = Theme.of(context).colorScheme.primary;
    final indicatorColor = widget.color ?? defaultColor;
    
    return Positioned(
      top: widget.padding.top,
      right: widget.padding.right,
      child: Obx(() {
        // Get the current unread count
        final unreadCount = _notificationService!.unreadCount;
        
        // Only show the indicator if there are unread notifications
        if (unreadCount <= 0) {
          return const SizedBox.shrink();
        }          // If we have notifications and haven't shown yet, fade in
        if (unreadCount > 0 && !_hasShown.value) {
          // Use GetX reactive approach instead of setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _currentOpacity.value = widget.opacity;
              _hasShown.value = true;
            }
          });
        }
        
        return GestureDetector(
          onTap: () => _notificationService!.toggleNotificationCenter(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {              return AnimatedOpacity(
                opacity: _currentOpacity.value,
                duration: widget.animationDuration,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: indicatorColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.size * 0.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
