import 'package:kpass/shared/models/models.dart';
import 'package:kpass/features/calendar/data/services/calendar_event_manager.dart';
import 'package:kpass/features/calendar/data/utils/calendar_permission_handler.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Service for managing calendar synchronization with conflict resolution
class CalendarSyncService {
  final CalendarEventManager _eventManager;
  final AssignmentsRepository _assignmentsRepository;
  
  // Sync status tracking
  CalendarSyncStatus _currentStatus = CalendarSyncStatus.idle;
  DateTime? _lastSyncTime;
  CalendarSyncResult? _lastSyncResult;
  
  // Sync settings
  CalendarSyncSettings _syncSettings = const CalendarSyncSettings(
    isEnabled: false,
    enabledCourseIds: [],
  );

  CalendarSyncService(
    this._eventManager,
    this._assignmentsRepository,
  );

  /// Get current sync status
  CalendarSyncStatus get currentStatus => _currentStatus;
  
  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Get last sync result
  CalendarSyncResult? get lastSyncResult => _lastSyncResult;
  
  /// Get sync settings
  CalendarSyncSettings get syncSettings => _syncSettings;

  /// Update sync settings
  void updateSyncSettings(CalendarSyncSettings settings) {
    _syncSettings = settings;
  }

  /// Perform full synchronization of assignments to calendar events
  Future<CalendarSyncResult> performFullSync({
    String? calendarId,
    bool resolveConflicts = true,
    Duration reminderOffset = const Duration(hours: 1),
  }) async {
    if (_currentStatus == CalendarSyncStatus.syncing) {
      throw CalendarException(
        message: 'Sync already in progress',
        code: 'SYNC_IN_PROGRESS',
      );
    }

    _currentStatus = CalendarSyncStatus.syncing;
    final syncStartTime = DateTime.now();

    try {
      // Check permissions
      await CalendarPermissionHandler.validatePermissionForOperation('full sync');

      // Check if sync is enabled
      if (!_syncSettings.isEnabled) {
        throw CalendarException(
          message: 'Calendar sync is disabled',
          code: 'SYNC_DISABLED',
        );
      }

      // Get all assignments
      final allAssignments = await _assignmentsRepository.getAssignments();
      
      // Filter assignments based on sync settings
      final assignmentsToSync = await _filterAssignmentsForSync(allAssignments);
      
      // Perform sync with conflict resolution
      final syncResult = await _eventManager.syncAssignmentsToCalendar(
        assignmentsToSync,
        calendarId: calendarId,
        reminderOffset: _syncSettings.reminderOffset,
        deleteOrphanedEvents: true,
      );

      // Handle conflicts if enabled
      if (resolveConflicts && syncResult.errorsEncountered > 0) {
        final conflictResolutionResult = await _resolveConflicts(
          assignmentsToSync,
          calendarId: calendarId,
          reminderOffset: reminderOffset,
        );
        
        // Merge results
        final mergedResult = _mergeSyncResults(syncResult, conflictResolutionResult);
        _lastSyncResult = mergedResult;
      } else {
        _lastSyncResult = syncResult;
      }

      _lastSyncTime = syncStartTime;
      _currentStatus = CalendarSyncStatus.completed;
      
      return _lastSyncResult!;
    } catch (e) {
      _currentStatus = CalendarSyncStatus.failed;
      if (e is CalendarException) rethrow;
      throw CalendarException.syncFailed(e.toString());
    }
  }

  /// Perform incremental synchronization for new and updated assignments
  Future<CalendarSyncResult> performIncrementalSync({
    String? calendarId,
    DateTime? since,
    Duration reminderOffset = const Duration(hours: 1),
  }) async {
    if (_currentStatus == CalendarSyncStatus.syncing) {
      throw CalendarException(
        message: 'Sync already in progress',
        code: 'SYNC_IN_PROGRESS',
      );
    }

    _currentStatus = CalendarSyncStatus.syncing;
    final syncStartTime = DateTime.now();

    try {
      // Check permissions
      await CalendarPermissionHandler.validatePermissionForOperation('incremental sync');

      // Check if sync is enabled
      if (!_syncSettings.isEnabled) {
        throw CalendarException(
          message: 'Calendar sync is disabled',
          code: 'SYNC_DISABLED',
        );
      }

      // Determine sync window
      final syncSince = since ?? _lastSyncTime ?? DateTime.now().subtract(const Duration(days: 7));
      
      // Get assignments updated since last sync
      final allAssignments = await _assignmentsRepository.getAssignments();
      final updatedAssignments = allAssignments.where((assignment) {
        return assignment.updatedAt != null && 
               assignment.updatedAt!.isAfter(syncSince);
      }).toList();

      // Filter assignments based on sync settings
      final assignmentsToSync = await _filterAssignmentsForSync(updatedAssignments);

      int eventsCreated = 0;
      int eventsUpdated = 0;
      int eventsDeleted = 0;
      int errorsEncountered = 0;
      final List<String> errorMessages = [];

      // Process each assignment individually for incremental sync
      for (final assignment in assignmentsToSync) {
        try {
          final hasExistingEvent = await _eventManager.hasCalendarEvent(
            assignment.id,
            calendarId: calendarId,
          );

          if (assignment.dueAt == null) {
            // Assignment has no due date, remove event if exists
            if (hasExistingEvent) {
              await _eventManager.deleteAssignmentEvent(
                assignment.id,
                calendarId: calendarId,
              );
              eventsDeleted++;
            }
          } else if (hasExistingEvent) {
            // Update existing event
            await _eventManager.updateAssignmentEvent(
              assignment,
              calendarId: calendarId,
              reminderOffset: _syncSettings.reminderOffset,
            );
            eventsUpdated++;
          } else {
            // Create new event
            await _eventManager.createAssignmentEvent(
              assignment,
              calendarId: calendarId,
              reminderOffset: _syncSettings.reminderOffset,
            );
            eventsCreated++;
          }
        } catch (e) {
          errorsEncountered++;
          errorMessages.add('Assignment ${assignment.id}: ${e.toString()}');
        }
      }

      final syncResult = CalendarSyncResult(
        eventsCreated: eventsCreated,
        eventsUpdated: eventsUpdated,
        eventsDeleted: eventsDeleted,
        errorsEncountered: errorsEncountered,
        errorMessages: errorMessages,
        syncTime: syncStartTime,
        syncDuration: DateTime.now().difference(syncStartTime),
      );

      _lastSyncResult = syncResult;
      _lastSyncTime = syncStartTime;
      _currentStatus = CalendarSyncStatus.completed;
      
      return syncResult;
    } catch (e) {
      _currentStatus = CalendarSyncStatus.failed;
      if (e is CalendarException) rethrow;
      throw CalendarException.syncFailed(e.toString());
    }
  }

  /// Resolve calendar event conflicts
  Future<CalendarSyncResult> _resolveConflicts(
    List<Assignment> assignments, {
    String? calendarId,
    Duration reminderOffset = const Duration(hours: 1),
  }) async {
    int conflictsResolved = 0;
    int errorsEncountered = 0;
    final List<String> errorMessages = [];
    final DateTime syncStartTime = DateTime.now();

    // Get existing Canvas events
    final existingEvents = await _eventManager.getCanvasAssignmentEvents(
      calendarId: calendarId,
    );

    // Check for time conflicts
    for (final assignment in assignments) {
      if (assignment.dueAt == null) continue;

      try {
        final assignmentEventTime = assignment.dueAt!.subtract(reminderOffset);
        
        // Find conflicting events (within 30 minutes)
        final conflictingEvents = existingEvents.where((event) {
          if (event.metadata['canvas_assignment_id'] == assignment.id.toString()) {
            return false; // Don't conflict with self
          }
          
          final timeDiff = (event.startTime.difference(assignmentEventTime)).abs();
          return timeDiff.inMinutes <= 30;
        }).toList();

        if (conflictingEvents.isNotEmpty) {
          // Resolve conflict by adjusting time
          final adjustedTime = _findNonConflictingTime(
            assignmentEventTime,
            existingEvents,
            reminderOffset,
          );

          // Update assignment event with adjusted time
          final adjustedAssignment = assignment.copyWith(
            dueAt: adjustedTime.add(reminderOffset),
          );

          await _eventManager.updateAssignmentEvent(
            adjustedAssignment,
            calendarId: calendarId,
            reminderOffset: reminderOffset,
          );

          conflictsResolved++;
        }
      } catch (e) {
        errorsEncountered++;
        errorMessages.add('Conflict resolution for assignment ${assignment.id}: ${e.toString()}');
      }
    }

    return CalendarSyncResult(
      eventsCreated: 0,
      eventsUpdated: conflictsResolved,
      eventsDeleted: 0,
      errorsEncountered: errorsEncountered,
      errorMessages: errorMessages,
      syncTime: syncStartTime,
      syncDuration: DateTime.now().difference(syncStartTime),
    );
  }

  /// Find a non-conflicting time for an event
  DateTime _findNonConflictingTime(
    DateTime originalTime,
    List<DeviceCalendarEvent> existingEvents,
    Duration reminderOffset,
  ) {
    DateTime candidateTime = originalTime;
    const int maxAttempts = 10;
    const Duration timeIncrement = Duration(minutes: 15);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      bool hasConflict = false;
      
      for (final event in existingEvents) {
        final timeDiff = (event.startTime.difference(candidateTime)).abs();
        if (timeDiff.inMinutes <= 30) {
          hasConflict = true;
          break;
        }
      }

      if (!hasConflict) {
        return candidateTime;
      }

      // Try earlier time first, then later
      if (attempt % 2 == 0) {
        candidateTime = originalTime.subtract(timeIncrement * ((attempt ~/ 2) + 1));
      } else {
        candidateTime = originalTime.add(timeIncrement * ((attempt ~/ 2) + 1));
      }
    }

    // If no non-conflicting time found, return original time
    return originalTime;
  }

  /// Filter assignments based on sync settings
  Future<List<Assignment>> _filterAssignmentsForSync(List<Assignment> assignments) async {
    if (_syncSettings.enabledCourseIds.isEmpty) {
      // If no specific courses enabled, sync all assignments with due dates
      return assignments.where((assignment) => assignment.dueAt != null).toList();
    }

    // Filter by enabled courses
    return assignments.where((assignment) {
      return assignment.dueAt != null && 
             _syncSettings.enabledCourseIds.contains(assignment.courseId);
    }).toList();
  }

  /// Merge two sync results
  CalendarSyncResult _mergeSyncResults(
    CalendarSyncResult result1,
    CalendarSyncResult result2,
  ) {
    return CalendarSyncResult(
      eventsCreated: result1.eventsCreated + result2.eventsCreated,
      eventsUpdated: result1.eventsUpdated + result2.eventsUpdated,
      eventsDeleted: result1.eventsDeleted + result2.eventsDeleted,
      errorsEncountered: result1.errorsEncountered + result2.errorsEncountered,
      errorMessages: [...result1.errorMessages, ...result2.errorMessages],
      syncTime: result1.syncTime,
      syncDuration: result1.syncDuration + result2.syncDuration,
    );
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'current_status': _currentStatus.toString(),
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'last_sync_result': _lastSyncResult != null ? {
        'events_created': _lastSyncResult!.eventsCreated,
        'events_updated': _lastSyncResult!.eventsUpdated,
        'events_deleted': _lastSyncResult!.eventsDeleted,
        'errors_encountered': _lastSyncResult!.errorsEncountered,
        'sync_duration_ms': _lastSyncResult!.syncDuration.inMilliseconds,
        'has_changes': _lastSyncResult!.hasChanges,
      } : null,
      'sync_settings': {
        'is_enabled': _syncSettings.isEnabled,
        'enabled_courses_count': _syncSettings.enabledCourseIds.length,
        'reminder_offset_hours': _syncSettings.reminderOffset.inHours,
        'auto_sync': _syncSettings.autoSync,
        'sync_to_device_calendar': _syncSettings.syncToDeviceCalendar,
      },
    };
  }

  /// Check if sync is needed based on settings and last sync time
  bool isSyncNeeded() {
    if (!_syncSettings.isEnabled || !_syncSettings.autoSync) {
      return false;
    }

    if (_lastSyncTime == null) {
      return true;
    }

    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceLastSync >= _syncSettings.autoSyncInterval;
  }

  /// Reset sync status (useful for testing)
  void resetSyncStatus() {
    _currentStatus = CalendarSyncStatus.idle;
    _lastSyncTime = null;
    _lastSyncResult = null;
  }

  /// Cancel ongoing sync (if possible)
  void cancelSync() {
    if (_currentStatus == CalendarSyncStatus.syncing) {
      _currentStatus = CalendarSyncStatus.cancelled;
    }
  }
}

/// Calendar synchronization status
enum CalendarSyncStatus {
  idle,
  syncing,
  completed,
  failed,
  cancelled,
}