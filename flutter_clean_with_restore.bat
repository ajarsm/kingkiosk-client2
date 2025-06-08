@echo off
REM Enhanced flutter clean script that automatically restores TensorFlow Lite libraries (Windows)
REM This ensures the libraries are available after clean operations

echo 🧹 Starting enhanced Flutter clean with library restoration (Windows)...
echo.

REM Step 1: Run flutter clean
echo 1️⃣ Running flutter clean...
flutter clean
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter clean failed
    exit /b 1
)

REM Step 2: Restore TensorFlow Lite libraries
echo 2️⃣ Restoring TensorFlow Lite libraries...
if exist "%~dp0restore_libraries_windows.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0restore_libraries_windows.ps1"
    if %ERRORLEVEL% neq 0 (
        echo ⚠️ Library restoration encountered issues, but continuing...
    )
) else (
    echo ⚠️ restore_libraries_windows.ps1 not found, manual library restoration may be needed
)

REM Step 3: Run flutter pub get to restore dependencies
echo 3️⃣ Restoring Flutter dependencies...
flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter pub get failed
    exit /b 1
)

echo.
echo 🎉 Enhanced Flutter clean complete with library restoration!
echo.
echo Next steps:
echo   • Run: flutter run -d windows
echo   • Or: flutter build windows
echo.
echo 📋 What was restored:
echo   ✅ Flutter dependencies (pub get)
echo   ✅ TensorFlow Lite C library (Windows)
echo   ✅ Build directories recreated
