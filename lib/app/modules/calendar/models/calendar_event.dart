/// Calendar Event Model
/// Represents a calendar event with date, title, and description
class CalendarEvent {
  final DateTime date;
  final String title;
  final String? description;
  final String? color; // Optional color for the event
  final String id; // Unique identifier

  CalendarEvent({
    required this.date,
    required this.title,
    this.description,
    this.color,
    String? id,
  }) : id = id ?? _generateId();

  /// Generate a unique ID for the event
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'color': color,
    };
  }

  /// Create from JSON
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
    );
  }

  /// Check if two events are the same (by ID)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Check if this event is on the same day as a given date
  bool isOnDay(DateTime day) {
    return date.year == day.year &&
        date.month == day.month &&
        date.day == day.day;
  }

  /// Get a short display summary
  String get summary {
    if (description != null && description!.isNotEmpty) {
      return '$title - $description';
    }
    return title;
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, date: ${date.toLocal()}, title: $title, description: $description)';
  }
}
