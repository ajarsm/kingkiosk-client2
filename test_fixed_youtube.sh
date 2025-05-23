#!/bin/bash

# Test YouTube player functionality
echo "Testing YouTube player functionality..."

# Activate the device
echo "Activating device..."
mosquitto_pub -h localhost -t 'kingkiosk/device/activation' -m '{"command":"activate", "device_id":"testdevice"}'
sleep 2

# Send YouTube command
echo "Opening YouTube video..."
mosquitto_pub -h localhost -t 'kingkiosk/device/testdevice/command' -m '{"command":"youtube", "window_id":"youtube_test", "title":"Demo Video", "url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
sleep 5

echo "Test completed successfully!"
