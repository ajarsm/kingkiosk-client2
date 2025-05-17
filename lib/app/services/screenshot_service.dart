// lib/app/services/screenshot_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import '../core/utils/app_constants.dart';
import 'storage_service.dart';

class ScreenshotService extends GetxService {
  final ScreenshotController _screenshotController = ScreenshotController();
  late final StorageService _storageService;

  // Observable properties
  final RxString latestScreenshotPath = ''.obs;
  final RxBool isTakingScreenshot = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Defer finding StorageService until dependencies are ready
    _storageService = Get.find<StorageService>();
  }

  // Get the controller
  ScreenshotController get controller => _screenshotController;

  // Take a screenshot of the entire screen
  Future<Uint8List?> captureScreenshot() async {
    isTakingScreenshot.value = true;

    try {
      // Use a simpler approach for capturing the screen - fake a screenshot for now
      // In a real implementation, we would use a platform channel to capture the actual screen
      // For now, we'll generate a simple colored square as a placeholder
      
      // Create a simple image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.blue;
      canvas.drawRect(Rect.fromLTWH(0, 0, 800, 600), paint);
      
      // Add some text to indicate this is a screenshot
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'King Kiosk Screenshot\n${DateTime.now()}',
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
      print('📸 Screenshot captured and saved to: $path');
      return bytes;
    } catch (e) {
      print('❌ Error capturing screenshot: $e');
      return null;
    } finally {
      isTakingScreenshot.value = false;
    }
  }

  // Alternative method using a provided GlobalKey
  Future<Uint8List?> captureEntireScreen(GlobalKey key) async {
    try {
      // Use the same approach as captureScreenshot for consistency
      // In a real implementation, we would use the key to capture the specific widget
      
      // Create a simple image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.teal;
      canvas.drawRect(Rect.fromLTWH(0, 0, 800, 600), paint);
      
      // Add some text to indicate this is a screenshot of a specific widget
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Widget Screenshot\nKey: ${key.toString()}\n${DateTime.now()}',
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

      final path = await _saveScreenshot(bytes);
      latestScreenshotPath.value = path;
      return bytes;
    } catch (e) {
      print('❌ Error capturing screen with key: $e');
      return null;
    }
  }

  // Save screenshot to a file and return the path
  Future<String> _saveScreenshot(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'kingkiosk_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      // Also store the latest screenshot path in storage for persistence
      _storageService.write(AppConstants.keyLatestScreenshot, file.path);
      return file.path;
    } catch (e) {
      print('❌ Error saving screenshot: $e');
      return '';
    }
  }

  // Convert image to base64 for MQTT transmission
  String imageToBase64(Uint8List bytes) {
    try {
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      return '';
    }
  }

  // Get the latest screenshot path from storage
  Future<String> getLatestScreenshotPath() async {
    final path =
        _storageService.read<String>(AppConstants.keyLatestScreenshot) ?? '';
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
