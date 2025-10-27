import 'package:flutter/foundation.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/features/notifications/data/services/hybrid_notification_service.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Provider for managing notification state and operations
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final HybridNotificationService _notificationService;

  NotificationSettings _settings = const NotificationSettings();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _hasPermissions = false;
  bool _fcmAvailable = false;
  String? _fcmToken;

  NotificationProvider(this._repository, this._notificationService);

  // Getters
  NotificationSettings get settings => _settings;
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermissions => _hasPermissions;
  bool get fcmAvailable => _fcmAvailable;
  String? get fcmToken => _fcmToken;
  
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  
  int get unreadCount => unreadNotifications.length;

  /// Initialize the notification provider
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize notification service
      await _notificationService.initialize(
        onNotificationTapped: _handleNotificationTapped,
      );

      // Check permissions
      _hasPermissions = await _notificationService.hasPermissions();
      
      // Check FCM availability and get token
      _fcmAvailable = _notificationService.isFCMAvailable;
      _fcmToken = _notificationService.fcmToken;

      // Load settings and notifications
      await Future.wait([
        _loadSettings(),
        _loadNotifications(),
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

  /// Load notifications
  Future<void> _loadNotifications() async {
    try {
      _notifications = await _repository.getNotifications();
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw NotificationException(
        message: 'Failed to load notifications: ${e.toString()}',
        code: 'NOTIFICATIONS_LOAD_FAILED',
      );
    }
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.saveNotificationSettings(newSettings);
      await _notificationService.updateNotificationSettings(newSettings);
      _settings = newSettings;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update specific setting without full reload
  Future<void> updateSetting<T>(T value, NotificationSettings Function(NotificationSettings, T) updater) async {
    try {
      final newSettings = updater(_settings, value);
      await updateSettings(newSettings);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle notifications for a specific course
  Future<void> toggleCourseNotifications(int courseId, bool enabled) async {
    final currentCourses = List<int>.from(_settings.enabledCourseIds);
    
    if (enabled && !currentCourses.contains(courseId)) {
      currentCourses.add(courseId);
    } else if (!enabled && currentCourses.contains(courseId)) {
      currentCourses.remove(courseId);
    }
    
    await updateSettings(_settings.copyWith(enabledCourseIds: currentCourses));
  }

  /// Set reminder time in minutes
  Future<void> setReminderTime(int minutes) async {
    await updateSettings(_settings.copyWith(defaultReminderMinutes: minutes));
  }

  /// Set quiet hours
  Future<void> setQuietHours(int? startHour, int? endHour) async {
    await updateSettings(_settings.copyWith(
      quietHoursStart: startHour,
      quietHoursEnd: endHour,
    ));
  }

  /// Toggle global notifications
  Future<void> toggleNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(isEnabled: enabled));
  }

  /// Toggle assignment reminders
  Future<void> toggleAssignmentReminders(bool enabled) async {
    await updateSettings(_settings.copyWith(assignmentRemindersEnabled: enabled));
  }

  /// Toggle new assignment notifications
  Future<void> toggleNewAssignmentNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(newAssignmentNotifications: enabled));
  }

  /// Toggle assignment update notifications
  Future<void> toggleAssignmentUpdateNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(assignmentUpdateNotifications: enabled));
  }

  /// Toggle sound
  Future<void> toggleSound(bool enabled) async {
    await updateSettings(_settings.copyWith(soundEnabled: enabled));
  }

  /// Toggle vibration
  Future<void> toggleVibration(bool enabled) async {
    await updateSettings(_settings.copyWith(vibrationEnabled: enabled));
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      _hasPermissions = await _notificationService.requestPermissions();
      notifyListeners();
      return _hasPermissions;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Show a notification immediately
  Future<void> showNotification(AppNotification notification) async {
    try {
      if (!_hasPermissions) {
        throw NotificationException.permissionDenied();
      }

      await _notificationService.showNotification(notification, _settings);
      await _repository.addNotification(notification.markAsShown());
      await _loadNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Schedule a notification for later
  Future<void> scheduleNotification(AppNotification notification) async {
    try {
      if (!_hasPermissions) {
        throw NotificationException.permissionDenied();
      }

      await _notificationService.scheduleNotification(notification, _settings);
      await _repository.addNotification(notification);
      await _loadNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      await _notificationService.cancelNotification(notificationId);
      await _repository.deleteNotification(notificationId);
      await _loadNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      await _loadNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      await _loadNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      await _repository.clearAllNotifications();
      await _loadNotifications();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get notifications for a specific course
  Future<List<AppNotification>> getNotificationsForCourse(int courseId) async {
    try {
      return await _repository.getNotificationsForCourse(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get notifications by type
  Future<List<AppNotification>> getNotificationsByType(NotificationType type) async {
    try {
      return await _repository.getNotificationsByType(type);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Refresh notifications from repository
  Future<void> refreshNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle notification tap
  void _handleNotificationTapped(String? payload) {
    if (payload != null) {
      // Handle deep link navigation
      // This would typically use a navigation service or router
      debugPrint('Notification tapped with payload: $payload');
    }
  }

  /// Get permission guidance message
  String getPermissionGuidanceMessage() {
    return _notificationService.getPermissionGuidanceMessage(_hasPermissions);
  }

  /// Subscribe to course notifications
  Future<void> subscribeToCourse(int courseId) async {
    try {
      await _notificationService.subscribeToCourse(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Unsubscribe from course notifications
  Future<void> unsubscribeFromCourse(int courseId) async {
    try {
      await _notificationService.unsubscribeFromCourse(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh FCM token
  Future<String?> refreshFCMToken() async {
    try {
      final newToken = await _notificationService.refreshFCMToken();
      _fcmToken = newToken;
      notifyListeners();
      return newToken;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get service status
  Map<String, dynamic> get serviceStatus => _notificationService.status;

  /// Check if notifications are available on this platform
  bool get isNotificationAvailable => _notificationService.isAvailable;

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final serviceStats = await _notificationService.getNotificationStatistics();
      final totalCount = await _repository.getNotificationCount();
      final unreadCount = await _repository.getUnreadNotificationCount();

      return {
        ...serviceStats,
        'total_notifications': totalCount,
        'unread_notifications': unreadCount,
        'settings': {
          'is_enabled': _settings.isEnabled,
          'assignment_reminders_enabled': _settings.assignmentRemindersEnabled,
          'default_reminder_minutes': _settings.defaultReminderMinutes,
          'enabled_courses_count': _settings.enabledCourseIds.length,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get notification history with filtering options
  Future<List<AppNotification>> getNotificationHistory({
    NotificationType? type,
    int? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      return await _repository.getNotificationHistory(
        type: type,
        courseId: courseId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get notification delivery status
  Future<Map<String, dynamic>> getNotificationStatus(String notificationId) async {
    try {
      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );
      
      final serviceStatus = await _notificationService.getNotificationStatus(notificationId);
      
      return {
        'id': notification.id,
        'title': notification.title,
        'type': notification.type.toString(),
        'created_at': notification.createdAt.toIso8601String(),
        'scheduled_at': notification.scheduledAt?.toIso8601String(),
        'is_read': notification.isRead,
        'is_shown': notification.isShown,
        'is_overdue': notification.isOverdue,
        'should_show_now': notification.shouldShowNow,
        ...serviceStatus,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get notifications grouped by date
  Map<DateTime, List<AppNotification>> get notificationsByDate {
    final Map<DateTime, List<AppNotification>> grouped = {};
    
    for (final notification in _notifications) {
      final date = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(notification);
    }
    
    return grouped;
  }

  /// Get notifications grouped by type
  Map<NotificationType, List<AppNotification>> get notificationsByType {
    final Map<NotificationType, List<AppNotification>> grouped = {};
    
    for (final notification in _notifications) {
      if (!grouped.containsKey(notification.type)) {
        grouped[notification.type] = [];
      }
      grouped[notification.type]!.add(notification);
    }
    
    return grouped;
  }

  /// Get recent notification activity (last 7 days)
  List<AppNotification> get recentActivity {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notifications
        .where((n) => n.createdAt.isAfter(sevenDaysAgo))
        .toList();
  }

  /// Check if course notifications are enabled
  bool isCourseNotificationsEnabled(int courseId) {
    return _settings.isCourseEnabled(courseId);
  }

  /// Get available reminder time options (in minutes)
  List<int> get availableReminderTimes => [
    15,    // 15 minutes
    30,    // 30 minutes
    60,    // 1 hour
    360,   // 6 hours
    1440,  // 24 hours
    2880,  // 48 hours
    10080, // 1 week
  ];

  /// Get reminder time display text
  String getReminderTimeText(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours hour${hours == 1 ? '' : 's'}';
    } else if (minutes < 10080) {
      final days = minutes ~/ 1440;
      return '$days day${days == 1 ? '' : 's'}';
    } else {
      final weeks = minutes ~/ 10080;
      return '$weeks week${weeks == 1 ? '' : 's'}';
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}