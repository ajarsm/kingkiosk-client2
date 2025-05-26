# King Kiosk MQTT Documentation

## Overview

This document provides comprehensive information about the MQTT interface for King Kiosk. MQTT enables remote control of your King Kiosk applications and allows integration with home automation systems like Home Assistant.

## Connection Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Broker URL | The MQTT broker's hostname or IP address | broker.emqx.io |
| Port | The MQTT broker's port | 1883 |
| Username | Optional username for broker authentication | (none) |
| Password | Optional password for broker authentication | (none) |
| Device Name | Unique identifier for your kiosk | Automatically generated |
| HA Discovery | Enable Home Assistant MQTT Discovery | false |

## Topic Structure

King Kiosk uses the following MQTT topic structure:

```
kingkiosk/<device-name>/command      # For single commands
kingkiosk/<device-name>/commands     # For batch commands
kingkiosk/<device-name>/status       # Device online/offline status
kingkiosk/<device-name>/<sensor>     # Sensor values (battery, cpu, etc.)
kiosk/<device-name>/window/<id>/command  # Window-specific commands
```

## Available Commands

Commands are sent as JSON payloads to the command topic. All commands follow this basic structure:

```json
{
  "command": "command_name",
  "param1": "value1",
  "param2": "value2"
}
```

### Media Commands

#### Play Media

```json
{
  "command": "play_media",
  "type": "audio|video|image",
  "url": "https://example.com/media.mp4",
  "title": "Optional Title",
  "style": "window|fullscreen|background",
  "loop": true|false,
  "window_id": "optional-custom-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| type | string | Yes | Media type: "audio", "video", or "image" |
| url | string | Yes | URL of the media to play |
| title | string | No | Title to display for the media window |
| style | string | No | Display style: "window", "fullscreen", or "background" |
| loop | boolean | No | Whether to loop the media (default: false) |
| window_id | string | No | Optional custom ID for the window |

#### Open Browser

```json
{
  "command": "open_browser",
  "url": "https://example.com",
  "title": "Example Website",
  "window_id": "optional-custom-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| url | string | Yes | URL to open in the browser |
| title | string | No | Title for the browser window |
| window_id | string | No | Optional custom ID for the window |

#### YouTube Player

```json
{
  "command": "youtube",
  "url": "https://youtube.com/watch?v=VIDEO_ID",
  "title": "YouTube Video",
  "window_id": "optional-custom-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| url | string | Yes | YouTube video URL |
| title | string | No | Title for the YouTube player window |
| window_id | string | No | Optional custom ID for the window |

### Window Management

#### Close Window

```json
{
  "command": "close_window",
  "window_id": "window-id-to-close"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the window to close |

#### Maximize Window

```json
{
  "command": "maximize_window",
  "window_id": "window-id-to-maximize"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the window to maximize |

#### Minimize Window

```json
{
  "command": "minimize_window",
  "window_id": "window-id-to-minimize"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the window to minimize |

### Media Window Controls

#### Play Media in Window

```json
{
  "command": "play",
  "window_id": "media-window-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the media window |

#### Pause Media in Window

```json
{
  "command": "pause",
  "window_id": "media-window-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the media window |

### Web Window Controls

#### Refresh Web Window

```json
{
  "command": "refresh",
  "window_id": "web-window-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the web window to refresh |

#### Restart Web Window

```json
{
  "command": "restart",
  "window_id": "web-window-id"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the web window to restart |

#### Evaluate JavaScript in Web Window

```json
{
  "command": "evaljs",
  "window_id": "web-window-id",
  "script": "document.getElementById('example').click();"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the web window |
| script | string | Yes | JavaScript code to execute in the web window |

#### Load URL in Web Window

```json
{
  "command": "loadurl",
  "window_id": "web-window-id",
  "url": "https://example.com/new-page"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the web window |
| url | string | Yes | New URL to load in the web window |

### Notifications

```json
{
  "command": "notify",
  "title": "Notification Title",
  "message": "Notification message",
  "is_html": true|false,
  "priority": "low|normal|high",
  "thumbnail": "https://example.com/image.jpg",
  "sound": "chime",
  "duration": 5000
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| title | string | Yes | Title of the notification |
| message | string | Yes | Notification message content |
| is_html | boolean | No | Whether message contains HTML (default: false) |
| priority | string | No | Priority level: "low", "normal", or "high" (default: "normal") |
| thumbnail | string | No | URL of an image to show in the notification |
| sound | string | No | Sound to play with notification (e.g., "chime") |
| duration | number | No | Duration in milliseconds to show notification (default: 5000) |

### System Controls

#### Set Volume

```json
{
  "command": "set_volume",
  "value": "0.7"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| value | string/number | Yes | Volume level (0.0 to 1.0) |

#### Mute Audio

```json
{
  "command": "mute"
}
```

#### Unmute Audio

```json
{
  "command": "unmute"
}
```

#### Set Brightness

```json
{
  "command": "set_brightness",
  "value": "0.8"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| value | string/number | Yes | Brightness level (0.0 to 1.0) |

#### Get Brightness

```json
{
  "command": "get_brightness",
  "response_topic": "optional/response/topic"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| response_topic | string | No | Topic to publish brightness value to |

#### Restore Brightness

```json
{
  "command": "restore_brightness"
}
```

### Visual Effects

#### Halo Effect

```json
{
  "command": "halo_effect",
  "enabled": true|false,
  "color": "#FF0000",
  "width": 10,
  "intensity": 0.8,
  "pulse_mode": "none|gentle|moderate|alert",
  "pulse_duration": 2000,
  "fade_in_duration": 800,
  "fade_out_duration": 1000,
  "confirm": true|false
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| enabled | boolean | No | Whether to enable or disable the effect (default: true) |
| color | string | No | Color in hex format or color name (default: "red") |
| width | number | No | Width of the halo effect in pixels |
| intensity | number | No | Opacity level (0.0 to 1.0) |
| pulse_mode | string | No | Pulse animation: "none", "gentle", "moderate", or "alert" |
| pulse_duration | number | No | Duration of pulse animation in milliseconds |
| fade_in_duration | number | No | Fade-in duration in milliseconds |
| fade_out_duration | number | No | Fade-out duration in milliseconds |
| confirm | boolean | No | Whether to send a confirmation message |

#### Window-Specific Halo Effect

```json
{
  "command": "halo_effect",
  "window_id": "window-id",
  "enabled": true|false,
  "color": "#00FF00",
  "width": 10,
  "intensity": 0.8,
  "pulse_mode": "none|gentle|moderate|alert",
  "pulse_duration": 2000,
  "fade_in_duration": 800,
  "fade_out_duration": 1000,
  "confirm": true|false
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| window_id | string | Yes | ID of the window to apply the halo effect to |
| enabled | boolean | No | Whether to enable or disable the effect (default: true) |
| color | string | No | Color in hex format or color name (default: "red") |
| width | number | No | Width of the halo effect in pixels |
| intensity | number | No | Opacity level (0.0 to 1.0) |
| pulse_mode | string | No | Pulse animation: "none", "gentle", "moderate", or "alert" |
| pulse_duration | number | No | Duration of pulse animation in milliseconds |
| fade_in_duration | number | No | Fade-in duration in milliseconds |
| fade_out_duration | number | No | Fade-out duration in milliseconds |
| confirm | boolean | No | Whether to send a confirmation message |

### Troubleshooting

#### Take Screenshot

```json
{
  "command": "screenshot",
  "notify": true|false,
  "confirm": true|false
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| notify | boolean | No | Whether to show a notification when screenshot is taken |
| confirm | boolean | No | Whether to send a confirmation message |

#### Reset Media System

```json
{
  "command": "reset_media",
  "force": true|false,
  "test": true|false
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| force | boolean | No | Force reset even if not necessary (default: false) |
| test | boolean | No | Only test media system, don't reset (default: false) |

## Batch Commands

You can send multiple commands at once using the batch format:

```json
{
  "command": "batch",
  "commands": [
    {
      "command": "play_media",
      "type": "audio",
      "url": "https://example.com/audio.mp3"
    },
    {
      "command": "notify",
      "title": "Media Started",
      "message": "Your audio is now playing"
    }
  ]
}
```

Alternatively, you can use this simplified format:

```json
{
  "commands": [
    {
      "command": "play_media",
      "type": "audio",
      "url": "https://example.com/audio.mp3"
    },
    {
      "command": "notify",
      "title": "Media Started",
      "message": "Your audio is now playing"
    }
  ]
}
```

## Home Assistant Integration

King Kiosk supports Home Assistant MQTT Discovery for automatic entity creation in Home Assistant.

When enabled, the following entities will be automatically created:

- Battery level sensor
- Battery status sensor
- CPU usage sensor
- Memory usage sensor
- Platform information sensor
- Open windows count sensor
- Screenshot camera entity

### Home Assistant Sensor Topic Structure

```
homeassistant/sensor/<device-name>_<sensor>/config   # Discovery config
kingkiosk/<device-name>/<sensor>                    # Sensor state topic
```

## Example MQTT Commands (Terminal)

### Playing Media

```bash
mosquitto_pub -h localhost -p 1883 -t "kingkiosk/device-12345/command" -m '{
  "command": "play_media",
  "type": "video",
  "url": "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4",
  "title": "Sample Video",
  "style": "window",
  "loop": true
}'
```

### Sending a Notification

```bash
mosquitto_pub -h localhost -p 1883 -t "kingkiosk/device-12345/command" -m '{
  "command": "notify",
  "title": "HTML with Thumbnail",
  "message": "<h2>HTML Format</h2><p>This notification includes <b>formatted text</b> and a thumbnail image.</p>",
  "is_html": true,
  "thumbnail": "https://picsum.photos/200"
}'
```

### Enabling Halo Effect

```bash
mosquitto_pub -h localhost -p 1883 -t "kingkiosk/device-12345/command" -m '{
  "command": "halo_effect",
  "color": "red",
  "pulse_mode": "gentle"
}'
```

### Taking a Screenshot

```bash
mosquitto_pub -h localhost -p 1883 -t "kingkiosk/device-12345/command" -m '{
  "command": "screenshot",
  "notify": true,
  "confirm": true
}'
```

## Troubleshooting

### Connection Issues

If you experience connection issues, try the following:

1. Verify that the MQTT broker URL and port are correct
2. Check if username/password are required for your broker
3. Ensure your network allows connections to the MQTT broker
4. Try using a different client ID by changing the device name

### Message Delivery Issues

If your commands are not being processed:

1. Verify that you're publishing to the correct topic
2. Ensure your JSON payload is valid
3. Check the device's logs for any MQTT-related errors
4. Verify that the device is connected to the broker

## API Reference

A full list of commands and parameters is provided in the sections above. For implementation details, refer to the MqttService class in the King Kiosk codebase.
