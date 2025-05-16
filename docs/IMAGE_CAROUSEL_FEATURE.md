# Image Carousel Feature

This document describes the image carousel functionality in King Kiosk, which allows displaying multiple images in a slidable carousel with auto-advancing capability.

## Overview

The image carousel feature enables displaying multiple images in a single window or fullscreen display with automatic transitions. This is useful for slideshows, product displays, or any situation where you want to cycle through multiple images.

## Features

- **Multiple Display Modes**: Works in both windowed and fullscreen modes
- **Auto-Transitioning**: Automatically advances to the next image after a configurable delay
- **Indicator Dots**: Shows pagination dots indicating the current image position
- **Manual Navigation**: Allows swiping between images manually
- **Custom Titles**: Supports custom titles for the carousel window

## MQTT Command Format

### Windowed Image Carousel

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

### Fullscreen Image Carousel

```json
{
  "command": "play_media",
  "type": "image", 
  "url": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg",
    "https://example.com/image3.jpg"
  ],
  "style": "fullscreen",
  "title": "My Fullscreen Carousel"
}
```

## Behavior

- If a single image URL is provided, a standard image display is used without carousel functionality
- If multiple images are provided, the carousel will automatically activate
- The carousel will auto-advance with a default 5-second interval between transitions
- When in fullscreen mode, controls are hidden for a cleaner presentation
- When in window mode, controls for closing and maximizing the window are available

## Implementation Details

The image carousel is implemented using the `flutter_carousel_widget` package with the following features:

- Smooth transitions between images
- Pagination indicators to show current position
- Auto-advancing capability
- Touch/swipe gesture support
- Optimized image loading with loading indicators

## Testing

Use the provided test script to verify carousel functionality:

```bash
chmod +x test_image_mqtt.sh
./test_image_mqtt.sh
```

This will test both windowed and fullscreen carousel modes with multiple images.

## Programmatic Usage

You can also use the carousel programmatically:

```dart
// For windowed carousel
controller.addImageTile("My Carousel", [url1, url2, url3]);

// Through BackgroundMediaService
mediaService.displayImageWindowed([url1, url2, url3], title: "Slideshow");

// For fullscreen carousel
mediaService.displayImageFullscreen([url1, url2, url3]);
```
