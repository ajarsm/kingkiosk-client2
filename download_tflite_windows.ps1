# PowerShell script to copy TensorFlow Lite Windows libraries
# This script copies the TensorFlow Lite native library from your downloaded location
# Can be used for initial setup or restoration after flutter clean

param(
    [switch]$Verbose,
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

# Local TensorFlow Lite DLL path (update this if you move the file)
$localTfliteDll = "C:\Users\rsm75\Downloads\tflite-dist-2.18.0\tflite-dist\libs\windows_x86_64\tensorflowlite_c.dll"

# TensorFlow Lite library URLs for Windows (fallback if local file not found)
$tfliteVersion = "2.14.0"
$windowsLibUrls = @(
    "https://github.com/tensorflow/tensorflow/releases/download/v2.14.0/libtensorflowlite_c-2.14.0-win-x64.zip",
    "https://github.com/am15h/tflite_flutter_plugin/releases/download/v0.10.4/libtensorflowlite_c-win.dll",
    "https://github.com/am15h/tflite_flutter_plugin/releases/download/v0.9.0/libtensorflowlite_c-win.dll"
)

# Create blobs directory if it doesn't exist
$blobsDir = "build\windows\x64\runner\Debug\blobs"
$debugBlobsDir = "build\windows\x64\runner\Debug"
$releaseBlobsDir = "build\windows\x64\runner\Release\blobs"
$releaseDir = "build\windows\x64\runner\Release"

Write-Host "📁 Creating Windows build directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $blobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $debugBlobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $releaseBlobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

Write-Host "🔧 Setting up TensorFlow Lite Windows library..." -ForegroundColor Cyan

try {
    $copySuccess = $false
      # First try to copy from local file if it exists
    if (Test-Path $localTfliteDll) {
        Write-Host "✅ Found local TensorFlow Lite DLL at: $localTfliteDll" -ForegroundColor Green
          # Copy to Debug directories with correct filename
        $debugDllPath = "$blobsDir\libtensorflowlite_c-win.dll"
        $debugRunnerDllPath = "$debugBlobsDir\libtensorflowlite_c-win.dll"
        
        Copy-Item $localTfliteDll $debugDllPath -Force
        Copy-Item $localTfliteDll $debugRunnerDllPath -Force
        
        # Copy to Release directories with correct filename
        $releaseDllPath = "$releaseBlobsDir\libtensorflowlite_c-win.dll"
        $releaseRunnerDllPath = "$releaseDir\libtensorflowlite_c-win.dll"
        
        Copy-Item $localTfliteDll $releaseDllPath -Force
        Copy-Item $localTfliteDll $releaseRunnerDllPath -Force
        
        $copySuccess = $true
        Write-Host "✅ Successfully copied TensorFlow Lite library to all required locations:" -ForegroundColor Green
        Write-Host "   Debug:" -ForegroundColor Yellow
        Write-Host "     - $debugDllPath" -ForegroundColor Gray
        Write-Host "     - $debugRunnerDllPath" -ForegroundColor Gray
        Write-Host "   Release:" -ForegroundColor Yellow
        Write-Host "     - $releaseDllPath" -ForegroundColor Gray
        Write-Host "     - $releaseRunnerDllPath" -ForegroundColor Gray
        
        # Verify files exist and show sizes
        if (Test-Path $debugDllPath) {
            $fileSize = (Get-Item $debugDllPath).Length
            Write-Host "   📊 File size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Gray
        }
          } else {
        Write-Host "⚠️ Local TensorFlow Lite DLL not found at: $localTfliteDll" -ForegroundColor Yellow
        if (!$SkipDownload) {
            Write-Host "📥 Attempting to download from online sources..." -ForegroundColor Cyan
            # Future enhancement: Add download logic here
            Write-Host "💡 For now, please download manually and place at: $localTfliteDll" -ForegroundColor Yellow
        } else {
            Write-Host "⏭️ Skipping download as requested" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    if ($copySuccess) {
        Write-Host "🎉 TensorFlow Lite setup complete!" -ForegroundColor Green
        Write-Host "✅ You can now rebuild your Flutter Windows application." -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ TensorFlow Lite setup incomplete" -ForegroundColor Yellow
        Write-Host "📥 Please obtain the library file and run this script again" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error setting up TensorFlow Lite library: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Manual copy instructions:" -ForegroundColor Yellow
    Write-Host "1. Copy from: $localTfliteDll" -ForegroundColor Gray
    Write-Host "2. Place as: build\windows\x64\runner\Debug\libtensorflowlite_c-win.dll" -ForegroundColor Gray
    Write-Host "3. Also copy to: build\windows\x64\runner\Debug\blobs\libtensorflowlite_c-win.dll" -ForegroundColor Gray
    Write-Host "4. Also copy to: build\windows\x64\runner\Release\libtensorflowlite_c-win.dll" -ForegroundColor Gray
    Write-Host "5. Also copy to: build\windows\x64\runner\Release\blobs\libtensorflowlite_c-win.dll" -ForegroundColor Gray
    exit 1
}
