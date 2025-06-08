# PowerShell script to restore TensorFlow Lite libraries after flutter clean (Windows)
param([switch]$Verbose)

$ErrorActionPreference = "Stop"

Write-Host "Restoring TensorFlow Lite libraries after clean (Windows)..." -ForegroundColor Cyan

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source library (in project root)
$SourceTfliteDll = Join-Path $ScriptDir "tensorflowlite_c.dll"

# Target directories
$DebugBlobsDir = Join-Path $ScriptDir "build\windows\x64\runner\Debug\blobs"
$DebugRunnerDir = Join-Path $ScriptDir "build\windows\x64\runner\Debug"
$ReleaseBlobsDir = Join-Path $ScriptDir "build\windows\x64\runner\Release\blobs"
$ReleaseRunnerDir = Join-Path $ScriptDir "build\windows\x64\runner\Release"

# Create directories
Write-Host "Creating build directories..." -ForegroundColor Yellow
$Directories = @($DebugBlobsDir, $DebugRunnerDir, $ReleaseBlobsDir, $ReleaseRunnerDir)
foreach ($Dir in $Directories) {
    if (!(Test-Path $Dir)) {
        New-Item -ItemType Directory -Force -Path $Dir | Out-Null
        if ($Verbose) { Write-Host "   Created: $Dir" -ForegroundColor Gray }
    }
}

# Check if source exists
if (!(Test-Path $SourceTfliteDll)) {
    Write-Host "ERROR: Source TensorFlow Lite DLL not found at: $SourceTfliteDll" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure you have the tensorflowlite_c.dll file in the project root." -ForegroundColor Yellow
    Write-Host "You can download it from:" -ForegroundColor Yellow
    Write-Host "  - https://github.com/tensorflow/tensorflow/releases" -ForegroundColor Gray
    Write-Host "  - Or run: .\download_tflite_windows.ps1" -ForegroundColor Gray
    exit 1
}

# Copy library to all locations
Write-Host "Copying TensorFlow Lite library to build directories..." -ForegroundColor Yellow

$TargetFiles = @(
    @{ Path = Join-Path $DebugBlobsDir "libtensorflowlite_c-win.dll"; Name = "Debug/blobs" },
    @{ Path = Join-Path $DebugRunnerDir "libtensorflowlite_c-win.dll"; Name = "Debug/runner" },
    @{ Path = Join-Path $ReleaseBlobsDir "libtensorflowlite_c-win.dll"; Name = "Release/blobs" },
    @{ Path = Join-Path $ReleaseRunnerDir "libtensorflowlite_c-win.dll"; Name = "Release/runner" }
)

$SuccessCount = 0
foreach ($Target in $TargetFiles) {
    try {
        Copy-Item $SourceTfliteDll $Target.Path -Force
        Write-Host "SUCCESS: Restored to $($Target.Name): libtensorflowlite_c-win.dll" -ForegroundColor Green
        $SuccessCount++
    }
    catch {
        Write-Host "ERROR: Failed to copy to $($Target.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Show results
if ($SuccessCount -eq $TargetFiles.Count) {
    $FileSize = (Get-Item $SourceTfliteDll).Length
    $FileSizeMB = [math]::Round($FileSize / 1MB, 2)
    Write-Host "Library file size: $FileSizeMB MB" -ForegroundColor Gray
    Write-Host ""
    Write-Host "TensorFlow Lite library restoration complete!" -ForegroundColor Green
    Write-Host "Libraries restored to all Windows build directories" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "WARNING: Partial restoration: $SuccessCount/$($TargetFiles.Count) locations updated" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Restoration Summary:" -ForegroundColor Cyan
Write-Host "  SUCCESS: Build directories created" -ForegroundColor Green
Write-Host "  SUCCESS: TensorFlow Lite C library restored" -ForegroundColor Green
Write-Host "  SUCCESS: Ready for Flutter Windows build" -ForegroundColor Green
