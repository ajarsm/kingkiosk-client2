# WebView Persistence Fix - Callback Handler Implementation

## Problem Overview
In the KingKiosk Flutter application, WebViews were being unnecessarily recreated when the widget tree rebuilt, causing:
- Visible flickering when navigating between screens
- Duplicate network requests
- Loss of WebView state (scroll position, form data, etc.)
- Memory leaks and performance degradation

## Solution Architecture
The solution implements a multi-layered approach using callback handlers to ensure that WebView instances remain stable throughout the application lifecycle:

### 1. Key Components

#### WebViewInstanceManager
A singleton class that maintains a static map of WebView instances by ID:

```dart
class WebViewInstanceManager {
  static final WebViewInstanceManager _instance = WebViewInstanceManager._internal();
  final Map<String, _WebViewWrapper> _instances = {};
  
  InAppWebView getOrCreateWebView({
    required String id, 
    required String url, 
    required ValueKey<String> key,
    required WebViewCallbackHandler callbackHandler,
  }) {
    // Implementation ensures stable WebView instances
  }
}
```

#### WebViewCallbackHandler Interface
An interface that defines the callback methods for WebView events:

```dart
class WebViewCallbackHandler {
  void onWebViewCreated(InAppWebViewController controller, String id) {}
  void onLoadStart(InAppWebViewController controller, WebUri? url) {}
  void onLoadStop(InAppWebViewController controller, WebUri? url) {}
  void onReceivedError(InAppWebViewController controller, URLRequest request, WebResourceError error) {}
  void onConsoleMessage(InAppWebViewController controller, ConsoleMessage consoleMessage) {}
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  }
}
```

#### _WebViewWrapper
A wrapper class that holds a WebView instance and its callback handler:

```dart
class _WebViewWrapper {
  final String id;
  final String url;
  late WebViewCallbackHandler _callbackHandler;
  late final InAppWebView webView;
  
  // Creates a WebView with callbacks passing to the current handler
  _WebViewWrapper({
    required this.id,
    required this.url,
    required ValueKey<String> key,
    required WebViewCallbackHandler callbackHandler,
  }) {
    _callbackHandler = callbackHandler;
    webView = _createWebView(url, key);
  }
  
  // Updates the callback handler when the same WebView is used with a new WebViewTile
  void updateCallbackHandler(WebViewCallbackHandler handler) {
    _callbackHandler = handler;
  }
}
```

#### WebViewTile
A widget that implements the WebViewCallbackHandler interface to handle WebView events:

```dart
class _WebViewTileState extends State<WebViewTile>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver
    implements WebViewCallbackHandler {
  
  // Gets a stable WebView instance from the manager
  @override
  void initState() {
    super.initState();
    final String instanceKey = widget.windowId ?? widget.url;
    _stableWebViewWidget = WebViewInstanceManager().getOrCreateWebView(
      id: instanceKey,
      url: widget.url,
      key: _stableWebViewKey,
      callbackHandler: this, // Pass this as the callback handler
    );
  }
  
  // Implementation of WebViewCallbackHandler methods
  @override
  void onWebViewCreated(InAppWebViewController controller, String id) {
    // Handle WebView creation
  }
  
  @override
  void onLoadStop(InAppWebViewController controller, WebUri? url) async {
    // Handle page load completion
  }
  
  // etc.
}
```

### 2. Key Insights

1. **Flutter InAppWebView API Changes**:
   - In flutter_inappwebview 6.x, event handlers must be specified in the constructor
   - Setting them directly on the WebView instance after creation no longer works

2. **Callback Pattern**:
   - Using a callback interface allows the WebView instance to remain stable
   - When a new WebViewTile is created using the same ID, it can register as the new callback handler

3. **Wrapper Class**:
   - The _WebViewWrapper class maintains the connection between the WebView and its current callback handler
   - Allows updating the handler without recreating the WebView

## Implementation Benefits

1. **Stability**: WebView instances persist through widget tree rebuilds
2. **Performance**: Eliminates duplicate network requests and flickering
3. **State Preservation**: Maintains WebView state (scroll position, form inputs)
4. **Flexibility**: Allows WebViewTile widgets to be rebuilt while keeping the same WebView instance
5. **Resource Management**: Prevents memory leaks by properly cleaning up instances when windows are closed

## Testing & Verification

The solution has been tested with:
- `test_webview_callback_solution.sh`: Verifies WebView instance stability through multiple refreshes
- Manual testing with MQTT commands to ensure proper behavior

## Compatibility Notes

This solution:
- Works with flutter_inappwebview 6.1.5
- Is fully compatible with existing window management system
- Preserves all WebView functionality including JavaScript execution and touch handling
