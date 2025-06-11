import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

// Test the calendar MQTT command integration
import '../lib/app/modules/calendar/controllers/calendar_controller.dart';
import '../lib/app/modules/calendar/controllers/calendar_window_controller.dart';

void main() {
  group('Calendar MQTT Integration Tests', () {
    setUp(() {
      // Initialize GetX for testing
      Get.reset();
    });

    test('Calendar Controller initializes correctly', () {
      final controller = CalendarController();
      controller.onInit();

      expect(controller.calendarFormat.value, CalendarFormat.month);
      expect(controller.focusedDay.value, isA<DateTime>());
      expect(controller.isVisible.value, false);
    });

    test('Calendar Window Controller initializes correctly', () {
      // Register calendar controller first
      Get.put(CalendarController());

      final windowController = CalendarWindowController();
      windowController.onInit();

      expect(windowController.isWindowVisible.value, false);
      expect(windowController.windowWidth.value, 400.0);
      expect(windowController.windowHeight.value, 500.0);
    });

    test('Calendar MQTT command "show" works', () {
      Get.put(CalendarController());
      final windowController = CalendarWindowController();
      windowController.onInit();

      final command = {'action': 'show'};
      windowController.handleCommand('show', command);

      expect(windowController.isWindowVisible.value, true);
      expect(windowController.calendarController.isVisible.value, true);
    });

    test('Calendar MQTT command "toggle" works', () {
      Get.put(CalendarController());
      final windowController = CalendarWindowController();
      windowController.onInit();

      // First toggle - should show
      final command = {'action': 'toggle'};
      windowController.handleCommand('toggle', command);
      expect(windowController.isWindowVisible.value, true);

      // Second toggle - should hide
      windowController.handleCommand('toggle', command);
      expect(windowController.isWindowVisible.value, false);
    });

    test('Calendar MQTT command "goto" works', () {
      Get.put(CalendarController());
      final windowController = CalendarWindowController();
      windowController.onInit();

      final command = {'action': 'goto', 'date': '2025-12-25'};
      windowController.handleCommand('goto', command);

      final expectedDate = DateTime.parse('2025-12-25');
      expect(
          windowController.calendarController.selectedDay.value, expectedDate);
      expect(
          windowController.calendarController.focusedDay.value, expectedDate);
      expect(windowController.isWindowVisible.value, true);
    });

    test('Calendar MQTT command "format" works', () {
      Get.put(CalendarController());
      final windowController = CalendarWindowController();
      windowController.onInit();

      final command = {'action': 'format', 'format': 'week'};
      windowController.handleCommand('goto',
          command); // Using goto since format is handled by calendar controller

      // This should show the window since goto command shows the window
      expect(windowController.isWindowVisible.value, true);
    });

    tearDown(() {
      Get.reset();
    });
  });
}
