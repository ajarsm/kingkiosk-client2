# TensorFlow Lite Library Management

## Overview

This project uses TensorFlow Lite for person detection capabilities on macOS. The native libraries need to be properly managed to survive Flutter clean operations and build processes.

## Library Files

- `libtensorflowlite_c.dylib` - Core TensorFlow Lite C library
- `libtensorflowlite_metal_delegate.dylib` - Metal GPU acceleration delegate

## File Locations

### Source Libraries (Project Root)
```
/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/
├── libtensorflowlite_c.dylib
└── libtensorflowlite_metal_delegate.dylib
```

### Target Location (macOS Resources)
```
/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/macos/Runner/Resources/
├── libtensorflowlite_c.dylib
├── libtensorflowlite_c-mac.dylib (copy for compatibility)
├── libtensorflowlite_metal_delegate.dylib
└── libtensorflowlite_metal_delegate-mac.dylib (copy for compatibility)
```

## Scripts for Library Management

### 1. `restore_libraries.sh` 
Restores TensorFlow Lite libraries from project root to macOS Resources folder.

**Usage:**
```bash
./restore_libraries.sh
```

### 2. `flutter_clean_with_restore.sh`
Enhanced clean script that automatically restores libraries after cleaning.

**Usage:**
```bash
./flutter_clean_with_restore.sh
```

**What it does:**
- Runs `flutter clean`
- Restores TensorFlow Lite libraries
- Makes build scripts executable
- Runs `flutter pub get`

### 3. `macos/copy_tflite_libs.sh`
Build-time script that copies libraries to the app bundle.

**Usage:** (Called automatically during Xcode build)
```bash
cd macos && ./copy_tflite_libs.sh
```

## When Libraries Get Lost

### After `flutter clean`
The `flutter clean` command removes the `macos/Runner/Resources/` directory, which contains our TensorFlow Lite libraries.

**Solution:** Use the enhanced clean script:
```bash
./flutter_clean_with_restore.sh
```

Or manually restore:
```bash
flutter clean
./restore_libraries.sh
flutter pub get
```

### After Build Issues
If you encounter TensorFlow Lite loading errors:

1. **Check if libraries exist:**
   ```bash
   ls -la macos/Runner/Resources/libtensorflowlite*.dylib
   ```

2. **Restore if missing:**
   ```bash
   ./restore_libraries.sh
   ```

3. **Rebuild:**
   ```bash
   flutter build macos
   ```

## Build Integration

The `copy_tflite_libs.sh` script copies the libraries to the final app bundle during build. This ensures they're available at runtime.

The script copies libraries to:
- `$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources/`
- `$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks/`

## Troubleshooting

### Library Not Found Errors
```
Failed to load dynamic library 'libtensorflowlite_c.dylib'
```

**Solutions:**
1. Run `./restore_libraries.sh`
2. Ensure libraries are in `macos/Runner/Resources/`
3. Check file permissions: `chmod +x macos/copy_tflite_libs.sh`
4. Clean rebuild: `./flutter_clean_with_restore.sh && flutter build macos`

### Person Detection Fallback Mode
If libraries can't be loaded, the person detection service will:
- Log a warning about missing libraries
- Continue with simulated detection for development
- Set `lastError` to explain the fallback

### Build Script Permissions
Ensure scripts are executable:
```bash
chmod +x restore_libraries.sh
chmod +x flutter_clean_with_restore.sh  
chmod +x macos/copy_tflite_libs.sh
```

## Best Practices

### For Development
- Always use `./flutter_clean_with_restore.sh` instead of `flutter clean`
- Check library status after any clean operation
- Keep source libraries in project root as backup

### For Deployment
- Ensure `copy_tflite_libs.sh` runs during build
- Verify libraries are included in final app bundle
- Test person detection functionality after deployment

### For CI/CD
Include library restoration in your pipeline:
```bash
# After flutter clean
./restore_libraries.sh
# Before build
flutter build macos
```

## File Sizes
- `libtensorflowlite_c.dylib`: ~12MB
- `libtensorflowlite_metal_delegate.dylib`: ~7MB
- Total: ~19MB of native libraries

These libraries are essential for TensorFlow Lite functionality and person detection features.
