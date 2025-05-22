import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import '../../services/audio_service.dart';

/// This class provides a compatibility layer for older audio playback code
class AudioPlayerCompat {
  // Use method to safely get AudioService instead of static field
  static AudioService? _getAudioService() {
    try {
      if (Get.isRegistered<AudioService>()) {
        return Get.find<AudioService>();
      }
    } catch (e) {
      print('Error finding AudioService: $e');
    }
    return null;
  }

  /// Play error sound (for wrong PIN)
  static Future<void> playErrorSound() async {
    final service = _getAudioService();
    if (service != null) {
      await service.playWrongPinSound();
    } else {
      await AudioService.playError();
    }
  }

  /// Play success sound
  static Future<void> playSuccessSound() async {
    final service = _getAudioService();
    if (service != null) {
      await service.playSuccessSound();
    } else {
      await AudioService.playSuccess();
    }
  }

  /// Play notification sound
  static Future<void> playNotification() async {
    try {
      print('🔔 AudioPlayerCompat.playNotification() called');

      // Try multiple approaches to ensure sound plays
      bool played = false;

      // First try static method
      try {
        print('🔔 Trying AudioService.playNotification()');
        await AudioService.playNotification();
        print('✅ Static notification sound played successfully');
        played = true;
      } catch (e) {
        print('⚠️ Static method failed: $e');
      }

      // If static method failed, try instance method
      if (!played) {
        try {
          print('🔔 Trying instance method via Get.find()');
          if (Get.isRegistered<AudioService>()) {
            final audioService = Get.find<AudioService>();
            await audioService.playNotificationSound();
            print('✅ Instance notification sound played successfully');
            played = true;
          } else {
            print('⚠️ AudioService not registered with Get');
          }
        } catch (e) {
          print('⚠️ Instance method failed: $e');
        }
      }

      // If both failed, try creating a new instance
      if (!played) {
        try {
          print('🔔 Trying with new AudioService instance');
          final tempService = AudioService();
          await tempService.init();
          await tempService.playNotificationSound();
          print('✅ New instance notification sound played successfully');
        } catch (e) {
          print('⚠️ New instance method failed: $e');
          // Let the outer catch handle it
          throw e;
        }
      }
    } catch (e) {
      print('❌ All notification sound approaches failed: $e');
    }
  }
}

/// This class provides a drop-in replacement for code that expects an AudioPlayer class
class AudioPlayer {
  // No need for Player field anymore as we'll use AudioService

  /// Create a new audio player
  AudioPlayer() {
    print('🔊 AudioPlayer compatibility wrapper created');
  }

  /// Try to get the AudioService instance
  AudioService? _getAudioService() {
    try {
      if (Get.isRegistered<AudioService>()) {
        return Get.find<AudioService>();
      }
    } catch (e) {
      print('Error finding AudioService: $e');
    }
    return null;
  }

  /// Play a sound
  Future<void> play(dynamic source) async {
    print('🔊 AudioPlayer.play() called with source: $source');
    try {
      final service = _getAudioService();
      if (service == null) {
        throw Exception('AudioService not registered');
      }

      if (source.toString().contains('error') ||
          source.toString().contains('beep') ||
          source.toString().contains('wrong')) {
        await service.playWrongPinSound();
      } else if (source.toString().contains('success')) {
        await service.playSuccessSound();
      } else {
        await service.playNotificationSound();
      }
    } catch (e) {
      print('⚠️ Error in AudioPlayer.play: $e');
      // Try static methods as fallback
      try {
        if (source.toString().contains('error') ||
            source.toString().contains('beep') ||
            source.toString().contains('wrong')) {
          await AudioService.playError();
        } else if (source.toString().contains('success')) {
          await AudioService.playSuccess();
        } else {
          await AudioService.playNotification();
        }
      } catch (e2) {
        print('⚠️ AudioPlayer fallback also failed: $e2');
      }
    }
  }

  /// Stop playing a sound
  Future<void> stop() async {
    try {
      // Try to stop using the service
      final service = _getAudioService();
      if (service != null) {
        // Service handles stopping as needed
      }
    } catch (e) {
      print('⚠️ Error in AudioPlayer.stop: $e');
    }
    return;
  }

  /// Release resources
  Future<void> dispose() async {
    try {
      // No need to manage resources as AudioService handles cleanup
    } catch (e) {
      print('⚠️ Error in AudioPlayer.dispose: $e');
    }
    return;
  }
}

/// Compatibility replacement for AssetSource that works with media_kit
class AssetSource {
  final String path;

  AssetSource(this.path);

  /// Convert to asset path format for Media constructor
  String toAssetPath() => 'asset:///assets/sounds/$path';

  @override
  String toString() => path;
}
