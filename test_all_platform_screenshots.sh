#!/bin/bash
# Comprehensive test script for the cross-platform screenshot feature
# This script runs tests for both regular and Home Assistant screenshots

# Set device ID and MQTT broker details
# Replace these with your actual MQTT broker details
MQTT_BROKER="localhost"
MQTT_PORT="1883"
DEVICE_NAME="device-12345"  # Replace with your actual device name from the app

# Text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}King Kiosk Screenshot Feature Tester${NC}"
echo -e "${BLUE}=====================================${NC}"
echo
echo -e "Device: ${YELLOW}$DEVICE_NAME${NC}"
echo -e "MQTT Broker: ${YELLOW}$MQTT_BROKER:$MQTT_PORT${NC}"
echo

# Function to run a test
run_test() {
    local test_name=$1
    local payload=$2
    
    echo -e "${GREEN}TEST: $test_name${NC}"
    echo -e "${YELLOW}Payload: $payload${NC}"
    
    # Send command
    mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m "$payload"
    
    echo -e "${GREEN}Command sent! Waiting for 3 seconds...${NC}"
    sleep 3
    echo
}

# Test 1: Basic screenshot
run_test "Basic Screenshot" '{
  "command": "screenshot"
}'

# Test 2: Screenshot with notification
run_test "Screenshot with Notification" '{
  "command": "screenshot",
  "notify": true
}'

# Test 3: Screenshot with confirmation
echo -e "${GREEN}TEST: Screenshot with Confirmation${NC}"
echo -e "${YELLOW}Payload: {\"command\": \"screenshot\", \"confirm\": true}${NC}"

# Start subscription in background
mosquitto_sub -h $MQTT_BROKER -p $MQTT_PORT -t "kingkiosk/$DEVICE_NAME/screenshot/status" -v > /tmp/screenshot_status.log &
SUB_PID=$!

# Send command
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "screenshot",
  "confirm": true
}'

echo -e "${GREEN}Command sent! Waiting for confirmation...${NC}"
sleep 5

# Kill the subscription
kill $SUB_PID 2>/dev/null

# Display results
echo -e "${YELLOW}Confirmation received:${NC}"
cat /tmp/screenshot_status.log
rm /tmp/screenshot_status.log
echo

# Test 4: Complete test with all options
echo -e "${GREEN}TEST: Complete Test with All Options${NC}"
echo -e "${YELLOW}Payload: {\"command\": \"screenshot\", \"notify\": true, \"confirm\": true}${NC}"

# Start subscription in background
mosquitto_sub -h $MQTT_BROKER -p $MQTT_PORT -t "kingkiosk/$DEVICE_NAME/screenshot/status" -v > /tmp/screenshot_status.log &
SUB_PID=$!

# Send command
mosquitto_pub -h $MQTT_BROKER -p $MQTT_PORT -t "kiosk/$DEVICE_NAME/command" -m '{
  "command": "screenshot",
  "notify": true,
  "confirm": true
}'

echo -e "${GREEN}Command sent! Waiting for confirmation...${NC}"
sleep 5

# Kill the subscription
kill $SUB_PID 2>/dev/null

# Display results
echo -e "${YELLOW}Confirmation received:${NC}"
cat /tmp/screenshot_status.log
rm /tmp/screenshot_status.log
echo

# Final check for Home Assistant integration
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Home Assistant Integration Check${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Check if Home Assistant discovery topic exists
mosquitto_sub -h $MQTT_BROKER -p $MQTT_PORT -t "homeassistant/camera/${DEVICE_NAME}_screenshot/config" -C 1 -W 2 > /tmp/ha_discovery.log
if [ -s /tmp/ha_discovery.log ]; then
    echo -e "${GREEN}✓ Home Assistant discovery is configured correctly${NC}"
    echo -e "${YELLOW}Discovery configuration:${NC}"
    cat /tmp/ha_discovery.log
else
    echo -e "${RED}✗ Home Assistant discovery topic not found${NC}"
    echo -e "${YELLOW}This could be because:${NC}"
    echo -e "  - Home Assistant discovery is not enabled in settings"
    echo -e "  - The MQTT broker is not connected"
    echo -e "  - The device hasn't published discovery information yet"
fi
rm /tmp/ha_discovery.log
echo

echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}All tests completed!${NC}"
echo -e "${BLUE}=====================================${NC}"
