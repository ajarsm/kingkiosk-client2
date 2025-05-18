/// Image gallery saver stub for web platform
/// This file provides minimal stub implementations for image_gallery_saver package
import 'dart:typed_data';

// Stub class for ImageGallerySaver
class ImageGallerySaver {
  static Future<Map<String, dynamic>> saveImage(
    Uint8List bytes, {
    int quality = 80,
    String? name,
  }) async {
    return {'isSuccess': true, 'filePath': null};
  }
}
