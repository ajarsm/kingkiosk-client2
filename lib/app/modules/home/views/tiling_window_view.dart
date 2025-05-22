import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/tiling_window_controller.dart';
import '../widgets/web_view_tile.dart';
import '../widgets/media_tile.dart';
import '../widgets/audio_tile.dart';
import '../widgets/image_tile.dart';
import '../widgets/auto_hide_title_bar.dart';
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
import '../../../services/ai_assistant_service.dart';
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
  // Optional reference to AI assistant service
  AiAssistantService? aiAssistantService;
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

    // Try to find AI Assistant service if available
    try {
      aiAssistantService = Get.find<AiAssistantService>();
    } catch (e) {
      // AI Assistant service may not be ready yet
      debugPrint('AI Assistant service not available yet: $e');

      // Set up delayed retry
      Future.delayed(Duration(seconds: 3), () {
        try {
          aiAssistantService = Get.find<AiAssistantService>();
          setState(() {}); // Refresh UI once service is available
        } catch (e) {
          debugPrint('Still cannot find AI Assistant service: $e');
        }
      });
    }

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
                )), // Translucent notification indicator in upper right corner
            const TranslucentNotificationIndicator(
              opacity: 0.4, // Slightly more visible
              size: 28.0,
              padding: EdgeInsets.only(top: 20, right: 20),
            ),
            // Floating AI button for call hangup
            _buildFloatingAiButton(),
            // Edge handle for toolbar/appbar reveal (mobile and desktop)            if (PlatformUtils.isMobile)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior
                      .opaque, // Only detect gestures on the visible handle
                  onDoubleTap: () {
                    _autoHidingToolbarKey.currentState?.showToolbar();
                  },
                  onLongPress: () {
                    _autoHidingToolbarKey.currentState?.showToolbar();
                  },
                  child: Container(
                    width:
                        60, // Only make the handle itself receive touch events
                    height: 24,
                    alignment: Alignment.topCenter,
                    color: Colors.transparent,
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
                child: Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior
                          .opaque, // Only detect gestures on the visible handle
                      onTap: () {
                        _autoHidingToolbarKey.currentState?.showToolbar();
                      },
                      child: Container(
                        width:
                            60, // Only make the handle itself receive touch events
                        height: 16,
                        alignment: Alignment.topCenter,
                        color: Colors.transparent,
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

            // Translucent AI hangup button in upper right when call is active
            if (aiAssistantService != null)
              Obx(() {
                if (aiAssistantService!.isAiCallActive.value) {
                  return Positioned(
                    top: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: () => aiAssistantService!.endAiCall(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(14),
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.blueAccent.withOpacity(0.85),
                          size: 36,
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              }),

            // Floating AI button for quickly hanging up during calls
            _buildFloatingAiButton(),
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
        return MouseRegion(
          onEnter: (_) {
            print('DEBUG: Mouse entered window ${tile.name}');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
              borderRadius: BorderRadius.circular(24),
            ),
            child: _buildTitleBar(tile, locked),
          ),
        );
      }),
    );
  }

  Widget _buildTitleBar(WindowTile tile, bool locked) {
    return AutoHideTitleBar(
      tile: tile,
      locked: locked,
      icon: _getIconForTileType(tile.type),
      isTilingMode: controller.tilingMode.value,
      onSelectTile: (tile) => controller.selectTile(tile),
      onUpdatePosition: (tile, offset) =>
          controller.updateTilePosition(tile, offset),
      onSplitVertical: (tile) => controller.splitTileVertical(tile),
      onSplitHorizontal: (tile) => controller.splitTileHorizontal(tile),
      onMaximize: (tile) => controller.maximizeTile(tile),
      onRestore: (tile) => controller.restoreTile(tile),
      onClose: (tile) => controller.closeTile(tile),
      contentBuilder: (tile) => _buildTileContent(tile),
      onSizeChanged: !controller.tilingMode.value && !locked
          ? (tile, size) => controller.updateTileSize(tile, size)
          : null,
      initiallyVisible: true,
      alwaysVisible: false, // Set to true for debugging if needed
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
              url: tile.url,
              refreshKey: refreshKey,
              windowId: tile.id,
            );
          });
        } else {
          // Create the WebViewTile without a controller - it will self-register
          return WebViewTile(
            url: tile.url,
            windowId: tile.id,
          );
        }

      case TileType.media:
        return MediaTile(
          url: tile.url,
          loop: tile.loop,
        );

      case TileType.audio:
        return AudioTile(
          url: tile.url,
        );

      case TileType.image:
        return ImageTile(
          url: tile.url,
          imageUrls: tile.imageUrls,
        );
    }
  }

  Widget _buildBottomToolbar(bool locked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
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
            _buildAiAssistantButton(),
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

  // Build the AI Assistant button that shows call state
  Widget _buildAiAssistantButton() {
    // If AI assistant service is not available yet, show a loading icon
    if (aiAssistantService == null) {
      return _buildToolbarButton(
        icon: Icons.smart_toy_outlined,
        label: 'AI Loading',
        onPressed: null,
        locked: true,
      );
    }

    return Obx(() {
      // Check if AI is enabled in settings
      if (!aiAssistantService!.isAiEnabled.value) {
        // AI is disabled, show greyed out button
        return _buildToolbarButton(
          icon: Icons.smart_toy,
          label: 'AI (Off)',
          onPressed: null,
          locked: true,
        );
      }
      // AI call is active - show call status and button to end
      if (aiAssistantService!.isAiCallActive.value) {
        // Choose icon based on call state
        IconData callIcon;
        Color iconColor;
        String statusLabel;

        switch (aiAssistantService!.aiCallState.value) {
          case 'connecting':
            callIcon = Icons.smart_toy;
            iconColor = Colors.amber;
            statusLabel = 'Connecting';
            break;
          case 'connected':
          case 'confirmed':
            callIcon = Icons.smart_toy;
            iconColor = Colors.green;
            statusLabel = 'Active';
            break;
          case 'failed':
            callIcon = Icons.smart_toy_outlined;
            iconColor = Colors.red;
            statusLabel = 'Failed';
            break;
          case 'ended':
            callIcon = Icons.smart_toy_outlined;
            iconColor = Colors.grey;
            statusLabel = 'Ended';
            break;
          default:
            callIcon = Icons.smart_toy;
            iconColor = Colors.blue;
            statusLabel = 'In Call';
        }
        // Return styled button with active call state
        return InkWell(
          onTap: () => aiAssistantService!.endAiCall(),
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
                    Icon(callIcon, color: iconColor, size: 18),
                    const SizedBox(height: 1),
                    Text(
                      statusLabel,
                      style: TextStyle(color: iconColor, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      // Default state - AI is enabled but not in a call
      return _buildToolbarButton(
        icon: Icons.smart_toy,
        label: 'AI',
        onPressed: () {
          if (aiAssistantService!.isAiCallActive.value) {
            aiAssistantService!.endAiCall();
          } else {
            aiAssistantService!.callAiAssistant();
          }
        },
        locked: false,
      );
    });
  }

  // Toolbar for the kiosk with all buttons and controls
  Widget _buildToolbar(BuildContext context, bool locked) {
    return _buildBottomToolbar(locked);
  }

  // Floating AI button for quickly hanging up during calls
  Widget _buildFloatingAiButton() {
    if (aiAssistantService == null) {
      return const SizedBox.shrink(); // No button if service not available
    }

    return Obx(() {
      // Only show the button when an AI call is active
      if (!aiAssistantService!.isAiCallActive.value) {
        return const SizedBox.shrink(); // Hide when no active call
      }

      // Choose icon based on call state
      IconData callIcon;
      Color iconColor;
      Color bgColor;

      switch (aiAssistantService!.aiCallState.value) {
        case 'connecting':
          callIcon = Icons.call_end_rounded;
          iconColor = Colors.white;
          bgColor = Colors.amber.withOpacity(0.7);
          break;
        case 'connected':
        case 'confirmed':
          callIcon = Icons.call_end_rounded;
          iconColor = Colors.white;
          bgColor = Colors.red.withOpacity(0.7);
          break;
        case 'failed':
          return const SizedBox.shrink(); // Hide button on call failure
        case 'ended':
          return const SizedBox.shrink(); // Hide button when call ended
        default:
          callIcon = Icons.call_end_rounded;
          iconColor = Colors.white;
          bgColor = Colors.red.withOpacity(0.7);
      } // Return a translucent floating button in the corner that doesn't block input events to what's below
      return Positioned(
        top: 16,
        right: 16,
        child: Material(
          elevation: 3,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => aiAssistantService!.endAiCall(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(callIcon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'End Call',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
