import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/features/calendar/data/services/calendar_service.dart';
import 'package:kpass/features/notifications/presentation/providers/notification_provider.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/models/course.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Service responsible for performing background synchronization
class BackgroundSyncService {
  final CoursesRepository _coursesRepository;
  final AssignmentsRepository _assignmentsRepository;
  final CalendarService _calendarService;
  final NotificationProvider _notificationProvider;
  final Connectivity _connectivity;

  BackgroundSyncService({
    required CoursesRepository coursesRepository,
    required AssignmentsRepository assignmentsRepository,
    required CalendarService calendarService,
    required NotificationProvider notificationProvider,
    required Connectivity connectivity,
  })  : _coursesRepository = coursesRepository,
        _assignmentsRepository = assignmentsRepository,
        _calendarService = calendarService,
        _notificationProvider = notificationProvider,
        _connectivity = connectivity;

  /// Perform complete background synchronization
  Future<BackgroundSyncResult> performBackgroundSync({
    bool forceFullSync = false,
  }) async {
    if (kDebugMode) {
      print('Starting background sync...');
    }

    final syncResult = BackgroundSyncResult();
    
    try {
      // Check network connectivity
      if (!await _hasNetworkConnectivity()) {
        throw BackgroundSyncException(
          message: 'No network connectivity available',
          code: 'NO_NETWORK',
        );
      }

      // Check authentication
      if (!await _isAuthenticated()) {
        throw BackgroundSyncException(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        );
      }

      // Perform sync operations
      await _syncCourses(syncResult, forceFullSync);
      await _syncAssignments(syncResult, forceFullSync);
      await _updateCalendarEvents(syncResult);
      await _scheduleNotifications(syncResult);

      syncResult.isSuccess = true;
      syncResult.completedAt = DateTime.now();

      if (kDebugMode) {
        print('Background sync completed successfully: $syncResult');
      }

      // Send success notification if there are updates
      if (syncResult.hasUpdates) {
        await _sendSyncCompleteNotification(syncResult);
      }

    } catch (e) {
      syncResult.isSuccess = false;
      syncResult.error = e.toString();
      syncResult.completedAt = DateTime.now();

      if (kDebugMode) {
        print('Background sync failed: $e');
      }

      // Send error notification for critical failures
      if (e is! BackgroundSyncException) {
        await _sendSyncErrorNotification(e.toString());
      } else {
        final exception = e;
        if (exception.code != 'NO_NETWORK') {
          await _sendSyncErrorNotification(e.toString());
        }
      }
    }

    return syncResult;
  }

  /// Sync courses from Canvas API
  Future<void> _syncCourses(BackgroundSyncResult result, bool forceFullSync) async {
    try {
      if (kDebugMode) {
        print('Syncing courses...');
      }

      // Get current courses from local storage
      final localCourses = await _coursesRepository.getCourses();
      
      // Fetch courses from Canvas API (using repository which handles parsing)
      final remoteCourses = await _coursesRepository.getCourses(forceRefresh: true);
      
      // Detect changes
      final courseChanges = _detectCourseChanges(localCourses, remoteCourses);
      
      if (courseChanges.hasChanges || forceFullSync) {
        // Update local storage
        await _coursesRepository.saveCourses(remoteCourses);
        
        // Update sync result
        result.newCourses = courseChanges.newCourses.length;
        result.updatedCourses = courseChanges.updatedCourses.length;
        result.removedCourses = courseChanges.removedCourses.length;
        
        if (kDebugMode) {
          print('Course sync: ${result.newCourses} new, ${result.updatedCourses} updated, ${result.removedCourses} removed');
        }
      }
    } catch (e) {
      throw BackgroundSyncException(
        message: 'Failed to sync courses: ${e.toString()}',
        code: 'COURSE_SYNC_FAILED',
      );
    }
  }

  /// Sync assignments from Canvas API
  Future<void> _syncAssignments(BackgroundSyncResult result, bool forceFullSync) async {
    try {
      if (kDebugMode) {
        print('Syncing assignments...');
      }

      // Get current assignments from local storage
      final localAssignments = await _assignmentsRepository.getAllAssignments();
      
      // Fetch assignments from repository (which handles parsing)
      final allRemoteAssignments = await _assignmentsRepository.getAssignments(forceRefresh: true);
      
      // Detect changes
      final assignmentChanges = _detectAssignmentChanges(localAssignments, allRemoteAssignments);
      
      if (assignmentChanges.hasChanges || forceFullSync) {
        // Update local storage
        for (final assignment in allRemoteAssignments) {
          await _assignmentsRepository.saveAssignment(assignment);
        }
        
        // Remove assignments that no longer exist
        for (final removedAssignment in assignmentChanges.removedAssignments) {
          await _assignmentsRepository.deleteAssignment(removedAssignment.id);
        }
        
        // Update sync result
        result.newAssignments = assignmentChanges.newAssignments.length;
        result.updatedAssignments = assignmentChanges.updatedAssignments.length;
        result.removedAssignments = assignmentChanges.removedAssignments.length;
        
        // Store changes for later processing
        result.newAssignmentsList = assignmentChanges.newAssignments;
        result.updatedAssignmentsList = assignmentChanges.updatedAssignments;
        
        if (kDebugMode) {
          print('Assignment sync: ${result.newAssignments} new, ${result.updatedAssignments} updated, ${result.removedAssignments} removed');
        }
      }
    } catch (e) {
      throw BackgroundSyncException(
        message: 'Failed to sync assignments: ${e.toString()}',
        code: 'ASSIGNMENT_SYNC_FAILED',
      );
    }
  }

  /// Update calendar events based on assignment changes
  Future<void> _updateCalendarEvents(BackgroundSyncResult result) async {
    try {
      if (!result.hasAssignmentUpdates) return;

      if (kDebugMode) {
        print('Updating calendar events...');
      }

      // Check if calendar permissions are available
      if (!await _calendarService.hasPermissions()) {
        if (kDebugMode) {
          print('Calendar permissions not available, skipping calendar update');
        }
        return;
      }

      int calendarEventsCreated = 0;
      int calendarEventsUpdated = 0;

      // Create calendar events for new assignments
      for (final assignment in result.newAssignmentsList) {
        if (assignment.dueAt != null) {
          try {
            await _calendarService.createAssignmentEvent(assignment);
            calendarEventsCreated++;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to create calendar event for assignment ${assignment.id}: $e');
            }
          }
        }
      }

      // Update calendar events for modified assignments
      for (final assignment in result.updatedAssignmentsList) {
        if (assignment.dueAt != null) {
          try {
            await _calendarService.updateAssignmentEvent(assignment);
            calendarEventsUpdated++;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to update calendar event for assignment ${assignment.id}: $e');
            }
          }
        }
      }

      result.calendarEventsCreated = calendarEventsCreated;
      result.calendarEventsUpdated = calendarEventsUpdated;

      if (kDebugMode) {
        print('Calendar update: $calendarEventsCreated created, $calendarEventsUpdated updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Calendar update failed: $e');
      }
      // Don't throw here as calendar update is not critical
    }
  }

  /// Schedule notifications for new and updated assignments
  Future<void> _scheduleNotifications(BackgroundSyncResult result) async {
    try {
      if (!result.hasAssignmentUpdates) return;

      if (kDebugMode) {
        print('Scheduling notifications...');
      }

      // Check if notifications are enabled
      if (!_notificationProvider.settings.isEnabled) {
        if (kDebugMode) {
          print('Notifications disabled, skipping notification scheduling');
        }
        return;
      }

      int notificationsScheduled = 0;

      // Schedule notifications for new assignments
      for (final assignment in result.newAssignmentsList) {
        if (assignment.dueAt != null && 
            _notificationProvider.settings.newAssignmentNotifications &&
            _notificationProvider.settings.isCourseEnabled(assignment.courseId)) {
          
          try {
            final notification = AppNotification.newAssignment(
              id: 'new_assignment_${assignment.id}',
              assignmentName: assignment.name,
              dueDate: assignment.dueAt!,
              assignmentId: assignment.id,
              courseId: assignment.courseId,
              courseName: assignment.courseName,
            );
            
            await _notificationProvider.showNotification(notification);
            notificationsScheduled++;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to schedule notification for new assignment ${assignment.id}: $e');
            }
          }
        }

        // Schedule reminder notifications
        if (assignment.dueAt != null && 
            _notificationProvider.settings.assignmentRemindersEnabled &&
            _notificationProvider.settings.isCourseEnabled(assignment.courseId)) {
          
          try {
            final reminderTime = assignment.dueAt!.subtract(
              Duration(minutes: _notificationProvider.settings.defaultReminderMinutes),
            );
            
            if (reminderTime.isAfter(DateTime.now())) {
              final reminderNotification = AppNotification.assignmentReminder(
                id: 'reminder_${assignment.id}',
                assignmentName: assignment.name,
                dueDate: assignment.dueAt!,
                assignmentId: assignment.id,
                courseId: assignment.courseId,
                courseName: assignment.courseName,
                scheduledAt: reminderTime,
              );
              
              await _notificationProvider.scheduleNotification(reminderNotification);
              notificationsScheduled++;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to schedule reminder for assignment ${assignment.id}: $e');
            }
          }
        }
      }

      // Send update notifications for modified assignments
      for (final assignment in result.updatedAssignmentsList) {
        if (_notificationProvider.settings.assignmentUpdateNotifications &&
            _notificationProvider.settings.isCourseEnabled(assignment.courseId)) {
          
          try {
            final notification = AppNotification.assignmentUpdate(
              id: 'update_assignment_${assignment.id}',
              assignmentName: assignment.name,
              assignmentId: assignment.id,
              courseId: assignment.courseId,
              courseName: assignment.courseName,
            );
            
            await _notificationProvider.showNotification(notification);
            notificationsScheduled++;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to schedule update notification for assignment ${assignment.id}: $e');
            }
          }
        }
      }

      result.notificationsScheduled = notificationsScheduled;

      if (kDebugMode) {
        print('Notifications scheduled: $notificationsScheduled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification scheduling failed: $e');
      }
      // Don't throw here as notification scheduling is not critical
    }
  }

  /// Send sync completion notification
  Future<void> _sendSyncCompleteNotification(BackgroundSyncResult result) async {
    try {
      final notification = AppNotification.syncComplete(
        id: 'sync_complete_${DateTime.now().millisecondsSinceEpoch}',
        newAssignments: result.newAssignments,
        updatedAssignments: result.updatedAssignments,
      );
      
      await _notificationProvider.showNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send sync complete notification: $e');
      }
    }
  }

  /// Send sync error notification
  Future<void> _sendSyncErrorNotification(String error) async {
    try {
      final notification = AppNotification.syncError(
        id: 'sync_error_${DateTime.now().millisecondsSinceEpoch}',
        errorMessage: error,
      );
      
      await _notificationProvider.showNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send sync error notification: $e');
      }
    }
  }

  /// Check network connectivity
  Future<bool> _hasNetworkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is authenticated
  Future<bool> _isAuthenticated() async {
    try {
      // This would typically check if we have a valid token
      // For now, we'll assume authentication is handled elsewhere
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Detect changes in courses
  CourseChanges _detectCourseChanges(List<Course> local, List<Course> remote) {
    final changes = CourseChanges();
    
    // Create maps for efficient lookup
    final localMap = {for (var course in local) course.id: course};
    final remoteMap = {for (var course in remote) course.id: course};
    
    // Find new and updated courses
    for (final remoteCourse in remote) {
      final localCourse = localMap[remoteCourse.id];
      if (localCourse == null) {
        changes.newCourses.add(remoteCourse);
      } else if (_courseHasChanged(localCourse, remoteCourse)) {
        changes.updatedCourses.add(remoteCourse);
      }
    }
    
    // Find removed courses
    for (final localCourse in local) {
      if (!remoteMap.containsKey(localCourse.id)) {
        changes.removedCourses.add(localCourse);
      }
    }
    
    return changes;
  }

  /// Detect changes in assignments
  AssignmentChanges _detectAssignmentChanges(List<Assignment> local, List<Assignment> remote) {
    final changes = AssignmentChanges();
    
    // Create maps for efficient lookup
    final localMap = {for (var assignment in local) assignment.id: assignment};
    final remoteMap = {for (var assignment in remote) assignment.id: assignment};
    
    // Find new and updated assignments
    for (final remoteAssignment in remote) {
      final localAssignment = localMap[remoteAssignment.id];
      if (localAssignment == null) {
        changes.newAssignments.add(remoteAssignment);
      } else if (_assignmentHasChanged(localAssignment, remoteAssignment)) {
        changes.updatedAssignments.add(remoteAssignment);
      }
    }
    
    // Find removed assignments
    for (final localAssignment in local) {
      if (!remoteMap.containsKey(localAssignment.id)) {
        changes.removedAssignments.add(localAssignment);
      }
    }
    
    return changes;
  }

  /// Check if course has changed
  bool _courseHasChanged(Course local, Course remote) {
    return local.name != remote.name ||
           local.courseCode != remote.courseCode ||
           local.updatedAt != remote.updatedAt;
  }

  /// Check if assignment has changed
  bool _assignmentHasChanged(Assignment local, Assignment remote) {
    return local.name != remote.name ||
           local.description != remote.description ||
           local.dueAt != remote.dueAt ||
           local.pointsPossible != remote.pointsPossible ||
           local.submissionTypes != remote.submissionTypes ||
           local.updatedAt != remote.updatedAt;
  }
}

/// Result of background synchronization
class BackgroundSyncResult {
  bool isSuccess = false;
  DateTime? completedAt;
  String? error;
  
  // Course changes
  int newCourses = 0;
  int updatedCourses = 0;
  int removedCourses = 0;
  
  // Assignment changes
  int newAssignments = 0;
  int updatedAssignments = 0;
  int removedAssignments = 0;
  
  // Assignment lists for further processing
  List<Assignment> newAssignmentsList = [];
  List<Assignment> updatedAssignmentsList = [];
  
  // Calendar events
  int calendarEventsCreated = 0;
  int calendarEventsUpdated = 0;
  
  // Notifications
  int notificationsScheduled = 0;
  
  bool get hasUpdates => 
      newCourses > 0 || 
      updatedCourses > 0 || 
      removedCourses > 0 ||
      newAssignments > 0 || 
      updatedAssignments > 0 || 
      removedAssignments > 0;
  
  bool get hasAssignmentUpdates => 
      newAssignments > 0 || 
      updatedAssignments > 0;
  
  @override
  String toString() {
    return 'BackgroundSyncResult('
        'success: $isSuccess, '
        'courses: +$newCourses ~$updatedCourses -$removedCourses, '
        'assignments: +$newAssignments ~$updatedAssignments -$removedAssignments, '
        'calendar: +$calendarEventsCreated ~$calendarEventsUpdated, '
        'notifications: $notificationsScheduled'
        ')';
  }
}

/// Course change detection result
class CourseChanges {
  List<Course> newCourses = [];
  List<Course> updatedCourses = [];
  List<Course> removedCourses = [];
  
  bool get hasChanges => 
      newCourses.isNotEmpty || 
      updatedCourses.isNotEmpty || 
      removedCourses.isNotEmpty;
}

/// Assignment change detection result
class AssignmentChanges {
  List<Assignment> newAssignments = [];
  List<Assignment> updatedAssignments = [];
  List<Assignment> removedAssignments = [];
  
  bool get hasChanges => 
      newAssignments.isNotEmpty || 
      updatedAssignments.isNotEmpty || 
      removedAssignments.isNotEmpty;
}
