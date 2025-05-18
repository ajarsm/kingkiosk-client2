// Mobile-specific implementation for Android/iOS

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'screenshot_helper.dart';

// Implementation for iOS
class IOSScreenshotHelper extends PlatformScreenshotHelper {
  @override
  bool get needsStoragePermissions => true;

  @override
  String get platformName => 'iOS';

  @override
  Future<bool> publishToGallery(Uint8List bytes, String name) async {
    try {
      // Add explicit file extension to ensure proper PNG file format
      final nameWithExtension = name.endsWith('.png') ? name : '$name.png';

      print('📱 iOS: Saving screenshot to gallery as "$nameWithExtension"');

      // Create a temporary file with proper PNG format
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$nameWithExtension');

      // Write the raw bytes directly to the file
      await tempFile.writeAsBytes(bytes);
      print('📱 iOS: Temporary file created at: ${tempFile.path}');

      // Use the file path method instead of direct bytes to ensure proper format is maintained
      final result = await ImageGallerySaverPlus.saveFile(tempFile.path);
      print('📱 iOS: Image gallery save result: $result');

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
        print('📱 iOS: Temporary file deleted');
      }

      return true;
    } catch (e) {
      print('❌ iOS: Error saving to gallery: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final photosStatus = await Permission.photos.status;

      if (photosStatus.isDenied) {
        print('📱 iOS: Photos permission is denied, requesting...');
        final result = await Permission.photos.request();
        return result.isGranted;
      } else if (photosStatus.isPermanentlyDenied) {
        print(
            '⚠️ iOS: Photos permission is permanently denied, open app settings');
        Get.snackbar(
          'Photos Permission Required',
          'Please enable photos access in app settings to save screenshots',
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        );
        return false;
      }

      print('✅ iOS: Photos permission already granted');
      return true;
    } catch (e) {
      print('❌ iOS: Error checking permissions: $e');
      return false;
    }
  }

  @override
  Future<String> saveScreenshot(Uint8List bytes, String filename) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${documentsDir.path}/screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final file = File('${screenshotsDir.path}/$filename');
      await file.writeAsBytes(bytes);
      print('💾 iOS: Screenshot saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ iOS: Error saving screenshot: $e');
      return '';
    }
  }
}

// Implementation for Android
class AndroidScreenshotHelper extends PlatformScreenshotHelper {
  @override
  bool get needsStoragePermissions => true;

  @override
  String get platformName => 'Android';

  @override
  Future<bool> publishToGallery(Uint8List bytes, String name) async {
    try {
      // Ensure permissions are granted before saving
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('❌ Android: Cannot save to gallery - permission denied');
        return false;
      }

      // Try to save the image with better error handling
      try {
        // Add explicit file extension to ensure proper PNG file format
        final nameWithExtension = name.endsWith('.png') ? name : '$name.png';

        print(
            '📱 Android: Saving screenshot to gallery as "$nameWithExtension"');

        // Create a temporary file with proper PNG format
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$nameWithExtension');

        // Write raw binary data to file
        await tempFile.writeAsBytes(bytes);
        print('📱 Android: Created temporary file at: ${tempFile.path}');

        // Check if tempFile was written correctly
        if (!(await tempFile.exists())) {
          throw Exception('Failed to create temporary file');
        }

        final fileSize = await tempFile.length();
        print('📱 Android: Temporary file size: ${fileSize} bytes');

        // Now save the file to gallery using saveFile instead of saveImage
        final result = await ImageGallerySaverPlus.saveFile(tempFile.path);
        print('📱 Android: Image gallery save result: $result');

        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
          print('📱 Android: Temporary file deleted');
        }

        // Check if result indicates success
        if (result is Map) {
          final isSuccess = result['isSuccess'] ?? false;
          if (!isSuccess) {
            print('⚠️ Android: Gallery save reported failure: $result');
            return false;
          }
        }

        return true;
      } catch (e) {
        print('❌ Android: Image gallery save error: $e');

        // Show error to user
        Get.snackbar(
          'Screenshot Error',
          'Could not save screenshot to gallery: ${e.toString().split('\n').first}',
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('❌ Android: Error in publishToGallery: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // First check Android version to determine which permissions to request
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      print('📱 Android SDK Version: $sdkInt');

      if (sdkInt >= 33) {
        // Android 13+
        // For Android 13 and higher, we need to request Photos permissions
        print('📱 Android 13+: Requesting Photos permission');
        final photosStatus = await Permission.photos.status;

        if (photosStatus.isDenied) {
          print('📱 Android: Photos permission is denied, requesting...');
          final result = await Permission.photos.request();
          return result.isGranted;
        } else if (photosStatus.isPermanentlyDenied) {
          _showPermissionSnackbar('Photos');
          return false;
        }

        print('✅ Android 13+: Photos permission already granted');
        return true;
      } else if (sdkInt >= 29) {
        // Android 10-12
        // For Android 10-12, we need access to media locations and storage
        print('📱 Android 10-12: Requesting Media Locations');

        // Try both media locations and storage for better compatibility
        final mediaLocationStatus = await Permission.mediaLibrary.status;
        final storageStatus = await Permission.storage.status;

        if (mediaLocationStatus.isDenied) {
          final mediaResult = await Permission.mediaLibrary.request();
          if (!mediaResult.isGranted) {
            if (mediaResult.isPermanentlyDenied) {
              _showPermissionSnackbar('Media Library');
            }
            // Try storage permissions as fallback
            if (storageStatus.isDenied) {
              final storageResult = await Permission.storage.request();
              return storageResult.isGranted;
            }
          }
          return mediaResult.isGranted;
        }

        print('✅ Android 10-12: Media permissions granted');
        return true;
      } else {
        // For Android 9 and below, we just need storage permission
        final storageStatus = await Permission.storage.status;

        if (storageStatus.isDenied) {
          print('📱 Android ≤9: Storage permission is denied, requesting...');
          final result = await Permission.storage.request();
          return result.isGranted;
        } else if (storageStatus.isPermanentlyDenied) {
          _showPermissionSnackbar('Storage');
          return false;
        }

        print('✅ Android ≤9: Storage permission already granted');
        return true;
      }
    } catch (e) {
      print('❌ Android: Error checking permissions: $e');
      return false;
    }
  }

  // Helper to show consistent permission snackbars
  void _showPermissionSnackbar(String permissionType) {
    print('⚠️ Android: $permissionType permission is permanently denied');
    Get.snackbar(
      '$permissionType Permission Required',
      'Please enable $permissionType access in app settings to save screenshots',
      duration: Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      mainButton: TextButton(
        onPressed: () => openAppSettings(),
        child: Text('Open Settings', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Future<String> saveScreenshot(Uint8List bytes, String filename) async {
    try {
      // Ensure permissions are granted before saving
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('❌ Android: Cannot save screenshot - permission denied');
        return '';
      }

      // Try to find best directory for saving files based on Android version
      Directory? saveDir;
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      try {
        if (sdkInt >= 30) {
          // Android 11+
          // On Android 11+, we should use app-specific directories
          saveDir = await getApplicationDocumentsDirectory();
          print('📱 Android 11+: Using application documents directory');
        } else {
          // Try external storage first for Android 10 and below
          try {
            saveDir = await getExternalStorageDirectory();
            print('📱 Android: Using external storage directory');
          } catch (e) {
            // Fall back to application documents
            saveDir = await getApplicationDocumentsDirectory();
            print(
                '📱 Android: Using application documents directory (fallback)');
          }
        }
      } catch (e) {
        // Final fallback - use temp directory
        saveDir = await getTemporaryDirectory();
        print('📱 Android: Using temporary directory (fallback)');
      }

      if (saveDir == null) {
        throw Exception('Could not find a valid directory to save screenshots');
      }

      final screenshotsDir = Directory('${saveDir.path}/screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final file = File('${screenshotsDir.path}/$filename');
      await file.writeAsBytes(bytes);
      print('💾 Android: Screenshot saved to: ${file.path}');

      // For files saved outside gallery, trigger a media scan to make them visible
      if (sdkInt < 30) {
        // Not needed in Android 11+ with scoped storage
        try {
          // Note: This would ideally use the media scanner, but we'll handle it via gallery
          // We're treating gallery save as a separate step, so nothing extra needed here
        } catch (e) {
          print('⚠️ Android: Media scan failed: $e');
        }
      }

      return file.path;
    } catch (e) {
      print('❌ Android: Error saving screenshot: $e');

      // Show error to user
      Get.snackbar(
        'Screenshot Error',
        'Could not save screenshot: ${e.toString().split('\n').first}',
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.7),
        colorText: Colors.white,
      );

      return '';
    }
  }
}

// Mobile helper implementation selector
@Deprecated('Use PlatformScreenshotHelperFactory.create() instead')
PlatformScreenshotHelper createPlatformSpecificHelper() {
  if (Platform.isIOS) {
    return IOSScreenshotHelper();
  } else {
    return AndroidScreenshotHelper();
  }
}
