import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../controllers/web_window_controller.dart';
import 'webview_manager.dart';

class WebViewTile extends StatefulWidget {
  final String url;
  final int? refreshKey;
  final String? windowId; // New: window ID for MQTT and window management

  const WebViewTile({
    Key? key,
    required this.url,
    this.refreshKey,
    this.windowId,
  }) : super(key: key);

  @override
  State<WebViewTile> createState() => _WebViewTileState();
}

class _WebViewTileState extends State<WebViewTile>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late WebViewData _webViewData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final GlobalKey webViewKey = GlobalKey();

  @override
  bool get wantKeepAlive => true; // Keep state alive when widget is not visible
  @override
  void initState() {
    super.initState();
    // Disable WebView debug logging
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    WidgetsBinding.instance.addObserver(this);
    _webViewData = WebViewManager().getWebViewFor(widget.url);
  }

  @override
  void didUpdateWidget(WebViewTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If URL changed OR refreshKey changed (for refresh command)
    if (oldWidget.url != widget.url ||
        oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.windowId != widget.windowId) {
      // Reset the WebViewData
      _webViewData = WebViewManager().getWebViewFor(widget.url);

      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final webViewWidget = InAppWebView(
      key: ValueKey('webview_${widget.url}_${widget.refreshKey ?? 0}'),
      initialUrlRequest: URLRequest(
        url: WebUri(widget.url),
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
        // Ensure touch events work properly
        useOnDownloadStart: true,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptAjaxRequest: true,
        useShouldInterceptFetchRequest: true,
      ),
      onWebViewCreated: (controller) {
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
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
        });
      },
      onLoadStop: (controller, url) async {
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
          print("WebView: Enhanced touch handling script injected");
        } catch (e) {
          print("WebView: Error injecting touch handling script: $e");
        }
      },
      onReceivedError: (controller, request, error) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = error.description;
        });
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("WebView Console [${widget.url}]: ${consoleMessage.message}");
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        print("WebView URL loading: ${navigationAction.request.url}");
        return NavigationActionPolicy.ALLOW;
      },
    );

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
            child:
                webViewWidget, // Removed unnecessary stack to reduce complexity
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
}
