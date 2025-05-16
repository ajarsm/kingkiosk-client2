import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../widgets/image_tile.dart';

class ImageWindowController extends GetxController implements KioskWindowController {
  @override
  final String windowName;
  final String imageUrl;
  final List<String> imageUrls;
  final VoidCallback? closeCallback; // Renamed from onClose to avoid conflict
  
  @override
  KioskWindowType get windowType => KioskWindowType.custom;
  
  ImageWindowController({
    required this.windowName,
    required this.imageUrl,
    this.imageUrls = const [], // Default to empty list
    this.closeCallback,
  });
  
  Widget buildWindow() {
    return ImageTile(
      url: imageUrl,
      imageUrls: imageUrls,
      showControls: true,
      onClose: () {
        if (closeCallback != null) {
          closeCallback!();
        }
      },
    );
  }
  
  @override
  void handleCommand(String command, Map<String, dynamic>? payload) {
    // Handle any MQTT commands specific to image windows
    switch (command) {
      case 'reload':
        // If we supported reloading, we would trigger it here
        break;
      case 'close':
        if (closeCallback != null) {
          closeCallback!();
        }
        break;
      default:
        print('Unknown command for image window: $command');
        break;
    }
  }
  
  @override
  void disposeWindow() {
    // Nothing specific to dispose for images
  }
  
  // This is the inherited method from GetxController
  @override
  void onClose() {
    // Clean up any resources if needed
    super.onClose();
  }
}
