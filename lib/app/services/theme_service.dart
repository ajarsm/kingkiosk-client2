import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/utils/app_constants.dart';

class ThemeService extends GetxService {
  final _storage = GetStorage();
  final _isDarkMode = false.obs;
  
  ThemeService();
  
  // Initialize the service and return itself for Get.put() chaining
  ThemeService init() {
    // Load initial value from storage
    _isDarkMode.value = _storage.read(AppConstants.keyIsDarkMode) ?? false;
    return this;
  }
  
  // Get current dark mode state
  bool get isDarkMode => _isDarkMode.value;
  
  // Get observable for the dark mode state
  RxBool get rxIsDarkMode => _isDarkMode;
  
  // Get the current theme mode
  ThemeMode getThemeMode() {
    return _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }
  
  // Toggle theme mode
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _storage.write(AppConstants.keyIsDarkMode, _isDarkMode.value);
    Get.changeThemeMode(getThemeMode());
  }
  
  // Set theme mode directly
  void setDarkMode(bool isDark) {
    _isDarkMode.value = isDark;
    _storage.write(AppConstants.keyIsDarkMode, isDark);
    
    // Defer theme change to avoid setState during build issues
    Future.microtask(() {
      Get.changeThemeMode(getThemeMode());
    });
  }
}