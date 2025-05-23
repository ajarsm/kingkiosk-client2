#!/bin/bash

# Thorough test script to verify the robust halo effect MQTT command handling for color parameters
# Location: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/verify_robust_color_handling.sh

echo "🎨 Testing Robust Halo Effect Color Handling..."

# Function to send MQTT command and wait
send_mqtt_command() {
  local cmd="$1"
  local desc="$2"
  local wait_time="$3"
  
  echo -e "\n🧪 Test: $desc"
  echo "Sending MQTT command: $cmd"
  
  # Send the command using mosquitto_pub
  # Adjust these parameters as needed for your environment
  mosquitto_pub -h localhost -t "kingkiosk/testdevice/command" -m "$cmd"
  
  echo "⏱️ Waiting ${wait_time}s to observe effect..."
  sleep "$wait_time"
}

# Start with clean state
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Reset halo effect" 1

# Test various color formats
send_mqtt_command '{"command":"halo_effect", "color":"#FF0000", "enabled":true}' "Standard hex color (red)" 2
send_mqtt_command '{"command":"halo_effect", "color":"red", "enabled":true}' "Named color (red)" 2
send_mqtt_command '{"command":"halo_effect", "color":"#00FF00", "enabled":true}' "Standard hex color (green)" 2
send_mqtt_command '{"command":"halo_effect", "color":"green", "enabled":true}' "Named color (green)" 2
send_mqtt_command '{"command":"halo_effect", "color":"#0000FF", "enabled":true}' "Standard hex color (blue)" 2
send_mqtt_command '{"command":"halo_effect", "color":"blue", "enabled":true}' "Named color (blue)" 2

# Test invalid color formats (should default to red)
send_mqtt_command '{"command":"halo_effect", "color":"invalid", "enabled":true}' "Invalid color name" 2
send_mqtt_command '{"command":"halo_effect", "color":"#XYZ", "enabled":true}' "Invalid hex value" 2
send_mqtt_command '{"command":"halo_effect", "color":"", "enabled":true}' "Empty color string" 2
send_mqtt_command '{"command":"halo_effect", "color":null, "enabled":true}' "Null color value" 2
send_mqtt_command '{"command":"halo_effect", "enabled":true}' "Missing color parameter" 2

# Test 3-digit hex format
send_mqtt_command '{"command":"halo_effect", "color":"#F00", "enabled":true}' "3-digit hex (red)" 2
send_mqtt_command '{"command":"halo_effect", "color":"#0F0", "enabled":true}' "3-digit hex (green)" 2
send_mqtt_command '{"command":"halo_effect", "color":"#00F", "enabled":true}' "3-digit hex (blue)" 2

# Test with and without # prefix
send_mqtt_command '{"command":"halo_effect", "color":"FF00FF", "enabled":true}' "Hex without # prefix (purple)" 2

# Test with direct integer color value
send_mqtt_command '{"command":"halo_effect", "color":16711680, "enabled":true}' "Integer color value (red)" 2
send_mqtt_command '{"command":"halo_effect", "color":-65536, "enabled":true}' "Negative integer color value" 2

# Test edge cases with other parameters
send_mqtt_command '{"command":"halo_effect", "color":"#FFFF00", "width":"invalid", "enabled":true}' "Valid color with invalid width" 2
send_mqtt_command '{"command":"halo_effect", "color":"#FF00FF", "intensity":"invalid", "enabled":true}' "Valid color with invalid intensity" 2
send_mqtt_command '{"command":"halo_effect", "color":"#00FFFF", "pulse_mode":"invalid", "enabled":true}' "Valid color with invalid pulse mode" 2

# Test combinations of parameters
send_mqtt_command '{"command":"halo_effect", "color":"#FFA500", "width":100, "intensity":0.8, "pulse_mode":"moderate", "enabled":true}' "Complex valid parameters (orange)" 3
send_mqtt_command '{"command":"halo_effect", "color":"#800080", "width":"120", "intensity":"0.5", "pulse_mode":"gentle", "enabled":true}' "String numeric parameters (purple)" 3

# Test for proper cleanup
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Disable halo effect" 1
send_mqtt_command '{"command":"halo_effect", "color":"#00FF00", "enabled":true}' "Re-enable with green" 2 
send_mqtt_command '{"command":"halo_effect", "enabled":false}' "Final disable" 1

echo -e "\n✅ Color handling tests completed"
