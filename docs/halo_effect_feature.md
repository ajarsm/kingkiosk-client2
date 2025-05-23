# Halo Effect Feature Documentation

## Overview
The Halo Effect feature provides a visual status indicator for the KingKiosk application by displaying a colored gradient around the edges of the screen. This feature is particularly useful for displaying system states like alarm status (armed/disarmed), away mode, or alerts.

## Features
- **Color Customization**: Any hex color can be specified
- **Animated Effects**: Smooth fade in/out and optional pulsing animations
- **Responsive Design**: Works on all screen sizes and orientations
- **Non-intrusive**: The gradient appears only at the edges, preserving main content visibility
- **MQTT Control**: Controlled via standard MQTT command interface

## MQTT Command Interface

### Command Format
```json
{
  "command": "halo_effect",
  "color": "#FF0000",      // Hex color code (required when enabled=true)
  "enabled": true,         // Toggle the effect on/off (defaults to true)
  "width": 60,             // Optional: controls how far the gradient extends inward (in pixels)
  "intensity": 0.7,        // Optional: controls opacity/intensity (0.0-1.0)
  "pulse_mode": "none",    // Optional: "none", "gentle", "moderate", or "alert"
  "pulse_duration": 2000,  // Optional: pulse animation cycle length in milliseconds
  "fade_in_duration": 800, // Optional: fade in animation duration in milliseconds
  "fade_out_duration": 1000 // Optional: fade out animation duration in milliseconds
}
```

### Example Commands

#### Basic Red Halo (Alarm Armed)
```json
{
  "command": "halo_effect",
  "color": "#FF0000",
  "enabled": true
}
```

#### Green Gentle Pulse (Alarm Disarmed)
```json
{
  "command": "halo_effect",
  "color": "#00FF00",
  "enabled": true,
  "pulse_mode": "gentle",
  "pulse_duration": 4000
}
```

#### Red Alert Flash (Alarm Triggered)
```json
{
  "command": "halo_effect",
  "color": "#FF0000",
  "enabled": true,
  "pulse_mode": "alert",
  "pulse_duration": 1000,
  "intensity": 0.9
}
```

#### Blue Away Mode
```json
{
  "command": "halo_effect",
  "color": "#0066FF",
  "enabled": true,
  "intensity": 0.6
}
```

#### Purple Night Mode
```json
{
  "command": "halo_effect",
  "color": "#9900FF",
  "enabled": true,
  "intensity": 0.5
}
```

#### Disable Halo Effect
```json
{
  "command": "halo_effect",
  "enabled": false
}
```

## Home Assistant Integration

### Example Automations

#### Arm Alarm Automation
```yaml
automation:
  - alias: Alarm Armed - Show Red Halo
    trigger:
      platform: state
      entity_id: alarm_control_panel.home_alarm
      to: 'armed_away'
    action:
      - service: mqtt.publish
        data:
          topic: kingkiosk/command
          payload: '{"command":"halo_effect", "color":"#FF0000", "enabled":true}'
```

#### Disarm Alarm Automation
```yaml
automation:
  - alias: Alarm Disarmed - Show Green Halo
    trigger:
      platform: state
      entity_id: alarm_control_panel.home_alarm
      to: 'disarmed'
    action:
      - service: mqtt.publish
        data:
          topic: kingkiosk/command
          payload: '{"command":"halo_effect", "color":"#00FF00", "enabled":true, "pulse_mode":"gentle", "pulse_duration":4000}'
      # Optional: Turn off the halo effect after 30 seconds
      - delay: '00:00:30'
      - service: mqtt.publish
        data:
          topic: kingkiosk/command
          payload: '{"command":"halo_effect", "enabled":false}'
```

#### Alarm Triggered Automation
```yaml
automation:
  - alias: Alarm Triggered - Show Flashing Red Halo
    trigger:
      platform: state
      entity_id: alarm_control_panel.home_alarm
      to: 'triggered'
    action:
      - service: mqtt.publish
        data:
          topic: kingkiosk/command
          payload: '{"command":"halo_effect", "color":"#FF0000", "enabled":true, "pulse_mode":"alert", "pulse_duration":1000, "intensity":0.9}'
```

## Implementation Technical Details

The Halo Effect feature is implemented using the following components:

1. **AnimatedHaloEffect Widget**: A custom widget that renders the gradient border and manages animations
2. **HaloEffectController**: A GetX controller to manage the state of the halo effect
3. **MQTT Command Handler**: Processes incoming MQTT commands to control the halo effect
4. **Custom Painter**: Renders the gradient effect around the screen edges

## Testing

A test script is provided to verify functionality:
```bash
./test_halo_effect.sh
```

This script sends various MQTT commands to demonstrate different halo effects.
