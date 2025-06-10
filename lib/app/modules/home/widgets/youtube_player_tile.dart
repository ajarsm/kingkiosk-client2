import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'web_view_tile.dart'; // For WebViewCallbackHandler
import '../../../services/window_manager_service.dart';
import '../controllers/youtube_window_controller.dart';
import '../controllers/youtube_player_tile_controller.dart';

/// YouTube Player Tile Manager to manage YouTube player instances across rebuilds
class YouTubePlayerManager {
  static final YouTubePlayerManager _instance =
      YouTubePlayerManager._internal();

  factory YouTubePlayerManager() => _instance;

  YouTubePlayerManager._internal();

  // Map of window IDs to their stable YouTubePlayerTile instances
  final Map<String, YouTubePlayerTile> _youtubeTiles = {};

  /// Get a stable YouTubePlayerTile instance for a given window ID and video URL
  YouTubePlayerTile getYouTubePlayerTileFor(
      String windowId, String videoUrl, String videoId,
      {int? refreshKey,
      bool autoplay = true,
      bool showControls = true,
      bool showInfo = true}) {
    if (!_youtubeTiles.containsKey(windowId)) {
      print(
          '🎬 YouTubePlayerManager - Creating new player for windowId: $windowId, videoId: $videoId');
      _youtubeTiles[windowId] = YouTubePlayerTile(
        key: ValueKey('youtube_player_$windowId'),
        videoUrl: videoUrl,
        videoId: videoId,
        windowId: windowId,
        refreshKey: refreshKey,
        autoplay: autoplay,
        showControls: showControls,
        showInfo: showInfo,
      );
    } else if (refreshKey != null) {
      // If refreshKey is provided or videoUrl changed, update the instance
      final existingTile = _youtubeTiles[windowId]!;
      if (existingTile.videoUrl != videoUrl ||
          existingTile.refreshKey != refreshKey) {
        print(
            '🎬 YouTubePlayerManager - Updating player for windowId: $windowId');
        _youtubeTiles[windowId] = YouTubePlayerTile(
          key: ValueKey('youtube_player_$windowId'),
          videoUrl: videoUrl,
          videoId: videoId,
          windowId: windowId,
          refreshKey: refreshKey,
          autoplay: autoplay,
          showControls: showControls,
          showInfo: showInfo,
        );
      }
    }

    print('🎬 YouTubePlayerManager - Returning player for windowId: $windowId');
    return _youtubeTiles[windowId]!;
  }

  /// Remove a YouTube player when its window is closed
  void removeYouTubePlayer(String windowId) {
    if (_youtubeTiles.containsKey(windowId)) {
      print(
          '🎬 YouTubePlayerManager - Removing player for windowId: $windowId');
      _youtubeTiles.remove(windowId);

      // Clean up the WebView instance
      try {
        WebViewInstanceManager().removeWebView(windowId);
      } catch (e) {
        print('⚠️ YouTubePlayerManager - Error cleaning up resources: $e');
      }
    }
  }

  /// Extract YouTube video ID from any YouTube URL format
  static String? extractVideoId(String url) {
    // Handle various YouTube URL formats
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );

    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }
}

/// YouTubePlayerTile widget
/// A specialized WebViewTile for YouTube videos using the IFrame API
class YouTubePlayerTile extends GetView<YouTubePlayerTileController> {
  final String videoUrl;
  final String videoId;
  final String windowId;
  final int? refreshKey;
  final bool autoplay;
  final bool showControls;
  final bool showInfo;

  const YouTubePlayerTile({
    Key? key,
    required this.videoUrl,
    required this.videoId,
    required this.windowId,
    this.refreshKey,
    this.autoplay = true,
    this.showControls = true,
    this.showInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(
        YouTubePlayerTileController(
          videoUrl: videoUrl,
          videoId: videoId,
          windowId: windowId,
          refreshKey: refreshKey,
          autoplay: autoplay,
          showControls: showControls,
          showInfo: showInfo,
        ),
        tag: windowId);

    return Obx(() => _YouTubePlayerView(
          controller: controller,
          videoUrl: videoUrl,
          videoId: videoId,
          windowId: windowId,
          refreshKey: refreshKey,
          autoplay: autoplay,
          showControls: showControls,
          showInfo: showInfo,
        ));
  }
}

class _YouTubePlayerView extends StatefulWidget {
  final YouTubePlayerTileController controller;
  final String videoUrl;
  final String videoId;
  final String windowId;
  final int? refreshKey;
  final bool autoplay;
  final bool showControls;
  final bool showInfo;

  const _YouTubePlayerView({
    Key? key,
    required this.controller,
    required this.videoUrl,
    required this.videoId,
    required this.windowId,
    this.refreshKey,
    this.autoplay = true,
    this.showControls = true,
    this.showInfo = true,
  }) : super(key: key);

  @override
  State<_YouTubePlayerView> createState() => _YouTubePlayerViewState();
}

class _YouTubePlayerViewState extends State<_YouTubePlayerView>
    implements WebViewCallbackHandler {
  late final InAppWebViewController _controller;

  // Create HTML content with YouTube IFrame API
  String get _youtubeHtml {
    // Set player parameters based on widget properties
    final playerVars = {
      'autoplay': widget.autoplay ? 1 : 0,
      'controls': widget.showControls ? 1 : 0,
      'showinfo': widget.showInfo ? 1 : 0,
      'rel': 0, // Don't show related videos
      'modestbranding': 1, // Minimal YouTube branding
      'enablejsapi': 1, // Enable JavaScript API
    };

    final playerVarsJson =
        playerVars.entries.map((e) => "'${e.key}': ${e.value}").join(', ');

    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html {
              margin: 0;
              padding: 0;
              width: 100%;
              height: 100%;
              overflow: hidden;
              background-color: #000;
            }
            #player {
              width: 100%;
              height: 100%;
            }
          </style>
        </head>
        <body>
          <div id="player"></div>
          
          <script>
            // 1. Load the IFrame Player API code asynchronously
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
            
            // 2. This function creates an <iframe> (and YouTube player) after the API code downloads
            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '${widget.videoId}',
                playerVars: {
                  ${playerVarsJson}
                },
                events: {
                  'onReady': onPlayerReady,
                  'onStateChange': onPlayerStateChange,
                  'onError': onPlayerError
                }
              });
            }
            
            // 3. API will call this function when the video player is ready
            function onPlayerReady(event) {
              console.log("YouTube player ready");
              window.flutter_inappwebview.callHandler('onPlayerReady');
            }
            
            // 4. API calls this function when the player's state changes
            function onPlayerStateChange(event) {
              // Send player state to Flutter
              // States: -1 (unstarted), 0 (ended), 1 (playing), 2 (paused), 3 (buffering), 5 (video cued)
              window.flutter_inappwebview.callHandler('onPlayerStateChange', event.data);
            }
            
            // 5. Handle errors
            function onPlayerError(event) {
              console.error("YouTube player error:", event.data);
              window.flutter_inappwebview.callHandler('onPlayerError', event.data);
            }
            
            // 6. Expose player control functions that can be called from Flutter
            function playVideo() {
              if (player && player.playVideo) player.playVideo();
            }
            
            function pauseVideo() {
              if (player && player.pauseVideo) player.pauseVideo();
            }
            
            function stopVideo() {
              if (player && player.stopVideo) player.stopVideo();
            }
            
            function seekTo(seconds, allowSeekAhead) {
              if (player && player.seekTo) player.seekTo(seconds, allowSeekAhead);
            }
            
            function setVolume(volume) {
              if (player && player.setVolume) player.setVolume(volume);
            }
            
            function mute() {
              if (player && player.mute) player.mute();
            }
            
            function unMute() {
              if (player && player.unMute) player.unMute();
            }
            
            function loadVideoById(videoId) {
              if (player && player.loadVideoById) player.loadVideoById(videoId);
            }
          </script>
        </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          key: ValueKey(
              'youtube_webview_${widget.windowId}_${widget.refreshKey}'),
          initialData: InAppWebViewInitialData(data: _youtubeHtml),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            transparentBackground: true,
            useHybridComposition: true,
            supportZoom: false,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            onWebViewCreated(controller, widget.windowId);

            // Register JavaScript handlers for communication
            controller.addJavaScriptHandler(
              handlerName: 'onPlayerReady',
              callback: (args) {
                widget.controller.setLoading(false);
                print(
                    '🎬 YouTube player ready for windowId: ${widget.windowId}');

                // Register this player with the window manager if available
                try {
                  final windowManager = Get.find<WindowManagerService>();
                  final existingController =
                      windowManager.getWindow(widget.windowId);

                  if (existingController == null) {
                    // Create a new YouTube window controller with the widget ID
                    YouTubeWindowController.create(
                      windowName: widget.windowId,
                      webViewController: controller,
                      videoId: widget.videoId,
                    );
                    print(
                        '🎬 Created new YouTubeWindowController for windowId: ${widget.windowId}');
                  }
                } catch (e) {
                  print(
                      '⚠️ Could not register YouTube player with WindowManager: $e');
                }
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'onPlayerStateChange',
              callback: (args) {
                final state = args.isNotEmpty ? args.first : null;
                print(
                    '🎬 YouTube player state changed to $state for windowId: ${widget.windowId}');
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'onPlayerError',
              callback: (args) {
                final errorCode = args.isNotEmpty ? args.first : null;
                print(
                    '⚠️ YouTube player error $errorCode for windowId: ${widget.windowId}');
              },
            );
          },
          onLoadStop: (controller, url) {
            onLoadStop(controller, url);
          },
          onConsoleMessage: (controller, consoleMessage) {
            print('🎬 YouTube console: ${consoleMessage.message}');
          },
          onReceivedServerTrustAuthRequest: (controller, challenge) async {
            print(
                '🔒 YouTube player - Received SSL certificate challenge, proceeding anyway');
            return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED);
          },
        ),
        if (widget.controller.isLoading.value)
          Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  // Call JavaScript functions to control the YouTube player
  void play() => _controller.evaluateJavascript(source: 'playVideo()');
  void pause() => _controller.evaluateJavascript(source: 'pauseVideo()');
  void stop() => _controller.evaluateJavascript(source: 'stopVideo()');
  void seekTo(int seconds, {bool allowSeekAhead = true}) =>
      _controller.evaluateJavascript(
          source: 'seekTo($seconds, ${allowSeekAhead ? 'true' : 'false'})');
  void setVolume(int volume) =>
      _controller.evaluateJavascript(source: 'setVolume($volume)');
  void mute() => _controller.evaluateJavascript(source: 'mute()');
  void unmute() => _controller.evaluateJavascript(source: 'unMute()');
  void loadVideo(String videoId) =>
      _controller.evaluateJavascript(source: 'loadVideoById("$videoId")');

  // WebViewCallbackHandler implementation
  @override
  void onWebViewCreated(InAppWebViewController controller, String id) {
    print('🎬 YouTube WebView created for windowId: $id');
  }

  @override
  void onLoadStart(InAppWebViewController controller, WebUri? url) {
    print('🎬 YouTube WebView load started for windowId: ${widget.windowId}');
  }

  @override
  void onLoadStop(InAppWebViewController controller, WebUri? url) {
    print('🎬 YouTube WebView load completed for windowId: ${widget.windowId}');
  }

  @override
  void onReceivedError(InAppWebViewController controller, URLRequest request,
      WebResourceError error) {
    print(
        '⚠️ YouTube WebView error: ${error.description} for windowId: ${widget.windowId}');

    // Show error UI for main frame errors only (not resource errors)
    // Only use error types that are guaranteed to exist in this version
    if (error.type == WebResourceErrorType.TIMEOUT ||
        error.type == WebResourceErrorType.HOST_LOOKUP ||
        error.type == WebResourceErrorType.FAILED_SSL_HANDSHAKE) {
      widget.controller.setLoading(false);
    }
  }

  @override
  void onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage consoleMessage) {
    // Console messages are handled in the main onConsoleMessage callback
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  }
}
