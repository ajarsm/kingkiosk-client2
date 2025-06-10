import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../widgets/media_tile.dart';
import '../../../services/media_hardware_detection.dart';

/// Controller for MediaTile to replace StatefulWidget state management
class MediaTileController extends GetxController with WidgetsBindingObserver {
  final String url;
  final bool loop;

  // Reactive state variables
  final isInitialized = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final position = Duration.zero.obs;

  late final PlayerWithController _playerData;

  MediaTileController({
    required this.url,
    this.loop = false,
  });

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycleChange(state);
  }

  /// Initialize the media player with reactive updates
  Future<void> _initializePlayer() async {
    try {
      _playerData = MediaPlayerManager().getPlayerFor(url);

      if (_playerData.isInitialized) {
        // If already initialized, just update our state reactively
        isInitialized.value = true;
        return;
      }

      // Set up position listener
      _playerData.player.streams.position.listen((pos) {
        position.value = pos;
      });

      // Open media
      await _playerData.player.open(Media(url));

      // Set playlist mode
      try {
        if (loop) {
          await _playerData.player.setPlaylistMode(PlaylistMode.loop);
        } else {
          await _playerData.player.setPlaylistMode(PlaylistMode.none);
        }
      } catch (e) {
        print('Warning: Could not set playlist mode: $e');
        // Continue anyway
      }

      // Mark as initialized
      _playerData.isInitialized = true;
      isInitialized.value = true; // Reactive update
    } catch (error) {
      print('Error initializing video player: $error');

      // Report error to hardware detection service
      try {
        final hardwareDetectionService =
            Get.find<MediaHardwareDetectionService>();
        hardwareDetectionService.trackMediaError(error.toString());

        // If hardware acceleration was disabled due to this error,
        // try to recreate the player with new settings
        if (hardwareDetectionService.hasDetectedIssue.value) {
          print('Hardware issue detected, recreating player with new settings');
          // Force manager to dispose and recreate this player
          MediaPlayerManager().disposePlayerFor(url);
          // Get a new player with updated hardware settings
          _playerData = MediaPlayerManager().getPlayerFor(url);

          // Try to initialize again with new settings
          await _playerData.player.open(Media(url));

          if (loop) {
            await _playerData.player.setPlaylistMode(PlaylistMode.loop);
          }

          // If we got here, the player was successfully recreated with new settings
          _playerData.isInitialized = true;
          isInitialized.value = true;
          hasError.value = false;
          return;
        }
      } catch (e) {
        print('Error reporting hardware issue: $e');
        // Continue with normal error handling
      }

      hasError.value = true;
      errorMessage.value = error.toString();
    }
  }

  /// Handle app lifecycle changes
  void handleLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isInitialized.value) {
      // Resume from the saved position when app comes back to foreground
      _playerData.player.seek(position.value);
    } else if (state == AppLifecycleState.paused) {
      // Position is already being tracked via the stream listener
    }
  }

  /// Retry initialization after error
  Future<void> retry() async {
    hasError.value = false;
    isInitialized.value = false;
    errorMessage.value = '';
    await _initializePlayer();
  }

  /// Toggle hardware acceleration and retry
  Future<void> toggleHardwareAccelerationAndRetry() async {
    try {
      final hardwareDetectionService =
          Get.find<MediaHardwareDetectionService>();
      final currentSetting =
          hardwareDetectionService.isHardwareAccelerationEnabled.value;
      hardwareDetectionService.toggleHardwareAcceleration(!currentSetting);

      // Force reload
      hasError.value = false;
      isInitialized.value = false;
      errorMessage.value = '';
      await _initializePlayer();
    } catch (e) {
      print('Error toggling hardware acceleration: $e');
      hasError.value = true;
      errorMessage.value = 'Error toggling hardware acceleration: $e';
    }
  }

  /// Check if this is a hardware-related issue
  bool get isHardwareIssue {
    try {
      final hardwareDetectionService =
          Get.find<MediaHardwareDetectionService>();
      return hardwareDetectionService.hasDetectedIssue.value;
    } catch (e) {
      print('Error checking hardware acceleration status: $e');
      return false;
    }
  }

  /// Check if hardware acceleration is enabled
  bool get isHardwareAccelerationEnabled {
    try {
      final hardwareDetectionService =
          Get.find<MediaHardwareDetectionService>();
      return hardwareDetectionService.isHardwareAccelerationEnabled.value;
    } catch (e) {
      print('Error checking hardware acceleration status: $e');
      return true;
    }
  }

  /// Cleanup resources
  void _cleanup() {
    try {
      // Check if player is already disposed
      bool isDisposed = false;
      try {
        final _ = _playerData.player.state.playing;
      } catch (e) {
        if (e.toString().contains('Player has been disposed')) {
          isDisposed = true;
          print('Player for $url was already disposed in MediaTileController');
        }
      }

      if (!isDisposed) {
        _playerData.player.pause();
        print('MediaTileController for $url disposed');
      }
    } catch (e) {
      print('Error cleaning up MediaTileController resources: $e');
    }
  }

  /// Get the player controller for the video widget
  VideoController get videoController => _playerData.controller;

  /// Get the player for direct access
  Player get player => _playerData.player;
}
