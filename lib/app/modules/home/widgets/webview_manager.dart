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
}

class WebViewData {
  final Completer<InAppWebViewController> controller;
  bool isInitialized = false;
  
  WebViewData(this.controller);
}