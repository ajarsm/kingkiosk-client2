@echo off
echo Creating King Kiosk distribution package...

REM Create a distribution directory
if not exist "dist" mkdir dist

REM Copy MSIX file
if exist "build\windows\x64\runner\Release\king_kiosk.msix" (
    copy "build\windows\x64\runner\Release\king_kiosk.msix" "dist\"
    echo Copied MSIX package to dist folder.
) else (
    echo Error: Could not find king_kiosk.msix file.
    echo Please build the app first with: flutter pub run msix:create
    pause
    exit /b 1
)

REM Copy installer and certificate
copy "install_kingkiosk.bat" "dist\"
copy "kingkiosk_cert.pfx" "dist\"
copy "INSTALLATION_GUIDE.md" "dist\"

echo.
echo Distribution package created in the "dist" folder.
echo Ready for distribution:
echo  - king_kiosk.msix
echo  - install_kingkiosk.bat
echo  - kingkiosk_cert.pfx
echo  - INSTALLATION_GUIDE.md
echo.
echo You can zip this folder and distribute it to users.
echo.

pause
