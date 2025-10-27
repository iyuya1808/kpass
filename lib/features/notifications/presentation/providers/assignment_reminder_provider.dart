import 'package:flutter/foundation.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/features/notifications/data/services/assignment_reminder_service.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';

/// Provider for managing assignment reminder scheduling
class AssignmentReminderProvider extends ChangeNotifier {
  final AssignmentReminderService _reminderService;
  final AssignmentsRepository _assignmentsRepository;
  final CoursesRepository _coursesRepository;

  List<AppNotification> _scheduledReminders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _statistics = {};

  AssignmentReminderProvider(
    this._reminderService,
    this._assignmentsRepository,
    this._coursesRepository,
  );

  // Getters
  List<AppNotification> get scheduledReminders => _scheduledReminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get statistics => _statistics;

  /// Initialize the provider
  Future<void> initialize() async {
    await Future.wait([
      loadScheduledReminders(),
      loadStatistics(),
    ]);
  }

  /// Load all scheduled reminders
  Future<void> loadScheduledReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _scheduledReminders = await _reminderService.getAllScheduledReminders();
      _scheduledReminders.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load reminder statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _reminderService.getReminderStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Schedule reminder for a single assignment
  Future<bool> scheduleReminder({
    required Assignment assignment,
    Duration? customReminderOffset,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get course name for better notification
      String? courseName;
      try {
        final courses = await _coursesRepository.getCourses();
        final course = courses.firstWhere((c) => c.id == assignment.courseId);
        courseName = course.name;
      } catch (e) {
        // Course name is optional, continue without it
      }

      await _reminderService.scheduleAssignmentReminder(
        assignment: assignment,
        customReminderOffset: customReminderOffset,
        courseName: courseName,
      );

      await loadScheduledReminders();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Schedule reminders for all assignments
  Future<AssignmentReminderResult> scheduleAllReminders({
    Duration? customReminderOffset,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get all assignments
      final assignments = await _assignmentsRepository.getAssignments();
      
      // Get course names for better notifications
      final courses = await _coursesRepository.getCourses();
      final courseNames = <int, String>{};
      for (final course in courses) {
        courseNames[course.id] = course.name;
      }

      // Schedule reminders
      final result = await _reminderService.scheduleMultipleReminders(
        assignments: assignments,
        customReminderOffset: customReminderOffset,
        courseNames: courseNames,
      );

      await loadScheduledReminders();
      await loadStatistics();
      
      return result;
    } catch (e) {
      _error = e.toString();
      return AssignmentReminderResult(
        scheduled: 0,
        skipped: 0,
        failed: 1,
        errors: [e.toString()],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update reminder for an assignment
  Future<bool> updateReminder({
    required Assignment assignment,
    Duration? customReminderOffset,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get course name
      String? courseName;
      try {
        final courses = await _coursesRepository.getCourses();
        final course = courses.firstWhere((c) => c.id == assignment.courseId);
        courseName = course.name;
      } catch (e) {
        // Course name is optional
      }

      await _reminderService.updateAssignmentReminder(
        assignment: assignment,
        customReminderOffset: customReminderOffset,
        courseName: courseName,
      );

      await loadScheduledReminders();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel reminder for an assignment
  Future<bool> cancelReminder(int assignmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reminderService.cancelAssignmentReminder(assignmentId);
      await loadScheduledReminders();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel multiple reminders
  Future<void> cancelMultipleReminders(List<int> assignmentIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reminderService.cancelMultipleReminders(assignmentIds);
      await loadScheduledReminders();
      await loadStatistics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Schedule custom reminders with multiple timing options
  Future<bool> scheduleCustomReminders({
    required Assignment assignment,
    required List<Duration> reminderOffsets,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get course name
      String? courseName;
      try {
        final courses = await _coursesRepository.getCourses();
        final course = courses.firstWhere((c) => c.id == assignment.courseId);
        courseName = course.name;
      } catch (e) {
        // Course name is optional
      }

      await _reminderService.scheduleCustomReminder(
        assignment: assignment,
        reminderOffsets: reminderOffsets,
        courseName: courseName,
      );

      await loadScheduledReminders();
      await loadStatistics();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reschedule all reminders (useful when settings change)
  Future<AssignmentReminderResult> rescheduleAllReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get all assignments
      final assignments = await _assignmentsRepository.getAssignments();
      
      // Get course names
      final courses = await _coursesRepository.getCourses();
      final courseNames = <int, String>{};
      for (final course in courses) {
        courseNames[course.id] = course.name;
      }

      // Reschedule all reminders
      final result = await _reminderService.rescheduleAllReminders(
        assignments: assignments,
        courseNames: courseNames,
      );

      await loadScheduledReminders();
      await loadStatistics();
      
      return result;
    } catch (e) {
      _error = e.toString();
      return AssignmentReminderResult(
        scheduled: 0,
        skipped: 0,
        failed: 1,
        errors: [e.toString()],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clean up expired reminders
  Future<int> cleanupExpiredReminders() async {
    try {
      final cleanedUp = await _reminderService.cleanupExpiredReminders();
      await loadScheduledReminders();
      await loadStatistics();
      return cleanedUp;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Get reminders for a specific assignment
  Future<List<AppNotification>> getRemindersForAssignment(int assignmentId) async {
    try {
      return await _reminderService.getScheduledReminders(assignmentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Check if assignment has scheduled reminders
  Future<bool> hasReminders(int assignmentId) async {
    try {
      return await _reminderService.hasScheduledReminder(assignmentId);
    } catch (e) {
      return false;
    }
  }

  /// Get next reminder time for assignment
  Future<DateTime?> getNextReminderTime(int assignmentId) async {
    try {
      return await _reminderService.getNextReminderTime(assignmentId);
    } catch (e) {
      return null;
    }
  }

  /// Get reminders grouped by course
  Map<int, List<AppNotification>> get remindersByCourse {
    final Map<int, List<AppNotification>> grouped = {};
    
    for (final reminder in _scheduledReminders) {
      if (reminder.courseId != null) {
        grouped[reminder.courseId!] ??= [];
        grouped[reminder.courseId!]!.add(reminder);
      }
    }
    
    return grouped;
  }

  /// Get reminders for today
  List<AppNotification> get todayReminders {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _scheduledReminders.where((reminder) {
      if (reminder.scheduledAt == null) return false;
      return reminder.scheduledAt!.isAfter(startOfDay) && 
             reminder.scheduledAt!.isBefore(endOfDay);
    }).toList();
  }

  /// Get upcoming reminders (next 7 days)
  List<AppNotification> get upcomingReminders {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _scheduledReminders.where((reminder) {
      if (reminder.scheduledAt == null) return false;
      return reminder.scheduledAt!.isAfter(now) && 
             reminder.scheduledAt!.isBefore(nextWeek);
    }).toList();
  }

  /// Get overdue reminders (should have been shown but weren't)
  List<AppNotification> get overdueReminders {
    final now = DateTime.now();

    return _scheduledReminders.where((reminder) {
      if (reminder.scheduledAt == null || reminder.isShown) return false;
      return reminder.scheduledAt!.isBefore(now);
    }).toList();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get formatted statistics for display
  Map<String, String> get formattedStatistics {
    return {
      'Total Reminders': _statistics['total_reminders']?.toString() ?? '0',
      'Scheduled': _statistics['scheduled_reminders']?.toString() ?? '0',
      'Shown': _statistics['shown_reminders']?.toString() ?? '0',
      'Overdue': _statistics['overdue_reminders']?.toString() ?? '0',
    };
  }
}