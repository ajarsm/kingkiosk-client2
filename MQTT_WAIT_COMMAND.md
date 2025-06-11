# MQTT Wait Command Documentation

## Overview
The `wait` command allows you to add delays in MQTT batch command scripts without blocking other kiosk operations.

## Usage

### Single Wait Command
```json
{
  "command": "wait",
  "seconds": 5.5
}
```

### Batch Script with Wait Commands
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "play_media",
      "type": "video",
      "url": "https://example.com/video1.mp4"
    },
    {
      "command": "wait",
      "seconds": 10
    },
    {
      "command": "play_media", 
      "type": "video",
      "url": "https://example.com/video2.mp4"
    },
    {
      "command": "wait",
      "seconds": 2.5
    },
    {
      "command": "tts",
      "text": "Videos have finished playing"
    }
  ]
}
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `command` | string | Yes | Must be "wait" |
| `seconds` | number | Yes | Number of seconds to wait (0.1 to 300) |
| `response_topic` | string | No | MQTT topic to publish completion/error status |

## Response Format

When `response_topic` is provided, the command publishes a response:

### Success Response
```json
{
  "success": true,
  "waited_seconds": 5.5,
  "command": "wait",
  "timestamp": "2025-06-11T14:30:45.123Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Wait seconds must be between 0 and 300, got: 500",
  "command": "wait", 
  "timestamp": "2025-06-11T14:30:45.123Z"
}
```

## Key Features

- ✅ **Non-blocking**: Only pauses the script, not other kiosk functions
- ✅ **Precise timing**: Supports fractional seconds (e.g., 2.5 seconds)
- ✅ **Safety limits**: Maximum wait time of 5 minutes (300 seconds)
- ✅ **Batch compatible**: Works seamlessly in batch command scripts
- ✅ **Response feedback**: Optional status reporting via MQTT
- ✅ **Error handling**: Validates input parameters and reports errors

## Example Use Cases

### Sequential Media Playback
```json
{
  "commands": [
    {"command": "play_media", "url": "intro.mp4"},
    {"command": "wait", "seconds": 30},
    {"command": "play_media", "url": "main.mp4"},
    {"command": "wait", "seconds": 120},
    {"command": "play_media", "url": "outro.mp4"}
  ]
}
```

### Timed Announcements
```json
{
  "commands": [
    {"command": "tts", "text": "Welcome to our presentation"},
    {"command": "wait", "seconds": 3},
    {"command": "tts", "text": "Starting in 5 seconds"},
    {"command": "wait", "seconds": 5},
    {"command": "open_browser", "url": "presentation.html"}
  ]
}
```

### Slideshow with Delays
```json
{
  "commands": [
    {"command": "open_browser", "url": "slide1.html"},
    {"command": "wait", "seconds": 15},
    {"command": "open_browser", "url": "slide2.html"},
    {"command": "wait", "seconds": 15},
    {"command": "open_browser", "url": "slide3.html"}
  ]
}
```

## Technical Notes

- Wait commands use `Future.delayed()` which is asynchronous and non-blocking
- The kiosk remains fully responsive during wait periods
- Other MQTT commands can be processed while a wait is active
- Fractional seconds are supported with millisecond precision
- Maximum wait time is enforced for safety (300 seconds = 5 minutes)
