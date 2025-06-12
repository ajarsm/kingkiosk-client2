import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../../controllers/app_state_controller.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../data/models/window_tile_v2.dart';
import '../../../modules/settings/controllers/settings_controller_compat.dart';
import '../../../routes/app_pages.dart';
import '../../../services/ai_assistant_service.dart';
import '../../../services/navigation_service.dart';
import '../../../services/platform_sensor_service.dart';
import '../../../services/window_manager_service.dart';
import '../../../widgets/system_info_dashboard.dart';
import '../../../widgets/settings_lock_pin_pad.dart';
import '../controllers/tiling_window_controller.dart';
import '../controllers/web_window_controller.dart';
import '../widgets/auto_hide_title_bar.dart';
import '../widgets/media_tile.dart';
import '../widgets/audio_tile.dart';
import '../widgets/audio_visualizer_tile.dart';
import '../widgets/image_tile.dart';
import '../widgets/pdf_tile.dart';
import '../widgets/webview_tile_manager.dart';
import '../widgets/youtube_player_tile.dart';
import '../widgets/clock_widget.dart';
import '../widgets/alarmo_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/calendar_widget.dart';
import '../../../widgets/window_halo_wrapper.dart';
import 'package:king_kiosk/notification_system/notification_system.dart';

class TilingWindowView extends StatefulWidget {
  const TilingWindowView({Key? key}) : super(key: key);

  @override
  TilingWindowViewState createState() => TilingWindowViewState();
}

class TilingWindowViewState extends State<TilingWindowView> {
  // ---------------------------------------------------------------------------
  // Cached services / controllers
  // ---------------------------------------------------------------------------
  late final TilingWindowController controller;
  late final AppStateController appStateController;
  late final PlatformSensorService sensorService;
  late final SettingsControllerFixed settingsController;
  AiAssistantService? aiAssistantService;

  late final StreamSubscription kioskModeSub;

  // Auto-hiding toolbar key
  final GlobalKey<_AutoHidingToolbarState> _autoHidingToolbarKey =
      GlobalKey<_AutoHidingToolbarState>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    controller = Get.find<TilingWindowController>();
    appStateController = Get.find<AppStateController>();
    sensorService = Get.find<PlatformSensorService>();
    settingsController = Get.find<SettingsControllerFixed>();

    // Try to locate AI assistant (may not yet be registered)
    Future<void>(() async {
      try {
        aiAssistantService = Get.find<AiAssistantService>();
      } catch (_) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          aiAssistantService = Get.find<AiAssistantService>();
        } catch (_) {}
      }
    });

    // Sync kiosk mode with platform utils
    kioskModeSub = settingsController.kioskMode.listen((enabled) {
      enabled
          ? PlatformUtils.enableKioskMode()
          : PlatformUtils.disableKioskMode();
    });
    if (settingsController.kioskMode.value) {
      PlatformUtils.enableKioskMode();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sz = MediaQuery.of(context).size;
    controller
        .setContainerBoundsIfChanged(Rect.fromLTWH(0, 0, sz.width, sz.height));
  }

  @override
  void dispose() {
    kioskModeSub.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final locked = settingsController.isSettingsLocked.value;
        return Stack(
          children: [
            _buildBackground(),
            // --- windows -----------------------------------------------------
            Obx(() => Stack(
                  children: controller.tiles
                      .map((tile) => _buildWindowTile(tile, locked))
                      .toList(),
                )),
            // --- translucent notifications -----------------------------------
            const TranslucentNotificationIndicator(
              opacity: 0.4,
              size: 28,
              padding: EdgeInsets.only(top: 20, right: 20),
            ),
            // --- AI floating button ------------------------------------------
            _buildFloatingAiButton(),
            // --- toolbar (auto-hiding) ---------------------------------------
            _AutoHidingToolbar(
              key: _autoHidingToolbarKey,
              child: _buildToolbar(context, locked),
            ),
            // --- grab handle --------------------------------------------------
            Obx(() {
              final visible =
                  _autoHidingToolbarKey.currentState?.isToolbarVisible.value ??
                      false;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: visible ? 0 : 1,
                child: IgnorePointer(
                  ignoring: visible,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap:
                              _autoHidingToolbarKey.currentState?.showToolbar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // --- notification center -----------------------------------------
            _buildNotificationCenter(),
            // --- small AI hang-up button -------------------------------------
            if (aiAssistantService != null)
              Obx(() {
                if (!aiAssistantService!.isAiCallActive.value) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: aiAssistantService!.endAiCall,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.blueAccent.withOpacity(0.85),
                        size: 36,
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------
  Widget _buildBackground() {
    final type = settingsController.backgroundType.value;

    if (type == 'image') {
      final path = settingsController.backgroundImagePath.value;
      if (path.isNotEmpty) {
        return Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.18,
              child: FractionallySizedBox(
                widthFactor: 0.7,
                heightFactor: 0.7,
                child: _buildImageWidget(path),
              ),
            ),
          ),
        );
      }
    } else if (type == 'webview') {
      final url = settingsController.backgroundWebUrl.value;
      if (url.isNotEmpty) {
        return Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: IgnorePointer(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(url)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  disableContextMenu: true,
                  supportZoom: false,
                  transparentBackground: true,
                  disableHorizontalScroll: true,
                  disableVerticalScroll: true,
                  allowsBackForwardNavigationGestures: false,
                  allowsLinkPreview: false,
                  isFraudulentWebsiteWarningEnabled: false,
                  clearCache: false,
                ),
                onLoadStart: (_, __) =>
                    debugPrint('🌐 Background webview started loading'),
                onLoadStop: (_, __) =>
                    debugPrint('✅ Background webview finished loading'),
                onLoadError: (_, __, ___, message) =>
                    debugPrint('❌ Background webview load error: $message'),
              ),
            ),
          ),
        );
      }
    }
    // default fallback
    return _defaultBackground();
  }

  Widget _defaultBackground() => Positioned.fill(
        child: Center(
          child: Opacity(
            opacity: 0.18,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.5,
              child: Image.asset(
                'assets/images/Royal Kiosk with Wi-Fi Waves.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: Colors.white.withOpacity(0.5),
            ),
          );
        },
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    debugPrint('❌ Local image file does not exist: $path');
    return _buildErrorPlaceholder();
  }

  Widget _buildErrorPlaceholder() => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image,
                color: Colors.grey.withOpacity(0.5), size: 48),
            const SizedBox(height: 8),
            Text(
              'Image failed to load',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Window tiles
  // ---------------------------------------------------------------------------
  Widget _buildWindowTile(WindowTile tile, bool locked) {
    if (tile.type == TileType.webView) {
      final wm = Get.find<WindowManagerService>();
      final webCtrl = wm.getWindow(tile.id);
      if (webCtrl is WebWindowController) {
        return Obx(() {
          webCtrl.refreshCounter.value; // reactive
          return _buildWindowTileCore(tile, locked);
        });
      }
    }
    return _buildWindowTileCore(tile, locked);
  }

  Widget _buildWindowTileCore(WindowTile tile, bool locked) => Positioned(
        left: tile.position.dx,
        top: tile.position.dy,
        width: tile.size.width,
        height: tile.size.height,
        child: MouseRegion(
          onEnter: (_) => debugPrint('Mouse entered window ${tile.name}'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(24),
            ),
            child: _buildTitleBar(tile, locked),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Title bar & content
  // ---------------------------------------------------------------------------
  Widget _buildTitleBar(WindowTile tile, bool locked) {
    return AutoHideTitleBar(
      tile: tile,
      locked: locked,
      icon: _iconForType(tile.type),
      isTilingMode: controller.tilingMode.value,
      onSelectTile: controller.selectTile,
      onUpdatePosition: controller.updateTilePosition,
      onSplitVertical: controller.splitTileVertical,
      onSplitHorizontal: controller.splitTileHorizontal,
      onMaximize: controller.maximizeTile,
      onRestore: controller.restoreTile,
      onClose: controller.closeTile,
      contentBuilder: _buildTileContent,
      onSizeChanged: !controller.tilingMode.value && !locked
          ? controller.updateTileSize
          : null,
      initiallyVisible: true,
      alwaysVisible: false,
    );
  }

  Icon _iconForType(TileType t) {
    switch (t) {
      case TileType.webView:
        return const Icon(Icons.web, size: 16);
      case TileType.media:
        return const Icon(Icons.video_file, size: 16);
      case TileType.audio:
        return const Icon(Icons.audio_file, size: 16);
      case TileType.audioVisualizer:
        return const Icon(Icons.graphic_eq, size: 16);
      case TileType.image:
        return const Icon(Icons.image, size: 16);
      case TileType.youtube:
        return const Icon(Icons.smart_display, size: 16);
      case TileType.pdf:
        return const Icon(Icons.picture_as_pdf, size: 16);
      case TileType.clock:
        return const Icon(Icons.access_time, size: 16);
      case TileType.alarmo:
        return const Icon(Icons.security, size: 16);
      case TileType.weather:
        return const Icon(Icons.wb_sunny, size: 16);
      case TileType.calendar:
        return const Icon(Icons.calendar_today, size: 16);
    }
  }

  Widget _buildTileContent(WindowTile tile) {
    late final Widget content;
    switch (tile.type) {
      case TileType.webView:
        final wm = Get.find<WindowManagerService>();
        final web = wm.getWindow(tile.id);
        if (web is WebWindowController) {
          content = Obx(() {
            web.refreshCounter.value;
            return WebViewTileManager().getWebViewTileFor(tile.id, tile.url,
                refreshKey: web.refreshCounter.value);
          });
        } else {
          content = WebViewTileManager().getWebViewTileFor(tile.id, tile.url);
        }
        break;
      case TileType.youtube:
        String vid = tile.metadata?['videoId'] as String? ??
            YouTubePlayerManager.extractVideoId(tile.url) ??
            '';
        content = YouTubePlayerManager().getYouTubePlayerTileFor(
          tile.id,
          tile.url,
          vid,
          autoplay: true,
          showControls: true,
          showInfo: true,
        );
        break;
      case TileType.media:
        content = MediaTile(url: tile.url, loop: tile.loop);
        break;
      case TileType.audio:
        content = AudioTile(url: tile.url);
        break;
      case TileType.audioVisualizer:
        content = AudioVisualizerTile(url: tile.url);
        break;
      case TileType.image:
        content = ImageTile(url: tile.url, imageUrls: tile.imageUrls);
        break;
      case TileType.pdf:
        content = PdfTile(url: tile.url, windowId: tile.id);
        break;
      case TileType.clock:
        content = ClockWidget(windowId: tile.id, showControls: false);
        break;
      case TileType.alarmo:
        content = AlarmoWidget(windowId: tile.id, showControls: false);
        break;
      case TileType.weather:
        content = WeatherWidget(windowId: tile.id, windowName: tile.name);
        break;
      case TileType.calendar:
        content = CalendarWidget(windowId: tile.id, showControls: false);
        break;
    }

    return WindowHaloWrapper(windowId: tile.id, child: content);
  }

  // ---------------------------------------------------------------------------
  // Toolbar helpers
  // ---------------------------------------------------------------------------
  Widget _buildToolbar(BuildContext context, bool locked) =>
      _buildBottomToolbar(locked);

  Widget _buildBottomToolbar(bool locked) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            label: 'Add',
            onPressed: locked
                ? null
                : () {
                    // Add your implementation here
                  },
            locked: locked,
          ),
          _buildToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onPressed: locked
                ? null
                : () {
                    Get.toNamed(Routes.SETTINGS);
                  },
            locked: locked,
          ),
        ],
      ),
    );
  }

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
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (The rest of the helper dialogs / toolbar / notification-center code
  //  is unchanged – only whitespace/commas tweaked for consistency)

  // ---------------------------------------------------------------------------
  // Floating AI button (fixed bracket / parenthesis mismatch)
  // ---------------------------------------------------------------------------
  Widget _buildFloatingAiButton() {
    if (aiAssistantService == null) return const SizedBox.shrink();

    return Obx(() {
      if (!aiAssistantService!.isAiEnabled.value ||
          !aiAssistantService!.isAiCallActive.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 80,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: aiAssistantService!.endAiCall,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.call_end, color: Colors.white, size: 24),
                    SizedBox(height: 2),
                    Text(
                      'End',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Notification center (unchanged)
  // ---------------------------------------------------------------------------
  Widget _buildNotificationCenter() {
    final notificationService = Get.find<NotificationService>();
    return Obx(() {
      if (!notificationService.isNotificationCenterOpen) {
        return const SizedBox.shrink();
      }

      final sz = MediaQuery.of(context).size;
      final width =
          sz.width < 600 ? sz.width * 0.9 : (sz.width < 1200 ? 380.0 : 420.0);

      final rightPad = PlatformUtils.isMobile ? 8.0 : 0.0;

      return Positioned(
        top: 16,
        right: rightPad,
        bottom: 64,
        width: width,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: NotificationCenter(),
        ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// Auto-hiding toolbar (unchanged – only minor formatting tweaks)
// -----------------------------------------------------------------------------
class _AutoHidingToolbar extends StatefulWidget {
  final Widget child;
  const _AutoHidingToolbar({Key? key, required this.child}) : super(key: key);

  @override
  _AutoHidingToolbarState createState() => _AutoHidingToolbarState();
}

class _AutoHidingToolbarState extends State<_AutoHidingToolbar> {
  Timer? _hideTimer;
  late final NotificationService _notificationService;
  final RxBool isToolbarVisible = false.obs;

  @override
  void initState() {
    super.initState();
    _notificationService = Get.find<NotificationService>();
    _notificationService.notificationCenterVisibilityStream.listen((isOpen) {
      if (isOpen && !isToolbarVisible.value) showToolbar();
    });
  }

  void showToolbar() {
    isToolbarVisible.value = true;
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (_notificationService.isNotificationCenterOpen) {
        _notificationService.toggleNotificationCenter();
      }
      isToolbarVisible.value = false;
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Obx(() {
          final visible = isToolbarVisible.value;
          return IgnorePointer(
            ignoring: !visible,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: visible ? 50 : 0,
              curve: Curves.easeInOut,
              child: visible ? widget.child : const SizedBox.shrink(),
            ),
          );
        }),
      );
}
