#!/bin/bash

# Test WebView persistence implementation with callback handler approach
# This script performs tests to verify that WebViews persist correctly during rebuilds

echo "🧪 Starting WebView Callback Handler Implementation Test..."

# Create a log file
LOG_FILE="webview_fix_callback_test.log"
echo "📝 Log file: $LOG_FILE"
> $LOG_FILE

# Function to send MQTT command
send_mqtt_command() {
  WINDOW_ID=$1
  URL=$2
  echo "Sending MQTT command to open browser window ID: $WINDOW_ID with URL: $URL"
  mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "{\"command\":\"open_browser\",\"window_id\":\"$WINDOW_ID\",\"url\":\"$URL\"}"
}

# Function to send refresh MQTT command 
refresh_window() {
  WINDOW_ID=$1
  URL=$2
  echo "Refreshing browser window ID: $WINDOW_ID with URL: $URL?refresh=$(date +%s)"
  mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "{\"command\":\"open_browser\",\"window_id\":\"$WINDOW_ID\",\"url\":\"$URL?refresh=$(date +%s)\"}"
}

# Function to close window
close_window() {
  WINDOW_ID=$1
  echo "Closing window ID: $WINDOW_ID"
  mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "{\"command\":\"close_window\",\"window_id\":\"$WINDOW_ID\"}"
}

# Test case 1: Create and refresh same window multiple times
echo "🧪 Test case 1: Create and refresh same window multiple times" | tee -a $LOG_FILE
WINDOW_ID="test_webview_1"
URL="https://flutter.dev"

send_mqtt_command $WINDOW_ID $URL
sleep 3

# Refresh the window multiple times
for i in {1..3}; do
  refresh_window $WINDOW_ID $URL
  sleep 2
done

# Test case 2: Create multiple windows and verify they don't interfere
echo "🧪 Test case 2: Create multiple windows and verify they don't interfere" | tee -a $LOG_FILE
send_mqtt_command "test_webview_2" "https://dart.dev"
sleep 2
send_mqtt_command "test_webview_3" "https://github.com"
sleep 2

# Refresh one of them
refresh_window "test_webview_2" "https://dart.dev"
sleep 2

# Close windows in reverse order
close_window "test_webview_3"
sleep 1
close_window "test_webview_2"
sleep 1
close_window "test_webview_1"

echo "🔍 Analyzing logs..."
# Count WebView creations
CREATIONS=$(grep -c "Creating new WebView for ID:" $LOG_FILE)
REUSES=$(grep -c "Reusing WebView for ID:" $LOG_FILE)

echo "📊 Results:" | tee -a $LOG_FILE
echo "- WebView creations: $CREATIONS (should be 3, one for each unique window ID)" | tee -a $LOG_FILE
echo "- WebView reuses: $REUSES (should be at least 3 for refreshes)" | tee -a $LOG_FILE

if [ "$CREATIONS" -eq 3 ] && [ "$REUSES" -ge 3 ]; then
  echo "✅ TEST PASSED: WebView instances are properly persistent!" | tee -a $LOG_FILE
else
  echo "❌ TEST FAILED: WebView instances are not being properly maintained" | tee -a $LOG_FILE
fi

echo "🧹 Test complete"
