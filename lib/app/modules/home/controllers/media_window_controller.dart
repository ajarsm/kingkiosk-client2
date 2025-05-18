import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../widgets/media_tile.dart';

class MediaWindowController extends KioskWindowController {
  @override
  final String windowName;
  @override
  KioskWindowType get windowType => KioskWindowType.media;
  final PlayerWithController playerData;
  final void Function()? onClose;

  MediaWindowController({
    required this.windowName,
    required this.playerData,
    this.onClose,
  });

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) {
    switch (action) {
      case 'play':
        playerData.player.play();
        break;
      case 'pause':
        playerData.player.pause();
        break;
      case 'close':
        disposeWindow();
        break;
      default:
        print('Unknown media command: $action');
    }
  }
  @override
  void disposeWindow() {
    try {
      // Stop the player first to release hardware resources immediately
      playerData.player.stop();
      
      // Dispose with a short delay to prevent race conditions
      Future.delayed(Duration(milliseconds: 50), () {
        try {
          playerData.player.dispose();
          print('Player disposed for media window: $windowName');
        } catch (e) {
          print('Error in delayed player disposal: $e');
        }
      });
      
      if (onClose != null) onClose!();
    } catch (e) {
      print('Error disposing media window: $e');
      // Still try to call onClose even if disposal fails
      if (onClose != null) onClose!();
    }
  }
}
