import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'package:kpass/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:kpass/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:kpass/features/calendar/data/services/calendar_service.dart';
import 'package:kpass/features/calendar/data/services/calendar_event_manager.dart';
import 'package:kpass/features/calendar/data/utils/calendar_permission_handler.dart';

/// Implementation of CalendarRepository
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource _remoteDataSource;
  final CalendarLocalDataSource _localDataSource;
  final CalendarService _calendarService;
  final CalendarEventManager _eventManager;

  const CalendarRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._calendarService,
    this._eventManager,
  );

  @override
  Future<List<CalendarEvent>> getCalendarEvents({bool forceRefresh = false}) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await _localDataSource.isCacheExpired()) {
        final cachedEvents = await _localDataSource.getCachedCalendarEvents();
        if (cachedEvents.isNotEmpty) {
          return ModelUtils.validateCalendarEvents(cachedEvents);
        }
      }

      // Fetch from remote and cache
      final remoteEvents = await _remoteDataSource.getCalendarEvents();
      await _localDataSource.cacheCalendarEvents(remoteEvents);
      
      return ModelUtils.validateCalendarEvents(remoteEvents);
    } on ApiException {
      // If remote fails, try to return cached data
      try {
        final cachedEvents = await _localDataSource.getCachedCalendarEvents();
        return ModelUtils.validateCalendarEvents(cachedEvents);
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get calendar events: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getCalendarEventsInRange(
    DateTime startDate,
    DateTime endDate, {
    bool forceRefresh = false,
  }) async {
    try {
      // For date range queries, always fetch from remote for accuracy
      final remoteEvents = await _remoteDataSource.getCalendarEventsInRange(
        startDate,
        endDate,
      );
      
      return ModelUtils.validateCalendarEvents(remoteEvents);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw RepositoryException(
        message: 'Failed to get calendar events in range: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getCalendarEventsForDate(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      return await getCalendarEventsInRange(
        startOfDay,
        endOfDay,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get calendar events for date: ${e.toString()}',
      );
    }
  }

  @override
  Future<CalendarEvent?> getCalendarEvent(
    String eventId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedEvent = await _localDataSource.getCachedCalendarEvent(eventId);
        if (cachedEvent != null && cachedEvent.isValid()) {
          return cachedEvent;
        }
      }

      // Fetch from remote
      final remoteEvent = await _remoteDataSource.getCalendarEvent(eventId);
      await _localDataSource.cacheCalendarEvent(remoteEvent);
      
      return remoteEvent.isValid() ? remoteEvent : null;
    } on ApiException {
      // If remote fails, try cached data
      try {
        final cachedEvent = await _localDataSource.getCachedCalendarEvent(eventId);
        return cachedEvent?.isValid() == true ? cachedEvent : null;
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get calendar event $eventId: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getAssignmentEvents({bool forceRefresh = false}) async {
    try {
      final events = await getCalendarEvents(forceRefresh: forceRefresh);
      return events.where((event) => event.isAssignmentEvent).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignment events: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getTodayEvents({bool forceRefresh = false}) async {
    try {
      return await getCalendarEventsForDate(DateTime.now(), forceRefresh: forceRefresh);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get today events: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getUpcomingEvents({
    Duration threshold = const Duration(days: 7),
    bool forceRefresh = false,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(threshold);
      
      return await getCalendarEventsInRange(now, endDate, forceRefresh: forceRefresh);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get upcoming events: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> searchCalendarEvents(
    String query, {
    bool forceRefresh = false,
  }) async {
    try {
      final events = await getCalendarEvents(forceRefresh: forceRefresh);
      final lowercaseQuery = query.toLowerCase();
      
      return events.where((event) {
        return event.title.toLowerCase().contains(lowercaseQuery) ||
               (event.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to search calendar events: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<DateTime, List<CalendarEvent>>> getCalendarEventsGroupedByDate({
    bool forceRefresh = false,
  }) async {
    try {
      final events = await getCalendarEvents(forceRefresh: forceRefresh);
      return ModelUtils.groupEventsByDate(events);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get calendar events grouped by date: ${e.toString()}',
      );
    }
  }

  @override
  Future<CalendarEvent> createAssignmentEvent(Assignment assignment) async {
    try {
      // Create event using event manager
      await _eventManager.createAssignmentEvent(assignment);
      
      // Get the created event
      final deviceEvent = await _eventManager.getAssignmentCalendarEvent(assignment.id);
      if (deviceEvent == null) {
        throw CalendarException.eventCreationFailed('Failed to retrieve created event');
      }

      // Convert to CalendarEvent
      return CalendarEvent.fromAssignment(
        assignmentId: assignment.id,
        assignmentName: assignment.name,
        dueDate: assignment.dueAt!,
        description: assignment.description,
      );
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.eventCreationFailed(e.toString());
    }
  }

  @override
  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event) async {
    try {
      // Update via remote data source
      final updatedEvent = await _remoteDataSource.updateCalendarEvent(event);
      
      // Update cache
      await _localDataSource.cacheCalendarEvent(updatedEvent);
      
      return updatedEvent;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw CalendarException.eventUpdateFailed(e.toString());
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      // Delete via remote data source
      await _remoteDataSource.deleteCalendarEvent(eventId);
      
      // Remove from cache
      await _localDataSource.removeCachedCalendarEvent(eventId);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw CalendarException.eventDeletionFailed(e.toString());
    }
  }

  @override
  Future<void> syncAssignmentToDeviceCalendar(Assignment assignment) async {
    try {
      await CalendarPermissionHandler.validatePermissionForOperation('sync assignment');
      await _eventManager.createAssignmentEvent(assignment);
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.syncFailed(e.toString());
    }
  }

  @override
  Future<void> removeAssignmentFromDeviceCalendar(int assignmentId) async {
    try {
      await CalendarPermissionHandler.validatePermissionForOperation('remove assignment');
      await _eventManager.deleteAssignmentEvent(assignmentId);
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.syncFailed(e.toString());
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsNeedingSync() async {
    try {
      // This would typically integrate with AssignmentsRepository
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignments needing sync: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CalendarEvent>> getOrphanedCalendarEvents() async {
    try {
      // Get all Canvas assignment events
      final canvasEvents = await _eventManager.getCanvasAssignmentEvents();
      
      // Convert to CalendarEvent objects
      return canvasEvents.map((deviceEvent) => CalendarEvent(
        id: deviceEvent.id ?? 'unknown',
        title: deviceEvent.title,
        startTime: deviceEvent.startTime,
        description: deviceEvent.description,
        endTime: deviceEvent.endTime,
        isAllDay: deviceEvent.isAllDay,
        location: deviceEvent.location,
        canvasAssignmentId: deviceEvent.metadata['canvas_assignment_id'],
      )).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get orphaned calendar events: ${e.toString()}',
      );
    }
  }

  @override
  Future<CalendarSyncResult> performFullSync() async {
    try {
      await CalendarPermissionHandler.validatePermissionForOperation('full sync');
      
      // This would integrate with AssignmentsRepository to get all assignments
      // For now, return empty sync result
      return CalendarSyncResult(
        eventsCreated: 0,
        eventsUpdated: 0,
        eventsDeleted: 0,
        errorsEncountered: 0,
        errorMessages: [],
        syncTime: DateTime.now(),
        syncDuration: Duration.zero,
      );
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.syncFailed(e.toString());
    }
  }

  @override
  Future<CalendarSyncResult> performIncrementalSync() async {
    try {
      await CalendarPermissionHandler.validatePermissionForOperation('incremental sync');
      
      // This would integrate with AssignmentsRepository to get updated assignments
      // For now, return empty sync result
      return CalendarSyncResult(
        eventsCreated: 0,
        eventsUpdated: 0,
        eventsDeleted: 0,
        errorsEncountered: 0,
        errorMessages: [],
        syncTime: DateTime.now(),
        syncDuration: Duration.zero,
      );
    } catch (e) {
      if (e is CalendarException) rethrow;
      throw CalendarException.syncFailed(e.toString());
    }
  }

  @override
  Future<void> refreshCalendarEvents() async {
    try {
      await getCalendarEvents(forceRefresh: true);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to refresh calendar events: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localDataSource.clearCache();
      _eventManager.clearCache();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to clear cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<CacheStatus> getCacheStatus() async {
    try {
      final metadata = await _localDataSource.getCacheMetadata();
      final isExpired = await _localDataSource.isCacheExpired();
      final age = metadata.lastUpdated.millisecondsSinceEpoch > 0
          ? DateTime.now().difference(metadata.lastUpdated)
          : null;

      return CacheStatus(
        lastUpdated: metadata.lastUpdated.millisecondsSinceEpoch > 0 
            ? metadata.lastUpdated 
            : null,
        itemCount: metadata.itemCount,
        isExpired: isExpired,
        age: age,
      );
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get cache status: ${e.toString()}',
      );
    }
  }

  @override
  Future<CalendarPermissionStatus> checkCalendarPermissions() async {
    try {
      return await _calendarService.checkPermissions();
    } catch (e) {
      throw CalendarException(
        message: 'Failed to check calendar permissions: ${e.toString()}',
        code: 'PERMISSION_CHECK_FAILED',
      );
    }
  }

  @override
  Future<CalendarPermissionStatus> requestCalendarPermissions() async {
    try {
      return await _calendarService.requestPermissions();
    } catch (e) {
      throw CalendarException(
        message: 'Failed to request calendar permissions: ${e.toString()}',
        code: 'PERMISSION_REQUEST_FAILED',
      );
    }
  }

  @override
  Future<CalendarSyncSettings> getSyncSettings() async {
    try {
      // This would typically be stored in shared preferences or secure storage
      // For now, return default settings
      return const CalendarSyncSettings(
        isEnabled: false,
        enabledCourseIds: [],
        reminderOffset: Duration(hours: 1),
        syncToDeviceCalendar: false,
        autoSync: true,
        autoSyncInterval: Duration(hours: 6),
      );
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get sync settings: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateSyncSettings(CalendarSyncSettings settings) async {
    try {
      // This would typically save to shared preferences or secure storage
      // For now, this is a no-op
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to update sync settings: ${e.toString()}',
      );
    }
  }
}