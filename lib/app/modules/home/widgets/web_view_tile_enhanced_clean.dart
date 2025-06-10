import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../controllers/web_view_tile_controller.dart';

/// A global manager for WebView instances to prevent recreation during rebuilds
class WebViewInstanceManager {
  static final WebViewInstanceManager _instance =
      WebViewInstanceManager._internal();

  factory WebViewInstanceManager() => _instance;

  WebViewInstanceManager._internal();

  // Map of window IDs to their WebView instances
  final Map<String, _WebViewWrapper> _instances = {};

  // Create or get an existing WebView instance
  InAppWebView getOrCreateWebView({
    required String id,
    required String url,
    required ValueKey<String> key,
    required WebViewCallbackHandler callbackHandler,
  }) {
    print('📌 WebViewInstanceManager: Request for ID: $id, URL: $url');
    print(
        '📌 WebViewInstanceManager: Current instances: ${_instances.keys.toList()}');

    if (!_instances.containsKey(id)) {
      print('📌 WebViewInstanceManager: ✨ Creating NEW WebView for ID: $id');
      _instances[id] = _WebViewWrapper(
        id: id,
        url: url,
        key: key,
        callbackHandler: callbackHandler,
      );
    } else {
      print(
          '📌 WebViewInstanceManager: ♻️ Reusing EXISTING WebView for ID: $id');
      // Update the callback handler to ensure it's using the current state
      _instances[id]!.updateCallbackHandler(callbackHandler);
    }

    print(
        '📌 WebViewInstanceManager: Total active instances: ${_instances.length}');
    return _instances[id]!.webView;
  }

  // Remove a WebView instance
  bool removeWebView(String id) {
    print('📌 WebViewInstanceManager: Request to REMOVE WebView ID: $id');
    print(
        '📌 WebViewInstanceManager: Current instances before removal: ${_instances.keys.toList()}');

    if (_instances.containsKey(id)) {
      print(
          '📌 WebViewInstanceManager: ✅ Successfully removing WebView for ID: $id');
      _instances.remove(id);
      print(
          '📌 WebViewInstanceManager: Remaining instances: ${_instances.keys.toList()}');
      return true;
    } else {
      print(
          '📌 WebViewInstanceManager: ❌ WebView ID: $id not found for removal');
      return false;
    }
  }
}

/// A wrapper class that holds a WebView instance and its callback handler
class _WebViewWrapper {
  final String id;
  final String url;
  late WebViewCallbackHandler _callbackHandler;
  late final InAppWebView webView;

  _WebViewWrapper({
    required this.id,
    required this.url,
    required ValueKey<String> key,
    required WebViewCallbackHandler callbackHandler,
  }) {
    _callbackHandler = callbackHandler;
    webView = _createWebView(url, key);
  }

  // Update the callback handler (used when same WebView is used with a new WebViewTile instance)
  void updateCallbackHandler(WebViewCallbackHandler handler) {
    _callbackHandler = handler;
  }

  // Create a new WebView instance with all event handlers
  InAppWebView _createWebView(String url, ValueKey<String> key) {
    return InAppWebView(
      key: key,
      initialUrlRequest: URLRequest(
        url: WebUri(url),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: true,
        useOnLoadResource: false,
        supportZoom: true,
        verticalScrollBarEnabled: true,
        horizontalScrollBarEnabled: true,
        allowsInlineMediaPlayback: true,
        disableHorizontalScroll: false,
        disableVerticalScroll: false,
        allowsLinkPreview: true,
        allowsBackForwardNavigationGestures: true,
        javaScriptCanOpenWindowsAutomatically: true,
        userAgent:
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15",
        useOnDownloadStart: true,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptAjaxRequest: true,
        useShouldInterceptFetchRequest: true,
        clearCache: false,
        cacheEnabled: true,
      ),
      // Pass event handlers in the constructor
      onWebViewCreated: (controller) {
        _callbackHandler.onWebViewCreated(controller, id);
      },
      onLoadStart: (controller, url) {
        _callbackHandler.onLoadStart(controller, url);
      },
      onLoadStop: (controller, url) {
        _callbackHandler.onLoadStop(controller, url);
      },
      onReceivedError: (controller, request, error) {
        // Convert WebResourceRequest to URLRequest for the callback
        final urlRequest = URLRequest(url: request.url);
        _callbackHandler.onReceivedError(controller, urlRequest, error);
      },
      onConsoleMessage: (controller, consoleMessage) {
        _callbackHandler.onConsoleMessage(controller, consoleMessage);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return _callbackHandler.shouldOverrideUrlLoading(
            controller, navigationAction);
      },
      // Handler for SSL certificate errors - proceed regardless of certificate validity
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        print(
            '🔒 WebViewTile - Received SSL certificate challenge, proceeding anyway');
        return ServerTrustAuthResponse(
            action: ServerTrustAuthResponseAction.PROCEED);
      },
    );
  }
}

/// Interface for WebView event callbacks
class WebViewCallbackHandler {
  void onWebViewCreated(InAppWebViewController controller, String id) {}
  void onLoadStart(InAppWebViewController controller, WebUri? url) {}
  void onLoadStop(InAppWebViewController controller, WebUri? url) {}
  void onReceivedError(InAppWebViewController controller, URLRequest request,
      WebResourceError error) {}
  void onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {}
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  }
}

class WebViewTile extends GetView<WebViewTileController> {
  final String url;
  final int? refreshKey;
  final String? windowId; // Window ID for MQTT and window management

  const WebViewTile({
    Key? key,
    required this.url,
    this.refreshKey,
    this.windowId,
  }) : super(key: key);

  @override
  String get tag => windowId ?? url; // Use windowId or URL as unique tag

  // Static method to clean up WebView instances
  static bool cleanUpWebViewInstance(String windowId) {
    return WebViewInstanceManager().removeWebView(windowId);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller with URL-specific tag
    Get.put(
        WebViewTileController(
          url: url,
          refreshKey: refreshKey,
          windowId: windowId,
        ),
        tag: tag);

    return Obx(() => _buildContent());
  }

  Widget _buildContent() {
    if (!controller.isUrlValid.value) {
      return _buildInvalidUrlWidget();
    }

    if (controller.hasError.value) {
      return _buildErrorWidget();
    }

    if (controller.isLoading.value) {
      return _buildLoadingWidget();
    }

    return _buildWebView();
  }

  Widget _buildInvalidUrlWidget() {
    return Container(
      color: Colors.red.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Invalid URL',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The provided URL is not valid',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.red.shade50,
      child: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Failed to load page',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      onPressed:
                          controller.canRetry ? () => controller.retry() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.clear),
                      label: Text('Clear Cache'),
                      onPressed: () => controller.clearWebView(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (!controller.canRetry) ...[
                  SizedBox(height: 12),
                  Text(
                    'Max retry attempts reached',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return controller.stableWebViewWidget;
  }
}
