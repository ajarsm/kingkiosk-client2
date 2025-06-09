#!/usr/bin/env dart

/// Diagnostic script to help troubleshoot Alarmo MQTT connectivity
/// This will help identify why the ARM button isn't working

void main() {
  print('🔧 Alarmo MQTT Connectivity Troubleshooting');
  print('=' * 50);

  printIssueAnalysis();
  printMqttChecklist();
  printHomeAssistantSetup();
  printTestCommands();
  printDebuggingSteps();
}

void printIssueAnalysis() {
  print('\n🚨 Issue Analysis');
  print('-' * 20);
  print('From your screenshot, I can see:');
  print('✅ Alarmo widget is displaying correctly');
  print('✅ Shows "DISARMED" state (so MQTT state updates work)');
  print('✅ Number pad is visible and functional');
  print('❌ ARM button only opens mode selector, doesn\'t actually arm');
  print('');
  print('🎯 Root Cause: The ARM command isn\'t reaching Home Assistant');
  print(
      '   This means MQTT command publishing might not be configured correctly.');
}

void printMqttChecklist() {
  print('\n📋 MQTT Configuration Checklist');
  print('-' * 35);
  print('');
  print('1. ✅ App MQTT Connection:');
  print('   - Check your app\'s MQTT broker settings');
  print('   - Verify connection status in app logs');
  print('   - Topic: Should be connected to same broker as HA');
  print('');
  print('2. ✅ Home Assistant MQTT:');
  print('   - MQTT integration installed and configured');
  print('   - Broker accessible from both app and HA');
  print('   - Test with Developer Tools > MQTT');
  print('');
  print('3. ✅ Alarmo MQTT Configuration:');
  print('   - Alarmo addon MQTT settings enabled');
  print('   - Command topic: alarmo/command');
  print('   - State topic: alarmo/state');
  print('   - Event topic: alarmo/event');
}

void printHomeAssistantSetup() {
  print('\n🏠 Home Assistant Alarmo Setup');
  print('-' * 35);
  print('');
  print('1. Install Alarmo Addon:');
  print('   - Supervisor > Add-on Store > Alarmo');
  print('   - Start the addon');
  print('   - Configure at least one area');
  print('');
  print('2. Enable MQTT in Alarmo:');
  print('   - Alarmo > Configuration > MQTT');
  print('   - Enable "Use MQTT"');
  print('   - Command topic: alarmo/command');
  print('   - State topic: alarmo/state');
  print('   - Event topic: alarmo/event');
  print('');
  print('3. Configure Users/Codes:');
  print('   - Alarmo > Users > Add User');
  print('   - Set PIN code (e.g., 1234)');
  print('   - Enable for areas you want to control');
}

void printTestCommands() {
  print('\n🧪 Test Commands');
  print('-' * 20);
  print('');
  print('1. Test MQTT from Home Assistant:');
  print('   Developer Tools > Services > mqtt.publish');
  print('   Service data:');
  print('   topic: alarmo/command');
  print('   payload: \'{"command": "arm_away", "code": "1234"}\'');
  print('');
  print('2. Test from command line (if mosquitto installed):');
  print('   mosquitto_pub -h YOUR_MQTT_BROKER \\');
  print('     -t "alarmo/command" \\');
  print('     -m \'{"command": "arm_away", "code": "1234"}\'');
  print('');
  print('3. Listen to state updates:');
  print('   mosquitto_sub -h YOUR_MQTT_BROKER -t "alarmo/state"');
  print('');
  print('4. Monitor all Alarmo topics:');
  print('   mosquitto_sub -h YOUR_MQTT_BROKER -t "alarmo/#"');
}

void printDebuggingSteps() {
  print('\n🔍 Step-by-Step Debugging');
  print('-' * 30);
  print('');
  print('Step 1: Verify Alarmo is receiving commands');
  print('  - Use HA Developer Tools to send test command');
  print('  - If this works, issue is with app MQTT publishing');
  print('  - If this doesn\'t work, issue is with Alarmo MQTT config');
  print('');
  print('Step 2: Check app MQTT publishing');
  print('  - Look for "Sent arm command:" in app console logs');
  print('  - Monitor MQTT broker for incoming messages');
  print('  - Verify topic names match exactly');
  print('');
  print('Step 3: Verify PIN code');
  print('  - Enter PIN in app: 1234 (or your configured code)');
  print('  - Press ARM button');
  print('  - Select mode from popup');
  print('  - Press ARM again');
  print('');
  print('Step 4: Check MQTT broker logs');
  print('  - Look for connection attempts from app');
  print('  - Check for published messages to alarmo/command');
  print('  - Verify no authentication issues');
  print('');
  print('🎯 Expected Workflow:');
  print('  1. Enter PIN code (e.g., 1234)');
  print('  2. Press ARM button');
  print('  3. Select mode (Away/Home/Night)');
  print('  4. Press ARM button again');
  print('  5. Widget should show "ARMING" then "ARMED AWAY"');
}
