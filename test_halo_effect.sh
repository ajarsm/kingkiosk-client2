#!/bin/bash

# Test script for Halo Effect feature in KingKiosk
# This script tests various halo effect commands via MQTT

echo "🧪 Starting Halo Effect Feature Test..."

# Create a log file
LOG_FILE="halo_effect_test.log"
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

# Test Case 1: Red Halo Effect (Alarmo Armed)
echo "🧪 Test Case 1: Red Halo Effect (Alarmo Armed)" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#FF0000", "enabled":true}'
wait_for_effect 5 "red halo"

# Test Case 2: Green Halo Effect with Gentle Pulse (Alarmo Disarmed)
echo "🧪 Test Case 2: Green Halo Effect with Gentle Pulse (Alarmo Disarmed)" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#00FF00", "enabled":true, "pulse_mode":"gentle", "pulse_duration":4000}'
wait_for_effect 8 "green gentle pulse"

# Test Case 3: Blue Halo Effect (Away Mode)
echo "🧪 Test Case 3: Blue Halo Effect (Away Mode)" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#0066FF", "enabled":true, "intensity":0.6}'
wait_for_effect 5 "blue halo"

# Test Case 4: Flashing Red Alert Halo Effect (Alarm Triggered)
echo "🧪 Test Case 4: Flashing Red Alert Halo Effect (Alarm Triggered)" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#FF0000", "enabled":true, "pulse_mode":"alert", "pulse_duration":1000, "intensity":0.9}'
wait_for_effect 8 "red flashing alert"

# Test Case 5: Yellow Warning Halo Effect (Low Battery)
echo "🧪 Test Case 5: Yellow Warning Halo Effect (Low Battery)" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#FFCC00", "enabled":true, "pulse_mode":"moderate", "pulse_duration":2000}'
wait_for_effect 6 "yellow warning"

# Test Case 6: Purple Night Mode Halo Effect
echo "🧪 Test Case 6: Purple Night Mode Halo Effect" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#9900FF", "enabled":true, "intensity":0.5}'
wait_for_effect 5 "purple night mode"

# Test Case 7: Disable Halo Effect
echo "🧪 Test Case 7: Disable Halo Effect" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "enabled":false}'
wait_for_effect 3 "disabled halo"

# Test Case 8: Test Width Parameter
echo "🧪 Test Case 8: Test Width Parameter" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#FF6600", "enabled":true, "width":120}'
wait_for_effect 5 "wide orange halo"

# Test Case 9: Test Fade Duration Parameters
echo "🧪 Test Case 9: Test Fade Duration Parameters" | tee -a $LOG_FILE
send_mqtt_command '{"command":"halo_effect", "color":"#00CCFF", "enabled":true, "fade_in_duration":2000, "fade_out_duration":3000}'
wait_for_effect 5 "slow fade cyan halo"

# Finalize by disabling the effect
send_mqtt_command '{"command":"halo_effect", "enabled":false}'

echo "🧹 Test complete"
echo "Use this test script to visually verify the halo effect functionality"
echo "Check the log file for details: $LOG_FILE"
