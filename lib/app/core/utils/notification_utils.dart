import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utility class for showing notifications and messages in the app
class NotificationUtils {
  /// Shows a snackbar with the given message
  static void showSnackbar({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 3),
    SnackStyle snackStyle = SnackStyle.FLOATING,
  }) {
    // Only show if GetX is initialized and context exists
    if (Get.isRegistered<BuildContext>() && Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        duration: duration,
        snackStyle: snackStyle,
      );
    } else {
      // Fallback to print if context is not available
      print('NOTIFICATION: $title - $message');
    }
  }

  /// Shows a success snackbar
  static void showSuccess({
    String title = 'Success',
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Only show if GetX is initialized and context exists
    if (Get.isRegistered<BuildContext>() && Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } else {
      // Fallback to print if context is not available
      print('SUCCESS: $title - $message');
    }
  }

  /// Shows an error snackbar
  static void showError({
    String title = 'Error',
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Only show if GetX is initialized and context exists
    if (Get.isRegistered<BuildContext>() && Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } else {
      // Fallback to print if context is not available
      print('ERROR: $title - $message');
    }
  }

  /// Shows a warning snackbar
  static void showWarning({
    String title = 'Warning',
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Only show if GetX is initialized and context exists
    if (Get.isRegistered<BuildContext>() && Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
    } else {
      // Fallback to print if context is not available
      print('WARNING: $title - $message');
    }
  }

  /// Shows an info snackbar
  static void showInfo({
    String title = 'Information',
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Only show if GetX is initialized and context exists
    if (Get.isRegistered<BuildContext>() && Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.info, color: Colors.white),
      );
    } else {
      // Fallback to print if context is not available
      print('INFO: $title - $message');
    }
  }
}