@echo off
REM Quick setup script for TensorFlow Lite Windows environment
REM This script sets up everything needed for Windows TensorFlow Lite support

echo 🚀 Quick TensorFlow Lite Windows Setup
echo =====================================
echo.

REM Step 1: Check if source library exists
echo 1️⃣ Checking for source TensorFlow Lite library...
if exist "tensorflowlite_c.dll" (
    echo ✅ tensorflowlite_c.dll found in project root
) else (
    echo ⚠️ tensorflowlite_c.dll not found in project root
    echo.
    echo 📥 Please download TensorFlow Lite library for Windows:
    echo    1. Visit: https://github.com/tensorflow/tensorflow/releases
    echo    2. Download Windows x64 TensorFlow Lite C library
    echo    3. Extract tensorflowlite_c.dll to this project root
    echo.
    echo 🔄 Alternative: Check default download location...
    
    if exist "C:\Users\rsm75\Downloads\tflite-dist-2.18.0\tflite-dist\libs\windows_x86_64\tensorflowlite_c.dll" (
        echo ✅ Found TensorFlow Lite library in default download location
        echo 📋 Copying to project root...
        copy "C:\Users\rsm75\Downloads\tflite-dist-2.18.0\tflite-dist\libs\windows_x86_64\tensorflowlite_c.dll" . >nul 2>&1
        if exist "tensorflowlite_c.dll" (
            echo ✅ Successfully copied tensorflowlite_c.dll to project root
        ) else (
            echo ❌ Failed to copy library. Please copy manually.
            pause
            exit /b 1
        )
    ) else (
        echo ❌ Library not found in default location either
        echo 💡 Please obtain the library manually and re-run this script
        pause
        exit /b 1
    )
)

REM Step 2: Run the setup script
echo.
echo 2️⃣ Setting up TensorFlow Lite libraries in build directories...
if exist "download_tflite_windows.ps1" (
    powershell -ExecutionPolicy Bypass -File .\download_tflite_windows.ps1 -Verbose
) else (
    echo ❌ download_tflite_windows.ps1 not found
    exit /b 1
)

REM Step 3: Test restoration script
echo.
echo 3️⃣ Testing library restoration script...
if exist "restore_libraries_windows.ps1" (
    powershell -ExecutionPolicy Bypass -File .\restore_libraries_windows.ps1 -Verbose
) else (
    echo ❌ restore_libraries_windows.ps1 not found
    exit /b 1
)

REM Step 4: Validate setup
echo.
echo 4️⃣ Validating complete setup...
if exist "verify_tensorflow_setup_windows.bat" (
    call verify_tensorflow_setup_windows.bat
) else (
    echo ⚠️ verify_tensorflow_setup_windows.bat not found, skipping validation
)

echo.
echo 🎉 Quick setup complete!
echo.
echo 📋 Next steps:
echo    • Test with: flutter run -d windows
echo    • Build with: flutter build windows
echo    • Use enhanced clean: flutter_clean_with_restore.bat
echo.
echo 💡 If you encounter issues, check TENSORFLOW_LITE_LIBRARY_MANAGEMENT_WINDOWS.md
pause
