import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kpass/core/errors/exceptions.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart' show CalendarPermissionStatus;

/// Service for managing device calendar permissions and operations
class CalendarService implements DeviceCalendarDataSource {
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  CalendarService({DeviceCalendarPlugin? deviceCalendarPlugin})
      : _deviceCalendarPlugin = deviceCalendarPlugin ?? DeviceCalendarPlugin();

  /// Check current calendar permission status
  @override
  Future<CalendarPermissionStatus> checkPermissions() async {
    try {
      final hasPermissions = await _deviceCalendarPlugin.hasPermissions();
      
      if (hasPermissions.isSuccess && hasPermissions.data == true) {
        return CalendarPermissionStatus.granted;
      }
      
      // Check system permission status for more detailed info
      final systemStatus = await Permission.calendarFullAccess.status;
      return _mapPermissionStatus(systemStatus);
    } catch (e) {
      throw CalendarException(
        message: 'Failed to check calendar permissions: ${e.toString()}',
        code: 'PERMISSION_CHECK_FAILED',
      );
    }
  }

  /// Request calendar permissions from the user
  @override
  Future<CalendarPermissionStatus> requestPermissions() async {
    try {
      // First check if we already have permissions
      final currentStatus = await checkPermissions();
      if (currentStatus == CalendarPermissionStatus.granted) {
        return currentStatus;
      }

      // If permanently denied, we can't request again
      if (currentStatus == CalendarPermissionStatus.permanentlyDenied) {
        return currentStatus;
      }

      // Request permissions using device_calendar plugin
      final permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      
      if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
        return CalendarPermissionStatus.granted;
      }

      // Check the actual system status after request
      final systemStatus = await Permission.calendarFullAccess.status;
      return _mapPermissionStatus(systemStatus);
    } catch (e) {
      throw CalendarException(
        message: 'Failed to request calendar permissions: ${e.toString()}',
        code: 'PERMISSION_REQUEST_FAILED',
      );
    }
  }

  /// Get available device calendars
  @override
  Future<List<DeviceCalendar>> getDeviceCalendars() async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        throw CalendarException(
          message: 'Failed to retrieve calendars: ${calendarsResult.errors.join(', ')}',
          code: 'CALENDAR_RETRIEVAL_FAILED',
        );
      }

      return calendarsResult.data!
          .map((calendar) => DeviceCalendar(
                id: calendar.id!,
                name: calendar.name ?? 'Unknown Calendar',
                color: calendar.color?.toString(),
                isReadOnly: calendar.isReadOnly ?? true,
                isDefault: calendar.isDefault ?? false,
              ))
          .toList();
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException(
        message: 'Failed to get device calendars: ${e.toString()}',
        code: 'GET_CALENDARS_FAILED',
      );
    }
  }

  /// Create an event in the device calendar
  @override
  Future<String> createDeviceCalendarEvent(
    String calendarId,
    DeviceCalendarEvent event,
  ) async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      final deviceEvent = Event(calendarId)
        ..title = event.title
        ..description = event.description
        ..start = TZDateTime.from(event.startTime, local)
        ..end = event.endTime != null ? TZDateTime.from(event.endTime!, local) : null
        ..allDay = event.isAllDay
        ..location = event.location;

      // Add metadata as custom properties if supported
      if (event.metadata.isNotEmpty) {
        // Note: Custom properties support varies by platform
        // This is a simplified implementation
        final metadataString = event.metadata.entries
            .map((e) => '${e.key}:${e.value}')
            .join(';');
        deviceEvent.description = '${deviceEvent.description ?? ''}\n\nMetadata: $metadataString';
      }

      final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(deviceEvent);
      
      if (createResult == null || !createResult.isSuccess || createResult.data == null) {
        throw CalendarException.eventCreationFailed(
          createResult?.errors.join(', ') ?? 'Unknown error',
        );
      }

      return createResult.data!;
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventCreationFailed(e.toString());
    }
  }

  /// Update an event in the device calendar
  @override
  Future<void> updateDeviceCalendarEvent(
    String calendarId,
    String eventId,
    DeviceCalendarEvent event,
  ) async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      final deviceEvent = Event(calendarId, eventId: eventId)
        ..title = event.title
        ..description = event.description
        ..start = TZDateTime.from(event.startTime, local)
        ..end = event.endTime != null ? TZDateTime.from(event.endTime!, local) : null
        ..allDay = event.isAllDay
        ..location = event.location;

      // Add metadata as custom properties if supported
      if (event.metadata.isNotEmpty) {
        final metadataString = event.metadata.entries
            .map((e) => '${e.key}:${e.value}')
            .join(';');
        deviceEvent.description = '${deviceEvent.description ?? ''}\n\nMetadata: $metadataString';
      }

      final updateResult = await _deviceCalendarPlugin.createOrUpdateEvent(deviceEvent);
      
      if (updateResult == null || !updateResult.isSuccess) {
        throw CalendarException.eventUpdateFailed(
          updateResult?.errors.join(', ') ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventUpdateFailed(e.toString());
    }
  }

  /// Delete an event from the device calendar
  @override
  Future<void> deleteDeviceCalendarEvent(String calendarId, String eventId) async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      final deleteResult = await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      
      if (!deleteResult.isSuccess) {
        throw CalendarException.eventDeletionFailed(
          deleteResult.errors.join(', '),
        );
      }
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventDeletionFailed(e.toString());
    }
  }

  /// Get events from device calendar in date range
  @override
  Future<List<DeviceCalendarEvent>> getDeviceCalendarEvents(
    String calendarId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(
          startDate: startDate,
          endDate: endDate,
        ),
      );
      
      if (!eventsResult.isSuccess || eventsResult.data == null) {
        throw CalendarException(
          message: 'Failed to retrieve events: ${eventsResult.errors.join(', ')}',
          code: 'EVENT_RETRIEVAL_FAILED',
        );
      }

      return eventsResult.data!
          .map((event) => DeviceCalendarEvent(
                id: event.eventId,
                title: event.title ?? 'Untitled Event',
                description: event.description,
                startTime: event.start?.toLocal() ?? DateTime.now(),
                endTime: event.end?.toLocal(),
                isAllDay: event.allDay ?? false,
                location: event.location,
                metadata: _extractMetadataFromDescription(event.description),
              ))
          .toList();
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException(
        message: 'Failed to get device calendar events: ${e.toString()}',
        code: 'GET_EVENTS_FAILED',
      );
    }
  }

  /// Find events by metadata (Canvas assignment ID)
  @override
  Future<List<DeviceCalendarEvent>> findEventsByMetadata(
    String calendarId,
    Map<String, String> metadata,
  ) async {
    try {
      // Get all events in a reasonable range (last year to next year)
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, 1, 1);
      final endDate = DateTime(now.year + 1, 12, 31);
      
      final events = await getDeviceCalendarEvents(calendarId, startDate, endDate);
      
      // Filter events by metadata
      return events.where((event) {
        return metadata.entries.every((entry) {
          return event.metadata[entry.key] == entry.value;
        });
      }).toList();
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException(
        message: 'Failed to find events by metadata: ${e.toString()}',
        code: 'FIND_EVENTS_FAILED',
      );
    }
  }

  /// Provide user guidance for permission handling
  String getPermissionGuidanceMessage(CalendarPermissionStatus status) {
    switch (status) {
      case CalendarPermissionStatus.granted:
        return 'Calendar access is granted. You can sync assignments to your calendar.';
      case CalendarPermissionStatus.denied:
        return 'Calendar access was denied. Please grant permission to sync assignments to your calendar.';
      case CalendarPermissionStatus.restricted:
        return 'Calendar access is restricted by system settings. Please check your device settings.';
      case CalendarPermissionStatus.permanentlyDenied:
        return 'Calendar access was permanently denied. Please go to Settings > Privacy > Calendar to enable access for this app.';
      case CalendarPermissionStatus.unknown:
        return 'Calendar permission status is unknown. Please try requesting permission again.';
    }
  }

  /// Check if calendar sync is available
  Future<bool> isCalendarSyncAvailable() async {
    try {
      final status = await checkPermissions();
      return status == CalendarPermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Check if calendar permissions are granted
  Future<bool> hasPermissions() async {
    try {
      final status = await checkPermissions();
      return status == CalendarPermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Create a calendar event for an assignment
  Future<void> createAssignmentEvent(dynamic assignment) async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      // Get the default calendar
      final calendar = await getDefaultCalendar();
      if (calendar == null) {
        throw CalendarException.calendarNotFound();
      }

      // Create the event
      final event = DeviceCalendarEvent(
        title: assignment.name,
        description: assignment.description ?? '',
        startTime: assignment.dueAt,
        endTime: assignment.dueAt,
        isAllDay: false,
        metadata: {
          'assignment_id': assignment.id.toString(),
          'course_id': assignment.courseId.toString(),
          'type': 'canvas_assignment',
        },
      );

      await createDeviceCalendarEvent(calendar.id, event);
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventCreationFailed(e.toString());
    }
  }

  /// Update a calendar event for an assignment
  Future<void> updateAssignmentEvent(dynamic assignment) async {
    try {
      final permissionStatus = await checkPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        throw CalendarException.permissionDenied();
      }

      // Get the default calendar
      final calendar = await getDefaultCalendar();
      if (calendar == null) {
        throw CalendarException.calendarNotFound();
      }

      // Find existing event by assignment ID
      final existingEvents = await findEventsByMetadata(
        calendar.id,
        {'assignment_id': assignment.id.toString()},
      );

      if (existingEvents.isEmpty) {
        // Event doesn't exist, create it instead
        await createAssignmentEvent(assignment);
        return;
      }

      // Update the first matching event
      final eventId = existingEvents.first.id;
      if (eventId == null) {
        throw CalendarException.eventUpdateFailed('Event ID is null');
      }

      final event = DeviceCalendarEvent(
        id: eventId,
        title: assignment.name,
        description: assignment.description ?? '',
        startTime: assignment.dueAt,
        endTime: assignment.dueAt,
        isAllDay: false,
        metadata: {
          'assignment_id': assignment.id.toString(),
          'course_id': assignment.courseId.toString(),
          'type': 'canvas_assignment',
        },
      );

      await updateDeviceCalendarEvent(calendar.id, eventId, event);
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventUpdateFailed(e.toString());
    }
  }

  /// Get the default calendar for the device
  Future<DeviceCalendar?> getDefaultCalendar() async {
    try {
      final calendars = await getDeviceCalendars();
      return calendars.where((calendar) => calendar.isDefault).firstOrNull ??
             calendars.where((calendar) => !calendar.isReadOnly).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Map system permission status to our enum
  CalendarPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return CalendarPermissionStatus.granted;
      case PermissionStatus.denied:
        return CalendarPermissionStatus.denied;
      case PermissionStatus.restricted:
        return CalendarPermissionStatus.restricted;
      case PermissionStatus.permanentlyDenied:
        return CalendarPermissionStatus.permanentlyDenied;
      case PermissionStatus.provisional:
        return CalendarPermissionStatus.granted; // Treat provisional as granted
      case PermissionStatus.limited:
        return CalendarPermissionStatus.granted; // Treat limited as granted
    }
  }

  /// Extract metadata from event description
  Map<String, String> _extractMetadataFromDescription(String? description) {
    if (description == null) return {};
    
    final metadataMatch = RegExp(r'Metadata: (.+)$', multiLine: true).firstMatch(description);
    if (metadataMatch == null) return {};
    
    final metadataString = metadataMatch.group(1);
    if (metadataString == null) return {};
    
    final metadata = <String, String>{};
    for (final pair in metadataString.split(';')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        metadata[parts[0].trim()] = parts[1].trim();
      }
    }
    
    return metadata;
  }
}

// Local timezone reference
final local = tz.local;