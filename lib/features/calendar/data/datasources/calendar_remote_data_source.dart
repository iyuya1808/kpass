import 'package:kpass/shared/models/models.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart' show CalendarPermissionStatus;

/// Remote data source interface for calendar events
abstract class CalendarRemoteDataSource {
  /// Fetch all calendar events from Canvas API
  Future<List<CalendarEvent>> getCalendarEvents();

  /// Fetch calendar events for a specific date range from Canvas API
  Future<List<CalendarEvent>> getCalendarEventsInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Fetch a specific calendar event by ID from Canvas API
  Future<CalendarEvent> getCalendarEvent(String eventId);

  /// Fetch calendar events with pagination support
  Future<List<CalendarEvent>> getCalendarEventsWithPagination({
    int page = 1,
    int perPage = 50,
  });

  /// Fetch calendar events for specific contexts (courses)
  Future<List<CalendarEvent>> getCalendarEventsForContexts(
    List<String> contextCodes,
  );

  /// Create a calendar event via Canvas API
  Future<CalendarEvent> createCalendarEvent(CalendarEvent event);

  /// Update a calendar event via Canvas API
  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event);

  /// Delete a calendar event via Canvas API
  Future<void> deleteCalendarEvent(String eventId);
}

/// Local data source interface for calendar events
abstract class CalendarLocalDataSource {
  /// Get cached calendar events
  Future<List<CalendarEvent>> getCachedCalendarEvents();

  /// Get cached calendar events for a date range
  Future<List<CalendarEvent>> getCachedCalendarEventsInRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get a cached calendar event by ID
  Future<CalendarEvent?> getCachedCalendarEvent(String eventId);

  /// Cache calendar events data
  Future<void> cacheCalendarEvents(List<CalendarEvent> events);

  /// Cache a single calendar event
  Future<void> cacheCalendarEvent(CalendarEvent event);

  /// Remove a cached calendar event
  Future<void> removeCachedCalendarEvent(String eventId);

  /// Clear all cached calendar events
  Future<void> clearCache();

  /// Get cache metadata
  Future<CacheMetadata> getCacheMetadata();

  /// Update cache metadata
  Future<void> updateCacheMetadata(CacheMetadata metadata);

  /// Check if cache is expired
  Future<bool> isCacheExpired();

  /// Get cache size in bytes
  Future<int> getCacheSize();
}

/// Device calendar data source interface
abstract class DeviceCalendarDataSource {
  /// Check calendar permissions
  Future<CalendarPermissionStatus> checkPermissions();

  /// Request calendar permissions
  Future<CalendarPermissionStatus> requestPermissions();

  /// Get available device calendars
  Future<List<DeviceCalendar>> getDeviceCalendars();

  /// Create an event in device calendar
  Future<String> createDeviceCalendarEvent(
    String calendarId,
    DeviceCalendarEvent event,
  );

  /// Update an event in device calendar
  Future<void> updateDeviceCalendarEvent(
    String calendarId,
    String eventId,
    DeviceCalendarEvent event,
  );

  /// Delete an event from device calendar
  Future<void> deleteDeviceCalendarEvent(String calendarId, String eventId);

  /// Get events from device calendar in date range
  Future<List<DeviceCalendarEvent>> getDeviceCalendarEvents(
    String calendarId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Find events by metadata (Canvas assignment ID)
  Future<List<DeviceCalendarEvent>> findEventsByMetadata(
    String calendarId,
    Map<String, String> metadata,
  );
}

/// Device calendar representation
class DeviceCalendar {
  final String id;
  final String name;
  final String? color;
  final bool isReadOnly;
  final bool isDefault;

  const DeviceCalendar({
    required this.id,
    required this.name,
    this.color,
    required this.isReadOnly,
    required this.isDefault,
  });

  @override
  String toString() {
    return 'DeviceCalendar(id: $id, name: $name, readOnly: $isReadOnly)';
  }
}

/// Device calendar event representation
class DeviceCalendarEvent {
  final String? id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  final Map<String, String> metadata;

  const DeviceCalendarEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.metadata = const {},
  });

  /// Create from Canvas CalendarEvent
  factory DeviceCalendarEvent.fromCalendarEvent(CalendarEvent event) {
    return DeviceCalendarEvent(
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      isAllDay: event.isAllDay ?? false,
      location: event.location,
      metadata: {
        'canvas_event_id': event.id,
        if (event.canvasAssignmentId != null)
          'canvas_assignment_id': event.canvasAssignmentId!,
        'source': 'kpass_canvas',
      },
    );
  }

  @override
  String toString() {
    return 'DeviceCalendarEvent(id: $id, title: $title, startTime: $startTime)';
  }
}