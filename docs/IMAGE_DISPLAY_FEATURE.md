# Image Display Feature in KingKiosk

This document describes the new image display capability added to the KingKiosk system.

## Overview

The image display feature allows displaying images either in a windowed tile or fullscreen mode using the same MQTT command pattern as other media types (audio/video). This feature enhances the kiosk's ability to show static content like photos, diagrams, notifications, or promotional material.

## How It Works

Images can be displayed in two modes:
1. **Windowed Mode** - The image appears as a resizable, movable tile in the window manager.
2. **Fullscreen Mode** - The image takes over the entire screen.

## Using the Feature

### MQTT Commands

Display an image using the `play_media` MQTT command:

```json
{
  "command": "play_media",
  "type": "image",
  "url": "https://example.com/path/to/image.jpg",
  "style": "window",
  "title": "My Image Title"
}
```

Parameters:
- `type`: Must be `"image"` (the system can also auto-detect images from common file extensions)
- `url`: Full URL to the image file (supports jpg, jpeg, png, gif, webp, bmp)
- `style`: Either `"window"` or `"fullscreen"` (defaults to `"window"` if not specified)
- `title`: Optional title for the windowed image (defaults to "MQTT Image" if not specified)

### Programmatic API

Use the BackgroundMediaService directly in code:

```dart
final mediaService = Get.find<BackgroundMediaService>();

// Display in window
mediaService.displayImageWindowed("https://example.com/image.jpg", title: "Custom Title");

// Display fullscreen
mediaService.displayImageFullscreen("https://example.com/image.jpg");
```

## Technical Details

- Images are displayed using Flutter's `Image.network` widget, which handles loading and caching
- Loading indicators show while images are being downloaded
- Error states display when images fail to load
- Fullscreen images can be closed using the X button in the top-right corner
- Windowed images integrate with the existing window management system

## Supported Image Formats

The feature supports all image formats supported by Flutter's Image widget:
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)
- BMP (.bmp)

## Example

```json
{
  "command": "play_media",
  "url": "https://example.com/notifications/alert.png",
  "type": "image",
  "style": "fullscreen"
}
```

This will display the alert image in fullscreen mode.
