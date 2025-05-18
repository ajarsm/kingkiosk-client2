import 'package:flutter/material.dart';
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
      final sinceLastRecovery = DateTime.now().difference(lastRecoveryTime.value!);
      if (sinceLastRecovery.inSeconds < cooldownPeriodSeconds) {
        print('⚠️ Recovery requested too soon (${sinceLastRecovery.inSeconds}s since last recovery)');
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
      print('⚠️ Media reset rejected - recovery already in progress or cooldown period active');
      return false;
    }
    
    // Update state
    isPerformingRecovery.value = true;
    lastRecoveryTime.value = DateTime.now();
    recoveryCount.value++;
    
    try {
      print('=== 🚨 EMERGENCY MEDIA RESET INITIATED (#${recoveryCount.value}) ===');
      print('Time: ${DateTime.now().toIso8601String()}');
      
      // Step 1: Stop background media service
      try {
        final backgroundService = Get.find<BackgroundMediaService>();
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
        print('✅ Suggested garbage collection with ${memoryPressure.length} objects');
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
      
      // Try to dispose and recreate the player
      final disposed = manager.disposePlayerFor(url);
      if (disposed) {
        // Wait for cleanup to complete
        await Future.delayed(Duration(milliseconds: 200));
        print('Player for $url was reset and will be recreated on next use');
      }
      
      return disposed;
    } catch (e) {
      print('Error fixing media player for $url: $e');
      return false;
    }
  }
}
