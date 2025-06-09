#!/usr/bin/env dart

/// Test script to verify Alarmo integration is working correctly
/// This script checks the key components of the Alarmo implementation

import 'dart:io';

void main() {
  print('🚨 Alarmo Integration Test');
  print('=' * 50);

  // Check if all Alarmo files exist
  final files = [
    'lib/app/modules/home/controllers/alarmo_window_controller.dart',
    'lib/app/modules/home/widgets/alarmo_widget.dart',
    'lib/app/data/models/window_tile_v2.dart',
    'lib/app/modules/home/controllers/tiling_window_controller.dart',
    'lib/app/modules/home/views/tiling_window_view.dart',
  ];

  bool allFilesExist = true;
  print('📁 Checking Alarmo files...');

  for (final file in files) {
    final fileExists = File(file).existsSync();
    final status = fileExists ? '✅' : '❌';
    print('  $status $file');
    if (!fileExists) allFilesExist = false;
  }

  if (!allFilesExist) {
    print('\n❌ Some required files are missing!');
    exit(1);
  }

  print('\n📦 Checking key implementation components...');

  // Check for TileType.alarmo in WindowTile model
  final windowTileContent =
      File('lib/app/data/models/window_tile_v2.dart').readAsStringSync();
  final hasAlarmoTileType = windowTileContent.contains('alarmo');
  print('  ${hasAlarmoTileType ? '✅' : '❌'} TileType.alarmo enum value');

  // Check for AlarmoWindowController import in TilingWindowController
  final tilingControllerContent =
      File('lib/app/modules/home/controllers/tiling_window_controller.dart')
          .readAsStringSync();
  final hasAlarmoImport =
      tilingControllerContent.contains('alarmo_window_controller.dart');
  final hasAddAlarmoTileMethod =
      tilingControllerContent.contains('addAlarmoTile');
  print('  ${hasAlarmoImport ? '✅' : '❌'} AlarmoWindowController import');
  print('  ${hasAddAlarmoTileMethod ? '✅' : '❌'} addAlarmoTile method');

  // Check for AlarmoWidget import and usage in TilingWindowView
  final tilingViewContent =
      File('lib/app/modules/home/views/tiling_window_view.dart')
          .readAsStringSync();
  final hasAlarmoWidgetImport =
      tilingViewContent.contains('alarmo_widget.dart');
  final hasAlarmoCase = tilingViewContent.contains('TileType.alarmo');
  print('  ${hasAlarmoWidgetImport ? '✅' : '❌'} AlarmoWidget import');
  print('  ${hasAlarmoCase ? '✅' : '❌'} TileType.alarmo case handling');

  // Check for MQTT integration in AlarmoWindowController
  final alarmoControllerContent =
      File('lib/app/modules/home/controllers/alarmo_window_controller.dart')
          .readAsStringSync();
  final hasMqttService = alarmoControllerContent.contains('MqttService');
  final hasStateHandling =
      alarmoControllerContent.contains('_handleStateUpdate');
  final hasCommandPublishing =
      alarmoControllerContent.contains('publishJsonToTopic');
  print('  ${hasMqttService ? '✅' : '❌'} MQTT service integration');
  print('  ${hasStateHandling ? '✅' : '❌'} State update handling');
  print('  ${hasCommandPublishing ? '✅' : '❌'} Command publishing');

  // Check for number_pad_keyboard usage in AlarmoWidget
  final alarmoWidgetContent =
      File('lib/app/modules/home/widgets/alarmo_widget.dart')
          .readAsStringSync();
  final hasNumberPadKeyboard =
      alarmoWidgetContent.contains('NumberPadKeyboard');
  final hasGetxObx = alarmoWidgetContent.contains('Obx(');
  print('  ${hasNumberPadKeyboard ? '✅' : '❌'} NumberPadKeyboard usage');
  print('  ${hasGetxObx ? '✅' : '❌'} GetX reactive UI (Obx)');

  print('\n🔧 Implementation Summary:');
  print('  • AlarmoWindowController: MQTT state management & commands');
  print('  • AlarmoWidget: Native dialpad UI with number_pad_keyboard');
  print('  • TileType.alarmo: Added to WindowTile model');
  print('  • Tiling integration: addAlarmoTile methods & tile rendering');
  print('  • Reactive UI: GetX Obx for real-time state updates');

  print('\n📚 Usage Instructions:');
  print('  1. Ensure Home Assistant Alarmo addon is configured');
  print('  2. Set up MQTT broker connection in the app');
  print('  3. Use controller.addAlarmoTile("alarm1") to add an Alarmo tile');
  print('  4. Configure Alarmo topics if different from defaults:');
  print('     - State topic: alarmo/state');
  print('     - Command topic: alarmo/command');
  print('     - Event topic: alarmo/event');

  print('\n🎯 Next Steps:');
  print('  • Test with actual Home Assistant Alarmo instance');
  print('  • Verify MQTT state synchronization');
  print('  • Test arm/disarm functionality with PIN codes');
  print('  • Customize UI theme and layout as needed');

  final allComponentsPresent = allFilesExist &&
      hasAlarmoTileType &&
      hasAlarmoImport &&
      hasAddAlarmoTileMethod &&
      hasAlarmoWidgetImport &&
      hasAlarmoCase &&
      hasMqttService &&
      hasStateHandling &&
      hasCommandPublishing &&
      hasNumberPadKeyboard &&
      hasGetxObx;

  if (allComponentsPresent) {
    print('\n🎉 Alarmo integration is complete and ready for testing!');
    exit(0);
  } else {
    print('\n⚠️  Some components may need attention. Check the details above.');
    exit(1);
  }
}
