import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../modules/home/controllers/tiling_window_controller.dart';

/// Service to handle media playback in the background or fullscreen
class BackgroundMediaService extends GetxService {
  // Singleton player instance for background audio/video
  late final Player _player;
  late final VideoController _videoController;
  
  // Observable values
  final isPlaying = false.obs;
  final currentMedia = Rx<String?>(null);
  final mediaType = Rx<String>('none'); // 'none', 'audio', 'video'
  
  // Fullscreen controller
  final isFullscreen = false.obs;

  BackgroundMediaService() {
    // Initialize player
    _player = Player();
    _videoController = VideoController(_player);
  }
  
  /// Initialize the service
  Future<BackgroundMediaService> init() async {
    return this;
  }

  /// Play audio in the background
  Future<void> playAudio(String url, {bool loop = false}) async {
    try {
      await _player.stop();
      await _player.open(Media(url));
      await _player.setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'audio';
    } catch (e) {
      print('Error playing audio: $e');
    }
  }
  
  /// Play video in the background (no UI)
  Future<void> playVideo(String url, {bool loop = false}) async {
    try {
      await _player.stop();
      await _player.open(Media(url));
      await _player.setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'video';
    } catch (e) {
      print('Error playing video: $e');
    }
  }
  
  /// Play video in a windowed tile managed by the window manager
  Future<void> playVideoWindowed(String url, {bool loop = false}) async {
    try {
      // Use the window manager to add a media tile
      final controller = Get.find<TilingWindowController>();
      controller.addMediaTile('MQTT Video', url, loop: loop);
    } catch (e) {
      print('Error opening video in window manager: $e');
    }
  }

  /// Play video in fullscreen
  Future<void> playVideoFullscreen(String url, {bool loop = false}) async {
    try {
      await _player.stop();
      await _player.open(Media(url));
      await _player.setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'video';
      isFullscreen.value = true;
      
      // Show fullscreen video dialog
      Get.dialog(
        Dialog.fullscreen(
          child: Stack(
            children: [
              // Video player
              Positioned.fill(
                child: Video(controller: _videoController),
              ),
              
              // Close button
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    isFullscreen.value = false;
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      ).then((_) {
        isFullscreen.value = false;
      });
    } catch (e) {
      print('Error playing video fullscreen: $e');
      isFullscreen.value = false;
    }
  }
  
  /// Pause current playback
  Future<void> pause() async {
    if (isPlaying.value) {
      await _player.pause();
      isPlaying.value = false;
    }
  }
  
  /// Resume current playback
  Future<void> resume() async {
    if (!isPlaying.value && currentMedia.value != null) {
      await _player.play();
      isPlaying.value = true;
    }
  }
  
  /// Stop current playback
  Future<void> stop() async {
    await _player.stop();
    isPlaying.value = false;
    currentMedia.value = null;
    mediaType.value = 'none';
    
    // Close fullscreen if open
    if (isFullscreen.value) {
      isFullscreen.value = false;
      Get.back();
    }
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100);
  }
  
  /// Get current position in seconds
  Future<Duration> getCurrentPosition() async {
    return _player.state.position;
  }
  
  /// Get media duration in seconds
  Future<Duration> getDuration() async {
    return _player.state.duration;
  }
  
  /// Seek to position in seconds
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }
  
  /// Clean up resources
  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}