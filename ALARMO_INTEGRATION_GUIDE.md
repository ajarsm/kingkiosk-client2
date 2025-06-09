# Alarmo Integration Documentation

## Overview

The Alarmo integration provides a native Flutter dialpad widget for controlling the Home Assistant Alarmo addon via MQTT. This implementation mimics the Home Assistant Alarmo keypad interface, displaying alarm states and allowing users to arm/disarm the system.

## Components

### 1. AlarmoWindowController
**File:** `lib/app/modules/home/controllers/alarmo_window_controller.dart`

- **Purpose:** Manages MQTT communication and state for Alarmo controls
- **Features:**
  - MQTT subscription to Alarmo state and event topics
  - Command publishing for arm/disarm operations  
  - Reactive state management with GetX
  - Support for multiple arm modes (away, home, night, vacation, custom)
  - PIN code validation and entry management
  - Error handling and timeout management

### 2. AlarmoWidget
**File:** `lib/app/modules/home/widgets/alarmo_widget.dart`

- **Purpose:** Native Flutter UI for the Alarmo dialpad
- **Features:**
  - Number pad keyboard using `number_pad_keyboard` package
  - Real-time state display with color coding
  - ARM mode selection interface  
  - PIN code entry visualization
  - Error message display
  - Responsive design for low-end devices

### 3. Integration Components

#### WindowTile Model Extension
**File:** `lib/app/data/models/window_tile_v2.dart`
- Added `TileType.alarmo` enum value

#### TilingWindowController Extension  
**File:** `lib/app/modules/home/controllers/tiling_window_controller.dart`
- Added `addAlarmoTile(String name, {Map<String, dynamic>? config})` method
- Added `addAlarmoTileWithId(String id, String name, {Map<String, dynamic>? config})` method

#### TilingWindowView Integration
**File:** `lib/app/modules/home/views/tiling_window_view.dart`
- Added case handling for `TileType.alarmo` in tile content rendering
- Integrated AlarmoWidget into the tiling system

## Configuration

### Default MQTT Topics
- **State Topic:** `alarmo/state` - Receives current alarm state
- **Command Topic:** `alarmo/command` - Sends arm/disarm commands  
- **Event Topic:** `alarmo/event` - Receives event notifications

### Supported Alarm States
- `disarmed` - System is disarmed
- `arming` - System is in arming countdown
- `armed_away` - Armed in away mode
- `armed_home` - Armed in home mode  
- `armed_night` - Armed in night mode
- `armed_vacation` - Armed in vacation mode
- `armed_custom_bypass` - Armed with custom bypass
- `pending` - Pending disarm (entry delay)
- `triggered` - Alarm has been triggered
- `unavailable` - System unavailable

### Supported Arm Modes
- **Away:** Full protection when nobody is home
- **Home:** Partial protection when people are home
- **Night:** Night-time protection mode
- **Vacation:** Extended away mode for vacations
- **Custom:** User-defined custom mode

## Usage

There are several ways to open/create an Alarmo widget:

### Method 1: Via MQTT Command (Recommended)

Send an MQTT message to your app's command topic (usually `kingkiosk/device_name/command`):

**Basic Alarmo Widget:**
```json
{
  "command": "alarmo_widget",
  "name": "Main Alarm"
}
```

**Advanced Configuration:**
```json
{
  "command": "alarmo_widget", 
  "name": "Kitchen Alarm",
  "window_id": "alarm_kitchen_01",
  "entity": "alarm_control_panel.alarmo",
  "require_code": true,
  "code_length": 4,
  "state_topic": "alarmo/state",
  "command_topic": "alarmo/command",
  "event_topic": "alarmo/event", 
  "available_modes": ["away", "home", "night"]
}
```

### Method 2: Programmatically via TilingWindowController

```dart
// Get the tiling window controller
final controller = Get.find<TilingWindowController>();

// Add basic Alarmo tile
controller.addAlarmoTile("Security Panel");

// Add with custom configuration
controller.addAlarmoTile("Main Alarm", config: {
  "entity": "alarm_control_panel.house_alarm",
  "require_code": true,
  "code_length": 6,
  "available_modes": ["away", "home"]
});

// Add with specific window ID
controller.addAlarmoTileWithId("alarm_01", "Front Door Alarm", config: {
  "entity": "alarm_control_panel.front_door"
});
```

### Method 3: Via Home Assistant Automation

Create an automation in Home Assistant that sends the MQTT command:

```yaml
# automation.yaml
- alias: "Open Alarmo Widget on Kiosk"
  trigger:
    - platform: state
      entity_id: input_boolean.show_alarm_keypad
      to: 'on'
  action:
    - service: mqtt.publish
      data:
        topic: "kingkiosk/YOUR_DEVICE_NAME/command"
        payload: |
          {
            "command": "alarmo_widget",
            "name": "Security Keypad",
            "entity": "alarm_control_panel.alarmo"
          }
```

### Method 4: Via Node-RED Flow

```json
[
    {
        "id": "alarmo_widget_trigger",
        "type": "inject",
        "name": "Open Alarmo Widget",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "{\"command\":\"alarmo_widget\",\"name\":\"Alarm Control\"}",
        "payloadType": "json",
        "x": 160,
        "y": 100,
        "wires": [
            [
                "mqtt_publish_alarmo"
            ]
        ]
    },
    {
        "id": "mqtt_publish_alarmo", 
        "type": "mqtt out",
        "name": "Send to Kiosk",
        "topic": "kingkiosk/YOUR_DEVICE_NAME/command",
        "qos": "",
        "retain": "",
        "respTopic": "",
        "contentType": "",
        "userProps": "",
        "correl": "",
        "expiry": "",
        "broker": "your_mqtt_broker",
        "x": 400,
        "y": 100,
        "wires": []
    }
]
```

### Quick Test Commands

You can test the widget using any MQTT client:

**mosquitto_pub:**
```bash
mosquitto_pub -h YOUR_MQTT_BROKER -t "kingkiosk/YOUR_DEVICE_NAME/command" -m '{"command": "alarmo_widget", "name": "Test Alarm"}'
```

**MQTT Explorer:**
1. Connect to your MQTT broker
2. Navigate to `kingkiosk/YOUR_DEVICE_NAME/command`
3. Publish the JSON payload

**Home Assistant Developer Tools:**
1. Go to Developer Tools > Services
2. Select `mqtt.publish`
3. Use this service data:
```yaml
topic: kingkiosk/YOUR_DEVICE_NAME/command
payload: '{"command": "alarmo_widget", "name": "Security Panel"}'
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `entity` | String | `'alarm_control_panel.alarmo'` | Home Assistant entity ID |
| `require_code` | bool | `true` | Whether PIN code is required |
| `code_length` | int | `4` | Length of PIN code |
| `state_topic` | String | `'alarmo/state'` | MQTT state topic |
| `command_topic` | String | `'alarmo/command'` | MQTT command topic |
| `event_topic` | String | `'alarmo/event'` | MQTT event topic |
| `available_modes` | List<String> | `['away', 'home', 'night', 'vacation', 'custom']` | Available arm modes |

### MQTT Command Format

**Arm Command:**
```json
{
  "command": "arm_away",
  "code": "1234"
}
```

**Disarm Command:**
```json
{
  "command": "disarm",
  "code": "1234"  
}
```

### State Display Colors
- **Green:** Disarmed
- **Orange:** Arming/Pending
- **Red:** Armed states
- **Dark Red:** Triggered
- **Grey:** Unavailable

## Home Assistant Setup

### 1. Install Alarmo Addon
1. Go to Home Assistant > Add-ons > Add-on Store
2. Search for "Alarmo" and install
3. Configure areas, sensors, and users

### 2. Configure MQTT
Ensure MQTT integration is set up in Home Assistant:
```yaml
# configuration.yaml
mqtt:
  broker: YOUR_MQTT_BROKER_IP
  port: 1883
  username: YOUR_USERNAME
  password: YOUR_PASSWORD
```

### 3. Alarmo MQTT Configuration
In Alarmo settings, enable MQTT and configure:
- **State Topic:** `alarmo/state`
- **Command Topic:** `alarmo/command`
- **Event Topic:** `alarmo/event`

## Troubleshooting

### Common Issues

1. **No State Updates**
   - Verify MQTT broker connection
   - Check Alarmo MQTT configuration
   - Ensure state topic is correct

2. **Commands Not Working**
   - Verify command topic configuration
   - Check PIN code requirements
   - Ensure proper JSON format in commands

3. **Widget Not Responding**
   - Check AlarmoWindowController is properly registered
   - Verify GetX controller lifecycle
   - Check for any console errors

### Debug Commands

```dart
// Check controller registration
final controller = Get.find<AlarmoWindowController>(tag: "alarm1");
print('Controller state: ${controller.currentState}');

// Manually test MQTT publishing
final mqttService = Get.find<MqttService>();
mqttService.publishJsonToTopic('alarmo/command', {
  'command': 'disarm',
  'code': '1234'
});
```

## Dependencies

- **GetX:** State management and dependency injection
- **number_pad_keyboard:** PIN entry interface
- **MQTT Service:** Communication with Home Assistant

## Performance Optimizations

- Uses GetX reactive programming for efficient UI updates
- Minimal MQTT subscriptions to reduce network overhead
- Lightweight widget design for low-end device compatibility
- Efficient state management with reactive properties

## Security Considerations

- PIN codes are transmitted over MQTT (ensure encrypted connection)
- Use secure MQTT broker with authentication
- Consider VPN for remote access
- Regularly update PIN codes

## Future Enhancements

- Multiple area support
- Sensor status display
- Event history logging
- Voice control integration
- Biometric authentication
- Custom sound notifications
