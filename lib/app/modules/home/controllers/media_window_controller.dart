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
    playerData.player.dispose();
    if (onClose != null) onClose!();
  }
}
