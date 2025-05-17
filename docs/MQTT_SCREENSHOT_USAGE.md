# MQTT Screenshot Command

This document explains how to use the screenshot feature in King Kiosk via MQTT commands.

## Basic Usage

To take a screenshot of the kiosk display, send a command to the device's command topic:

```
kiosk/[device-name]/command
```

with this simple payload:

```json
{
  "command": "screenshot"
}
```

## How it Works

When the kiosk receives this command, it will:

1. Capture a screenshot of the current display
2. Save the screenshot to the device's storage
3. If Home Assistant discovery is enabled, the screenshot will be published as a camera entity to your Home Assistant instance

## Home Assistant Integration

The screenshot feature integrates with Home Assistant by:

1. Auto-discovering as a camera entity using the MQTT Camera integration
2. Publishing base64-encoded images to the topic: `kingkiosk/[device-name]/screenshot`

### How to use in Home Assistant

Once the screenshot has been taken and sent to Home Assistant, you'll see a camera entity with the name "[Device Name] Screenshot" in your Home Assistant dashboard.

You can:
- View the latest screenshot in the Lovelace UI
- Create automations that trigger screenshots at specific times or events
- Use the screenshot as part of a notification or alert

### Example Automation

```yaml
# Take a screenshot every hour
automation:
  - alias: "Take hourly kiosk screenshot"
    trigger:
      - platform: time_pattern
        minutes: "0"  # Every hour at :00 minutes
    action:
      - service: mqtt.publish
        data:
          topic: "kiosk/device-12345/command"  # Replace with your device name
          payload: '{"command": "screenshot"}'
```

## Troubleshooting

If screenshots aren't working:

1. Ensure that the MQTT connection is working
2. Check the app logs for any errors related to screenshot capture
3. Verify that the correct topic format is being used
4. If using with Home Assistant, ensure that MQTT discovery is enabled in the kiosk settings

## Technical Notes

The screenshot feature generates a representation of the current app state and converts it to a base64 encoded string for transmission via MQTT. The image is temporarily stored on the device and can be retrieved from the app's temporary directory.

**Implementation Notes:**
- The current implementation provides a placeholder image that displays the current date and time
- For security and technical reasons, capturing the actual screen contents may be restricted on certain platforms
- Image sizing and quality are optimized for MQTT transmission while maintaining reasonable visual quality

**Limitations:**
- Due to platform restrictions, the screenshot may not capture the exact visual state of the application
- Some platforms may require special permissions to capture the actual screen contents
- The quality and resolution of screenshots are optimized for transmission over MQTT
