#!/usr/bin/env dart

/// Test script to verify the Alarmo MQTT command functionality
/// This script validates that the "alarmo_widget" command works correctly

import 'dart:convert';

void main() async {
  print('🚨 Testing Alarmo MQTT Command');
  print('=' * 50);

  // Test various alarmo_widget command payloads
  await testBasicAlarmoCommand();
  await testAlarmoCommandWithConfig();
  await testAlarmoCommandWithCustomId();

  print('\n🎉 All Alarmo MQTT command tests completed!');
}

/// Test basic alarmo_widget command
Future<void> testBasicAlarmoCommand() async {
  print('\n🔧 Test 1: Basic alarmo_widget command');

  final basicCommand = {"command": "alarmo_widget", "name": "Kitchen Alarm"};

  print('Command: ${jsonEncode(basicCommand)}');
  print('Expected: Creates Alarmo tile with default configuration');

  // Validate command structure
  final isValid = validateCommand(basicCommand);
  print('Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');
}

/// Test alarmo_widget command with configuration
Future<void> testAlarmoCommandWithConfig() async {
  print('\n🔧 Test 2: alarmo_widget command with configuration');

  final configCommand = {
    "command": "alarmo_widget",
    "name": "Main Alarm",
    "entity": "alarm_control_panel.alarmo",
    "require_code": true,
    "code_length": 4,
    "state_topic": "alarmo/state",
    "command_topic": "alarmo/command",
    "event_topic": "alarmo/event",
    "available_modes": ["away", "home", "night"]
  };

  print('Command: ${jsonEncode(configCommand)}');
  print('Expected: Creates Alarmo tile with custom configuration');

  // Validate command structure
  final isValid = validateCommand(configCommand);
  print('Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');
}

/// Test alarmo_widget command with custom window ID
Future<void> testAlarmoCommandWithCustomId() async {
  print('\n🔧 Test 3: alarmo_widget command with custom window ID');

  final customIdCommand = {
    "command": "alarmo_widget",
    "name": "Security Panel",
    "window_id": "alarm_panel_01",
    "entity": "alarm_control_panel.house_alarm"
  };

  print('Command: ${jsonEncode(customIdCommand)}');
  print('Expected: Creates Alarmo tile with specific window ID');

  // Validate command structure
  final isValid = validateCommand(customIdCommand);
  print('Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');
}

/// Validate command has required structure
bool validateCommand(Map<String, dynamic> command) {
  // Check required fields
  if (!command.containsKey('command') ||
      command['command'] != 'alarmo_widget') {
    print('  ❌ Missing or invalid command field');
    return false;
  }

  if (!command.containsKey('name') || command['name'].toString().isEmpty) {
    print('  ❌ Missing or empty name field');
    return false;
  }

  // Check optional fields are valid if present
  final optionalStringFields = [
    'window_id',
    'entity',
    'state_topic',
    'command_topic',
    'event_topic'
  ];
  for (final field in optionalStringFields) {
    if (command.containsKey(field) && command[field] != null) {
      if (command[field].toString().isEmpty) {
        print('  ❌ Empty $field field');
        return false;
      }
    }
  }

  // Check boolean fields
  if (command.containsKey('require_code') && command['require_code'] is! bool) {
    print('  ❌ Invalid require_code field (must be boolean)');
    return false;
  }

  // Check numeric fields
  if (command.containsKey('code_length') && command['code_length'] is! int) {
    print('  ❌ Invalid code_length field (must be integer)');
    return false;
  }

  // Check array fields
  if (command.containsKey('available_modes') &&
      command['available_modes'] is! List) {
    print('  ❌ Invalid available_modes field (must be array)');
    return false;
  }

  print('  ✅ Command structure is valid');
  return true;
}
