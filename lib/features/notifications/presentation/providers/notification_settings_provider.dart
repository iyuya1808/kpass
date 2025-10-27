import 'package:flutter/foundation.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/features/notifications/data/services/hybrid_notification_service.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Provider for managing notification settings
class NotificationSettingsProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final HybridNotificationService _notificationService;
  final CoursesRepository _coursesRepository;

  NotificationSettings _settings = const NotificationSettings();
  List<Course> _availableCourses = [];
  bool _isLoading = false;
  String? _error;
  bool _hasPermissions = false;

  NotificationSettingsProvider(
    this._repository,
    this._notificationService,
    this._coursesRepository,
  );

  // Getters
  NotificationSettings get settings => _settings;
  List<Course> get availableCourses => _availableCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermissions => _hasPermissions;

  /// Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadSettings(),
        _loadCourses(),
        _checkPermissions(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notification settings
  Future<void> _loadSettings() async {
    try {
      _settings = await _repository.getNotificationSettings();
    } catch (e) {
      throw NotificationException(
        message: 'Failed to load notification settings: ${e.toString()}',
        code: 'SETTINGS_LOAD_FAILED',
      );
    }
  }

  /// Load available courses
  Future<void> _loadCourses() async {
    try {
      _availableCourses = await _coursesRepository.getCourses();
    } catch (e) {
      // Courses loading failure shouldn't block settings
      _availableCourses = [];
      if (kDebugMode) {
        print('Failed to load courses for notification settings: $e');
      }
    }
  }

  /// Check notification permissions
  Future<void> _checkPermissions() async {
    try {
      _hasPermissions = await _notificationService.hasPermissions();
    } catch (e) {
      _hasPermissions = false;
      if (kDebugMode) {
        print('Failed to check notification permissions: $e');
      }
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hasPermissions = await _notificationService.requestPermissions();
      return _hasPermissions;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update global notification enabled state
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _updateSettings(_settings.copyWith(isEnabled: enabled));
  }

  /// Update assignment reminders enabled state
  Future<void> setAssignmentRemindersEnabled(bool enabled) async {
    await _updateSettings(_settings.copyWith(assignmentRemindersEnabled: enabled));
  }

  /// Update default reminder time
  Future<void> setDefaultReminderMinutes(int minutes) async {
    await _updateSettings(_settings.copyWith(defaultReminderMinutes: minutes));
  }

  /// Update new assignment notifications enabled state
  Future<void> setNewAssignmentNotificationsEnabled(bool enabled) async {
    await _updateSettings(_settings.copyWith(newAssignmentNotifications: enabled));
  }

  /// Update assignment update notifications enabled state
  Future<void> setAssignmentUpdateNotificationsEnabled(bool enabled) async {
    await _updateSettings(_settings.copyWith(assignmentUpdateNotifications: enabled));
  }

  /// Update sound enabled state
  Future<void> setSoundEnabled(bool enabled) async {
    await _updateSettings(_settings.copyWith(soundEnabled: enabled));
  }

  /// Update vibration enabled state
  Future<void> setVibrationEnabled(bool enabled) async {
    await _updateSettings(_settings.copyWith(vibrationEnabled: enabled));
  }

  /// Set quiet hours
  Future<void> setQuietHours(int? startHour, int? endHour) async {
    await _updateSettings(_settings.copyWith(
      quietHoursStart: startHour,
      quietHoursEnd: endHour,
    ));
  }

  /// Enable notifications for a specific course
  Future<void> enableCourseNotifications(int courseId) async {
    final updatedCourseIds = List<int>.from(_settings.enabledCourseIds);
    if (!updatedCourseIds.contains(courseId)) {
      updatedCourseIds.add(courseId);
      await _updateSettings(_settings.copyWith(enabledCourseIds: updatedCourseIds));
      
      // Subscribe to course notifications via FCM
      try {
        await _notificationService.subscribeToCourse(courseId);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to subscribe to course $courseId: $e');
        }
      }
    }
  }

  /// Disable notifications for a specific course
  Future<void> disableCourseNotifications(int courseId) async {
    final updatedCourseIds = List<int>.from(_settings.enabledCourseIds);
    if (updatedCourseIds.remove(courseId)) {
      await _updateSettings(_settings.copyWith(enabledCourseIds: updatedCourseIds));
      
      // Unsubscribe from course notifications via FCM
      try {
        await _notificationService.unsubscribeFromCourse(courseId);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to unsubscribe from course $courseId: $e');
        }
      }
    }
  }

  /// Toggle course notifications
  Future<void> toggleCourseNotifications(int courseId) async {
    if (_settings.isCourseEnabled(courseId)) {
      await disableCourseNotifications(courseId);
    } else {
      await enableCourseNotifications(courseId);
    }
  }

  /// Enable notifications for all courses
  Future<void> enableAllCourseNotifications() async {
    final allCourseIds = _availableCourses.map((course) => course.id).toList();
    await _updateSettings(_settings.copyWith(enabledCourseIds: allCourseIds));
    
    // Subscribe to all course notifications via FCM
    for (final courseId in allCourseIds) {
      try {
        await _notificationService.subscribeToCourse(courseId);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to subscribe to course $courseId: $e');
        }
      }
    }
  }

  /// Disable notifications for all courses
  Future<void> disableAllCourseNotifications() async {
    final currentCourseIds = List<int>.from(_settings.enabledCourseIds);
    await _updateSettings(_settings.copyWith(enabledCourseIds: []));
    
    // Unsubscribe from all course notifications via FCM
    for (final courseId in currentCourseIds) {
      try {
        await _notificationService.unsubscribeFromCourse(courseId);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to unsubscribe from course $courseId: $e');
        }
      }
    }
  }

  /// Update settings with validation and persistence
  Future<void> _updateSettings(NotificationSettings newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate settings
      _validateSettings(newSettings);
      
      // Update via notification service (handles FCM topic subscriptions)
      await _notificationService.updateNotificationSettings(newSettings);
      
      // Update local state
      _settings = newSettings;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate notification settings
  void _validateSettings(NotificationSettings settings) {
    if (settings.defaultReminderMinutes < 0) {
      throw ValidationException(
        message: 'Reminder time cannot be negative',
        code: 'INVALID_REMINDER_TIME',
      );
    }

    if (settings.defaultReminderMinutes > 10080) { // 7 days in minutes
      throw ValidationException(
        message: 'Reminder time cannot exceed 7 days',
        code: 'REMINDER_TIME_TOO_LONG',
      );
    }

    if (settings.quietHoursStart != null && 
        (settings.quietHoursStart! < 0 || settings.quietHoursStart! > 23)) {
      throw ValidationException(
        message: 'Quiet hours start must be between 0 and 23',
        code: 'INVALID_QUIET_HOURS_START',
      );
    }

    if (settings.quietHoursEnd != null && 
        (settings.quietHoursEnd! < 0 || settings.quietHoursEnd! > 23)) {
      throw ValidationException(
        message: 'Quiet hours end must be between 0 and 23',
        code: 'INVALID_QUIET_HOURS_END',
      );
    }
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    await _updateSettings(const NotificationSettings());
  }

  /// Get reminder time options (in minutes)
  List<ReminderTimeOption> get reminderTimeOptions => [
    const ReminderTimeOption(minutes: 5, label: '5 minutes before'),
    const ReminderTimeOption(minutes: 15, label: '15 minutes before'),
    const ReminderTimeOption(minutes: 30, label: '30 minutes before'),
    const ReminderTimeOption(minutes: 60, label: '1 hour before'),
    const ReminderTimeOption(minutes: 120, label: '2 hours before'),
    const ReminderTimeOption(minutes: 360, label: '6 hours before'),
    const ReminderTimeOption(minutes: 720, label: '12 hours before'),
    const ReminderTimeOption(minutes: 1440, label: '1 day before'),
    const ReminderTimeOption(minutes: 2880, label: '2 days before'),
    const ReminderTimeOption(minutes: 10080, label: '1 week before'),
  ];

  /// Get quiet hours options
  List<QuietHoursOption> get quietHoursOptions => [
    const QuietHoursOption(startHour: null, endHour: null, label: 'No quiet hours'),
    const QuietHoursOption(startHour: 22, endHour: 8, label: '10 PM - 8 AM'),
    const QuietHoursOption(startHour: 23, endHour: 7, label: '11 PM - 7 AM'),
    const QuietHoursOption(startHour: 0, endHour: 8, label: '12 AM - 8 AM'),
    const QuietHoursOption(startHour: 21, endHour: 9, label: '9 PM - 9 AM'),
  ];

  /// Get courses with notification status
  List<CourseNotificationStatus> get coursesWithNotificationStatus {
    return _availableCourses.map((course) => CourseNotificationStatus(
      course: course,
      isEnabled: _settings.isCourseEnabled(course.id),
    )).toList();
  }

  /// Get enabled courses count
  int get enabledCoursesCount => _settings.enabledCourseIds.length;

  /// Get total courses count
  int get totalCoursesCount => _availableCourses.length;

  /// Check if all courses are enabled
  bool get allCoursesEnabled => 
      _availableCourses.isNotEmpty && 
      _settings.enabledCourseIds.length == _availableCourses.length;

  /// Check if no courses are enabled
  bool get noCoursesEnabled => _settings.enabledCourseIds.isEmpty;

  /// Get current quiet hours status
  String get quietHoursStatus {
    if (_settings.quietHoursStart == null || _settings.quietHoursEnd == null) {
      return 'No quiet hours set';
    }
    
    final start = _settings.quietHoursStart!;
    final end = _settings.quietHoursEnd!;
    
    return '${_formatHour(start)} - ${_formatHour(end)}';
  }

  /// Format hour for display
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Check if currently in quiet hours
  bool get isInQuietHours => _settings.isInQuietHours();

  /// Get settings summary for display
  Map<String, String> get settingsSummary => {
    'Notifications': _settings.isEnabled ? 'Enabled' : 'Disabled',
    'Assignment Reminders': _settings.assignmentRemindersEnabled ? 'Enabled' : 'Disabled',
    'Default Reminder Time': _getReminderTimeLabel(_settings.defaultReminderMinutes),
    'New Assignment Alerts': _settings.newAssignmentNotifications ? 'Enabled' : 'Disabled',
    'Update Notifications': _settings.assignmentUpdateNotifications ? 'Enabled' : 'Disabled',
    'Sound': _settings.soundEnabled ? 'Enabled' : 'Disabled',
    'Vibration': _settings.vibrationEnabled ? 'Enabled' : 'Disabled',
    'Quiet Hours': quietHoursStatus,
    'Enabled Courses': '$enabledCoursesCount of $totalCoursesCount',
  };

  /// Get reminder time label for minutes
  String _getReminderTimeLabel(int minutes) {
    final option = reminderTimeOptions
        .where((option) => option.minutes == minutes)
        .firstOrNull;
    return option?.label ?? '$minutes minutes before';
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
}

/// Reminder time option for UI
class ReminderTimeOption {
  final int minutes;
  final String label;

  const ReminderTimeOption({
    required this.minutes,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTimeOption &&
          runtimeType == other.runtimeType &&
          minutes == other.minutes;

  @override
  int get hashCode => minutes.hashCode;
}

/// Quiet hours option for UI
class QuietHoursOption {
  final int? startHour;
  final int? endHour;
  final String label;

  const QuietHoursOption({
    required this.startHour,
    required this.endHour,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuietHoursOption &&
          runtimeType == other.runtimeType &&
          startHour == other.startHour &&
          endHour == other.endHour;

  @override
  int get hashCode => Object.hash(startHour, endHour);
}

/// Course notification status for UI
class CourseNotificationStatus {
  final Course course;
  final bool isEnabled;

  const CourseNotificationStatus({
    required this.course,
    required this.isEnabled,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseNotificationStatus &&
          runtimeType == other.runtimeType &&
          course == other.course &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => Object.hash(course, isEnabled);
}