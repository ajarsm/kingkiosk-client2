#!/bin/bash
# Test script specifically for testing Android screenshot functionality
# Run this script after connecting an Android device via USB

# Colors for console output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testing Android Screenshot Functionality ===${NC}"
echo -e "${YELLOW}This script will build and run the app on an Android device${NC}"

# Run Flutter doctor to check environment
echo -e "${BLUE}Running flutter doctor...${NC}"
flutter doctor -v | grep -i android

# List connected Android devices
echo -e "${BLUE}Checking connected Android devices...${NC}"
flutter devices | grep -i android

# Build and run the app on Android
echo -e "${BLUE}Building and running app on Android device...${NC}"
flutter run --debug -d android

echo -e "${GREEN}App should be running on your Android device.${NC}"
echo -e "${YELLOW}Now testing screenshot via MQTT command with enhanced debugging:${NC}"

# Check if mosquitto_pub is available
if command -v mosquitto_pub &> /dev/null; then
  # Wait for app to fully initialize
  echo -e "${BLUE}Waiting 10 seconds for app to initialize...${NC}"
  sleep 10
  
  # Publishing MQTT screenshot command
  echo -e "${BLUE}Publishing screenshot command via MQTT...${NC}"
  mosquitto_pub -h broker.emqx.io -p 1883 -t "kiosk/device-12345/command" -m '{
    "command": "screenshot", 
    "notify": true,
    "confirm": true
  }'
  
  echo -e "${GREEN}Command sent! Check the app and gallery for the screenshot.${NC}"
  echo -e "${YELLOW}Listening for confirmation (press Ctrl+C to stop)...${NC}"
  
  # Listen for confirmation messages
  mosquitto_sub -h broker.emqx.io -p 1883 -t "kingkiosk/device-12345/screenshot/status" -v
else
  echo -e "${RED}mosquitto_pub not found. Install it with 'brew install mosquitto' or manually publish:${NC}"
  echo -e "${YELLOW}Topic: kiosk/device-12345/command${NC}"
  echo -e "${YELLOW}Payload: {\"command\": \"screenshot\", \"notify\": true, \"confirm\": true}${NC}"
fi

echo -e "${BLUE}=== Android Screenshot Test Complete ===${NC}"
echo -e "${YELLOW}Check the device's gallery app to verify the screenshot was saved as a proper PNG file${NC}"
