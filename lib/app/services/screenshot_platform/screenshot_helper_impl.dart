// Platform selector implementation

import 'dart:io';

import 'screenshot_helper.dart';

// Import platform-specific implementations
import 'screenshot_helper_mobile.dart'
    if (dart.library.html) 'screenshot_helper_stub.dart';
import 'screenshot_helper_desktop.dart'
    if (dart.library.html) 'screenshot_helper_stub.dart';

/// Extension to override the factory method with our platform-specific implementation
extension PlatformScreenshotHelperFactoryImpl
    on PlatformScreenshotHelperFactory {
  // We can't actually override static methods in Dart, but we can "replace" the implementation
  // by importing this file instead of using the original method
}

/// Implementation of the factory create method
/// This replaces the stub in the base class
PlatformScreenshotHelper createHelper() {
  if (Platform.isAndroid || Platform.isIOS) {
    // Use mobile implementation from screenshot_helper_mobile.dart
    return mobilePlatformHelper();
  } else {
    // Use desktop implementation from screenshot_helper_desktop.dart
    return desktopPlatformHelper();
  }
}

// Platform-specific factory implementations
PlatformScreenshotHelper mobilePlatformHelper() =>
    Platform.isIOS ? IOSScreenshotHelper() : AndroidScreenshotHelper();

PlatformScreenshotHelper desktopPlatformHelper() => DesktopScreenshotHelper();

// For backwards compatibility with any code that was directly calling this
@Deprecated('Use PlatformScreenshotHelperFactory.create() instead')
PlatformScreenshotHelper createPlatformSpecificHelper() => createHelper();
