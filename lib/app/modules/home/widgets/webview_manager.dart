import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Maintains persistent WebView instances to prevent reloading
class WebViewManager {
  static final WebViewManager _instance = WebViewManager._internal();

  factory WebViewManager() => _instance;

  WebViewManager._internal();

  final Map<String, WebViewData> _webViews = {};

  WebViewData getWebViewFor(String url) {
    if (!_webViews.containsKey(url)) {
      final controller = Completer<InAppWebViewController>();
      _webViews[url] = WebViewData(controller);
      print(
          '🔄 [REFRESH] WebViewManager - Created new WebViewData for URL: $url');
    } else {
      print(
          '🔄 [REFRESH] WebViewManager - Reusing existing WebViewData for URL: $url');
    }
    return _webViews[url]!;
  }

  void dispose() {
    for (final webViewData in _webViews.values) {
      webViewData.safelyExecute((controller) async {
        try {
          await controller.clearCache();
          await controller.stopLoading();
        } catch (e) {
          print('⚠️ Error during WebView disposal: $e');
        }
      });
    }
    _webViews.clear();
  }

  /// Hard refresh - force recreation of WebViewData for a URL
  void forceRefresh(String url) {
    if (_webViews.containsKey(url)) {
      try {
        print(
            '🔄 [REFRESH] WebViewManager - Forcing refresh of WebViewData for URL: $url');
        // Try to dispose the old controller if it exists
        final oldData = _webViews[url];
        if (oldData != null) {
          oldData.safelyExecute((controller) async {
            try {
              await controller.stopLoading();
              // Try to clear cache and cookies
              await controller.clearCache();
            } catch (e) {
              print('⚠️ Error during WebView controller cleanup: $e');
            }
          });
        }

        // Replace with new WebViewData regardless of cleanup success
        _webViews[url] = WebViewData(Completer<InAppWebViewController>());
      } catch (e) {
        print('⚠️ [REFRESH] Error while forcing refresh: $e');
      }
    }
  }
}

class WebViewData {
  final Completer<InAppWebViewController> controller;
  bool isInitialized = false;

  WebViewData(this.controller);
}

/// Extension to add safe execution methods to WebViewData
extension WebViewDataSafeExecution on WebViewData {
  /// Safely execute an action on the controller if it's available
  /// Returns true if the action was executed, false otherwise
  Future<bool> safelyExecute(
      Future<void> Function(InAppWebViewController) action) async {
    if (!isInitialized) {
      print('ℹ️ WebView not initialized yet, cannot perform action');
      return false;
    }

    try {
      // Use a timeout to prevent hanging if the controller is in an invalid state
      final webViewController = await controller.future.timeout(
        const Duration(milliseconds: 800),
        onTimeout: () {
          print('⚠️ WebView controller future timed out');
          throw TimeoutException('Controller future timed out');
        },
      );

      // Execute the action
      await action(webViewController);
      return true;
    } on TimeoutException catch (_) {
      print('⚠️ Timeout while accessing WebView controller');
      return false;
    } catch (e) {
      print('⚠️ Error accessing WebView controller: $e');
      return false;
    }
  }
}
