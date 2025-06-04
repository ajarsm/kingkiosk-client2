# PowerShell script to download TensorFlow Lite Windows libraries
# This script downloads the required TensorFlow Lite native libraries for Windows

$ErrorActionPreference = "Stop"

# TensorFlow Lite library URLs for Windows
$tfliteVersion = "2.14.0"
# Try multiple sources for the DLL
$windowsLibUrls = @(
    "https://github.com/tensorflow/tensorflow/releases/download/v2.14.0/libtensorflowlite_c-2.14.0-win-x64.zip",
    "https://github.com/am15h/tflite_flutter_plugin/releases/download/v0.10.4/libtensorflowlite_c-win.dll",
    "https://github.com/am15h/tflite_flutter_plugin/releases/download/v0.9.0/libtensorflowlite_c-win.dll"
)

# Create blobs directory if it doesn't exist
$blobsDir = "build\windows\x64\runner\Debug\blobs"
$debugBlobsDir = "build\windows\x64\runner\Debug"

Write-Host "Creating directories..."
New-Item -ItemType Directory -Force -Path $blobsDir | Out-Null
New-Item -ItemType Directory -Force -Path $debugBlobsDir | Out-Null

Write-Host "Downloading TensorFlow Lite Windows library..."

try {
    $downloadSuccess = $false
    
    foreach ($url in $windowsLibUrls) {
        try {
            Write-Host "Trying to download from: $url"
            
            if ($url.EndsWith(".zip")) {
                # Handle ZIP download
                $zipPath = "$env:TEMP\tflite.zip"
                Invoke-WebRequest -Uri $url -OutFile $zipPath -TimeoutSec 30
                
                # Extract the ZIP
                Expand-Archive -Path $zipPath -DestinationPath "$env:TEMP\tflite_extract" -Force
                
                # Find the DLL in the extracted files
                $dllFile = Get-ChildItem -Path "$env:TEMP\tflite_extract" -Filter "*.dll" -Recurse | Select-Object -First 1
                if ($dllFile) {
                    $dllPath = "$blobsDir\libtensorflowlite_c-win.dll"
                    Copy-Item $dllFile.FullName $dllPath -Force
                    $downloadSuccess = $true
                    Write-Host "✅ Successfully downloaded and extracted TensorFlow Lite library from ZIP"
                    break
                }
            } else {
                # Handle direct DLL download
                $dllPath = "$blobsDir\libtensorflowlite_c-win.dll"
                Invoke-WebRequest -Uri $url -OutFile $dllPath -TimeoutSec 30
                $downloadSuccess = $true
                Write-Host "✅ Successfully downloaded TensorFlow Lite library"
                break
            }
        } catch {
            Write-Host "Failed to download from $url : $($_.Exception.Message)"
            continue
        }
    }
    
    if (-not $downloadSuccess) {
        throw "All download attempts failed"
    }
    
    # Copy to the runner directory
    $runnerDllPath = "$debugBlobsDir\libtensorflowlite_c-win.dll"
    Copy-Item $dllPath $runnerDllPath -Force
    
    Write-Host "✅ Successfully placed TensorFlow Lite library at:"
    Write-Host "   - $dllPath"
    Write-Host "   - $runnerDllPath"
    
    # Verify files exist
    if (Test-Path $dllPath) {
        $fileSize = (Get-Item $dllPath).Length
        Write-Host "   File size: $($fileSize / 1MB) MB"
    }
    
    Write-Host ""
    Write-Host "🎉 TensorFlow Lite setup complete!"
    Write-Host "You can now rebuild your Flutter application."
    
} catch {
    Write-Host "❌ Error downloading TensorFlow Lite library: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Manual download instructions:"
    Write-Host "1. Download TensorFlow Lite C library from one of these sources:"
    foreach ($url in $windowsLibUrls) {
        Write-Host "   - $url"
    }
    Write-Host "2. Place the file at: $blobsDir\libtensorflowlite_c-win.dll"
    Write-Host "3. Also copy to: $debugBlobsDir\libtensorflowlite_c-win.dll"
    exit 1
}
