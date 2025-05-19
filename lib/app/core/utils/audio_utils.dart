import 'package:get/get.dart';
import '../../services/audio_service.dart';

/// This class provides a compatibility layer between the old audioplayers usage
/// and the new just_audio based AudioService
class AudioPlayerCompat {
  static final AudioService _audioService = Get.find<AudioService>();

  /// Play error sound (for wrong PIN)
  static Future<void> playErrorSound() async {
    await _audioService.playWrongPinSound();
  }

  /// Play success sound
  static Future<void> playSuccessSound() async {
    await _audioService.playSuccessSound();
  }

  /// Play notification sound
  static Future<void> playNotification() async {
    await _audioService.playNotificationSound();
  }
}

/// This class provides a drop-in replacement for the old AudioPlayer class
/// for code that still uses AudioPlayer directly
class AudioPlayer {
  static final AudioService _audioService = Get.find<AudioService>();

  /// Play a sound
  Future<void> play(dynamic source) async {
    if (source.toString().contains('error') ||
        source.toString().contains('beep')) {
      await _audioService.playWrongPinSound();
    } else if (source.toString().contains('success')) {
      await _audioService.playSuccessSound();
    } else {
      await _audioService.playNotificationSound();
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
