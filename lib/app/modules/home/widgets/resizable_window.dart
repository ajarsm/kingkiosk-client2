import 'package:flutter/material.dart';

/// A widget that provides resize handles for a window-like container
class ResizableWindow extends StatefulWidget {
  final Widget child;
  final Function(Size) onResize;
  final Size initialSize;
  final double minWidth;
  final double minHeight;
  
  const ResizableWindow({
    Key? key,
    required this.child,
    required this.onResize,
    required this.initialSize,
    this.minWidth = 200,
    this.minHeight = 100,
  }) : super(key: key);

  @override
  _ResizableWindowState createState() => _ResizableWindowState();
}

class _ResizableWindowState extends State<ResizableWindow> {
  late Size _size;
  
  @override
  void initState() {
    super.initState();
    _size = widget.initialSize;
  }
  
  @override
  void didUpdateWidget(ResizableWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSize != widget.initialSize) {
      _size = widget.initialSize;
    }
  }
  
  void _updateSize(double dx, double dy) {
    final newWidth = _size.width + dx;
    final newHeight = _size.height + dy;
    
    setState(() {
      _size = Size(
        newWidth > widget.minWidth ? newWidth : widget.minWidth,
        newHeight > widget.minHeight ? newHeight : widget.minHeight,
      );
    });
    
    widget.onResize(_size);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size.width,
      height: _size.height,
      child: Stack(
        children: [
          // Main content
          Positioned.fill(child: widget.child),
          
          // Right edge resize handle
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                onPanUpdate: (details) => _updateSize(details.delta.dx, 0),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Bottom edge resize handle
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                onPanUpdate: (details) => _updateSize(0, details.delta.dy),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Bottom-right corner resize handle
          Positioned(
            right: 0,
            bottom: 0,
            width: 20,
            height: 20,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeDownRight,
              child: GestureDetector(
                onPanUpdate: (details) => _updateSize(details.delta.dx, details.delta.dy),
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.drag_handle, size: 12, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}