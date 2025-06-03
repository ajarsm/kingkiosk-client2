#!/bin/bash

# Test script for Audio Visualizer implementation via MQTT
# This script tests the new visualizer overlay feature

echo "🎵 Testing Audio Visualizer via MQTT..."

# Test 1: Audio with visualizer style
echo "Test 1: Creating audio visualizer tile..."
mosquitto_pub -h localhost -t "kingkiosk/command" -m '{
  "command": "play_media",
  "type": "audio",
  "style": "visualizer",
  "url": "https://www.soundjay.com/misc/sounds/bell-ringing-05.wav",
  "title": "Test Audio Visualizer",
  "windowId": "audio-visualizer-test-1"
}'

sleep 3

# Test 2: Audio with visualizer style and auto-generated ID
echo "Test 2: Creating audio visualizer tile with auto-generated ID..."
mosquitto_pub -h localhost -t "kingkiosk/command" -m '{
  "command": "play_media",
  "type": "audio",
  "style": "visualizer",
  "url": "https://www.soundjay.com/misc/sounds/beep-07a.wav",
  "title": "Auto ID Visualizer"
}'

sleep 3

# Test 3: Regular audio for comparison
echo "Test 3: Creating regular audio tile for comparison..."
mosquitto_pub -h localhost -t "kingkiosk/command" -m '{
  "command": "play_media",
  "type": "audio",
  "style": "window",
  "url": "https://www.soundjay.com/misc/sounds/beep-10.wav",
  "title": "Regular Audio Tile"
}'

sleep 3

# Test 4: Close all windows
echo "Test 4: Closing all windows..."
mosquitto_pub -h localhost -t "kingkiosk/command" -m '{
  "action": "close_all_windows"
}'

echo "✅ Audio Visualizer tests completed!"
echo ""
echo "Expected behavior:"
echo "- Test 1: Should create an audio visualizer tile with animated frequency bars"
echo "- Test 2: Should create another visualizer tile with auto-generated ID"
echo "- Test 3: Should create a regular audio tile for comparison"
echo "- Test 4: Should close all tiles"
echo ""
echo "Verify that the visualizer tiles show animated frequency bars that respond to audio playback."
