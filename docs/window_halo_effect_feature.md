# Window-Specific Halo Effect Feature

## Overview

The Window-Specific Halo Effect feature extends the original app-wide halo effect to support individual windows. This allows for targeted visual highlighting of specific windows with customizable colors and animations.

## Implementation

The implementation consists of several components:

### 1. WindowHaloController

A GetX controller that manages per-window halo effects. It maintains a map of window IDs to their respective halo effect controllers.

```dart
class WindowHaloController extends GetxController {
  // Map of window IDs to their halo effect controllers
  final _windowControllers = <String, HaloEffectControllerGetx>{}.obs;
  
  // Methods for enabling/disabling halo effects per window
  // ...
}
```

### 2. WindowHaloWrapper

A widget that wraps window content and applies the appropriate halo effect based on the window ID.

```dart
class WindowHaloWrapper extends StatelessWidget {
  final String windowId;
  final Widget child;
  
  // ...
}
```

### 3. MQTT Integration

The MQTT service processes window-specific halo effect commands by checking for a `window_id` parameter:

```json
{
  "command": "halo_effect",
  "window_id": "my_window_1",
  "color": "#FF0000",
  "enabled": true,
  "pulse_mode": "gentle",
  "pulse_duration": 3000
}
```

## Usage

### Basic Window Halo

```json
{
  "command": "halo_effect",
  "window_id": "window_id_here",
  "color": "#0066FF",  // Blue color
  "enabled": true
}
```

### Pulsing Window Halo

```json
{
  "command": "halo_effect",
  "window_id": "window_id_here",
  "color": "#00FF00",  // Green color
  "enabled": true,
  "pulse_mode": "gentle",  // Options: gentle, moderate, alert
  "pulse_duration": 3000  // Duration in milliseconds
}
```

### Disabling a Window Halo

```json
{
  "command": "halo_effect",
  "window_id": "window_id_here",
  "enabled": false
}
```

### App-Wide Halo (Original Behavior)

```json
{
  "command": "halo_effect",
  "color": "#9900FF",  // Purple color
  "enabled": true
}
```

## Testing

Use the provided test script to verify window-specific halo effects:

```bash
./test_window_halo_effect.sh
```

The script creates test windows and applies various halo effects to demonstrate the functionality.

## Benefits

- Draws attention to specific windows
- Can indicate status or alert conditions for individual content
- Provides visual separation in multi-window layouts
- Works alongside the app-wide halo effect
