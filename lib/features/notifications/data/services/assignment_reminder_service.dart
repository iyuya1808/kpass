import 'package:kpass/shared/models/models.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/data/services/local_notification_service.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Service for managing assignment reminder notifications
class AssignmentReminderService {
  final LocalNotificationService _notificationService;
  final NotificationRepository _notificationRepository;

  const AssignmentReminderService(
    this._notificationService,
    this._notificationRepository,
  );

  /// Schedule a reminder for an assignment
  Future<void> scheduleAssignmentReminder({
    required Assignment assignment,
    Duration? customReminderOffset,
    String? courseName,
  }) async {
    try {
      // Check if assignment has a due date
      if (assignment.dueAt == null) {
        throw NotificationException(
          message: 'Cannot schedule reminder for assignment without due date',
          code: 'NO_DUE_DATE',
        );
      }

      // Get notification settings
      final settings = await _notificationRepository.getNotificationSettings();

      // Check if reminders are enabled
      if (!settings.isEnabled || !settings.assignmentRemindersEnabled) {
        return;
      }

      // Check if notifications are enabled for this course
      if (!settings.isCourseEnabled(assignment.courseId)) {
        return;
      }

      // Determine reminder time
      final reminderOffset = customReminderOffset ?? 
          Duration(minutes: settings.defaultReminderMinutes);
      final reminderTime = assignment.dueAt!.subtract(reminderOffset);

      // Don't schedule reminders for past times
      if (reminderTime.isBefore(DateTime.now())) {
        return;
      }

      // Create notification ID
      final notificationId = 'assignment_reminder_${assignment.id}';

      // Create notification
      final notification = AppNotification.assignmentReminder(
        id: notificationId,
        assignmentName: assignment.name,
        dueDate: assignment.dueAt!,
        assignmentId: assignment.id,
        courseId: assignment.courseId,
        courseName: courseName,
        scheduledAt: reminderTime,
      );

      // Schedule the notification
      await _notificationService.scheduleNotification(notification, settings);

      // Store notification in repository
      await _notificationRepository.addNotification(notification);
    } catch (e) {
      if (e is NotificationException) rethrow;
      throw NotificationException(
        message: 'Failed to schedule assignment reminder: ${e.toString()}',
        code: 'REMINDER_SCHEDULING_FAILED',
      );
    }
  }

  /// Schedule reminders for multiple assignments
  Future<AssignmentReminderResult> scheduleMultipleReminders({
    required List<Assignment> assignments,
    Duration? customReminderOffset,
    Map<int, String>? courseNames,
  }) async {
    int scheduled = 0;
    int skipped = 0;
    int failed = 0;
    final List<String> errors = [];

    for (final assignment in assignments) {
      try {
        final courseName = courseNames?[assignment.courseId];
        await scheduleAssignmentReminder(
          assignment: assignment,
          customReminderOffset: customReminderOffset,
          courseName: courseName,
        );
        scheduled++;
      } catch (e) {
        if (e is NotificationException && e.code == 'NO_DUE_DATE') {
          skipped++;
        } else {
          failed++;
          errors.add('Assignment ${assignment.id}: ${e.toString()}');
        }
      }
    }

    return AssignmentReminderResult(
      scheduled: scheduled,
      skipped: skipped,
      failed: failed,
      errors: errors,
    );
  }

  /// Update reminder for an assignment (reschedule if due date changed)
  Future<void> updateAssignmentReminder({
    required Assignment assignment,
    Duration? customReminderOffset,
    String? courseName,
  }) async {
    try {
      // Cancel existing reminder
      await cancelAssignmentReminder(assignment.id);

      // Schedule new reminder
      await scheduleAssignmentReminder(
        assignment: assignment,
        customReminderOffset: customReminderOffset,
        courseName: courseName,
      );
    } catch (e) {
      throw NotificationException(
        message: 'Failed to update assignment reminder: ${e.toString()}',
        code: 'REMINDER_UPDATE_FAILED',
      );
    }
  }

  /// Cancel reminder for an assignment
  Future<void> cancelAssignmentReminder(int assignmentId) async {
    try {
      final notificationId = 'assignment_reminder_$assignmentId';
      
      // Cancel scheduled notification
      await _notificationService.cancelNotification(notificationId);
      
      // Remove from repository
      await _notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to cancel assignment reminder: ${e.toString()}',
        code: 'REMINDER_CANCELLATION_FAILED',
      );
    }
  }

  /// Cancel reminders for multiple assignments
  Future<void> cancelMultipleReminders(List<int> assignmentIds) async {
    for (final assignmentId in assignmentIds) {
      try {
        await cancelAssignmentReminder(assignmentId);
      } catch (e) {
        // Continue canceling other reminders even if one fails
        continue;
      }
    }
  }

  /// Schedule reminder with custom timing options
  Future<void> scheduleCustomReminder({
    required Assignment assignment,
    required List<Duration> reminderOffsets,
    String? courseName,
  }) async {
    if (assignment.dueAt == null) {
      throw NotificationException(
        message: 'Cannot schedule reminder for assignment without due date',
        code: 'NO_DUE_DATE',
      );
    }

    final settings = await _notificationRepository.getNotificationSettings();

    for (int i = 0; i < reminderOffsets.length; i++) {
      final offset = reminderOffsets[i];
      final reminderTime = assignment.dueAt!.subtract(offset);

      // Skip past reminders
      if (reminderTime.isBefore(DateTime.now())) {
        continue;
      }

      final notificationId = 'assignment_reminder_${assignment.id}_$i';
      
      final notification = AppNotification.assignmentReminder(
        id: notificationId,
        assignmentName: assignment.name,
        dueDate: assignment.dueAt!,
        assignmentId: assignment.id,
        courseId: assignment.courseId,
        courseName: courseName,
        scheduledAt: reminderTime,
      );

      await _notificationService.scheduleNotification(notification, settings);
      await _notificationRepository.addNotification(notification);
    }
  }

  /// Get scheduled reminders for an assignment
  Future<List<AppNotification>> getScheduledReminders(int assignmentId) async {
    try {
      final notifications = await _notificationRepository.getNotifications();
      return notifications
          .where((notification) => 
              notification.assignmentId == assignmentId &&
              notification.type == NotificationType.assignmentReminder &&
              notification.scheduledAt != null &&
              !notification.isShown)
          .toList();
    } catch (e) {
      throw NotificationException(
        message: 'Failed to get scheduled reminders: ${e.toString()}',
        code: 'GET_REMINDERS_FAILED',
      );
    }
  }

  /// Get all scheduled reminders
  Future<List<AppNotification>> getAllScheduledReminders() async {
    try {
      final notifications = await _notificationRepository.getNotifications();
      return notifications
          .where((notification) => 
              notification.type == NotificationType.assignmentReminder &&
              notification.scheduledAt != null &&
              !notification.isShown)
          .toList();
    } catch (e) {
      throw NotificationException(
        message: 'Failed to get all scheduled reminders: ${e.toString()}',
        code: 'GET_ALL_REMINDERS_FAILED',
      );
    }
  }

  /// Reschedule all reminders based on updated settings
  Future<AssignmentReminderResult> rescheduleAllReminders({
    required List<Assignment> assignments,
    Map<int, String>? courseNames,
  }) async {
    try {
      // Cancel all existing reminders
      final existingReminders = await getAllScheduledReminders();
      for (final reminder in existingReminders) {
        if (reminder.assignmentId != null) {
          await cancelAssignmentReminder(reminder.assignmentId!);
        }
      }

      // Schedule new reminders with current settings
      return await scheduleMultipleReminders(
        assignments: assignments,
        courseNames: courseNames,
      );
    } catch (e) {
      throw NotificationException(
        message: 'Failed to reschedule reminders: ${e.toString()}',
        code: 'RESCHEDULE_FAILED',
      );
    }
  }

  /// Clean up expired reminders (past due date)
  Future<int> cleanupExpiredReminders() async {
    try {
      final now = DateTime.now();
      final notifications = await _notificationRepository.getNotifications();
      int cleanedUp = 0;

      for (final notification in notifications) {
        if (notification.type == NotificationType.assignmentReminder &&
            notification.scheduledAt != null &&
            notification.scheduledAt!.isBefore(now) &&
            !notification.isShown) {
          
          // Cancel the notification and remove from repository
          await _notificationService.cancelNotification(notification.id);
          await _notificationRepository.deleteNotification(notification.id);
          cleanedUp++;
        }
      }

      return cleanedUp;
    } catch (e) {
      throw NotificationException(
        message: 'Failed to cleanup expired reminders: ${e.toString()}',
        code: 'CLEANUP_FAILED',
      );
    }
  }

  /// Get reminder statistics
  Future<Map<String, dynamic>> getReminderStatistics() async {
    try {
      final notifications = await _notificationRepository.getNotifications();
      final reminders = notifications
          .where((n) => n.type == NotificationType.assignmentReminder)
          .toList();

      final scheduled = reminders
          .where((n) => n.scheduledAt != null && !n.isShown)
          .length;
      
      final shown = reminders
          .where((n) => n.isShown)
          .length;

      final overdue = reminders
          .where((n) => n.scheduledAt != null && 
                       n.scheduledAt!.isBefore(DateTime.now()) && 
                       !n.isShown)
          .length;

      return {
        'total_reminders': reminders.length,
        'scheduled_reminders': scheduled,
        'shown_reminders': shown,
        'overdue_reminders': overdue,
        'reminders_by_course': _groupRemindersByCourse(reminders),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Group reminders by course for statistics
  Map<int, int> _groupRemindersByCourse(List<AppNotification> reminders) {
    final Map<int, int> courseGroups = {};
    
    for (final reminder in reminders) {
      if (reminder.courseId != null) {
        courseGroups[reminder.courseId!] = 
            (courseGroups[reminder.courseId!] ?? 0) + 1;
      }
    }
    
    return courseGroups;
  }

  /// Check if reminder exists for assignment
  Future<bool> hasScheduledReminder(int assignmentId) async {
    try {
      final reminders = await getScheduledReminders(assignmentId);
      return reminders.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get next reminder time for assignment
  Future<DateTime?> getNextReminderTime(int assignmentId) async {
    try {
      final reminders = await getScheduledReminders(assignmentId);
      if (reminders.isEmpty) return null;

      reminders.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
      return reminders.first.scheduledAt;
    } catch (e) {
      return null;
    }
  }
}

/// Result of scheduling multiple assignment reminders
class AssignmentReminderResult {
  final int scheduled;
  final int skipped;
  final int failed;
  final List<String> errors;

  const AssignmentReminderResult({
    required this.scheduled,
    required this.skipped,
    required this.failed,
    required this.errors,
  });

  bool get hasErrors => failed > 0;
  int get total => scheduled + skipped + failed;
  bool get isSuccessful => failed == 0;

  @override
  String toString() {
    return 'AssignmentReminderResult(scheduled: $scheduled, skipped: $skipped, failed: $failed)';
  }
}