// lib/notification_system/services/alert_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_models.dart';
import '../widgets/alert_dialog.dart';

/// Service for managing positioned alerts
class AlertService extends GetxController {
  final RxBool _isAlertVisible = false.obs;
  final Rx<AppNotification?> _currentAlert = Rx<AppNotification?>(null);

  // Getters
  bool get isAlertVisible => _isAlertVisible.value;
  AppNotification? get currentAlert => _currentAlert.value;
  /// Show a positioned alert
  void showAlert({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.low,
    NotificationThumbnail? thumbnail,
    bool isHtml = false,
    String position = 'center',
    bool showBorder = true,
    Color? borderColor,
    int? autoDismissSeconds,
  }) {
    // Create alert notification
    final alert = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      priority: priority,
      thumbnail: thumbnail,
      isHtml: isHtml,
    );    _currentAlert.value = alert;
    _isAlertVisible.value = true;

    print('🎯 [AlertService] Showing alert at position: "$position"');
      // Create the alert widget
    Widget alertWidget = AlertDialogWidget(
      notification: alert,
      onDismiss: hideAlert,
      showBorder: showBorder,
      borderColor: borderColor,
      autoDismissSeconds: autoDismissSeconds,
    );

    // Show the positioned alert using Get.dialog with proper positioning
    Get.dialog(
      _buildPositionedAlert(alertWidget, position),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  /// Hide the current alert
  void hideAlert() {
    _isAlertVisible.value = false;
    _currentAlert.value = null;
    
    // Close any open dialog
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
  /// Build a positioned alert widget
  Widget _buildPositionedAlert(Widget alertWidget, String position) {
    print('🎯 [AlertService] Building alert at position: "$position"');
    
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: _getPositionedChild(alertWidget, position),
      ),
    );
  }

  /// Get the positioned child widget based on position
  Widget _getPositionedChild(Widget alertWidget, String position) {
    const double padding = 20.0;
    
    switch (position.toLowerCase()) {
      case 'top-left':
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'top-right':
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'top-center':
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'bottom-left':
        return Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'bottom-right':
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'bottom-center':
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'center-left':
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'center-right':
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: alertWidget,
          ),
        );
      case 'center':
      default:
        return Center(child: alertWidget);
    }
  }
}
