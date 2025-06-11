import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/calendar_controller.dart';
import '../models/calendar_event.dart';

/// GetX-based Calendar View Widget
/// Reactive calendar widget that responds to MQTT commands
class CalendarView extends GetView<CalendarController> {
  const CalendarView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: controller.isVisible.value ? null : 0,
          child: controller.isVisible.value
              ? Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalendarHeader(),
                          const SizedBox(height: 16),
                          _buildCalendar(),
                          const SizedBox(height: 16),
                          _buildCalendarFooter(),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ));
  }

  /// Build calendar header with title and controls
  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(() => Text(
              controller.calendarTitle.value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: controller.goToToday,
              tooltip: 'Go to Today',
            ),
            Obx(() => IconButton(
                  icon: Icon(
                      controller.calendarFormat.value == CalendarFormat.month
                          ? Icons.view_week
                          : Icons.view_module),
                  onPressed: _toggleCalendarFormat,
                  tooltip: 'Toggle Format',
                )),
          ],
        ),
      ],
    );
  }

  /// Build the main calendar widget
  Widget _buildCalendar() {
    return Obx(() => TableCalendar<CalendarEvent>(
          firstDay: CalendarController.kFirstDay,
          lastDay: CalendarController.kLastDay,
          focusedDay: controller.focusedDay.value,
          calendarFormat: controller.calendarFormat.value,
          eventLoader: controller.getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: _getCalendarStyle(),
          headerStyle: _getHeaderStyle(),
          availableGestures: AvailableGestures.all,
          selectedDayPredicate: (day) {
            return controller.isDaySelected(day);
          },
          onDaySelected: controller.onDaySelected,
          onFormatChanged: controller.onFormatChanged,
          onPageChanged: controller.onPageChanged,
          calendarBuilders: _getCalendarBuilders(),
        ));
  }

  /// Build calendar footer with selected date info
  Widget _buildCalendarFooter() {
    return Obx(() {
      final selectedDay = controller.selectedDay.value;
      if (selectedDay == null) return const SizedBox.shrink();

      final events = controller.getEventsForDay(selectedDay);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Get.theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected: ${_formatDate(selectedDay)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Events (${events.length}):',
                style: TextStyle(
                  color: Get.theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              ...events
                  .map((event) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Get.theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Get.theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Tooltip(
                                        message:
                                            'Event ID: ${event.id}\nUse this ID for MQTT commands',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Get
                                                .theme.colorScheme.secondary
                                                .withValues(alpha: 0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'ID: ${event.id.substring(0, 8)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Get.theme.colorScheme
                                                  .onSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (event.description != null &&
                                      event.description!.isNotEmpty)
                                    Text(
                                      event.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Get.theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  controller.removeEventById(event.id),
                              icon: const Icon(Icons.close, size: 16),
                              tooltip: 'Remove this event',
                              constraints: const BoxConstraints.tightFor(
                                  width: 32, height: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddEventDialog(selectedDay),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                if (events.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => controller.removeEvent(selectedDay),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Get calendar style configuration
  CalendarStyle _getCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      selectedDecoration: BoxDecoration(
        color: Get.theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Get.theme.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      markerDecoration: BoxDecoration(
        color: Get.theme.colorScheme.tertiary,
        shape: BoxShape.circle,
      ),
      weekendTextStyle: TextStyle(
        color: Get.theme.colorScheme.error,
      ),
    );
  }

  /// Get header style configuration
  HeaderStyle _getHeaderStyle() {
    return const HeaderStyle(
      formatButtonVisible: false,
      titleCentered: true,
      formatButtonShowsNext: false,
    );
  }

  /// Get calendar builders for custom day widgets
  CalendarBuilders<CalendarEvent> _getCalendarBuilders() {
    return CalendarBuilders(
      markerBuilder: (context, date, events) {
        if (events.isNotEmpty) {
          return Positioned(
            bottom: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              width: 16,
              height: 16,
              child: Center(
                child: Text(
                  '${events.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        return null;
      },
    );
  }

  /// Toggle calendar format between month and week
  void _toggleCalendarFormat() {
    final currentFormat = controller.calendarFormat.value;
    if (currentFormat == CalendarFormat.month) {
      controller.onFormatChanged(CalendarFormat.week);
    } else {
      controller.onFormatChanged(CalendarFormat.month);
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Show dialog to add a new event
  void _showAddEventDialog(DateTime selectedDay) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Add Event for ${_formatDate(selectedDay)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final description = descriptionController.text.trim();
                controller.addEvent(
                  selectedDay,
                  title,
                  description.isEmpty ? null : description,
                );
                Get.back();
              }
            },
            child: const Text('Add Event'),
          ),
        ],
      ),
    );
  }
}

/// Compact Calendar Widget for overlay/popup use
class CompactCalendarView extends GetView<CalendarController> {
  const CompactCalendarView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calendar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Obx(() => TableCalendar<CalendarEvent>(
                    firstDay: CalendarController.kFirstDay,
                    lastDay: CalendarController.kLastDay,
                    focusedDay: controller.focusedDay.value,
                    calendarFormat: CalendarFormat.month,
                    eventLoader: controller.getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: _getCompactCalendarStyle(),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    selectedDayPredicate: (day) {
                      return controller.isDaySelected(day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      controller.onDaySelected(selectedDay, focusedDay);
                      Get.back(); // Close dialog after selection
                    },
                    onPageChanged: controller.onPageChanged,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  CalendarStyle _getCompactCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      selectedDecoration: BoxDecoration(
        color: Get.theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Get.theme.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      markerDecoration: BoxDecoration(
        color: Get.theme.colorScheme.tertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}
