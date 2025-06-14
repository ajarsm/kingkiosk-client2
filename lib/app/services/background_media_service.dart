import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import '../modules/home/controllers/tiling_window_controller.dart';
import '../modules/home/widgets/image_tile.dart';
import './media_recovery_service.dart';

/// Service to handle media playback in the background or fullscreen
class BackgroundMediaService extends GetxService {
  // Singleton player instance for background audio/video
  late Player _player;

  // Observable values
  final isPlaying = false.obs;
  final currentMedia = Rx<String?>(null);
  final mediaType = Rx<String>('none'); // 'none', 'audio', 'video', 'image'

  // Fullscreen controller
  final isFullscreen = false.obs;

  // Image specific properties
  final currentImage = Rx<String?>(null);
  final isImageDisplayed = false.obs;
  // Health check related properties
  Timer? _healthCheckTimer;
  final isHealthy = true.obs;
  final healthCheckIntervalSeconds = 60.obs; // Default: check every minute
  final lastHealthCheckTime = Rx<DateTime?>(null);
  final consecutiveFailures = 0.obs; // Make observable for monitoring
  final recoveryAttemptCount = 0.obs; // Count recovery attempts

  BackgroundMediaService() {
    // Initialize player
    _initializePlayer();

    // Start health check system
    _startHealthChecks();
  }
  void _initializePlayer() {
    // Initialize player
    _player = Player();
    print('New media player instance initialized');
  }

  /// Start periodic health checks for the media player
  void _startHealthChecks() {
    // Cancel any existing timer
    _healthCheckTimer?.cancel();

    // Create a new timer that runs regularly
    _healthCheckTimer = Timer.periodic(
        Duration(seconds: healthCheckIntervalSeconds.value),
        (_) => _performHealthCheck());

    print(
        'Media player health checks started (every ${healthCheckIntervalSeconds.value}s)');
  }

  /// Update health check interval - use this to tune performance vs reliability
  void setHealthCheckInterval(int seconds) {
    if (seconds < 5) seconds = 5; // minimum 5 seconds
    if (seconds > 300) seconds = 300; // maximum 5 minutes

    healthCheckIntervalSeconds.value = seconds;
    _startHealthChecks(); // Restart with new interval

    print('Media health check interval updated to ${seconds}s');
  }

  /// Perform a health check on the media player
  Future<void> _performHealthCheck() async {
    try {
      lastHealthCheckTime.value = DateTime.now();
      // Only check when media is supposed to be playing
      if (!isPlaying.value || currentMedia.value == null) {
        isHealthy.value = true;
        consecutiveFailures.value = 0;
        return;
      }

      // Check if player is in a valid state
      final isPlayerValid = _player.state.playing == isPlaying.value;
      final hasValidPosition = _player.state.position.inMilliseconds > 0 ||
          mediaType.value == 'image';
      // Update health status
      isHealthy.value = isPlayerValid && hasValidPosition;

      // Log status
      print(
          'Media health check: ${isHealthy.value ? "HEALTHY ✅" : "UNHEALTHY ❌"} - ${currentMedia.value}');

      // Handle recovery if needed
      if (!isHealthy.value) {
        consecutiveFailures.value++;
        _handleUnhealthyState();
      } else {
        consecutiveFailures.value = 0;
      }
    } catch (e) {
      print('Error during media health check: $e');
      isHealthy.value = false;
      consecutiveFailures.value++;
      _handleUnhealthyState();
    }
  }

  /// Handle unhealthy player state with progressive recovery
  void _handleUnhealthyState() {
    if (consecutiveFailures.value >= 3) {
      print(
          '⚠️ Critical media failure detected! Attempting emergency recovery...');
      recoveryAttemptCount.value++;

      // Try to find MediaRecoveryService for full reset
      try {
        final recoveryService = Get.find<MediaRecoveryService>();
        recoveryService.resetAllMediaResources();
      } catch (e) {
        print(
            '❌ Could not access MediaRecoveryService, attempting self-recovery');
        _attemptSelfRecovery();
      }

      consecutiveFailures.value = 0;
    } else {
      print(
          '⚠️ Media unhealthy, attempting soft recovery (attempt ${consecutiveFailures.value})');
      _attemptSelfRecovery();
    }
  }

  /// Attempt to recover without full system reset
  Future<void> _attemptSelfRecovery() async {
    try {
      if (currentMedia.value != null) {
        final url = currentMedia.value!;
        final wasPlaying = isPlaying.value;
        final currentType = mediaType.value;

        // Stop and restart
        await stop();
        await Future.delayed(Duration(milliseconds: 500));

        // Attempt to restart if it was playing
        if (wasPlaying && url.isNotEmpty) {
          if (currentType == 'audio') {
            await playAudio(url);
          } else if (currentType == 'video') {
            await playVideo(url);
          }
        }
      }
    } catch (e) {
      print('❌ Self-recovery attempt failed: $e');
    }
  }

  /// Get health data as a structured object for monitoring
  Map<String, dynamic> getHealthData() {
    return {
      'isHealthy': isHealthy.value,
      'lastCheckTime': lastHealthCheckTime.value?.toIso8601String(),
      'checkIntervalSeconds': healthCheckIntervalSeconds.value,
      'consecutiveFailures': consecutiveFailures.value,
      'recoveryAttemptCount': recoveryAttemptCount.value,
      'currentMedia': currentMedia.value,
      'isPlaying': isPlaying.value,
      'mediaType': mediaType.value,
    };
  }

  /// Initialize the service
  Future<BackgroundMediaService> init() async {
    // Start health checks
    _startHealthChecks();
    return this;
  }

  /// Play audio in the background
  Future<void> playAudio(String url, {bool loop = false}) async {
    try {
      await _player.stop();
      await _player.open(Media(url));
      await _player
          .setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'audio';
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  /// Play audio in a windowed tile
  Future<void> playAudioWindowed(String url,
      {bool loop = false, String? title, String? windowId}) async {
    try {
      final controller = Get.find<TilingWindowController>();
      if (windowId != null && windowId.isNotEmpty) {
        controller.addAudioTileWithId(windowId, title ?? 'Kiosk Audio', url);
      } else {
        controller.addAudioTile(title ?? 'Kiosk Audio', url);
      }
      currentMedia.value = url;
      mediaType.value = 'audio';
      isPlaying.value = true;
    } catch (e) {
      print('Error opening audio in window manager: $e');
    }
  }

  /// Play video in the background (no UI)
  Future<void> playVideo(String url, {bool loop = false}) async {
    try {
      await _player.stop();
      await _player.open(Media(url));
      await _player
          .setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'video';
    } catch (e) {
      print('Error playing video: $e');
    }
  }

  /// Play video in a windowed tile managed by the window manager
  Future<void> playVideoWindowed(String url,
      {bool loop = false, String? title, String? windowId}) async {
    try {
      final controller = Get.find<TilingWindowController>();
      if (windowId != null && windowId.isNotEmpty) {
        controller.addMediaTileWithId(windowId, title ?? 'Kiosk Video', url,
            loop: loop);
      } else {
        controller.addMediaTile(title ?? 'Kiosk Video', url, loop: loop);
      }
    } catch (e) {
      print('Error opening video in window manager: $e');
    }
  }

  /// Play video in fullscreen mode
  Future<void> playVideoFullscreen(String url, {bool loop = false}) async {
    try {
      // First stop any current playback
      await stop();

      // Play the video using a fullscreen dialog
      await _player.stop();
      await _player.open(Media(url));
      await _player
          .setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);

      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'video';
      isFullscreen.value = true;

      // Consider implementing a proper fullscreen video player here
      // For now, this just plays the audio/video without visual component
      print('Playing video in fullscreen mode: $url');
    } catch (e) {
      print('Error playing video in fullscreen: $e');
    }
  }

  /// Display an image in fullscreen
  Future<void> displayImageFullscreen(dynamic urlData) async {
    try {
      // Stop any current media playback
      await stop();

      // Extract URLs
      List<String> imageUrls = [];

      if (urlData is String) {
        imageUrls = [urlData];
        currentImage.value = urlData;
      } else if (urlData is List) {
        imageUrls = List<String>.from(urlData.map((url) => url.toString()));
        if (imageUrls.isNotEmpty) {
          currentImage.value = imageUrls[0];
        }
      }

      if (imageUrls.isEmpty) {
        print('❌ No valid image URLs provided');
        return;
      }

      mediaType.value = 'image';
      isImageDisplayed.value = true;
      isFullscreen.value = true;
      // Show fullscreen image dialog
      Get.dialog(
        Dialog.fullscreen(
          child: Stack(
            children: [
              // Image viewer with carousel or single image
              Positioned.fill(
                child: Center(
                  child: imageUrls.length > 1
                      ? ImageTile(
                          url: imageUrls.first,
                          imageUrls: imageUrls,
                          showControls: false,
                        )
                      : Image.network(
                          imageUrls.first,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red, size: 50),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    imageUrls.first,
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Close button
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    closeImage();
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error displaying image fullscreen: $e');
    }
  }

  /// Display an image in a windowed tile
  Future<void> displayImageWindowed(dynamic urlData, {String? title}) async {
    try {
      // Extract URLs
      List<String> imageUrls = [];

      if (urlData is String) {
        imageUrls = [urlData];
      } else if (urlData is List) {
        imageUrls = List<String>.from(urlData.map((url) => url.toString()));
      }

      if (imageUrls.isEmpty) {
        print('❌ No valid image URLs provided for windowed display');
        return;
      }      // Use the tiling window controller to display the image
      final controller = Get.find<TilingWindowController>();
      final id = 'mqtt_image_${DateTime.now().millisecondsSinceEpoch}';
      controller.addImageTileWithId(id, title ?? 'MQTT Image', imageUrls);
      print('Image displayed in window: ${imageUrls.first}');
    } catch (e) {
      print('Error displaying image in window: $e');
    }
  }

  /// Close the currently displayed image
  void closeImage() {
    isImageDisplayed.value = false;
    isFullscreen.value = false;
    currentImage.value = null;
    if (mediaType.value == 'image') {
      mediaType.value = 'none';
    }
  }

  /// Get the player instance directly
  /// This method should be used carefully as it exposes internal state
  /// @returns The current Player instance
  Player? getPlayer() {
    return _player;
  }

  /// Stop current playback
  Future<void> stop() async {
    try {
      // First stop the player to release hardware resources
      await _player.stop();
      isPlaying.value = false;
      currentMedia.value = null;

      // Also clear image if displayed
      if (isImageDisplayed.value) {
        closeImage();
      } else {
        mediaType.value = 'none';
      }

      // Close fullscreen if open
      if (isFullscreen.value) {
        isFullscreen.value = false;
        // Use a try-catch for the Get.back() call to prevent crashes if dialog is already closed
        try {
          Get.back();
        } catch (e) {
          print('Error closing fullscreen dialog: $e');
        }
      }

      // Force resource cleanup after stopping
      await Future.delayed(Duration(milliseconds: 100));
      await _player.dispose(); // Reinitialize player to ensure clean state
      _player = Player();

      print('BackgroundMediaService player disposed and recreated');
    } catch (e) {
      print('Error stopping background media: $e');
    }
  }

  /// Pause current playback
  Future<void> pause() async {
    try {
      // Only pause if actually playing
      if (isPlaying.value) {
        await _player.pause();
        isPlaying.value = false;
        print('Background media paused');
      }
    } catch (e) {
      print('Error pausing background media: $e');
    }
  }

  /// Play/resume current playback
  Future<void> play() async {
    try {
      // Only resume if not already playing
      if (!isPlaying.value && currentMedia.value != null) {
        await _player.play();
        isPlaying.value = true;
        print('Background media resumed');
      }
    } catch (e) {
      print('Error resuming background media: $e');
    }
  }

  /// Seek to a specific position in the current media
  Future<void> seek(Duration position) async {
    try {
      if (currentMedia.value != null) {
        await _player.seek(position);
        print('Background media seeked to $position');
      }
    } catch (e) {
      print('Error seeking background media: $e');
    }
  }
}
