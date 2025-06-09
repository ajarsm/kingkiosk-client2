import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'lib/app/modules/home/widgets/clock_widget.dart';
import 'lib/app/modules/home/controllers/clock_window_controller.dart';

void main() {
  group('Clock Tile Tests', () {
    late ClockWindowController controller;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      controller = ClockWindowController(windowName: 'test-clock');
      Get.put(controller);
    });

    tearDown(() {
      Get.delete<ClockWindowController>();
    });

    testWidgets('Clock widget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: ClockWidget(
                windowId: 'test-clock',
                showControls: false,
              ),
            ),
          ),
        ),
      );

      // Verify the widget renders without errors
      expect(find.byType(ClockWidget), findsOneWidget);
    });

    test('Clock controller configuration works', () {
      // Test setting network image URL
      controller.configure({
        'network_image_url': 'https://example.com/clock-bg.jpg',
        'show_numbers': true,
        'show_second_hand': false,
        'theme': 'dark'
      });

      expect(controller.networkImageUrl,
          equals('https://example.com/clock-bg.jpg'));
      expect(controller.showNumbers, equals(true));
      expect(controller.showSecondHand, equals(false));
      expect(controller.theme, equals('dark'));
    });

    test('Clock controller visibility works', () {
      expect(controller.isVisible, equals(true));
      expect(controller.isMinimized, equals(false));

      controller.handleCommand('minimize', {});
      expect(controller.isMinimized, equals(true));

      controller.handleCommand('maximize', {});
      expect(controller.isMinimized, equals(false));
    });
  });
}
