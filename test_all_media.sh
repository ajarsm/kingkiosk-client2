#!/bin/bash

# This script tests MQTT commands for all media types with custom titles

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
echo "MQTT Media Commands Test with Custom Titles"
echo "====================================="

# Test 1: Display image with custom title
echo -e "${BLUE}Test 1: Display an image with custom title${NC}"
publish_command '{
  "command": "play_media",
  "type": "image", 
  "url": "https://picsum.photos/800/600",
  "style": "window",
  "title": "Custom Image Title"
}'

# Test 2: Play video with custom title
echo -e "${BLUE}Test 2: Play video with custom title${NC}"
publish_command '{
  "command": "play_media",
  "type": "video",
  "url": "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
  "style": "window",
  "title": "Custom Video Title",
  "loop": true
}'

# Test 3: Play audio with custom title
echo -e "${BLUE}Test 3: Play audio with custom title${NC}"
publish_command '{
  "command": "play_media",
  "type": "audio",
  "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
  "style": "window",
  "title": "Custom Audio Title",
  "loop": true
}'

# Test 4: Open web browser with custom title
echo -e "${BLUE}Test 4: Open web browser with custom title${NC}"
publish_command '{
  "command": "open_browser",
  "url": "https://www.wikipedia.org",
  "title": "Custom Web Title"
}'

# Test 5: Image carousel with custom title
echo -e "${BLUE}Test 5: Image carousel with custom title${NC}"
publish_command '{
  "command": "play_media",
  "type": "image", 
  "url": [
    "https://picsum.photos/800/600?random=1", 
    "https://picsum.photos/800/600?random=2",
    "https://picsum.photos/800/600?random=3"
  ],
  "style": "window",
  "title": "Custom Carousel Title"
}'

# Test 6: Stop all media
echo -e "${BLUE}Test 6: Stop media command to close all media${NC}"
publish_command '{
  "command": "stop_media"
}'

echo "====================================="
echo "Tests complete! Check the kiosk display to verify the results."
echo "====================================="
