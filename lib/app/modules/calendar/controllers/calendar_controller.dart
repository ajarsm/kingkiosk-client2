import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../services/storage_service.dart';
import '../models/calendar_event.dart';

/// GetX Controller for calendar functionality
/// Provides reactive calendar state management without setState
class CalendarController extends GetxController {
  // Services
  StorageService? _storageService;

  StorageService get storageService {
    _storageService ??= Get.find<StorageService>();
    return _storageService!;
  }

  // Storage keys
  static const String _eventsKey = 'calendar_events';
  static const String _visibilityKey = 'calendar_visibility';
  static const String _titleKey = 'calendar_title';

  // Observable calendar state
  final Rx<CalendarFormat> calendarFormat = CalendarFormat.month.obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime?> selectedDay = Rx<DateTime?>(null);
  final RxList<CalendarEvent> events = <CalendarEvent>[].obs;

  // Calendar range constants
  static final DateTime kFirstDay = DateTime(DateTime.now().year - 2, 1, 1);
  static final DateTime kLastDay = DateTime(DateTime.now().year + 2, 12, 31);

  // Calendar display options
  final RxBool isVisible = false.obs;
  final RxString calendarTitle = 'Calendar'.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      // Initialize with today as selected day
      selectedDay.value = DateTime.now();
      focusedDay.value = DateTime.now();

      // Load persisted state from storage
      _loadStateFromStorage();

      // Load events from storage
      _loadEventsFromStorage();

      print('📅 Calendar controller initialized');
    } catch (e) {
      print('❌ Error initializing calendar controller: $e');
      // Set defaults if initialization fails
      selectedDay.value = DateTime.now();
      focusedDay.value = DateTime.now();
      events.clear();
    }
  }

  /// Load events from storage
  void _loadEventsFromStorage() {
    try {
      final storedEvents = storageService.read<List<dynamic>>(_eventsKey) ?? [];
      events.clear();

      for (final eventData in storedEvents) {
        try {
          if (eventData is Map<String, dynamic>) {
            // New format: CalendarEvent objects
            final event = CalendarEvent.fromJson(eventData);
            events.add(event);
          } else if (eventData is String) {
            // Legacy format: just dates - convert to CalendarEvent
            final eventDate = DateTime.parse(eventData);
            final event = CalendarEvent(
              date: eventDate,
              title: 'Event', // Default title for legacy events
            );
            events.add(event);
          }
        } catch (e) {
          print('⚠️ Invalid event data format: $eventData - $e');
        }
      }

      print('📅 Loaded ${events.length} events from storage');
    } catch (e) {
      print('⚠️ Error loading events from storage: $e');
      events.clear();
    }
  }

  /// Save events to storage
  void _saveEventsToStorage() {
    try {
      final eventObjects = events.map((event) => event.toJson()).toList();
      storageService.write(_eventsKey, eventObjects);
      print('📅 Saved ${events.length} events to storage');
    } catch (e) {
      print('⚠️ Error saving events to storage: $e');
    }
  }

  /// Load calendar state from storage
  void _loadStateFromStorage() {
    print('📅 _loadStateFromStorage() called');
    try {
      // Load visibility state
      final savedVisibility = storageService.read<bool>(_visibilityKey);
      print(
          '📅 Raw saved visibility: $savedVisibility (type: ${savedVisibility.runtimeType})');
      if (savedVisibility != null) {
        isVisible.value = savedVisibility;
        print('📅 Loaded visibility state: ${isVisible.value}');
      } else {
        print(
            '📅 No saved visibility state found, keeping default: ${isVisible.value}');
      }

      // Load calendar title
      final savedTitle = storageService.read<String>(_titleKey);
      print('📅 Raw saved title: $savedTitle');
      if (savedTitle != null && savedTitle.isNotEmpty) {
        calendarTitle.value = savedTitle;
        print('📅 Loaded calendar title: ${calendarTitle.value}');
      } else {
        print(
            '📅 No saved title found, keeping default: ${calendarTitle.value}');
      }
    } catch (e) {
      print('⚠️ Error loading calendar state from storage: $e');
    }
  }

  /// Save calendar state to storage
  void _saveStateToStorage() {
    try {
      storageService.write(_visibilityKey, isVisible.value);
      storageService.write(_titleKey, calendarTitle.value);
      print(
          '📅 Saved calendar state: visible=${isVisible.value}, title=${calendarTitle.value}');
    } catch (e) {
      print('⚠️ Error saving calendar state to storage: $e');
    }
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
  List<CalendarEvent> getEventsForDay(DateTime day) {
    return events.where((event) => event.isOnDay(day)).toList();
  }

  /// Add event to a specific day
  void addEvent(DateTime day,
      [String? eventTitle, String? description, String? color]) {
    if (!events.any((event) => event.isOnDay(day))) {
      final event = CalendarEvent(
        date: day,
        title: eventTitle ?? 'Event',
        description: description,
        color: color,
      );
      events.add(event);
      _saveEventsToStorage();
      print('📅 Event added for: ${day.toLocal()} - "${event.title}"');
    } else {
      print('📅 Event already exists for: ${day.toLocal()}');
    }
  }

  /// Add a full event object
  void addEventObject(CalendarEvent event) {
    if (!events.any((existingEvent) => existingEvent.isOnDay(event.date))) {
      events.add(event);
      _saveEventsToStorage();
      print('📅 Event added: ${event.title} for ${event.date.toLocal()}');
    } else {
      print('📅 Event already exists for: ${event.date.toLocal()}');
    }
  }

  /// Remove event from a specific day
  void removeEvent(DateTime day) {
    final removedCount = events.length;
    events.removeWhere((event) => event.isOnDay(day));
    final actualRemoved = removedCount - events.length;
    if (actualRemoved > 0) {
      _saveEventsToStorage();
      print('📅 Removed $actualRemoved event(s) for: ${day.toLocal()}');
    } else {
      print('📅 No events found to remove for: ${day.toLocal()}');
    }
  }

  /// Remove a specific event by ID
  void removeEventById(String eventId) {
    final removedCount = events.length;
    events.removeWhere((event) => event.id == eventId);
    final actualRemoved = removedCount - events.length;
    if (actualRemoved > 0) {
      _saveEventsToStorage();
      print('📅 Removed event with ID: $eventId');
    } else {
      print('📅 No event found with ID: $eventId');
    }
  }

  /// Clear all events
  void clearAllEvents() {
    events.clear();
    _saveEventsToStorage();
    print('📅 All events cleared');
  }

  /// Show calendar
  void showCalendar() {
    isVisible.value = true;
    _saveStateToStorage();
    print('📅 Calendar shown');
  }

  /// Hide calendar
  void hideCalendar() {
    isVisible.value = false;
    _saveStateToStorage();
    print('📅 Calendar hidden');
  }

  /// Toggle calendar visibility
  void toggleCalendar() {
    isVisible.value = !isVisible.value;
    _saveStateToStorage();
    print('📅 Calendar toggled: ${isVisible.value ? 'shown' : 'hidden'}');
  }

  /// Set calendar title
  void setCalendarTitle(String title) {
    calendarTitle.value = title;
    _saveStateToStorage();
    print('📅 Calendar title set to: $title');
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
              final title = command['title'] as String?;
              final description = command['description'] as String?;
              final color = command['color'] as String?;
              addEvent(date, title, description, color);
            } catch (e) {
              print('❌ Invalid date format for add_event: $dateStr');
            }
          }
          break;

        case 'remove_event':
          final dateStr = command['date'] as String?;
          final eventId = command['event_id'] as String?;

          if (eventId != null) {
            // Remove by specific event ID
            removeEventById(eventId);
          } else if (dateStr != null) {
            // Remove all events on a specific date
            try {
              final date = DateTime.parse(dateStr);
              removeEvent(date);
            } catch (e) {
              print('❌ Invalid date format for remove_event: $dateStr');
            }
          } else {
            print('❌ remove_event requires either date or event_id parameter');
          }
          break;

        case 'clear_events':
          clearAllEvents();
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

        case 'list_events':
          // Return all events - this will be printed to console for now
          final allEvents = getAllEvents();
          print('📅 All Events:');
          if (allEvents.isEmpty) {
            print('   No events found');
          } else {
            for (var i = 0; i < allEvents.length; i++) {
              final event = allEvents[i];
              print('   ${i + 1}. ID: ${event['id']}');
              print('      Date: ${event['date']}');
              print('      Title: ${event['title']}');
              if (event['description'] != null) {
                print('      Description: ${event['description']}');
              }
              print('');
            }
          }
          break;

        case 'remove_event_by_title':
          final title = command['title'] as String?;
          if (title != null) {
            final dateStr = command['date'] as String?;
            DateTime? date;
            if (dateStr != null) {
              try {
                date = DateTime.parse(dateStr);
              } catch (e) {
                print(
                    '❌ Invalid date format for remove_event_by_title: $dateStr');
                break;
              }
            }
            removeEventByTitle(title, date);
          } else {
            print('❌ remove_event_by_title requires title parameter');
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
      'events': events
          .map((event) => {
                'id': event.id,
                'date': event.date.toIso8601String(),
                'title': event.title,
                'description': event.description,
                'color': event.color,
              })
          .toList(),
    };
  }

  /// Get all events (for MQTT command)
  List<Map<String, dynamic>> getAllEvents() {
    return events
        .map((event) => {
              'id': event.id,
              'date': event.date.toIso8601String(),
              'title': event.title,
              'description': event.description,
              'color': event.color,
            })
        .toList();
  }

  /// Remove event by title and optional date
  void removeEventByTitle(String title, [DateTime? date]) {
    final removedCount = events.length;
    events.removeWhere((event) {
      final titleMatches = event.title.toLowerCase() == title.toLowerCase();
      final dateMatches = date == null || event.isOnDay(date);
      return titleMatches && dateMatches;
    });
    final actualRemoved = removedCount - events.length;
    if (actualRemoved > 0) {
      _saveEventsToStorage();
      print('📅 Removed $actualRemoved event(s) with title: "$title"' +
          (date != null ? ' on ${date.toLocal()}' : ''));
    } else {
      print('📅 No events found with title: "$title"' +
          (date != null ? ' on ${date.toLocal()}' : ''));
    }
  }
}
