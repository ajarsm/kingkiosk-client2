import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../services/window_manager_service.dart';
import 'image_tile.dart';

/// A helper widget that renders the correct content for a tile based on its type
class WindowTileRenderer extends StatelessWidget {
  final WindowTile tile;
  final bool showControls;
  
  const WindowTileRenderer({
    Key? key,
    required this.tile,
    this.showControls = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Use the window manager if possible for registered windows
    final windowManager = Get.find<WindowManagerService>();
    final controller = windowManager.getWindow(tile.id);
    
    if (controller != null) {
      // Use the controller's build method if available
      return buildFromController(controller);
    } else {
      // Fall back to basic rendering based on tile type
      return buildBasicTile();
    }
  }
  
  Widget buildFromController(KioskWindowController controller) {
    // This method would need to be adapted based on how your controllers work
    // For now, we'll handle the basic tile types
    return buildBasicTile();
  }
  
  Widget buildBasicTile() {
    switch (tile.type) {
      case TileType.webView:
        return Center(child: Text('Web View: ${tile.url}'));
        
      case TileType.media:
        return Center(child: Text('Media: ${tile.url}'));
        
      case TileType.audio:
        return Center(child: Text('Audio: ${tile.url}'));
        
      case TileType.image:
        return ImageTile(
          url: tile.url, 
          showControls: showControls,
          onClose: null, // This would be handled by the window manager
        );
        
      default:
        return Center(child: Text('Unknown Tile Type'));
    }
  }
}
