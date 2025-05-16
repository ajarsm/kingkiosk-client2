#!/bin/bash

# This script tests MQTT batch commands functionality

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
echo "MQTT Batch Commands Test"
echo "====================================="

# Test: Send a batch of commands to open multiple windows
echo -e "${BLUE}Test: Sending a batch of commands to open multiple windows${NC}"
publish_command '{
  "commands": [
    {
      "command": "play_media",
      "type": "image", 
      "url": "https://picsum.photos/800/600?random=1",
      "style": "window",
      "title": "Image 1 from Batch"
    },
    {
      "command": "play_media",
      "type": "image", 
      "url": [
        "https://picsum.photos/800/600?random=2", 
        "https://picsum.photos/800/600?random=3",
        "https://picsum.photos/800/600?random=4"
      ],
      "style": "window",
      "title": "Carousel from Batch"
    },
    {
      "command": "open_browser",
      "url": "https://www.wikipedia.org",
      "title": "Web Window from Batch"
    },
    {
      "command": "play_media",
      "type": "audio",
      "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      "style": "window",
      "title": "Audio from Batch"
    }
  ]
}'

# Wait a moment to see the windows
echo -e "${BLUE}Waiting 10 seconds to see the windows...${NC}"
sleep 10

# Test: Close all windows using stop_media command
echo -e "${BLUE}Test: Close all windows using stop_media command${NC}"
publish_command '{
  "command": "stop_media"
}'

echo "====================================="
echo "Batch Commands Test Complete!"
echo "====================================="
