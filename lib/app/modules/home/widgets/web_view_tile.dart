import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  /// Get platform-appropriate user agent string
  static String getPlatformUserAgent() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      // Windows Edge user agent for better compatibility with modern web apps
      return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0";
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      // macOS Safari user agent
      return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15";
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      // Linux Chrome user agent
      return "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    } else {
      // Default fallback
      return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    }
  }

  /// Get platform-specific WebView settings
  static InAppWebViewSettings getPlatformWebViewSettings() {
    // Platform-specific settings for optimal compatibility
    if (defaultTargetPlatform == TargetPlatform.windows) {      // Windows WebView2-specific settings for better Home Assistant compatibility
      return InAppWebViewSettings(
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
        userAgent: getPlatformUserAgent(),
        useOnDownloadStart: true,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptAjaxRequest: true,
        useShouldInterceptFetchRequest: true,
        clearCache: false,
        preferredContentMode: UserPreferredContentMode.RECOMMENDED,
        incognito: false,
        cacheEnabled: true,
        // Windows-specific optimizations for focus and touch handling
        hardwareAcceleration: true,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        // Enhanced focus and input handling for Windows
        allowsAirPlayForMediaPlayback: false,
        allowsPictureInPictureMediaPlayback: false,
        isFraudulentWebsiteWarningEnabled: false,
        selectionGranularity: SelectionGranularity.CHARACTER,        // Ensure proper touch and click handling
        disallowOverScroll: false,
        enableViewportScale: true,
        suppressesIncrementalRendering: false,
        isTextInteractionEnabled: true,
      );
    } else {
      // Default settings for other platforms
      return InAppWebViewSettings(
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
        userAgent: getPlatformUserAgent(),
        useOnDownloadStart: true,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptAjaxRequest: true,
        useShouldInterceptFetchRequest: true,
        clearCache: false,
        preferredContentMode: UserPreferredContentMode.RECOMMENDED,
        incognito: false,
        cacheEnabled: true,
      );
    }
  }

  // Create or get an existing WebView instance
  InAppWebView getOrCreateWebView({
    required String id,
    required String url,
    required ValueKey<String> key,
    required WebViewCallbackHandler callbackHandler,
  }) {
    if (!_instances.containsKey(id)) {
      print(
          '📌 WebViewInstanceManager: Creating new WebView for ID: $id and URL: $url');
      _instances[id] = _WebViewWrapper(
        id: id,
        url: url,
        key: key,
        callbackHandler: callbackHandler,
      );
    } else {
      print('📌 WebViewInstanceManager: Reusing WebView for ID: $id');
      // Update the callback handler to ensure it's using the current state
      _instances[id]!.updateCallbackHandler(callbackHandler);
    }
    return _instances[id]!.webView;
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
      initialSettings: WebViewInstanceManager.getPlatformWebViewSettings(),
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
    // Pass this class instance as the callback handler
    final String instanceKey = widget.windowId ?? widget.url;
    _stableWebViewWidget = WebViewInstanceManager().getOrCreateWebView(
      id: instanceKey,
      url: widget.url,
      key: _stableWebViewKey,
      callbackHandler: this,
    );

    print(
        '📌 WebViewTile - Created stable WebView widget with key: $_stableWebViewKey');
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
                if (_isRetrying)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
    print(
        '🔧 WebViewTile - Load started for URL: ${url?.toString() ?? widget.url}');
    setState(() {
      _isLoading = true;
    });
  }

  @override
  void onLoadStop(InAppWebViewController controller, WebUri? url) async {
    print(
        '🔧 WebViewTile - Load completed for URL: ${url?.toString() ?? widget.url}');
    setState(() {
      _isLoading = false;
    });    // Enable touch events on WebView content with reduced logging
    try {
      await controller.evaluateJavascript(source: """
        (function() {
          console.log('🔧 Initializing Windows WebView touch handling');
          
          // Debouncing for reduced console spam
          let lastLogTime = 0;
          function dLog(message, force = false) {
            const now = Date.now();
            if (force || now - lastLogTime > 1000) { // Log max once per second
              console.log(message);
              lastLogTime = now;
            }
          }
          
          // Global touch handling state
          let touchStartTarget = null;
          let isDragging = false;
          let processingTouch = false;
          
          // Enhanced touch to click conversion
          function handleTouchStart(e) {
            if (processingTouch) return;
            
            touchStartTarget = e.target;
            isDragging = false;
            
            // Immediate focus for inputs
            if (e.target.matches('input, textarea, select')) {
              e.target.focus();
              dLog('📝 Input focused: ' + e.target.type);
            }
          }
          
          function handleTouchMove(e) {
            if (touchStartTarget) {
              isDragging = true;
            }
          }
          
          function handleTouchEnd(e) {
            if (!touchStartTarget || isDragging || processingTouch) {
              touchStartTarget = null;
              return;
            }
            
            processingTouch = true;
            e.preventDefault();
            e.stopPropagation();
            
            const touch = e.changedTouches[0];
            const target = document.elementFromPoint(touch.clientX, touch.clientY) || touchStartTarget;
            
            // Windows-specific input focus enhancement
            if (target.matches('input, textarea, select')) {
              focusInputWithWindowsEnhancement(target);
            } else {
              // Regular click simulation for non-inputs
              target.dispatchEvent(new MouseEvent('click', {
                bubbles: true,
                cancelable: true,
                clientX: touch.clientX,
                clientY: touch.clientY
              }));
            }
            
            // Handle Home Assistant components
            handleHomeAssistantComponents(target);
            
            touchStartTarget = null;
            setTimeout(() => { processingTouch = false; }, 100);
          }
          
          // Windows-specific input focus with virtual keyboard triggers
          function focusInputWithWindowsEnhancement(input) {
            dLog('🪟 Enhancing input focus for Windows');
            
            // Clear existing focus
            if (document.activeElement && document.activeElement !== input) {
              document.activeElement.blur();
            }
            
            // Primary focus methods
            input.focus();
            input.click();
            
            // WebView2 specific enhancements
            if (window.chrome && window.chrome.webview) {
              try {
                input.focus({ preventScroll: false });
              } catch (e) {}
            }
            
            // Force cursor position for text inputs
            if (input.setSelectionRange && input.type !== 'password') {
              const len = input.value.length;
              input.setSelectionRange(len, len);
            }
            
            // Virtual keyboard triggers
            input.setAttribute('inputmode', 'text');
            input.setAttribute('autocomplete', 'on');
            
            // Windows touch simulation for virtual keyboard
            const rect = input.getBoundingClientRect();
            const touchEvent = new TouchEvent('touchstart', {
              bubbles: true,
              cancelable: true,
              touches: [{
                identifier: 1,
                target: input,
                clientX: rect.left + rect.width / 2,
                clientY: rect.top + rect.height / 2
              }]
            });
            input.dispatchEvent(touchEvent);
            
            // Focus verification and retry
            setTimeout(() => {
              if (document.activeElement !== input) {
                input.focus();
                input.click();
                dLog('🔄 Focus retry applied');
              }
            }, 100);
          }
          
          // Handle Home Assistant and MDC components
          function handleHomeAssistantComponents(target) {
            // MDC text field handling
            if (target.classList.contains('mdc-text-field__input') || target.closest('.mdc-text-field')) {
              const mdcField = target.closest('.mdc-text-field');
              const actualInput = target.matches('input') ? target : target.querySelector('input');
              
              if (actualInput && mdcField) {
                mdcField.classList.add('mdc-text-field--focused');
                actualInput.focus();
                actualInput.dispatchEvent(new Event('input', {bubbles: true}));
                dLog('🎯 MDC text field activated');
              }
            }
            
            // Home Assistant web components
            if (target.matches('ha-textfield, paper-input, mwc-textfield')) {
              let input = target.querySelector('input');
              if (!input && target.shadowRoot) {
                input = target.shadowRoot.querySelector('input');
              }
              
              if (input) {
                focusInputWithWindowsEnhancement(input);
                dLog('🏠 HA component input focused');
              }
            }
          }
          
          // Apply touch handling to interactive elements
          function applyTouchHandling(root = document) {
            const interactiveSelectors = [
              'input', 'textarea', 'select', 'button', 'a',
              '[role="button"]', '[onclick]',
              'ha-textfield', 'paper-input', 'mwc-textfield',
              '.mdc-text-field', '.mdc-button',
              '[name="username"]', '[name="password"]', '[type="email"]', '[type="password"]'
            ];
            
            const elements = root.querySelectorAll(interactiveSelectors.join(', '));
            
            elements.forEach(el => {
              if (!el.hasAttribute('data-touch-enhanced')) {
                el.setAttribute('data-touch-enhanced', 'true');
                el.style.touchAction = 'manipulation';
                
                if (el.matches('input, textarea, select')) {
                  el.addEventListener('touchstart', function(e) {
                    e.stopPropagation();
                    focusInputWithWindowsEnhancement(this);
                  }, {passive: false});
                }
              }
            });
            
            dLog('✅ Touch handling applied to ' + elements.length + ' elements', true);
          }
          
          // Enhanced focus override for all inputs
          const originalFocus = HTMLElement.prototype.focus;
          HTMLElement.prototype.focus = function(options) {
            if (this.matches('input, textarea')) {
              originalFocus.call(this, options);
              
              // Windows virtual keyboard enhancement
              if (window.chrome && window.chrome.webview) {
                try {
                  this.focus({ preventScroll: false });
                } catch (e) {}
              }
              
              // Ensure visibility
              this.scrollIntoView({ behavior: 'smooth', block: 'center' });
            } else {
              originalFocus.call(this, options);
            }
          };
          
          // Setup touch listeners
          document.addEventListener('touchstart', handleTouchStart, {passive: false});
          document.addEventListener('touchmove', handleTouchMove, {passive: false});
          document.addEventListener('touchend', handleTouchEnd, {passive: false});
          
          // Initial application
          applyTouchHandling();
          
          // Watch for dynamic content with reduced frequency
          if (window.MutationObserver) {
            const observer = new MutationObserver(function(mutations) {
              let hasNewInputs = false;
              mutations.forEach(function(mutation) {
                if (mutation.addedNodes.length > 0) {
                  mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1 && node.matches && 
                        node.matches('input, textarea, ha-textfield, paper-input, mwc-textfield, .mdc-text-field')) {
                      hasNewInputs = true;
                    }
                  });
                }
              });
              
              if (hasNewInputs) {
                setTimeout(() => applyTouchHandling(), 500);
              }
            });
            
            observer.observe(document.body, {
              childList: true,
              subtree: true
            });
          }
          
          dLog('🔧 Windows WebView touch handling initialized', true);
        })();
                          pageY: centerY
                        }]
                      })
                    ];
                    
                    events.forEach((event, index) => {
                      setTimeout(() => this.dispatchEvent(event), index * 10);
                    });
                  };
                  
                  // Execute focus sequence with retries
                  focusSequence();
                  setTimeout(focusSequence, 100);
                  setTimeout(focusSequence, 250);
                  
                  // Comprehensive event dispatch
                  const eventTypes = ['focus', 'focusin', 'input', 'click'];
                  eventTypes.forEach((eventType, index) => {
                    setTimeout(() => {
                      if (eventType === 'focus' || eventType === 'focusin') {
                        this.dispatchEvent(new FocusEvent(eventType, {bubbles: true}));
                      } else {
                        this.dispatchEvent(new Event(eventType, {bubbles: true}));
                      }
                    }, index * 25);
                  });
                  
                  // Try custom HA events
                  try {
                    this.dispatchEvent(new CustomEvent('ha-focus', {bubbles: true}));
                    this.dispatchEvent(new CustomEvent('value-changed', {bubbles: true, detail: {value: this.value}}));
                  } catch (e) {}
                  
                }, {passive: false});
                
                // Also enhance click events
                actualInput.addEventListener('click', function(e) {
                  console.log('🔐 Login input clicked!');
                  this.focus();
                  this.dispatchEvent(new FocusEvent('focus', {bubbles: true}));
                  this.dispatchEvent(new FocusEvent('focusin', {bubbles: true}));
                });
                
                // Mark as enhanced
                actualInput.setAttribute('data-login-enhanced', 'true');
              });
            }
          }
          
          // Apply login enhancement immediately and on DOM changes
          enhanceHALoginForm();
          setTimeout(enhanceHALoginForm, 1000);
          setTimeout(enhanceHALoginForm, 3000);
          setTimeout(enhanceHALoginForm, 5000);
          
          console.log('🎉 Ultra-enhanced touch handling initialization complete');
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
    print(
        '⚠️ WebViewTile - Error loading URL: ${request.url}, Error: ${error.description}');
    setState(() {
      _hasError = true;
      _isLoading = false;
      _errorMessage = error.description;
    });

    // Retry with backoff
    _retryWithBackoff();
  }

  @override
  void onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {
    print("🔧 WebViewTile Console [${widget.url}]: ${consoleMessage.message}");
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    print(
        "🔧 WebViewTile - URL navigating to: ${navigationAction.request.url}");
    return NavigationActionPolicy.ALLOW;
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
}
