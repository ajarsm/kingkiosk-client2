# Splash Screen Loading Process

## Overview
The splash screen in Flutter GetX Kiosk serves as both a branding element and a functional loading screen where various app services are initialized. This document explains what happens during the splash screen display.

## What's Happening During the Loading Screen

### Service Initialization 
During the splash screen display, the following services are being initialized:

1. **StorageService**: 
   - Initializes local storage (GetStorage)
   - Loads saved preferences
   - Prepares the database if needed

2. **WebSocketService & MediasoupService**:
   - Establishes connection parameters
   - Loads cached credentials

3. **PlatformSensorService**:
   - Initializes platform-specific sensor access
   - Starts battery and memory monitoring
   - Begins CPU usage tracking

4. **NavigationService & ThemeService**:
   - Prepares the navigation controller
   - Loads the saved theme preference
   - Sets up theme listeners

5. **BackgroundMediaService**:
   - Initializes the media players
   - Prepares codecs and buffers

6. **MQTT Service**:
   - Detects device information
   - Loads broker settings
   - Attempts initial connection if enabled

### Loading Logic

The splash screen uses a combination of real loading processes and minimum display time:

```dart
void _initializeServices() async {
  // Start timing the initialization
  final stopwatch = Stopwatch()..start();

  // Initialize all required services
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ThemeService().init());
  await Get.putAsync(() => NavigationService().init());
  // ... more service initialization

  // Ensure minimum splash display time (1.5 seconds)
  final elapsedMs = stopwatch.elapsedMilliseconds;
  if (elapsedMs < 1500) {
    await Future.delayed(Duration(milliseconds: 1500 - elapsedMs));
  }
  
  // Navigate to home screen
  Get.offNamed(Routes.HOME);
}
```

## Optimization Opportunities

- The splash screen currently uses a minimum display time of 1.5 seconds, even if services initialize faster
- This could be reduced for faster app startup
- Alternatively, some initialization could be moved to background processes after the main UI has loaded

## Customizing the Splash Screen

To customize the splash screen display time:

1. Open `lib/app/modules/splash/controllers/splash_controller.dart`
2. Modify the minimum display time in the `_initializeServices()` method
3. Or remove the minimum time completely for fastest possible startup

If your app performs lengthy initialization tasks, consider:
- Using a progress indicator
- Showing initialization status messages
- Moving non-critical initialization to a background process