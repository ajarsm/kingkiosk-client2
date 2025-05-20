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
        transparentBackground: false,
        supportZoom: true,
        verticalScrollBarEnabled: true,
        horizontalScrollBarEnabled: true,
        allowsInlineMediaPlayback: true,
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
      onLoadStop: (controller, url) {
        setState(() {
          _isLoading = false;
        });
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
    );

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Failed to load web content'),
            SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Unable to load: ${widget.url}',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _webViewData.safelyExecute((controller) async {
                  await controller.reload();
                });
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        webViewWidget,
        if (_isLoading && !_hasError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading ${widget.url}...'),
              ],
            ),
          ),
      ],
    );
  }
}
