import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// PermissionsManager handles camera and microphone permissions for mobile platforms.
class PermissionsManager {
  /// Request camera and microphone permissions if on iOS or Android.
  static Future<bool> requestCameraAndMicPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // No permissions needed for desktop/web
      return true;
    }
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Check if camera and microphone permissions are granted.
  static Future<bool> hasCameraAndMicPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Open app settings for the user to grant permissions.
  static Future<void> openAppSettings() async {
    await openAppSettings(); // Use the top-level function from permission_handler
  }
}
