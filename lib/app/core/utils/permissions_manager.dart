import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart';

/// PermissionsManager handles various permissions for mobile platforms.
class PermissionsManager {
  /// Request camera and microphone permissions if on iOS or Android.
  static Future<bool> requestCameraAndMicPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // No permissions needed for desktop/web
      return true;
    }
    final cameraStatus = await perm.Permission.camera.request();
    final micStatus = await perm.Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Check if camera and microphone permissions are granted.
  static Future<bool> hasCameraAndMicPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    final cameraStatus = await perm.Permission.camera.status;
    final micStatus = await perm.Permission.microphone.status;
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Request location permission for all platforms using geolocator.
  static Future<bool> requestLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // No permissions needed for desktop/web
      return true;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permission permanently denied. Please enable in settings.');
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted.
  static Future<bool> hasLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Open app settings for the user to grant permissions.
  static Future<bool> openAppSettings() async {
    return await perm
        .openAppSettings(); // Use the top-level function from permission_handler
  }
}
