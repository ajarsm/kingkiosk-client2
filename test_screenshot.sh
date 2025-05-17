#!/bin/bash
# Script to test MQTT screenshot feature

# Set device ID and MQTT broker details
# Replace these with your actual MQTT broker details
MQTT_BROKER="localhost"
MQTT_PORT="1883"
DEVICE_NAME="device-12345"  # Replace with your actual device name from the app

echo "Sending screenshot command..."
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "screenshot"
}'

echo "Screenshot command sent!"
echo "The screenshot should be taken and published to Home Assistant if discovery is enabled."
echo "Check the app logs for confirmation."
