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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver
    implements WebViewCallbackHandler {
  late WebViewData _webViewData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  // Track retry attempts for exponential backoff
  int _retryAttempts = 0;
  static const int MAX_RETRY_ATTEMPTS = 5;
  bool _isRetrying = false;

  // URL validation result
  bool _isUrlValid = true;

  // Stable key that won't change during widget lifetime
  late final ValueKey<String> _stableWebViewKey;

  // The actual WebView instance - will be retrieved from WebViewInstanceManager
  late final InAppWebView _stableWebViewWidget;

  // Debug tracking
  static int _instanceCount = 0;
  late final int _instanceId;
  late final DateTime _createdAt;

  @override
  bool get wantKeepAlive => true; // Keep state alive when widget is not visible
  @override
  void didUpdateWidget(WebViewTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    print(
        '� WebViewTile #$_instanceId UPDATE: ${oldWidget.url} -> ${widget.url}');
    print(
        '� WebViewTile #$_instanceId refreshKey: ${oldWidget.refreshKey} -> ${widget.refreshKey}');
    print(
        '🔄 WebViewTile #$_instanceId windowId: ${oldWidget.windowId} -> ${widget.windowId}');

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

    if (shouldReloadPage || windowIdChanged) {
      print(
          '🔄 WebViewTile #$_instanceId RELOADING: shouldReloadPage=$shouldReloadPage, windowIdChanged=$windowIdChanged');
    } else {
      print(
          '🔄 WebViewTile #$_instanceId NO RELOAD: No significant changes detected');
    }

    // We no longer need to recreate the WebView - just reload the URL if needed
    if (shouldReloadPage || windowIdChanged) {
      print(
          '🔄 WebViewTile - URL or refresh key changed - Reloading URL: ${widget.url}, refreshKey: ${widget.refreshKey}, windowId: ${widget.windowId}');
      // Update the WebViewData
      _webViewData = WebViewManager().getWebViewFor(widget.url);

      // Reset retry attempts when URL changes
      _retryAttempts = 0;

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
    final lifespan = DateTime.now().difference(_createdAt);
    print('🔴 WebViewTile #$_instanceId DISPOSE: ${widget.url}');
    print(
        '⏱️ WebViewTile #$_instanceId lifespan: ${lifespan.inMilliseconds}ms');
    print('🆔 WebViewTile #$_instanceId windowId: ${widget.windowId}');
    print('🔢 Total active instances before disposal: $_instanceCount');

    WidgetsBinding.instance.removeObserver(this);
    // Note: We don't remove the WebView instance here since it would defeat the purpose
    // of maintaining stable instances. WebView instances should be cleaned up when
    // windows are explicitly closed via WebViewTile.cleanUpWebViewInstance().
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize debug tracking
    _instanceId = ++_instanceCount;
    _createdAt = DateTime.now();

    print('🟢 WebViewTile #$_instanceId INIT: ${widget.url}');
    print('🕐 WebViewTile #$_instanceId created at: ${_createdAt.toString()}');
    print('🆔 WebViewTile #$_instanceId windowId: ${widget.windowId}');
    print('🔑 WebViewTile #$_instanceId refreshKey: ${widget.refreshKey}');

    // Disable WebView debug logging
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    WidgetsBinding.instance.addObserver(this);

    // Validate URL
    _isUrlValid = _validateUrl(widget.url);
    if (!_isUrlValid) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Invalid URL format: ${widget.url}';
      });
      return;
    }

    // Get the WebViewData from our manager
    _webViewData = WebViewManager().getWebViewFor(widget.url);

    // Create a stable key that will remain constant throughout the lifecycle
    _stableWebViewKey = ValueKey(
        'webview_stable_${widget.windowId ?? DateTime.now().millisecondsSinceEpoch}');
    print(
        '🔧 WebViewTile - Using stable WebView for key: $_stableWebViewKey with URL: ${widget.url}');

    // Get a stable WebView instance from our global manager
    // Pass this class instance as the callback handler
    final String instanceKey = widget.windowId ?? widget.url;
    _stableWebViewWidget = WebViewInstanceManager().getOrCreateWebView(
      id: instanceKey,
      url: widget.url,
      key: _stableWebViewKey,
      callbackHandler: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
                if (_isRetrying)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.redAccent.withOpacity(0.7),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(height: 28),
                if (!_isRetrying)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh_rounded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        onPressed: () {
                          _retryAttempts = 0; // Reset counter on manual retry
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                          });
                          _webViewData.safelyExecute((controller) async {
                            await controller.reload();
                          });
                        },
                        label:
                            Text('Retry Now', style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: Icon(Icons.autorenew),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                              color: Colors.redAccent.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        onPressed: () {
                          _retryWithBackoff();
                        },
                        label:
                            Text('Auto-retry', style: TextStyle(fontSize: 16)),
                      ),
                    ],
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
            child: _stableWebViewWidget,
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

  // WebViewCallbackHandler implementation
  @override
  void onWebViewCreated(InAppWebViewController controller, String id) {
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
  }

  @override
  void onLoadStart(InAppWebViewController controller, WebUri? url) {
    if (!mounted) {
      print(
          '⚠️ WebViewTile #$_instanceId onLoadStart called but widget not mounted!');
      return;
    }

    print(
        '🔄 WebViewTile #$_instanceId LOAD START: ${url?.toString() ?? widget.url}');
    print(
        '🔄 WebViewTile #$_instanceId mounted: $mounted, loading: $_isLoading');

    setState(() {
      _isLoading = true;
    });
  }

  @override
  void onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (!mounted) {
      print(
          '⚠️ WebViewTile #$_instanceId onLoadStop called but widget not mounted!');
      return;
    }

    final loadTime = DateTime.now().difference(_createdAt);
    print(
        '✅ WebViewTile #$_instanceId LOAD COMPLETE: ${url?.toString() ?? widget.url}');
    print(
        '⏱️ WebViewTile #$_instanceId total load time: ${loadTime.inMilliseconds}ms');
    print(
        '🔄 WebViewTile #$_instanceId mounted: $mounted, retries: $_retryAttempts');

    setState(() {
      _isLoading = false;
      // Reset retry counter on successful load
      _retryAttempts = 0;
    }); // Enable ultra-enhanced touch events and focus handling for Home Assistant login
    try {
      await controller.evaluateJavascript(source: """
        (function() {
          'use strict';
          console.log('🚀 Ultra-Enhanced HA Touch Handler - Windows Edition');
          
          let touchStartTarget = null;
          let focusDebounce = new Map();
          
          // Optimized debounce function
          function debounce(func, wait) {
            let timeout;
            return function executedFunction(...args) {
              clearTimeout(timeout);
              timeout = setTimeout(() => func(...args), wait);
            }
          }
          
          // Ultimate Windows keyboard trigger with retry mechanism
          function triggerWindowsVirtualKeyboard(input) {
            if (!input || input.readOnly || input.disabled) return false;
            
            const elementId = input.id || input.name || input.placeholder || 'input';
            const now = Date.now();
            
            // Debounce per element (500ms)
            if (focusDebounce.has(elementId) && now - focusDebounce.get(elementId) < 500) {
              return false;
            }
            focusDebounce.set(elementId, now);
            
            console.log('⌨️ Activating Windows keyboard for:', elementId, input.type);
            
            // Clear existing focus
            if (document.activeElement && document.activeElement !== input) {
              document.activeElement.blur();
            }
            
            // Multi-stage activation
            try {
              input.focus();
              input.click();
              
              // Delayed retry for stubborn fields
              setTimeout(() => {
                input.focus();
                input.dispatchEvent(new FocusEvent('focus', {bubbles: true}));
                input.dispatchEvent(new FocusEvent('focusin', {bubbles: true}));
                
                // MDC component activation
                if (input.classList.contains('mdc-text-field__input')) {
                  const mdcField = input.closest('.mdc-text-field');
                  if (mdcField) {
                    mdcField.classList.add('mdc-text-field--focused');
                    input.dispatchEvent(new Event('input', {bubbles: true}));
                  }
                }
                
                // Home Assistant component events
                const haComponent = input.closest('ha-textfield, paper-input, mwc-textfield');
                if (haComponent) {
                  input.dispatchEvent(new CustomEvent('value-changed', {
                    bubbles: true,
                    detail: {value: input.value}
                  }));
                }
              }, 50);
              
              return true;
            } catch (e) {
              console.warn('Keyboard trigger failed:', e);
              return false;
            }
          }
          
          // Enhanced touch event handlers
          function handleTouchStart(e) {
            touchStartTarget = e.target;
          }
          
          function handleTouchEnd(e) {
            if (!touchStartTarget) return;
            
            e.preventDefault();
            e.stopPropagation();
            
            const touch = e.changedTouches[0];
            const target = document.elementFromPoint(touch.clientX, touch.clientY) || touchStartTarget;
            
            // Direct input handling
            if (target.matches('input, textarea, select')) {
              console.log('📱 Direct touch on input:', target.type, target.name);
              triggerWindowsVirtualKeyboard(target);
            }
            
            // Home Assistant components (shadow DOM support)
            else if (target.closest('ha-textfield, paper-input, mwc-textfield')) {
              const component = target.closest('ha-textfield, paper-input, mwc-textfield');
              let input = component.querySelector('input');
              if (!input && component.shadowRoot) {
                input = component.shadowRoot.querySelector('input');
              }
              if (input) {
                console.log('🏠 HA component touch:', input.type, input.name);
                triggerWindowsVirtualKeyboard(input);
              }
            }
            
            // MDC text fields
            else if (target.closest('.mdc-text-field')) {
              const mdcField = target.closest('.mdc-text-field');
              const input = mdcField.querySelector('input, textarea');
              if (input) {
                console.log('🎯 MDC field touch:', input.type, input.name);
                triggerWindowsVirtualKeyboard(input);
              }
            }
            
            touchStartTarget = null;
          }
          
          // Apply touch event listeners
          document.removeEventListener('touchstart', handleTouchStart);
          document.removeEventListener('touchend', handleTouchEnd);
          document.addEventListener('touchstart', handleTouchStart, {passive: true});
          document.addEventListener('touchend', handleTouchEnd, {passive: false});
          
          // Enhanced click handling for mouse/trackpad users
          document.addEventListener('click', function(e) {
            const target = e.target;
            if (target.matches('input, textarea, select') && 
                ['email', 'password', 'text', 'search', 'url'].includes(target.type)) {
              console.log('🖱️ Click on input:', target.type, target.name);
              setTimeout(() => triggerWindowsVirtualKeyboard(target), 30);
            }
          });
          
          // Ultimate login form detector and enhancer
          const enhanceLoginForm = debounce(function() {
            const selectors = [
              'input[type="email"]', 'input[type="password"]', 'input[type="text"]',
              'input[name*="username"]', 'input[name*="email"]', 'input[name*="password"]',
              'ha-textfield input', 'paper-input input', 'mwc-textfield input',
              '.mdc-text-field__input',
              '[placeholder*="username" i]', '[placeholder*="email" i]', '[placeholder*="password" i]'
            ];
            
            const loginInputs = document.querySelectorAll(selectors.join(', '));
            
            if (loginInputs.length > 0) {
              console.log('🔐 Enhancing', loginInputs.length, 'login inputs');
              
              loginInputs.forEach(input => {
                if (!input.hasAttribute('data-ha-enhanced')) {
                  input.setAttribute('data-ha-enhanced', 'true');
                  
                  // Ultra-aggressive touch enhancement for login fields
                  input.addEventListener('touchstart', function(e) {
                    e.stopPropagation();
                    setTimeout(() => triggerWindowsVirtualKeyboard(this), 10);
                  }, {passive: false});
                  
                  input.addEventListener('click', function(e) {
                    setTimeout(() => triggerWindowsVirtualKeyboard(this), 10);
                  });
                  
                  // Focus event enhancement
                  input.addEventListener('focus', function() {
                    console.log('✅ Login field focused:', this.type, this.name);
                    
                    // Extra MDC activation for stubborn fields
                    if (this.classList.contains('mdc-text-field__input')) {
                      const field = this.closest('.mdc-text-field');
                      if (field) {
                        field.classList.add('mdc-text-field--focused');
                        field.classList.add('mdc-text-field--activated');
                      }
                    }
                  });
                }
              });
            }
          }, 300);
          
          // Apply enhancements immediately and on dynamic content
          enhanceLoginForm();
          setTimeout(enhanceLoginForm, 1000);
          setTimeout(enhanceLoginForm, 3000);
          
          // Watch for dynamic content changes
          if (window.MutationObserver) {
            const observer = new MutationObserver(enhanceLoginForm);
            observer.observe(document.body, {
              childList: true,
              subtree: true,
              attributes: false
            });
          }
          
          // Focus override for Windows compatibility
          const originalFocus = HTMLElement.prototype.focus;
          HTMLElement.prototype.focus = function(options) {
            try {
              originalFocus.call(this, options);
              
              // Ensure input fields get keyboard
              if (this.matches('input, textarea, select')) {
                setTimeout(() => {
                  if (document.activeElement === this) {
                    this.dispatchEvent(new Event('input', {bubbles: true}));
                  }
                }, 100);
              }
            } catch (e) {
              console.warn('Focus override failed:', e);
            }
          };
          
          console.log('✅ Ultra-Enhanced HA Touch Handler initialized successfully');
        })();
      """);
      print("🔧 WebViewTile - Ultra-enhanced touch handling script injected");
    } catch (e) {
      print("⚠️ WebViewTile - Error injecting touch handling script: $e");
    }
  }

  @override
  void onReceivedError(InAppWebViewController controller, URLRequest request,
      WebResourceError error) {
    if (!mounted) {
      print(
          '⚠️ WebViewTile #$_instanceId onReceivedError called but widget not mounted!');
      return;
    }

    print('❌ WebViewTile #$_instanceId ERROR: ${request.url}');
    print('❌ WebViewTile #$_instanceId error type: ${error.type}');
    print(
        '❌ WebViewTile #$_instanceId error description: ${error.description}');
    print(
        '❌ WebViewTile #$_instanceId retry attempt: $_retryAttempts/$MAX_RETRY_ATTEMPTS');

    // Skip retry for resources, only retry main frame errors
    if (error.type == WebResourceErrorType.TIMEOUT ||
        error.type == WebResourceErrorType.HOST_LOOKUP ||
        error.type == WebResourceErrorType.NOT_CONNECTED_TO_INTERNET ||
        error.type == WebResourceErrorType.FAILED_SSL_HANDSHAKE) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = '${error.description}\nURL: ${request.url}';
      });

      // Auto-retry with backoff for connection errors
      print('🔁 WebViewTile #$_instanceId attempting retry with backoff...');
      _retryWithBackoff();
    }
  }

  @override
  void onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {
    // Filter out common, non-critical console messages to reduce noise
    final message = consoleMessage.message;
    final messageLevel = consoleMessage.messageLevel;

    // Skip common framework messages and non-critical warnings
    final skipPatterns = [
      'Lit is in dev mode',
      'lit-html is in dev mode',
      'Download the React DevTools',
      'The above error occurred',
      'Consider adding an error boundary',
      'Failed to load resource: net::ERR_BLOCKED_BY_CLIENT',
      'Violates the following Content Security Policy directive',
      'extensions::SafeBuiltins',
      'chrome-extension://',
      'moz-extension://',
      'safari-extension://',
      '[object Object]', // Generic object logging
      'Warning: componentWillMount has been renamed',
      'Warning: componentWillReceiveProps has been renamed',
      'Warning: componentWillUpdate has been renamed',
    ];

    // Check if message should be skipped
    if (skipPatterns.any((pattern) => message.contains(pattern))) {
      return; // Skip this message
    }

    // Only show errors and important warnings
    if (messageLevel == ConsoleMessageLevel.ERROR) {
      print("❌ WebViewTile Error [${widget.url}]: $message");
    } else if (messageLevel == ConsoleMessageLevel.WARNING &&
        !message.toLowerCase().contains('deprecated') &&
        !message.toLowerCase().contains('favicon')) {
      print("⚠️ WebViewTile Warning [${widget.url}]: $message");
    }
    // Skip INFO, DEBUG, LOG levels unless they contain critical keywords
    else if (message.toLowerCase().contains('error') ||
        message.toLowerCase().contains('failed') ||
        message.toLowerCase().contains('critical')) {
      print("🔧 WebViewTile Important [${widget.url}]: $message");
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    print(
        "🔧 WebViewTile - URL navigating to: ${navigationAction.request.url}");
    // Validate URL before loading
    final url = navigationAction.request.url.toString();
    if (!_validateUrl(url)) {
      print("⚠️ WebViewTile - Blocking navigation to invalid URL: $url");
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  // Validate URL and set _isUrlValid state
  bool _validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        print('⚠️ WebViewTile - Invalid URL format: $url');
        return false;
      }
      return true;
    } catch (e) {
      print('⚠️ WebViewTile - Error parsing URL: $e');
      return false;
    }
  }

  // Retry loading with exponential backoff
  void _retryWithBackoff() {
    if (_retryAttempts >= MAX_RETRY_ATTEMPTS) {
      print('⚠️ WebViewTile - Maximum retry attempts reached');
      setState(() {
        _isRetrying = false;
        _errorMessage =
            'Failed after $_retryAttempts attempts. Please check your connection and try again.';
      });
      return;
    }

    setState(() {
      _isRetrying = true;
      _errorMessage = 'Retrying in ${_getBackoffSeconds()} seconds...';
    });

    // Calculate backoff time based on retry attempt (exponential with jitter)
    final backoffMs = _getBackoffMilliseconds();
    print(
        '🔄 WebViewTile - Retry attempt #${_retryAttempts + 1} with backoff of ${backoffMs}ms');

    Future.delayed(Duration(milliseconds: backoffMs), () {
      if (mounted) {
        _retryAttempts++;
        setState(() {
          _hasError = false;
          _isLoading = true;
          _isRetrying = false;
        });
        _webViewData.safelyExecute((controller) async {
          await controller.reload();
        });
      }
    });
  }

  // Calculate backoff time in milliseconds using exponential backoff with jitter
  int _getBackoffMilliseconds() {
    // Base exponential backoff: 2^attempt * 1000ms (1 second)
    final baseBackoff = (1 << _retryAttempts) * 1000;
    // Add some randomness (jitter) - up to 25% of base value
    final jitter = (baseBackoff *
            0.25 *
            (DateTime.now().millisecondsSinceEpoch % 100) /
            100)
        .round();
    // Return base + jitter, but cap at 30 seconds max
    return (baseBackoff + jitter).clamp(0, 30000);
  }

  // Get human-readable seconds for display
  int _getBackoffSeconds() {
    return (_getBackoffMilliseconds() / 1000).ceil();
  }

  // WidgetsBindingObserver methods for lifecycle debugging
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 WebViewTile #$_instanceId APP LIFECYCLE: $state');
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangePlatformBrightness() {
    print('🔄 WebViewTile #$_instanceId BRIGHTNESS CHANGED');
    super.didChangePlatformBrightness();
  }

  @override
  void didChangeMetrics() {
    print('🔄 WebViewTile #$_instanceId METRICS CHANGED');
    super.didChangeMetrics();
  }
}
