#!/bin/bash

# Test script specifically for the halo effect pulsing animations
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/test_halo_pulse.sh

echo "🧪 Testing Halo Effect Pulse Animations..."
echo "This will send MQTT commands to test different pulse modes"

# Function to send MQTT command and wait
send_mqtt_command() {
  local cmd="$1"
  local desc="$2"
  local wait_time="$3"
  
  echo -e "\n🧪 Test: $desc"
  echo "Sending MQTT command: $cmd"
  
  # Send the command using mosquitto_pub
  # Adjust the broker address and topic as needed for your environment
  mosquitto_pub -h localhost -t "kingkiosk/rajofficemac/command" -m "$cmd"
  
  echo "⏱️ Waiting ${wait_time}s to observe effect..."
  sleep "$wait_time"
}

# First disable any existing halo effect
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Reset halo effect" 2

# Test with gentle pulse
send_mqtt_command '{
  "command": "halo_effect", 
  "color": "#FF0000", 
  "enabled": true, 
  "pulse_mode": "gentle", 
  "pulse_duration": 2000
}' "Red with gentle pulse" 8

# Test with moderate pulse
send_mqtt_command '{
  "command": "halo_effect", 
  "color": "#00FF00", 
  "enabled": true, 
  "pulse_mode": "moderate", 
  "pulse_duration": 2000
}' "Green with moderate pulse" 8

# Test with alert pulse
send_mqtt_command '{
  "command": "halo_effect", 
  "color": "#0000FF", 
  "enabled": true, 
  "pulse_mode": "alert", 
  "pulse_duration": 1000
}' "Blue with alert pulse" 8

# Test with different intensity
send_mqtt_command '{
  "command": "halo_effect", 
  "color": "#FFAA00", 
  "enabled": true, 
  "pulse_mode": "moderate", 
  "intensity": 0.9,
  "pulse_duration": 2000
}' "Orange with high intensity" 8

# Disable at the end
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Reset halo effect" 2

echo -e "\n✅ Pulse test completed"
echo "Make sure the animations are smooth and working as expected"
