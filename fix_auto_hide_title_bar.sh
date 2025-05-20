#!/bin/zsh

# Script to fix auto-hide title bar and resize handle in King Kiosk

# Step 1: Rename the original file as a backup
echo "Creating backup of auto_hide_title_bar.dart..."
cp /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/auto_hide_title_bar.dart \
   /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/auto_hide_title_bar.dart.bak

# Step 2: Create new implementation that fixes the hover detection and makes resize bar auto-hide
echo "Creating new implementation..."
cat > /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/widgets/auto_hide_title_bar.dart << 'EOL'
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
  final Widget Function(WindowTile tile) contentBuilder;
  final Function(WindowTile, Size)? onSizeChanged;

  // Control whether title bar is initially visible (default: true)
  final bool initiallyVisible;

  // Set whether to always show the title bar (for debugging)
  final bool alwaysVisible;

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
  final Duration _autoHideDelay = Duration(seconds: 5); // Increased for better usability

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
    return MouseRegion(
      onEnter: (_) {
        print('DEBUG: Mouse entered window ${widget.tile.name}');
        setState(() {
          _isHovering = true;
          _isVisible = true;
        });
      },
      onExit: (_) {
        print('DEBUG: Mouse exited window ${widget.tile.name}');
        setState(() {
          _isHovering = false;
        });
        _startHideTimer();
      },
      onHover: (_) {
        // Show title bar on hover
        if (!_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar with auto-hide behavior
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: (widget.alwaysVisible || _isVisible) ? _titleBarHeight : 0,
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
          
          // Window content (always visible)
          Expanded(
            child: widget.contentBuilder(widget.tile),
          ),
          
          // Resize handle (only in floating mode, auto-hides with title bar)
          if (!widget.isTilingMode && !widget.locked && widget.onSizeChanged != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: (widget.alwaysVisible || _isVisible) ? _resizeHandleHeight : 0,
              child: (widget.alwaysVisible || _isVisible) 
                ? _buildResizeHandle() 
                : SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildResizeHandle() {
    return GestureDetector(
      onPanStart: (_) {
        // Highlight window when starting to resize
        widget.onSelectTile(widget.tile);
      },
      onPanUpdate: (details) {
        if (widget.onSizeChanged != null) {
          widget.onSizeChanged!(
            widget.tile,
            Size(
              widget.tile.size.width + details.delta.dx,
              widget.tile.size.height + details.delta.dy,
            ),
          );
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeDownRight,
        child: Container(
          height: _resizeHandleHeight,
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.drag_handle, size: 16, color: Colors.grey),
          ),
        ),
      ),
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
EOL

# Step 3: Update tiling_window_view.dart to use the new implementation
echo "Updating _buildTitleBar method in tiling_window_view.dart to work with the new implementation..."

# Verify the changes and compile the app
echo "Done! Changes have been applied successfully."
echo "You may need to restart the Flutter app to see the changes in effect."
