# MQTT Calendar Commands Reference

This document lists all available MQTT commands for managing the calendar widget and events in KingKiosk.

## Overview

The calendar system supports two types of operations:
1. **Widget Management** - Show/hide calendar widgets
2. **Event Management** - Add/remove/manage calendar events

## MQTT Topic

All calendar commands should be sent to your configured MQTT command topic (typically `kingkiosk/command`).

## Command Structure

All commands use JSON format:
```json
{
  "command": "calendar",
  "action": "<action_name>",
  // additional parameters...
}
```

---

## Widget Management Commands

### Show/Create Calendar Widget

Shows or creates a calendar widget in the tiling window system.

```json
{
  "command": "calendar",
  "action": "show",
  "name": "My Calendar",
  "window_id": "calendar_1"
}
```

**Parameters:**
- `action`: `"show"` or `"create"` (both work the same)
- `name` (optional): Display name for the calendar widget (default: "Calendar")
- `window_id` (optional): Unique identifier for the calendar window

**Alternative (simplified):**
```json
{
  "command": "calendar",
  "action": "create",
  "name": "Work Calendar"
}
```

### Hide Calendar Widget

Hides a specific calendar widget.

```json
{
  "command": "calendar",
  "action": "hide",
  "window_id": "calendar_1"
}
```

**Parameters:**
- `action`: `"hide"`
- `window_id`: Required - ID of the calendar widget to hide

---

## Event Management Commands

### Add Event

Adds an event with title and optional description to a specific date.

```json
{
  "command": "calendar",
  "action": "add_event",
  "date": "2025-06-15",
  "title": "Meeting with Team",
  "description": "Weekly standup meeting",
  "color": "#FF5722"
}
```

**Parameters:**
- `action`: `"add_event"`
- `date`: Date in ISO format (YYYY-MM-DD or full ISO 8601)
- `title`: Event title/name (required)
- `description` (optional): Detailed description of the event
- `color` (optional): Color code for the event (for future UI enhancements)

**Examples:**
```json
// Simple event
{"command": "calendar", "action": "add_event", "date": "2025-06-15", "title": "Doctor Appointment"}

// Event with description
{"command": "calendar", "action": "add_event", "date": "2025-06-20", "title": "Team Meeting", "description": "Quarterly planning session"}

// Event with color
{"command": "calendar", "action": "add_event", "date": "2025-06-25", "title": "Birthday Party", "description": "John's birthday celebration", "color": "#4CAF50"}
```

### Remove Event

Removes event(s) from a specific date or removes a specific event by ID.

```json
{
  "command": "calendar",
  "action": "remove_event",
  "date": "2025-06-15"
}
```

**OR**

```json
{
  "command": "calendar",
  "action": "remove_event",
  "event_id": "1718447200000123"
}
```

**Parameters:**
- `action`: `"remove_event"`
- `date`: Date in ISO format (removes ALL events on this date)
- `event_id`: Specific event ID (removes only this event)

**Note:** You must provide either `date` OR `event_id`, not both.

**Finding Event IDs:**
- Event IDs are displayed in the calendar GUI next to each event title (shown as "ID: 12345678...")
- Hover over the ID badge to see the full event ID and copy it for MQTT commands
- Use the `list_events` command to print all events with their full IDs to the console

### Clear All Events

Removes all event markers from the calendar.

```json
{
  "command": "calendar",
  "action": "clear_events"
}
```

**Parameters:**
- `action`: `"clear_events"`

### List All Events

Displays all events in the console with their full IDs, titles, dates, and descriptions. Useful for discovering event IDs for targeted removal.

```json
{
  "command": "calendar",
  "action": "list_events"
}
```

**Parameters:**
- `action`: `"list_events"`

**Output**: Prints event information to the console in the format:
```
Event ID: 1718447200000123
Date: 2025-06-15
Title: Meeting with Team
Description: Weekly standup meeting

Event ID: 1718533600000456
Date: 2025-06-16
Title: Project Review
Description: Quarterly project evaluation
```

### Remove Event by Title

Removes all events that match a specific title. Useful when you know the event name but not the ID.

```json
{
  "command": "calendar",
  "action": "remove_event_by_title",
  "title": "Meeting with Team"
}
```

**Parameters:**
- `action`: `"remove_event_by_title"`
- `title`: Exact title of the event(s) to remove

---

## Navigation Commands

### Go to Specific Date

Navigates the calendar to show a specific date and selects it.

```json
{
  "command": "calendar",
  "action": "go_to_date",
  "date": "2025-12-25"
}
```

**Parameters:**
- `action`: `"go_to_date"`
- `date`: Date in ISO format (YYYY-MM-DD or full ISO 8601)

---

## View Format Commands

### Change Calendar Format

Changes the calendar display format between month, week, and two-week views.

```json
{
  "command": "calendar",
  "action": "format",
  "format": "month"
}
```

**Parameters:**
- `action`: `"format"`
- `format`: One of:
  - `"month"` - Monthly view (default)
  - `"week"` - Weekly view
  - `"twoweeks"` or `"two_weeks"` - Two-week view

---

## Complete Examples

### Create Calendar and Add Rich Events

```json
// 1. Create a calendar widget
{
  "command": "calendar",
  "action": "create",
  "name": "Work Schedule",
  "window_id": "work_calendar"
}

// 2. Add events with titles and descriptions
{
  "command": "calendar",
  "action": "add_event",
  "date": "2025-06-16",
  "title": "Project Kickoff",
  "description": "Initial meeting for the new client project"
}

{
  "command": "calendar",
  "action": "add_event",
  "date": "2025-06-18",
  "title": "Code Review",
  "description": "Review pull requests for release 2.1"
}

{
  "command": "calendar",
  "action": "add_event",
  "date": "2025-06-20",
  "title": "Client Demo",
  "description": "Demonstrate new features to stakeholders",
  "color": "#FF5722"
}

// 3. Switch to week view
{
  "command": "calendar",
  "action": "format",
  "format": "week"
}

// 4. Navigate to current week
{
  "command": "calendar",
  "action": "go_to_date",
  "date": "2025-06-16"
}
```

### Event Management Workflow

```json
// Add multiple events with rich data
{"command": "calendar", "action": "add_event", "date": "2025-06-15", "title": "Morning Standup", "description": "Daily team sync"}
{"command": "calendar", "action": "add_event", "date": "2025-06-20", "title": "Client Call", "description": "Quarterly business review with ABC Corp"}
{"command": "calendar", "action": "add_event", "date": "2025-06-25", "title": "Team Building", "description": "Offsite team activities", "color": "#4CAF50"}

// Remove a specific event by ID (you'd get the ID from the system)
{"command": "calendar", "action": "remove_event", "event_id": "1718447200000123"}

// Remove all events on a specific date
{"command": "calendar", "action": "remove_event", "date": "2025-06-20"}

// Clear all events and start fresh
{"command": "calendar", "action": "clear_events"}
```

---

## Notes

1. **Date Formats**: All dates should be in ISO format. Examples:
   - `"2025-06-15"` (YYYY-MM-DD)
   - `"2025-06-15T00:00:00Z"` (Full ISO 8601)

2. **Event Data**: Events now support rich data:
   - **Title**: Required field for event name/summary
   - **Description**: Optional detailed description
   - **Color**: Optional color code for visual distinction (planned feature)
   - **ID**: Automatically generated unique identifier for each event

3. **Event Persistence**: Events are automatically saved to local storage and persist across app restarts.

4. **Multiple Calendars**: You can create multiple calendar widgets with different `window_id` values.

5. **Error Handling**: Invalid dates or commands will be logged to the console with error messages.

6. **Event Display**: 
   - Events appear as numbered dots on calendar dates
   - Click on a date to see full event details including titles and descriptions
   - Each event can be individually removed from the event list

7. **GUI Integration**: The calendar GUI now includes:
   - "Add Event" button that opens a dialog for title/description entry
   - Individual event display with titles and descriptions
   - Per-event remove buttons
   - "Clear All" button to remove all events on a date

---

## Status Monitoring

The calendar controller provides status information that can be accessed programmatically:

```dart
// Get calendar status
Map<String, dynamic> status = calendarController.getCalendarStatus();
// Returns:
// {
//   'visible': true/false,
//   'selected_date': '2025-06-15T...',
//   'focused_date': '2025-06-15T...',
//   'format': 'month',
//   'events_count': 5
// }
```

This status could potentially be published to MQTT topics for monitoring purposes in future implementations.
