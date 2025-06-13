import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';
import '../widgets/image_tile.dart';

class ImageWindowController extends GetxController
    implements KioskWindowController {
  @override
  final String windowName;
  final String imageUrl;
  final List<String> imageUrls;
  final VoidCallback? closeCallback; // Renamed from onClose to avoid conflict
  final String displayType; // 'single', 'carousel', or 'auto'
  final Duration? autoPlayInterval;

  @override
  KioskWindowType get windowType => KioskWindowType.custom;

  // Reactive properties for dynamic updates
  final RxList<String> _dynamicImageUrls = <String>[].obs;
  final RxString _currentImageUrl = ''.obs;
  final RxString _displayMode = 'single'.obs;
  final RxBool _autoPlay = true.obs;
  final RxInt _autoPlaySeconds = 5.obs;

  // Getters for reactive properties
  List<String> get dynamicImageUrls => _dynamicImageUrls;
  String get currentImageUrl => _currentImageUrl.value;
  String get displayMode => _displayMode.value;
  bool get autoPlay => _autoPlay.value;
  int get autoPlaySeconds => _autoPlaySeconds.value;

  ImageWindowController({
    required this.windowName,
    required this.imageUrl,
    this.imageUrls = const [], // Default to empty list
    this.closeCallback,
    this.displayType = 'auto', // Default to auto-detect
    this.autoPlayInterval,
  }) {
    // Initialize reactive properties
    _currentImageUrl.value = imageUrl;
    _dynamicImageUrls.assignAll(imageUrls);

    // Determine display mode
    if (displayType == 'carousel' ||
        (displayType == 'auto' && imageUrls.length > 1)) {
      _displayMode.value = 'carousel';
    } else {
      _displayMode.value = 'single';
    }

    // Set auto-play interval if provided
    if (autoPlayInterval != null) {
      _autoPlaySeconds.value = autoPlayInterval!.inSeconds;
    }

    print(
        '🖼️ ImageWindowController initialized: $windowName, mode: ${_displayMode.value}, images: ${_dynamicImageUrls.length}');
  }

  Widget buildWindow() {
    return Obx(() => ImageTile(
          url: _currentImageUrl.value,
          imageUrls: _dynamicImageUrls,
          showControls: true,
          autoPlayInterval: Duration(seconds: _autoPlaySeconds.value),
          onClose: () {
            if (closeCallback != null) {
              closeCallback!();
            }
          },
        ));
  }

  // Method to add images to carousel
  void addImage(String imageUrl) {
    if (!_dynamicImageUrls.contains(imageUrl)) {
      _dynamicImageUrls.add(imageUrl);
      print(
          '🖼️ Added image to carousel: $imageUrl (total: ${_dynamicImageUrls.length})');

      // Switch to carousel mode if we have multiple images
      if (_dynamicImageUrls.length > 1 && _displayMode.value == 'single') {
        _displayMode.value = 'carousel';
      }
    }
  }

  // Method to remove images from carousel
  void removeImage(String imageUrl) {
    if (_dynamicImageUrls.remove(imageUrl)) {
      print(
          '🖼️ Removed image from carousel: $imageUrl (remaining: ${_dynamicImageUrls.length})');

      // Switch to single mode if we only have one image left
      if (_dynamicImageUrls.length <= 1 && _displayMode.value == 'carousel') {
        _displayMode.value = 'single';
      }
    }
  }

  // Method to replace all images
  void setImages(List<String> newImageUrls) {
    _dynamicImageUrls.assignAll(newImageUrls);
    if (newImageUrls.isNotEmpty) {
      _currentImageUrl.value = newImageUrls.first;
    }

    // Update display mode
    _displayMode.value = newImageUrls.length > 1 ? 'carousel' : 'single';
    print(
        '🖼️ Set images for carousel: ${newImageUrls.length} images, mode: ${_displayMode.value}');
  }

  // Method to set auto-play settings
  void setAutoPlay(bool enabled, {int? intervalSeconds}) {
    _autoPlay.value = enabled;
    if (intervalSeconds != null) {
      _autoPlaySeconds.value = intervalSeconds;
    }
    print(
        '🖼️ Auto-play settings: enabled=$enabled, interval=${_autoPlaySeconds.value}s');
  }

  @override
  void handleCommand(String command, Map<String, dynamic>? payload) {
    // Handle any MQTT commands specific to image windows
    switch (command) {
      case 'reload':
        // Reload current image(s)
        update();
        break;
      case 'close':
        if (closeCallback != null) {
          closeCallback!();
        }
        break;
      case 'add_image':
        if (payload != null && payload['url'] is String) {
          addImage(payload['url'] as String);
        }
        break;
      case 'remove_image':
        if (payload != null && payload['url'] is String) {
          removeImage(payload['url'] as String);
        }
        break;
      case 'set_images':
        if (payload != null && payload['urls'] is List) {
          final urls = (payload['urls'] as List).cast<String>();
          setImages(urls);
        }
        break;
      case 'set_carousel':
        if (payload != null) {
          final urls = payload['urls'] as List<String>? ?? [];
          final interval = payload['interval'] as int? ?? 5;
          final autoPlay = payload['auto_play'] as bool? ?? true;

          setImages(urls);
          setAutoPlay(autoPlay, intervalSeconds: interval);
        }
        break;
      case 'set_autoplay':
        if (payload != null) {
          final enabled = payload['enabled'] as bool? ?? true;
          final interval = payload['interval'] as int? ?? 5;
          setAutoPlay(enabled, intervalSeconds: interval);
        }
        break;
      case 'next_image':
        // This would be handled by the carousel widget internally
        break;
      case 'previous_image':
        // This would be handled by the carousel widget internally
        break;
      default:
        print('Unknown command for image window: $command');
        break;
    }
  }

  @override
  void disposeWindow() {
    // Clean up any resources
    _dynamicImageUrls.clear();
    print('🖼️ ImageWindowController disposed: $windowName');
  }

  // This is the inherited method from GetxController
  @override
  void onClose() {
    // Clean up any resources if needed
    super.onClose();
  }

  // Factory method to create a carousel image window
  static ImageWindowController createCarousel({
    required String windowName,
    required List<String> imageUrls,
    VoidCallback? closeCallback,
    Duration autoPlayInterval = const Duration(seconds: 5),
  }) {
    return ImageWindowController(
      windowName: windowName,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      imageUrls: imageUrls,
      closeCallback: closeCallback,
      displayType: 'carousel',
      autoPlayInterval: autoPlayInterval,
    );
  }

  // Factory method to create a single image window
  static ImageWindowController createSingle({
    required String windowName,
    required String imageUrl,
    VoidCallback? closeCallback,
  }) {
    return ImageWindowController(
      windowName: windowName,
      imageUrl: imageUrl,
      imageUrls: [imageUrl],
      closeCallback: closeCallback,
      displayType: 'single',
    );
  }
}
