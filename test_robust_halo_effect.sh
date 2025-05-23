#!/bin/bash

# Test script to verify the robust halo effect fixes
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/test_robust_halo_effect.sh

echo "🧪 Testing Robust Halo Effect MQTT Commands..."
echo "This test will send various edge case MQTT commands to verify our error handling"

# Function to send MQTT command and wait
send_mqtt_command() {
  local cmd="$1"
  local desc="$2"
  local wait_time="$3"
  
  echo -e "\n🧪 Test: $desc"
  echo "Sending MQTT command: $cmd"
  
  # Send the command using mosquitto_pub (make sure it's installed)
  # Adjust the broker address and topic as needed for your environment
  mosquitto_pub -h localhost -t "kingkiosk/testdevice/command" -m "$cmd"
  
  echo "⏱️ Waiting ${wait_time}s to observe effect..."
  sleep "$wait_time"
}

# Start testing with valid commands
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Reset halo effect state" 2

# Test standard valid command
send_mqtt_command '{"command":"halo_effect", "color":"#FF0000", "enabled":true}' "Standard red border" 3

# Test edge cases for color parameter
send_mqtt_command '{"command":"halo_effect", "color":"invalid", "enabled":true}' "Invalid color string" 3
send_mqtt_command '{"command":"halo_effect", "color":"#XYZ", "enabled":true}' "Invalid hex color" 3
send_mqtt_command '{"command":"halo_effect", "color":"red", "enabled":true}' "Named color" 3
send_mqtt_command '{"command":"halo_effect", "color":null, "enabled":true}' "Null color" 3
send_mqtt_command '{"command":"halo_effect", "enabled":true}' "Missing color" 3

# Test edge cases for numeric parameters
send_mqtt_command '{"command":"halo_effect", "color":"#00FF00", "width":"invalid", "enabled":true}' "Invalid width" 3
send_mqtt_command '{"command":"halo_effect", "color":"#00FF00", "width":-10, "enabled":true}' "Negative width" 3
send_mqtt_command '{"command":"halo_effect", "color":"#0000FF", "intensity":"invalid", "enabled":true}' "Invalid intensity" 3
send_mqtt_command '{"command":"halo_effect", "color":"#0000FF", "intensity":2.5, "enabled":true}' "Intensity out of range (high)" 3
send_mqtt_command '{"command":"halo_effect", "color":"#0000FF", "intensity":-0.5, "enabled":true}' "Intensity out of range (low)" 3

# Test edge cases for duration parameters
send_mqtt_command '{"command":"halo_effect", "color":"#FF00FF", "pulse_mode":"gentle", "pulse_duration":"invalid", "enabled":true}' "Invalid pulse duration" 3
send_mqtt_command '{"command":"halo_effect", "color":"#FF00FF", "pulse_mode":"gentle", "pulse_duration":20, "enabled":true}' "Pulse duration too small" 3
send_mqtt_command '{"command":"halo_effect", "color":"#FF00FF", "pulse_mode":"gentle", "pulse_duration":20000, "enabled":true}' "Pulse duration too large" 3

# Complex test cases
send_mqtt_command '{"command":"halo_effect", "color":"#00FFFF", "width":100, "intensity":0.8, "pulse_mode":"moderate", "pulse_duration":1500, "fade_in_duration":400, "fade_out_duration":700, "enabled":true}' "Complex valid parameters" 5
send_mqtt_command '{"command":"halo_effect", "color":"#00FFFF", "width":"100", "intensity":"0.8", "pulse_mode":"moderate", "pulse_duration":"1500", "enabled":true}' "String numeric parameters" 3

# Disable halo effect at the end
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Disable halo effect" 2

echo -e "\n✅ All halo effect tests completed"
