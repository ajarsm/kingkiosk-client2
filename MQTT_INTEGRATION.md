# MQTT Integration for Flutter GetX Kiosk

This document explains the MQTT integration features implemented in the Flutter GetX Kiosk application.

## Features

### 1. Home Assistant Auto-Discovery
- The kiosk automatically registers its sensors with Home Assistant
- Enables monitoring of the kiosk's status from Home Assistant
- Publishes sensor data including battery level, CPU usage, memory usage, etc.

### 2. Remote Control via MQTT Commands
- Control the kiosk remotely by sending commands via MQTT
- Play media (audio/video) in background or fullscreen mode
- Control playback (play, pause, stop)
- More command types can be easily added

### 3. Device Status Publishing
- Device reports its online/offline status automatically
- Publishes sensor data at regular intervals
- Uses retained messages for status persistence

## MQTT Topics Structure

### Device Status
- `kiosk/{device_name}/status` - Online/offline status (retained)

### Sensor Data
- `kiosk/{device_name}/sensor/battery_level/state` - Battery level
- `kiosk/{device_name}/sensor/battery_status/state` - Battery status
- `kiosk/{device_name}/sensor/cpu_usage/state` - CPU usage
- `kiosk/{device_name}/sensor/memory_usage/state` - Memory usage

### Command Channel
- `kiosk/{device_name}/command` - Send commands to the kiosk

### Home Assistant Auto-Discovery
- `homeassistant/sensor/{device_name}/{unique_id}/config` - Sensor configuration

## Command Examples

### Play Audio in Background
```json
{
  "play_media": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
  "type": "audio"
}
```

### Play Video in Background
```json
{
  "play_media": "https://example.com/video.mp4",
  "type": "video",
  "style": "background"
}
```

### Play Video in Fullscreen
```json
{
  "play_media": "https://example.com/video.mp4",
  "type": "video",
  "style": "fullscreen"
}
```

### Pause Media
```json
{
  "pause_media": true
}
```

### Resume Media
```json
{
  "resume_media": true
}
```

### Stop Media
```json
{
  "stop_media": true
}
```

## Configuration

MQTT settings can be configured in the application's settings screen:

1. **MQTT Broker URL**: The URL of your MQTT broker
2. **MQTT Broker Port**: The port number (default: 1883)
3. **Username/Password**: Authentication credentials (if required)
4. **Device Name**: Unique identifier for this device
5. **Home Assistant Discovery**: Toggle to enable/disable Home Assistant integration

## Implementation Details

The MQTT implementation uses the following components:

- **MqttService**: Core service managing MQTT connectivity
- **BackgroundMediaService**: Handles media playback without UI
- **mqtt_client**: Dart package for MQTT protocol support
- **Settings UI**: Configuration interface for MQTT settings

## Security Considerations

- MQTT credentials are stored securely
- TLS support for secure connections
- MQTT topics use device name as namespace to avoid conflicts

## Extending the System

To add new command types:

1. Update the `_processCommand` method in `MqttService`
2. Add appropriate handlers for new commands
3. Document the new command format in this file