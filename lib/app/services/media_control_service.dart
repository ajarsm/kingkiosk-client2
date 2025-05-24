import 'package:get/get.dart';
import './background_media_service.dart';
import '../services/window_manager_service.dart';

/// Service to handle media control commands for both background and window media
class MediaControlService extends GetxService {
  /// Initialize the service
  Future<MediaControlService> init() async {
    print('MediaControlService initialized');
    return this;
  }

  /// Play a media window
  /// @param windowId The ID of the window to control
  /// @returns Success status
  Future<bool> playMedia(String windowId) async {
    try {
      final windowManager = Get.find<WindowManagerService>();
      final window = windowManager.getWindow(windowId);

      if (window == null) {
        print('❌ [MediaControl] No window found with ID: $windowId');
        return false;
      }

      print('▶️ [MediaControl] Sending play command to window: $windowId');
      window.handleCommand('play', {});
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error playing media in window $windowId: $e');
      return false;
    }
  }

  /// Pause a media window
  /// @param windowId The ID of the window to control
  /// @returns Success status
  Future<bool> pauseMedia(String windowId) async {
    try {
      final windowManager = Get.find<WindowManagerService>();
      final window = windowManager.getWindow(windowId);

      if (window == null) {
        print('❌ [MediaControl] No window found with ID: $windowId');
        return false;
      }

      print('⏸️ [MediaControl] Sending pause command to window: $windowId');
      window.handleCommand('pause', {});
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error pausing media in window $windowId: $e');
      return false;
    }
  }

  /// Stop a media window
  /// @param windowId The ID of the window to control
  /// @returns Success status
  Future<bool> stopMedia(String windowId) async {
    try {
      final windowManager = Get.find<WindowManagerService>();
      final window = windowManager.getWindow(windowId);

      if (window == null) {
        print('❌ [MediaControl] No window found with ID: $windowId');
        return false;
      }

      print('⏹️ [MediaControl] Sending stop command to window: $windowId');
      window.handleCommand('stop', {});
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error stopping media in window $windowId: $e');
      return false;
    }
  }

  /// Seek to a position in a media window
  /// @param windowId The ID of the window to control
  /// @param position Position in seconds
  /// @returns Success status
  Future<bool> seekMedia(String windowId, double position) async {
    try {
      final windowManager = Get.find<WindowManagerService>();
      final window = windowManager.getWindow(windowId);

      if (window == null) {
        print('❌ [MediaControl] No window found with ID: $windowId');
        return false;
      }

      print(
          '⏩ [MediaControl] Seeking to position $position in window: $windowId');
      window.handleCommand('seek', {'position': position});
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error seeking in window $windowId: $e');
      return false;
    }
  }

  /// For background audio player - play
  Future<bool> playBackgroundAudio() async {
    try {
      final backgroundService = Get.find<BackgroundMediaService>();

      if (backgroundService.currentMedia.value == null ||
          backgroundService.mediaType.value != 'audio') {
        print('❌ [MediaControl] No background audio is loaded');
        return false;
      }

      print('▶️ [MediaControl] Playing background audio');
      await backgroundService.play();
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error playing background audio: $e');
      return false;
    }
  }

  /// For background audio player - pause
  Future<bool> pauseBackgroundAudio() async {
    try {
      final backgroundService = Get.find<BackgroundMediaService>();

      if (backgroundService.currentMedia.value == null ||
          backgroundService.mediaType.value != 'audio') {
        print('❌ [MediaControl] No background audio is loaded');
        return false;
      }

      print('⏸️ [MediaControl] Pausing background audio');
      await backgroundService.pause();
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error pausing background audio: $e');
      return false;
    }
  }

  /// For background audio player - stop
  Future<bool> stopBackgroundAudio() async {
    try {
      final backgroundService = Get.find<BackgroundMediaService>();

      if (backgroundService.currentMedia.value == null ||
          backgroundService.mediaType.value != 'audio') {
        print('❌ [MediaControl] No background audio is loaded');
        return false;
      }

      print('⏹️ [MediaControl] Stopping background audio');
      await backgroundService.stop();
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error stopping background audio: $e');
      return false;
    }
  }

  /// For background audio player - seek
  Future<bool> seekBackgroundAudio(double position) async {
    try {
      final backgroundService = Get.find<BackgroundMediaService>();

      if (backgroundService.currentMedia.value == null ||
          backgroundService.mediaType.value != 'audio') {
        print('❌ [MediaControl] No background audio is loaded');
        return false;
      }

      print('⏩ [MediaControl] Seeking background audio to position $position');
      await backgroundService.seek(Duration(seconds: position.round()));
      return true;
    } catch (e) {
      print('❌ [MediaControl] Error seeking background audio: $e');
      return false;
    }
  }
}
