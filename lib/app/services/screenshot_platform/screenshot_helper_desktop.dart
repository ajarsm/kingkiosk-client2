// Desktop-specific implementation for macOS, Windows, Linux

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'screenshot_helper.dart';

// General desktop implementation
class DesktopScreenshotHelper extends PlatformScreenshotHelper {
  @override
  bool get needsStoragePermissions => false;

  @override
  String get platformName => Platform.operatingSystem;

  @override
  Future<bool> publishToGallery(Uint8List bytes, String name) async {
    // Desktop platforms don't have a gallery concept like mobile
    // Return true since we're not expected to do anything
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    // Desktop platforms don't need explicit permissions for basic file operations
    return true;
  }

  @override
  Future<String> saveScreenshot(Uint8List bytes, String filename) async {
    try {
      // Get the most appropriate directory for screenshots
      final Directory docDir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${docDir.path}/KingKiosk/Screenshots');

      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final file = File('${screenshotsDir.path}/$filename');
      await file.writeAsBytes(bytes);
      print('💾 ${platformName}: Screenshot saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ ${platformName}: Error saving screenshot: $e');
      return '';
    }
  }
}

// Platform-specific helper factory implementation
@Deprecated('Use PlatformScreenshotHelperFactory.create() instead')
PlatformScreenshotHelper createPlatformSpecificHelper() {
  return DesktopScreenshotHelper();
}
