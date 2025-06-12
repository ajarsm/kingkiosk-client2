# KingKiosk MQTT Service Reference Manual

## Table of Contents
1. [Overview](#overview)
2. [Connection Setup](#connection-setup)
3. [Device Configuration](#device-configuration)
4. [Media Commands](#media-commands)
5. [Window Management](#window-management)
6. [System Control](#system-control)
7. [Notification Commands](#notification-commands)
8. [Visual Effects](#visual-effects)
9. [Background Control](#background-control)
10. [Widget Commands](#widget-commands)
11. [Automation & Batch Scripts](#automation--batch-scripts)
12. [Settings & Provisioning](#settings--provisioning)
13. [Monitoring & Diagnostics](#monitoring--diagnostics)
14. [Home Assistant Integration](#home-assistant-integration)
15. [Error Handling](#error-handling)

## Overview

The KingKiosk MQTT service provides comprehensive remote control and monitoring capabilities for your kiosk application. All commands are sent as JSON payloads to specific MQTT topics with automatic device discovery and real-time sensor reporting.

### Core Features
- **Media Playback**: Audio, video, images with multiple presentation styles
- **Window Management**: Create, control, and manipulate multiple windows
- **System Control**: Volume, brightness, screenshots, TTS
- **Visual Effects**: Halo effects for windows and global app
- **Background Control**: Dynamic background images and webviews
- **Notifications**: Alerts and notifications with customizable styling
- **Automation**: Batch script execution with progress tracking
- **Remote Provisioning**: Complete settings configuration via MQTT
- **Home Assistant Integration**: Auto-discovery and sensor publishing

### Base Topics
- **Command Topic**: `kingkiosk/{device_name}/command`
- **Commands Topic**: `kingkiosk/{device_name}/commands` (alias)
- **Status Topic**: `kingkiosk/{device_name}/status`
- **Sensor Topics**: `kingkiosk/{device_name}/{sensor_name}`
- **Response Topics**: `kingkiosk/{device_name}/{command}/response`
- **Window Topics**: `kiosk/{device_name}/window/{window_id}/command`

### Command Structure
All commands follow this basic JSON structure:
```json
{
  "command": "command_name",
  "parameter1": "value1",
  "parameter2": "value2",
  "response_topic": "optional/response/topic"
}
```

### Device Status
Devices automatically publish online/offline status with Last Will and Testament (LWT):
- **Online**: `online`
- **Offline**: `offline` (automatic on disconnect)

## Connection Setup

### MQTT Broker Configuration
Configure your MQTT broker connection through the settings UI or via provisioning commands.

**Connection Parameters:**
- `brokerUrl`: MQTT broker hostname or IP address
- `port`: MQTT broker port (1883 for plain, 8883 for SSL/TLS)
- `username`: Optional authentication username
- `password`: Optional authentication password
- `clientId`: Auto-generated unique identifier
- `keepAlive`: 30 seconds (automatic)
- `autoReconnect`: Enabled with automatic resubscription

**Connection Features:**
- Automatic reconnection on network loss
- Persistent session support
- Connection status monitoring
- Graceful disconnect handling

## Device Configuration

### Device Naming
Device names are automatically sanitized to be MQTT-friendly:
- "kiosk" prefix removed if present
- Spaces replaced with underscores
- Special characters removed
- Converted to lowercase
- Unique suffix added if name is empty

**Example Transformations:**
- `"Kiosk Living Room"` → `"living_room"`
- `"My Device!"` → `"my_device"`
- `""` → `"device-12345"` (auto-generated)

## Media Commands

### play_media
Play audio, video, or display images with various presentation styles.

```json
{
  "command": "play_media",
  "type": "video|audio|image",
  "url": "https://example.com/media.mp4",
  "style": "fullscreen|window|background|visualizer",
  "title": "Media Title",
  "loop": true,
  "window_id": "custom-id-123",
  "hardware_accel": true
}
```

**Parameters:**
- `type`: Media type (auto-detected from URL extension if omitted)
  - `video`: Video files (.mp4, .webm, .avi, .mov, .mkv)
  - `audio`: Audio files (.mp3, .wav, .flac, .m4a, .ogg)
  - `image`: Image files (.jpg, .png, .gif, .webp)
- `url`: Media URL (HTTP/HTTPS/file:// supported)
- `style`: Presentation style
  - `fullscreen`: Full screen playback with controls
  - `window`: Windowed playback
  - `background`: Background audio only (audio files)
  - `visualizer`: Audio with visualization effects
- `title`: Window title (default: "Kiosk Audio/Video")
- `loop`: Enable looping playback (default: false)
- `window_id`: Custom window identifier for later control
- `hardware_accel`: Force hardware acceleration on/off

**Examples:**

Play video in fullscreen:
```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
  "style": "fullscreen",
  "loop": true
}
```

Play audio with visualizer:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://www.soundjay.com/misc/sounds/bell-ringing-05.wav",
  "style": "visualizer",
  "title": "Background Music",
  "window_id": "music-player-1"
}
```

Display image in window:
```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://picsum.photos/1920/1080",
  "style": "window",
  "title": "Photo Display"
}
```

### Media Control Commands
Control playback of existing media windows:

**Play/Resume:**
```json
{
  "command": "play",
  "window_id": "music-player-1"
}
```

**Pause:**
```json
{
  "command": "pause",
  "window_id": "music-player-1"
}
```

**Close Media:**
```json
{
  "command": "close",
  "window_id": "music-player-1"
}
```

### Background Audio Control
Control background audio playback:

**Play Background Audio:**
```json
{
  "command": "play_audio",
  "url": "https://example.com/background.mp3",
  "loop": true
}
```

**Pause/Stop Background Audio:**
```json
{
  "command": "pause_audio"
}
```

```json
{
  "command": "stop_audio"
}
```

**Seek Background Audio:**
```json
{
  "command": "seek_audio",
  "position": 30.5
}
```

### Emergency Media Reset
Fix black screens or stuck media:

```json
{
  "command": "reset_media",
  "force": true,
  "test": false
}
```

**Parameters:**
- `force`: Force reset even if media appears working
- `test`: Test mode - report issues without fixing

## Window Management

### Browser Windows

**Open Browser Window:**
```json
{
  "command": "open_browser",
  "url": "https://example.com",
  "title": "My Website",
  "window_id": "browser-1"
}
```

### YouTube Windows

**Open YouTube Video:**
```json
{
  "command": "youtube",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "YouTube Player",
  "window_id": "youtube-1"
}
```

### PDF Documents

**Open PDF Document:**
```json
{
  "command": "open_pdf",
  "url": "https://example.com/document.pdf",
  "title": "PDF Viewer",
  "window_id": "pdf-1"
}
```

### Window Control Commands

**Close Window:**
```json
{
  "command": "close_window",
  "window_id": "browser-1"
}
```

**Maximize Window:**
```json
{
  "command": "maximize_window",
  "window_id": "browser-1"
}
```

**Minimize Window:**
```json
{
  "command": "minimize_window",
  "window_id": "browser-1"
}
```

### WebView Controls
Control web content in browser windows:

**Refresh Page:**
```json
{
  "command": "refresh",
  "window_id": "browser-1"
}
```

**Restart WebView:**
```json
{
  "command": "restart",
  "window_id": "browser-1"
}
```

**Execute JavaScript:**
```json
{
  "command": "evaljs",
  "window_id": "browser-1",
  "code": "document.body.style.backgroundColor = 'red';"
}
```

**Load New URL:**
```json
{
  "command": "loadurl",
  "window_id": "browser-1",
  "url": "https://newsite.com"
}
```

## System Control

### Volume Control

**Set Volume (0.0 to 1.0):**
```json
{
  "command": "set_volume",
  "value": "0.5"
}
```

**Mute System:**
```json
{
  "command": "mute"
}
```

**Unmute System:**
```json
{
  "command": "unmute"
}
```

### Brightness Control

**Set Brightness (0.0 to 1.0):**
```json
{
  "command": "set_brightness",
  "value": "0.8"
}
```

**Get Current Brightness:**
```json
{
  "command": "get_brightness",
  "response_topic": "kingkiosk/my-device/brightness/response"
}
```

**Restore Full Brightness:**
```json
{
  "command": "restore_brightness"
}
```

### Text-to-Speech (TTS)

**Speak Text:**
```json
{
  "command": "tts",
  "text": "Hello, this is a test message",
  "language": "en-US",
  "rate": 1.0,
  "pitch": 1.0,
  "volume": 0.8
}
```

**Alternative TTS Commands:**
```json
{
  "command": "speak",
  "text": "Another way to speak"
}
```

```json
{
  "command": "say",
  "text": "Yet another way"
}
```

### Screenshot

**Take Screenshot:**
```json
{
  "command": "screenshot",
  "notify": true,
  "confirm": true,
  "response_topic": "kingkiosk/my-device/screenshot/response"
}
```

**Parameters:**
- `notify`: Show notification when screenshot is taken
- `confirm`: Send confirmation message
- Screenshots are automatically saved and can be published to Home Assistant

## Notification Commands

### Alert (Center Screen)
Display modal alerts in the center of the screen:

```json
{
  "command": "alert",
  "title": "Important Alert",
  "message": "This is an important message",
  "type": "warning",
  "duration": 5000,
  "buttons": ["OK", "Cancel"],
  "color": "#FF5722"
}
```

**Parameters:**
- `title`: Alert title (required)
- `message`: Alert message body (required)
- `type`: Alert type (`info`, `warning`, `error`, `success`)
- `duration`: Auto-dismiss duration in milliseconds
- `buttons`: Array of button labels
- `color`: Custom alert color (hex or named color)

### Notification (Corner Toast)
Display toast notifications:

```json
{
  "command": "notify",
  "title": "Notification",
  "message": "This is a notification",
  "type": "info",
  "duration": 3000,
  "position": "top-right"
}
```

**Parameters:**
- `title`: Notification title
- `message`: Notification message
- `type`: Notification type (`info`, `warning`, `error`, `success`)
- `duration`: Display duration in milliseconds
- `position`: Position on screen (`top-right`, `top-left`, `bottom-right`, `bottom-left`)

## Visual Effects

### Halo Effects
Apply glowing halo effects to the entire app or specific windows:

**Global App Halo:**
```json
{
  "command": "halo_effect",
  "enabled": true,
  "color": "#FF0000",
  "width": 20.0,
  "intensity": 0.7,
  "pulse_mode": "breathe",
  "pulse_duration": 2000,
  "fade_in_duration": 500,
  "fade_out_duration": 500,
  "confirm": true
}
```

**Window-Specific Halo:**
```json
{
  "command": "halo_effect",
  "window_id": "browser-1",
  "enabled": true,
  "color": "#00FF00",
  "width": 15.0,
  "intensity": 0.5,
  "pulse_mode": "pulse"
}
```

**Disable Halo:**
```json
{
  "command": "halo_effect",
  "enabled": false
}
```

**Parameters:**
- `enabled`: Enable/disable halo effect
- `color`: Halo color (hex, RGB, or named color)
- `width`: Halo border width in pixels
- `intensity`: Halo intensity (0.0 to 1.0)
- `pulse_mode`: Animation mode (`none`, `pulse`, `breathe`)
- `pulse_duration`: Pulse animation duration in milliseconds
- `fade_in_duration`: Fade in duration
- `fade_out_duration`: Fade out duration
- `window_id`: Apply to specific window (omit for global)
- `confirm`: Send confirmation message

**Supported Colors:**
- Hex: `#FF0000`, `#00FF00`, `#0000FF`
- Named: `red`, `green`, `blue`, `yellow`, `orange`, `purple`, `pink`, `cyan`, `white`, `black`
- RGB integers: Direct color values

## Background Control

### Set Background Image
Set a custom background image:

```json
{
  "command": "set_background",
  "type": "image",
  "image_url": "https://picsum.photos/1920/1080",
  "response_topic": "kingkiosk/my-device/background/response"
}
```

**Local File:**
```json
{
  "command": "set_background",
  "type": "image",
  "image_path": "/path/to/local/image.jpg"
}
```

### Set Background WebView
Set a website as the background:

```json
{
  "command": "set_background",
  "type": "webview",
  "web_url": "https://grafana.example.com/dashboard"
}
```

### Reset to Default Background
```json
{
  "command": "set_background",
  "type": "default"
}
```

### Get Background Status
```json
{
  "command": "get_background",
  "response_topic": "kingkiosk/my-device/background/status"
}
```

**Response format:**
```json
{
  "type": "image",
  "image_path": "https://example.com/image.jpg",
  "web_url": "",
  "timestamp": "2025-06-12T10:30:00Z"
}
```

## Widget Commands

### Clock Widget
Display analog or digital clocks:

```json
{
  "command": "open_clock",
  "title": "Office Clock",
  "window_id": "clock-1",
  "style": "analog"
}
```

### Alarmo Security Widget
Integrate with Home Assistant Alarmo:

```json
{
  "command": "alarmo_widget",
  "name": "Security Panel",
  "window_id": "alarmo-1",
  "entity": "alarm_control_panel.alarmo",
  "require_code": true,
  "code_length": 4,
  "state_topic": "alarmo/state",
  "command_topic": "alarmo/command",
  "event_topic": "alarmo/event",
  "available_modes": ["armed_home", "armed_away", "disarmed"]
}
```

**Parameters:**
- `entity`: Home Assistant entity ID
- `require_code`: Whether to require PIN code
- `code_length`: Length of PIN code
- `state_topic`: MQTT topic for state updates
- `command_topic`: MQTT topic for commands
- `event_topic`: MQTT topic for events
- `available_modes`: Array of available alarm modes

### Weather Widget
Display weather information:

```json
{
  "command": "open_weather_client",
  "name": "Weather Display",
  "window_id": "weather-1",
  "api_key": "your_openweather_api_key",
  "location": "New York, NY",
  "units": "metric",
  "language": "en",
  "show_forecast": true,
  "auto_refresh": 300
}
```

**Parameters:**
- `api_key`: OpenWeatherMap API key
- `location`: Location string or coordinates
- `units`: Temperature units (`metric`, `imperial`, `kelvin`)
- `language`: Language code for weather descriptions
- `show_forecast`: Show forecast data
- `auto_refresh`: Auto-refresh interval in seconds

### Calendar Widget
Display and manage calendar events:

```json
{
  "command": "calendar",
  "action": "show",
  "name": "Office Calendar",
  "window_id": "calendar-1",
  "source": "google",
  "calendar_id": "primary"
}
```

**Actions:**
- `show`: Display calendar
- `add_event`: Add calendar event
- `refresh`: Refresh calendar data

## Automation & Batch Scripts

### Batch Script Execution
Execute multiple commands in sequence:

```json
{
  "command": "batch",
  "commands": [
    {
      "command": "set_brightness",
      "value": "0.5"
    },
    {
      "command": "wait",
      "seconds": 2
    },
    {
      "command": "play_media",
      "type": "video",
      "url": "https://example.com/video.mp4",
      "style": "fullscreen"
    },
    {
      "command": "notify",
      "title": "Batch Complete",
      "message": "All commands executed successfully"
    }
  ],
  "response_topic": "kingkiosk/my-device/batch/response"
}
```

**Alternative format (commands array at root):**
```json
{
  "commands": [
    {"command": "mute"},
    {"command": "wait", "seconds": 1},
    {"command": "unmute"}
  ]
}
```

### Batch Control Commands

**Check Batch Status:**
```json
{
  "command": "batch_status",
  "response_topic": "kingkiosk/my-device/batch/status"
}
```

**Kill Running Batch:**
```json
{
  "command": "kill_batch_script"
}
```

**Wait Command (for batch scripts):**
```json
{
  "command": "wait",
  "seconds": 5.5
}
```

**Batch Status Response:**
```json
{
  "status": "running|idle|killed",
  "progress": 3,
  "total": 10,
  "batch_id": "1699123456789",
  "current_command": "play_media"
}
```

### Batch Script Features
- **Progress Tracking**: Real-time progress updates
- **Error Handling**: Continue or stop on errors
- **Kill Switch**: Emergency stop capability
- **Wait Commands**: Built-in delays
- **Response Topics**: Status and completion notifications
- **Timeout Protection**: Automatic cleanup
- **Nested Commands**: Support for complex command structures

## Settings & Provisioning

### Remote Provisioning
Configure device settings remotely via MQTT:

```json
{
  "command": "provision",
  "settings": {
    "device_name": "Kitchen Display",
    "mqtt_broker": "192.168.1.100",
    "mqtt_port": 1883,
    "mqtt_username": "kiosk_user",
    "mqtt_password": "secure_password",
    "ha_discovery": true,
    "volume_level": 0.7,
    "brightness_level": 0.8,
    "enable_location": true,
    "auto_brightness": false,
    "screen_timeout": 300
  },
  "response_topic": "kingkiosk/my-device/provision/response"
}
```

**Supported Settings:**

**Theme & Display:**
- `darkmode` / `dark_mode` / `isdarkmode`: Enable dark mode (boolean)
- `show_system_info`: Show system information (boolean)

**Kiosk Mode:**
- `kioskmode` / `kiosk_mode`: Enable kiosk mode (boolean)
- `starturl` / `kiosk_start_url`: Default URL for kiosk mode (string)

**MQTT Configuration:**
- `mqtt_enabled` / `mqttenabled`: Enable MQTT connection (boolean)
- `mqtt_broker_url` / `brokerurl`: MQTT broker hostname/IP (string)
- `mqtt_broker_port` / `brokerport`: MQTT broker port (integer, 1-65535)
- `mqtt_username`: MQTT authentication username (string)
- `mqtt_password`: MQTT authentication password (string)
- `mqtt_ha_discovery` / `hadiscovery`: Enable Home Assistant discovery (boolean)

**Device Configuration:**
- `device_name`: Device display name (string, auto-sanitized)

**SIP Communication:**
- `sip_enabled` / `sipenabled`: Enable SIP communication (boolean)
- `sip_server_host` / `sipserverhost`: SIP server hostname/IP (string)
- `sip_protocol` / `sipprotocol`: SIP protocol - 'ws' or 'wss' (string)

**AI Integration:**
- `ai_enabled` / `aienabled`: Enable AI features (boolean)
- `ai_provider_host` / `aiproviderhost`: AI provider host URL (string)

**Person Detection:**
- `person_detection_enabled` / `persondetection`: Enable person detection (boolean)

**Wyoming Satellite:**
- `wyoming_enabled` / `wyomingenabled`: Enable Wyoming satellite (boolean)  
- `wyoming_host` / `wyominghost`: Wyoming server hostname/IP (string)
- `wyoming_port` / `wyomingport`: Wyoming server port (integer, 1-65535)

**Media Device Selection:**
- `selected_audio_input` / `selectedaudioinput`: Selected audio input device (string)
- `selected_video_input` / `selectedvideoinput`: Selected video input device (string)
- `selected_audio_output` / `selectedaudiooutput`: Selected audio output device (string)

**System URLs:**
- `websocket_url` / `websocketurl`: WebSocket server URL (string)
- `media_server_url` / `mediaserverurl`: Media server URL (string)

**Security:**
- `settings_pin` / `settingspin`: Settings access PIN (string)

**System Storage:**
- `latest_screenshot` / `latestscreenshot`: Latest screenshot path (string)

**Provisioning Response:**
```json
{
  "success": true,
  "message": "All 8 settings applied successfully",
  "device_name": "Kitchen Display",
  "applied_settings": [
    "device_name",
    "mqtt_broker",
    "mqtt_port",
    "ha_discovery"
  ],
  "failed_settings": {},
  "timestamp": "2025-06-12T10:30:00Z"
}
```

### Complete Device Provisioning Example

**Full Configuration:**
```json
{
  "command": "provision",
  "settings": {
    "device_name": "Reception Kiosk",
    "darkmode": true,
    "kioskmode": true,
    "starturl": "https://company.com/reception",
    "mqtt_enabled": true,
    "mqtt_broker_url": "192.168.1.100",
    "mqtt_broker_port": 1883,
    "mqtt_username": "kiosk_user",
    "mqtt_password": "secure_pass",
    "mqtt_ha_discovery": true,
    "sip_enabled": true,
    "sip_server_host": "sip.company.com",
    "sip_protocol": "wss",
    "ai_enabled": true,
    "ai_provider_host": "http://192.168.1.200:11434",
    "person_detection_enabled": true,
    "wyoming_enabled": false,
    "show_system_info": false,
    "settings_pin": "1234"
  },
  "response_topic": "kingkiosk/reception-kiosk/provision/response"
}
```

**Single Setting Update:**
```json
{
  "command": "provision",
  "person_detection_enabled": true
}
```

**Multiple Settings Update:**
```json
{
  "command": "provision",
  "darkmode": false,
  "starturl": "https://new-site.com",
  "ai_enabled": true
}
```

### Pull Current Configuration (get_config)
Remotely retrieve all current device settings as a JSON object via MQTT.

**Request:**
```json
{
  "command": "get_config",
  "response_topic": "kingkiosk/{device}/config/response"
}
```

- `response_topic` (optional): Where the config will be published. If omitted, defaults to `kingkiosk/{device}/config/response`.

**Response Example:**
```json
{
  "command": "get_config",
  "status": "success",
  "device_name": "reception-kiosk",
  "config": {
    "isDarkMode": true,
    "kioskMode": true,
    "showSystemInfo": false,
    "kioskStartUrl": "https://company.com/reception",
    "personDetectionEnabled": true,
    "mqttEnabled": true,
    "mqttBrokerUrl": "192.168.1.100",
    "mqttBrokerPort": 1883,
    "mqttUsername": "kiosk_user",
    "mqttPassword": "secure_pass",
    "deviceName": "reception-kiosk",
    "mqttHaDiscovery": true,
    "sipEnabled": true,
    "sipServerHost": "sip.company.com",
    "sipProtocol": "wss",
    "selectedAudioInput": "default",
    "selectedVideoInput": "default",
    "selectedAudioOutput": "default",
    "wyomingHost": "",
    "wyomingPort": 0,
    "wyomingEnabled": false,
    "aiProviderHost": "http://192.168.1.200:11434",
    "aiEnabled": true,
    "latestScreenshot": "",
    "websocketUrl": "wss://echo.websocket.org",
    "mediaServerUrl": "https://example.com"
  },
  "timestamp": "2025-06-12T10:30:00Z"
}
```

You can use this to remotely audit, backup, or synchronize device settings.

## Monitoring & Diagnostics

### Sensor Data
The service automatically publishes sensor data every 30 seconds:

**Published Sensors:**
- `kingkiosk/{device}/battery` - Battery level (0-100)
- `kingkiosk/{device}/battery_status` - Battery status (charging/discharging/full)
- `kingkiosk/{device}/cpu_usage` - CPU usage percentage
- `kingkiosk/{device}/memory_usage` - Memory usage percentage
- `kingkiosk/{device}/platform` - Operating system
- `kingkiosk/{device}/latitude` - GPS latitude
- `kingkiosk/{device}/longitude` - GPS longitude
- `kingkiosk/{device}/altitude` - GPS altitude
- `kingkiosk/{device}/location_accuracy` - GPS accuracy
- `kingkiosk/{device}/location_status` - Location service status

### Person Detection
Control person detection features:

```json
{
  "command": "person_detection",
  "action": "enable|disable|toggle|status"
}
```

**Actions:**
- `enable`: Turn on person detection
- `disable`: Turn off person detection
- `toggle`: Switch detection state
- `status`: Get current status

### Force Sensor Update
Trigger immediate sensor data publication:

```json
{
  "command": "force_sensor_update"
}
```

### Diagnostics Topics
Additional diagnostic information is published to:
- `kiosk/{device}/diagnostics/windows` - Window information
- `kingkiosk/{device}/screenshot` - Screenshot data (if enabled)

## Home Assistant Integration

### Auto-Discovery
The service supports Home Assistant MQTT Discovery for automatic device integration.

**Enable Discovery:**
```json
{
  "command": "provision",
  "ha_discovery": true
}
```

**Discovery Topics:**
- `homeassistant/sensor/{device}_battery/config`
- `homeassistant/sensor/{device}_cpu_usage/config`
- `homeassistant/sensor/{device}_memory_usage/config`
- `homeassistant/camera/{device}_screenshot/config`

### Device Information
Each discovered entity includes device information:
```json
{
  "device": {
    "identifiers": ["kiosk_my_device"],
    "name": "My Kiosk Device",
    "model": "Flutter GetX Kiosk",
    "manufacturer": "KingKiosk"
  }
}
```

### Entity Categories
- **Diagnostic**: System sensors (CPU, memory, battery)
- **Config**: Settings and configuration
- **Camera**: Screenshot functionality

### Availability
All entities report availability based on device online/offline status:
- **Available**: `online`
- **Unavailable**: `offline`

## Error Handling

### Command Validation
All commands are validated before execution:
- **JSON Format**: Commands must be valid JSON
- **Required Fields**: Missing required parameters are reported
- **Type Validation**: Parameter types are checked
- **Range Validation**: Numeric values are validated against acceptable ranges

### Response Topics
Most commands support optional response topics for status feedback:

```json
{
  "command": "any_command",
  "response_topic": "kingkiosk/my-device/responses/custom"
}
```

### Error Messages
Error responses include detailed information:
```json
{
  "success": false,
  "error": "Invalid parameter value",
  "details": "Volume must be between 0.0 and 1.0",
  "command": "set_volume",
  "timestamp": "2025-06-12T10:30:00Z"
}
```

### Debugging
Enable debug logging by:
1. Setting log level in app settings
2. Using force sensor updates for testing
3. Monitoring connection status topics
4. Checking Home Assistant discovery logs

### Connection Recovery
The service includes automatic recovery features:
- **Auto-reconnect**: Automatic broker reconnection
- **Resubscribe**: Automatic topic resubscription
- **Status Publishing**: Online/offline status management
- **Keep-alive**: Connection health monitoring

### Common Issues

**Device Not Responding:**
- Check MQTT broker connection
- Verify device name and topics
- Confirm device is online (`kingkiosk/{device}/status` = `online`)

**Commands Not Executing:**
- Validate JSON format
- Check required parameters
- Verify command spelling and case
- Monitor response topics for error messages

**Home Assistant Integration:**
- Ensure `ha_discovery` is enabled
- Check discovery topic permissions
- Verify MQTT integration in Home Assistant
- Review Home Assistant MQTT logs

**Media Playback Issues:**
- Use `reset_media` command for black screens
- Check URL accessibility
- Verify media format support
- Test with different `hardware_accel` settings

### Support and Troubleshooting

**Debug Commands:**
```json
{"command": "force_sensor_update"}
{"command": "batch_status"}
{"command": "get_background"}
{"command": "screenshot", "notify": true}
```

**Health Check Script:**
```json
{
  "commands": [
    {"command": "force_sensor_update"},
    {"command": "get_brightness"},
    {"command": "batch_status"},
    {"command": "screenshot", "notify": true}
  ]
}
```

This comprehensive reference covers all MQTT functionality in the KingKiosk service. For additional support, monitor the device status topics and use response topics to debug command execution.
