import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

/// Types of notifications in the app
enum NotificationType {
  @JsonValue('assignment_reminder')
  assignmentReminder,
  @JsonValue('new_assignment')
  newAssignment,
  @JsonValue('assignment_update')
  assignmentUpdate,
  @JsonValue('sync_complete')
  syncComplete,
  @JsonValue('sync_error')
  syncError,
}

/// Priority levels for notifications
enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Represents a notification in the app
@JsonSerializable()
class AppNotification extends Equatable {
  /// Unique identifier for the notification
  final String id;
  
  /// Title of the notification
  final String title;
  
  /// Body text of the notification
  final String body;
  
  /// Type of notification
  final NotificationType type;
  
  /// Priority level
  final NotificationPriority priority;
  
  /// When the notification was created
  final DateTime createdAt;
  
  /// When the notification should be shown (for scheduled notifications)
  final DateTime? scheduledAt;
  
  /// Whether the notification has been read
  final bool isRead;
  
  /// Whether the notification has been shown to the user
  final bool isShown;
  
  /// Associated assignment ID (if applicable)
  final int? assignmentId;
  
  /// Associated course ID (if applicable)
  final int? courseId;
  
  /// Additional data for the notification
  final Map<String, dynamic>? data;
  
  /// Deep link URL for when notification is tapped
  final String? deepLink;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.priority = NotificationPriority.normal,
    this.scheduledAt,
    this.isRead = false,
    this.isShown = false,
    this.assignmentId,
    this.courseId,
    this.data,
    this.deepLink,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  /// Create an assignment reminder notification
  factory AppNotification.assignmentReminder({
    required String id,
    required String assignmentName,
    required DateTime dueDate,
    required int assignmentId,
    required int courseId,
    String? courseName,
    DateTime? scheduledAt,
  }) {
    final timeUntilDue = dueDate.difference(DateTime.now());
    final timeText = _formatTimeUntilDue(timeUntilDue);
    
    return AppNotification(
      id: id,
      title: 'Assignment Due Soon',
      body: '$assignmentName is due $timeText${courseName != null ? ' in $courseName' : ''}',
      type: NotificationType.assignmentReminder,
      priority: timeUntilDue.inHours <= 1 ? NotificationPriority.high : NotificationPriority.normal,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      assignmentId: assignmentId,
      courseId: courseId,
      deepLink: '/assignment/$assignmentId',
      data: {
        'assignment_name': assignmentName,
        'due_date': dueDate.toIso8601String(),
        'course_name': courseName,
      },
    );
  }

  /// Create a new assignment notification
  factory AppNotification.newAssignment({
    required String id,
    required String assignmentName,
    required DateTime dueDate,
    required int assignmentId,
    required int courseId,
    String? courseName,
  }) {
    return AppNotification(
      id: id,
      title: 'New Assignment',
      body: '$assignmentName has been posted${courseName != null ? ' in $courseName' : ''}',
      type: NotificationType.newAssignment,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      assignmentId: assignmentId,
      courseId: courseId,
      deepLink: '/assignment/$assignmentId',
      data: {
        'assignment_name': assignmentName,
        'due_date': dueDate.toIso8601String(),
        'course_name': courseName,
      },
    );
  }

  /// Create an assignment update notification
  factory AppNotification.assignmentUpdate({
    required String id,
    required String assignmentName,
    required int assignmentId,
    required int courseId,
    String? courseName,
    String? updateDescription,
  }) {
    return AppNotification(
      id: id,
      title: 'Assignment Updated',
      body: '$assignmentName has been updated${courseName != null ? ' in $courseName' : ''}',
      type: NotificationType.assignmentUpdate,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      assignmentId: assignmentId,
      courseId: courseId,
      deepLink: '/assignment/$assignmentId',
      data: {
        'assignment_name': assignmentName,
        'course_name': courseName,
        'update_description': updateDescription,
      },
    );
  }

  /// Create a sync complete notification
  factory AppNotification.syncComplete({
    required String id,
    required int newAssignments,
    required int updatedAssignments,
  }) {
    String body;
    if (newAssignments > 0 && updatedAssignments > 0) {
      body = '$newAssignments new and $updatedAssignments updated assignments';
    } else if (newAssignments > 0) {
      body = '$newAssignments new assignments found';
    } else if (updatedAssignments > 0) {
      body = '$updatedAssignments assignments updated';
    } else {
      body = 'All assignments are up to date';
    }

    return AppNotification(
      id: id,
      title: 'Sync Complete',
      body: body,
      type: NotificationType.syncComplete,
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
      deepLink: '/dashboard',
      data: {
        'new_assignments': newAssignments,
        'updated_assignments': updatedAssignments,
      },
    );
  }

  /// Create a sync error notification
  factory AppNotification.syncError({
    required String id,
    required String errorMessage,
  }) {
    return AppNotification(
      id: id,
      title: 'Sync Failed',
      body: 'Unable to sync assignments: $errorMessage',
      type: NotificationType.syncError,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      deepLink: '/settings',
      data: {
        'error_message': errorMessage,
      },
    );
  }

  /// Mark notification as read
  AppNotification markAsRead() {
    return copyWith(isRead: true);
  }

  /// Mark notification as shown
  AppNotification markAsShown() {
    return copyWith(isShown: true);
  }

  /// Create a copy with updated values
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? isRead,
    bool? isShown,
    int? assignmentId,
    int? courseId,
    Map<String, dynamic>? data,
    String? deepLink,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      isShown: isShown ?? this.isShown,
      assignmentId: assignmentId ?? this.assignmentId,
      courseId: courseId ?? this.courseId,
      data: data ?? this.data,
      deepLink: deepLink ?? this.deepLink,
    );
  }

  /// Check if notification is overdue (scheduled time has passed)
  bool get isOverdue {
    if (scheduledAt == null) return false;
    return DateTime.now().isAfter(scheduledAt!);
  }

  /// Check if notification should be shown now
  bool get shouldShowNow {
    if (isShown) return false;
    if (scheduledAt == null) return true;
    return DateTime.now().isAfter(scheduledAt!);
  }

  /// Format time until due for display
  static String _formatTimeUntilDue(Duration timeUntilDue) {
    if (timeUntilDue.isNegative) {
      return 'overdue';
    } else if (timeUntilDue.inDays > 0) {
      return 'in ${timeUntilDue.inDays} day${timeUntilDue.inDays == 1 ? '' : 's'}';
    } else if (timeUntilDue.inHours > 0) {
      return 'in ${timeUntilDue.inHours} hour${timeUntilDue.inHours == 1 ? '' : 's'}';
    } else if (timeUntilDue.inMinutes > 0) {
      return 'in ${timeUntilDue.inMinutes} minute${timeUntilDue.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'very soon';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        priority,
        createdAt,
        scheduledAt,
        isRead,
        isShown,
        assignmentId,
        courseId,
        data,
        deepLink,
      ];

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, priority: $priority)';
  }
}