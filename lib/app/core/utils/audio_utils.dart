import 'package:get/get.dart';
import '../../services/audio_service.dart';

/// This class provides a compatibility layer between the old audioplayers usage
/// and the new just_audio based AudioService
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

/// This class provides a drop-in replacement for the old AudioPlayer class
/// for code that still uses AudioPlayer directly
class AudioPlayer {
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
    // No implementation needed as just_audio handles this internally
    return;
  }

  /// Release resources
  Future<void> dispose() async {
    // No implementation needed as just_audio handles this internally
    return;
  }
}

/// Drop-in replacement for AssetSource
class AssetSource {
  final String path;

  AssetSource(this.path);

  @override
  String toString() => path;
}
