@echo off
REM Validation script for TensorFlow Lite Windows setup
REM Checks all required files and directories for proper Windows build

echo 🔍 Validating TensorFlow Lite Windows Setup...
echo.

set "ERROR_COUNT=0"

REM Check project root for source library
echo 📁 Checking source library in project root...
if exist "tensorflowlite_c.dll" (
    echo ✅ tensorflowlite_c.dll found in project root
    for %%I in (tensorflowlite_c.dll) do echo    📊 Size: %%~zI bytes
) else (
    echo ❌ tensorflowlite_c.dll NOT found in project root
    set /a ERROR_COUNT+=1
)

REM Check Windows build scripts
echo.
echo 🛠️ Checking Windows build scripts...
if exist "restore_libraries_windows.ps1" (
    echo ✅ restore_libraries_windows.ps1 found
) else (
    echo ❌ restore_libraries_windows.ps1 NOT found
    set /a ERROR_COUNT+=1
)

if exist "flutter_clean_with_restore.bat" (
    echo ✅ flutter_clean_with_restore.bat found
) else (
    echo ❌ flutter_clean_with_restore.bat NOT found
    set /a ERROR_COUNT+=1
)

if exist "download_tflite_windows.ps1" (
    echo ✅ download_tflite_windows.ps1 found
) else (
    echo ❌ download_tflite_windows.ps1 NOT found
    set /a ERROR_COUNT+=1
)

REM Check Windows build directories and libraries
echo.
echo 🏗️ Checking Windows build directories...

set "DEBUG_BLOBS=build\windows\x64\runner\Debug\blobs"
set "DEBUG_RUNNER=build\windows\x64\runner\Debug"
set "RELEASE_BLOBS=build\windows\x64\runner\Release\blobs"
set "RELEASE_RUNNER=build\windows\x64\runner\Release"

if exist "%DEBUG_BLOBS%" (
    echo ✅ Debug blobs directory exists
) else (
    echo ⚠️ Debug blobs directory missing (will be created on build)
)

if exist "%DEBUG_RUNNER%" (
    echo ✅ Debug runner directory exists
) else (
    echo ⚠️ Debug runner directory missing (will be created on build)
)

if exist "%RELEASE_BLOBS%" (
    echo ✅ Release blobs directory exists
) else (
    echo ⚠️ Release blobs directory missing (will be created on build)
)

if exist "%RELEASE_RUNNER%" (
    echo ✅ Release runner directory exists
) else (
    echo ⚠️ Release runner directory missing (will be created on build)
)

REM Check for TensorFlow Lite libraries in build directories
echo.
echo 📦 Checking TensorFlow Lite libraries in build directories...

if exist "%DEBUG_BLOBS%\libtensorflowlite_c-win.dll" (
    echo ✅ Debug/blobs: libtensorflowlite_c-win.dll found
) else (
    echo ❌ Debug/blobs: libtensorflowlite_c-win.dll NOT found
    set /a ERROR_COUNT+=1
)

if exist "%DEBUG_RUNNER%\libtensorflowlite_c-win.dll" (
    echo ✅ Debug/runner: libtensorflowlite_c-win.dll found
) else (
    echo ❌ Debug/runner: libtensorflowlite_c-win.dll NOT found
    set /a ERROR_COUNT+=1
)

if exist "%RELEASE_BLOBS%\libtensorflowlite_c-win.dll" (
    echo ✅ Release/blobs: libtensorflowlite_c-win.dll found
) else (
    echo ❌ Release/blobs: libtensorflowlite_c-win.dll NOT found
    set /a ERROR_COUNT+=1
)

if exist "%RELEASE_RUNNER%\libtensorflowlite_c-win.dll" (
    echo ✅ Release/runner: libtensorflowlite_c-win.dll found
) else (
    echo ❌ Release/runner: libtensorflowlite_c-win.dll NOT found
    set /a ERROR_COUNT+=1
)

REM Check pubspec.yaml for tflite dependency
echo.
echo 📋 Checking Flutter dependencies...
if exist "pubspec.yaml" (
    findstr /c:"tflite_flutter" pubspec.yaml >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo ✅ tflite_flutter dependency found in pubspec.yaml
    ) else (
        echo ⚠️ tflite_flutter dependency not found in pubspec.yaml
    )
) else (
    echo ❌ pubspec.yaml not found
    set /a ERROR_COUNT+=1
)

REM Summary
echo.
echo 📊 VALIDATION SUMMARY
echo ==================
if %ERROR_COUNT% equ 0 (
    echo ✅ All critical components are present
    echo 🎉 Windows TensorFlow Lite setup is READY
) else (
    echo ❌ Found %ERROR_COUNT% critical issues
    echo 🔧 Run the following to fix issues:
    echo.
    echo    1. Ensure tensorflowlite_c.dll is in project root
    echo    2. Run: powershell -ExecutionPolicy Bypass -File .\restore_libraries_windows.ps1
    echo    3. Or run: flutter_clean_with_restore.bat
)

echo.
echo 💡 To restore libraries after flutter clean:
echo    flutter_clean_with_restore.bat  (Enhanced clean with auto-restore)
echo    OR
echo    flutter clean ^&^& powershell -ExecutionPolicy Bypass -File .\restore_libraries_windows.ps1 ^&^& flutter pub get

pause
