// lib/app/services/screenshot_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';

import '../core/utils/app_constants.dart';
import 'storage_service.dart';

// Platform helper implementation - contains the actual platform-specific code
import 'screenshot_platform/screenshot_helper_impl.dart' as impl;
// Abstract interface definition to maintain type safety
import 'screenshot_platform/screenshot_helper.dart'
    show PlatformScreenshotHelper;

class ScreenshotService extends GetxService {
  ScreenshotController _screenshotController = ScreenshotController();
  StorageService? _storageService;

  // Global key for widget tree screenshot
  final GlobalKey screenshotKey = GlobalKey();

  // Observable properties
  final RxString latestScreenshotPath = ''.obs;
  final RxBool isTakingScreenshot = false.obs;

  // Lazy getter for StorageService
  StorageService get _storage {
    _storageService ??= Get.find<StorageService>();
    return _storageService!;
  }

  // Static method to ensure the service is registered
  static ScreenshotService ensureInitialized() {
    if (!Get.isRegistered<ScreenshotService>()) {
      print('📸 ScreenshotService not found, registering new instance');
      final service = ScreenshotService();
      Get.put(service, permanent: true);
      return service;
    }
    return Get.find<ScreenshotService>();
  }

  // Update the controller from an external source
  // This is used when the main app creates a Screenshot widget
  void updateController(ScreenshotController controller) {
    _screenshotController = controller;
    print('✅ Screenshot controller updated from main app');
  }

  // Get the controller
  ScreenshotController get controller => _screenshotController;

  // Take a screenshot of the entire screen
  Future<Uint8List?> captureScreenshot() async {
    isTakingScreenshot.value = true;
    try {
      // Create platform-specific helper using the implementation directly
      // Explicitly use the interface type to ensure the import is used
      final PlatformScreenshotHelper helper = impl.createHelper();

      // Check and request permissions if needed for this platform
      if (helper.needsStoragePermissions) {
        final hasPermission = await _requestStoragePermissions();
        if (!hasPermission) {
          print('⚠️ Storage permission not granted, cannot save screenshot');
          // Show a notification to the user
          Get.snackbar('Permission Required',
              'Permission is needed to save screenshots on ${helper.platformName}',
              duration: Duration(seconds: 3),
              snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        print(
            '💻 Running on ${helper.platformName}, no permission checks needed');
      }

      // Use the Screenshot widget's controller to capture the screen
      print(
          '📸 Attempting to capture screenshot with Screenshot widget controller');
      final bytes = await _screenshotController.capture();

      if (bytes == null) {
        print(
            '⚠️ Screenshot controller returned null bytes, using fallback method');
        return _generateFallbackScreenshot();
      }

      // Save the screenshot
      final path = await _saveScreenshot(bytes);
      latestScreenshotPath.value = path;
      print('📸 Screenshot captured and saved to: $path');
      return bytes;
    } catch (e) {
      print('❌ Error capturing screenshot with controller: $e');
      print('⚠️ Falling back to generated placeholder image');

      // Fallback to generated image if screenshot fails
      return _generateFallbackScreenshot();
    } finally {
      isTakingScreenshot.value = false;
    }
  }

  // Generate a fallback screenshot when actual screenshot fails
  Future<Uint8List?> _generateFallbackScreenshot() async {
    try {
      // Create a simple image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.blue;
      canvas.drawRect(Rect.fromLTWH(0, 0, 800, 600), paint);

      // Add some text to indicate this is a fallback screenshot
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'King Kiosk Screenshot (Fallback)\n${DateTime.now()}',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 700);
      textPainter.paint(canvas, Offset(50, 50));

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(800, 600);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save the screenshot
      final path = await _saveScreenshot(bytes);
      latestScreenshotPath.value = path;
      print('📸 Fallback screenshot generated and saved to: $path');
      return bytes;
    } catch (e) {
      print('❌ Error generating fallback screenshot: $e');
      return null;
    }
  }

  // Alternative method using a provided GlobalKey
  Future<Uint8List?> captureEntireScreen(GlobalKey key) async {
    try {
      print('📸 Attempting to capture specific widget with key: $key');

      // Try to find the RenderRepaintBoundary for the key
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        // Capture the widget using the render object
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final Uint8List bytes = byteData.buffer.asUint8List();
          final path = await _saveScreenshot(bytes);
          latestScreenshotPath.value = path;
          print('📸 Widget screenshot captured and saved to: $path');
          return bytes;
        } else {
          print('❌ Failed to get byte data from widget image');
        }
      } else {
        print('❌ Could not find render boundary for key: $key');
      }

      // Fall back to the main screenshot method if the specific widget capture fails
      print('⚠️ Falling back to main screenshot method');
      return await captureScreenshot();
    } catch (e) {
      print('❌ Error capturing screen with key: $e');
      // Fall back to the main screenshot method
      return await captureScreenshot();
    }
  }

  // Save screenshot to a file and return the path
  Future<String> _saveScreenshot(Uint8List bytes) async {
    try {
      // Create platform-specific helper if needed
      // This explicitly uses the implementation to ensure the import is used
      final PlatformScreenshotHelper helper = impl.createHelper();
      print('🖥️ Using ${helper.platformName} screenshot helper');

      final fileName =
          'kingkiosk_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save screenshot using platform-specific implementation
      final path = await helper.saveScreenshot(bytes, fileName);

      // Try to publish to gallery (only works on mobile platforms)
      if (helper.needsStoragePermissions) {
        try {
          await helper.publishToGallery(
              bytes, 'KingKiosk_${DateTime.now().millisecondsSinceEpoch}');
        } catch (e) {
          print('⚠️ Error publishing to gallery: $e');
        }
      }

      // Store the latest screenshot path in storage for persistence
      if (path.isNotEmpty) {
        _storage.write(AppConstants.keyLatestScreenshot, path);
        print('💾 Screenshot saved to: $path');
      }
      return path;
    } catch (e) {
      print('❌ Error saving screenshot: $e');
      return '';
    }
  }

  // Request storage permissions based on platform
  Future<bool> _requestStoragePermissions() async {
    try {
      print('📱 Checking storage permissions...');

      // Create platform-specific helper using the implementation directly
      final PlatformScreenshotHelper helper = impl.createHelper();

      // Check if this platform needs permissions
      if (!helper.needsStoragePermissions) {
        print(
            'ℹ️ Platform ${helper.platformName} does not need storage permissions');
        return true;
      }

      print('📱 Requesting permissions for ${helper.platformName}');
      return await helper.requestPermissions();
    } catch (e) {
      print('❌ Error checking storage permissions: $e');
      return false;
    }
  }

  // Convert image to base64 for MQTT transmission
  String imageToBase64(Uint8List bytes) {
    try {
      // Ensure we're using raw image bytes and encoding them properly
      print('📸 Converting ${bytes.length} bytes of image data to base64');
      final encoded = base64Encode(bytes);
      print('📸 Base64 conversion complete, length: ${encoded.length}');
      return encoded;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      return '';
    }
  }

  // Get the latest screenshot path from storage
  Future<String> getLatestScreenshotPath() async {
    final path = _storage.read<String>(AppConstants.keyLatestScreenshot) ?? '';
    latestScreenshotPath.value = path;

    // Verify the file exists
    if (path.isNotEmpty) {
      final file = File(path);
      if (!await file.exists()) {
        latestScreenshotPath.value = '';
        return '';
      }
    }

    return path;
  }
}
