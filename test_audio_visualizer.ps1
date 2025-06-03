# Test script for Audio Visualizer implementation via MQTT
# This script tests the new visualizer overlay feature

Write-Host "🎵 Testing Audio Visualizer via MQTT..." -ForegroundColor Cyan

# Test 1: Audio with visualizer style
Write-Host "Test 1: Creating audio visualizer tile..." -ForegroundColor Yellow
$message1 = @"
{
  "command": "play_media",
  "type": "audio",
  "style": "visualizer",
  "url": "https://www.soundjay.com/misc/sounds/bell-ringing-05.wav",
  "title": "Test Audio Visualizer",
  "windowId": "audio-visualizer-test-1"
}
"@

mosquitto_pub -h localhost -t "kingkiosk/command" -m $message1
Start-Sleep -Seconds 3

# Test 2: Audio with visualizer style and auto-generated ID
Write-Host "Test 2: Creating audio visualizer tile with auto-generated ID..." -ForegroundColor Yellow
$message2 = @"
{
  "command": "play_media",
  "type": "audio",
  "style": "visualizer",
  "url": "https://www.soundjay.com/misc/sounds/beep-07a.wav",
  "title": "Auto ID Visualizer"
}
"@

mosquitto_pub -h localhost -t "kingkiosk/command" -m $message2
Start-Sleep -Seconds 3

# Test 3: Regular audio for comparison
Write-Host "Test 3: Creating regular audio tile for comparison..." -ForegroundColor Yellow
$message3 = @"
{
  "command": "play_media",
  "type": "audio",
  "style": "window",
  "url": "https://www.soundjay.com/misc/sounds/beep-10.wav",
  "title": "Regular Audio Tile"
}
"@

mosquitto_pub -h localhost -t "kingkiosk/command" -m $message3
Start-Sleep -Seconds 3

# Test 4: Close all windows
Write-Host "Test 4: Closing all windows..." -ForegroundColor Yellow
$message4 = @"
{
  "action": "close_all_windows"
}
"@

mosquitto_pub -h localhost -t "kingkiosk/command" -m $message4

Write-Host "✅ Audio Visualizer tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Expected behavior:" -ForegroundColor White
Write-Host "- Test 1: Should create an audio visualizer tile with animated frequency bars" -ForegroundColor Gray
Write-Host "- Test 2: Should create another visualizer tile with auto-generated ID" -ForegroundColor Gray
Write-Host "- Test 3: Should create a regular audio tile for comparison" -ForegroundColor Gray
Write-Host "- Test 4: Should close all tiles" -ForegroundColor Gray
Write-Host ""
Write-Host "Verify that the visualizer tiles show animated frequency bars that respond to audio playback." -ForegroundColor Cyan
