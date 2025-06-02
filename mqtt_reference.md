<!-- filepath: /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/mqtt_reference.md -->
# KingKiosk MQTT Reference Guide

This document provides a comprehensive reference of MQTT topics and message formats used for controlling KingKiosk through MQTT. The information is based on the actual implementation in the codebase, ensuring accurate command formats and parameters.

## Table of Contents
- [General MQTT Structure](#general-mqtt-structure)
- [Command Topics](#command-topics)
- [Window Management](#window-management)
- [Tile Types](#tile-types)
- [WebView Commands](#webview-commands)
- [Media Commands](#media-commands)
- [YouTube Commands](#youtube-commands)
- [Audio Playback](#audio-playback)
- [Image Display](#image-display)
- [Notification Commands](#notification-commands)
- [System Controls](#system-controls)
- [Halo Effect](#halo-effect)
- [Screenshot](#screenshot)
- [Media Recovery](#media-recovery)
- [Command Relationships and Cross-References](#command-relationships-and-cross-references)
- [Home Assistant Integration](#home-assistant-integration)
- [Testing and Troubleshooting](#testing-and-troubleshooting)
- [Conclusion](#conclusion)

## General MQTT Structure

### Base Topic Format
```
kingkiosk/{deviceName}/command    # For single commands
kingkiosk/{deviceName}/commands   # For single or batch commands
```

- **deviceName**: Unique identifier for the kiosk device (set in the app settings)
- The device name is sanitized automatically (spaces and special characters replaced with underscores)
- If not set, a default device name is generated in the format `device-{random number}`

### Window Command Topic Format
```
kiosk/{deviceName}/window/{windowId}/command
```

- **deviceName**: Unique identifier for the kiosk device
- **windowId**: Unique identifier for a specific window on the kiosk (usually auto-generated when a window is created)

### Message Format
All commands use JSON format:

```json
{
  "command": "command_name",
  "param1": "value1",
  "param2": "value2"
}
```

### Batch Commands
You can send multiple commands at once using the batch format:

```json
{
  "command": "batch",
  "commands": [
    {
      "command": "command1",
      "param1": "value1"
    },
    {
      "command": "command2",
      "param2": "value2"
    }
  ]
}
```

Alternative batch format (without the "command":"batch" wrapper):

```json
{
  "commands": [
    {
      "command": "command1",
      "param1": "value1"
    },
    {
      "command": "command2",
      "param2": "value2"
    }
  ]
}
```

Batch commands are processed sequentially in the order they appear in the array.

## Command Topics

### Main Topics
The KingKiosk app listens to two main command topics:

- `kingkiosk/{deviceName}/command` - For single commands
- `kingkiosk/{deviceName}/commands` - For single or batch commands (identical functionality)

### Window-Specific Command Topics
For sending commands to specific windows:

- `kiosk/{deviceName}/window/{windowId}/command` - For controlling a specific window

### Response Topics
The app publishes responses and status updates to:

- `kingkiosk/{deviceName}/status` - Device online/offline status (payload: "online" or "offline")
- `kingkiosk/{deviceName}/{sensorName}` - Sensor values (battery, cpu_usage, memory_usage, platform)
- `kingkiosk/{deviceName}/status/media_reset` - Media reset status (JSON with details)
- `kingkiosk/{deviceName}/status/media_health` - Media health status (JSON with details)
- `kingkiosk/{deviceName}/screenshot/status` - Screenshot confirmation (JSON with details)
- `kingkiosk/{deviceName}/halo_effect/status` - Halo effect confirmation (JSON with details)

### Device Status Reporting
The app automatically publishes its status:
- When connecting to MQTT broker: `online` message sent to status topic 
- When disconnecting from MQTT broker: `offline` message sent to status topic
- Every 30-60 seconds: sensor values updated (battery, CPU, memory, etc.)

This behavior can be used for monitoring the device and automating actions based on its status.

## Window Management

### Open Browser Window
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "open_browser",
  "url": "https://example.com",
  "title": "Example Website",
  "window_id": "browser-123"
}
```
- **url**: Required. The URL to load in the browser.
- **title**: Optional. The title for the window (defaults to "MQTT Web").
- **window_id**: Optional. Custom ID for the window (auto-generated if not provided).

### Open YouTube Video
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "youtube",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "YouTube Video",
  "window_id": "youtube-123"
}
```
- **url**: Required. YouTube video URL.
- **title**: Optional. The title for the window (defaults to "YouTube").
- **window_id**: Optional. Custom ID for the window (auto-generated if not provided).

### Close Window
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "close_window",
  "window_id": "window-123"
}
```
- **window_id**: Required. The ID of the window to close.

### Maximize Window
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "maximize_window",
  "window_id": "window-123"
}
```
- **window_id**: Required. The ID of the window to maximize.

### Minimize Window
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "minimize_window",
  "window_id": "window-123"
}
```
- **window_id**: Required. The ID of the window to minimize.

### Open PDF Document
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "open_pdf",
  "url": "https://example.com/document.pdf",
  "title": "PDF Document",
  "window_id": "pdf-123"
}
```
- **url**: Required. URL to the PDF document.
- **title**: Optional. The title for the window (defaults to "PDF Document").
- **window_id**: Optional. Custom ID for the window (auto-generated if not provided).

## WebView Commands

### Refresh Web Page
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "refresh",
  "window_id": "web-123"
}
```
- **window_id**: Required. The ID of the web window to refresh.

### Restart WebView
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "restart",
  "window_id": "web-123"
}
```
- **window_id**: Required. The ID of the web window to restart.

### Execute JavaScript
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "evaljs",
  "window_id": "web-123",
  "code": "document.getElementById('username').value = 'admin';"
}
```
- **window_id**: Required. The ID of the web window where JavaScript should be executed.
- **code**: Required. The JavaScript code to execute.

### Load URL
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "loadurl",
  "window_id": "web-123",
  "url": "https://example.com/newpage"
}
```
- **window_id**: Required. The ID of the web window.
- **url**: Required. The new URL to load.

## Media Commands

### Play Media
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "loop": true,
  "style": "background",
  "window_id": "audio-123",
  "hardware_accel": true
}
```
- **type**: Media type: "audio", "video", or "image" (automatically inferred from URL extension if not provided)
- **url**: Required. URL of the media to play
- **loop**: Optional. Boolean flag for looping playback (default: false)
- **style**: Optional. Playback style: "background", "window", "fullscreen" (defaults: audio="background", video="window", image="window")
- **window_id**: Optional. Custom ID for the media window (auto-generated if not provided)
- **title**: Optional. Title for the media window
- **hardware_accel**: Optional. Boolean flag to enable or disable hardware acceleration for this specific media (overrides system detection)

### Media Type Detection
If the `type` parameter is omitted, the system will try to determine the media type based on the URL extension:
- **audio**: .mp3, .wav
- **video**: .mp4, .webm
- **image**: .jpg, .jpeg, .png, .gif, .webp, .bmp

### Hardware Acceleration Control
KingKiosk provides hardware acceleration control for media playback via MQTT. This is useful for devices where hardware acceleration might cause issues with certain media files.

The system normally auto-detects hardware compatibility, but you can override this behavior:

- Use the `hardware_accel` parameter in the `play_media` command to enable or disable hardware acceleration for a specific media item
- When specified, this setting takes precedence over the system's auto-detection
- The override only applies to the current media playback request
- After playback ends, the system reverts to its default hardware acceleration detection

Example usage:
```json
{
  "command": "play_media",
  "url": "https://example.com/video.mp4",
  "hardware_accel": false
}
```

This is particularly useful for:
- Troubleshooting media playback issues
- Playing media that has known compatibility issues with hardware acceleration
- Testing performance differences between hardware and software decoding

### Play Media in Window
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "loop": false,
  "style": "window",
  "title": "Video Player",
  "window_id": "video-123",
  "hardware_accel": false
}
```

### Play Fullscreen Media
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "style": "fullscreen",
  "loop": true,
  "hardware_accel": true
}
```

### Window-Specific Media Controls
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play",
  "window_id": "media-123"
}
```
- **command**: Required. Action to perform: "play", "pause", or "stop"
- **window_id**: Required. ID of the media window to control

**Examples**:
```json
{
  "command": "pause",
  "window_id": "media-123"
}
```

```json
{
  "command": "stop",
  "window_id": "media-123"
}
```

```json
{
  "command": "seek",
  "window_id": "media-123",
  "position": 120
}
```
- **position**: Required for seek command. Position in seconds to seek to

### Background Audio Controls
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_audio"
}
```
- **command**: Required. Action to perform: "play_audio", "pause_audio", "stop_audio", or "seek_audio"
- These commands specifically target the background audio player

**Examples**:
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

```json
{
  "command": "seek_audio",
  "position": 30.5
}
```
- **position**: Required for seek_audio command. Position in seconds to seek to

### Volume Control
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "set_volume",
  "value": "0.75"
}
```
- **value**: Required. Volume level from 0.0 to 1.0

### Mute/Unmute
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "mute"
}
```
Or:
```json
{
  "command": "unmute"
}
```

## YouTube Commands

KingKiosk provides specialized support for YouTube videos with enhanced controls and features beyond standard media playback.

### Open YouTube Video
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "youtube",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "YouTube Video",
  "window_id": "youtube-123",
  "autoplay": true,
  "show_controls": true,
  "show_info": true
}
```
- **url**: Required. YouTube video URL
  - Supports various formats including:
    - Standard watch URLs: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
    - Short URLs: `https://youtu.be/dQw4w9WgXcQ`
    - Embed URLs: `https://www.youtube.com/embed/dQw4w9WgXcQ`
  - The video ID will be extracted automatically from any valid YouTube URL
- **title**: Optional. The title for the window (defaults to "YouTube")
- **window_id**: Optional. Custom ID for the window (auto-generated if not provided)
- **autoplay**: Optional. Whether to start playing automatically (default: true)
- **show_controls**: Optional. Whether to show YouTube player controls (default: true)
- **show_info**: Optional. Whether to show video title and info (default: true)

### Control YouTube Playback
Controls for YouTube windows use the same format as media controls:

**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play",
  "window_id": "youtube-123"
}
```
- **command**: Required. Action to perform:
  - "play": Start or resume playback
  - "pause": Pause playback
  - "stop": Stop playback
  - "close": Close the YouTube window
- **window_id**: Required. ID of the YouTube window to control

### Advanced YouTube Control Example
You can control multiple aspects of YouTube playback in a single command:

**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "set_volume",
      "value": "0.7"
    },
    {
      "command": "play",
      "window_id": "youtube-123"
    }
  ]
}
```
- Use batch commands to control both the YouTube player and system settings at once
- You can combine YouTube controls with other commands like volume, brightness, etc.

## Notification Commands

Notifications can be used to display important information to the user without interrupting their current workflow. They appear as banners or toast messages and can have different styles, durations, and positions.

### Send Notification
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "notify",
  "title": "System Update",
  "message": "A new system update is available",
  "type": "info",
  "duration": 5000,
  "position": "top-right",
  "sound": true,
  "priority": "normal",
  "is_html": false,
  "thumbnail": "https://example.com/image.png"
}
```
- **title**: Required. The notification title
- **message**: Required. The notification message content
- **type**: Optional. Notification type (default: "info")
  - "info": Blue information notification
  - "warning": Yellow/orange warning notification
  - "error": Red error notification
  - "success": Green success notification
- **duration**: Optional. Display duration in milliseconds, 0 for persistent (default: 5000)
- **position**: Optional. Display position (default: "top-right")
  - "top-right": Upper right corner
  - "top-left": Upper left corner
  - "bottom-right": Lower right corner
  - "bottom-left": Lower left corner
  - "center": Center of screen
- **sound**: Optional. Whether to play a notification sound (default: true)
- **priority**: Optional. Notification priority (default: "normal")
  - "low": Less visually prominent
  - "normal": Standard visibility
  - "high": More visually prominent
- **is_html**: Optional. Whether the message contains HTML markup (default: false)
- **thumbnail**: Optional. URL to an image to display in the notification

### Send HTML Notification
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "notify",
  "title": "HTML Content",
  "message": "<b>Important</b> message with <span style='color:red'>formatted</span> text",
  "is_html": true,
  "duration": 10000
}
```
- Use the `is_html` parameter to enable HTML formatting in the message
- Supports basic HTML tags: `<b>`, `<i>`, `<u>`, `<span>`, `<div>`, etc.
- Can include inline CSS for styling

### Send Notification with Thumbnail
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "notify",
  "title": "New Message",
  "message": "You've received a new message from Alice",
  "thumbnail": "https://example.com/profile.jpg",
  "position": "bottom-right"
}
```
- The `thumbnail` parameter accepts a URL to an image
- The image will be displayed alongside the notification text
- Useful for showing user avatars, product thumbnails, or contextual images

### Send Alert (Center-Screen Dialog)
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "alert",
  "title": "System Alert",
  "message": "Critical system update required",
  "type": "info",
  "position": "center",
  "auto_dismiss_seconds": 5,
  "sound": true,
  "is_html": false,
  "show_border": true,
  "border_color": "#3498db",
  "thumbnail": "https://example.com/warning-icon.png"
}
```
- **title**: Required. The alert dialog title
- **message**: Required. The alert message content
- **type**: Optional. Alert type affects styling and default border color (default: "info")
  - "info": Blue information alert
  - "warning": Orange warning alert  
  - "error": Red error alert
  - "success": Green success alert
- **position**: Optional. Alert position on screen (default: "center")
  - "center": Center of screen (default)
  - "top-left": Upper left corner
  - "top-center": Top center
  - "top-right": Upper right corner
  - "center-left": Center left
  - "center-right": Center right
  - "bottom-left": Lower left corner
  - "bottom-center": Bottom center
  - "bottom-right": Lower right corner
- **show_border**: Optional. Whether to show colored border (default: true)
- **border_color**: Optional. Custom border color in hex format (#RRGGBB or #AARRGGBB)
- **auto_dismiss_seconds**: Optional. Auto-dismiss duration in seconds (1-300), omit for manual dismiss only (default: manual)
- **sound**: Optional. Whether to play an alert sound (default: true)
- **is_html**: Optional. Whether the message contains HTML markup (default: false)
- **thumbnail**: Optional. URL/path to an image to display in the alert dialog

**Position Examples:**
```json
// Top-right corner alert with blue border
{
  "command": "alert",
  "title": "Network Status",
  "message": "WiFi connection restored",
  "type": "success",
  "position": "top-right",
  "border_color": "#2ecc71"
}

// Bottom-left corner alert without border
{
  "command": "alert",
  "title": "Low Battery",
  "message": "Device battery is running low",
  "type": "warning", 
  "position": "bottom-left",
  "show_border": false
}

// Custom colored border alert
{
  "command": "alert",
  "title": "Custom Alert",
  "message": "Alert with purple border",
  "position": "center",
  "border_color": "#9b59b6"
}

// Auto-dismiss alert with countdown
{
  "command": "alert",
  "title": "Temporary Alert",
  "message": "This alert will automatically dismiss in 5 seconds",
  "type": "info",
  "position": "top-center",
  "auto_dismiss_seconds": 5
}

// Quick notification-style alert
{
  "command": "alert",
  "title": "Quick Update", 
  "message": "System updated successfully",
  "type": "success",
  "position": "bottom-right",
  "auto_dismiss_seconds": 3,
  "show_border": false
}
```

**Differences from regular notifications:**
- Alerts appear as modal dialogs in the center of the screen
- Alerts require user interaction to dismiss (unless duration is set)
- Alerts are more prominent and interrupt the user's current workflow
- Alerts support the same HTML formatting and thumbnail features as notifications
- Alerts reuse the sophisticated notification system infrastructure
- **NEW**: Alerts can be positioned anywhere on the screen using the `position` parameter

**Positioning Notes:**
- If no `position` is specified, alerts default to center-screen (existing behavior)
- Positioned alerts maintain the same modal behavior and styling
- All alert features (HTML, thumbnails, sounds, etc.) work with any position
- Position names are case-insensitive ("Center", "TOP-LEFT", "bottom_right" all work)
- Invalid position values will fallback to center positioning

## System Controls

### Set Volume
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "set_volume",
  "value": "0.75"
}
```
- **value**: Required. Volume level from 0.0 to 1.0

### Mute/Unmute
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "mute"
}
```
Or:
```json
{
  "command": "unmute"
}
```

### Set Brightness
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "set_brightness",
  "value": "0.8"
}
```
- **value**: Required. Brightness level from 0.0 to 1.0

### Get Brightness
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "get_brightness",
  "response_topic": "kingkiosk/my-device/brightness_response"
}
```
- **response_topic**: Optional. Topic where the brightness value will be published

### Restore Brightness
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "restore_brightness"
}
```

### Reset Media System
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "reset_media",
  "force": true,
  "test": false
}
```
- **force**: Optional. Force reset even if a recent reset was performed (default: false)
- **test**: Optional. Run a health check test without performing a reset (default: false)
- **Note**: Background audio is automatically preserved during media reset operations. If background audio is playing when reset_media is called, it will be automatically restored after the reset is complete.

### Remote Device Provisioning
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "provision",
  "settings": {
    "isDarkMode": true,
    "kioskMode": false,
    "showSystemInfo": true,
    "mqttEnabled": true,
    "mqttBrokerUrl": "mqtt.example.com",
    "mqttBrokerPort": 1883,
    "mqttUsername": "kiosk_user",
    "mqttPassword": "secure_password",
    "deviceName": "lobby-kiosk-01",
    "settingsPin": "1234"
  },
  "response_topic": "kingkiosk/my-device/provision_response"
}
```

The provision command allows remote configuration of all application settings via MQTT, enabling remote device setup and management.

**Parameters:**
- **settings**: Required. Object containing the settings to apply
- **response_topic**: Optional. Topic where the provision response will be published

**Supported Settings:**

**Theme Settings:**
- **isDarkMode**: Boolean. Enable or disable dark mode theme

**App Settings:**
- **kioskMode**: Boolean. Enable or disable kiosk mode (hides system UI)
- **showSystemInfo**: Boolean. Show or hide system information overlay
- **kioskStartUrl**: String. Default URL to load when kiosk mode starts

**MQTT Settings:**
- **mqttEnabled**: Boolean. Enable or disable MQTT functionality
- **mqttBrokerUrl**: String. MQTT broker hostname or IP address
- **mqttBrokerPort**: Integer. MQTT broker port (typically 1883 or 8883)
- **mqttUsername**: String. MQTT authentication username
- **mqttPassword**: String. MQTT authentication password
- **deviceName**: String. Unique device identifier for MQTT topics
- **mqttHaDiscovery**: Boolean. Enable Home Assistant auto-discovery

**SIP Settings:**
- **sipEnabled**: Boolean. Enable or disable SIP functionality
- **sipServerHost**: String. SIP server hostname or IP address
- **sipProtocol**: String. SIP protocol ("UDP", "TCP", or "TLS")

**AI Settings:**
- **aiEnabled**: Boolean. Enable or disable AI features
- **aiProviderHost**: String. AI provider hostname or endpoint

**Security Settings:**
- **settingsPin**: String. PIN code for accessing device settings

**Flexible Key Formats:**
Settings keys support both camelCase and snake_case formats:
```json
{
  "command": "provision",
  "settings": {
    "is_dark_mode": true,        // snake_case
    "isDarkMode": true,          // camelCase
    "mqtt_broker_url": "...",    // snake_case
    "mqttBrokerUrl": "..."       // camelCase
  }
}
```

**Provision Response:**
When a response topic is specified, a detailed response will be published:

**Topic**: `{response_topic}` (as specified in the command)  
**Payload**:
```json
{
  "status": "success",
  "timestamp": "2023-07-15T12:34:56.789Z",
  "device_name": "lobby-kiosk-01",
  "applied_settings": [
    "isDarkMode",
    "kioskMode",
    "mqttBrokerUrl"
  ],
  "failed_settings": [
    {
      "key": "invalidSetting",
      "error": "Unknown setting key"
    }
  ],
  "total_requested": 4,
  "total_applied": 3,
  "total_failed": 1
}
```

**Response Status Values:**
- **success**: All settings were applied successfully
- **partial**: Some settings were applied, others failed
- **error**: No settings could be applied (usually due to malformed request)

**Error Handling:**
- Invalid setting keys are ignored and reported in the response
- Type conversion is attempted for boolean and integer values
- String values like "true"/"false" are converted to booleans
- String numbers are converted to integers where appropriate
- Device name is automatically sanitized (spaces/special chars become underscores)
- A visual notification is shown on the device when provisioning completes

**Security Considerations:**
- The provision command can change sensitive settings like MQTT credentials
- Consider using secure MQTT connections (TLS) when sending provision commands
- The settings PIN can be changed via provisioning, use with caution
- All settings are validated before being applied

## Halo Effect

The Halo Effect creates a colored border around either the entire screen or a specific window. This feature is useful for drawing attention to important content or indicating system states.

### Enable Halo Effect
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "halo_effect",
  "color": "#FF0000",
  "width": 10,
  "intensity": 0.8,
  "enabled": true,
  "pulse_mode": "gentle",
  "pulse_duration": 2000,
  "fade_in_duration": 800,
  "fade_out_duration": 1000,
  "confirm": true
}
```
- **color**: Optional. Halo color in hex format (default: "#FF0000")
  - Supports standard hex formats: "#RGB", "#RRGGBB", "#RGBA", "#RRGGBBAA"
  - Also supports named colors: "red", "green", "blue", etc.
  - Invalid color values will fallback to red
- **width**: Optional. Halo width in pixels (default: 10, range: 1-200)
- **intensity**: Optional. Halo intensity (default: 0.8, range: 0.1-1.0)
- **enabled**: Optional. Whether to enable or disable the halo (default: true)
- **pulse_mode**: Optional. Animation mode (default: "none")
  - "none": Static halo with no animation
  - "gentle": Slow, subtle pulsing animation
  - "moderate": Medium-speed pulsing animation
  - "alert": Fast, attention-grabbing pulsing animation
- **pulse_duration**: Optional. Pulse cycle duration in milliseconds (default: 2000, range: 100-10000)
- **fade_in_duration**: Optional. Fade-in duration in milliseconds (default: 800, range: 50-5000)
- **fade_out_duration**: Optional. Fade-out duration in milliseconds (default: 1000, range: 50-5000)
- **confirm**: Optional. Request a confirmation message (default: false)

### Disable Halo Effect
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "halo_effect",
  "enabled": false
}
```

### Window-Specific Halo Effect
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "halo_effect",
  "window_id": "browser-123",
  "color": "#00FF00",
  "enabled": true,
  "pulse_mode": "alert",
  "pulse_duration": 1500
}
```
- **window_id**: Required. ID of the window to apply the halo effect to
- All other parameters are the same as for global halo effect
- Window-specific halos override the global halo effect for that window
- Multiple windows can have different halo effects simultaneously

### Halo Effect Confirmation
When `confirm: true` is specified, a confirmation message will be sent to:

**Topic**: `kingkiosk/{deviceName}/halo_effect/status`  
**Payload**:
```json
{
  "status": "success",
  "timestamp": "2023-07-15T12:34:56.789Z",
  "color": "#FF0000",
  "pulse_mode": "gentle",
  "window_id": "browser-123"  // Only included for window-specific halos
}
```

## Screenshot

### Take Screenshot
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "screenshot",
  "notify": true,
  "confirm": true
}
```
- **notify**: Optional. Show a notification when the screenshot is taken (default: false)
- **confirm**: Optional. Send a confirmation message when the screenshot is completed (default: false)

### Screenshot Confirmation
When `confirm: true` is specified, a confirmation message will be sent to:

**Topic**: `kingkiosk/{deviceName}/screenshot/status`  
**Payload**:
```json
{
  "status": "success",
  "timestamp": "2023-07-15T12:34:56.789Z",
  "path": "/path/to/screenshot.png"
}
```

## Media Recovery

The KingKiosk app includes robust media recovery features to handle situations where media playback encounters issues such as black screens, frozen media, or audio playback problems.

### Automated Health Checks
The app automatically performs periodic health checks on media players. By default, these checks occur every 60 seconds. If issues are detected, the app will attempt self-recovery steps before resorting to a full media reset.

### Media Health Check (Test Only)
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "reset_media",
  "test": true
}
```
- **test**: Set to true to perform a health check without resetting media resources
- Use this to check the current health status of media players without disrupting playback

### Force Media Reset
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "reset_media",
  "force": true
}
```
- **force**: Set to true to force a reset even if a recent reset was performed
- This performs a complete reset of all media resources including:
  - Stopping all audio/video playback
  - Closing all media tiles
  - Reinitializing the MediaKit framework
  - Releasing hardware resources
- **Note**: Background audio is preserved during media reset operations. If background audio is playing when reset_media is called, its state is captured before the reset and restored afterward.

### Media Reset Status
When a media reset is performed, the app will publish status information to:
**Topic**: `kingkiosk/{deviceName}/status/media_reset`  
**Payload**:
```json
{
  "success": true,
  "timestamp": "2023-07-15T12:34:56.789Z",
  "resetCount": 3,
  "forced": true,
  "audioUrl": "https://example.com/audio.mp3",
  "audioRestored": true
}
```
- **success**: Whether the reset was successful
- **timestamp**: When the reset was performed
- **resetCount**: How many resets have been performed since app start
- **forced**: Whether this was a forced reset
- **audioUrl**: The URL of the background audio that was playing (if any)
- **audioRestored**: Whether background audio was successfully restored

### Media Health Status
When a health check is performed with `test: true`, the app will publish health information to:
**Topic**: `kingkiosk/{deviceName}/status/media_health`  
**Payload** (example):
```json
{
  "isHealthy": true,
  "lastCheckTime": "2023-07-15T12:34:56.789Z",
  "checkIntervalSeconds": 60,
  "consecutiveFailures": 0,
  "recoveryAttemptCount": 2,
  "currentMedia": "https://example.com/video.mp4",
  "isPlaying": true,
  "mediaType": "video",
  "backgroundAudio": {
    "url": "https://example.com/audio.mp3",
    "isPlaying": true,
    "isLooping": true
  }
}
```
- The status now includes background audio information if it's playing

### Home Assistant Integration
If Home Assistant discovery is enabled, screenshots will be automatically published as a camera entity to Home Assistant under:

**Entity ID**: `camera.{deviceName}_screenshot`

## Command Relationships and Cross-References

This section outlines the relationships between different command types and how they can be used together effectively.

### Media and Control Relationships

| Command Type | Related Commands | Description |
|--------------|-----------------|-------------|
| Media Playback | `play_media`, `play`, `pause`, `stop`, `seek` | Media playback commands create media windows, control commands manipulate them |
| Audio Playback | `play_media`, `play_audio`, `pause_audio`, `stop_audio`, `seek_audio` | Audio playback creates background or windowed audio players, control commands manipulate them |
| YouTube | `youtube`, `play`, `pause`, `stop` | YouTube commands create YouTube players, media controls can manipulate them |
| WebView | `open_browser`, `refresh`, `execute_javascript` | Browser windows can be controlled with various web-specific commands |

### Window Management Workflow

Typical workflow for window management:

1. Create window with commands like `open_browser`, `play_media`, `youtube`
2. Control window with `maximize_window`, `minimize_window`, etc.
3. Manipulate content with command-specific controls
4. Close window with `close_window` command

### Content Type Detection and Defaults

When using the `play_media` command:

| URL Pattern | Default Type | Default Style | Notes |
|-------------|--------------|--------------|-------|
| Ends with .mp4, .webm, .mov | video | window | Default video player |
| Ends with .mp3, .wav, .ogg | audio | background | Default audio player |
| Ends with .jpg, .png, .gif, .webp | image | window | Default image viewer |
| YouTube URL | youtube | window | Auto-redirects to YouTube player |
| Other URL | web | window | Opens as a web page |

### Command Execution Order in Batch Commands

When using batch commands, they execute in the order specified in the array:

```json
{
  "commands": [
    { "command": "first_command" },
    { "command": "second_command" }
  ]
}
```

This is important when:
- Creating a window then controlling it
- Setting volume before starting media
- Creating elements that will interact with each other

### Status Reporting Integration

Commands that generate status reports:
- `reset_media` → Reports to `kingkiosk/{deviceName}/status/media_reset`
- `screenshot` → Reports to `kingkiosk/{deviceName}/screenshot/status`
- `halo_effect` → Reports to `kingkiosk/{deviceName}/halo_effect/status`

You can use Home Assistant automations to listen for these status topics and trigger actions.

## Home Assistant Integration

The KingKiosk app can automatically register its sensors and features with Home Assistant using MQTT discovery.

### Enabling Home Assistant Discovery
Enable Home Assistant discovery in the app settings under MQTT configuration.

### Auto-Discovered Entities

When Home Assistant discovery is enabled, the following entities are automatically created:

- **Battery Level**: `sensor.{deviceName}_battery`
- **Battery Status**: `sensor.{deviceName}_battery_status` 
- **CPU Usage**: `sensor.{deviceName}_cpu_usage`
- **Memory Usage**: `sensor.{deviceName}_memory_usage`
- **Platform**: `sensor.{deviceName}_platform`
- **Screenshot**: `camera.{deviceName}_screenshot`
- **Windows**: `sensor.{deviceName}_windows`

### Publishing Status
The app automatically publishes its availability status to:
```
kingkiosk/{deviceName}/status
```

With payload values:
- `online` - When the app is running and connected
- `offline` - When the app is shutting down or disconnected

## Audio Playback

### Play Audio with Looping
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "loop": true
}
```
- **loop**: Set to true to enable continuous looping of audio (implemented using MediaKit's PlaylistMode.single)
- **type**: Can be omitted if the URL ends with a recognized audio extension (.mp3, .wav)

### Play Audio in Background
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "style": "background"
}
```
- **style**: Set to "background" to play audio without visual interface (default for audio)
- The background player supports caching for better performance

### Play Audio in Window
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "style": "window",
  "title": "Music Player",
  "window_id": "audio-123"
}
```
- **style**: Set to "window" to play audio in a dedicated window tile with player controls
- **title**: Title for the audio window
- **window_id**: Optional custom ID for the window (auto-generated if not provided)

### Background Audio Control Commands
Background audio can be controlled using the following commands:

**Topic**: `kingkiosk/{deviceName}/command`  
**Payload** (Play):
```json
{
  "command": "play_audio"
}
```

**Payload** (Pause):
```json
{
  "command": "pause_audio"
}
```

**Payload** (Stop):
```json
{
  "command": "stop_audio"
}
```

**Payload** (Seek):
```json
{
  "command": "seek_audio",
  "position": 30.5
}
```
- **position**: Required. Position in seconds to seek to

### Window Audio Control Commands
For windowed audio players, use the standard media controls with the window_id:

**Topic**: `kingkiosk/{deviceName}/command`  
**Payload** (Play):
```json
{
  "command": "play",
  "window_id": "audio-123"
}
```

**Payload** (Pause):
```json
{
  "command": "pause",
  "window_id": "audio-123"
}
```

**Payload** (Stop):
```json
{
  "command": "stop",
  "window_id": "audio-123"
}
```

**Payload** (Seek):
```json
{
  "command": "seek",
  "window_id": "audio-123",
  "position": 45
}
```
- **position**: Required. Position in seconds to seek to

## Image Display

### Display Image
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://example.com/image.jpg",
  "style": "window",
  "title": "Image Viewer",
  "window_id": "image-123"
}
```
- **url**: Required. URL of the image to display
- **type**: Optional if URL ends with image extension (.jpg, .jpeg, .png, .gif, .webp, .bmp)
- **style**: Optional. Display style: "window", "fullscreen" (default: "window")
- **title**: Optional. Title for the image window
- **window_id**: Optional. Custom ID for the window (auto-generated if not provided)

### Display Fullscreen Image
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://example.com/image.jpg",
  "style": "fullscreen"
}
```
- Displays the image fullscreen with a close button
- When closed, the app returns to the previous state

### Display Multiple Images (Gallery)
**Topic**: `kingkiosk/{deviceName}/command`  
**Payload**:
```json
{
  "command": "play_media",
  "type": "image",
  "url": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg",
    "https://example.com/image3.jpg"
  ],
  "title": "Image Gallery",
  "style": "window"
}
```
- **url**: Can be a string for a single image or an array of URLs for multiple images
- When multiple images are provided, they display as a gallery with navigation controls
- The first image in the array is displayed initially
- Can be displayed either in window or fullscreen mode using the `style` parameter

## Tile Types

KingKiosk supports various types of window tiles that can be created and controlled via MQTT:

### Web Browser Tile
```json
{
  "command": "open_browser",
  "url": "https://example.com",
  "title": "Web Browser",
  "window_id": "web-123"
}
```

### YouTube Tile
```json
{
  "command": "youtube",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "YouTube Video",
  "window_id": "youtube-123"
}
```

### Media Tile
```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "style": "window",
  "title": "Video Player",
  "window_id": "video-123",
  "hardware_accel": true
}
```

### Audio Tile
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "style": "window",
  "title": "Audio Player",
  "window_id": "audio-123"
}
```

### Image Tile
```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://example.com/image.jpg",
  "style": "window",
  "title": "Image Viewer",
  "window_id": "image-123"
}
```

### PDF Tile
```json
{
  "command": "open_pdf",
  "url": "https://example.com/document.pdf",
  "title": "PDF Document",
  "window_id": "pdf-123"
}
```

## Testing and Troubleshooting

### Testing MQTT Commands
You can test MQTT commands using tools like:
- MQTT Explorer (recommended for GUI testing)
- Mosquitto clients (`mosquitto_pub`)
- Home Assistant MQTT Developer Tools
- Node-RED

### Example Mosquitto Commands

#### Play an Audio File
```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/command" -m '{"command":"play_media","type":"audio","url":"https://example.com/audio.mp3","loop":true,"hardware_accel":true}'
```

#### Open a Web Browser
```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/command" -m '{"command":"open_browser","url":"https://example.com","title":"Example Website"}'
```

#### Take a Screenshot
```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/command" -m '{"command":"screenshot","notify":true,"confirm":true}'
```

#### Send a Batch Command
```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/commands" -m '{"commands":[{"command":"mute"},{"command":"set_brightness","value":"0.5"}]}'
```

#### Control Background Audio
```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/command" -m '{"command":"play_audio"}'
```

```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/command" -m '{"command":"pause_audio"}'
```

```bash
mosquitto_pub -h broker.example.com -p 1883 -u username -P password -t "kingkiosk/my-device/command" -m '{"command":"seek_audio","position":30}'
```

### Common Issues and Solutions

#### Command Not Working
- Verify the device name in your topic matches exactly what's in the app settings
- Check for JSON formatting errors (use a JSON validator)
- Ensure special characters and quotes are properly escaped

#### Media Playback Issues
- If media doesn't play correctly, try the `reset_media` command with `force: true`
- For audio/video issues, make sure the URL is directly accessible (test in a browser)
- For looping audio/video, verify the `loop` parameter is set to `true`
- If videos show artifacts or don't play correctly, try setting `hardware_accel: false` in your `play_media` command
- For devices with weak GPUs, enabling `hardware_accel: true` might improve playback performance

#### Hardware Acceleration Troubleshooting
- **Black screens or frozen video**: Try disabling hardware acceleration with `hardware_accel: false`
- **High CPU usage/stuttering**: Try enabling hardware acceleration with `hardware_accel: true`
- **RTSP streams issues**: Some RTSP streams may work better with hardware acceleration disabled
- **Device-specific problems**: If a video works on one device but not another, hardware acceleration differences are often the cause
- **Browser playback works but not in app**: Try toggling the `hardware_accel` parameter

#### Window Management
- If you can't find a window ID, check the app's logs or send a notification command to display active windows
- To close all windows, use a batch command with multiple `close_window` commands

### Debugging Tips
1. Enable verbose logging in the app settings for more detailed MQTT logs
2. Use the `notify` command to display debug information: `{"command":"notify","title":"Debug","message":"Testing MQTT"}`
3. Check the connection status via `kingkiosk/{deviceName}/status` topic
4. For persistent media issues, try completely restarting the app
5. Enable Home Assistant discovery for monitoring device status via the Home Assistant interface

## Conclusion

This reference guide documents the MQTT interface for the KingKiosk application. For further customization or implementation details, refer to the source code, particularly:

- `mqtt_service_consolidated.dart` - Main MQTT message processing
- `window_manager_service.dart` - Window management 
- `background_media_service.dart` - Media playback 
- `media_control_service.dart` - Media control functionality
- `media_recovery_service.dart` - Media recovery and reset functionality
- `mqtt_notification_handler.dart` - Notification handling
