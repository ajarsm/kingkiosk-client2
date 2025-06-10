import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ResizableWindowController extends GetxController {
  final Rx<Size> size;
  final Function(Size) onResize;
  final double minWidth;
  final double minHeight;

  ResizableWindowController({
    required Size initialSize,
    required this.onResize,
    required this.minWidth,
    required this.minHeight,
  }) : size = initialSize.obs;

  void updateSize(double dx, double dy) {
    final newWidth = size.value.width + dx;
    final newHeight = size.value.height + dy;

    size.value = Size(
      newWidth > minWidth ? newWidth : minWidth,
      newHeight > minHeight ? newHeight : minHeight,
    );

    onResize(size.value);
  }

  void setSize(Size newSize) {
    size.value = newSize;
  }
}
