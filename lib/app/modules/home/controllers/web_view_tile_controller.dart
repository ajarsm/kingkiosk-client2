import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../widgets/web_view_tile_enhanced.dart';
import '../widgets/webview_manager.dart';

/// Controller for WebViewTile to replace StatefulWidget state management
class WebViewTileController extends GetxController
    with WidgetsBindingObserver
    implements WebViewCallbackHandler {
  final String url;
  final int? refreshKey;
  final String? windowId;

  // Reactive state variables
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final retryAttempts = 0.obs;
  final isRetrying = false.obs;
  final isUrlValid = true.obs;

  // Non-reactive variables (no need to be reactive)
  static const int MAX_RETRY_ATTEMPTS = 5;
  static int _instanceCount = 0;
  late final int instanceId;
  late final DateTime createdAt;
  late final ValueKey<String> stableWebViewKey;
  late final InAppWebView stableWebViewWidget;
  late WebViewData webViewData;

  WebViewTileController({
    required this.url,
    this.refreshKey,
    this.windowId,
  });

  String get tag => windowId ?? url; // Use windowId or URL as unique tag

  @override
  void onInit() {
    super.onInit();

    // Initialize instance tracking
    instanceId = ++_instanceCount;
    createdAt = DateTime.now();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    print('🚀 WebViewTileController #$instanceId CREATED: $url');
    print('🚀 WindowId: $windowId, RefreshKey: $refreshKey');

    _initializeWebView();
  }

  @override
  void onClose() {
    print('🗑️ WebViewTileController #$instanceId DISPOSED: $url');
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 WebViewTileController #$instanceId AppLifecycleState: $state');

    // Handle app lifecycle changes if needed
    if (state == AppLifecycleState.resumed) {
      // App resumed, check if webview needs refresh
      _handleAppResume();
    } else if (state == AppLifecycleState.paused) {
      // App paused, pause any ongoing operations
      _handleAppPause();
    }
  }

  /// Initialize the WebView
  void _initializeWebView() {
    print('🔧 WebViewTileController #$instanceId: Initializing WebView...');

    // Validate URL first
    if (!_validateUrl(url)) {
      isUrlValid.value = false;
      hasError.value = true;
      errorMessage.value = 'Invalid URL format';
      isLoading.value = false;
      return;
    }

    try {
      // Create stable key and get WebView data
      stableWebViewKey = ValueKey(
          '${windowId ?? url}_${DateTime.now().millisecondsSinceEpoch}');
      webViewData = WebViewManager().getWebViewFor(url);

      // Create the WebView widget
      stableWebViewWidget = WebViewInstanceManager().getOrCreateWebView(
        id: windowId ?? url,
        url: url,
        key: stableWebViewKey,
        callbackHandler: this,
      );

      print(
          '✅ WebViewTileController #$instanceId: WebView initialized successfully');
    } catch (e) {
      print(
          '❌ WebViewTileController #$instanceId: Error initializing WebView: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to initialize WebView: $e';
      isLoading.value = false;
    }
  }

  /// Handle widget updates (equivalent to didUpdateWidget)
  void handleUpdate({
    required String newUrl,
    int? newRefreshKey,
    String? newWindowId,
  }) {
    print('🔄 WebViewTileController #$instanceId UPDATE: $url -> $newUrl');
    print('🔄 refreshKey: $refreshKey -> $newRefreshKey');
    print('🔄 windowId: $windowId -> $newWindowId');

    // Only reload the WebView if URL changed OR refreshKey changed AND refreshKey is not null
    bool shouldReloadPage = url != newUrl;

    // Only consider refreshKey changes when a non-null refreshKey is provided
    if (newRefreshKey != null && refreshKey != newRefreshKey) {
      shouldReloadPage = true;
    }

    // Handle windowId changes separately to avoid unnecessary resets
    bool windowIdChanged =
        windowId != newWindowId && newWindowId != null && windowId != null;

    if (shouldReloadPage || windowIdChanged) {
      print(
          '🔄 WebViewTileController #$instanceId RELOADING: shouldReloadPage=$shouldReloadPage, windowIdChanged=$windowIdChanged');

      // Update the WebViewData
      webViewData = WebViewManager().getWebViewFor(newUrl);

      // Reset retry attempts when URL changes
      retryAttempts.value = 0;

      // Use the existing controller to load the new URL
      webViewData.safelyExecute((controller) async {
        try {
          print(
              '🔄 WebViewTileController - Loading new URL: $newUrl using existing controller');
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri(newUrl)));
        } catch (e) {
          print('⚠️ WebViewTileController - Error loading new URL: $e');
        }
      });

      isLoading.value = true;
      hasError.value = false;
    } else {
      print(
          '🔄 WebViewTileController #$instanceId NO RELOAD: No significant changes detected');
    }
  }

  /// Handle app resume
  void _handleAppResume() {
    // Implementation for app resume if needed
    print('📱 WebViewTileController #$instanceId: App resumed');
  }

  /// Handle app pause
  void _handleAppPause() {
    // Implementation for app pause if needed
    print('📱 WebViewTileController #$instanceId: App paused');
  }

  /// Retry loading the WebView
  Future<void> retry() async {
    if (isRetrying.value) return;

    isRetrying.value = true;
    retryAttempts.value++;

    print(
        '🔄 WebViewTileController #$instanceId: Retry attempt ${retryAttempts.value}/$MAX_RETRY_ATTEMPTS');

    try {
      hasError.value = false;
      errorMessage.value = '';
      isLoading.value = true;

      // Wait with exponential backoff
      final backoffMs = _getBackoffMilliseconds();
      await Future.delayed(Duration(milliseconds: backoffMs));

      // Attempt to reload
      webViewData.safelyExecute((controller) async {
        try {
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
        } catch (e) {
          throw Exception('Failed to reload URL: $e');
        }
      });
    } catch (e) {
      print('❌ WebViewTileController #$instanceId: Retry failed: $e');
      hasError.value = true;
      errorMessage.value = 'Retry failed: $e';
      isLoading.value = false;
    } finally {
      isRetrying.value = false;
    }
  }

  /// Clear the WebView
  void clearWebView() {
    webViewData.safelyExecute((controller) async {
      try {
        await controller.clearCache();
        await controller.reload();
      } catch (e) {
        print(
            '⚠️ WebViewTileController #$instanceId: Error clearing WebView: $e');
      }
    });
  }

  /// Clean up WebView instance
  static bool cleanUpWebViewInstance(String windowId) {
    return WebViewInstanceManager().removeWebView(windowId);
  }

  /// Validate URL format
  bool _validateUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get exponential backoff in milliseconds
  int _getBackoffMilliseconds() {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s (max)
    final seconds = _getBackoffSeconds();
    return seconds * 1000;
  }

  /// Get exponential backoff in seconds
  int _getBackoffSeconds() {
    if (retryAttempts.value <= 0) return 1;

    // Cap at 16 seconds maximum
    final backoff = (1 << (retryAttempts.value - 1)).clamp(1, 16);
    return backoff;
  }

  /// Check if can retry
  bool get canRetry => retryAttempts.value < MAX_RETRY_ATTEMPTS;

  /// Cleanup resources
  void _cleanup() {
    try {
      // Cleanup is handled by WebViewManager and WebViewInstanceManager
      print('🧹 WebViewTileController #$instanceId: Cleanup completed');
    } catch (e) {
      print('⚠️ WebViewTileController #$instanceId: Error during cleanup: $e');
    }
  }

  // WebViewCallbackHandler implementation
  @override
  void onWebViewCreated(InAppWebViewController controller, String id) {
    print(
        '🎉 WebViewTileController #$instanceId: WebView created with id: $id');
    webViewData.controller.complete(controller);
    webViewData.isInitialized = true;
  }

  @override
  void onLoadStart(InAppWebViewController controller, WebUri? uri) {
    print('🔄 WebViewTileController #$instanceId: Load started: $uri');
    isLoading.value = true;
    hasError.value = false;
  }

  @override
  void onLoadStop(InAppWebViewController controller, WebUri? uri) {
    print('✅ WebViewTileController #$instanceId: Load completed: $uri');
    isLoading.value = false;
    hasError.value = false;
    retryAttempts.value = 0; // Reset retry attempts on success
  }

  @override
  void onReceivedError(InAppWebViewController controller, URLRequest request,
      WebResourceError error) {
    print('❌ WebViewTileController #$instanceId: Error: ${error.description}');
    isLoading.value = false;
    hasError.value = true;
    errorMessage.value = error.description;
  }

  @override
  void onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {
    print(
        '📝 WebViewTileController #$instanceId: Console: ${consoleMessage.message}');
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  }
}
