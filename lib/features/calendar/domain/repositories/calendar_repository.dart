import 'package:kpass/shared/models/models.dart';

/// Repository interface for managing calendar event data
abstract class CalendarRepository {
  /// Get all calendar events for the authenticated user
  /// Returns cached data if available and [forceRefresh] is false
  Future<List<CalendarEvent>> getCalendarEvents({bool forceRefresh = false});

  /// Get calendar events for a specific date range
  Future<List<CalendarEvent>> getCalendarEventsInRange(
    DateTime startDate,
    DateTime endDate, {
    bool forceRefresh = false,
  });

  /// Get calendar events for a specific date
  Future<List<CalendarEvent>> getCalendarEventsForDate(
    DateTime date, {
    bool forceRefresh = false,
  });

  /// Get a specific calendar event by ID
  Future<CalendarEvent?> getCalendarEvent(
    String eventId, {
    bool forceRefresh = false,
  });

  /// Get calendar events that are assignment-related
  Future<List<CalendarEvent>> getAssignmentEvents({bool forceRefresh = false});

  /// Get calendar events for today
  Future<List<CalendarEvent>> getTodayEvents({bool forceRefresh = false});

  /// Get upcoming calendar events (within specified duration)
  Future<List<CalendarEvent>> getUpcomingEvents({
    Duration threshold = const Duration(days: 7),
    bool forceRefresh = false,
  });

  /// Search calendar events by title or description
  Future<List<CalendarEvent>> searchCalendarEvents(
    String query, {
    bool forceRefresh = false,
  });

  /// Get calendar events grouped by date
  Future<Map<DateTime, List<CalendarEvent>>> getCalendarEventsGroupedByDate({
    bool forceRefresh = false,
  });

  /// Create a calendar event from an assignment
  Future<CalendarEvent> createAssignmentEvent(Assignment assignment);

  /// Update a calendar event
  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event);

  /// Delete a calendar event
  Future<void> deleteCalendarEvent(String eventId);

  /// Sync assignment to device calendar
  Future<void> syncAssignmentToDeviceCalendar(Assignment assignment);

  /// Remove assignment from device calendar
  Future<void> removeAssignmentFromDeviceCalendar(int assignmentId);

  /// Get assignments that need calendar sync
  Future<List<Assignment>> getAssignmentsNeedingSync();

  /// Get orphaned calendar events (assignments no longer exist)
  Future<List<CalendarEvent>> getOrphanedCalendarEvents();

  /// Perform full calendar synchronization
  Future<CalendarSyncResult> performFullSync();

  /// Perform incremental calendar synchronization
  Future<CalendarSyncResult> performIncrementalSync();

  /// Refresh calendar data from remote source
  Future<void> refreshCalendarEvents();

  /// Clear cached calendar data
  Future<void> clearCache();

  /// Get cache status information
  Future<CacheStatus> getCacheStatus();

  /// Check device calendar permissions
  Future<CalendarPermissionStatus> checkCalendarPermissions();

  /// Request device calendar permissions
  Future<CalendarPermissionStatus> requestCalendarPermissions();

  /// Get calendar sync settings
  Future<CalendarSyncSettings> getSyncSettings();

  /// Update calendar sync settings
  Future<void> updateSyncSettings(CalendarSyncSettings settings);
}

/// Result of calendar synchronization operation
class CalendarSyncResult {
  final int eventsCreated;
  final int eventsUpdated;
  final int eventsDeleted;
  final int errorsEncountered;
  final List<String> errorMessages;
  final DateTime syncTime;
  final Duration syncDuration;

  const CalendarSyncResult({
    required this.eventsCreated,
    required this.eventsUpdated,
    required this.eventsDeleted,
    required this.errorsEncountered,
    required this.errorMessages,
    required this.syncTime,
    required this.syncDuration,
  });

  bool get hasErrors => errorsEncountered > 0;
  bool get hasChanges => eventsCreated > 0 || eventsUpdated > 0 || eventsDeleted > 0;
  int get totalChanges => eventsCreated + eventsUpdated + eventsDeleted;

  @override
  String toString() {
    return 'CalendarSyncResult(created: $eventsCreated, updated: $eventsUpdated, '
        'deleted: $eventsDeleted, errors: $errorsEncountered, '
        'duration: ${syncDuration.inMilliseconds}ms)';
  }
}

/// Calendar permission status
enum CalendarPermissionStatus {
  granted,
  denied,
  restricted,
  permanentlyDenied,
  unknown,
}

/// Calendar synchronization settings
class CalendarSyncSettings {
  final bool isEnabled;
  final List<int> enabledCourseIds;
  final Duration reminderOffset;
  final bool syncToDeviceCalendar;
  final String? deviceCalendarId;
  final bool autoSync;
  final Duration autoSyncInterval;

  const CalendarSyncSettings({
    required this.isEnabled,
    required this.enabledCourseIds,
    this.reminderOffset = const Duration(hours: 1),
    this.syncToDeviceCalendar = false,
    this.deviceCalendarId,
    this.autoSync = true,
    this.autoSyncInterval = const Duration(hours: 6),
  });

  CalendarSyncSettings copyWith({
    bool? isEnabled,
    List<int>? enabledCourseIds,
    Duration? reminderOffset,
    bool? syncToDeviceCalendar,
    String? deviceCalendarId,
    bool? autoSync,
    Duration? autoSyncInterval,
  }) {
    return CalendarSyncSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      enabledCourseIds: enabledCourseIds ?? this.enabledCourseIds,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      syncToDeviceCalendar: syncToDeviceCalendar ?? this.syncToDeviceCalendar,
      deviceCalendarId: deviceCalendarId ?? this.deviceCalendarId,
      autoSync: autoSync ?? this.autoSync,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
    );
  }

  @override
  String toString() {
    return 'CalendarSyncSettings(isEnabled: $isEnabled, '
        'enabledCourses: ${enabledCourseIds.length}, '
        'syncToDevice: $syncToDeviceCalendar, autoSync: $autoSync)';
  }
}