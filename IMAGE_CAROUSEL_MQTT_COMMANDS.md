# Image Carousel MQTT Commands

This document provides examples of MQTT commands for using the enhanced image carousel functionality in KingKiosk.

## Basic Image Display

### Single Image
```json
{
  "action": "add_window",
  "windowType": "image",
  "windowId": "my_image",
  "title": "My Image",
  "url": "https://example.com/image.jpg"
}
```

### Image Carousel
```json
{
  "action": "add_window",
  "windowType": "image",
  "windowId": "my_carousel",
  "title": "Image Carousel",
  "urls": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg",
    "https://example.com/image3.jpg",
    "https://example.com/image4.jpg"
  ]
}
```

## Dynamic Carousel Management

### Add Image to Existing Carousel
```json
{
  "action": "window_command",
  "windowId": "my_carousel",
  "command": "add_image",
  "payload": {
    "url": "https://example.com/new_image.jpg"
  }
}
```

### Remove Image from Carousel
```json
{
  "action": "window_command",
  "windowId": "my_carousel",
  "command": "remove_image",
  "payload": {
    "url": "https://example.com/image_to_remove.jpg"
  }
}
```

### Replace All Images in Carousel
```json
{
  "action": "window_command",
  "windowId": "my_carousel",
  "command": "set_images",
  "payload": {
    "urls": [
      "https://example.com/new_image1.jpg",
      "https://example.com/new_image2.jpg",
      "https://example.com/new_image3.jpg"
    ]
  }
}
```

## Carousel Configuration

### Set Carousel with Custom Auto-Play
```json
{
  "action": "window_command",
  "windowId": "my_carousel",
  "command": "set_carousel",
  "payload": {
    "urls": [
      "https://example.com/image1.jpg",
      "https://example.com/image2.jpg",
      "https://example.com/image3.jpg"
    ],
    "auto_play": true,
    "interval": 3
  }
}
```

### Configure Auto-Play Settings Only
```json
{
  "action": "window_command",
  "windowId": "my_carousel",
  "command": "set_autoplay",
  "payload": {
    "enabled": true,
    "interval": 8
  }
}
```

### Disable Auto-Play
```json
{
  "action": "window_command",
  "windowId": "my_carousel",
  "command": "set_autoplay",
  "payload": {
    "enabled": false
  }
}
```

## Batch Commands for Image Rotation

### Create Multiple Carousels
```json
[
  {
    "action": "add_window",
    "windowType": "image",
    "windowId": "carousel_1",
    "title": "Nature Photos",
    "urls": [
      "https://example.com/nature1.jpg",
      "https://example.com/nature2.jpg",
      "https://example.com/nature3.jpg"
    ]
  },
  {
    "action": "add_window",
    "windowType": "image",
    "windowId": "carousel_2",
    "title": "City Photos",
    "urls": [
      "https://example.com/city1.jpg",
      "https://example.com/city2.jpg",
      "https://example.com/city3.jpg"
    ]
  }
]
```

### Update Multiple Carousels
```json
[
  {
    "action": "window_command",
    "windowId": "carousel_1",
    "command": "set_images",
    "payload": {
      "urls": [
        "https://example.com/updated_nature1.jpg",
        "https://example.com/updated_nature2.jpg"
      ]
    }
  },
  {
    "action": "window_command",
    "windowId": "carousel_2",
    "command": "set_autoplay",
    "payload": {
      "enabled": true,
      "interval": 5
    }
  }
]
```

## Practical Examples

### Digital Signage Rotation
```json
{
  "action": "add_window",
  "windowType": "image",
  "windowId": "digital_signage",
  "title": "Store Promotions",
  "urls": [
    "https://mystore.com/promotion1.jpg",
    "https://mystore.com/promotion2.jpg",
    "https://mystore.com/promotion3.jpg",
    "https://mystore.com/sale_banner.jpg"
  ]
}
```

### Art Gallery Display
```json
{
  "action": "add_window",
  "windowType": "image",
  "windowId": "art_gallery",
  "title": "Featured Artworks",
  "urls": [
    "https://gallery.com/artwork1.jpg",
    "https://gallery.com/artwork2.jpg",
    "https://gallery.com/artwork3.jpg"
  ]
}
```

### Menu Display with Rotation
```json
{
  "action": "add_window",
  "windowType": "image",
  "windowId": "restaurant_menu",
  "title": "Today's Menu",
  "urls": [
    "https://restaurant.com/breakfast_menu.jpg",
    "https://restaurant.com/lunch_menu.jpg",
    "https://restaurant.com/dinner_menu.jpg",
    "https://restaurant.com/drinks_menu.jpg"
  ]
}
```

## Advanced Usage

### Conditional Carousel Creation
Create a carousel only if multiple images are provided, otherwise show single image:
```json
{
  "action": "add_window",
  "windowType": "image",
  "windowId": "adaptive_display",
  "title": "Adaptive Image Display",
  "url": "https://example.com/fallback.jpg",
  "urls": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg"
  ]
}
```

### Timed Image Updates
Use MQTT scheduling or external automation to update carousel content:
```json
// Morning images
{
  "action": "window_command",
  "windowId": "daily_rotation",
  "command": "set_images",
  "payload": {
    "urls": [
      "https://example.com/morning1.jpg",
      "https://example.com/morning2.jpg"
    ]
  }
}

// Evening images (sent later)
{
  "action": "window_command",
  "windowId": "daily_rotation",
  "command": "set_images",
  "payload": {
    "urls": [
      "https://example.com/evening1.jpg",
      "https://example.com/evening2.jpg"
    ]
  }
}
```

## Notes

- All image URLs should be publicly accessible
- Supported formats: JPG, PNG, GIF, WebP
- Auto-play intervals are in seconds
- Carousel automatically detects when to switch between single and multi-image mode
- Use the `windowId` to reference specific image windows for updates
- Batch commands are processed sequentially
