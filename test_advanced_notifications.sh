#!/bin/bash
# Script to test advanced notification features

# Set device ID and MQTT broker details
# Replace these with your actual MQTT broker details
MQTT_BROKER="localhost"
MQTT_PORT="1883"
DEVICE_NAME="device-12345"  # Replace with your actual device name from the app

# HTML notification with thumbnail
echo "Sending HTML notification with thumbnail..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "notify",
  "title": "HTML with Thumbnail",
  "message": "<h2>HTML Format</h2><p>This notification includes <b>formatted text</b> and a thumbnail image.</p>",
  "is_html": true,
  "thumbnail": "https://picsum.photos/200"
}'

echo "Waiting 3 seconds..."
sleep 3

# Low priority notification
echo "Sending low priority notification..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "notify",
  "title": "Low Priority",
  "message": "This is a low priority notification.",
  "priority": "low"
}'

echo "Waiting 3 seconds..."
sleep 3

# High priority notification with HTML and thumbnail
echo "Sending high priority HTML notification with thumbnail..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "notify",
  "title": "IMPORTANT ALERT",
  "message": "<h1 style=\"color:red\">Critical Update</h1><p>This is a <b>high priority</b> notification with <span style=\"color:blue\">styled text</span>.</p>",
  "is_html": true,
  "priority": "high",
  "thumbnail": "https://picsum.photos/id/237/200"
}'

echo "Advanced notification tests completed!"
