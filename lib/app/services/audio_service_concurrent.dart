import '../services/audio_service.dart';

/// Helper class to provide concurrent sound playback without awaiting completion
class AudioServiceConcurrent {
  /// Plays error sound concurrently with animation (non-blocking)
  static void playErrorConcurrent() {
    // Use a fire-and-forget approach for concurrent sound with animation
    AudioService.playError(); // Don't await this call
  }

  /// Plays success sound concurrently (non-blocking)
  static void playSuccessConcurrent() {
    AudioService.playSuccess(); // Don't await this call
  }
}
