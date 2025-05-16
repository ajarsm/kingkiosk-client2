# Custom Titles for Window Tiles

This document describes how to use custom titles for different types of window tiles in the King Kiosk application.

## Overview

All window tile types now support custom titles through MQTT commands. This feature allows you to specify a meaningful name for each tile when it's created, which is displayed in the window title bar and used for identification.

## Supported Window Types

Custom titles are supported for all window types:

- **Images** (single or carousel)
- **Videos**
- **Audio players**
- **Web browsers**

## MQTT Command Format

### Image Display

```json
{
  "command": "play_media",
  "type": "image", 
  "url": "https://example.com/image.jpg",
  "style": "window",
  "title": "My Custom Image Title"
}
```

For image carousels, you can provide an array of URLs:

```json
{
  "command": "play_media",
  "type": "image", 
  "url": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg",
    "https://example.com/image3.jpg"
  ],
  "style": "window",
  "title": "My Image Carousel"
}
```

### Video Playback

```json
{
  "command": "play_media",
  "type": "video",
  "url": "https://example.com/video.mp4",
  "style": "window",
  "title": "My Custom Video Title",
  "loop": true
}
```

### Audio Playback

```json
{
  "command": "play_media",
  "type": "audio",
  "url": "https://example.com/audio.mp3",
  "style": "window",
  "title": "My Custom Audio Title"
}
```

### Web Browser

```json
{
  "command": "open_browser",
  "url": "https://www.example.com",
  "title": "My Custom Web Title"
}
```

## Default Titles

If no custom title is provided, the system will use these defaults:

- Images: "MQTT Image"
- Videos: "Kiosk Video"
- Audio: "Kiosk Audio"
- Web: "MQTT Web"

## Testing Custom Titles

A test script is provided to demonstrate custom titles for all media types:

```bash
chmod +x test_all_media.sh
./test_all_media.sh
```

This script sends MQTT commands with custom titles for images, videos, audio, and web browsers.

## Programmatic Usage

When programmatically creating windows, you can specify custom titles:

```dart
// For web view
controller.addWebViewTile("My Custom Web Title", url);

// For video
controller.addMediaTile("My Custom Video Title", url, loop: false);

// For audio
controller.addAudioTile("My Custom Audio Title", url);

// For image
controller.addImageTile("My Custom Image Title", url);

// For image carousel
controller.addImageTile("My Custom Carousel Title", imageUrlsList);
```
