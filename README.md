# KingKiosk Client

A cross-platform Flutter kiosk application for displaying interactive content, media, and web pages via MQTT commands.

## Features

- Interactive tiling window system
- WebView integration for displaying web content
- Media playback (audio, video, images)
- MQTT control system for remote management
- Notification system with audio feedback
- Screenshot functionality
- System control (volume, brightness)
- Cross-platform support (Windows, macOS, Android, iOS)

## Recent Fixes and Improvements

The application has undergone several important fixes and improvements:

1. **WebView Duplicate Loading Fix** - Fixed issue where WebView tiles loaded twice when opened via MQTT commands
2. **Audio Looping Functionality** - Added support for looping audio playback via MQTT commands
3. **Media Kit Migration** - Replaced just_audio with media_kit for better cross-platform audio support
4. **Touch Event Handling** - Fixed issues with web pages not accepting touch/input events
5. **Blue Outline Removal** - Removed unwanted blue outlines around WebView/tile windows

For a detailed list of fixes and improvements, see [FIXES_SUMMARY.md](FIXES_SUMMARY.md).

## Getting Started

### Prerequisites

- Flutter 3.19.0 or higher
- Dart 3.3.0 or higher
- An MQTT broker for remote control (optional)

### Installation

1. Clone the repository
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Run the application:
   ```
   flutter run
   ```

## Documentation

- [Android Build Guide](docs/ANDROID_BUILD_GUIDE.md)
- [WebView Duplicate Fix](webview_duplicate_fix.md)
- [Audio Looping Update](audio_looping_update.md)
