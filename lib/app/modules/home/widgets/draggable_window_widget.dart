import 'package:flutter/material.dart';
import '../../../data/models/window_tile.dart';

/// A widget that provides a draggable and resizable window
/// with proper support for both mouse and touch input
class DraggableWindowWidget extends StatefulWidget {
  final WindowTile tile;
  final bool isSelected;
  final Widget titleBarContent;
  final Widget content;
  final Function(WindowTile tile) onSelect;
  final Function(WindowTile tile) onClose;
  final Function(WindowTile tile, Offset position) onPositionChanged;
  final Function(WindowTile tile, Size size) onSizeChanged;
  
  const DraggableWindowWidget({
    Key? key,
    required this.tile,
    required this.isSelected,
    required this.titleBarContent,
    required this.content,
    required this.onSelect,
    required this.onClose,
    required this.onPositionChanged,
    required this.onSizeChanged,
  }) : super(key: key);

  @override
  _DraggableWindowWidgetState createState() => _DraggableWindowWidgetState();
}

class _DraggableWindowWidgetState extends State<DraggableWindowWidget> {
  // Minimum window size constraints - increased for better fit
  final double minWidth = 250.0;
  final double minHeight = 180.0;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.tile.size.width,
      height: widget.tile.size.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.isSelected ? Colors.blue : Colors.grey,
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isSelected 
                ? Colors.blue.withOpacity(0.3) 
                : Colors.black.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar - draggable area
          GestureDetector(
            onTap: () => widget.onSelect(widget.tile),
            onPanUpdate: (details) {
              widget.onPositionChanged(
                widget.tile, 
                Offset(
                  widget.tile.position.dx + details.delta.dx,
                  widget.tile.position.dy + details.delta.dy,
                ),
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: Container(
                height: 30,
                color: Colors.grey[200],
                child: Row(
                  children: [
                    // Title bar content (icon, title)
                    Expanded(child: widget.titleBarContent),
                    
                    // Close button
                    IconButton(
                      icon: Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () => widget.onClose(widget.tile),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onSelect(widget.tile),
              child: widget.content,
            ),
          ),
          
          // Bottom resize area with drag handles
          _buildResizeHandles(),
        ],
      ),
    );
  }
  
  Widget _buildResizeHandles() {
    return Stack(
      children: [
        // Bottom edge resize handle
        Container(
          height: 8,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                final newHeight = widget.tile.size.height + details.delta.dy;
                if (newHeight >= minHeight) {
                  widget.onSizeChanged(
                    widget.tile, 
                    Size(widget.tile.size.width, newHeight),
                  );
                }
              },
            ),
          ),
        ),
        
        // Right edge resize handle
        Positioned(
          right: 0,
          top: -30, // Extend up to include the full height
          bottom: 0,
          width: 8,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final newWidth = widget.tile.size.width + details.delta.dx;
                if (newWidth >= minWidth) {
                  widget.onSizeChanged(
                    widget.tile, 
                    Size(newWidth, widget.tile.size.height),
                  );
                }
              },
            ),
          ),
        ),
        
        // Corner drag handle
        Positioned(
          right: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeDownRight,
            child: GestureDetector(
              onPanUpdate: (details) {
                final newWidth = widget.tile.size.width + details.delta.dx;
                final newHeight = widget.tile.size.height + details.delta.dy;
                widget.onSizeChanged(
                  widget.tile, 
                  Size(
                    newWidth >= minWidth ? newWidth : minWidth,
                    newHeight >= minHeight ? newHeight : minHeight,
                  ),
                );
              },
              child: Container(
                height: 20,
                width: 20,
                alignment: Alignment.bottomRight,
                child: Icon(Icons.drag_handle, size: 16, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }
}