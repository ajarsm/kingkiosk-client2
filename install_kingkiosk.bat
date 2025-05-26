@echo off
echo Installing King Kiosk...

REM Try to locate the MSIX file
if exist "build\windows\x64\runner\Release\king_kiosk.msix" (
    set MSIX_PATH=build\windows\x64\runner\Release\king_kiosk.msix
) else if exist "king_kiosk.msix" (
    set MSIX_PATH=king_kiosk.msix
) else (
    echo Error: Could not find king_kiosk.msix file.
    echo Please make sure the MSIX file is in the current directory or in build\windows\x64\runner\Release\
    pause
    exit /b 1
)

echo Found MSIX at: %MSIX_PATH%

REM Allow installation of the app package with certificate
echo Installing app package...
powershell -Command "Add-AppxPackage -Path '%MSIX_PATH%' -ForceApplicationShutdown -ForceUpdateFromAnyVersion"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Installation failed with standard method. Trying alternative method...
    echo.
    
    REM Try to install the certificate first
    echo Installing certificate from the MSIX package...
    powershell -Command "$cert = Get-PfxCertificate -FilePath 'kingkiosk_cert.pfx'; Import-Certificate -CertificateStore Cert:\LocalMachine\Root -Certificate $cert"
    
    echo Trying installation again...
    powershell -Command "Add-AppxPackage -Path '%MSIX_PATH%' -ForceApplicationShutdown -ForceUpdateFromAnyVersion"
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Installation failed. Please contact support.
        pause
        exit /b 1
    )
)

echo.
echo Installation complete!
pause
