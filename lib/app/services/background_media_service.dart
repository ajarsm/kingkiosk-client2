import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../modules/home/controllers/tiling_window_controller.dart';
import '../modules/home/widgets/image_tile.dart';

/// Service to handle media playback in the background or fullscreen
class BackgroundMediaService extends GetxService {
  // Singleton player instance for background audio/video
  late final Player _player;
  late final VideoController _videoController;
  
  // Observable values
  final isPlaying = false.obs;
  final currentMedia = Rx<String?>(null);
  final mediaType = Rx<String>('none'); // 'none', 'audio', 'video', 'image'
  
  // Fullscreen controller
  final isFullscreen = false.obs;
  
  // Image specific properties
  final currentImage = Rx<String?>(null);
  final isImageDisplayed = false.obs;

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
  
  /// Play audio in a windowed tile 
  Future<void> playAudioWindowed(String url, {bool loop = false, String? title, String? windowId}) async {
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
      await _player.setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
      isPlaying.value = true;
      currentMedia.value = url;
      mediaType.value = 'video';
    } catch (e) {
      print('Error playing video: $e');
    }
  }
  
  /// Play video in a windowed tile managed by the window manager
  Future<void> playVideoWindowed(String url, {bool loop = false, String? title, String? windowId}) async {
    try {
      final controller = Get.find<TilingWindowController>();
      if (windowId != null && windowId.isNotEmpty) {
        controller.addMediaTileWithId(windowId, title ?? 'Kiosk Video', url, loop: loop);
      } else {
        controller.addMediaTile(title ?? 'Kiosk Video', url, loop: loop);
      }
    } catch (e) {
      print('Error opening video in window manager: $e');
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
                                value: loadingProgress.expectedTotalBytes != null
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
                                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    imageUrls.first,
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    closeImage();
                    Get.back();
                  },
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black,
        ),
        barrierDismissible: false,
      ).then((_) {
        closeImage();
      });
    } catch (e) {
      print('Error displaying image fullscreen: $e');
      closeImage();
    }
  }
  
  /// Display an image in a windowed tile
  Future<void> displayImageWindowed(dynamic urlData, {String? title}) async {
    try {
      final controller = Get.find<TilingWindowController>();
      controller.addImageTile(title ?? 'Kiosk Image', urlData);
      
      // Store the primary URL in our service state
      String primaryUrl;
      if (urlData is String) {
        primaryUrl = urlData;
      } else if (urlData is List && urlData.isNotEmpty) {
        primaryUrl = urlData[0].toString();
      } else {
        primaryUrl = 'Invalid URL';
      }
      
      currentImage.value = primaryUrl;
      mediaType.value = 'image';
      isImageDisplayed.value = true;
    } catch (e) {
      print('Error opening image in window manager: $e');
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
    
    // Also clear image if displayed
    if (isImageDisplayed.value) {
      closeImage();
    } else {
      mediaType.value = 'none';
    }
    
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