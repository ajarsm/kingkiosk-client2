#!/usr/bin/env dart

/// Quick script to demonstrate how to open Alarmo widgets
/// This shows the different ways you can create Alarmo tiles

void main() {
  print('🚨 Alarmo Widget Usage Examples');
  print('=' * 50);

  printMqttExamples();
  printProgrammaticExamples();
  printAutomationExamples();

  print('\n✨ Choose the method that works best for your setup!');
}

void printMqttExamples() {
  print('\n📡 MQTT Command Examples');
  print('-' * 30);

  print('\n1. Basic Alarmo Widget:');
  print('Topic: kingkiosk/YOUR_DEVICE_NAME/command');
  print('Payload:');
  print('''
{
  "command": "alarmo_widget",
  "name": "Main Alarm"
}''');

  print('\n2. Advanced Configuration:');
  print('Payload:');
  print('''
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
}''');

  print('\n3. mosquitto_pub command:');
  print('''mosquitto_pub -h YOUR_MQTT_BROKER \\
  -t "kingkiosk/YOUR_DEVICE_NAME/command" \\
  -m '{"command": "alarmo_widget", "name": "Security Panel"}\'''');
}

void printProgrammaticExamples() {
  print('\n💻 Programmatic Examples (Dart/Flutter)');
  print('-' * 40);

  print('\n1. Basic tile creation:');
  print('''
final controller = Get.find<TilingWindowController>();
controller.addAlarmoTile("Security Panel");''');

  print('\n2. With custom configuration:');
  print('''
controller.addAlarmoTile("Main Alarm", config: {
  "entity": "alarm_control_panel.house_alarm",
  "require_code": true,
  "code_length": 6,
  "available_modes": ["away", "home"]
});''');

  print('\n3. With specific window ID:');
  print('''
controller.addAlarmoTileWithId("alarm_01", "Front Door", config: {
  "entity": "alarm_control_panel.front_door"
});''');
}

void printAutomationExamples() {
  print('\n🏠 Home Assistant Automation');
  print('-' * 35);

  print('\nautomation.yaml:');
  print('''
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
          }''');

  print('\n📱 Developer Tools > Services:');
  print('Service: mqtt.publish');
  print('Service data:');
  print('''
topic: kingkiosk/YOUR_DEVICE_NAME/command
payload: '{"command": "alarmo_widget", "name": "Alarm Control"}\'''');
}
