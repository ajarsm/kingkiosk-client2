# Android Screenshot Permissions Guide

This document explains how screenshot functionality is implemented in KingKiosk for Android devices across different versions.

## Android Version Differences

Android permissions for saving media have changed significantly across versions:

### Android 9 and below (API level ≤ 28)
- Uses `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE` permissions
- Simple storage access with minimal restrictions

### Android 10-12 (API level 29-32)
- Introduces Scoped Storage restrictions
- Requires `READ_EXTERNAL_STORAGE` permission (but writing to gallery needs different handling)
- Media-specific permissions with `ACCESS_MEDIA_LOCATION`

### Android 13+ (API level ≥ 33)
- Granular permissions: `READ_MEDIA_IMAGES` instead of general storage permissions
- More restrictive permissions model
- Storage permissions need to be requested at runtime

## Implementation Details

The KingKiosk app handles these differences with a version-aware permission strategy:

1. **Permission Declaration**
   - `AndroidManifest.xml` contains all required permissions with appropriate SDK version limits
   - Android 13+: `READ_MEDIA_IMAGES`
   - Android 10-12: `ACCESS_MEDIA_LOCATION` and `READ_EXTERNAL_STORAGE` 
   - Android 9 and below: `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE`

2. **Runtime Permission Handling**
   - `AndroidScreenshotHelper.requestPermissions()` checks device Android version
   - Requests appropriate permissions based on Android version
   - Shows user-friendly prompts when permissions are denied

3. **Storage Strategy**
   - Android 11+: Uses app-specific directories (more secure)
   - Android 10 and below: Tries external storage with fallbacks
   - All versions: Creates a dedicated "screenshots" subdirectory

## Troubleshooting

If screenshots are not working:

1. **Check Permissions**
   - Ensure app has proper permissions in system settings
   - For Android 13+: Photos and Media permission must be granted
   - For older Android: Storage permission must be granted

2. **Check App Logs**
   - Look for permission denied errors
   - Check the storage path being used

3. **Manual Testing**
   - Use the `test_screenshot_permissions.sh` script
   - Send an MQTT command: `{"command": "screenshot", "notify": true}`

4. **Common Issues**
   - Permissions granted but still failing: Try restarting the app
   - No permissions dialog: Check if permission was permanently denied (must go to system settings)
   - Screenshot captured but not visible in gallery: Media scanner might not have indexed it

## Resources

- [Android Storage Documentation](https://developer.android.com/training/data-storage)
- [Media Storage Documentation](https://developer.android.com/training/data-storage/shared/media)
- [Permission Handler Package](https://pub.dev/packages/permission_handler)
- [ImageGallerySaverPlus Package](https://pub.dev/packages/image_gallery_saver_plus)
