# Android Kiosk Mode Implementation Guide

## Overview

King Kiosk now features a comprehensive Android kiosk mode that transforms the app into a true kiosk solution. When enabled, the app becomes the device's home launcher and implements various lockdown mechanisms to prevent users from exiting the app or accessing other device functions.

## Features

### 🏠 Home Launcher Integration
- **Automatic Home App Selection**: When kiosk mode is enabled, the app registers as a home launcher
- **Priority Intent Filters**: Uses high-priority intent filters to become the preferred home app
- **Boot Integration**: Launches automatically on device boot when set as home launcher

### 🔒 Kiosk Lockdown Features
- **System UI Hiding**: Hides status bar, navigation bar, and notification panel
- **Hardware Button Blocking**: Blocks back, home, recent apps, and menu buttons
- **Task Lock (Screen Pinning)**: Pins the app using Android's task lock feature
- **App Focus Management**: Automatically returns focus to the app if user tries to leave
- **Device Admin Integration**: Uses device administrator privileges for enhanced control

### 🛡️ Advanced Security Features
- **App Uninstall Protection**: Prevents the app from being uninstalled when kiosk mode is active
- **Battery Optimization Exemption**: Requests exemption from battery optimization
- **Wake Lock Integration**: Keeps device awake during kiosk sessions
- **System Settings Blocking**: Prevents access to Android settings

### 🎛️ Device Management Features
- **Remote Device Lock**: Lock the device immediately
- **Remote Device Reboot**: Reboot the device (requires device admin)
- **Status Monitoring**: Comprehensive status reporting of kiosk state

## Android Version Compatibility

### Android 5.0+ (API 21+)
- ✅ Task Lock (Screen Pinning)
- ✅ App Uninstall Blocking
- ✅ Basic Kiosk Mode

### Android 7.0+ (API 24+)
- ✅ Remote Device Reboot
- ✅ Enhanced Device Admin Features

### Android 10+ (API 29+)
- ✅ Gesture Navigation Blocking
- ✅ Enhanced System UI Control

## Setup Instructions

### 1. Enable Kiosk Mode

```dart
// Get the Android Kiosk Service
final kioskService = Get.find<AndroidKioskService>();

// Enable comprehensive kiosk mode
bool success = await kioskService.enableKioskMode();

if (success) {
  print('🔒 Kiosk mode enabled successfully');
} else {
  print('❌ Failed to enable kiosk mode');
}
```

### 2. Grant Required Permissions

The app will automatically request the following permissions:

1. **Device Administrator Permission**
   - Required for app uninstall protection, device lock, and reboot
   - User will see a system dialog requesting admin privileges

2. **System Alert Window Permission**
   - Required for overlay features and focus management
   - User will be taken to settings to grant permission

3. **Battery Optimization Exemption**
   - Required to prevent the system from killing the app
   - User will be taken to settings to exempt the app

### 3. Set as Home Launcher

The kiosk system will automatically:
1. Clear any existing default launcher preference
2. Trigger Android's home app selection dialog
3. User must select "King Kiosk" and tap "Always"

## Manual Setup (Alternative)

If automatic setup doesn't work, users can manually configure:

### Set as Home Launcher
1. Go to **Settings > Apps > Default Apps > Home App**
2. Select **King Kiosk**
3. Enable kiosk mode in the app

### Grant Device Admin (Optional but Recommended)
1. Go to **Settings > Security > Device Administrators**
2. Enable **King Kiosk Device Administrator**

## API Reference

### Core Methods

```dart
// Enable/Disable Kiosk Mode
await kioskService.enableKioskMode();
await kioskService.disableKioskMode();

// Check Status
bool isActive = kioskService.isKioskModeActive;
bool isHomeApp = kioskService.isHomeAppSet;
bool hasPermissions = kioskService.hasSystemPermissions;

// Force Launcher Settings
await kioskService.forceSetAsHomeLauncher();
await kioskService.clearDefaultLauncher();
```

### Advanced Features

```dart
// Task Lock (Screen Pinning)
await kioskService.enableTaskLock();
await kioskService.disableTaskLock();
bool isLocked = await kioskService.isTaskLocked();

// App Protection
await kioskService.preventAppUninstall();
await kioskService.allowAppUninstall();

// Device Control (Requires Device Admin)
await kioskService.lockDevice();
await kioskService.rebootDevice();

// System UI Control
await kioskService.hideSystemUI();
await kioskService.blockHardwareButtons();
await kioskService.unblockHardwareButtons();
```

### Status Monitoring

```dart
// Get comprehensive status
Map<String, bool> status = await kioskService.getKioskStatus();

print('Kiosk Active: ${status['isKioskActive']}');
print('Home App: ${status['isHomeApp']}');
print('Device Admin: ${status['hasDeviceAdmin']}');
print('Task Locked: ${status['isTaskLocked']}');
```

## Troubleshooting

### App Not Set as Home Launcher
1. Ensure home launcher intent filters are in AndroidManifest.xml
2. Clear default launcher: `await kioskService.clearDefaultLauncher()`
3. Force launcher selection: `await kioskService.forceSetAsHomeLauncher()`

### Hardware Buttons Not Blocked
1. Verify kiosk mode is active: `kioskService.isKioskModeActive`
2. Check device admin permission: `await kioskService.hasDeviceAdminPermission()`
3. Enable task lock: `await kioskService.enableTaskLock()`

### User Can Still Exit App
1. Enable task lock (screen pinning): `await kioskService.enableTaskLock()`
2. Ensure device admin is granted
3. Check system UI hiding: `await kioskService.hideSystemUI()`

### App Killed by System
1. Request battery optimization exemption
2. Enable wake lock in app settings
3. Set app as device admin

## Security Considerations

### High Security Environment
```dart
// Enable maximum security
await kioskService.enableKioskMode();
await kioskService.enableTaskLock();
await kioskService.preventAppUninstall();
await kioskService.hideSystemUI();
```

### Moderate Security Environment
```dart
// Basic kiosk with home launcher
await kioskService.enableKioskMode();
// Task lock and app protection are optional
```

### Exit Strategy
Always provide a way to disable kiosk mode for authorized users:

```dart
// Admin unlock sequence
if (await authenticateAdmin()) {
  await kioskService.disableKioskMode();
  await kioskService.allowAppUninstall();
  await kioskService.disableTaskLock();
}
```

## Testing Checklist

### ✅ Basic Functionality
- [ ] App sets as home launcher
- [ ] Kiosk mode enables/disables correctly
- [ ] System UI hides in kiosk mode
- [ ] Hardware buttons are blocked

### ✅ Advanced Features
- [ ] Task lock works (screen pinning)
- [ ] App uninstall is blocked
- [ ] Device admin permissions granted
- [ ] Focus returns to app when user tries to leave

### ✅ Edge Cases
- [ ] App survives device reboot
- [ ] Kiosk state persists after app restart
- [ ] Emergency exit works for admins
- [ ] Battery optimization doesn't kill app

## Best Practices

1. **Always provide an exit mechanism** for authorized users
2. **Test on multiple Android versions** (5.0, 8.0, 10.0, 12.0+)
3. **Request permissions gracefully** with user-friendly explanations
4. **Monitor kiosk status** and handle edge cases
5. **Document the setup process** for end users
6. **Test with different device manufacturers** (Samsung, Huawei, etc.)

## Known Limitations

- Some Samsung devices have additional launcher restrictions
- MIUI (Xiaomi) may require additional permissions
- Android Go devices may have limited device admin features
- Some corporate devices may block device admin features
- Task lock may not work on devices with custom Android versions
