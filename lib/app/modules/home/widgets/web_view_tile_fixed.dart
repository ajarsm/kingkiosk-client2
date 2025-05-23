import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../controllers/web_window_controller.dart';
import 'webview_manager.dart';

/// A global manager for WebView instances to prevent recreation during rebuilds
class WebViewInstanceManager {
  static final WebViewInstanceManager _instance =
      WebViewInstanceManager._internal();

  factory WebViewInstanceManager() => _instance;

  WebViewInstanceManager._internal();

  // Map of window IDs to their WebView instances
  final Map<String, InAppWebView> _instances = {};

  // Create or get an existing WebView instance
  InAppWebView getOrCreateWebView(String id, String url, ValueKey<String> key) {
    if (!_instances.containsKey(id)) {
      print(
          '📌 WebViewInstanceManager: Creating new WebView for ID: $id and URL: $url');
      _instances[id] = _createWebView(url, key);
    } else {
      print('📌 WebViewInstanceManager: Reusing WebView for ID: $id');
    }
    return _instances[id]!;
  }

  // Create a new WebView instance
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
      ),
    );
  }

  // Remove a WebView instance
  bool removeWebView(String id) {
    if (_instances.containsKey(id)) {
      print('📌 WebViewInstanceManager: Removing WebView for ID: $id');
      _instances.remove(id);
      return true;
    }
    return false;
  }
}

class WebViewTile extends StatefulWidget {
  final String url;
  final int? refreshKey;
  final String? windowId; // Window ID for MQTT and window management

  const WebViewTile({
    Key? key,
    required this.url,
    this.refreshKey,
    this.windowId,
  }) : super(key: key);

  // Static method to clean up WebView instances
  static bool cleanUpWebViewInstance(String windowId) {
    return WebViewInstanceManager().removeWebView(windowId);
  }

  @override
  State<WebViewTile> createState() => _WebViewTileState();
}

class _WebViewTileState extends State<WebViewTile>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late WebViewData _webViewData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Stable key that won't change during widget lifetime
  late final ValueKey<String> _stableWebViewKey;

  // The actual WebView instance - will be retrieved from WebViewInstanceManager
  late final InAppWebView _stableWebViewWidget;

  @override
  bool get wantKeepAlive => true; // Keep state alive when widget is not visible

  @override
  void didUpdateWidget(WebViewTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    print(
        '🔧 WebViewTile - didUpdateWidget called. Old URL: ${oldWidget.url}, New URL: ${widget.url}');
    print(
        '🔧 WebViewTile - didUpdateWidget old refreshKey: ${oldWidget.refreshKey}, new refreshKey: ${widget.refreshKey}');

    // Only reload the WebView if URL changed OR refreshKey changed AND refreshKey is not null
    bool shouldReloadPage = oldWidget.url != widget.url;

    // Only consider refreshKey changes when a non-null refreshKey is provided
    if (widget.refreshKey != null &&
        oldWidget.refreshKey != widget.refreshKey) {
      shouldReloadPage = true;
    }

    // Handle windowId changes separately to avoid unnecessary resets
    bool windowIdChanged = oldWidget.windowId != widget.windowId &&
        widget.windowId != null &&
        oldWidget.windowId != null;

    // We no longer need to recreate the WebView - just reload the URL if needed
    if (shouldReloadPage || windowIdChanged) {
      print(
          '🔄 WebViewTile - URL or refresh key changed - Reloading URL: ${widget.url}, refreshKey: ${widget.refreshKey}, windowId: ${widget.windowId}');
      // Update the WebViewData
      _webViewData = WebViewManager().getWebViewFor(widget.url);

      // Use the existing controller to load the new URL
      _webViewData.safelyExecute((controller) async {
        try {
          print(
              '🔄 WebViewTile - Loading new URL: ${widget.url} using existing controller');
          await controller.loadUrl(
              urlRequest: URLRequest(url: WebUri(widget.url)));
        } catch (e) {
          print('⚠️ WebViewTile - Error loading new URL: $e');
        }
      });

      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    } else {
      print('🔧 WebViewTile - No URL or refreshKey change, skipping reload');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Note: We don't remove the WebView instance here since it would defeat the purpose
    // of maintaining stable instances. WebView instances should be cleaned up when
    // windows are explicitly closed via WebViewTile.cleanUpWebViewInstance().
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Disable WebView debug logging
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    WidgetsBinding.instance.addObserver(this);

    // Get the WebViewData from our manager
    _webViewData = WebViewManager().getWebViewFor(widget.url);

    // Create a stable key that will remain constant throughout the lifecycle
    _stableWebViewKey = ValueKey(
        'webview_stable_${widget.windowId ?? DateTime.now().millisecondsSinceEpoch}');
    print(
        '🔧 WebViewTile - Using stable WebView for key: $_stableWebViewKey with URL: ${widget.url}');

    // Get a stable WebView instance from our global manager
    final String instanceKey = widget.windowId ?? widget.url;
    _stableWebViewWidget = WebViewInstanceManager()
        .getOrCreateWebView(instanceKey, widget.url, _stableWebViewKey);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Configure our stable WebView instance with event handlers
    final webViewWidget = _configureWebView(_stableWebViewWidget);

    if (_hasError) {
      return Center(
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          color: Colors.red.shade50.withOpacity(0.95),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: [Colors.redAccent, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(rect),
                  child:
                      Icon(Icons.error_rounded, color: Colors.white, size: 64),
                ),
                SizedBox(height: 22),
                Text('Failed to load web content',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.red.shade700)),
                SizedBox(height: 12),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 400),
                  style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                  child: Text(
                    _errorMessage.isNotEmpty
                        ? _errorMessage
                        : 'Unable to load: ${widget.url}',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _webViewData.safelyExecute((controller) async {
                      await controller.reload();
                    });
                  },
                  label: Text('Retry', style: TextStyle(fontSize: 17)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent, width: 0),
        boxShadow: [
          BoxShadow(
            color: Colors.transparent,
            blurRadius: 0,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: webViewWidget,
          ),
          if (_isLoading && !_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    width: _isLoading ? 56 : 0,
                    height: _isLoading ? 56 : 0,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          Colors.lightBlueAccent,
                          Colors.cyanAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(rect),
                      child: Icon(Icons.language_rounded,
                          size: 56, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 18),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 400),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                    child: Text('Loading page...'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.url,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade400,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Configure the WebView with all necessary event handlers
  InAppWebView _configureWebView(InAppWebView webView) {
    // Set up event handlers for this webView instance
    webView.onWebViewCreated = (controller) {
      print('🔧 WebViewTile - WebView created with key: $_stableWebViewKey');
      if (!_webViewData.isInitialized) {
        _webViewData.controller.complete(controller);
        _webViewData.isInitialized = true;
      }

      // Register WebWindowController when the webview is created
      if (widget.windowId != null) {
        final wm = Get.find<WindowManagerService>();
        wm.unregisterWindow(widget.windowId!);
        final webController = WebWindowController(
          windowName: widget.windowId!,
          webViewController: controller,
          onClose: () {
            wm.unregisterWindow(widget.windowId!);
          },
        );
        wm.registerWindow(webController);
      }
    };

    webView.onLoadStart = (controller, url) {
      print(
          '🔧 WebViewTile - Load started for URL: ${url?.toString() ?? widget.url}');
      setState(() {
        _isLoading = true;
      });
    };

    webView.onLoadStop = (controller, url) async {
      print(
          '🔧 WebViewTile - Load completed for URL: ${url?.toString() ?? widget.url}');
      setState(() {
        _isLoading = false;
      });

      // Enable touch events on WebView content
      try {
        await controller.evaluateJavascript(source: """
          // Add enhanced touch handling for elements
          document.addEventListener('touchstart', function(e) {
            console.log('Touch event intercepted and passed through');
          }, {passive: true});
          
          // Make all interactive elements clearly tappable
          const interactiveElements = document.querySelectorAll('a, button, input, select, [role="button"]');
          interactiveElements.forEach(el => {
            if (!el.style.cursor) el.style.cursor = 'pointer';
          });
        """);
        print("🔧 WebViewTile - Enhanced touch handling script injected");
      } catch (e) {
        print("⚠️ WebViewTile - Error injecting touch handling script: $e");
      }
    };

    webView.onReceivedError = (controller, request, error) {
      print(
          '⚠️ WebViewTile - Error loading URL: ${request.url}, Error: ${error.description}');
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = error.description;
      });
    };

    webView.onConsoleMessage = (controller, consoleMessage) {
      print(
          "🔧 WebViewTile Console [${widget.url}]: ${consoleMessage.message}");
    };

    webView.shouldOverrideUrlLoading = (controller, navigationAction) async {
      print(
          "🔧 WebViewTile - URL navigating to: ${navigationAction.request.url}");
      return NavigationActionPolicy.ALLOW;
    };

    return webView;
  }
}
