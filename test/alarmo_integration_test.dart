import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// Import the Alarmo components
import 'package:king_kiosk/app/modules/home/controllers/alarmo_window_controller.dart';
import 'package:king_kiosk/app/modules/home/widgets/alarmo_widget.dart';
import 'package:king_kiosk/app/data/models/window_tile_v2.dart';

void main() {
  group('Alarmo Integration Tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('AlarmoWidget should render without errors',
        (WidgetTester tester) async {
      // Create a mock controller
      final controller = AlarmoWindowController(windowName: 'test_alarm');
      Get.put(controller, tag: 'test_alarm');

      // Build the widget
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: AlarmoWidget(windowName: 'test_alarm'),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(AlarmoWidget), findsOneWidget);

      // Check for key UI elements - might need to adjust based on actual implementation
      expect(find.byType(Container),
          findsWidgets); // Should have containers for layout
    });

    test('AlarmoWindowController should initialize with correct defaults', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Check default values
      expect(controller.currentState, AlarmoState.disarmed);
      expect(controller.enteredCode, '');
      expect(controller.selectedArmMode, AlarmoArmMode.away);
      expect(controller.errorMessage, null);
      expect(controller.isLoading, false);
    });

    test('AlarmoWindowController should handle PIN entry correctly', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test PIN entry
      controller.addDigit(1);
      expect(controller.enteredCode, '1');

      controller.addDigit(2);
      controller.addDigit(3);
      controller.addDigit(4);
      expect(controller.enteredCode, '1234');

      // Test clear
      controller.clearCode();
      expect(controller.enteredCode, '');
    });

    test('AlarmoWindowController should handle backspace correctly', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Add some digits
      controller.addDigit(1);
      controller.addDigit(2);
      controller.addDigit(3);
      expect(controller.enteredCode, '123');

      // Test backspace
      controller.removeLastDigit();
      expect(controller.enteredCode, '12');

      controller.removeLastDigit();
      expect(controller.enteredCode, '1');

      controller.removeLastDigit();
      expect(controller.enteredCode, '');
    });

    test('AlarmoWindowController should validate state changes', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test state updates
      controller.updateState(AlarmoState.armed_away);
      expect(controller.currentState, AlarmoState.armed_away);

      controller.updateState(AlarmoState.armed_home);
      expect(controller.currentState, AlarmoState.armed_home);

      controller.updateState(AlarmoState.disarmed);
      expect(controller.currentState, AlarmoState.disarmed);

      controller.updateState(AlarmoState.pending);
      expect(controller.currentState, AlarmoState.pending);

      controller.updateState(AlarmoState.triggered);
      expect(controller.currentState, AlarmoState.triggered);
    });

    test('WindowTile should support alarmo type', () {
      final tile = WindowTile(
        id: 'alarmo_tile_1',
        name: 'Test Alarmo',
        type: TileType.alarmo,
        url: '', // Not used for alarmo tiles
        position: const Offset(0, 0),
        size: const Size(300, 400),
      );

      expect(tile.type, TileType.alarmo);
      expect(tile.name, 'Test Alarmo');
      expect(tile.id, 'alarmo_tile_1');
    });

    test('AlarmoWindowController should handle mode selection', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test mode selection
      controller.selectArmMode(AlarmoArmMode.home);
      expect(controller.selectedArmMode, AlarmoArmMode.home);

      controller.selectArmMode(AlarmoArmMode.night);
      expect(controller.selectedArmMode, AlarmoArmMode.night);

      controller.selectArmMode(AlarmoArmMode.away);
      expect(controller.selectedArmMode, AlarmoArmMode.away);
    });

    test('AlarmoWindowController should format display states correctly', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test display state formatting
      expect(controller.getDisplayState(AlarmoState.disarmed), 'Disarmed');
      expect(controller.getDisplayState(AlarmoState.armed_away), 'Armed Away');
      expect(controller.getDisplayState(AlarmoState.armed_home), 'Armed Home');
      expect(
          controller.getDisplayState(AlarmoState.armed_night), 'Armed Night');
      expect(controller.getDisplayState(AlarmoState.pending), 'Pending');
      expect(controller.getDisplayState(AlarmoState.arming), 'Arming');
      expect(controller.getDisplayState(AlarmoState.triggered), 'Triggered');
    });
  });
}
