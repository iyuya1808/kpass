import 'package:kpass/shared/models/models.dart';
import 'package:kpass/features/notifications/data/services/assignment_reminder_service.dart';
import 'package:kpass/features/notifications/data/services/local_notification_service.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Manager for handling assignment-related notifications
/// Coordinates between assignment updates and notification scheduling
class AssignmentNotificationManager {
  final AssignmentReminderService _reminderService;
  final LocalNotificationService _notificationService;
  final NotificationRepository _notificationRepository;
  final AssignmentsRepository _assignmentsRepository;
  final CoursesRepository _coursesRepository;

  const AssignmentNotificationManager(
    this._reminderService,
    this._notificationService,
    this._notificationRepository,
    this._assignmentsRepository,
    this._coursesRepository,
  );

  /// Handle new assignment detected
  Future<void> handleNewAssignment(Assignment assignment) async {
    try {
      final settings = await _notificationRepository.getNotificationSettings();
      
      // Show new assignment notification if enabled
      if (settings.isEnabled && 
          settings.newAssignmentNotifications &&
          settings.isCourseEnabled(assignment.courseId)) {
        
        await _showNewAssignmentNotification(assignment, settings);
      }

      // Schedule reminder if assignment has due date
      if (assignment.dueAt != null) {
        final courseName = await _getCourseName(assignment.courseId);
        await _reminderService.scheduleAssignmentReminder(
          assignment: assignment,
          courseName: courseName,
        );
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to handle new assignment: ${e.toString()}',
        code: 'NEW_ASSIGNMENT_FAILED',
      );
    }
  }

  /// Handle assignment update
  Future<void> handleAssignmentUpdate(
    Assignment oldAssignment,
    Assignment newAssignment,
  ) async {
    try {
      final settings = await _notificationRepository.getNotificationSettings();
      
      // Check if due date changed
      final dueDateChanged = oldAssignment.dueAt != newAssignment.dueAt;
      
      // Check if assignment details changed significantly
      final significantChange = _hasSignificantChange(oldAssignment, newAssignment);

      // Show update notification if enabled and there's a significant change
      if (settings.isEnabled && 
          settings.assignmentUpdateNotifications &&
          settings.isCourseEnabled(newAssignment.courseId) &&
          significantChange) {
        
        await _showAssignmentUpdateNotification(
          oldAssignment,
          newAssignment,
          settings,
        );
      }

      // Update reminder if due date changed
      if (dueDateChanged) {
        final courseName = await _getCourseName(newAssignment.courseId);
        
        if (newAssignment.dueAt != null) {
          // Update reminder with new due date
          await _reminderService.updateAssignmentReminder(
            assignment: newAssignment,
            courseName: courseName,
          );
        } else {
          // Cancel reminder if due date was removed
          await _reminderService.cancelAssignmentReminder(newAssignment.id);
        }
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to handle assignment update: ${e.toString()}',
        code: 'ASSIGNMENT_UPDATE_FAILED',
      );
    }
  }

  /// Handle assignment deletion/completion
  Future<void> handleAssignmentRemoval(int assignmentId) async {
    try {
      // Cancel any scheduled reminders
      await _reminderService.cancelAssignmentReminder(assignmentId);
      
      // Remove any related notifications
      await _removeAssignmentNotifications(assignmentId);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to handle assignment removal: ${e.toString()}',
        code: 'ASSIGNMENT_REMOVAL_FAILED',
      );
    }
  }

  /// Sync all assignments and update notifications accordingly
  Future<AssignmentNotificationSyncResult> syncAllAssignments() async {
    try {
      final assignments = await _assignmentsRepository.getAssignments();
      final courses = await _coursesRepository.getCourses();
      final courseNames = <int, String>{};
      
      for (final course in courses) {
        courseNames[course.id] = course.name;
      }

      // Get existing reminders
      final existingReminders = await _reminderService.getAllScheduledReminders();
      final existingAssignmentIds = existingReminders
          .map((r) => r.assignmentId)
          .where((id) => id != null)
          .cast<int>()
          .toSet();

      // Current assignment IDs with due dates
      final currentAssignmentIds = assignments
          .where((a) => a.dueAt != null)
          .map((a) => a.id)
          .toSet();

      // Find assignments that need new reminders
      final newAssignmentIds = currentAssignmentIds
          .difference(existingAssignmentIds);
      
      // Find assignments that no longer exist (need cleanup)
      final removedAssignmentIds = existingAssignmentIds
          .difference(currentAssignmentIds);

      int remindersScheduled = 0;
      int remindersUpdated = 0;
      int remindersRemoved = 0;
      final List<String> errors = [];

      // Schedule reminders for new assignments
      for (final assignmentId in newAssignmentIds) {
        try {
          final assignment = assignments.firstWhere((a) => a.id == assignmentId);
          await _reminderService.scheduleAssignmentReminder(
            assignment: assignment,
            courseName: courseNames[assignment.courseId],
          );
          remindersScheduled++;
        } catch (e) {
          errors.add('Failed to schedule reminder for assignment $assignmentId: $e');
        }
      }

      // Update existing reminders (check for due date changes)
      for (final assignment in assignments) {
        if (assignment.dueAt != null && existingAssignmentIds.contains(assignment.id)) {
          try {
            // Check if reminder needs updating by comparing with existing
            final existingReminder = existingReminders
                .where((r) => r.assignmentId == assignment.id)
                .firstOrNull;
            
            if (existingReminder != null && _needsReminderUpdate(assignment, existingReminder)) {
              await _reminderService.updateAssignmentReminder(
                assignment: assignment,
                courseName: courseNames[assignment.courseId],
              );
              remindersUpdated++;
            }
          } catch (e) {
            errors.add('Failed to update reminder for assignment ${assignment.id}: $e');
          }
        }
      }

      // Remove reminders for deleted assignments
      for (final assignmentId in removedAssignmentIds) {
        try {
          await _reminderService.cancelAssignmentReminder(assignmentId);
          remindersRemoved++;
        } catch (e) {
          errors.add('Failed to remove reminder for assignment $assignmentId: $e');
        }
      }

      return AssignmentNotificationSyncResult(
        remindersScheduled: remindersScheduled,
        remindersUpdated: remindersUpdated,
        remindersRemoved: remindersRemoved,
        errors: errors,
      );
    } catch (e) {
      throw NotificationException(
        message: 'Failed to sync assignment notifications: ${e.toString()}',
        code: 'SYNC_FAILED',
      );
    }
  }

  /// Show immediate notification for new assignment
  Future<void> _showNewAssignmentNotification(
    Assignment assignment,
    NotificationSettings settings,
  ) async {
    final courseName = await _getCourseName(assignment.courseId);
    
    final notification = AppNotification.newAssignment(
      id: 'new_assignment_${assignment.id}_${DateTime.now().millisecondsSinceEpoch}',
      assignmentName: assignment.name,
      dueDate: assignment.dueAt ?? DateTime.now().add(const Duration(days: 7)),
      assignmentId: assignment.id,
      courseId: assignment.courseId,
      courseName: courseName,
    );

    await _notificationService.showNotification(notification, settings);
    await _notificationRepository.addNotification(notification.markAsShown());
  }

  /// Show notification for assignment update
  Future<void> _showAssignmentUpdateNotification(
    Assignment oldAssignment,
    Assignment newAssignment,
    NotificationSettings settings,
  ) async {
    final courseName = await _getCourseName(newAssignment.courseId);
    final updateDescription = _getUpdateDescription(oldAssignment, newAssignment);
    
    final notification = AppNotification.assignmentUpdate(
      id: 'update_assignment_${newAssignment.id}_${DateTime.now().millisecondsSinceEpoch}',
      assignmentName: newAssignment.name,
      assignmentId: newAssignment.id,
      courseId: newAssignment.courseId,
      courseName: courseName,
      updateDescription: updateDescription,
    );

    await _notificationService.showNotification(notification, settings);
    await _notificationRepository.addNotification(notification.markAsShown());
  }

  /// Get course name by ID
  Future<String?> _getCourseName(int courseId) async {
    try {
      final courses = await _coursesRepository.getCourses();
      final course = courses.where((c) => c.id == courseId).firstOrNull;
      return course?.name;
    } catch (e) {
      return null;
    }
  }

  /// Check if assignment has significant changes worth notifying about
  bool _hasSignificantChange(Assignment oldAssignment, Assignment newAssignment) {
    return oldAssignment.name != newAssignment.name ||
           oldAssignment.description != newAssignment.description ||
           oldAssignment.dueAt != newAssignment.dueAt ||
           oldAssignment.pointsPossible != newAssignment.pointsPossible;
  }

  /// Get description of what changed in the assignment
  String _getUpdateDescription(Assignment oldAssignment, Assignment newAssignment) {
    final changes = <String>[];
    
    if (oldAssignment.name != newAssignment.name) {
      changes.add('title changed');
    }
    if (oldAssignment.dueAt != newAssignment.dueAt) {
      changes.add('due date changed');
    }
    if (oldAssignment.pointsPossible != newAssignment.pointsPossible) {
      changes.add('points changed');
    }
    if (oldAssignment.description != newAssignment.description) {
      changes.add('description updated');
    }
    
    if (changes.isEmpty) {
      return 'Assignment details updated';
    }
    
    return changes.join(', ');
  }

  /// Check if reminder needs updating based on assignment changes
  bool _needsReminderUpdate(Assignment assignment, AppNotification existingReminder) {
    // Check if due date in reminder matches current assignment due date
    final reminderDueDate = existingReminder.data?['due_date'];
    if (reminderDueDate != null) {
      final existingDueDate = DateTime.tryParse(reminderDueDate);
      return existingDueDate != assignment.dueAt;
    }
    
    return false;
  }

  /// Remove all notifications related to an assignment
  Future<void> _removeAssignmentNotifications(int assignmentId) async {
    final notifications = await _notificationRepository.getNotifications();
    final assignmentNotifications = notifications
        .where((n) => n.assignmentId == assignmentId)
        .toList();

    for (final notification in assignmentNotifications) {
      await _notificationRepository.deleteNotification(notification.id);
      
      // Cancel if it's a scheduled notification
      if (notification.scheduledAt != null && !notification.isShown) {
        await _notificationService.cancelNotification(notification.id);
      }
    }
  }

  /// Get notification statistics for assignments
  Future<Map<String, dynamic>> getAssignmentNotificationStatistics() async {
    try {
      final notifications = await _notificationRepository.getNotifications();
      final assignmentNotifications = notifications
          .where((n) => n.assignmentId != null)
          .toList();

      final reminderNotifications = assignmentNotifications
          .where((n) => n.type == NotificationType.assignmentReminder)
          .toList();
      
      final newAssignmentNotifications = assignmentNotifications
          .where((n) => n.type == NotificationType.newAssignment)
          .toList();
      
      final updateNotifications = assignmentNotifications
          .where((n) => n.type == NotificationType.assignmentUpdate)
          .toList();

      return {
        'total_assignment_notifications': assignmentNotifications.length,
        'reminder_notifications': reminderNotifications.length,
        'new_assignment_notifications': newAssignmentNotifications.length,
        'update_notifications': updateNotifications.length,
        'scheduled_reminders': reminderNotifications
            .where((n) => n.scheduledAt != null && !n.isShown)
            .length,
        'shown_reminders': reminderNotifications
            .where((n) => n.isShown)
            .length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

/// Result of syncing assignment notifications
class AssignmentNotificationSyncResult {
  final int remindersScheduled;
  final int remindersUpdated;
  final int remindersRemoved;
  final List<String> errors;

  const AssignmentNotificationSyncResult({
    required this.remindersScheduled,
    required this.remindersUpdated,
    required this.remindersRemoved,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get totalChanges => remindersScheduled + remindersUpdated + remindersRemoved;
  bool get isSuccessful => errors.isEmpty;

  @override
  String toString() {
    return 'AssignmentNotificationSyncResult('
        'scheduled: $remindersScheduled, '
        'updated: $remindersUpdated, '
        'removed: $remindersRemoved, '
        'errors: ${errors.length})';
  }
}