import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_manager.dart';

class WebViewTile extends StatefulWidget {
  final String url;
  
  const WebViewTile({
    Key? key,
    required this.url,
  }) : super(key: key);

  @override
  State<WebViewTile> createState() => _WebViewTileState();
}

class _WebViewTileState extends State<WebViewTile> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final WebViewData _webViewData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final GlobalKey webViewKey = GlobalKey();
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when widget is not visible
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _webViewData = WebViewManager().getWebViewFor(widget.url);
  }
  
  @override
  void didUpdateWidget(WebViewTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
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
              _errorMessage.isNotEmpty ? _errorMessage : 'Unable to load: ${widget.url}',
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
                _webViewData.controller.future.then((controller) {
                  controller.reload();
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
        InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(
            url: WebUri(widget.url),
          ),
          initialSettings: InAppWebViewSettings(
            supportZoom: true,
            useHybridComposition: true,
            javaScriptEnabled: true,
          ),
          onWebViewCreated: (controller) {
            if (!_webViewData.isInitialized) {
              _webViewData.controller.complete(controller);
              _webViewData.isInitialized = true;
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
            print("WebView Console: ${consoleMessage.message}");
          },
        ),
        
        if (_isLoading && !_hasError)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}