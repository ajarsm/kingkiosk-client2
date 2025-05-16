#!/bin/bash

# This script tests MQTT image display commands

# Configuration
MQTT_BROKER="localhost"
MQTT_PORT=1883
DEVICE_NAME="test_kiosk" # Update this to match your device name
MQTT_TOPIC="kiosk/${DEVICE_NAME}/command"

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if mosquitto_pub is installed
if ! command -v mosquitto_pub &> /dev/null; then
    echo -e "${RED}Error: mosquitto_pub is not installed. Please install mosquitto clients:${NC}"
    echo "  brew install mosquitto (on macOS)"
    echo "  sudo apt install mosquitto-clients (on Ubuntu/Debian)"
    exit 1
fi

# Function to publish MQTT commands
publish_command() {
    local payload=$1
    echo -e "${BLUE}Publishing to ${MQTT_TOPIC}:${NC}"
    echo -e "${YELLOW}$payload${NC}"
    mosquitto_pub -h "${MQTT_BROKER}" -p "${MQTT_PORT}" -t "${MQTT_TOPIC}" -m "$payload"
    echo -e "${GREEN}Command sent!${NC}"
    echo "-----------------------------------"
    sleep 1
}

echo "====================================="
echo "MQTT Image Display Test"
echo "====================================="

# Test 1: Display image in window mode
echo -e "${BLUE}Test 1: Display an image in window mode${NC}"
publish_command '{
  "command": "play_media",
  "type": "image", 
  "url": "https://picsum.photos/800/600",
  "style": "window",
  "title": "Window Mode Test"
}'

# Test 2: Display image in fullscreen mode
echo -e "${BLUE}Test 2: Display an image in fullscreen mode${NC}"
publish_command '{
  "command": "play_media",
  "type": "image", 
  "url": "https://picsum.photos/800/600?random=1", 
  "style": "fullscreen"
}'

# Test 3: Test image auto-detection from URL
echo -e "${BLUE}Test 3: Test image type auto-detection from URL extension${NC}"
publish_command '{
  "command": "play_media",
  "url": "https://picsum.photos/800/600.jpg?random=2",
  "style": "window",
  "title": "Auto-detected Image"
}'

# Test 4: Test error handling with invalid image URL
echo -e "${BLUE}Test 4: Test error handling with invalid image URL${NC}"
publish_command '{
  "command": "play_media",
  "type": "image", 
  "url": "https://example.com/not-an-image.jpg",
  "style": "window",
  "title": "Error Test"
}'

# Test 5: Stop all media including images
echo -e "${BLUE}Test 5: Stop media command to close images${NC}"
publish_command '{
  "command": "stop_media"
}'

echo "====================================="
echo "Tests complete! Check the kiosk display to verify the results."
echo "====================================="
