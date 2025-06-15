import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../core/utils/app_constants.dart';

/// A global controller for application-wide state management
class AppStateController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  // Theme settings
  final RxBool isDarkMode = false.obs;

  // Application settings
  final RxBool kioskMode = true.obs;
  final RxBool showSystemInfo = true.obs;
  final RxString kioskStartUrl = AppConstants.defaultKioskStartUrl.obs;

  // Connection status
  final RxBool isConnected = false.obs;
  final RxString connectionError = ''.obs;

  // Loading state
  final RxBool isLoading = false.obs;
  final RxString loadingMessage = ''.obs;

  // App status
  final RxBool isInitialized = false.obs;
  final RxBool isOnline = false.obs;
  final RxString currentPage = ''.obs;

  // Error state
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  // App lifecycle
  final RxBool isInForeground = true.obs;
  @override
  void onInit() {
    super.onInit();
    developer.log('AppStateController initialized');
    _loadSettings();
    // Mark as initialized
    isInitialized.value = true;
  }

  void _loadSettings() {
    isDarkMode.value =
        _storageService.read<bool>(AppConstants.keyIsDarkMode) ?? false;
    kioskMode.value =
        _storageService.read<bool>(AppConstants.keyKioskMode) ?? true;
    showSystemInfo.value =
        _storageService.read<bool>(AppConstants.keyShowSystemInfo) ?? true;
    kioskStartUrl.value =
        _storageService.read<String>(AppConstants.keyKioskStartUrl) ??
            AppConstants.defaultKioskStartUrl;

    _applyTheme();
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    _applyTheme();
  }

  void _applyTheme() {
    // Use ThemeService to change theme app-wide
    final themeService = Get.find<ThemeService>();
    themeService.setDarkMode(isDarkMode.value);

    // Also notify any listening widgets through reactive state
    update(['theme_state']);
  }

  void toggleKioskMode() {
    kioskMode.value = !kioskMode.value;
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
  }

  void toggleShowSystemInfo() {
    showSystemInfo.value = !showSystemInfo.value;
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
  }

  void setKioskStartUrl(String url) {
    if (url.isNotEmpty) {
      kioskStartUrl.value = url;
      _storageService.write(AppConstants.keyKioskStartUrl, url);
    }
  }

  // Kiosk auto-load functionality has been removed

  void setLoading(bool isLoading, {String message = ''}) {
    this.isLoading.value = isLoading;
    loadingMessage.value = message;
  }

  void setConnectionStatus(bool isConnected, {String error = ''}) {
    this.isConnected.value = isConnected;
    connectionError.value = error;
    if (isConnected) {
      clearError();
    }
  }

  void setOnlineStatus(bool online) {
    isOnline.value = online;
  }

  void setCurrentPage(String page) {
    currentPage.value = page;
  }

  void setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
    developer.log('AppStateController error: $message');
  }

  void clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }

  void setForegroundState(bool isInForeground) {
    this.isInForeground.value = isInForeground;
  }
}
