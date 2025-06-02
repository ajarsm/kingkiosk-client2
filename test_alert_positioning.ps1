# PowerShell script to test MQTT alert positioning functionality
# Test script for the enhanced alert positioning feature

param(
    [string]$MqttBroker = "localhost",
    [int]$MqttPort = 1883,
    [string]$DeviceName = "test_device"
)

$Topic = "kingkiosk/$DeviceName/command"

Write-Host "🚨 MQTT Alert Positioning Test" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host "Target Device: $DeviceName" -ForegroundColor Cyan
Write-Host "MQTT Broker: ${MqttBroker}:${MqttPort}" -ForegroundColor Cyan
Write-Host ""

# Function to send MQTT message using mosquitto_pub (requires mosquitto clients)
function Send-AlertCommand {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Position = "center",
        [string]$Type = "info",
        [int]$Duration = 0,
        [bool]$IsHtml = $false,
        [string]$Thumbnail = ""
    )
    
    $payload = @{
        command = "alert"
        title = $Title
        message = $Message
        type = $Type
        position = $Position
        duration = $Duration
        sound = $true
        is_html = $IsHtml
    }
    
    if ($Thumbnail -ne "") {
        $payload.thumbnail = $Thumbnail
    }
    
    $jsonPayload = $payload | ConvertTo-Json -Compress
    
    try {
        # Using mosquitto_pub command (requires mosquitto clients to be installed)
        & mosquitto_pub -h $MqttBroker -p $MqttPort -t $Topic -m $jsonPayload
        Write-Host "📨 Sent $Type alert to $Position`: '$Title'" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to send MQTT message. Is mosquitto_pub installed?" -ForegroundColor Red
        Write-Host "   Install: https://mosquitto.org/download/" -ForegroundColor Yellow
        Write-Host "   Alternative: Use the Python test script instead" -ForegroundColor Yellow
    }
}

# Test if mosquitto_pub is available
try {
    & mosquitto_pub --help | Out-Null
    $mosquittoAvailable = $true
}
catch {
    $mosquittoAvailable = $false
    Write-Host "⚠️  mosquitto_pub not found. Please install mosquitto clients or use the Python test script." -ForegroundColor Yellow
    Write-Host "   Download: https://mosquitto.org/download/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Testing alert positioning functionality..." -ForegroundColor Green
Write-Host ""

# Test different positions
$positions = @(
    @{Position="center"; Type="info"; Title="Default Center Alert"; Message="This alert appears in the center (default behavior)"},
    @{Position="top-left"; Type="warning"; Title="Top-Left Alert"; Message="This alert appears in the top-left corner"},
    @{Position="top-center"; Type="info"; Title="Top-Center Alert"; Message="This alert appears at the top-center"},
    @{Position="top-right"; Type="success"; Title="Top-Right Alert"; Message="This alert appears in the top-right corner"},
    @{Position="center-left"; Type="error"; Title="Center-Left Alert"; Message="This alert appears on the center-left"},
    @{Position="center-right"; Type="warning"; Title="Center-Right Alert"; Message="This alert appears on the center-right"},
    @{Position="bottom-left"; Type="info"; Title="Bottom-Left Alert"; Message="This alert appears in the bottom-left corner"},
    @{Position="bottom-center"; Type="success"; Title="Bottom-Center Alert"; Message="This alert appears at the bottom-center"},
    @{Position="bottom-right"; Type="error"; Title="Bottom-Right Alert"; Message="This alert appears in the bottom-right corner"}
)

foreach ($test in $positions) {
    Send-AlertCommand -Title $test.Title -Message $test.Message -Position $test.Position -Type $test.Type -Duration 3000
    Start-Sleep -Seconds 4
}

Write-Host ""
Write-Host "✅ Basic positioning test completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Testing additional features..." -ForegroundColor Yellow

# Test HTML alert
Send-AlertCommand -Title "HTML Alert Test" -Message "<b>Bold text</b> and <span style='color:red'>red text</span>" -Position "top-right" -Type "info" -Duration 5000 -IsHtml $true
Start-Sleep -Seconds 6

# Test alert with thumbnail
Send-AlertCommand -Title "Alert with Thumbnail" -Message "This alert includes a thumbnail image" -Position "bottom-left" -Type "success" -Duration 5000 -Thumbnail "https://via.placeholder.com/64x64/00ff00/ffffff?text=OK"

Write-Host ""
Write-Host "🎉 Alert positioning test completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary of tested positions:" -ForegroundColor Cyan
Write-Host "- center (default)" -ForegroundColor White
Write-Host "- top-left, top-center, top-right" -ForegroundColor White
Write-Host "- center-left, center-right" -ForegroundColor White
Write-Host "- bottom-left, bottom-center, bottom-right" -ForegroundColor White
