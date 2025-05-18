#!/bin/bash
# Script to test screenshot permissions with Android
# Usage: ./test_screenshot_permissions.sh

# Colors for console output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testing King Kiosk Screenshot Functionality ===${NC}"
echo -e "${YELLOW}This script will build and run the app on an Android device${NC}"

# Apply plugin patches first (just in case)
echo -e "${BLUE}Applying plugin patches...${NC}"
./apply_plugin_patches.sh

# Run Flutter doctor to check environment
echo -e "${BLUE}Running flutter doctor...${NC}"
flutter doctor -v

# Clean build directory for a fresh start
echo -e "${BLUE}Cleaning build directory...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}Getting dependencies...${NC}"
flutter pub get

# Build and run the app on Android
echo -e "${BLUE}Building and running app on Android device...${NC}"
flutter run --debug

echo -e "${GREEN}App should be running on your device.${NC}"
echo -e "${YELLOW}Now testing screenshot via MQTT command:${NC}"

# Check if mosquitto_pub is available
if command -v mosquitto_pub &> /dev/null; then
  # Wait for app to fully initialize
  sleep 10
  
  # Publishing MQTT screenshot command
  echo -e "${BLUE}Publishing screenshot command via MQTT...${NC}"
  mosquitto_pub -h broker.emqx.io -p 1883 -t "kiosk/device-12345/command" -m '{"command": "screenshot", "notify": true}'
  
  echo -e "${GREEN}Command sent! Check the app and gallery for the screenshot.${NC}"
else
  echo -e "${RED}mosquitto_pub not found. Install it with 'brew install mosquitto' or manually publish:${NC}"
  echo -e "${YELLOW}Topic: kiosk/device-12345/command${NC}"
  echo -e "${YELLOW}Payload: {\"command\": \"screenshot\", \"notify\": true}${NC}"
fi

echo -e "${BLUE}=== Screenshot Test Complete ===${NC}"
echo -e "${YELLOW}Check the app logs for permission status and screenshot results${NC}"
