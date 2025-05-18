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

For advanced options, you can use:

```json
{
  "command": "screenshot",
  "notify": true,     // Show notification on device when screenshot is taken
  "confirm": true     // Get confirmation on a status topic
}
```

## How it Works

When the kiosk receives this command, it will:

1. Capture a screenshot of the current display
2. Save the screenshot to the device's storage based on the platform:
   - **iOS**: Saved to photos library and app documents
   - **Android**: Saved to media store and app documents
   - **Desktop**: Saved to application documents directory
   - **Web**: Offered as a download (platform limitations apply)
3. If Home Assistant discovery is enabled, the screenshot will be published as a camera entity to your Home Assistant instance

## Platform-Specific Behavior

### iOS and Android
- Requires appropriate permissions (handled automatically)
- Saves to the device gallery/photos app
- Also saves to app's internal storage

### Desktop (Windows/macOS/Linux)
- No special permissions required
- Saves to application documents directory

### Web
- No permissions required
- Screenshots are offered as downloads
- Home Assistant integration functions normally

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

The screenshot feature captures the current state of the app and converts it to a base64 encoded string for transmission via MQTT. The image is stored on the device according to platform-specific best practices.

**Implementation Notes:**
- Uses a platform abstraction layer to handle different environments appropriately
- Automatically handles permission requests on mobile platforms
- Provides fallback screenshots when capture fails showing the current date and time
- Image sizing and quality are optimized for MQTT transmission while maintaining good visual quality

**Enhanced Features:**
- Status reporting via `kingkiosk/[device-name]/screenshot/status` topic when using `confirm: true`
- Optional notification on device when screenshot is taken
- Cross-platform support with appropriate behavior on each platform

**Permissions:**
- **iOS**: Requires Photos Library access
- **Android**: Requires storage permission (API 28 and below) or media store access
- **Desktop**: No special permissions required
- **Web**: Uses browser's security model

**Platform-Specific Storage:**
- **iOS**: Photos Library + app documents directory
- **Android**: Media Store + app documents directory
- **Desktop**: Application documents directory (`~/Documents/KingKiosk/Screenshots/`)
- **Web**: Browser downloads
