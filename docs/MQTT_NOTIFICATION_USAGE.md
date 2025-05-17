# MQTT Notification System Integration

This document provides examples of how to use the MQTT notification system in King Kiosk.

## Basic Usage

To send a notification via MQTT, publish a message to the device's command topic:

```
kiosk/[device-name]/command
```

with a payload like:

```json
{
  "command": "notify",
  "title": "Notification Title",
  "message": "This is the notification message content."
}
```

## Parameters

| Parameter  | Required | Description                                                             |
|------------|----------|-------------------------------------------------------------------------|
| `command`  | Yes      | Must be "notify"                                                        |
| `title`    | No       | Title of the notification (defaults to "MQTT Notification" if omitted)  |
| `message`  | Yes      | Content of the notification                                            |
| `priority` | No       | "high", "normal", or "low" (defaults to "normal")                       |
| `is_html`  | No       | Boolean, whether message contains HTML formatting (defaults to false)   |
| `html`     | No       | Alternative to is_html, same functionality                              |
| `thumbnail`| No       | URL to thumbnail image for the notification                             |

## Example Commands

### Basic Notification

```json
{
  "command": "notify",
  "title": "System Alert",
  "message": "System update completed successfully."
}
```

### HTML Notification with High Priority

```json
{
  "command": "notify",
  "title": "Important Update",
  "message": "<h3>New Feature Available</h3><p>Click <a href=\"https://example.com\">here</a> to learn more.</p>",
  "is_html": true,
  "priority": "high",
  "thumbnail": "https://example.com/notification-icon.png"
}
```

## Home Assistant Integration

To integrate with Home Assistant, you can use the following automation:

```yaml
# Example Home Assistant automation that sends notification to King Kiosk
automation:
  - alias: "Send notification to King Kiosk"
    trigger:
      - platform: state
        entity_id: binary_sensor.motion_sensor
        to: "on"
    action:
      - service: mqtt.publish
        data:
          topic: "kiosk/device-12345/command"  # Replace with your device name
          payload: >
            {
              "command": "notify",
              "title": "Motion Detected",
              "message": "Motion was detected in the {{ trigger.to_state.attributes.friendly_name }}.",
              "priority": "high"
            }
```

You can also send HTML formatted notifications:

```yaml
automation:
  - alias: "Send weather update notification to King Kiosk"
    trigger:
      - platform: time_pattern
        hours: "/3"  # Every 3 hours
    action:
      - service: mqtt.publish
        data:
          topic: "kiosk/device-12345/command"  # Replace with your device name
          payload_template: >
            {
              "command": "notify",
              "title": "Weather Update",
              "message": "<h3>Current Weather</h3><p>Temperature: {{ states('sensor.temperature') }}°C</p><p>Humidity: {{ states('sensor.humidity') }}%</p>",
              "is_html": true,
              "thumbnail": "{{ states('sensor.weather_icon') }}"
            }
```

## Using with Batch Commands

You can include notifications in batch commands for more complex scenarios:

```json
{
  "command": "batch",
  "commands": [
    {
      "command": "notify",
      "title": "Starting Update",
      "message": "The system will now perform updates."
    },
    {
      "command": "set_volume",
      "value": 0.7
    },
    {
      "command": "play_media",
      "type": "audio",
      "url": "https://example.com/notification-sound.mp3",
      "style": "background"
    }
  ]
}
```

## Troubleshooting

If notifications aren't appearing:

1. Verify that the MQTT connection is working
2. Check the topic format (should be `kiosk/[device-name]/command`)
3. Ensure the JSON payload is properly formatted
4. Check device logs for any error messages related to notification processing
