import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_settings.g.dart';

/// Notification settings for the application
@JsonSerializable()
class NotificationSettings extends Equatable {
  /// Whether notifications are enabled globally
  final bool isEnabled;
  
  /// Whether assignment reminders are enabled
  final bool assignmentRemindersEnabled;
  
  /// Default reminder time before assignment due date (in minutes)
  final int defaultReminderMinutes;
  
  /// Whether to show notifications for new assignments
  final bool newAssignmentNotifications;
  
  /// Whether to show notifications for assignment updates
  final bool assignmentUpdateNotifications;
  
  /// Course IDs for which notifications are enabled
  final List<int> enabledCourseIds;
  
  /// Quiet hours start time (24-hour format, e.g., 22 for 10 PM)
  final int? quietHoursStart;
  
  /// Quiet hours end time (24-hour format, e.g., 8 for 8 AM)
  final int? quietHoursEnd;
  
  /// Whether to use sound for notifications
  final bool soundEnabled;
  
  /// Whether to use vibration for notifications
  final bool vibrationEnabled;

  const NotificationSettings({
    this.isEnabled = true,
    this.assignmentRemindersEnabled = true,
    this.defaultReminderMinutes = 60, // 1 hour before due date
    this.newAssignmentNotifications = true,
    this.assignmentUpdateNotifications = true,
    this.enabledCourseIds = const [],
    this.quietHoursStart,
    this.quietHoursEnd,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  /// Create a copy with updated values
  NotificationSettings copyWith({
    bool? isEnabled,
    bool? assignmentRemindersEnabled,
    int? defaultReminderMinutes,
    bool? newAssignmentNotifications,
    bool? assignmentUpdateNotifications,
    List<int>? enabledCourseIds,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      assignmentRemindersEnabled: assignmentRemindersEnabled ?? this.assignmentRemindersEnabled,
      defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
      newAssignmentNotifications: newAssignmentNotifications ?? this.newAssignmentNotifications,
      assignmentUpdateNotifications: assignmentUpdateNotifications ?? this.assignmentUpdateNotifications,
      enabledCourseIds: enabledCourseIds ?? this.enabledCourseIds,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  /// Check if notifications should be shown for a specific course
  bool isCourseEnabled(int courseId) {
    if (enabledCourseIds.isEmpty) {
      return true; // If no specific courses are set, enable for all
    }
    return enabledCourseIds.contains(courseId);
  }

  /// Check if current time is within quiet hours
  bool isInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }

    final now = DateTime.now();
    final currentHour = now.hour;

    if (quietHoursStart! <= quietHoursEnd!) {
      // Same day quiet hours (e.g., 22:00 to 08:00 next day)
      return currentHour >= quietHoursStart! && currentHour < quietHoursEnd!;
    } else {
      // Overnight quiet hours (e.g., 22:00 to 08:00 next day)
      return currentHour >= quietHoursStart! || currentHour < quietHoursEnd!;
    }
  }

  @override
  List<Object?> get props => [
        isEnabled,
        assignmentRemindersEnabled,
        defaultReminderMinutes,
        newAssignmentNotifications,
        assignmentUpdateNotifications,
        enabledCourseIds,
        quietHoursStart,
        quietHoursEnd,
        soundEnabled,
        vibrationEnabled,
      ];

  @override
  String toString() {
    return 'NotificationSettings('
        'isEnabled: $isEnabled, '
        'assignmentRemindersEnabled: $assignmentRemindersEnabled, '
        'defaultReminderMinutes: $defaultReminderMinutes, '
        'enabledCourses: ${enabledCourseIds.length})';
  }
}