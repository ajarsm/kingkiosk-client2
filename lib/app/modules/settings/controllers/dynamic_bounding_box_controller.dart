import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DynamicBoundingBoxController extends GetxController {
  final Rx<Size?> imageSize = Rx<Size?>(null);

  void decodeImageSize(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      imageSize.value = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } catch (e) {
      // Handle error silently
    }
  }
}
