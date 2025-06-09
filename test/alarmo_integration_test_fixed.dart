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
      // Build the widget
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: AlarmoWidget(windowId: 'test_alarm'),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(AlarmoWidget), findsOneWidget);

      // Check for key UI elements
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

      // Test backspace (removeDigit is the actual method name)
      controller.removeDigit();
      expect(controller.enteredCode, '12');

      controller.removeDigit();
      expect(controller.enteredCode, '1');

      controller.removeDigit();
      expect(controller.enteredCode, '');
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

      // Test mode selection (setArmMode is the actual method name)
      controller.setArmMode(AlarmoArmMode.home);
      expect(controller.selectedArmMode, AlarmoArmMode.home);

      controller.setArmMode(AlarmoArmMode.night);
      expect(controller.selectedArmMode, AlarmoArmMode.night);

      controller.setArmMode(AlarmoArmMode.away);
      expect(controller.selectedArmMode, AlarmoArmMode.away);
    });

    test('AlarmoWindowController should format display states correctly', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test display state formatting (getStateDisplayText is the actual method name)
      expect(controller.getStateDisplayText(), 'DISARMED');
    });

    test('AlarmoWindowController should format arm mode display correctly', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test arm mode display formatting
      expect(controller.getArmModeDisplayText(AlarmoArmMode.away), 'Away');
      expect(controller.getArmModeDisplayText(AlarmoArmMode.home), 'Home');
      expect(controller.getArmModeDisplayText(AlarmoArmMode.night), 'Night');
      expect(
          controller.getArmModeDisplayText(AlarmoArmMode.vacation), 'Vacation');
      expect(controller.getArmModeDisplayText(AlarmoArmMode.custom), 'Custom');
    });

    test('AlarmoWindowController should provide correct state colors', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test state color mapping
      expect(
          controller.getStateColor(), Colors.green); // Default disarmed state
    });

    test('AlarmoWindowController should provide correct arm mode icons', () {
      final controller = AlarmoWindowController(windowName: 'test_alarm');

      // Test arm mode icon mapping
      expect(
          controller.getArmModeIcon(AlarmoArmMode.away), Icons.home_outlined);
      expect(controller.getArmModeIcon(AlarmoArmMode.home), Icons.home);
      expect(controller.getArmModeIcon(AlarmoArmMode.night), Icons.bedtime);
      expect(controller.getArmModeIcon(AlarmoArmMode.vacation), Icons.luggage);
      expect(controller.getArmModeIcon(AlarmoArmMode.custom), Icons.tune);
    });
  });
}
