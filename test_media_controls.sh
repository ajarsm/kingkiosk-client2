#!/bin/bash
# filepath: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/test_media_controls.sh

# Set these variables according to your setup
MQTT_HOST="localhost"
MQTT_PORT="1883"
MQTT_USER=""
MQTT_PASS=""
DEVICE_NAME="test-device"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== KingKiosk Media Controls and Reset Test ===${NC}"
echo "Testing media controls and reset_media with background audio preservation"
echo "Target device: ${DEVICE_NAME}"
echo ""

# Function to publish MQTT message
publish_mqtt() {
  local topic=$1
  local message=$2
  
  if [ -z "$MQTT_USER" ]; then
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "$topic" -m "$message"
  else
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$topic" -m "$message"
  fi
  
  # Wait a moment for the command to be processed
  sleep 1
}

# Topic definition
COMMAND_TOPIC="kingkiosk/${DEVICE_NAME}/command"

# Test 1: Play background audio
echo -e "${YELLOW}Test 1: Playing background audio...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "loop": true,
  "style": "background"
}'
echo -e "${GREEN}✓ Sent command to play background audio${NC}"
sleep 3

# Test 2: Pause background audio
echo -e "${YELLOW}Test 2: Pausing background audio...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "pause_audio"
}'
echo -e "${GREEN}✓ Sent command to pause background audio${NC}"
sleep 2

# Test 3: Resume background audio
echo -e "${YELLOW}Test 3: Resuming background audio...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "play_audio"
}'
echo -e "${GREEN}✓ Sent command to resume background audio${NC}"
sleep 2

# Test 4: Seek background audio
echo -e "${YELLOW}Test 4: Seeking background audio to position 30s...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "seek_audio",
  "position": 30
}'
echo -e "${GREEN}✓ Sent command to seek background audio${NC}"
sleep 2

# Test 5: Create a media window
echo -e "${YELLOW}Test 5: Creating a video window...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "title": "Test Video",
  "window_id": "test-video-123"
}'
echo -e "${GREEN}✓ Sent command to create video window${NC}"
sleep 3

# Test 6: Pause video
echo -e "${YELLOW}Test 6: Pausing video...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "pause",
  "window_id": "test-video-123"
}'
echo -e "${GREEN}✓ Sent command to pause video${NC}"
sleep 2

# Test 7: Resume video
echo -e "${YELLOW}Test 7: Resuming video...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "play",
  "window_id": "test-video-123"
}'
echo -e "${GREEN}✓ Sent command to resume video${NC}"
sleep 2

# Test 8: Seek video
echo -e "${YELLOW}Test 8: Seeking video to position 20s...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "seek",
  "window_id": "test-video-123",
  "position": 20
}'
echo -e "${GREEN}✓ Sent command to seek video${NC}"
sleep 2

# Test 9: Reset media (should preserve background audio)
echo -e "${YELLOW}Test 9: Resetting media (this should preserve background audio)...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "reset_media",
  "force": true
}'
echo -e "${GREEN}✓ Sent command to reset media${NC}"
sleep 5

# Test 10: Stop background audio
echo -e "${YELLOW}Test 10: Stopping background audio...${NC}"
publish_mqtt "$COMMAND_TOPIC" '{
  "command": "stop_audio"
}'
echo -e "${GREEN}✓ Sent command to stop background audio${NC}"
sleep 2

echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✓ Completed all media control tests${NC}"
echo ""
echo -e "${PURPLE}Notes:${NC}"
echo "1. Background audio should have continued playing after the media reset"
echo "2. The video window should have been closed during the reset"
echo "3. All media controls should have worked as expected"
echo ""
echo -e "${YELLOW}To verify implementation manually:${NC}"
echo "- Check that background audio was properly preserved during reset_media"
echo "- Verify that all media controls worked as expected"
echo "- Look for any errors in the app's logs"

# Make the script executable
chmod +x "$0"
