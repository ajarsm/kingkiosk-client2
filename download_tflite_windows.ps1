# PowerShell script to copy TensorFlow Lite Windows libraries
# This script copies the TensorFlow Lite native library from your downloaded location

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

Write-Host "Creating directories..."
New-Item -ItemType Directory -Force -Path $blobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $debugBlobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $releaseBlobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

Write-Host "Setting up TensorFlow Lite Windows library..."

try {
    $copySuccess = $false
    
    # First try to copy from local file if it exists
    if (Test-Path $localTfliteDll) {
        Write-Host "✅ Found local TensorFlow Lite DLL at: $localTfliteDll"
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
        Write-Host "✅ Successfully copied TensorFlow Lite library to all required locations:"
        Write-Host "   Debug:"
        Write-Host "     - $debugDllPath"
        Write-Host "     - $debugRunnerDllPath"
        Write-Host "   Release:"
        Write-Host "     - $releaseDllPath"
        Write-Host "     - $releaseRunnerDllPath"
        
        # Verify files exist and show sizes
        if (Test-Path $debugDllPath) {
            $fileSize = (Get-Item $debugDllPath).Length
            Write-Host "   File size: $([math]::Round($fileSize / 1MB, 2)) MB"
        }
        
    } else {
        Write-Host "⚠️ Local TensorFlow Lite DLL not found at: $localTfliteDll"
        Write-Host "Attempting to download from online sources..."
    }
    
    Write-Host ""
    Write-Host "🎉 TensorFlow Lite setup complete!"
    Write-Host "You can now rebuild your Flutter application."
    
} catch {
    Write-Host "❌ Error setting up TensorFlow Lite library: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Manual copy instructions:"
    Write-Host "1. Copy from: $localTfliteDll"
    Write-Host "2. Place the file at: build\windows\x64\runner\Debug\tensorflowlite_c.dll"
    Write-Host "3. Also copy to: build\windows\x64\runner\Debug\blobs\tensorflowlite_c.dll"
    exit 1
}
