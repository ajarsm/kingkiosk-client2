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
      print('🔄 [REFRESH] WebViewManager - Created new WebViewData for URL: $url');
    } else {
      print('🔄 [REFRESH] WebViewManager - Reusing existing WebViewData for URL: $url');
    }
    return _webViews[url]!;
  }
  
  void dispose() {
    for (final webViewData in _webViews.values) {
      webViewData.controller.future.then((controller) {
        controller.clearCache();
      }).catchError((_) {});
    }
    _webViews.clear();
  }

  /// Hard refresh - force recreation of WebViewData for a URL
  void forceRefresh(String url) {
    if (_webViews.containsKey(url)) {
      try {
        print('🔄 [REFRESH] WebViewManager - Forcing refresh of WebViewData for URL: $url');
        // Try to dispose the old controller if it exists
        _webViews[url]?.controller.future.then((controller) {
          controller.stopLoading();
        }).catchError((_) {});
        
        // Replace with new WebViewData
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