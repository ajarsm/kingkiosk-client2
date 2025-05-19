import 'package:get/get.dart';
import '../../../services/audio_service.dart';

/// Utility class for PIN entry audio feedback
/// (replacement for previous audioplayers implementation)
class PinAudioUtil {
  static final AudioService _audioService = Get.find<AudioService>();

  /// Play error beep sound for wrong PIN
  static Future<void> playErrorBeep() async {
    await _audioService.playWrongPinSound();
  }

  /// Play success sound for correct PIN
  static Future<void> playSuccessSound() async {
    await _audioService.playSuccessSound();
  }
}
