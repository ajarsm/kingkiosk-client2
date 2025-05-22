#!/bin/bash

# Test script for the WebView Permanent Fix Complete solution V2
# This script sends MQTT commands to test the WebView stability implementation

# Exit on error
set -e

echo "📱 Testing WebView Permanent Fix Complete V2..."

# Get the device name
DEVICE_NAME=$(grep 'deviceName:' lib/app/services/mqtt_service_consolidated.dart | head -n 1 | awk -F "'" '{print $2}')
if [ -z "$DEVICE_NAME" ]; then
    DEVICE_NAME="kingtesting"
    echo "⚠️ Could not find device name in source, using default: $DEVICE_NAME"
else
    echo "📱 Found device name: $DEVICE_NAME"
fi

# Function to send an MQTT message
send_mqtt_message() {
    local topic=$1
    local message=$2
    echo "📤 Sending MQTT message to topic: $topic"
    echo "📄 Message: $message"
    mosquitto_pub -h localhost -t "$topic" -m "$message"
}

# Function to wait a bit
wait_a_bit() {
    local seconds=$1
    echo "⏳ Waiting for $seconds seconds..."
    sleep $seconds
}

echo "🌐 Opening first WebView..."
send_mqtt_message "kiosk/$DEVICE_NAME/command" '{
  "command": "open_browser",
  "url": "https://flutter.dev",
  "title": "Flutter",
  "window_id": "test_flutter_1"
}'

wait_a_bit 3

echo "🌐 Opening second WebView..."
send_mqtt_message "kiosk/$DEVICE_NAME/command" '{
  "command": "open_browser",
  "url": "https://dart.dev",
  "title": "Dart",
  "window_id": "test_dart_1"
}'

wait_a_bit 3

echo "🔄 Switching back to first WebView (testing stability)..."
send_mqtt_message "kiosk/$DEVICE_NAME/windows/test_flutter_1" '{
  "action": "refresh"
}'

wait_a_bit 3

echo "🔄 Switching to second WebView (testing stability)..."
send_mqtt_message "kiosk/$DEVICE_NAME/windows/test_dart_1" '{
  "action": "refresh"
}'

wait_a_bit 3

echo "🌐 Opening third WebView with same ID as first (testing recreation)..."
send_mqtt_message "kiosk/$DEVICE_NAME/command" '{
  "command": "open_browser",
  "url": "https://pub.dev",
  "title": "Pub.dev",
  "window_id": "test_flutter_1"
}'

wait_a_bit 3

echo "🧹 Closing second WebView (testing cleanup)..."
send_mqtt_message "kiosk/$DEVICE_NAME/command" '{
  "command": "close_window",
  "window_id": "test_dart_1"
}'

wait_a_bit 3

echo "🔄 Opening new WebView with previously closed ID (testing reuse)..."
send_mqtt_message "kiosk/$DEVICE_NAME/command" '{
  "command": "open_browser",
  "url": "https://google.com",
  "title": "Google",
  "window_id": "test_dart_1"
}'

echo "✅ Test sequence completed!"
echo "📋 Check the Flutter app logs for WebView controller deallocation messages."
echo "📝 If you don't see 'FlutterWebViewController - dealloc' messages when switching between windows,"
echo "   the fix has been successful."
