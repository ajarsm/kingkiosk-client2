# PowerShell test script for MQTT alert auto-dismiss functionality

param(
    [string]$MqttBroker = "localhost",
    [int]$MqttPort = 1883,
    [string]$DeviceName = "test_device"
)

$Topic = "kingkiosk/$DeviceName/command"

Write-Host "🔔 MQTT Auto-Dismiss Alert Test" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow
Write-Host "Target Device: $DeviceName" -ForegroundColor Cyan
Write-Host "MQTT Broker: ${MqttBroker}:${MqttPort}" -ForegroundColor Cyan
Write-Host ""

# Function to send auto-dismiss alert
function Send-AutoDismissAlert {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Position = "center",
        [string]$Type = "info",
        [int]$AutoDismissSeconds = 0,
        [string]$BorderColor = "",
        [bool]$ShowBorder = $true
    )
    
    $payload = @{
        command = "alert"
        title = $Title
        message = $Message
        type = $Type
        position = $Position
        sound = $true
        is_html = $false
        show_border = $ShowBorder
    }
    
    if ($AutoDismissSeconds -gt 0) {
        $payload.auto_dismiss_seconds = $AutoDismissSeconds
    }
    
    if ($BorderColor -ne "") {
        $payload.border_color = $BorderColor
    }
    
    $jsonPayload = $payload | ConvertTo-Json -Compress
    
    try {
        & mosquitto_pub -h $MqttBroker -p $MqttPort -t $Topic -m $jsonPayload
        $dismissText = if ($AutoDismissSeconds -gt 0) { " (auto-dismiss: ${AutoDismissSeconds}s)" } else { " (manual dismiss)" }
        Write-Host "📨 Sent $Type alert to ${Position}${dismissText}: '$Title'" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to send MQTT message. Is mosquitto_pub installed?" -ForegroundColor Red
        exit 1
    }
}

# Test if mosquitto_pub is available
try {
    & mosquitto_pub --help | Out-Null
}
catch {
    Write-Host "⚠️  mosquitto_pub not found. Please install mosquitto clients." -ForegroundColor Yellow
    Write-Host "   Download: https://mosquitto.org/download/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Testing auto-dismiss alert functionality..." -ForegroundColor Green
Write-Host ""

# Test sequence
Write-Host "📱 Test 1: Quick 3-second auto-dismiss in top-right" -ForegroundColor Cyan
Send-AutoDismissAlert -Title "Quick Alert" -Message "This alert will disappear in 3 seconds" -Position "top-right" -Type "info" -AutoDismissSeconds 3
Start-Sleep -Seconds 4

Write-Host "`n📱 Test 2: 5-second auto-dismiss with custom orange border" -ForegroundColor Cyan
Send-AutoDismissAlert -Title "Auto-Dismiss Alert" -Message "Watch the countdown progress indicator for 5 seconds" -Position "center" -Type "warning" -AutoDismissSeconds 5 -BorderColor "#ff6b35"
Start-Sleep -Seconds 6

Write-Host "`n📱 Test 3: Manual dismiss comparison (no timer)" -ForegroundColor Cyan
Send-AutoDismissAlert -Title "Manual Dismiss" -Message "This alert has no timer and must be closed manually" -Position "bottom-left" -Type "success"
Start-Sleep -Seconds 3

Write-Host "`n📱 Test 4: Quick 1-second flash alert" -ForegroundColor Cyan
Send-AutoDismissAlert -Title "Flash Alert" -Message "Quick flash notification" -Position "top-center" -Type "info" -AutoDismissSeconds 1 -ShowBorder $false
Start-Sleep -Seconds 2

Write-Host "`n✅ Auto-dismiss tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Features tested:" -ForegroundColor White
Write-Host "  ✓ 1, 3, and 5-second auto-dismiss timers" -ForegroundColor Gray
Write-Host "  ✓ Visual countdown progress indicator" -ForegroundColor Gray
Write-Host "  ✓ Different positions with auto-dismiss" -ForegroundColor Gray
Write-Host "  ✓ Manual dismiss vs auto-dismiss comparison" -ForegroundColor Gray
Write-Host "  ✓ Custom border colors with timers" -ForegroundColor Gray
