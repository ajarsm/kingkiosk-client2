import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

/// Service to handle navigation throughout the app
class NavigationService extends GetxService {
  // Initialize the service
  NavigationService init() {
    return this;
  }
  
  /// Navigate to a route
  Future<dynamic>? navigateTo(String routeName, {dynamic arguments}) {
    return Get.toNamed(routeName, arguments: arguments);
  }
  
  /// Replace the current route
  Future<dynamic>? replaceTo(String routeName, {dynamic arguments}) {
    return Get.offNamed(routeName, arguments: arguments);
  }
  
  /// Replace all routes with a new route
  Future<dynamic>? replaceAllTo(String routeName, {dynamic arguments}) {
    return Get.offAllNamed(routeName, arguments: arguments);
  }
  
  /// Go back to previous route
  void goBack() {
    Get.back();
  }
  
  /// Return whether the navigator can go back
  bool canGoBack() {
    return Get.currentRoute != AppPages.INITIAL;
  }
  
  /// Show a snackbar notification
  void showSnackbar({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      duration: duration,
      backgroundColor: Get.isDarkMode ? Colors.grey[800] : Colors.grey[200],
      colorText: Get.isDarkMode ? Colors.white : Colors.black,
    );
  }
}