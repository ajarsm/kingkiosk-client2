import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/tiling_window_controller.dart';
import '../widgets/web_view_tile.dart';
import '../widgets/media_tile.dart';
import '../widgets/audio_tile.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../routes/app_pages.dart';
import '../../../services/navigation_service.dart';
import '../../../widgets/system_info_dashboard.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../controllers/app_state_controller.dart';

class TilingWindowView extends StatefulWidget {
  const TilingWindowView({Key? key}) : super(key: key);

  @override
  TilingWindowViewState createState() => TilingWindowViewState();
}

class TilingWindowViewState extends State<TilingWindowView> {
  // Cache all controllers needed during build to prevent GetX lookups during build
  late final TilingWindowController controller;
  late final AppStateController appStateController;
  late final PlatformSensorService sensorService;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState to avoid setState during build issues
    controller = Get.find<TilingWindowController>();
    appStateController = Get.find<AppStateController>();
    sensorService = Get.find<PlatformSensorService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update container bounds when dependencies change (e.g., screen size)
    // This avoids calling setState during build
    final screenSize = MediaQuery.of(context).size;
    controller.setContainerBoundsIfChanged(
      Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(color: Theme.of(context).scaffoldBackgroundColor),

          // Windows
          Obx(() => Stack(
                children: controller.tiles.map((tile) => _buildWindowTile(tile)).toList(),
              )),

          // Auto-hiding toolbar at the bottom
          _AutoHidingToolbar(
            child: _buildToolbar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowTile(WindowTile tile) {
    return Positioned(
      left: tile.position.dx,
      top: tile.position.dy,
      width: tile.size.width,
      height: tile.size.height,
      child: Obx(() {
        final isSelected = controller.selectedTile.value?.id == tile.id;

        return GestureDetector(
          onTap: () => controller.selectTile(tile),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
              borderRadius: BorderRadius.circular(4),
              color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Window title bar
                _buildTitleBar(tile),

                // Window content
                Expanded(
                  child: _buildTileContent(tile),
                ),

                // Only show resize handle in floating mode
                if (!controller.tilingMode.value) _buildResizeHandle(tile),
              ],
            ),
          ),
          // Only allow dragging in floating mode
          onPanUpdate: controller.tilingMode.value
              ? null
              : (details) {
                  controller.updateTilePosition(
                    tile,
                    Offset(
                      tile.position.dx + details.delta.dx,
                      tile.position.dy + details.delta.dy,
                    ),
                  );
                },
        );
      }),
    );
  }

  Widget _buildTitleBar(WindowTile tile) {
    return Container(
      height: 30,
      color: Get.isDarkMode ? Colors.grey[800] : Colors.grey[200],
      child: Row(
        children: [
          // Window icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _getIconForTileType(tile.type),
          ),

          // Window title
          Expanded(
            child: Text(
              tile.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Split buttons (only in tiling mode)
          if (controller.tilingMode.value)
            Row(
              children: [
                Tooltip(
                  message: "Split Vertically (Top/Bottom)",
                  child: IconButton(
                    icon: Icon(Icons.vertical_split, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => controller.splitTileVertical(tile),
                  ),
                ),
                Tooltip(
                  message: "Split Horizontally (Left/Right)",
                  child: IconButton(
                    icon: Icon(Icons.horizontal_split, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => controller.splitTileHorizontal(tile),
                  ),
                ),
              ],
            ),

          // Maximize button (only in floating mode)
          if (!controller.tilingMode.value)
            Tooltip(
              message: "Maximize Window",
              child: IconButton(
                icon: Icon(Icons.crop_square, size: 16),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () => controller.maximizeTile(tile),
              ),
            ),

          // Close button
          Tooltip(
            message: "Close Window",
            child: IconButton(
              icon: Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: () => controller.closeTile(tile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIconForTileType(TileType type) {
    switch (type) {
      case TileType.webView:
        return Icon(Icons.web, size: 16);
      case TileType.media:
        return Icon(Icons.video_file, size: 16);
      case TileType.audio:
        return Icon(Icons.audio_file, size: 16);
    }
  }

  Widget _buildTileContent(WindowTile tile) {
    switch (tile.type) {
      case TileType.webView:
        return WebViewTile(url: tile.url);
      case TileType.media:
        return MediaTile(url: tile.url);
      case TileType.audio:
        return AudioTile(url: tile.url);
    }
  }

  Widget _buildResizeHandle(WindowTile tile) {
    return GestureDetector(
      onPanUpdate: (details) {
        controller.updateTileSize(
          tile,
          Size(
            tile.size.width + details.delta.dx,
            tile.size.height + details.delta.dy,
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeDownRight,
        child: Container(
          height: 20,
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.drag_handle, size: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 50,
      color: Theme.of(context).primaryColor,
      child: Row(
        children: [
          // Add web view button
          _buildToolbarButton(
            icon: Icons.web,
            label: 'Web',
            onPressed: () => _showAddWebViewDialog(context),
          ),

          // Add video button
          _buildToolbarButton(
            icon: Icons.video_file,
            label: 'Video',
            onPressed: () => _showAddMediaDialog(context, isAudio: false),
          ),

          // Add audio button
          _buildToolbarButton(
            icon: Icons.audio_file,
            label: 'Audio',
            onPressed: () => _showAddMediaDialog(context, isAudio: true),
          ),

          // Toggle tiling/floating mode
          _buildToolbarButton(
            icon: controller.tilingMode.value ? Icons.view_quilt : Icons.view_carousel,
            label: controller.tilingMode.value ? 'Tiling' : 'Floating',
            onPressed: () => controller.toggleWindowMode(),
          ),

          // Compact system info display
          _buildCompactSystemInfo(),

          // Flexible spacer
          Spacer(),

          // System Info button
          _buildToolbarButton(
            icon: Icons.dashboard,
            label: 'System Info',
            onPressed: () => _showSystemInfoDialog(context),
          ),

          // Settings button
          _buildToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }  /// Builds a compact system info display for the toolbar
  Widget _buildCompactSystemInfo() {
    // Use cached controller and Obx for reactivity
    return Obx(() {
      // Only show if system info is enabled in settings  
      if (!appStateController.showSystemInfo.value) {
        return SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // We'll use the mini version of system info that only shows CPU and Memory
            Tooltip(
              message: "System Information",
              child: InkWell(
                onTap: () => _showSystemInfoDialog(context),
                child: _buildCompactStats(context),
              ),
            ),
          ],
        ),
      );
    }); // Using Obx closure instead of Builder
  }  /// Builds compact CPU and Memory stats display
  Widget _buildCompactStats(BuildContext context) {
    // Using the cached sensor service from initState
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CPU Usage
        Icon(Icons.memory, size: 14, color: Colors.white),
        SizedBox(width: 4),
        Obx(() {
          final cpuUsage = sensorService.cpuUsage.value;
          return Text(
            "${(cpuUsage * 100).toStringAsFixed(1)}%",
            style: TextStyle(color: Colors.white, fontSize: 11),
          );
        }),
        
        SizedBox(width: 12),
        
        // Memory Usage
        Icon(Icons.storage, size: 14, color: Colors.white),
        SizedBox(width: 4),
        Obx(() {
          final memoryUsage = sensorService.memoryUsage.value;
          return Text(
            "${(memoryUsage * 100).toStringAsFixed(1)}%",
            style: TextStyle(color: Colors.white, fontSize: 11),
          );
        }),
      ],
    );
  }

  void _showAddWebViewDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController urlController = TextEditingController(text: 'https://');

    // Use Future.microtask to avoid setState during build errors
    Future.microtask(() {
      Get.dialog(
        AlertDialog(
          title: Text('Add Web View'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a name for this window',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'Enter the website URL',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  controller.addWebViewTile(nameController.text, urlController.text);
                  Get.back();
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
    });
  }

  void _showAddMediaDialog(BuildContext context, {required bool isAudio}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    // Use Future.microtask to avoid setState during build errors
    Future.microtask(() {
      Get.dialog(
        AlertDialog(
          title: Text(isAudio ? 'Add Audio' : 'Add Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a name for this window',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'Enter the media URL',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  if (isAudio) {
                    controller.addAudioTile(nameController.text, urlController.text);
                  } else {
                    controller.addMediaTile(nameController.text, urlController.text);
                  }
                  Get.back();
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
    });
  }

  // Helper method to navigate to settings without setState during build
  void _navigateToSettings() {
    // Use Future.microtask to avoid setState during build errors
    Future.microtask(() {
      final navigationService = Get.find<NavigationService>();
      navigationService.navigateTo(Routes.SETTINGS);
    });
  }

  // Show the system information dashboard in a dialog
  void _showSystemInfoDialog(BuildContext context) {
    // Use Future.microtask to avoid setState during build errors
    Future.microtask(() {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Text('System Information'),
            ],
          ),
          content: Container(
            width: 500,
            height: 400,
            child: SingleChildScrollView(
              child: SystemInfoDashboard(compact: false),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    });
  }
}

/// Auto-hiding toolbar widget that shows on hover or tap
class _AutoHidingToolbar extends StatefulWidget {
  final Widget child;

  const _AutoHidingToolbar({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _AutoHidingToolbarState createState() => _AutoHidingToolbarState();
}

class _AutoHidingToolbarState extends State<_AutoHidingToolbar> {
  bool _isVisible = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showToolbar() {
    setState(() => _isVisible = true);

    // Reset any pending hide timer
    _hideTimer?.cancel();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: MouseRegion(
        onEnter: (_) => _showToolbar(),
        onExit: (_) => _startHideTimer(),
        child: GestureDetector(
          onTap: () {
            _showToolbar();
            _startHideTimer();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isVisible ? 50 : 5,
            child: _isVisible
                // When visible, show the full toolbar
                ? widget.child
                // When hidden, just show the handle (no Column to avoid overflow)
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}