# King Kiosk MQTT Commands Reference

This document provides a comprehensive reference of all MQTT commands available in the King Kiosk application.

## Table of Contents
1. [Media Commands](#media-commands)
   - [Play Media](#play-media)
   - [Web Browser](#web-browser)
2. [Window Management](#window-management)
   - [Close Window](#close-window)
   - [Maximize Window](#maximize-window)
   - [Minimize Window](#minimize-window)
3. [Media Player Controls](#media-player-controls)
   - [Play](#play)
   - [Pause](#pause)
4. [Web Window Controls](#web-window-controls)
   - [Refresh](#refresh)
   - [Restart](#restart)
   - [Load URL](#load-url)
   - [Execute JavaScript](#execute-javascript)
5. [System Controls](#system-controls)
   - [Volume Control](#volume-control)
   - [Brightness Control](#brightness-control)
6. [Batch Commands](#batch-commands)
7. [Command Topics](#command-topics)
8. [Best Practices](#best-practices)

---

## Media Commands

### Play Media

**Command:** `play_media`

Plays various types of media (video, audio, image) on the kiosk.

#### Parameters:
- `type`: Type of media - "video", "audio", or "image"
- `url`: URL of the media file
- `style`: Playback style - "window", "fullscreen", or background (default)
- `title`: Optional title for the window
- `loop`: Set to "true" to loop the media
- `window_id`: Optional custom ID to identify the window for further control

#### Examples:

##### Play Video in Window:
```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "style": "window",
  "title": "My Video",
  "loop": true,
  "window_id": "video1"
}
```

##### Play Audio in Window:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "style": "window",
  "title": "Music Track",
  "window_id": "audio1"
}
```

##### Display Image in Window:
```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://example.com/image.jpg",
  "title": "My Image",
  "window_id": "image1"
}
```

##### Play Video Fullscreen:
```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "style": "fullscreen",
  "loop": false
}
```

##### Display Image Fullscreen:
```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://example.com/image.jpg",
  "style": "fullscreen"
}
```

##### Play Audio in Background:
```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "loop": true
}
```

##### Display Multiple Images (Carousel):
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
  "window_id": "gallery1"
}
```

### Web Browser

**Command:** `open_browser`

Opens a web page in a window.

#### Parameters:
- `url`: The website URL to open
- `title`: Optional title for the window
- `window_id`: Optional custom ID to identify the window for further control

#### Example:
```json
{
  "command": "open_browser",
  "url": "https://example.com",
  "title": "Example Website",
  "window_id": "web1"
}
```

## Window Management

### Close Window

**Command:** `close_window`

Closes a specific window by ID.

#### Parameters:
- `window_id`: The ID of the window to close

#### Example:
```json
{
  "command": "close_window",
  "window_id": "video1"
}
```

### Maximize Window

**Command:** `maximize_window`

Maximizes a specific window by ID.

#### Parameters:
- `window_id`: The ID of the window to maximize

#### Example:
```json
{
  "command": "maximize_window",
  "window_id": "web1"
}
```

### Minimize Window

**Command:** `minimize_window`

Minimizes a specific window by ID.

#### Parameters:
- `window_id`: The ID of the window to minimize

#### Example:
```json
{
  "command": "minimize_window",
  "window_id": "video1"
}
```

## Media Player Controls

### Play

**Command:** `play`

Resumes playback of a paused media window.

#### Parameters:
- `window_id`: The ID of the media window to resume

#### Example:
```json
{
  "command": "play",
  "window_id": "video1"
}
```

### Pause

**Command:** `pause`

Pauses playback of a media window.

#### Parameters:
- `window_id`: The ID of the media window to pause

#### Example:
```json
{
  "command": "pause",
  "window_id": "video1"
}
```

> **Note:** There's also a legacy `pause_media` command that works the same way but is now deprecated.

## Web Window Controls

### Refresh

**Command:** `refresh`

Refreshes a web window.

#### Parameters:
- `window_id`: The ID of the web window to refresh

#### Example:
```json
{
  "command": "refresh",
  "window_id": "web1"
}
```

### Restart

**Command:** `restart`

Restarts a web window.

#### Parameters:
- `window_id`: The ID of the web window to restart

#### Example:
```json
{
  "command": "restart",
  "window_id": "web1"
}
```

### Load URL

**Command:** `loadurl`

Loads a new URL in an existing web window.

#### Parameters:
- `window_id`: The ID of the web window
- `url`: The new URL to load

#### Example:
```json
{
  "command": "loadurl",
  "window_id": "web1",
  "url": "https://example.com/new-page"
}
```

### Execute JavaScript

**Command:** `evaljs`

Executes JavaScript code in a web window.

#### Parameters:
- `window_id`: The ID of the web window
- `code`: The JavaScript code to execute

#### Example:
```json
{
  "command": "evaljs",
  "window_id": "web1",
  "code": "document.body.style.backgroundColor = 'red';"
}
```

## System Controls

### Volume Control

#### Set Volume

**Command:** `set_volume`

Sets the system volume level.

##### Parameters:
- `value`: Volume level from 0.0 (muted) to 1.0 (maximum)

##### Example:
```json
{
  "command": "set_volume",
  "value": 0.5
}
```

#### Mute System

**Command:** `mute`

Mutes the system audio.

##### Example:
```json
{
  "command": "mute"
}
```

#### Unmute System

**Command:** `unmute`

Unmutes the system audio.

##### Example:
```json
{
  "command": "unmute"
}
```

### Brightness Control

#### Set Brightness

**Command:** `set_brightness`

Sets the system screen brightness.

##### Parameters:
- `value`: Brightness level from 0.0 (dim) to 1.0 (brightest)

##### Example:
```json
{
  "command": "set_brightness",
  "value": 0.8
}
```

#### Get Brightness

**Command:** `get_brightness`

Gets the current system brightness level. Optionally publishes to a response topic.

##### Parameters:
- `response_topic`: Optional topic where the brightness value will be published

##### Example:
```json
{
  "command": "get_brightness",
  "response_topic": "kiosk/brightness/response"
}
```

#### Restore Brightness

**Command:** `restore_brightness`

Restores system brightness to default level (currently sets to maximum).

##### Example:
```json
{
  "command": "restore_brightness"
}
```

## Batch Commands

You can send multiple commands in a single MQTT message using the batch format.

### Batch Command Format

```json
{
  "commands": [
    {
      "command": "command1",
      ...parameters for command1...
    },
    {
      "command": "command2",
      ...parameters for command2...
    }
  ]
}
```

### Example:
```json
{
  "commands": [
    {
      "command": "play_media",
      "type": "video",
      "url": "https://example.com/video.mp4",
      "style": "window",
      "window_id": "video1"
    },
    {
      "command": "set_volume",
      "value": 0.7
    }
  ]
}
```

## Command Topics

The kiosk subscribes to the following command topics:

- `kingkiosk/{device_name}/command` - Send single commands here
- `kingkiosk/{device_name}/commands` - Also accepted for commands
- `kiosk/{device_name}/window/+/command` - Window-specific commands

Where `{device_name}` is the configured device name in the kiosk settings.

## Best Practices

1. **Always use window_id for windows** - This makes it much easier to control them later with other commands.

2. **Use descriptive window titles** - This helps identify what each window contains.

3. **Use batch commands for related operations** - For example, creating a window and setting volume in one message.

4. **Consider topic structure** - Use the appropriate topic for your command.

5. **Type inference** - If you don't specify a media type, the system will attempt to infer it from the file extension.

6. **Testing** - Test your MQTT commands with small payloads first to ensure they work as expected.

7. **Debugging** - Use the Home Assistant MQTT integration or MQTT Explorer to debug your commands.

8. **Status monitoring** - The kiosk publishes its status to `kingkiosk/{device_name}/status` with values "online" or "offline".
