import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../data/models/tiling_layout.dart';
import '../widgets/media_tile.dart';
import '../../../services/storage_service.dart';
import '../../../services/window_manager_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../settings/controllers/settings_controller.dart';
import 'media_window_controller.dart';
import 'web_window_controller.dart';

class TilingWindowController extends GetxController {
  // Constants for storage keys
  static const String keyTilingWindowState = 'tiling_window_state';

  // Observable list of all window tiles
  final tiles = <WindowTile>[].obs;
  
  // Currently selected tile
  final Rx<WindowTile?> selectedTile = Rx<WindowTile?>(null);
  
  // Tiling layout manager
  TilingLayout _layout = TilingLayout();
  
  // Layout mode (tiling or floating)
  final RxBool tilingMode = true.obs;
  
  // Container bounds (screen size minus toolbar)
  Rect _containerBounds = Rect.zero;
  
  @override
  void onInit() {
    super.onInit();
    // Initial size for default windows
    _containerBounds = Rect.fromLTWH(0, 0, Get.width, Get.height - 50);
    
    // Restore saved window state
    _restoreWindowState();
    
    // Listen for changes in tiles to save state
    ever(tiles, (_) => _saveWindowState());
  }
  
  // Kiosk URL auto-loading functionality has been removed
  
  /// Save the window layout state
  void _saveWindowState() {
    try {
      final StorageService storageService = Get.find<StorageService>();
      
      if (tiles.isEmpty) {
        storageService.remove(keyTilingWindowState);
        return;
      }
      
      // Create a serializable representation of tiles
      final List<Map<String, dynamic>> serializedTiles = tiles.map((tile) {
        return {
          'id': tile.id,
          'name': tile.name,
          'type': tile.type.toString().split('.').last,
          'url': tile.url,
          'position': {
            'dx': tile.position.dx,
            'dy': tile.position.dy,
          },
          'size': {
            'width': tile.size.width,
            'height': tile.size.height,
          },
        };
      }).toList();
      
      // Also save selected tile ID and tiling mode
      final Map<String, dynamic> state = {
        'tiles': serializedTiles,
        'selectedId': selectedTile.value?.id,
        'tilingMode': tilingMode.value,
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      storageService.write(keyTilingWindowState, jsonEncode(state));
      print('Tiling window state saved: ${serializedTiles.length} tiles');
    } catch (e) {
      print('Error saving tiling window state: $e');
    }
  }
  
  /// Restore window layout state
  bool _restoreWindowState() {
    try {
      final StorageService storageService = Get.find<StorageService>();
      final String? savedState = storageService.read<String>(keyTilingWindowState);
      
      if (savedState == null || savedState.isEmpty) {
        print('No saved tiling window state found');
        return false;
      }
      
      // Parse saved state
      final Map<String, dynamic> state = jsonDecode(savedState);
      final List<dynamic> tilesData = state['tiles'];
      final String? selectedId = state['selectedId'];
      final bool? savedTilingMode = state['tilingMode'];
      
      if (tilesData.isEmpty) {
        return false;
      }
      
      // Set tiling mode
      if (savedTilingMode != null) {
        tilingMode.value = savedTilingMode;
      }
      
      // Clear existing tiles
      tiles.clear();
      
      // Restore tiles
      for (final tileData in tilesData) {
        // Reconstruct position and size
        final position = Offset(
          tileData['position']['dx'],
          tileData['position']['dy'],
        );
        
        final size = Size(
          tileData['size']['width'],
          tileData['size']['height'],
        );
        
        // Parse tile type
        final String typeString = tileData['type'];
        TileType type;
        switch (typeString) {
          case 'webView':
            type = TileType.webView;
            break;
          case 'media':
            type = TileType.media;
            break;
          case 'audio':
            type = TileType.audio;
            break;
          default:
            type = TileType.webView;
        }
        
        // Create and add tile
        final tile = WindowTile(
          id: tileData['id'],
          name: tileData['name'],
          type: type,
          url: tileData['url'],
          position: position,
          size: size,
        );
        tiles.add(tile);
        
        // Set selected tile if this is it
        if (tile.id == selectedId) {
          selectedTile.value = tile;
        }
      }
      
      // If we're in tiling mode, apply the layout
      if (tilingMode.value && tiles.isNotEmpty) {
        _rebuildLayoutTree();
        _layout.applyLayout(_containerBounds);
      }
      
      print('Restored tiling window state: ${tiles.length} tiles');
      return true;
    } catch (e) {
      print('Error restoring tiling window state: $e');
      return false;
    }
  }
  
  /// Set the container bounds (screen size minus toolbar)
  void setContainerBounds(Rect bounds) {
    _containerBounds = bounds;
    if (tilingMode.value) {
      _layout.applyLayout(_containerBounds);
      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    }
  }
  
  /// Set the container bounds only if they've changed
  /// This prevents unnecessary rebuilds during build cycles
  void setContainerBoundsIfChanged(Rect bounds) {
    if (_containerBounds.width != bounds.width || 
        _containerBounds.height != bounds.height ||
        _containerBounds.left != bounds.left ||
        _containerBounds.top != bounds.top) {
      setContainerBounds(bounds);
    }
  }
  
  /// Toggles between tiling and floating mode
  void toggleWindowMode() {
    tilingMode.value = !tilingMode.value;
    if (tilingMode.value) {
      // When switching to tiling mode, rebuild the layout tree and apply it
      _rebuildLayoutTree();
      _layout.applyLayout(_containerBounds);
      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    }
  }
  
  /// Rebuilds the layout tree from scratch based on current tiles
  void _rebuildLayoutTree() {
    // Create a new layout
    _layout = TilingLayout();
    
    // If we have tiles, add them to the layout in order
    if (tiles.isNotEmpty) {
      // Add the first tile as root
      _layout.addTile(tiles.first);
      
      // Add remaining tiles with alternating split directions
      bool useHorizontalSplit = false;
      for (int i = 1; i < tiles.length; i++) {
        _layout.addTile(
          tiles[i],
          targetTile: tiles[i-1],
          direction: useHorizontalSplit 
              ? SplitDirection.horizontal 
              : SplitDirection.vertical
        );
        useHorizontalSplit = !useHorizontalSplit;
      }
    }
  }
  
  /// Publishes the list of open windows to MQTT for Home Assistant diagnostics
  void publishOpenWindowsToMqtt() {
    try {
      final mqttService = Get.find<MqttService>();
      final deviceName = Get.find<SettingsController>().deviceName.value;
      final List<Map<String, dynamic>> windowList = tiles.map((tile) => {
        'id': tile.id,
        'name': tile.name,
        'type': tile.type.toString().split('.').last,
        'url': tile.url,
      }).toList();
      final topic = 'kiosk/$deviceName/diagnostics/windows';
      if (mqttService.isConnected.value) {
        // Use a helper on the service to publish to an arbitrary topic
        mqttService.publishJsonToTopic(topic, {'windows': windowList}, retain: true);
        // Also (re)publish discovery config in case device name changed
        mqttService.publishWindowsDiscoveryConfig();
        print('Published windows state to $topic (retain=true) and discovery config.');
      } else {
        print('MQTT not connected, cannot publish open windows diagnostics');
      }
    } catch (e) {
      print('Error publishing open windows to MQTT: $e');
    }
  }

  /// Creates a WebView window tile
  void addWebViewTile(String name, String url, {InAppWebViewController? webViewController}) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.webView,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(600, 400),
    );
    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // --- Register WebWindowController for MQTT/web control ---
    if (webViewController != null) {
      final controller = WebWindowController(
        windowName: newTile.id, // Use unique tile ID for MQTT routing
        webViewController: webViewController,
        onClose: () {
          Get.find<WindowManagerService>().unregisterWindow(newTile.id);
        },
      );
      Get.find<WindowManagerService>().registerWindow(controller);
    }
    // --------------------------------------------------------

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }
  
  /// Creates a media (video) window tile
  void addMediaTile(String name, String url, {bool loop = false}) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.media,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(600, 400),
      loop: loop,
    );
    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // --- Register MediaWindowController for MQTT/media control ---
    final playerData = MediaPlayerManager().getPlayerFor(url);
    final controller = MediaWindowController(
      windowName: newTile.id, // Use unique tile ID for MQTT routing
      playerData: playerData,
      onClose: () {
        Get.find<WindowManagerService>().unregisterWindow(newTile.id);
      },
    );
    Get.find<WindowManagerService>().registerWindow(controller);
    // ------------------------------------------------------------

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }
  
  /// Creates an audio window tile
  void addAudioTile(String name, String url) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.audio,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(350, 180),
    );
    
    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;
    publishOpenWindowsToMqtt();
  }
  
  /// Selects a tile and brings it to the front
  void selectTile(WindowTile tile) {
    selectedTile.value = tile;
  }
  
  /// Closes/removes a window tile
  void closeTile(WindowTile tile) {
    final index = tiles.indexOf(tile);
    if (index >= 0) {
      // Stop media/web/audio playback and dispose controller if needed
      if (tile.type == TileType.audio || tile.type == TileType.media || tile.type == TileType.webView) {
        final wm = Get.find<WindowManagerService>();
        final controller = wm.getWindow(tile.id);
        if (controller != null) {
          controller.disposeWindow();
          wm.unregisterWindow(tile.id);
        } else {
          // If controller is missing, forcibly dispose the player for media/audio
          if (tile.type == TileType.audio || tile.type == TileType.media) {
            final playerData = MediaPlayerManager().getPlayerFor(tile.url);
            playerData.player.dispose();
          }
        }
      }
      if (tilingMode.value) {
        _layout.removeTile(tile);
        _layout.applyLayout(_containerBounds);
      }
      tiles.removeAt(index);
      if (selectedTile.value?.id == tile.id) {
        selectedTile.value = tiles.isNotEmpty ? tiles.last : null;
      }
      publishOpenWindowsToMqtt();
    }
  }
  
  /// In tiling mode: Splits the selected window
  /// In floating mode: Updates the tile position
  void updateTilePosition(WindowTile tile, Offset position) {
    if (tilingMode.value) {
      // In tiling mode, this triggers a split operation
      splitTileHorizontal(tile);
    } else {
      // In floating mode, update the position
      final index = tiles.indexWhere((t) => t.id == tile.id);
      if (index >= 0) {
        tile.position = position;
        tiles[index] = tile;
      }
    }
  }
  
  /// Updates the tile size (only in floating mode)
  void updateTileSize(WindowTile tile, Size size) {
    if (!tilingMode.value) {
      final index = tiles.indexWhere((t) => t.id == tile.id);
      if (index >= 0) {
        // Enforce minimum size
        final newSize = Size(
          math.max(size.width, 250),
          math.max(size.height, 180),
        );
        tile.size = newSize;
        tiles[index] = tile;
      }
    }
  }
  
  /// Maximizes a tile to fill the available space (only in floating mode)
  void maximizeTile(WindowTile tile) {
    if (!tilingMode.value) {
      final index = tiles.indexWhere((t) => t.id == tile.id);
      if (index >= 0) {
        // Use available container bounds but leave a small margin
        final margin = 5.0;
        tile.position = Offset(margin, margin);
        tile.size = Size(
          _containerBounds.width - 2 * margin,
          _containerBounds.height - 2 * margin,
        );
        tile.isMaximized = true; // <-- set maximized flag
        tiles[index] = tile;
        selectedTile.value = tile;
      }
    }
  }

  /// Restores a maximized tile to a default floating size and position
  void restoreTile(WindowTile tile) {
    if (!tilingMode.value) {
      final index = tiles.indexWhere((t) => t.id == tile.id);
      if (index >= 0) {
        tile.size = Size(600, 400); // Default floating size
        tile.position = _calculateNextPosition(); // Cascade position
        tile.isMaximized = false;
        tiles[index] = tile;
        selectedTile.value = tile;
      }
    }
  }
  
  /// Minimizes a tile (shrinks and moves to a minimized area in floating mode)
  void minimizeTile(WindowTile tile) {
    if (!tilingMode.value) {
      final index = tiles.indexWhere((t) => t.id == tile.id);
      if (index >= 0) {
        // Move to bottom left and shrink to a small strip
        final minimizedWidth = 180.0;
        final minimizedHeight = 40.0;
        final margin = 8.0;
        // Stack minimized windows vertically
        final minimizedTiles = tiles.where((t) => t.size.height == minimizedHeight).toList();
        final minimizedY = _containerBounds.height - ((minimizedTiles.length + 1) * (minimizedHeight + margin));
        tile.position = Offset(margin, minimizedY);
        tile.size = Size(minimizedWidth, minimizedHeight);
        tiles[index] = tile;
        selectedTile.value = tile;
      }
    } else {
      // In tiling mode, just remove the tile from the layout (optionally could hide instead)
      final index = tiles.indexWhere((t) => t.id == tile.id);
      if (index >= 0) {
        _layout.removeTile(tile);
        _layout.applyLayout(_containerBounds);
        // Optionally: tiles[index].isMinimized = true; // if you want to keep in list
        // For now, just remove from layout
        tiles[index] = tile; // No-op, but keeps the tile in the list
      }
    }
  }
  
  /// Split the selected window horizontally
  void splitTileHorizontal(WindowTile tile) {
    if (tilingMode.value && selectedTile.value != null) {
      _layout.addTile(
        tile, 
        targetTile: selectedTile.value!, 
        direction: SplitDirection.horizontal
      );
      _layout.applyLayout(_containerBounds);
      
      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    }
  }
  
  /// Split the selected window vertically
  void splitTileVertical(WindowTile tile) {
    if (tilingMode.value && selectedTile.value != null) {
      _layout.addTile(
        tile, 
        targetTile: selectedTile.value!, 
        direction: SplitDirection.vertical
      );
      _layout.applyLayout(_containerBounds);
      
      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    }
  }
  
  /// Calculate the next position for a floating window
  Offset _calculateNextPosition() {
    // Start at (20, 20) and cascade each window by 30px
    const baseOffset = 20.0;
    const incrementOffset = 30.0;
    final windowCount = tiles.length;
    
    return Offset(
      baseOffset + (windowCount * incrementOffset) % (_containerBounds.width / 2),
      baseOffset + (windowCount * incrementOffset) % (_containerBounds.height / 2),
    );
  }
}