# Clean TensorFlow Lite Windows Library Restore Script
# Optimized version with minimal output and error handling

param(
    [switch]$Verbose,
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Define paths
$ProjectRoot = $PSScriptRoot
$WindowsDir = Join-Path $ProjectRoot "windows"
$TensorFlowDLL = Join-Path $ProjectRoot "tensorflowlite_c.dll"
$DestinationDir = Join-Path $WindowsDir "runner"
$DestinationDLL = Join-Path $DestinationDir "tensorflowlite_c.dll"

# Function to write output conditionally
function Write-ConditionalOutput {
    param([string]$Message, [string]$Level = "Info")
    if ($Verbose) {
        switch ($Level) {
            "Error" { Write-Host $Message -ForegroundColor Red }
            "Warning" { Write-Host $Message -ForegroundColor Yellow }
            "Success" { Write-Host $Message -ForegroundColor Green }
            default { Write-Host $Message }
        }
    }
}

try {
    # Check if source DLL exists
    if (-not (Test-Path $TensorFlowDLL)) {
        Write-Host "ERROR: tensorflowlite_c.dll not found in project root" -ForegroundColor Red
        Write-Host "Run quick_setup_windows_tensorflow.bat first to download the library" -ForegroundColor Yellow
        exit 1
    }

    # Check if destination directory exists
    if (-not (Test-Path $DestinationDir)) {
        Write-ConditionalOutput "Creating destination directory: $DestinationDir" "Info"
        New-Item -Path $DestinationDir -ItemType Directory -Force | Out-Null
    }

    # Check if destination file already exists and is up to date
    if ((Test-Path $DestinationDLL) -and -not $Force) {
        $SourceHash = Get-FileHash $TensorFlowDLL -Algorithm MD5
        $DestHash = Get-FileHash $DestinationDLL -Algorithm MD5
        
        if ($SourceHash.Hash -eq $DestHash.Hash) {
            Write-ConditionalOutput "TensorFlow Lite library is already up to date" "Success"
            exit 0
        }
    }

    # Copy the DLL
    Write-ConditionalOutput "Copying TensorFlow Lite library..." "Info"
    Copy-Item $TensorFlowDLL $DestinationDLL -Force

    # Verify the copy
    if (Test-Path $DestinationDLL) {
        $FileSize = (Get-Item $DestinationDLL).Length
        Write-Host "✓ TensorFlow Lite library restored successfully ($([math]::Round($FileSize/1MB, 2)) MB)" -ForegroundColor Green
    } else {
        throw "Failed to copy TensorFlow Lite library"
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
