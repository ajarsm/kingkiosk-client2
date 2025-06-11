import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../calendar/controllers/calendar_window_controller.dart';
import '../../calendar/views/calendar_view.dart';

/// Calendar widget that displays a calendar with MQTT configuration support
class CalendarWidget extends StatelessWidget {
  final String windowId;
  final bool showControls;
  final VoidCallback? onClose;

  const CalendarWidget({
    Key? key,
    required this.windowId,
    this.showControls = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to get existing controller first, create if not found
    CalendarWindowController controller;
    try {
      controller = Get.find<CalendarWindowController>(tag: windowId);
    } catch (e) {
      // Controller not found, create a new one
      controller = Get.put(
        CalendarWindowController(windowName: windowId),
        tag: windowId,
      );
    }

    return Obx(() {
      if (!controller.isWindowVisible.value) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Window title bar with controls
            if (showControls) _buildTitleBar(context, controller),
            // Calendar content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const CalendarView(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTitleBar(
      BuildContext context, CalendarWindowController controller) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.calendar_today,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Calendar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          // Close button
          if (onClose != null)
            InkWell(
              onTap: onClose,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
