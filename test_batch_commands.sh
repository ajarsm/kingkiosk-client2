#!/bin/bash
# Script to test batch commands including notifications

# Set device ID and MQTT broker details
# Replace these with your actual MQTT broker details
MQTT_BROKER="localhost"
MQTT_PORT="1883"
DEVICE_NAME="device-12345"  # Replace with your actual device name from the app

echo "Sending batch command with notification and media..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "batch",
  "commands": [
    {
      "command": "notify",
      "title": "Batch Notification Test",
      "message": "This notification was sent as part of a batch command.",
      "priority": "high"
    },
    {
      "command": "play_media",
      "type": "image",
      "url": "https://picsum.photos/800/600",
      "style": "window",
      "title": "Random Image"
    }
  ]
}'

echo "Waiting 5 seconds..."
sleep 5

echo "Sending another batch with HTML notification and web browser..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "commands": [
    {
      "command": "notify",
      "title": "HTML Notification in Batch",
      "message": "<h2>Batch HTML Test</h2><p>This is an <b>HTML</b> notification with a <a href=\"https://example.com\">link</a>.</p>",
      "is_html": true,
      "thumbnail": "https://via.placeholder.com/150"
    },
    {
      "command": "open_browser",
      "title": "Example Website",
      "url": "https://example.com"
    }
  ]
}'

echo "Batch command tests completed!"