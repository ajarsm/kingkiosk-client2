// filepath: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/auto_hide_title_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/window_tile_v2.dart';

/// A title bar for windows that auto-hides and shows on hover/touch
class AutoHideTitleBar extends StatefulWidget {
  final WindowTile tile;
  final bool locked;
  final Widget icon;
  final bool isTilingMode;
  final Function(WindowTile) onSelectTile;
  final Function(WindowTile, Offset) onUpdatePosition;
  final Function(WindowTile) onSplitVertical;
  final Function(WindowTile) onSplitHorizontal;
  final Function(WindowTile) onMaximize;
  final Function(WindowTile) onRestore;
  final Function(WindowTile) onClose;

  // Control whether title bar is initially visible (default: true)
  final bool initiallyVisible;

  // Set whether to always show the title bar (for debugging)
  final bool alwaysVisible;

  // Window content builder
  final Widget Function(WindowTile tile) contentBuilder;

  // Resize callback (only used in floating mode)
  final Function(WindowTile, Size)? onSizeChanged;

  const AutoHideTitleBar({
    Key? key,
    required this.tile,
    required this.locked,
    required this.icon,
    required this.isTilingMode,
    required this.onSelectTile,
    required this.onUpdatePosition,
    required this.onSplitVertical,
    required this.onSplitHorizontal,
    required this.onMaximize,
    required this.onRestore,
    required this.onClose,
    required this.contentBuilder,
    this.onSizeChanged,
    this.initiallyVisible = true,
    this.alwaysVisible = false,
  }) : super(key: key);

  @override
  State<AutoHideTitleBar> createState() => _AutoHideTitleBarState();
}

class _AutoHideTitleBarState extends State<AutoHideTitleBar> {
  bool _isVisible = true; // Start visible for better user experience
  bool _isHovering = false;
  Timer? _hideTimer;

  // Title bar height when visible
  final double _titleBarHeight = 30.0;

  // Resize handle height when visible
  final double _resizeHandleHeight = 20.0;

  // Duration before auto-hiding
  final Duration _autoHideDelay =
      Duration(seconds: 5); // Increased for better usability

  // Debug mode to visualize hover area
  final bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    // Use the initiallyVisible property
    _isVisible = widget.initiallyVisible;

    // If not always visible, start the hide timer
    if (!widget.alwaysVisible && _isVisible) {
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    // Don't start timer if always visible
    if (widget.alwaysVisible) return;

    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted && !_isHovering) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _showTitleBar() {
    setState(() {
      _isVisible = true;
    });
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Content placed here to be under other elements
        Positioned.fill(
          top: (widget.alwaysVisible || _isVisible) ? _titleBarHeight : 0,
          child: widget.contentBuilder(widget.tile),
        ),

        // Subtle indicator for where to hover (always visible)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 4,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Get.isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  Get.isDarkMode
                      ? Colors.white.withOpacity(0.0)
                      : Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Hover detection area - ONLY the top portion of the window
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height:
              60, // Only detect hover at the top 60 pixels, not the entire window
          child: MouseRegion(
            onEnter: (_) {
              print('DEBUG: Mouse entered top area for ${widget.tile.name}');
              setState(() {
                _isHovering = true;
                _isVisible = true;
              });
            },
            onExit: (_) {
              print(
                  'DEBUG: Mouse exited top area for window ${widget.tile.name}');
              setState(() {
                _isHovering = false;
              });
              _startHideTimer();
            },
            onHover: (_) {
              // Ensure title bar is visible on hover
              if (!_isVisible) {
                setState(() {
                  _isVisible = true;
                });
              }
            },
            child: GestureDetector(
              behavior:
                  HitTestBehavior.opaque, // Only detect gestures where visible
              onTap: () {
                _showTitleBar();
              },
              // Container for hover area - visualized in debug mode
              child: Container(
                color: _debugMode
                    ? Colors.red.withOpacity(0.2)
                    : Colors.transparent,
                child: _debugMode
                    ? Center(
                        child: Text('Hover Area',
                            style: TextStyle(color: Colors.white)))
                    : null,
              ),
            ),
          ),
        ),

        // Actual title bar with transition and subtle shadow for better visibility
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          top: 0,
          left: 0,
          right: 0,
          height: (widget.alwaysVisible || _isVisible) ? _titleBarHeight : 0,
          child: Container(
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.grey[800] : Colors.grey[200],
              boxShadow: (widget.alwaysVisible || _isVisible)
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4.0,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: (widget.alwaysVisible || _isVisible)
                ? _buildTitleBarContent()
                : SizedBox.shrink(),
          ),
        ),

        // Resize handle at bottom (only in floating mode)
        if (widget.onSizeChanged != null && !widget.isTilingMode)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: 0,
            right: 0,
            bottom: 0,
            height:
                (widget.alwaysVisible || _isVisible) ? _resizeHandleHeight : 0,
            child: (widget.alwaysVisible || _isVisible)
                ? _buildResizeHandle()
                : SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildResizeHandle() {
    if (widget.locked) return SizedBox.shrink();

    return Column(
      children: [
        // Resize handle with visual indicator
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (widget.onSizeChanged != null) {
                  final newHeight = widget.tile.size.height + details.delta.dy;
                  final minHeight = 180.0;
                  if (newHeight >= minHeight) {
                    widget.onSizeChanged!(
                      widget.tile,
                      Size(widget.tile.size.width, newHeight),
                    );
                  }
                }
              },
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Corner resize handle (for width and height simultaneously)
        Align(
          alignment: Alignment.bottomRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeDownRight,
            child: GestureDetector(
              onPanUpdate: (details) {
                if (widget.onSizeChanged != null) {
                  final newWidth = widget.tile.size.width + details.delta.dx;
                  final newHeight = widget.tile.size.height + details.delta.dy;
                  final minWidth = 250.0;
                  final minHeight = 180.0;
                  widget.onSizeChanged!(
                    widget.tile,
                    Size(
                      newWidth >= minWidth ? newWidth : minWidth,
                      newHeight >= minHeight ? newHeight : minHeight,
                    ),
                  );
                }
              },
              child: Container(
                height: 16,
                width: 16,
                alignment: Alignment.bottomRight,
                child: Icon(Icons.drag_handle, size: 12, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBarContent() {
    return AbsorbPointer(
      absorbing: widget.locked,
      child: Row(
        children: [
          // Window icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: widget.icon,
          ),

          // Window title (drag area)
          Expanded(
            child: GestureDetector(
              onPanStart: (_) {
                // Highlight window when starting to drag
                widget.onSelectTile(widget.tile);
              },
              onPanUpdate: (details) {
                widget.onUpdatePosition(
                  widget.tile,
                  Offset(
                    widget.tile.position.dx + details.delta.dx,
                    widget.tile.position.dy + details.delta.dy,
                  ),
                );
              },
              child: Text(
                widget.tile.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Split buttons (only in tiling mode)
          if (widget.isTilingMode)
            Row(
              children: [
                Tooltip(
                  message: "Split Vertically (Top/Bottom)",
                  child: IconButton(
                    icon: Icon(Icons.vertical_split, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      widget.onSelectTile(widget.tile);
                      widget.onSplitVertical(widget.tile);
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
                      widget.onSelectTile(widget.tile);
                      widget.onSplitHorizontal(widget.tile);
                    },
                  ),
                ),
              ],
            ),

          // Maximize/Restore button (only in floating mode)
          if (!widget.isTilingMode)
            Tooltip(
              message: widget.tile.isMaximized
                  ? "Restore Window"
                  : "Maximize Window",
              child: IconButton(
                icon: Icon(
                  widget.tile.isMaximized
                      ? Icons.filter_none
                      : Icons.crop_square,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  widget.onSelectTile(widget.tile);
                  if (widget.tile.isMaximized) {
                    widget.onRestore(widget.tile);
                  } else {
                    widget.onMaximize(widget.tile);
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
              onPressed: () => widget.onClose(widget.tile),
            ),
          ),

          SizedBox(width: 8),
        ],
      ),
    );
  }
}
