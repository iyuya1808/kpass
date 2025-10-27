import 'package:kpass/shared/models/models.dart';
import 'package:kpass/features/calendar/data/services/calendar_service.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Manager for Canvas assignment calendar events with duplicate prevention
class CalendarEventManager {
  final CalendarService _calendarService;
  
  // Cache for tracking created events to prevent duplicates
  final Map<int, String> _assignmentEventMap = {};
  
  CalendarEventManager(this._calendarService);

  /// Create a calendar event for an assignment with duplicate prevention
  Future<String> createAssignmentEvent(
    Assignment assignment, {
    String? calendarId,
    Duration reminderOffset = const Duration(hours: 1),
  }) async {
    try {
      // Validate assignment has due date
      if (assignment.dueAt == null) {
        throw CalendarException(
          message: 'Cannot create calendar event for assignment without due date',
          code: 'NO_DUE_DATE',
        );
      }

      // Get default calendar if none specified
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      
      // Check for existing event to prevent duplicates
      final existingEventId = await _findExistingAssignmentEvent(assignment.id, targetCalendarId);
      if (existingEventId != null) {
        throw CalendarException(
          message: 'Calendar event already exists for assignment ${assignment.id}',
          code: 'DUPLICATE_EVENT',
        );
      }
      
      // Create calendar event from assignment
      final calendarEvent = _createCalendarEventFromAssignment(
        assignment,
        reminderOffset: reminderOffset,
      );

      // Create event in device calendar
      final eventId = await _calendarService.createDeviceCalendarEvent(
        targetCalendarId,
        calendarEvent,
      );

      // Cache the mapping
      _assignmentEventMap[assignment.id] = eventId;

      return eventId;
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventCreationFailed(e.toString());
    }
  }

  /// Update an existing calendar event for assignment changes
  Future<void> updateAssignmentEvent(
    Assignment assignment, {
    String? calendarId,
    Duration reminderOffset = const Duration(hours: 1),
  }) async {
    try {
      // Validate assignment has due date
      if (assignment.dueAt == null) {
        throw CalendarException(
          message: 'Cannot update calendar event for assignment without due date',
          code: 'NO_DUE_DATE',
        );
      }

      // Find existing event
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      final existingEventId = await _findExistingAssignmentEvent(assignment.id, targetCalendarId);
      
      if (existingEventId == null) {
        throw CalendarException(
          message: 'No existing calendar event found for assignment ${assignment.id}',
          code: 'EVENT_NOT_FOUND',
        );
      }

      // Create updated calendar event
      final updatedEvent = _createCalendarEventFromAssignment(
        assignment,
        reminderOffset: reminderOffset,
      );

      // Update event in device calendar
      await _calendarService.updateDeviceCalendarEvent(
        targetCalendarId,
        existingEventId,
        updatedEvent,
      );
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventUpdateFailed(e.toString());
    }
  }

  /// Delete calendar event for completed/removed assignments
  Future<void> deleteAssignmentEvent(
    int assignmentId, {
    String? calendarId,
  }) async {
    try {
      // Find existing event
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      final existingEventId = await _findExistingAssignmentEvent(assignmentId, targetCalendarId);
      
      if (existingEventId == null) {
        // Event doesn't exist, consider it already deleted
        return;
      }

      // Delete event from device calendar
      await _calendarService.deleteDeviceCalendarEvent(
        targetCalendarId,
        existingEventId,
      );

      // Remove from cache
      _assignmentEventMap.remove(assignmentId);
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventDeletionFailed(e.toString());
    }
  }

  /// Sync multiple assignments to calendar
  Future<CalendarSyncResult> syncAssignmentsToCalendar(
    List<Assignment> assignments, {
    String? calendarId,
    Duration reminderOffset = const Duration(hours: 1),
    bool deleteOrphanedEvents = true,
  }) async {
    int eventsCreated = 0;
    int eventsUpdated = 0;
    int eventsDeleted = 0;
    int errorsEncountered = 0;
    final List<String> errorMessages = [];
    final DateTime syncStartTime = DateTime.now();

    try {
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      
      // Get existing Canvas events in calendar
      final existingEvents = await _getCanvasEventsInCalendar(targetCalendarId);
      final existingAssignmentIds = existingEvents
          .map((event) => _extractAssignmentIdFromEvent(event))
          .where((id) => id != null)
          .cast<int>()
          .toSet();

      // Process each assignment
      for (final assignment in assignments) {
        try {
          // Skip assignments without due dates
          if (assignment.dueAt == null) continue;

          final assignmentId = assignment.id;
          final hasExistingEvent = existingAssignmentIds.contains(assignmentId);

          if (hasExistingEvent) {
            // Update existing event
            await updateAssignmentEvent(
              assignment,
              calendarId: targetCalendarId,
              reminderOffset: reminderOffset,
            );
            eventsUpdated++;
          } else {
            // Create new event
            await createAssignmentEvent(
              assignment,
              calendarId: targetCalendarId,
              reminderOffset: reminderOffset,
            );
            eventsCreated++;
          }
        } catch (e) {
          errorsEncountered++;
          errorMessages.add('Assignment ${assignment.id}: ${e.toString()}');
        }
      }

      // Delete orphaned events if requested
      if (deleteOrphanedEvents) {
        final currentAssignmentIds = assignments
            .where((a) => a.dueAt != null)
            .map((a) => a.id)
            .toSet();
        
        final orphanedAssignmentIds = existingAssignmentIds
            .where((id) => !currentAssignmentIds.contains(id))
            .toList();

        for (final orphanedId in orphanedAssignmentIds) {
          try {
            await deleteAssignmentEvent(orphanedId, calendarId: targetCalendarId);
            eventsDeleted++;
          } catch (e) {
            errorsEncountered++;
            errorMessages.add('Orphaned assignment $orphanedId: ${e.toString()}');
          }
        }
      }

      return CalendarSyncResult(
        eventsCreated: eventsCreated,
        eventsUpdated: eventsUpdated,
        eventsDeleted: eventsDeleted,
        errorsEncountered: errorsEncountered,
        errorMessages: errorMessages,
        syncTime: syncStartTime,
        syncDuration: DateTime.now().difference(syncStartTime),
      );
    } catch (e) {
      throw CalendarException.syncFailed(e.toString());
    }
  }

  /// Check if assignment has calendar event
  Future<bool> hasCalendarEvent(int assignmentId, {String? calendarId}) async {
    try {
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      final eventId = await _findExistingAssignmentEvent(assignmentId, targetCalendarId);
      return eventId != null;
    } catch (e) {
      return false;
    }
  }

  /// Get calendar event for assignment
  Future<DeviceCalendarEvent?> getAssignmentCalendarEvent(
    int assignmentId, {
    String? calendarId,
  }) async {
    try {
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      final events = await _calendarService.findEventsByMetadata(
        targetCalendarId,
        {'canvas_assignment_id': assignmentId.toString()},
      );
      
      return events.isNotEmpty ? events.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Get all Canvas assignment events in calendar
  Future<List<DeviceCalendarEvent>> getCanvasAssignmentEvents({String? calendarId}) async {
    try {
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      return await _getCanvasEventsInCalendar(targetCalendarId);
    } catch (e) {
      throw CalendarException(
        message: 'Failed to get Canvas assignment events: ${e.toString()}',
        code: 'GET_EVENTS_FAILED',
      );
    }
  }

  /// Clear all Canvas assignment events from calendar
  Future<int> clearAllCanvasEvents({String? calendarId}) async {
    try {
      final targetCalendarId = calendarId ?? await _getDefaultCalendarId();
      final canvasEvents = await _getCanvasEventsInCalendar(targetCalendarId);
      
      int deletedCount = 0;
      for (final event in canvasEvents) {
        try {
          if (event.id != null) {
            await _calendarService.deleteDeviceCalendarEvent(targetCalendarId, event.id!);
            deletedCount++;
          }
        } catch (e) {
          // Continue deleting other events even if one fails
        }
      }

      // Clear cache
      _assignmentEventMap.clear();
      
      return deletedCount;
    } catch (e) {
      throw CalendarException(
        message: 'Failed to clear Canvas events: ${e.toString()}',
        code: 'CLEAR_EVENTS_FAILED',
      );
    }
  }

  /// Create DeviceCalendarEvent from Assignment
  DeviceCalendarEvent _createCalendarEventFromAssignment(
    Assignment assignment, {
    Duration reminderOffset = const Duration(hours: 1),
  }) {
    final dueDate = assignment.dueAt!;
    final reminderTime = dueDate.subtract(reminderOffset);
    
    // Create event title
    final title = 'Assignment Due: ${assignment.name}';
    
    // Create event description
    final description = _buildEventDescription(assignment);
    
    return DeviceCalendarEvent(
      title: title,
      description: description,
      startTime: reminderTime,
      endTime: dueDate,
      isAllDay: false,
      location: null,
      metadata: {
        'canvas_assignment_id': assignment.id.toString(),
        'canvas_course_id': assignment.courseId.toString(),
        'source': 'kpass_canvas',
        'assignment_name': assignment.name,
        'due_date': dueDate.toIso8601String(),
      },
    );
  }

  /// Build event description from assignment details
  String _buildEventDescription(Assignment assignment) {
    final buffer = StringBuffer();
    
    buffer.writeln('Canvas Assignment: ${assignment.name}');
    
    if (assignment.description != null && assignment.description!.isNotEmpty) {
      // Remove HTML tags for calendar description
      final cleanDescription = assignment.description!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      if (cleanDescription.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Description:');
        buffer.writeln(cleanDescription);
      }
    }
    
    buffer.writeln();
    buffer.writeln('Due: ${assignment.dueAt!.toLocal()}');
    
    if (assignment.pointsPossible != null) {
      buffer.writeln('Points: ${assignment.pointsPossible}');
    }
    
    if (assignment.submissionTypes != null && assignment.submissionTypes!.isNotEmpty) {
      buffer.writeln('Submission: ${assignment.submissionTypesDisplay}');
    }
    
    buffer.writeln();
    buffer.writeln('Course ID: ${assignment.courseId}');
    buffer.writeln('Assignment ID: ${assignment.id}');
    
    return buffer.toString();
  }

  /// Find existing calendar event for assignment
  Future<String?> _findExistingAssignmentEvent(int assignmentId, String calendarId) async {
    // Check cache first
    if (_assignmentEventMap.containsKey(assignmentId)) {
      return _assignmentEventMap[assignmentId];
    }

    // Search in calendar
    try {
      final events = await _calendarService.findEventsByMetadata(
        calendarId,
        {'canvas_assignment_id': assignmentId.toString()},
      );
      
      if (events.isNotEmpty) {
        final eventId = events.first.id;
        if (eventId != null) {
          // Update cache
          _assignmentEventMap[assignmentId] = eventId;
          return eventId;
        }
      }
    } catch (e) {
      // Event not found or error occurred
    }
    
    return null;
  }

  /// Get Canvas events in calendar
  Future<List<DeviceCalendarEvent>> _getCanvasEventsInCalendar(String calendarId) async {
    return await _calendarService.findEventsByMetadata(
      calendarId,
      {'source': 'kpass_canvas'},
    );
  }

  /// Extract assignment ID from calendar event
  int? _extractAssignmentIdFromEvent(DeviceCalendarEvent event) {
    final assignmentIdStr = event.metadata['canvas_assignment_id'];
    return assignmentIdStr != null ? int.tryParse(assignmentIdStr) : null;
  }

  /// Get default calendar ID
  Future<String> _getDefaultCalendarId() async {
    final defaultCalendar = await _calendarService.getDefaultCalendar();
    if (defaultCalendar == null) {
      throw CalendarException.calendarNotFound();
    }
    return defaultCalendar.id;
  }

  /// Clear event cache (useful for testing)
  void clearCache() {
    _assignmentEventMap.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_events': _assignmentEventMap.length,
      'assignment_ids': _assignmentEventMap.keys.toList(),
    };
  }
}