import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/tiling_window_controller.dart';
import '../widgets/web_view_tile.dart';
import '../widgets/media_tile.dart';
import '../widgets/audio_tile.dart';
import '../widgets/image_tile.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../routes/app_pages.dart';
import '../../../services/navigation_service.dart';
import '../../../widgets/system_info_dashboard.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../controllers/app_state_controller.dart';
import '../../../modules/settings/controllers/settings_controller.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../widgets/settings_lock_pin_pad.dart';
import '../../../services/window_manager_service.dart';
import '../controllers/web_window_controller.dart';
import 'package:king_kiosk/notification_system/notification_system.dart';

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
  late final SettingsController settingsController;
  late final StreamSubscription kioskModeSub;

  // Add a GlobalKey to control the toolbar from the handle
  final GlobalKey<_AutoHidingToolbarState> _autoHidingToolbarKey =
      GlobalKey<_AutoHidingToolbarState>();
  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState to avoid setState during build issues
    controller = Get.find<TilingWindowController>();
    appStateController = Get.find<AppStateController>();
    sensorService = Get.find<PlatformSensorService>();
    settingsController = Get.find<SettingsController>();

    // Listen to kioskMode changes
    kioskModeSub = settingsController.kioskMode.listen((enabled) {
      if (enabled) {
        PlatformUtils.enableKioskMode();
      } else {
        PlatformUtils.disableKioskMode();
      }
    });

    // Initial apply
    if (settingsController.kioskMode.value) {
      PlatformUtils.enableKioskMode();
    }
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
  void dispose() {
    kioskModeSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final locked = settingsController.isSettingsLocked.value;
        return Stack(
          children: [
            // Background image for root window (faded, smaller)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.18, // Faint background
                  child: FractionallySizedBox(
                    widthFactor: 0.5, // Half the width
                    heightFactor: 0.5, // Half the height
                    child: Image.asset(
                      'assets/images/Royal Kiosk with Wi-Fi Waves.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ), // Windows and overlays
            Obx(() => Stack(
                  children: controller.tiles
                      .map((tile) => _buildWindowTile(tile, locked))
                      .toList(),
                )),
            // Translucent notification indicator in upper right corner
            const TranslucentNotificationIndicator(
              opacity: 0.4, // Slightly more visible
              size: 28.0,
              padding: EdgeInsets.only(top: 20, right: 20),
            ),
            // Edge handle for toolbar/appbar reveal (mobile and desktop)
            if (PlatformUtils.isMobile)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () {
                    _autoHidingToolbarKey.currentState?.showToolbar();
                  },
                  onLongPress: () {
                    _autoHidingToolbarKey.currentState?.showToolbar();
                  },
                  child: Container(
                    height: 24,
                    alignment: Alignment.topCenter,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (PlatformUtils.isDesktop)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _autoHidingToolbarKey.currentState?.showToolbar();
                    },
                    child: Container(
                      height: 16,
                      alignment: Alignment.topCenter,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Get.isDarkMode
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ), // Auto-hiding toolbar at the bottom
            _AutoHidingToolbar(
              key: _autoHidingToolbarKey,
              child: _buildToolbar(context, locked),
            ), // Overlay Wyoming FAB in top right

            // Notification Center positioned on the right side
            _buildNotificationCenter(),
          ],
        );
      }),
    );
  }

  Widget _buildWindowTile(WindowTile tile, bool locked) {
    if (tile.type == TileType.webView) {
      final wm = Get.find<WindowManagerService>();
      final webController = wm.getWindow(tile.id);
      if (webController is WebWindowController) {
        return Obx(() {
          // This Obx will rebuild the entire tile when refreshCounter changes
          final refreshValue = webController.refreshCounter.value;
          print(
              '🔄 [REFRESH] Rebuilding WebView tile for window: ${tile.id}, refreshCounter: $refreshValue');
          return _buildWindowTileCore(tile, locked);
        });
      }
    }
    // Fallback for non-web or missing controller
    return _buildWindowTileCore(tile, locked);
  }

  Widget _buildWindowTileCore(WindowTile tile, bool locked) {
    return Positioned(
      left: tile.position.dx,
      top: tile.position.dy,
      width: tile.size.width,
      height: tile.size.height,
      child: Obx(() {
        final isSelected = controller.selectedTile.value?.id == tile.id;
        final isHighlighted = controller.highlightedTiles.contains(tile.id);

        // Apply highlight if it's selected OR currently highlighted
        final shouldHighlight = isSelected || isHighlighted;

        return GestureDetector(
          onTap: locked ? null : () => controller.selectTile(tile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              border: Border.all(
                color: shouldHighlight ? Colors.blue : Colors.grey,
                width: shouldHighlight ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: shouldHighlight
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title bar and controls: lock pointer events when locked
                _buildTitleBar(tile, locked),
                // Window content: always interactive
                Expanded(
                  child: _buildTileContent(tile),
                ),
                // Only show resize handle in floating mode and when not locked
                if (!controller.tilingMode.value && !locked)
                  _buildResizeHandle(tile),
                // Force rebuild on lock state change to ensure drag is re-enabled
                if (locked) SizedBox.shrink(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTitleBar(WindowTile tile, bool locked) {
    return AbsorbPointer(
      absorbing: locked,
      child: Container(
        height: 30,
        color: Get.isDarkMode ? Colors.grey[800] : Colors.grey[200],
        child: Row(
          children: [
            // Window icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _getIconForTileType(tile.type),
            ), // Window title (drag area)
            Expanded(
              child: GestureDetector(
                onPanStart: (_) {
                  // Highlight window when starting to drag
                  controller.selectTile(tile);
                },
                onPanUpdate: (details) {
                  controller.updateTilePosition(
                    tile,
                    Offset(
                      tile.position.dx + details.delta.dx,
                      tile.position.dy + details.delta.dy,
                    ),
                  );
                },
                child: Text(
                  tile.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
                      onPressed: () {
                        controller.selectTile(tile);
                        controller.splitTileVertical(tile);
                      },
                    ),
                  ),
                  Tooltip(
                    message: "Split Horizontally (Left/Right)",
                    child: IconButton(
                      icon: Icon(Icons.horizontal_split, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        controller.selectTile(tile);
                        controller.splitTileHorizontal(tile);
                      },
                    ),
                  ),
                ],
              ),
            // Maximize/Restore button (only in floating mode)
            if (!controller.tilingMode.value)
              Tooltip(
                message:
                    tile.isMaximized ? "Restore Window" : "Maximize Window",
                child: IconButton(
                  icon: Icon(
                    tile.isMaximized ? Icons.filter_none : Icons.crop_square,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () {
                    controller.selectTile(tile);
                    if (tile.isMaximized) {
                      controller.restoreTile(tile);
                    } else {
                      controller.maximizeTile(tile);
                    }
                  },
                ),
              ),
            // Close button
            Tooltip(
              message: "Close Window",
              child: IconButton(
                icon: Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  controller.selectTile(tile);
                  controller.closeTile(tile);
                },
              ),
            ),
          ],
        ),
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
      case TileType.image:
        return Icon(Icons.image, size: 16);
    }
  }

  Widget _buildTileContent(WindowTile tile) {
    switch (tile.type) {
      case TileType.webView:
        // Find the WebWindowController for this tile
        final wm = Get.find<WindowManagerService>();
        final controller = wm.getWindow(tile.id);
        if (controller is WebWindowController) {
          return Obx(() {
            final refreshKey = controller.refreshCounter.value;
            print(
                '🔄 [REFRESH] Building WebViewTile with refreshKey: $refreshKey for window: ${tile.id}');
            return WebViewTile(
              key: ValueKey('${tile.id}_$refreshKey'),
              url: tile.url,
              refreshKey: refreshKey,
              windowId: tile.id,
            );
          });
        } else {
          // Fallback: just show the webview without refresh support
          print(
              '⚠️ [REFRESH] No WebWindowController found for window: ${tile.id}, using regular WebViewTile but passing windowId');
          return WebViewTile(
            key: ValueKey(tile.id),
            url: tile.url,
            windowId: tile.id,
          );
        }
      case TileType.media:
        return MediaTile(url: tile.url);
      case TileType.audio:
        return AudioTile(url: tile.url);
      case TileType.image:
        return ImageTile(
            url: tile.url, imageUrls: tile.imageUrls, showControls: true);
    }
  }

  Widget _buildResizeHandle(WindowTile tile) {
    return GestureDetector(
      onPanStart: (_) {
        // Highlight window when starting to resize
        controller.selectTile(tile);
      },
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

  Widget _buildToolbar(BuildContext context, bool locked) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left-side toolbar buttons
          ...[
            _buildToolbarButton(
              icon: Icons.web,
              label: 'Web',
              onPressed: locked ? null : () => _showAddWebViewDialog(context),
              locked: locked,
            ),
            _buildToolbarButton(
              icon: Icons.video_collection_rounded,
              label: 'Video',
              onPressed: locked
                  ? null
                  : () => _showAddMediaDialog(context, isAudio: false),
              locked: locked,
            ),
            _buildToolbarButton(
              icon: Icons.music_note_rounded,
              label: 'Audio',
              onPressed: locked
                  ? null
                  : () => _showAddMediaDialog(context, isAudio: true),
              locked: locked,
            ),
            _buildToolbarButton(
              icon: controller.tilingMode.value
                  ? Icons.grid_view_rounded
                  : Icons.view_carousel_rounded,
              label: controller.tilingMode.value ? 'Tiling' : 'Floating',
              onPressed: locked ? null : () => controller.toggleWindowMode(),
              locked: locked,
            ),
            _buildToolbarButton(
              icon: Icons.info_outline_rounded,
              label: 'IDs',
              onPressed: locked ? null : () => _showWindowIdsDialog(context),
              locked: locked,
            ),
            _buildToolbarButton(
              icon: Icons.dashboard_customize_rounded,
              label: 'System Info',
              onPressed: locked ? null : () => _showSystemInfoDialog(context),
              locked: locked,
            ),
          ],
          // Center lock icon
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () async {
                    if (locked) {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Unlock Kiosk'),
                          content: Builder(
                            builder: (context) {
                              final pinPadKey =
                                  GlobalKey<SettingsLockPinPadState>();
                              return SettingsLockPinPad(
                                key: pinPadKey,
                                onPinEntered: (pin) {
                                  if (pin ==
                                      settingsController.settingsPin.value) {
                                    settingsController.unlockSettings();
                                    Navigator.of(context).pop(true);
                                  } else {
                                    pinPadKey.currentState
                                        ?.showError('Incorrect PIN');
                                  }
                                },
                                pinLength: 4,
                              );
                            },
                          ),
                        ),
                      );
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unlocked!',
                              style: TextStyle(
                                color: Get.isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            backgroundColor:
                                Get.isDarkMode ? Colors.white : Colors.black,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      settingsController.lockSettings();
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: locked
                        ? Icon(Icons.lock_rounded,
                            key: ValueKey('locked'),
                            color: Colors.redAccent,
                            size: 38)
                        : Icon(Icons.lock_open_rounded,
                            key: ValueKey('unlocked'),
                            color: Colors.greenAccent,
                            size: 38),
                  ),
                ),
              ),
            ),
          ), // System info and settings
          _buildCompactSystemInfo(),
          // Notification Badge
          NotificationBadge(),
          SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Enter PIN to Access Settings'),
                  content: Builder(
                    builder: (context) {
                      final pinPadKey = GlobalKey<SettingsLockPinPadState>();
                      return SettingsLockPinPad(
                        key: pinPadKey,
                        onPinEntered: (pin) {
                          if (pin == settingsController.settingsPin.value) {
                            Navigator.of(context).pop(true);
                          } else {
                            pinPadKey.currentState?.showError('Incorrect PIN');
                          }
                        },
                        pinLength: 4,
                      );
                    },
                  ),
                ),
              );
              if (result == true) {
                _navigateToSettings();
              }
            },
            locked: false,
          ),
          SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.exit_to_app_rounded,
            label: 'Exit',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Enter PIN to Exit Application'),
                  content: Builder(
                    builder: (context) {
                      final pinPadKey = GlobalKey<SettingsLockPinPadState>();
                      return SettingsLockPinPad(
                        key: pinPadKey,
                        onPinEntered: (pin) {
                          if (pin == settingsController.settingsPin.value) {
                            Navigator.of(context).pop(true);
                          } else {
                            pinPadKey.currentState?.showError('Incorrect PIN');
                          }
                        },
                        pinLength: 4,
                      );
                    },
                  ),
                ),
              );
              if (result == true) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Exit'),
                    content:
                        Text('Are you sure you want to exit the application?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Yes'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _exitApplication();
                }
              }
            },
            locked: false,
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Builds a compact system info display for the toolbar
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
  }

  /// Builds compact CPU and Memory stats display
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

  // Toolbar button builder for the bottom toolbar
  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool locked = false,
  }) {
    return InkWell(
      onTap: locked ? null : onPressed,
      child: Opacity(
        opacity: locked ? 0.4 : 1.0,
        child: Container(
          height: 46,
          constraints: BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWebViewDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController urlController =
        TextEditingController(text: 'https://');

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
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  controller.addWebViewTile(
                      nameController.text, urlController.text);
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
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  if (isAudio) {
                    controller.addAudioTile(
                        nameController.text, urlController.text);
                  } else {
                    controller.addMediaTile(
                        nameController.text, urlController.text);
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

  void _showWindowIdsDialog(BuildContext context) {
    final tiles = controller.tiles;
    Future.microtask(() {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Text('Window IDs'),
            ],
          ),
          content: Container(
            width: 400,
            child: Obx(() => ListView(
                  shrinkWrap: true,
                  children: tiles
                      .map((tile) => ListTile(
                            title: Text(tile.name),
                            subtitle: Text(
                                'ID: ${tile.id}\nType: ${tile.type.toString().split('.').last}\nURL: ${tile.url}'),
                            dense: true,
                            trailing: IconButton(
                              icon: Icon(Icons.copy),
                              tooltip: 'Copy ID',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: tile.id));
                                Get.snackbar(
                                  'Copied',
                                  'Window ID copied to clipboard',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Get.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  colorText: Get.isDarkMode
                                      ? Colors.black
                                      : Colors.white,
                                );
                              },
                            ),
                          ))
                      .toList(),
                )),
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
  } // Build the notification center with auto-hide behavior that matches the toolbar

  Widget _buildNotificationCenter() {
    final notificationService = Get.find<NotificationService>();

    return Obx(() {
      // Don't render anything if notification center is closed
      if (!notificationService.isNotificationCenterOpen) {
        return SizedBox.shrink();
      }

      // Calculate appropriate positioning for notification center
      final screenSize = MediaQuery.of(context).size;

      // On smaller screens, take up more width. On larger screens, maintain a good width
      final width = screenSize.width < 600
          ? screenSize.width * 0.9
          : (screenSize.width < 1200 ? 380 : 420);

      // On mobile, push it away from the edge a bit
      final rightPadding = PlatformUtils.isMobile ? 8.0 : 0.0;

      // Make sure notification center doesn't extend past the bottom toolbar
      final bottomPadding = 64.0;
      return Positioned(
        top: 16,
        right: rightPadding,
        bottom: bottomPadding,
        width: width.toDouble(),
        child: GestureDetector(
          // This prevents clicks on the notification center from being handled by widgets behind it
          behavior: HitTestBehavior.opaque,
          onTap:
              () {}, // Empty onTap to prevent clicks from propagating through
          child: NotificationCenter(),
        ),
      );
    });
  }

  // Helper method to exit the application
  void _exitApplication() async {
    // Add a small delay to allow the dialog to close first
    await Future.delayed(const Duration(milliseconds: 300));

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exiting application...',
          style: TextStyle(
            color: Get.isDarkMode ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: Get.isDarkMode ? Colors.white : Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    // Add another small delay for the user to see the snackbar
    await Future.delayed(const Duration(seconds: 1));

    // Exit the application
    PlatformUtils.exitApplication();
  }
}

/// Auto-hiding toolbar widget that shows on hover or tap
/// Also coordinates with notification center visibility
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
  late NotificationService _notificationService;
  @override
  void initState() {
    super.initState();
    // Find the notification service
    _notificationService = Get.find<NotificationService>();

    // Listen to changes in notification center visibility
    _notificationService.notificationCenterVisibilityStream
        .listen((bool isOpen) {
      if (isOpen && !_isVisible) {
        // If notification center opens but toolbar is hidden, show the toolbar
        showToolbar();
      }
    });
  }

  // Expose a method to show the toolbar from outside (e.g., from handle)
  void showToolbar() {
    setState(() => _isVisible = true);
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        // When hiding toolbar, also close notification center if it's open
        if (_notificationService.isNotificationCenterOpen) {
          _notificationService.toggleNotificationCenter();
        }
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !_isVisible, // Only allow interaction when visible
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isVisible ? 50 : 0, // Fully hide when not visible
          curve: Curves.easeInOut,
          child: _isVisible ? widget.child : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
