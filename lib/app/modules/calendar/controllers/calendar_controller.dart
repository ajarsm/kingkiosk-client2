import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

/// GetX Controller for calendar functionality
/// Provides reactive calendar state management without setState
class CalendarController extends GetxController {
  // Observable calendar state
  final Rx<CalendarFormat> calendarFormat = CalendarFormat.month.obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime?> selectedDay = Rx<DateTime?>(null);
  final RxList<DateTime> events = <DateTime>[].obs;

  // Calendar range constants
  static final DateTime kFirstDay = DateTime(DateTime.now().year - 2, 1, 1);
  static final DateTime kLastDay = DateTime(DateTime.now().year + 2, 12, 31);

  // Calendar display options
  final RxBool isVisible = false.obs;
  final RxString calendarTitle = 'Calendar'.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with today as selected day
    selectedDay.value = DateTime.now();
    focusedDay.value = DateTime.now();

    // Add some sample events
    _initializeSampleEvents();

    print('📅 Calendar controller initialized');
  }

  /// Initialize with some sample events
  void _initializeSampleEvents() {
    final today = DateTime.now();
    events.addAll([
      today,
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 3)),
      today.add(const Duration(days: 7)),
    ]);
  }

  /// Check if a day is selected
  bool isDaySelected(DateTime day) {
    return isSameDay(selectedDay.value, day);
  }

  /// Handle day selection
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(this.selectedDay.value, selectedDay)) {
      this.selectedDay.value = selectedDay;
      this.focusedDay.value = focusedDay;

      print('📅 Day selected: ${selectedDay.toLocal()}');

      // Trigger any additional actions when day is selected
      _onDaySelectedActions(selectedDay);
    }
  }

  /// Handle calendar format changes
  void onFormatChanged(CalendarFormat format) {
    if (calendarFormat.value != format) {
      calendarFormat.value = format;
      print('📅 Calendar format changed to: $format');
    }
  }

  /// Handle page/month changes
  void onPageChanged(DateTime focusedDay) {
    this.focusedDay.value = focusedDay;
    print(
        '📅 Calendar page changed to: ${focusedDay.month}/${focusedDay.year}');
  }

  /// Get events for a specific day
  List<DateTime> getEventsForDay(DateTime day) {
    return events.where((event) => isSameDay(event, day)).toList();
  }

  /// Add event to a specific day
  void addEvent(DateTime day, [String? eventTitle]) {
    if (!events.any((event) => isSameDay(event, day))) {
      events.add(day);
      print('📅 Event added for: ${day.toLocal()}');
    }
  }

  /// Remove event from a specific day
  void removeEvent(DateTime day) {
    events.removeWhere((event) => isSameDay(event, day));
    print('📅 Event removed for: ${day.toLocal()}');
  }

  /// Show calendar
  void showCalendar() {
    isVisible.value = true;
    print('📅 Calendar shown');
  }

  /// Hide calendar
  void hideCalendar() {
    isVisible.value = false;
    print('📅 Calendar hidden');
  }

  /// Toggle calendar visibility
  void toggleCalendar() {
    isVisible.value = !isVisible.value;
    print('📅 Calendar toggled: ${isVisible.value ? 'shown' : 'hidden'}');
  }

  /// Navigate to today
  void goToToday() {
    final today = DateTime.now();
    selectedDay.value = today;
    focusedDay.value = today;
    print('📅 Navigated to today');
  }

  /// Navigate to specific date
  void goToDate(DateTime date) {
    selectedDay.value = date;
    focusedDay.value = date;
    print('📅 Navigated to: ${date.toLocal()}');
  }

  /// Actions to perform when a day is selected
  void _onDaySelectedActions(DateTime selectedDay) {
    // Check if the selected day has events
    final dayEvents = getEventsForDay(selectedDay);
    if (dayEvents.isNotEmpty) {
      print('📅 Selected day has ${dayEvents.length} event(s)');

      // Could trigger notifications or other actions here
      Get.snackbar(
        'Calendar',
        'Selected date has ${dayEvents.length} event(s)',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Handle MQTT calendar commands
  void handleMqttCalendarCommand(Map<String, dynamic> command) {
    try {
      final action = command['action'] as String?;

      switch (action) {
        case 'show':
          showCalendar();
          break;

        case 'hide':
          hideCalendar();
          break;

        case 'toggle':
          toggleCalendar();
          break;

        case 'today':
          goToToday();
          showCalendar();
          break;

        case 'goto':
          final dateStr = command['date'] as String?;
          if (dateStr != null) {
            try {
              final date = DateTime.parse(dateStr);
              goToDate(date);
              showCalendar();
            } catch (e) {
              print('❌ Invalid date format in calendar command: $dateStr');
            }
          }
          break;

        case 'add_event':
          final dateStr = command['date'] as String?;
          if (dateStr != null) {
            try {
              final date = DateTime.parse(dateStr);
              addEvent(date);
            } catch (e) {
              print('❌ Invalid date format for add_event: $dateStr');
            }
          }
          break;

        case 'remove_event':
          final dateStr = command['date'] as String?;
          if (dateStr != null) {
            try {
              final date = DateTime.parse(dateStr);
              removeEvent(date);
            } catch (e) {
              print('❌ Invalid date format for remove_event: $dateStr');
            }
          }
          break;

        case 'format':
          final formatStr = command['format'] as String?;
          if (formatStr != null) {
            CalendarFormat? format;
            switch (formatStr.toLowerCase()) {
              case 'month':
                format = CalendarFormat.month;
                break;
              case 'week':
                format = CalendarFormat.week;
                break;
              case 'twoweeks':
              case 'two_weeks':
                format = CalendarFormat.twoWeeks;
                break;
            }
            if (format != null) {
              onFormatChanged(format);
            }
          }
          break;

        default:
          print('❌ Unknown calendar command action: $action');
      }

      print('📅 MQTT calendar command processed: $action');
    } catch (e) {
      print('❌ Error processing MQTT calendar command: $e');
    }
  }

  /// Get calendar status for MQTT reporting
  Map<String, dynamic> getCalendarStatus() {
    return {
      'visible': isVisible.value,
      'selected_date': selectedDay.value?.toIso8601String(),
      'focused_date': focusedDay.value.toIso8601String(),
      'format': calendarFormat.value.toString().split('.').last,
      'events_count': events.length,
    };
  }
}
