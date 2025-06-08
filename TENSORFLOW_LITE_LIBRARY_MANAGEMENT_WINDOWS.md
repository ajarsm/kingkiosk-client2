# TensorFlow Lite Library Management (Windows)

## Overview

This project uses TensorFlow Lite for person detection capabilities on Windows. The native libraries need to be properly managed to survive Flutter clean operations and build processes.

## Library Files

- `tensorflowlite_c.dll` - Core TensorFlow Lite C library for Windows
- Renamed to `libtensorflowlite_c-win.dll` in build directories for compatibility

## File Locations

### Source Library (Project Root)
```
C:\Users\rsm75\dev\kingkiosk-client2\
└── tensorflowlite_c.dll
```

### Local Download Location (Default)
```
C:\Users\rsm75\Downloads\tflite-dist-2.18.0\tflite-dist\libs\windows_x86_64\
└── tensorflowlite_c.dll
```

### Target Locations (Windows Build Directories)
```
C:\Users\rsm75\dev\kingkiosk-client2\build\windows\x64\runner\
├── Debug\
│   ├── libtensorflowlite_c-win.dll
│   └── blobs\
│       └── libtensorflowlite_c-win.dll
└── Release\
    ├── libtensorflowlite_c-win.dll
    └── blobs\
        └── libtensorflowlite_c-win.dll
```

## Scripts for Library Management (Windows)

### 1. `restore_libraries_windows.ps1` (NEW)
PowerShell script that restores TensorFlow Lite libraries from project root to Windows build directories.

**Usage:**
```powershell
.\restore_libraries_windows.ps1
```

**With verbose output:**
```powershell
.\restore_libraries_windows.ps1 -Verbose
```

### 2. `flutter_clean_with_restore.bat` (NEW)
Enhanced clean batch script that automatically restores libraries after cleaning.

**Usage:**
```cmd
flutter_clean_with_restore.bat
```

**What it does:**
- Runs `flutter clean`
- Restores TensorFlow Lite libraries (calls PowerShell script)
- Runs `flutter pub get`

### 3. `download_tflite_windows.ps1` (UPDATED)
Enhanced setup script for initial library download and placement.

**Usage:**
```powershell
# Standard setup
.\download_tflite_windows.ps1

# Verbose mode
.\download_tflite_windows.ps1 -Verbose

# Skip download attempts
.\download_tflite_windows.ps1 -SkipDownload
```

## When Libraries Get Lost

### After `flutter clean`
The `flutter clean` command removes the `build\windows\` directory, which contains our TensorFlow Lite libraries.

**Solution 1:** Use the enhanced clean script:
```cmd
flutter_clean_with_restore.bat
```

**Solution 2:** Manual restoration:
```cmd
flutter clean
powershell -ExecutionPolicy Bypass -File .\restore_libraries_windows.ps1
flutter pub get
```

### After Build Issues
If you encounter TensorFlow Lite loading errors on Windows:

1. **Check if libraries exist:**
   ```cmd
   dir build\windows\x64\runner\Debug\*tensorflow*.dll
   dir build\windows\x64\runner\Release\*tensorflow*.dll
   ```

2. **Restore if missing:**
   ```powershell
   .\restore_libraries_windows.ps1
   ```

3. **Rebuild:**
   ```cmd
   flutter build windows
   ```

## Initial Setup

### First Time Setup
1. **Download TensorFlow Lite for Windows:**
   - From: https://github.com/tensorflow/tensorflow/releases
   - Or: https://github.com/am15h/tflite_flutter_plugin/releases
   - Extract `tensorflowlite_c.dll`

2. **Place in project root:**
   ```cmd
   copy "C:\Users\rsm75\Downloads\tflite-dist-2.18.0\tflite-dist\libs\windows_x86_64\tensorflowlite_c.dll" .
   ```

3. **Run setup script:**
   ```powershell
   .\download_tflite_windows.ps1
   ```

## Troubleshooting

### Library Not Found Errors
```
Failed to load dynamic library 'libtensorflowlite_c-win.dll'
```

**Solutions:**
1. Run `.\restore_libraries_windows.ps1`
2. Ensure library is in project root: `tensorflowlite_c.dll`
3. Check build directories for the renamed files
4. Clean rebuild: `flutter_clean_with_restore.bat && flutter build windows`

### PowerShell Execution Policy Issues
If you get execution policy errors:

```powershell
# Temporary bypass for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Or run with bypass
powershell -ExecutionPolicy Bypass -File .\restore_libraries_windows.ps1
```

### Person Detection Fallback Mode
If libraries can't be loaded, the person detection service will:
- Log a warning about missing libraries
- Continue with simulated detection for development
- Set `lastError` to explain the fallback

### Missing Source Library
If `tensorflowlite_c.dll` is not found in project root:

1. **Check default download location:**
   ```cmd
   dir "C:\Users\rsm75\Downloads\tflite-dist-*\tflite-dist\libs\windows_x86_64\tensorflowlite_c.dll"
   ```

2. **Copy to project root:**
   ```cmd
   copy "C:\Users\rsm75\Downloads\tflite-dist-2.18.0\tflite-dist\libs\windows_x86_64\tensorflowlite_c.dll" .
   ```

3. **Re-run restoration:**
   ```powershell
   .\restore_libraries_windows.ps1
   ```

## Best Practices (Windows)

### For Development
- Always use `flutter_clean_with_restore.bat` instead of `flutter clean`
- Check library status after any clean operation
- Keep source library (`tensorflowlite_c.dll`) in project root as backup

### For Deployment
- Ensure libraries are included in Windows build
- Test person detection functionality after deployment
- Verify library paths in Windows executable

### For CI/CD
Include library restoration in your Windows pipeline:
```cmd
REM After flutter clean
powershell -ExecutionPolicy Bypass -File .\restore_libraries_windows.ps1
REM Before build
flutter build windows
```

## File Size Reference
- **tensorflowlite_c.dll**: Approximately 15-25 MB
- If file size is significantly different, verify download integrity

## Related Files
- `tensorflowlite_c.dll` - Main library file (keep in project root)
- `pubspec.yaml` - Contains tflite_flutter dependency
- Windows build directories under `build\windows\x64\runner\`

## Support
For issues with Windows TensorFlow Lite setup:
1. Check all file paths in this document
2. Verify PowerShell execution permissions
3. Ensure Flutter Windows toolchain is properly installed
4. Test with a simple TensorFlow Lite model first
