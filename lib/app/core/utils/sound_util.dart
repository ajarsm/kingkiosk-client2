import 'package:get/get.dart';
import '../../../app/services/audio_service.dart';

/// Utility class to easily play sounds from anywhere in the app
/// This replaces the direct use of audioplayers package
class SoundUtil {
  /// Play error/wrong PIN sound
  static Future<void> playError() async {
    await AudioService.playError();
  }

  /// Play success sound
  static Future<void> playSuccess() async {
    await AudioService.playSuccess();
  }

  /// Play notification sound
  static Future<void> playNotification() async {
    try {
      if (Get.isRegistered<AudioService>()) {
        final audioService = Get.find<AudioService>();
        await audioService.playNotificationSound();
      }
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  /// Clear audio cache
  static Future<void> clearCache() async {
    try {
      if (Get.isRegistered<AudioService>()) {
        final audioService = Get.find<AudioService>();
        //await audioService.clearCache();
      }
    } catch (e) {
      print('Error clearing audio cache: $e');
    }
  }
}
