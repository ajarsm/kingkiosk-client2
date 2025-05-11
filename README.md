# Flutter GetX Kiosk Application

A multiplatform kiosk application built with Flutter and GetX state management. This application is designed to be used in kiosk mode and supports:

- WebView tiles for displaying web content
- Media tiles for playing video content
- Audio tiles for playing audio content
- Draggable and resizable windows
- Settings with persistent storage
- WebSocket communication
- MediaSoup support for WebRTC
- Platform sensor data collection

## Features

- Fully reactive UI using GetX state management
- Persistent settings using GetStorage
- Tiling window system that allows arranging multiple content windows
- Minimal window decoration for kiosk mode
- Support for WebRTC via MediaSoup
- Platform sensors and device information monitoring
- Dark/light theme support

## Getting Started

### Prerequisites

- Flutter SDK (>=2.12.0)
- Dart SDK (>=2.12.0)
- A development environment for your target platform(s)

### Installation

1. Clone this repository
2. Install dependencies:
```bash
flutter pub get
```
3. Run the application:
```bash
flutter run
```

## Project Structure

- `/lib/app/core`: Core application functionality (bindings, themes)
- `/lib/app/data`: Data models and repositories
- `/lib/app/modules`: Feature modules (splash, home, settings)
- `/lib/app/routes`: App routes and navigation
- `/lib/app/services`: Services (storage, websocket, mediasoup, sensors)
- `/lib/app/widgets`: Reusable widgets

## Usage

1. The app starts with a splash screen
2. The main screen allows adding, arranging and resizing web, video, and audio content
3. Settings screen provides configuration options

## Dependencies

- get: State management, dependency injection, route management
- get_storage: Persistent storage
- webview_all: Web content display
- media_kit: Media playback
- mediasfu_mediasoup_client: WebRTC functionality
- battery_plus, sensors_plus, device_info_plus: Platform sensors and info
- web_socket_channel: WebSocket communication# kingkiosk-client2
