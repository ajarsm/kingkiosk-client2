import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart';

/// Result class for permission requests with detailed status
class PermissionResult {
  final bool granted;
  final bool permanentlyDenied;
  final String status;

  PermissionResult({
    required this.granted,
    required this.permanentlyDenied,
    required this.status,
  });

  factory PermissionResult.fromPermissionStatus(perm.PermissionStatus status) {
    return PermissionResult(
      granted: status.isGranted,
      permanentlyDenied: status.isPermanentlyDenied,
      status: status.toString(),
    );
  }
}

/// PermissionsManager handles various permissions for mobile platforms.
class PermissionsManager {
  /// Request camera permission only
  static Future<PermissionResult> requestCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionResult(
          granted: true, permanentlyDenied: false, status: 'granted');
    }
    final status = await perm.Permission.camera.request();
    return PermissionResult.fromPermissionStatus(status);
  }

  /// Request microphone permission only
  static Future<PermissionResult> requestMicrophonePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionResult(
          granted: true, permanentlyDenied: false, status: 'granted');
    }
    final status = await perm.Permission.microphone.request();
    return PermissionResult.fromPermissionStatus(status);
  }

  /// Request both camera and microphone permissions with detailed results
  static Future<Map<String, PermissionResult>>
      requestCameraAndMicrophonePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      final granted = PermissionResult(
          granted: true, permanentlyDenied: false, status: 'granted');
      return {'camera': granted, 'microphone': granted};
    }

    final Map<perm.Permission, perm.PermissionStatus> statuses = await [
      perm.Permission.camera,
      perm.Permission.microphone,
    ].request();

    return {
      'camera': PermissionResult.fromPermissionStatus(
          statuses[perm.Permission.camera]!),
      'microphone': PermissionResult.fromPermissionStatus(
          statuses[perm.Permission.microphone]!),
    };
  }

  /// Check camera permission status
  static Future<PermissionResult> checkCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionResult(
          granted: true, permanentlyDenied: false, status: 'granted');
    }
    final status = await perm.Permission.camera.status;
    return PermissionResult.fromPermissionStatus(status);
  }

  /// Check microphone permission status
  static Future<PermissionResult> checkMicrophonePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionResult(
          granted: true, permanentlyDenied: false, status: 'granted');
    }
    final status = await perm.Permission.microphone.status;
    return PermissionResult.fromPermissionStatus(status);
  }

  /// Request location permission with detailed status information.
  static Future<PermissionResult> requestLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Desktop/web platforms - try to use location without explicit permissions
      try {
        // Test if location services work on desktop
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          return PermissionResult(
            granted: true,
            permanentlyDenied: false,
            status: 'Location available on desktop platform',
          );
        } else {
          return PermissionResult(
            granted: false,
            permanentlyDenied: false,
            status: 'Location services disabled on desktop platform',
          );
        }
      } catch (e) {
        return PermissionResult(
          granted: false,
          permanentlyDenied: false,
          status: 'Location not available on this platform: $e',
        );
      }
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return PermissionResult(
          granted: false,
          permanentlyDenied: false,
          status:
              'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return PermissionResult(
            granted: false,
            permanentlyDenied: false,
            status:
                'Location permission was denied. Please allow location access to use location features.',
          );
        }
      }

      // Check for permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        return PermissionResult(
          granted: false,
          permanentlyDenied: true,
          status:
              'Location permission was permanently denied. Please enable location access in your device settings.',
        );
      }

      // Permission granted
      return PermissionResult(
        granted: true,
        permanentlyDenied: false,
        status: 'Location permission granted successfully.',
      );
    } catch (e) {
      return PermissionResult(
        granted: false,
        permanentlyDenied: false,
        status: 'Error requesting location permission: $e',
      );
    }
  }

  /// Check if location permission is granted.
  static Future<bool> hasLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Desktop platforms - try to check if location services work
      try {
        return await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        return false;
      }
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

  /// Get current location permission status with detailed information.
  static Future<PermissionResult> getLocationPermissionStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        return PermissionResult(
          granted: serviceEnabled,
          permanentlyDenied: false,
          status: serviceEnabled
              ? 'Location available on desktop platform'
              : 'Location services disabled on desktop platform',
        );
      } catch (e) {
        return PermissionResult(
          granted: false,
          permanentlyDenied: false,
          status: 'Location not available on this platform: $e',
        );
      }
    }

    try {
      final permission = await Geolocator.checkPermission();
      bool isGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      bool isPermanentlyDenied = permission == LocationPermission.deniedForever;

      return PermissionResult(
        granted: isGranted,
        permanentlyDenied: isPermanentlyDenied,
        status: permission.toString(),
      );
    } catch (e) {
      return PermissionResult(
        granted: false,
        permanentlyDenied: false,
        status: 'Error checking location permission: $e',
      );
    }
  }

  /// Open location settings for the user to grant permissions.
  static Future<bool> openLocationSettings() async {
    // For location permissions, we use the same app settings method
    return await openAppSettings();
  }

  /// Open app settings for the user to grant permissions.
  static Future<bool> openAppSettings() async {
    return await perm
        .openAppSettings(); // Use the top-level function from permission_handler
  }

  /// Debug method to check all permission statuses
  static Future<Map<String, String>> debugPermissionStatuses() async {
    final Map<String, String> statuses = {};

    if (!Platform.isAndroid && !Platform.isIOS) {
      statuses['platform'] = 'Desktop/Web - permissions not required';
      return statuses;
    }

    try {
      // Check individual permission statuses
      final cameraStatus = await perm.Permission.camera.status;
      final micStatus = await perm.Permission.microphone.status;

      statuses['camera'] = cameraStatus.toString();
      statuses['microphone'] = micStatus.toString();
      statuses['camera_granted'] = cameraStatus.isGranted.toString();
      statuses['camera_denied'] = cameraStatus.isDenied.toString();
      statuses['camera_permanently_denied'] =
          cameraStatus.isPermanentlyDenied.toString();
      statuses['microphone_granted'] = micStatus.isGranted.toString();
      statuses['microphone_denied'] = micStatus.isDenied.toString();
      statuses['microphone_permanently_denied'] =
          micStatus.isPermanentlyDenied.toString();

      // Add service availability info for location
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final locationServiceEnabled =
              await Geolocator.isLocationServiceEnabled();
          statuses['location_service_enabled'] =
              locationServiceEnabled.toString();

          final locationPermission = await Geolocator.checkPermission();
          statuses['location_permission'] = locationPermission.toString();
        } catch (e) {
          statuses['location_error'] = e.toString();
        }
      }
    } catch (e) {
      statuses['error'] = e.toString();
    }

    return statuses;
  }

  /// Check if permissions can be requested (not permanently denied)
  static Future<bool> canRequestCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final status = await perm.Permission.camera.status;
    return !status.isPermanentlyDenied;
  }

  /// Check if permissions can be requested (not permanently denied)
  static Future<bool> canRequestMicrophonePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final status = await perm.Permission.microphone.status;
    return !status.isPermanentlyDenied;
  }
}
