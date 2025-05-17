#!/bin/bash
# Script to test sending notifications via MQTT

# Set device ID and MQTT broker details
# Replace these with your actual MQTT broker details
MQTT_BROKER="192.168."
MQTT_PORT="1883"
DEVICE_NAME="device-12345"  # Replace with your actual device name from the app

# Basic notification
echo "Sending basic notification..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "notify",
  "title": "MQTT Test Notification",
  "message": "This is a test notification sent via MQTT."
}'

echo "Waiting 3 seconds..."
sleep 3

# HTML notification with high priority
echo "Sending HTML notification with high priority..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "notify",
  "title": "HTML Notification Test",
  "message": "<h2>Important Alert</h2><p>This is a <b>formatted</b> message with <span style=\"color: red;\">colored text</span> and a <a href=\"https://example.com\">link</a>.</p>",
  "is_html": true,
  "priority": "high",
  "thumbnail": "https://via.placeholder.com/150"
}'

echo "Notification tests completed!"
