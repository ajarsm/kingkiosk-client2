# Calendar MQTT Command Examples

This document demonstrates how to use MQTT commands to control the table_calendar widget in the KingKiosk application.

## Available Calendar Commands

### Basic Calendar Control

#### Show Calendar
```json
{
  "command": "calendar",
  "action": "show"
}
```

#### Hide Calendar
```json
{
  "command": "calendar", 
  "action": "hide"
}
```

#### Toggle Calendar Visibility
```json
{
  "command": "calendar",
  "action": "toggle"
}
```

### Navigation Commands

#### Navigate to Today
```json
{
  "command": "calendar",
  "action": "today"
}
```

#### Navigate to Specific Date
```json
{
  "command": "calendar",
  "action": "goto",
  "date": "2025-12-25"
}
```

### Calendar Format Control

#### Set to Month View
```json
{
  "command": "calendar",
  "action": "format",
  "format": "month"
}
```

#### Set to Week View
```json
{
  "command": "calendar",
  "action": "format", 
  "format": "week"
}
```

#### Set to Two Weeks View
```json
{
  "command": "calendar",
  "action": "format",
  "format": "twoweeks"
}
```

### Event Management

#### Add Event to Date
```json
{
  "command": "calendar",
  "action": "add_event",
  "date": "2025-06-15"
}
```

#### Remove Event from Date
```json
{
  "command": "calendar",
  "action": "remove_event", 
  "date": "2025-06-15"
}
```

### Window Control (for floating calendar)

#### Show Calendar Window
```json
{
  "command": "calendar",
  "action": "show_window"
}
```

#### Hide Calendar Window
```json
{
  "command": "calendar",
  "action": "hide_window" 
}
```

#### Toggle Calendar Window
```json
{
  "command": "calendar",
  "action": "toggle_window"
}
```

#### Set Window Position
```json
{
  "command": "calendar",
  "action": "set_position",
  "x": 100,
  "y": 50
}
```

#### Set Window Size
```json
{
  "command": "calendar",
  "action": "set_size",
  "width": 500,
  "height": 600
}
```

## Testing with MQTT Client

You can test these commands using any MQTT client. For example, with `mosquitto_pub`:

```bash
# Show the calendar
mosquitto_pub -h your-mqtt-broker -t your/command/topic -m '{"command":"calendar","action":"show"}'

# Navigate to Christmas 2025
mosquitto_pub -h your-mqtt-broker -t your/command/topic -m '{"command":"calendar","action":"goto","date":"2025-12-25"}'

# Toggle calendar visibility
mosquitto_pub -h your-mqtt-broker -t your/command/topic -m '{"command":"calendar","action":"toggle"}'
```

## Features

- **Reactive**: All calendar state is managed with GetX, no setState() calls
- **Interactive**: Users can click days, change formats, add/remove events
- **MQTT Controlled**: Full remote control via MQTT commands
- **Floating Window**: Draggable, resizable calendar overlay
- **Event System**: Simple event management for marked dates
- **Multiple Views**: Month, week, and two-weeks formats supported

## Integration

The calendar is integrated into the app as a global overlay that can be shown/hidden anywhere in the application. It uses:

- `CalendarController`: Manages calendar state and logic
- `CalendarWindowController`: Manages floating window behavior  
- `FloatingCalendarWindow`: The actual UI widget overlay
- MQTT integration in `mqtt_service_consolidated.dart`

The calendar is automatically registered in the app's dependency injection system and is available globally throughout the application.
