# Secure Storage Platform Configuration

This document describes the secure storage configuration for each platform to ensure `flutter_secure_storage` works correctly across all supported platforms.

## Platform-Specific Configurations

### iOS
**File:** `ios/Runner/Runner.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>keychain-access-groups</key>
	<array>
		<string>$(AppIdentifierPrefix)com.kingkiosk.kingkioskClient2</string>
	</array>
</dict>
</plist>
```

**Required Changes:**
- Added `Runner.entitlements` file with keychain access groups
- Updated `ios/Runner.xcodeproj/project.pbxproj` to include entitlements file
- Added `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` to both Debug and Release configurations

### macOS
**Files:** 
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

**Added Configuration:**
```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.kingkiosk.client</string>
</array>
```

### Android
**Status:** ✅ No additional configuration needed

Android uses the Android Keystore system which doesn't require special permissions or entitlements. The existing permissions in `android/app/src/main/AndroidManifest.xml` are sufficient.

### Windows
**Status:** ✅ No additional configuration needed

Windows uses the Windows Credential Manager (via `flutter_secure_storage_windows`) which doesn't require special configuration.

### Linux
**Status:** ✅ No additional configuration needed

Linux uses the Secret Service API (libsecret) which is typically available on most desktop Linux distributions without additional configuration.

### Web
**Status:** ⚠️ Limited Security Support

**Files:**
- `web/index.html` - Updated with security headers
- `web/manifest.json` - Added storage permissions
- `web/secure_storage_config.js` - Web-specific configuration

**Added Configuration:**
```html
<!-- Security headers for web secure storage -->
<meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; connect-src 'self' ws: wss: http: https:;">
<meta http-equiv="Permissions-Policy" content="camera=*, microphone=*, geolocation=*">

<!-- Web secure storage configuration -->
<script src="secure_storage_config.js"></script>
```

**Manifest.json additions:**
```json
"permissions": ["storage"],
"storage": {"estimate": true}
```

**Web Limitations:**
- Uses browser localStorage/sessionStorage (less secure than native keystore)
- Requires HTTPS for maximum security
- Data can be accessed through browser developer tools
- Limited encryption capabilities
- Storage quotas may apply
- Data persistence depends on browser settings

**Security Recommendations for Web:**
1. **Always use HTTPS** in production
2. **Implement additional encryption** for highly sensitive data
3. **Consider session-only storage** for temporary secrets
4. **Validate browser support** for storage APIs
5. **Implement fallbacks** for unsupported browsers

## Error Resolution

### macOS/iOS Error: -34018 "A required entitlement isn't present"
This error occurs when the keychain access entitlements are missing or incorrectly configured.

**Resolution:**
1. Ensure entitlements files exist with correct keychain access groups
2. Verify the bundle identifier matches the app's bundle ID
3. Restart the app after adding entitlements (clean build recommended)

### Common Issues
- **Bundle Identifier Mismatch:** Ensure the bundle identifier in entitlements matches your app's actual bundle ID
- **Missing Entitlements:** All Apple platforms (iOS/macOS) require explicit keychain access entitlements
- **Signing Issues:** Development and distribution certificates must have keychain access capabilities

## Testing Secure Storage

After configuration, test secure storage functionality:

```dart
// Test write
await Get.find<StorageService>().writeSecure('test_key', 'test_value');

// Test read
final value = await Get.find<StorageService>().readSecure<String>('test_key');
print('Secure storage test: $value');
```

### Web-Specific Testing
For web platforms, additional testing is recommended:

```dart
// Check if running on web
if (kIsWeb) {
  print('Running on web platform - using browser storage');
  
  // Test storage quotas (web-specific)
  try {
    // This will work in modern browsers
    final estimate = await html.window.navigator.storage?.estimate();
    print('Storage quota: ${estimate?.quota}');
    print('Storage usage: ${estimate?.usage}');
  } catch (e) {
    print('Storage API not supported: $e');
  }
}
```

## Security Notes

1. **Keychain Access Groups:** Limits access to the app's own keychain entries
2. **Bundle Identifier:** Must match the app's actual bundle identifier
3. **Development vs Distribution:** Different signing requirements may apply
4. **Platform Differences:** Each platform uses different underlying secure storage mechanisms

## Sensitive Data Handled

The following sensitive data is automatically routed to secure storage:
- Settings PIN (`settingsPin`)
- MQTT Username (`mqttUsername`) 
- MQTT Password (`mqttPassword`)

All other data continues to use regular storage for performance reasons.
