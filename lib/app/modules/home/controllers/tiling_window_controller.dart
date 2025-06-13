import 'dart:convert';
import 'dart:math' as math;
import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/media_recovery_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:media_kit/media_kit.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../data/models/tiling_layout.dart';
import '../widgets/media_tile.dart';
import '../widgets/webview_tile_manager.dart'; // Add WebViewTileManager import
import '../widgets/youtube_player_tile.dart'; // Add YouTubePlayerManager import
import '../../../services/storage_service.dart';
import '../../../services/window_manager_service.dart';
import '../../../services/mqtt_service_consolidated.dart';

import '../../settings/controllers/settings_controller_compat.dart';
import 'media_window_controller.dart';
import 'web_window_controller.dart';
import 'image_window_controller.dart'; // Add import for image controller
import '../../calendar/controllers/calendar_controller.dart';
import 'pdf_window_controller.dart'; // Add import for PDF controller
import 'clock_window_controller.dart'; // Add import for clock controller
import 'alarmo_window_controller.dart'; // Add import for alarmo controller
import 'weather_window_controller.dart'; // Add import for weather controller
import '../../calendar/controllers/calendar_window_controller.dart'; // Add import for calendar controller

class TilingWindowController extends GetxController {
  // Constants for storage keys
  static const String keyTilingWindowState = 'tiling_window_state';

  // Observable list of all window tiles
  final tiles = <WindowTile>[].obs;

  // Currently selected tile
  final Rx<WindowTile?> selectedTile = Rx<WindowTile?>(null);

  // Tracks tiles with active highlights
  final highlightedTiles = <String>{}.obs;

  // Timer for auto-hiding the highlight
  Map<String, Timer> _highlightTimers = {};

  // Highlight duration in seconds
  static const int _highlightDuration = 15;

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
      } // Create a serializable representation of tiles
      final List<Map<String, dynamic>> serializedTiles = tiles.map((tile) {
        final Map<String, dynamic> tileMap = {
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
          'loop': tile.loop,
        };

        // Add imageUrls if not empty
        if (tile.imageUrls.isNotEmpty) {
          tileMap['imageUrls'] = tile.imageUrls;
        }

        // Add metadata if present
        if (tile.metadata != null) {
          tileMap['metadata'] = tile.metadata;
        }

        return tileMap;
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
      final String? savedState =
          storageService.read<String>(keyTilingWindowState);

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
          case 'audioVisualizer':
            type = TileType.audioVisualizer;
            break;
          case 'image':
            type = TileType.image;
            break;
          case 'youtube':
            type = TileType.youtube;
            break;
          case 'pdf':
            type = TileType.pdf;
            break;
          case 'clock':
            type = TileType.clock;
            break;
          case 'alarmo':
            type = TileType.alarmo;
            break;
          case 'weather':
            type = TileType.weather;
            break;
          case 'calendar':
            type = TileType.calendar;
            break;
          default:
            type = TileType.webView;
        } // Handle image URLs if present (for image tiles)
        List<String> imageUrls = [];
        if (tileData['imageUrls'] != null && tileData['imageUrls'] is List) {
          imageUrls = List<String>.from(tileData['imageUrls']);
        }

        // Handle metadata if present
        Map<String, dynamic>? metadata;
        if (tileData['metadata'] != null && tileData['metadata'] is Map) {
          metadata = Map<String, dynamic>.from(tileData['metadata']);
        }

        // Create and add tile
        final tile = WindowTile(
          id: tileData['id'],
          name: tileData['name'],
          type: type,
          url: tileData['url'],
          imageUrls: imageUrls,
          position: position,
          size: size,
          loop: tileData['loop'] ?? false,
          metadata: metadata,
        );
        tiles.add(tile);

        // Register window controllers for restored tiles
        _registerWindowControllerForTile(tile);

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

  /// Register window controllers for restored tiles
  void _registerWindowControllerForTile(WindowTile tile) {
    try {
      switch (tile.type) {
        case TileType.calendar:
          // Register CalendarWindowController for calendar tiles
          final controller = Get.put(
            CalendarWindowController(windowName: tile.id),
            tag: tile.id,
          );

          // Register with window manager
          Get.find<WindowManagerService>().registerWindow(controller);

          // Show the calendar window to ensure it's visible
          controller.showWindow();

          // Set the calendar title to match the tile name
          try {
            final calendarController = Get.find<CalendarController>();
            calendarController.setCalendarTitle(tile.name);
          } catch (e) {
            print('⚠️ Could not set calendar title: $e');
          }

          print(
              '📅 Registered and showed CalendarWindowController for restored tile: ${tile.id}');
          break;

        case TileType.clock:
          // Register ClockWindowController for clock tiles
          final controller = Get.put(
            ClockWindowController(windowName: tile.id),
            tag: tile.id,
          );

          // Apply initial configuration if metadata is present
          if (tile.metadata != null) {
            controller.configure(tile.metadata!);
          }

          Get.find<WindowManagerService>().registerWindow(controller);
          print(
              '🕒 Registered ClockWindowController for restored tile: ${tile.id}');
          break;

        case TileType.alarmo:
          // Register AlarmoWindowController for alarmo tiles
          final controller = Get.put(
            AlarmoWindowController(windowName: tile.id),
            tag: tile.id,
          );

          // Apply initial configuration if metadata is present
          if (tile.metadata != null) {
            controller.configure(tile.metadata!);
          }

          Get.find<WindowManagerService>().registerWindow(controller);
          print(
              '🚨 Registered AlarmoWindowController for restored tile: ${tile.id}');
          break;

        case TileType.weather:
          // Register WeatherWindowController for weather tiles
          final controller = Get.put(
            WeatherWindowController(windowName: tile.id),
            tag: tile.id,
          );

          // Apply initial configuration if metadata is present
          if (tile.metadata != null) {
            controller.configure(tile.metadata!);
          }

          Get.find<WindowManagerService>().registerWindow(controller);
          print(
              '🌤️ Registered WeatherWindowController for restored tile: ${tile.id}');
          break;
        case TileType.webView:
          // Register WebWindowController for webview tiles
          // Note: WebView controller needs the actual InAppWebViewController,
          // which will be created when the WebViewTile widget is initialized
          // For now, skip registration since it requires a valid webViewController
          print(
              '🌐 Skipping WebWindowController registration for restored tile: ${tile.id} (requires webViewController)');
          break;

        case TileType.media:
          // Register MediaWindowController for media tiles
          final playerData = MediaPlayerManager().getPlayerFor(tile.url);
          final controller = MediaWindowController(
            windowName: tile.id,
            playerData: playerData,
            onClose: () {
              Get.find<WindowManagerService>().unregisterWindow(tile.id);
            },
          );

          Get.find<WindowManagerService>().registerWindow(controller);
          print(
              '🎬 Registered MediaWindowController for restored tile: ${tile.id}');
          break;

        case TileType.image:
          // Register ImageWindowController for image tiles
          // Get the first image URL or use tile.url as fallback
          final imageUrl =
              tile.imageUrls.isNotEmpty ? tile.imageUrls.first : tile.url;
          final controller = ImageWindowController(
            windowName: tile.id,
            imageUrl: imageUrl,
            imageUrls: tile.imageUrls,
            closeCallback: () {
              Get.find<WindowManagerService>().unregisterWindow(tile.id);
            },
          );

          Get.find<WindowManagerService>().registerWindow(controller);
          print(
              '🖼️ Registered ImageWindowController for restored tile: ${tile.id}');
          break;

        case TileType.pdf:
          // Register PdfWindowController for PDF tiles
          final controller = PdfWindowController(
            windowName: tile.id,
            pdfUrl: tile.url,
            onCloseCallback: () {
              Get.find<WindowManagerService>().unregisterWindow(tile.id);
            },
          );

          Get.find<WindowManagerService>().registerWindow(controller);
          print(
              '📄 Registered PdfWindowController for restored tile: ${tile.id}');
          break;

        case TileType.audio:
        case TileType.audioVisualizer:
        case TileType.youtube:
          // These tiles don't need separate window controllers for visibility
          print(
              '🔊 Tile type ${tile.type} does not require a window controller: ${tile.id}');
          break;
      }
    } catch (e) {
      print('❌ Error registering window controller for tile ${tile.id}: $e');
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
      // When switching to tiling mode, reset and rebuild the layout tree
      _layout.resetLayout();
      _rebuildLayoutTree();
      _layout.applyLayout(_containerBounds);

      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    } else {
      // When switching to floating mode, make sure tiles have sensible positions
      for (var tile in tiles) {
        // Only update tiles with default position
        if (tile.position == Offset.zero) {
          tile.position = _calculateNextPosition();
        }
      }
    }

    // Save the window state
    _saveWindowState();
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
        _layout.addTile(tiles[i],
            targetTile: tiles[i - 1],
            direction: useHorizontalSplit
                ? SplitDirection.horizontal
                : SplitDirection.vertical);
        useHorizontalSplit = !useHorizontalSplit;
      }
    }
  }

  /// Publishes the list of open windows to MQTT for Home Assistant diagnostics
  void publishOpenWindowsToMqtt() {
    try {
      final mqttService = Get.find<MqttService>();
      final deviceName = Get.find<SettingsControllerFixed>().deviceName.value;
      final List<Map<String, dynamic>> windowList = tiles
          .map((tile) => {
                'id': tile.id,
                'name': tile.name,
                'type': tile.type.toString().split('.').last,
                'url': tile.url,
              })
          .toList();
      final topic = 'kiosk/$deviceName/diagnostics/windows';
      if (mqttService.isConnected.value) {
        // Use a helper on the service to publish to an arbitrary topic
        mqttService.publishJsonToTopic(topic, {'windows': windowList},
            retain: true);
        // Also (re)publish discovery config in case device name changed
        mqttService.publishWindowsDiscoveryConfig();
        print(
            'Published windows state to $topic (retain=true) and discovery config.');
      } else {
        print('MQTT not connected, cannot publish open windows diagnostics');
      }
    } catch (e) {
      print('Error publishing open windows to MQTT: $e');
    }
  }

  /// Creates a WebView window tile
  void addWebViewTile(String name, String url,
      {InAppWebViewController? webViewController}) {
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

    // --- Register WebWindowController for MQTT/web control if we already have a controller ---
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
    // Note: If no webViewController provided, the WebViewTile will register itself
    // when the WebView is created in its onWebViewCreated callback.

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

  /// Creates an audio visualizer window tile
  void addAudioVisualizerTile(String name, String url) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.audioVisualizer,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(400, 300), // Larger size for visualizer
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;
    publishOpenWindowsToMqtt();
  }

  /// Creates an audio visualizer window tile with a custom ID
  void addAudioVisualizerTileWithId(String id, String name, String url) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.audioVisualizer,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(400, 300), // Larger size for visualizer
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;
    publishOpenWindowsToMqtt();
  }

  /// Creates a WebView window tile with a custom ID
  void addWebViewTileWithId(String id, String name, String url,
      {InAppWebViewController? webViewController}) {
    final newTile = WindowTile(
      id: id,
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
    if (webViewController != null) {
      final controller = WebWindowController(
        windowName: newTile.id,
        webViewController: webViewController,
        onClose: () {
          Get.find<WindowManagerService>().unregisterWindow(newTile.id);
        },
      );
      Get.find<WindowManagerService>().registerWindow(controller);
    }
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a media (video) window tile with a custom ID
  void addMediaTileWithId(String id, String name, String url,
      {bool loop = false}) {
    final newTile = WindowTile(
      id: id,
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
    final playerData = MediaPlayerManager().getPlayerFor(url);
    final controller = MediaWindowController(
      windowName: newTile.id,
      playerData: playerData,
      onClose: () {
        Get.find<WindowManagerService>().unregisterWindow(newTile.id);
      },
    );
    Get.find<WindowManagerService>().registerWindow(controller);
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates an audio window tile with a custom ID
  void addAudioTileWithId(String id, String name, String url) {
    final newTile = WindowTile(
      id: id,
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

  /// Creates an image window tile with a custom ID
  void addImageTileWithId(String id, String name, dynamic urlData) {
    String primaryUrl;
    List<String> imageUrls = [];
    if (urlData is String) {
      primaryUrl = urlData;
    } else if (urlData is List) {
      imageUrls = List<String>.from(urlData.map((url) => url.toString()));
      primaryUrl = imageUrls.first;
    } else {
      print('❌ Invalid image URL format');
      return;
    }
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.image,
      url: primaryUrl,
      imageUrls: imageUrls,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(500, 400),
    );
    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;
    final controller = imageUrls.length > 1
        ? ImageWindowController.createCarousel(
            windowName: newTile.id,
            imageUrls: imageUrls,
            closeCallback: () {
              Get.find<WindowManagerService>().unregisterWindow(newTile.id);
            },
          )
        : ImageWindowController.createSingle(
            windowName: newTile.id,
            imageUrl: primaryUrl,
            closeCallback: () {
              Get.find<WindowManagerService>().unregisterWindow(newTile.id);
            },
          );
    Get.find<WindowManagerService>().registerWindow(controller);
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a PDF viewer window tile
  void addPdfTile(String name, String url) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.pdf,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(600, 800), // Default size suitable for PDF viewing
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register PDF Window Controller for window management
    // Note: The actual PdfWindowController will be created by the PdfTile widget
    // This just sets up the initial registration
    final controller = PdfWindowController(
      windowName: newTile.id,
      pdfUrl: url,
      onCloseCallback: () {
        Get.find<WindowManagerService>().unregisterWindow(newTile.id);
      },
    );
    Get.find<WindowManagerService>().registerWindow(controller);

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a PDF viewer window tile with a custom ID
  void addPdfTileWithId(String id, String name, String url) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.pdf,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(600, 800), // Default size suitable for PDF viewing
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register PDF Window Controller for window management
    final controller = PdfWindowController(
      windowName: id,
      pdfUrl: url,
      onCloseCallback: () {
        Get.find<WindowManagerService>().unregisterWindow(id);
      },
    );
    Get.find<WindowManagerService>().registerWindow(controller);

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a YouTube player window tile  /// Creates a YouTube player window tile  /// Creates a YouTube player window tile
  void addYouTubeTile(String name, String url, String videoId) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.youtube,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(640, 390), // 16:9 aspect ratio for videos
      metadata: {'videoId': videoId},
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // No need to register with window manager here - this will be done when the WebView is created
    // in the YouTubePlayerTile widget with the fix in youtube_window_controller_fixed.dart

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a YouTube player window tile with a custom ID
  void addYouTubeTileWithId(
      String id, String name, String url, String videoId) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.youtube,
      url: url,
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(640, 390), // 16:9 aspect ratio for videos
      metadata: {'videoId': videoId},
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // No need to register with window manager here - this will be done when the WebView is created
    // in the YouTubePlayerTile widget with the fix in youtube_window_controller_fixed.dart

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a clock window tile
  void addClockTile(String name, {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: TileType.clock,
      url: '', // Clock tiles don't need URLs
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(350, 350), // Square size for clock
      metadata: config, // Store clock configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register ClockWindowController for MQTT control
    final controller = Get.put(
      ClockWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      controller.configure(config);
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates a clock window tile with a custom ID
  void addClockTileWithId(String id, String name,
      {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.clock,
      url: '', // Clock tiles don't need URLs
      position: tilingMode.value ? Offset.zero : _calculateNextPosition(),
      size: Size(350, 350), // Square size for clock
      metadata: config, // Store clock configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register ClockWindowController for MQTT control
    final controller = Get.put(
      ClockWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      controller.configure(config);
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    // Save window state after adding tile
    _saveWindowState();
    publishOpenWindowsToMqtt();
  }

  /// Creates an Alarmo window tile
  void addAlarmoTile(String name, {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: 'alarmo_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: TileType.alarmo,
      url: '', // Alarmo tiles don't need URLs
      position: const Offset(50, 50),
      size: Size(400, 500), // Portrait size for dialpad
      metadata: config, // Store Alarmo configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register AlarmoWindowController for MQTT control
    final controller = Get.put(
      AlarmoWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      controller.configure(config);
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    print('Added Alarmo tile: ${newTile.name} with ID: ${newTile.id}');
  }

  /// Creates an Alarmo window tile with a custom ID
  void addAlarmoTileWithId(String id, String name,
      {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.alarmo,
      url: '', // Alarmo tiles don't need URLs
      position: const Offset(50, 50),
      size: Size(400, 500), // Portrait size for dialpad
      metadata: config, // Store Alarmo configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register AlarmoWindowController for MQTT control
    final controller = Get.put(
      AlarmoWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      controller.configure(config);
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    print('Added Alarmo tile: ${newTile.name} with ID: ${newTile.id}');
  }

  /// Creates a Weather window tile
  void addWeatherTile(String name, {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: TileType.weather,
      url: '', // Weather tiles don't need URLs
      position: const Offset(50, 50),
      size: Size(400, 400), // Square size for weather display
      metadata: config, // Store weather configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register WeatherWindowController for weather data
    final controller = Get.put(
      WeatherWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      controller.configure(config);
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    print('Added Weather tile: ${newTile.name} with ID: ${newTile.id}');
  }

  /// Creates a Weather window tile with a custom ID
  void addWeatherTileWithId(String id, String name,
      {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.weather,
      url: '', // Weather tiles don't need URLs
      position: const Offset(50, 50),
      size: Size(400, 400), // Square size for weather display
      metadata: config, // Store weather configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value = newTile;

    // Register WeatherWindowController for weather data
    final controller = Get.put(
      WeatherWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      controller.configure(config);
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    print('Added Weather tile: ${newTile.name} with ID: ${newTile.id}');
  }

  /// Creates a calendar window tile
  void addCalendarTile(String name, {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: 'calendar_${tiles.length}',
      name: name,
      type: TileType.calendar,
      url: '', // Calendar tiles don't need URLs
      position: const Offset(50, 50),
      size: Size(400, 500), // Rectangular size for calendar
      metadata: config, // Store calendar configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value =
        newTile; // Register CalendarWindowController for MQTT control
    final controller = Get.put(
      CalendarWindowController(windowName: newTile.id),
      tag: newTile.id,
    ); // Apply initial configuration if provided
    if (config != null) {
      // Handle calendar-specific configuration
      print('📅 Calendar configuration: $config');
    }

    Get.find<WindowManagerService>().registerWindow(controller);

    // Set the calendar title to match the tile name
    try {
      final calendarController = Get.find<CalendarController>();
      calendarController.setCalendarTitle(name);
    } catch (e) {
      print('⚠️ Could not set calendar title: $e');
    }

    // Show the calendar window by default when created
    controller.showWindow();

    // Save window state after adding tile
    _saveWindowState();
    print('Added Calendar tile: ${newTile.name} with ID: ${newTile.id}');
  }

  /// Creates a calendar window tile with a custom ID
  void addCalendarTileWithId(String id, String name,
      {Map<String, dynamic>? config}) {
    final newTile = WindowTile(
      id: id,
      name: name,
      type: TileType.calendar,
      url: '', // Calendar tiles don't need URLs
      position: const Offset(50, 50),
      size: Size(400, 500), // Rectangular size for calendar
      metadata: config, // Store calendar configuration
    );

    tiles.add(newTile);
    if (tilingMode.value) {
      _layout.addTile(newTile, targetTile: selectedTile.value);
      _layout.applyLayout(_containerBounds);
    }
    selectedTile.value =
        newTile; // Register CalendarWindowController for calendar control
    final controller = Get.put(
      CalendarWindowController(windowName: newTile.id),
      tag: newTile.id,
    );

    // Apply initial configuration if provided
    if (config != null) {
      // Handle calendar-specific configuration
      print('📅 Calendar configuration: $config');
    }
    Get.find<WindowManagerService>().registerWindow(controller);

    // Set the calendar title to match the tile name
    try {
      final calendarController = Get.find<CalendarController>();
      calendarController.setCalendarTitle(name);
    } catch (e) {
      print('⚠️ Could not set calendar title: $e');
    }

    // Show the calendar window by default when created
    controller.showWindow();

    print('Added Calendar tile: ${newTile.name} with ID: ${newTile.id}');
  }

  /// Selects a tile and brings it to the front
  void selectTile(WindowTile tile) {
    selectedTile.value = tile;

    // Add this tile to highlighted tiles
    highlightedTiles.add(tile.id);

    // Cancel any existing timer for this tile
    _highlightTimers[tile.id]?.cancel();

    // Start a new timer to remove the highlight after the duration
    _highlightTimers[tile.id] = Timer(
      Duration(seconds: _highlightDuration),
      () {
        // Remove the highlight when the timer expires
        highlightedTiles.remove(tile.id);
      },
    );
  }

  /// Cleans up all timers when the controller is disposed
  @override
  void onClose() {
    // Cancel all active highlight timers
    for (var timer in _highlightTimers.values) {
      timer.cancel();
    }
    _highlightTimers.clear();
    super.onClose();
  }

  /// Closes/removes a window tile
  void closeTile(WindowTile tile) {
    final index = tiles.indexOf(tile);
    if (index >= 0) {
      // Stop media/web/audio playback and dispose controller if needed
      if (tile.type == TileType.audio ||
          tile.type == TileType.audioVisualizer ||
          tile.type == TileType.media ||
          tile.type == TileType.webView ||
          tile.type == TileType.youtube) {
        final wm = Get.find<WindowManagerService>();
        final controller = wm.getWindow(tile.id);
        if (controller != null) {
          try {
            // Force dispose window resources first
            controller.disposeWindow();
            wm.unregisterWindow(tile.id);
            // For WebView tiles, also remove from the WebViewTileManager
            if (tile.type == TileType.webView) {
              try {
                WebViewTileManager().removeWebViewTile(tile.id);
                print(
                    '🔒 Removed WebViewTile from manager for window: ${tile.id}');
              } catch (e) {
                print('Error removing WebViewTile from manager: $e');
              }
            }
            // For YouTube tiles, also remove from the YouTubePlayerManager
            if (tile.type == TileType.youtube) {
              try {
                YouTubePlayerManager().removeYouTubePlayer(tile.id);
                print(
                    '🎬 Removed YouTubePlayerTile from manager for window: ${tile.id}');
              } catch (e) {
                print('Error removing YouTubePlayerTile from manager: $e');
              }
            }
          } catch (e) {
            print('Error disposing window controller: $e');
          }
        } // Always try to clean up the MediaPlayerManager for media/audio tiles
        // even if the controller wasn't present or failed
        if (tile.type == TileType.audio ||
            tile.type == TileType.audioVisualizer ||
            tile.type == TileType.media) {
          try {
            // Use a brief delay to allow other disposal operations to complete
            Future.delayed(Duration(milliseconds: 100), () {
              // Use try-catch to handle any disposal errors
              try {
                final playerManager = MediaPlayerManager();

                // Check if this URL is an RTSP stream (they're more prone to disposal issues)
                final isRtspStream =
                    tile.url.toLowerCase().startsWith('rtsp://');
                if (isRtspStream) {
                  print(
                      'RTSP stream detected for ${tile.url}, using careful disposal');
                }

                final disposed = playerManager.disposePlayerFor(tile.url);
                print('MediaPlayer disposed for ${tile.url}: $disposed');

                // Force a GC suggestion and asset disposal
                Future.delayed(Duration(milliseconds: isRtspStream ? 200 : 100),
                    () {
                  // This will help suggest to the system to clean up unused resources
                  MediaKit.ensureInitialized();
                });
              } catch (e) {
                print('Error in delayed player disposal: $e');
              }
            });
          } catch (e) {
            print('Error setting up player disposal: $e');
          }
        }
      }
      // First remove the tile from our data structure
      tiles.removeAt(index);

      // Then recalculate the tiling layout if needed
      if (tilingMode.value) {
        // Complete layout reset and recalculation
        _layout.resetLayout();

        // Only rebuild layout if we have remaining tiles
        if (tiles.isNotEmpty) {
          // Add all remaining tiles to the layout in order
          for (var remainingTile in tiles) {
            _layout.addTile(remainingTile);
          }

          // Apply the updated layout
          _layout.applyLayout(_containerBounds);
        }
      }

      // Update selection if needed
      if (selectedTile.value?.id == tile.id) {
        selectedTile.value = tiles.isNotEmpty ? tiles.last : null;
      }

      // Update MQTT status
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
        // Constrain window position within container bounds
        final constrainedPosition =
            _constrainPositionWithinContainer(position, tile.size);
        tile.position = constrainedPosition;
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

        // Check if current position would place the window outside bounds with new size
        final currentPos = tile.position;
        final rightEdge = currentPos.dx + newSize.width;
        final bottomEdge = currentPos.dy + newSize.height;

        // If window would extend beyond container bounds, adjust position
        Offset adjustedPosition = currentPos;
        if (rightEdge > _containerBounds.width) {
          // Adjust x position to keep window within horizontal bounds
          adjustedPosition = Offset(
              math.max(0, _containerBounds.width - newSize.width),
              adjustedPosition.dy);
        }

        if (bottomEdge > _containerBounds.height) {
          // Adjust y position to keep window within vertical bounds
          adjustedPosition = Offset(adjustedPosition.dx,
              math.max(0, _containerBounds.height - newSize.height));
        }

        // Update tile with new size and potentially adjusted position
        tile.size = newSize;
        if (adjustedPosition != currentPos) {
          tile.position = adjustedPosition;
        }

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
        final minimizedTiles =
            tiles.where((t) => t.size.height == minimizedHeight).toList();
        final minimizedY = _containerBounds.height -
            ((minimizedTiles.length + 1) * (minimizedHeight + margin));
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
      _layout.addTile(tile,
          targetTile: selectedTile.value!,
          direction: SplitDirection.horizontal);
      _layout.applyLayout(_containerBounds);

      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    }
  }

  /// Split the selected window vertically
  void splitTileVertical(WindowTile tile) {
    if (tilingMode.value && selectedTile.value != null) {
      _layout.addTile(tile,
          targetTile: selectedTile.value!, direction: SplitDirection.vertical);
      _layout.applyLayout(_containerBounds);

      // Force update of the UI
      final currentTiles = [...tiles];
      tiles.assignAll(currentTiles);
    }
  }

  /// Constrains a position within the container bounds considering window size
  Offset _constrainPositionWithinContainer(Offset position, Size windowSize) {
    // Ensure window doesn't move outside the container bounds
    final double maxX = _containerBounds.width - windowSize.width;
    final double maxY = _containerBounds.height - windowSize.height;

    // Apply constraints - keep window within visible container area
    return Offset(
      position.dx.clamp(0, maxX > 0 ? maxX : 0),
      position.dy.clamp(0, maxY > 0 ? maxY : 0),
    );
  }

  /// Calculate the next position for a floating window
  Offset _calculateNextPosition() {
    // Start at (20, 20) and cascade each window by 30px
    const baseOffset = 20.0;
    const incrementOffset = 30.0;
    final windowCount = tiles.length;

    // Generate a cascaded position
    final rawPosition = Offset(
      baseOffset +
          (windowCount * incrementOffset) % (_containerBounds.width / 2),
      baseOffset +
          (windowCount * incrementOffset) % (_containerBounds.height / 2),
    );

    // Default size for most windows
    final defaultSize = Size(600, 400);

    // Ensure the position is within bounds
    return _constrainPositionWithinContainer(rawPosition, defaultSize);
  }

  /// Emergency function to reset all media resources when black screens occur
  Future<void> resetAllMediaResources() async {
    try {
      print('=== EMERGENCY MEDIA RESET INITIATED ===');

      // Use MediaRecoveryService if available, as it handles this more cleanly
      try {
        final recoveryService = Get.find<MediaRecoveryService>();
        await recoveryService.resetAllMediaResources(force: true);
        print('Media resources reset via MediaRecoveryService');
        return;
      } catch (e) {
        print(
            'MediaRecoveryService not available, falling back to manual reset: $e');
      }

      // Step 2: Close all media/audio tiles
      final List<WindowTile> mediaToClose = [];
      for (final tile in tiles) {
        if (tile.type == TileType.media || tile.type == TileType.audio) {
          mediaToClose.add(tile);
        }
      }

      for (final tile in mediaToClose) {
        try {
          closeTile(tile);
          print('Closed media tile: ${tile.id}');
        } catch (e) {
          print('Error closing tile ${tile.id}: $e');
        }
      }

      // Step 3: Reset MediaPlayerManager
      try {
        final manager = MediaPlayerManager();
        manager.resetAllPlayers();
        print('Media player manager reset');
      } catch (e) {
        print('Error resetting player manager: $e');
      }

      // Step 4: Reinitialize MediaKit
      try {
        MediaKit.ensureInitialized();
        print('MediaKit reinitialized');
      } catch (e) {
        print('Error reinitializing MediaKit: $e');
      }
      print('=== EMERGENCY MEDIA RESET COMPLETED ===');
    } catch (e) {
      print('Error during emergency media reset: $e');
    }
  }
}
