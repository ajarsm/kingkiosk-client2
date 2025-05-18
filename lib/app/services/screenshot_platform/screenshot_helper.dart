// Platform-specific implementation for screenshot functionality

import 'dart:typed_data';

/// Abstract class for platform-specific screenshot operations
abstract class PlatformScreenshotHelper {
  /// Check if platform needs storage permissions
  bool get needsStoragePermissions;

  /// Request permissions needed for screenshots on this platform
  Future<bool> requestPermissions();

  /// Save a screenshot to an appropriate location and return the path
  Future<String> saveScreenshot(Uint8List bytes, String filename);

  /// Publish the screenshot to the system's gallery if applicable
  Future<bool> publishToGallery(Uint8List bytes, String name);

  /// Returns platform name for logging
  String get platformName;
}

/// Factory to create platform-appropriate helper
class PlatformScreenshotHelperFactory {
  /// Creates a platform-appropriate screenshot helper
  ///
  /// The actual implementation of this method comes from screenshot_helper_impl.dart
  /// We use a "trampoline" pattern where this base file defines the interface,
  /// and the implementation file provides the actual implementation
  static PlatformScreenshotHelper create() {
    // Import the implementation
    // When screenshot_helper_impl.dart is imported first, its implementation will be used
    return createHelper();
  }
}

/// This is defined externally in screenshot_helper_impl.dart
/// We just declare the signature here to maintain type safety
external PlatformScreenshotHelper createHelper();
