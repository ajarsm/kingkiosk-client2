import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/resizable_window_controller.dart';

/// A widget that provides resize handles for a window-like container
class ResizableWindow extends GetView<ResizableWindowController> {
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
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(ResizableWindowController(
      initialSize: initialSize,
      onResize: onResize,
      minWidth: minWidth,
      minHeight: minHeight,
    ));

    return Obx(() => Container(
          width: controller.size.value.width,
          height: controller.size.value.height,
          child: Stack(
            children: [
              // Main content
              Positioned.fill(child: child),

              // Right edge resize handle
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    onPanUpdate: (details) =>
                        controller.updateSize(details.delta.dx, 0),
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
                    onPanUpdate: (details) =>
                        controller.updateSize(0, details.delta.dy),
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
                    onPanUpdate: (details) => controller.updateSize(
                        details.delta.dx, details.delta.dy),
                    child: Container(
                      alignment: Alignment.bottomRight,
                      padding: EdgeInsets.all(4),
                      child:
                          Icon(Icons.drag_handle, size: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
