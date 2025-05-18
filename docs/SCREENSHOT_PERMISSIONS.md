# Screenshot Permissions Guide

This document explains the permissions required for the screenshot feature in King Kiosk to work properly on different platforms.

## Android Permissions

For Android devices, the following permissions are required:

1. **For Android 9 (API level 28) and below**:
   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
       android:maxSdkVersion="28" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
       android:maxSdkVersion="32" />
   ```

2. **For Android 10 (API level 29) and above**:
   - No special permissions are needed for app-specific storage
   - If saving to shared storage (Photos/Gallery), the app will request permission at runtime

### Runtime Permission Handling

- The app will request storage permissions when attempting to take a screenshot
- For permanently denied permissions, users will be prompted to open app settings
- Screenshots will always be saved to the app's internal storage even if permissions are denied

## iOS Permissions

For iOS devices, we need photo library access to save screenshots:

1. **Info.plist Entries**:
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>King Kiosk needs access to save screenshots to your photo library</string>
   <key>NSPhotoLibraryAddUsageDescription</key>
   <string>King Kiosk needs access to save screenshots to your photo library</string>
   ```

2. **Runtime Permission Behavior**:
   - The first time a screenshot is taken, iOS will prompt for Photos permission
   - If denied, screenshots will still be saved to the app's internal storage

## Desktop & Web Platform Support

The screenshot feature also works on desktop platforms (Windows, macOS, and Linux) and web, but with platform-specific behavior:

1. **Desktop Platforms**:
   - No special permissions are required
   - Screenshots are saved to the app's documents directory
   - The `permission_handler` package is not used on these platforms

2. **Web Platform**:
   - Platform detection is used to avoid using plugins that don't work on web
   - Screenshots are handled in memory only, with no local file writing

## Permission Status Notifications

The app will display notifications in the following situations:

- When permissions are denied but required (mobile only)
- When permissions are permanently denied (with a button to open settings, mobile only)
- When a screenshot is successfully saved

## Implementation Notes

### Platform-Specific Code Guards

All permission-related code is guarded with platform checks:

```dart
// Only perform permission checks on mobile platforms
if (Platform.isAndroid || Platform.isIOS) {
  final hasPermission = await _requestStoragePermissions();
  // ...permission handling...
} else {
  print('💻 Running on ${Platform.operatingSystem}, no permission checks needed');
}
```

### Technical Implementation

The screenshot implementation uses:

1. The `permission_handler` package for runtime permission requests (mobile only)
2. The `image_gallery_saver` package to save images to the photo gallery (mobile only)
3. The `path_provider` package to access app-specific directories
4. The `screenshot` package to capture the UI content

For technical details about the screenshot MQTT command and implementation, please see `MQTT_SCREENSHOT_USAGE.md`.
