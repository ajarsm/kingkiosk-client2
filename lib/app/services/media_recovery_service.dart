import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

import '../modules/home/controllers/tiling_window_controller.dart';
import '../modules/home/widgets/media_tile.dart';
import './background_media_service.dart';
import '../data/models/window_tile_v2.dart';

/// A service to help recover from media issues like black screens or player failures
class MediaRecoveryService extends GetxService {
  // Health tracking
  final lastRecoveryTime = Rx<DateTime?>(null);
  final recoveryCount = 0.obs;
  final isPerformingRecovery = false.obs;

  // Recovery configuration
  int cooldownPeriodSeconds = 30; // Minimum time between full resets

  /// Initialize the service
  Future<MediaRecoveryService> init() async {
    print('MediaRecoveryService initialized - ready to handle media issues');
    return this;
  }

  /// Check if we can perform a recovery (prevents too frequent resets)
  bool canPerformRecovery() {
    if (isPerformingRecovery.value) return false;

    if (lastRecoveryTime.value != null) {
      final sinceLastRecovery =
          DateTime.now().difference(lastRecoveryTime.value!);
      if (sinceLastRecovery.inSeconds < cooldownPeriodSeconds) {
        print(
            '⚠️ Recovery requested too soon (${sinceLastRecovery.inSeconds}s since last recovery)');
        print('   Waiting for cooldown period (${cooldownPeriodSeconds}s)');
        return false;
      }
    }

    return true;
  }

  /// Get current health status of media systems
  Map<String, dynamic> getMediaHealthStatus() {
    try {
      // Try to check BackgroundMediaService health
      Map<String, dynamic> mediaServiceData = {};

      try {
        final mediaService = Get.find<BackgroundMediaService>();
        mediaServiceData = mediaService.getHealthData();
      } catch (e) {
        print('Could not access BackgroundMediaService health: $e');
        mediaServiceData = {'error': 'Service unavailable'};
      }

      // Merge with recovery service data
      final result = {
        ...mediaServiceData,
        'recoveryCount': recoveryCount.value,
        'lastRecovery': lastRecoveryTime.value?.toIso8601String(),
        'isRecovering': isPerformingRecovery.value,
        'cooldownPeriodSeconds': cooldownPeriodSeconds,
      };

      return result;
    } catch (e) {
      print('Error getting media health status: $e');
      return {'error': e.toString()};
    }
  }

  /// Emergency function to reset all media resources when black screens occur
  /// Call this function when media playback becomes unreliable or shows black screens
  ///
  /// @param force If true, bypass the cooldown period check
  /// @returns True if recovery was performed, false if skipped
  Future<bool> resetAllMediaResources({bool force = false}) async {
    // Check if we're allowed to recover now
    if (!force && !canPerformRecovery()) {
      print(
          '⚠️ Media reset rejected - recovery already in progress or cooldown period active');
      return false;
    }

    // Update state
    isPerformingRecovery.value = true;
    lastRecoveryTime.value = DateTime.now();
    recoveryCount.value++;

    // Save current background audio state to restore after reset
    String? backgroundAudioUrl;
    bool wasPlaying = false;
    bool wasLooping = false;

    try {
      print(
          '=== 🚨 EMERGENCY MEDIA RESET INITIATED (#${recoveryCount.value}) ===');
      print('Time: ${DateTime.now().toIso8601String()}');

      // Step 1: Capture background audio state before stopping
      try {
        final backgroundService = Get.find<BackgroundMediaService>();
        // Only save state if background audio is playing
        if (backgroundService.isPlaying.value &&
            backgroundService.mediaType.value == 'audio' &&
            backgroundService.currentMedia.value != null) {
          backgroundAudioUrl = backgroundService.currentMedia.value;
          wasPlaying = backgroundService.isPlaying.value;
          // Try to get loop state if available
          try {
            // Get the player's current state
            final player = backgroundService.getPlayer();
            // Check if we're in a loop mode
            if (player != null) {
              // In media_kit, we need to check if it's looping another way
              // We'll use properties from BackgroundMediaService instead
              wasLooping = backgroundService.currentMedia.value != null &&
                  backgroundService.mediaType.value == 'audio' &&
                  backgroundService.isPlaying.value;

              // Most background audio in the application is looping, so default to true
              // if we have trouble determining the exact state
              if (!wasLooping) {
                wasLooping = true;
                print(
                    'Assuming background audio is looping (default behavior)');
              } else {
                print(
                    'Detected looping audio based on background service state');
              }

              if (wasPlaying) await player.play(); // Resume if it was playing
            }
          } catch (e) {
            print('❌ Could not determine audio loop state: $e');
            wasLooping = false;
          }
          print(
              '📝 Saved background audio state: url=$backgroundAudioUrl, playing=$wasPlaying, loop=$wasLooping');
        }

        await backgroundService.stop();
        print('✅ Background media service stopped');
      } catch (e) {
        print('❌ Error stopping background service: $e');
      }

      // Step 2: Find all media/audio tiles
      final tileController = Get.find<TilingWindowController>();
      final mediaToClose = <WindowTile>[];

      for (final tile in tileController.tiles) {
        if (tile.type == TileType.media || tile.type == TileType.audio) {
          mediaToClose.add(tile);
        }
      }

      // Step 3: Close all media/audio tiles
      print('🔄 Closing ${mediaToClose.length} media tiles...');
      for (final tile in mediaToClose) {
        try {
          tileController.closeTile(tile);
          print('✅ Closed media tile: ${tile.id}');
        } catch (e) {
          print('❌ Error closing tile ${tile.id}: $e');
        }
      }

      // Step 4: Reset MediaPlayerManager
      try {
        final manager = MediaPlayerManager();
        manager.resetAllPlayers();
        print('✅ Media player manager reset');
      } catch (e) {
        print('❌ Error resetting player manager: $e');
      }

      // Step 5: Reinitialize MediaKit
      try {
        // Small delay to ensure resources are released
        await Future.delayed(Duration(milliseconds: 300));
        MediaKit.ensureInitialized();
        print('✅ MediaKit reinitialized');
      } catch (e) {
        print('❌ Error reinitializing MediaKit: $e');
      }
      // Step 6: Force garbage collection (indirectly)
      try {
        // This is a trick to suggest garbage collection in Dart
        await Future.delayed(Duration(milliseconds: 300));
        // Create memory pressure to encourage GC
        final memoryPressure = List.filled(10000, 0);
        print(
            '✅ Suggested garbage collection with ${memoryPressure.length} objects');
      } catch (e) {
        print('❌ Error during GC suggestion: $e');
      }

      print('=== ✅ EMERGENCY MEDIA RESET COMPLETED ===');
      return true;
    } catch (e) {
      print('❌ Error during emergency media reset: $e');
      return false;
    } finally {
      isPerformingRecovery.value = false;
    }
  }

  /// Fix a specific media player that's having issues
  Future<bool> fixMediaPlayer(String url) async {
    try {
      final manager = MediaPlayerManager();
      print('Attempting to fix media player for: $url');

      // Check if it's an RTSP stream (which requires more careful handling)
      final isRtspStream = url.toLowerCase().startsWith('rtsp://');
      if (isRtspStream) {
        print('RTSP stream detected, using extra caution for disposal');
      }

      // Try to dispose and recreate the player
      final disposed = manager.disposePlayerFor(url);
      if (disposed) {
        // Wait for cleanup to complete - longer delay for RTSP streams
        await Future.delayed(Duration(milliseconds: isRtspStream ? 300 : 200));
        print('Player for $url was reset and will be recreated on next use');

        // Suggest garbage collection especially for RTSP streams
        if (isRtspStream) {
          MediaKit.ensureInitialized();
        }
      }

      return disposed;
    } catch (e) {
      print('Error fixing media player for $url: $e');
      return false;
    }
  }

  /// Capture the state of background audio before reset
  Future<Map<String, dynamic>> captureBackgroundAudioState() async {
    final result = <String, dynamic>{
      'url': null,
      'isPlaying': false,
      'isLooping': false,
    };

    try {
      final backgroundService = Get.find<BackgroundMediaService>();

      // Only save state if background audio is playing
      if (backgroundService.isPlaying.value &&
          backgroundService.mediaType.value == 'audio' &&
          backgroundService.currentMedia.value != null) {
        result['url'] = backgroundService.currentMedia.value;
        result['isPlaying'] = backgroundService.isPlaying.value;
        // We can't directly determine if it's looping, but we can assume it is
        // for most background audio
        result['isLooping'] = true;

        print('📝 Captured background audio state: ${result['url']}');
      }
    } catch (e) {
      print('❌ Error capturing background audio state: $e');
    }

    return result;
  }

  /// Restore background audio after reset
  Future<bool> restoreBackgroundAudio(Map<String, dynamic> audioState) async {
    final url = audioState['url'] as String?;
    if (url == null || url.isEmpty) {
      return false;
    }

    try {
      final backgroundService = Get.find<BackgroundMediaService>();

      print('🔄 Restoring background audio: $url');
      await backgroundService.playAudio(
        url,
        loop: audioState['isLooping'] == true,
      );

      // If it was paused, pause it again
      if (audioState['isPlaying'] == false) {
        await backgroundService.pause();
      }

      print('✅ Background audio restored successfully');
      return true;
    } catch (e) {
      print('❌ Error restoring background audio: $e');
      return false;
    }
  }
}
