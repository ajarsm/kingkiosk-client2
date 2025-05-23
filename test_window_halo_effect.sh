#!/bin/bash

# Test script for the Window-Specific Halo Effect feature in KingKiosk
# This script tests window-specific halo effects via MQTT

echo "🧪 Starting Window-Specific Halo Effect Test..."

# Create a log file
LOG_FILE="window_halo_effect_test.log"
echo "📝 Log file: $LOG_FILE"
> $LOG_FILE

# Function to send MQTT command
send_mqtt_command() {
  PAYLOAD=$1
  echo "Sending MQTT command: $PAYLOAD" | tee -a $LOG_FILE
  mosquitto_pub -h localhost -p 1883 -t kingkiosk/command -m "$PAYLOAD"
}

# Function to wait for visual confirmation
wait_for_effect() {
  SECONDS=$1
  EFFECT_NAME=$2
  echo "⏱️ Waiting $SECONDS seconds to observe $EFFECT_NAME effect..." | tee -a $LOG_FILE
  sleep $SECONDS
}

# First, create a few windows
echo "🧪 Creating two test windows..." | tee -a $LOG_FILE
send_mqtt_command '{"command":"open_browser", "url":"https://example.com", "title":"Test Window 1", "window_id":"test_window_1"}'
wait_for_effect 2 "window creation"

send_mqtt_command '{"command":"open_browser", "url":"https://google.com", "title":"Test Window 2", "window_id":"test_window_2"}'
wait_for_effect 2 "window creation"

# Test Case 1: Red Halo Effect on Window 1
echo "🧪 Test Case 1: Red Halo Effect on Window 1" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_1", "color":"#FF0000", "enabled":true}'
wait_for_effect 5 "red halo on window 1"

# Test Case 2: Blue Halo Effect on Window 2
echo "🧪 Test Case 2: Blue Halo Effect on Window 2" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_2", "color":"#0066FF", "enabled":true}'
wait_for_effect 5 "blue halo on window 2"

# Test Case 3: Green Pulsing Halo on Window 1
echo "🧪 Test Case 3: Green Pulsing Halo on Window 1" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_1", "color":"#00FF00", "enabled":true, "pulse_mode":"gentle", "pulse_duration":3000}'
wait_for_effect 8 "green pulsing halo on window 1"

# Test Case 4: Alert Pulse on Window 2
echo "🧪 Test Case 4: Alert Pulse on Window 2" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_2", "color":"#FF0000", "enabled":true, "pulse_mode":"alert", "pulse_duration":1000}'
wait_for_effect 8 "red alert pulse on window 2"

# Test Case 5: Disable Halo on Window 1
echo "🧪 Test Case 5: Disable Halo on Window 1" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_1", "enabled":false}'
wait_for_effect 3 "disabled halo on window 1"

# Test Case 6: Main App Halo (should work with existing windows)
echo "🧪 Test Case 6: Main App Halo" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#9900FF", "enabled":true}'
wait_for_effect 5 "main app purple halo"

# Clean up - disable all halos
echo "🧪 Cleaning up - disabling all halos" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "enabled":false}'
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_1", "enabled":false}'
send_mqtt_command '{"command":"halo_effect", "window_id":"test_window_2", "enabled":false}'
wait_for_effect 2 "clean up"

# Close windows
echo "🧪 Closing test windows" | tee -a $LOG_FILE
send_mqtt_command '{"command":"close_window", "window_id":"test_window_1"}'
send_mqtt_command '{"command":"close_window", "window_id":"test_window_2"}'

echo "🧹 Test complete"
echo "Use this test script to visually verify the window-specific halo effect functionality"
echo "Check the log file for details: $LOG_FILE"
