import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/window_tile.dart';
import '../../../services/websocket_service.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../controllers/app_state_controller.dart';

class HomeController extends GetxController {
  // Services
  final WebSocketService _websocketService = Get.find<WebSocketService>();
  final PlatformSensorService _platformSensorService = Get.find<PlatformSensorService>();
  final StorageService _storageService = Get.find<StorageService>();
  
  // Constants for storage keys
  static const String keyWindowState = 'window_state';

  // Window tiles
  final RxList<WindowTile> tiles = <WindowTile>[].obs;
  
  // Selected tile
  final Rx<WindowTile?> selectedTile = Rx<WindowTile?>(null);

  final RxBool isMaximizedWebViewActive = false.obs;
  final RxString currentWebViewUrl = ''.obs;
  final AppStateController appStateController = Get.find<AppStateController>();
  
  @override
  void onInit() {
    super.onInit();
    
    // First try to restore saved window state
    bool restoredState = _restoreWindowState();
    
    // If no state to restore or restoration failed, add default tiles for demonstration
    if (!restoredState) {
      final webSample = AppConstants.sampleWebItems[0];
      addWebViewTile(webSample['name']!, webSample['url']!);
      
      final mediaSample = AppConstants.sampleMediaItems[0];
      addMediaTile(mediaSample['name']!, mediaSample['url']!);
    }

    // Kiosk URL auto-loading functionality has been removed
    
    // Listen for changes in window tiles to save state
    ever(tiles, (_) => _saveWindowState());
  }
  
  void addWebViewTile(String name, String url) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.webView,
      url: url,
      position: _calculateNextPosition(),
      size: const Size(400, 300),
    );
    
    tiles.add(newTile);
    selectedTile.value = newTile;
  }
  
  void addMediaTile(String name, String url) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.media,
      url: url,
      position: _calculateNextPosition(),
      size: const Size(400, 300),
    );
    
    tiles.add(newTile);
    selectedTile.value = newTile;
  }
  
  void addAudioTile(String name, String url) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.audio,
      url: url,
      position: _calculateNextPosition(),
      size: const Size(350, 180), // Increased size to prevent overflow
    );
    
    tiles.add(newTile);
    selectedTile.value = newTile;
  }

  Offset _calculateNextPosition() {
    // Simple positioning logic - cascade windows
    final index = tiles.length;
    return Offset(50 + (index * 30), 50 + (index * 30));
  }
  
  void selectTile(WindowTile tile) {
    selectedTile.value = tile;
    
    // Bring the selected tile to the front (by removing and adding it back)
    final tilesCopy = List<WindowTile>.from(tiles);
    tilesCopy.remove(tile);
    tilesCopy.add(tile);
    tiles.assignAll(tilesCopy);
  }
  
  void updateTilePosition(WindowTile tile, Offset newPosition) {
    final index = tiles.indexWhere((element) => element.id == tile.id);
    if (index != -1) {
      // Create a new tile with updated position
      final updatedTile = tile.copyWith(position: newPosition);
      
      // Replace the old tile with the updated one
      final tilesCopy = List<WindowTile>.from(tiles);
      tilesCopy[index] = updatedTile;
      tiles.assignAll(tilesCopy);
      
      // Update selected tile if needed
      if (selectedTile.value?.id == tile.id) {
        selectedTile.value = updatedTile;
      }
    }
  }
  
  void updateTileSize(WindowTile tile, Size newSize) {
    final index = tiles.indexWhere((element) => element.id == tile.id);
    if (index != -1) {
      // Create a new tile with updated size
      final updatedTile = tile.copyWith(size: newSize);
      
      // Replace the old tile with the updated one
      final tilesCopy = List<WindowTile>.from(tiles);
      tilesCopy[index] = updatedTile;
      tiles.assignAll(tilesCopy);
      
      // Update selected tile if needed
      if (selectedTile.value?.id == tile.id) {
        selectedTile.value = updatedTile;
      }
    }
  }
  
  void closeTile(WindowTile tile) {
    tiles.removeWhere((element) => element.id == tile.id);
    
    // Clear selected tile if it was the one closed
    if (selectedTile.value?.id == tile.id) {
      selectedTile.value = tiles.isNotEmpty ? tiles.last : null;
    }
  }
  
  Map<String, dynamic> getSensorData() {
    return _platformSensorService.getAllSensorData();
  }
  
  void connectToWebsocket(String url) {
    _websocketService.connect(url);
  }
  
  void sendDataToWebsocket(dynamic data) {
    _websocketService.send(data);
  }

  void loadKioskUrl(String url) {
    if (url.isEmpty) {
      url = AppConstants.defaultKioskStartUrl;
    }
    
    // For URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    // Close all existing windows first
    final tilesToClose = [...tiles];
    for (var tile in tilesToClose) {
      closeTile(tile);
    }
    
    // Create a kiosk-specific WebView tile
    addWebViewTile('Kiosk View', url);
    
    // Update the maximized view state
    isMaximizedWebViewActive.value = true;
    currentWebViewUrl.value = url;
    
    // Save this as the kiosk URL for next time
    appStateController.setKioskStartUrl(url);
    
    // If we have a selected tile, maximize its size to fill most of the screen
    if (selectedTile.value != null) {
      final screenSize = Get.size;
      final newSize = Size(
        screenSize.width * 0.95, 
        screenSize.height * 0.9
      );
      final newPosition = Offset(
        screenSize.width * 0.025,
        screenSize.height * 0.05
      );
      
      updateTileSize(selectedTile.value!, newSize);
      updateTilePosition(selectedTile.value!, newPosition);
    }
  }
  
  void closeMaximizedWebView() {
    isMaximizedWebViewActive.value = false;
    currentWebViewUrl.value = '';
  }

  /// Save the current window state to persistent storage
  void _saveWindowState() {
    try {
      if (tiles.isEmpty) {
        // If there are no tiles, just remove the stored state
        _storageService.remove(keyWindowState);
        return;
      }

      // Convert tiles to a list of serializable maps
      final List<Map<String, dynamic>> serializedTiles = tiles.map((tile) {
        return {
          'id': tile.id,
          'name': tile.name,
          'type': tile.type.toString().split('.').last, // Convert enum to string
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

      // Also store selected tile ID if one is selected
      final String? selectedId = selectedTile.value?.id;
      
      // Create a wrapper map that includes tiles and selected ID
      final Map<String, dynamic> windowState = {
        'tiles': serializedTiles,
        'selectedId': selectedId,
        'savedAt': DateTime.now().toIso8601String(),
      };

      // Save to storage
      _storageService.write(keyWindowState, json.encode(windowState));
      print('Window state saved: ${serializedTiles.length} tiles');
    } catch (e) {
      print('Error saving window state: $e');
    }
  }

  /// Restore window state from persistent storage
  bool _restoreWindowState() {
    try {
      final String? savedState = _storageService.read<String>(keyWindowState);
      
      if (savedState == null || savedState.isEmpty) {
        print('No saved window state found');
        return false;
      }

      // Parse the saved state
      final Map<String, dynamic> windowState = json.decode(savedState);
      final List<dynamic> tilesData = windowState['tiles'];
      final String? selectedId = windowState['selectedId'];

      if (tilesData.isEmpty) {
        print('No tiles in saved state');
        return false;
      }

      // Clear existing tiles
      tiles.clear();

      // Restore tiles
      for (final tileData in tilesData) {
        // Convert stored position and size to Flutter objects
        final position = Offset(
          tileData['position']['dx'],
          tileData['position']['dy'],
        );
        
        final size = Size(
          tileData['size']['width'],
          tileData['size']['height'],
        );

        // Convert string type back to enum
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

        // Create and add the tile
        final tile = WindowTile(
          id: tileData['id'],
          name: tileData['name'],
          type: type,
          url: tileData['url'],
          position: position,
          size: size,
        );
        tiles.add(tile);

        // Restore selected tile if this is it
        if (tile.id == selectedId) {
          selectedTile.value = tile;
        }
      }

      // If no tile was selected but we have tiles, select the first one
      if (selectedTile.value == null && tiles.isNotEmpty) {
        selectedTile.value = tiles.first;
      }

      print('Restored ${tiles.length} tiles from saved state');
      return true;
    } catch (e) {
      print('Error restoring window state: $e');
      return false;
    }
  }
}