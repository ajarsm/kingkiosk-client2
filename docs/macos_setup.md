# macOS Setup for Flutter GetX Kiosk

This document provides instructions for setting up the Flutter GetX Kiosk application to run on macOS.

## Prerequisites

- macOS 10.14 (Mojave) or later
- Flutter SDK (with macOS desktop support enabled)

## Enable macOS Desktop Support

1. Run the following command to enable macOS desktop support in your Flutter installation:

```bash
flutter config --enable-macos-desktop
```

2. Verify macOS is enabled as a target platform:

```bash
flutter devices
```

You should see "macOS" listed as an available device.

## Create macOS Platform Files

Run the following command from your project root:

```bash
flutter create --platforms=macos .
```

## Update macOS Entitlements

For features like camera and microphone access, you need to update entitlements:

1. Open the following file:
```
macos/Runner/DebugProfile.entitlements
```

2. Add the following entitlements:

```xml
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.device.camera</key>
<true/>
```

3. Also update the Release.entitlements file similarly.

## Update Info.plist

1. Open the following file:
```
macos/Runner/Info.plist
```

2. Add usage descriptions:

```xml
<key>NSCameraUsageDescription</key>
<string>This application needs access to the camera for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This application needs access to the microphone for audio calls</string>
```

## Run on macOS

Run the application with:

```bash
flutter run -d macos
```

## Build for Release

Build a release version with:

```bash
flutter build macos
```

The built app will be available at:
`build/macos/Build/Products/Release/flutter_getx_kiosk.app`

## Common Issues

If you encounter "The application doesn't have permission to use the camera/microphone":

1. Open System Preferences > Security & Privacy
2. Select the Privacy tab
3. Select Camera or Microphone from the left sidebar
4. Ensure that your application is checked in the list