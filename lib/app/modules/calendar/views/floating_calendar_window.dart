import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/calendar_window_controller.dart';
import '../views/calendar_view.dart';

/// Floating Calendar Window Widget
/// A draggable, resizable calendar window for kiosk displays
class FloatingCalendarWindow extends GetView<CalendarWindowController> {
  const FloatingCalendarWindow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔍 FloatingCalendarWindow build() called');

    return Obx(() {
      final controller = Get.find<CalendarWindowController>();
      print(
          '🔍 FloatingCalendarWindow build: isWindowVisible = ${controller.isWindowVisible.value}');
      print(
          '🔍 FloatingCalendarWindow build: windowX = ${controller.windowX.value}, windowY = ${controller.windowY.value}');

      if (!controller.isWindowVisible.value) {
        print(
            '🔍 FloatingCalendarWindow: Not visible, returning empty container');
        return const SizedBox.shrink();
      }

      print('🔍 FloatingCalendarWindow: Visible, rendering calendar window');

      return Positioned(
        left: controller.windowX.value,
        top: controller.windowY.value,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: controller.windowWidth.value,
            height: controller.windowHeight.value,
            decoration: BoxDecoration(
              color: Colors.red, // Bright red for debugging visibility
              border: Border.all(color: Colors.blue, width: 5), // Blue border
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Debug header
                Container(
                  color: Colors.yellow,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'CALENDAR WINDOW DEBUG',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildWindowHeader(),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: _buildCalendarContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Build draggable window header
  Widget _buildWindowHeader() {
    return GestureDetector(
      onPanUpdate: (details) {
        final newX = controller.windowX.value + details.delta.dx;
        final newY = controller.windowY.value + details.delta.dy;
        controller.updatePosition(newX, newY);
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.calendar_month,
              color: Get.theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Calendar',
                style: TextStyle(
                  color: Get.theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            _buildWindowControls(),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// Build window control buttons
  Widget _buildWindowControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimize button
        IconButton(
          onPressed: controller.hideWindow,
          icon: const Icon(Icons.minimize, size: 16),
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          padding: EdgeInsets.zero,
          tooltip: 'Minimize',
        ),
        // Close button
        IconButton(
          onPressed: controller.hideWindow,
          icon: const Icon(Icons.close, size: 16),
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          padding: EdgeInsets.zero,
          tooltip: 'Close',
        ),
      ],
    );
  }

  /// Build calendar content with resize handle
  Widget _buildCalendarContent() {
    return Stack(
      children: [
        // Main calendar content
        Padding(
          padding: const EdgeInsets.all(12),
          child: CalendarView(),
        ),
        // Resize handle
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newWidth = controller.windowWidth.value + details.delta.dx;
              final newHeight =
                  controller.windowHeight.value + details.delta.dy;
              controller.updateSize(newWidth, newHeight);
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.drag_handle,
                size: 12,
                color: Get.theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Calendar Overlay Widget for full-screen display
class CalendarOverlay extends GetView<CalendarWindowController> {
  const CalendarOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isWindowVisible.value) {
        return const SizedBox.shrink();
      }

      return Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              color: Get.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildOverlayHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CalendarView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOverlayHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(
            Icons.calendar_month,
            color: Get.theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Calendar',
            style: TextStyle(
              color: Get.theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: controller.hideWindow,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
