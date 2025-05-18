// Web stub implementation

import 'dart:typed_data';
import 'screenshot_helper.dart';

// Web screenshot helper
class WebScreenshotHelper extends PlatformScreenshotHelper {
  @override
  bool get needsStoragePermissions => false;

  @override
  String get platformName => 'web';

  @override
  Future<bool> publishToGallery(Uint8List bytes, String name) async {
    // Web doesn't have a gallery concept, but we can trigger a download
    try {
      // Normally we would use js interop here to trigger a download
      // using: html.AnchorElement, Blob, etc.
      print('💻 Web: Simulating gallery save via download');
      return true;
    } catch (e) {
      print('💻 Web: Gallery publishing error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    // Web has its own permission model that's handled by the browser
    return true;
  }

  @override
  Future<String> saveScreenshot(Uint8List bytes, String filename) async {
    try {
      // In a real implementation, we would:
      // 1. Convert bytes to a Blob using js interop
      // 2. Create an object URL
      // 3. Create a download link and trigger the click

      print(
          '💻 Web: Screenshot captured, would trigger download in real implementation');

      // We return a virtual path since web doesn't have file system access
      // This serves as a reference for the app to know a screenshot was taken
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'web:screenshot:$timestamp';
    } catch (e) {
      print('💻 Web: Error saving screenshot: $e');
      return '';
    }
  }
}

// Stub for conditional imports
class IOSScreenshotHelper extends WebScreenshotHelper {}

class AndroidScreenshotHelper extends WebScreenshotHelper {}

class DesktopScreenshotHelper extends WebScreenshotHelper {}

// Factory implementations for web
PlatformScreenshotHelper mobilePlatformHelper() => WebScreenshotHelper();
PlatformScreenshotHelper desktopPlatformHelper() => WebScreenshotHelper();

// Main factory implementation for web
@Deprecated('Use PlatformScreenshotHelperFactory.create() instead')
PlatformScreenshotHelper createPlatformSpecificHelper() {
  return WebScreenshotHelper();
}
