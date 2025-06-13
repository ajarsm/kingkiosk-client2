// filepath: lib/app/modules/home/controllers/youtube_window_controller_fixed.dart
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import 'web_window_controller.dart';

/// Controller for YouTube windows
/// Extends the WebWindowController with YouTube-specific functionality
class YouTubeWindowController extends WebWindowController {
  // Player state values from the YouTube IFrame API
  static const int UNSTARTED = -1;
  static const int ENDED = 0;
  static const int PLAYING = 1;
  static const int PAUSED = 2;
  static const int BUFFERING = 3;
  static const int CUED = 5;

  // Observable properties for YouTube-specific functionality
  final RxInt playerState = (-1).obs; // -1 = unstarted
  final RxDouble volume = 100.0.obs;
  final RxBool isMuted = false.obs;
  final RxBool isReady = false.obs;
  final RxString videoId = ''.obs;
  final RxString videoTitle = ''.obs;
  final RxInt videoDuration = 0.obs;
  final RxInt currentTime = 0.obs;
  final RxBool isFullscreen = false.obs;

  // Timer for updating current time
  Timer? _timeUpdateTimer;
  bool _isDisposed = false;

  YouTubeWindowController({
    required String windowName,
    required InAppWebViewController webViewController,
    void Function()? onClose,
    String? initialVideoId,
  }) : super(
          windowName: windowName,
          webViewController: webViewController,
          onClose: onClose,
        ) {
    if (initialVideoId != null && initialVideoId.isNotEmpty) {
      videoId.value = initialVideoId;
    }

    // Setup YouTube event handlers
    _setupYouTubeEventHandlers();

    print(
        '🎬 YouTubeWindowController initialized for window: $windowName, videoId: ${videoId.value}');
  }

  // Setup YouTube event handlers
  void _setupYouTubeEventHandlers() {
    try {
      webViewController.addJavaScriptHandler(
        handlerName: 'onPlayerReady',
        callback: (args) {
          isReady.value = true;
          print('🎬 YouTube player ready event in controller for: $windowName');

          // Get initial video info
          _updateVideoInfo();
        },
      );

      webViewController.addJavaScriptHandler(
        handlerName: 'onPlayerStateChange',
        callback: (args) {
          if (args.isNotEmpty) {
            final newState = args.first as int;
            playerState.value = newState;

            // Update current time if playing
            if (newState == PLAYING) {
              _startTimeUpdates();
            } else {
              _stopTimeUpdates();
            }

            print(
                '🎬 YouTube player state changed to $newState for: $windowName');
          }
        },
      );

      webViewController.addJavaScriptHandler(
        handlerName: 'onPlayerError',
        callback: (args) {
          final errorCode = args.isNotEmpty ? args.first : null;
          print('⚠️ YouTube player error $errorCode for: $windowName');
        },
      );
    } catch (e) {
      print('⚠️ Error setting up YouTube event handlers: $e');
    }
  }

  // Play the video
  void play() {
    webViewController.evaluateJavascript(source: 'playVideo()');
  }

  // Pause the video
  void pause() {
    webViewController.evaluateJavascript(source: 'pauseVideo()');
  }

  // Stop the video
  void stop() {
    webViewController.evaluateJavascript(source: 'stopVideo()');
  }

  // Seek to a specific position (in seconds)
  void seekTo(int seconds, {bool allowSeekAhead = true}) {
    webViewController.evaluateJavascript(
        source: 'seekTo($seconds, ${allowSeekAhead ? 'true' : 'false'})');
  }

  // Set the volume (0-100)
  void setVolume(int volumeLevel) {
    webViewController.evaluateJavascript(source: 'setVolume($volumeLevel)');
    volume.value = volumeLevel.toDouble();
  }

  // Mute the video
  void mute() {
    webViewController.evaluateJavascript(source: 'mute()');
    isMuted.value = true;
  }

  // Unmute the video
  void unmute() {
    webViewController.evaluateJavascript(source: 'unMute()');
    isMuted.value = false;
  }

  // Load a different video
  void loadVideo(String videoId) {
    webViewController.evaluateJavascript(source: 'loadVideoById("$videoId")');
    this.videoId.value = videoId;
  }

  // Start periodic time updates when video is playing
  void _startTimeUpdates() {
    _stopTimeUpdates(); // Stop any existing timer

    _timeUpdateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      // Check if controller is disposed
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      _updateCurrentTime();

      // Stop timer if not playing
      if (playerState.value != PLAYING) {
        timer.cancel();
        _timeUpdateTimer = null;
      }
    });
  }

  // Stop periodic time updates
  void _stopTimeUpdates() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = null;
  }

  // Update video information (title, duration, etc.)
  Future<void> _updateVideoInfo() async {
    try {
      // Get video duration
      final durationResult = await webViewController.evaluateJavascript(
          source: 'player.getDuration ? player.getDuration() : 0');
      if (durationResult != null) {
        videoDuration.value = (durationResult as num).toInt();
      }

      // Get video title
      final titleResult = await webViewController.evaluateJavascript(
          source: 'player.getVideoData ? player.getVideoData().title : ""');
      if (titleResult != null && titleResult is String) {
        videoTitle.value = titleResult;
      }
    } catch (e) {
      print('⚠️ Error updating video info: $e');
    }
  }

  // Update current playback time
  Future<void> _updateCurrentTime() async {
    if (_isDisposed) return; // Don't update if disposed

    try {
      final timeResult = await webViewController.evaluateJavascript(
          source: 'player.getCurrentTime ? player.getCurrentTime() : 0');
      if (timeResult != null && !_isDisposed) {
        currentTime.value = (timeResult as num).toInt();
      }
    } catch (e) {
      if (!_isDisposed) {
        print('⚠️ Error updating current time: $e');
      }
    }
  }

  // Extracts the YouTube video ID from a URL
  static String? extractYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );

    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Override onClose to ensure proper cleanup
  @override
  void disposeWindow() {
    _isDisposed = true;
    _stopTimeUpdates();
    super.disposeWindow();
  }

  // Factory method to create and register a YouTube window controller
  static YouTubeWindowController create({
    required String windowName,
    required InAppWebViewController webViewController,
    void Function()? onClose,
    String? videoId,
  }) {
    final controller = YouTubeWindowController(
      windowName: windowName,
      webViewController: webViewController,
      onClose: onClose,
      initialVideoId: videoId,
    );

    // Register with window manager
    final windowManager = Get.find<WindowManagerService>();
    windowManager.registerWindow(controller);

    return controller;
  }
}
