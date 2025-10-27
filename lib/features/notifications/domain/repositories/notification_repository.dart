import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';

/// Repository interface for managing notification data
abstract class NotificationRepository {
  /// Get current notification settings
  Future<NotificationSettings> getNotificationSettings();

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings);

  /// Get all notifications
  Future<List<AppNotification>> getNotifications();

  /// Get unread notifications
  Future<List<AppNotification>> getUnreadNotifications();

  /// Add a new notification
  Future<void> addNotification(AppNotification notification);

  /// Update an existing notification
  Future<void> updateNotification(AppNotification notification);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Clear all notifications
  Future<void> clearAllNotifications();

  /// Get notifications for a specific course
  Future<List<AppNotification>> getNotificationsForCourse(int courseId);

  /// Get notifications by type
  Future<List<AppNotification>> getNotificationsByType(NotificationType type);

  /// Check if notification exists
  Future<bool> notificationExists(String notificationId);

  /// Get notification count
  Future<int> getNotificationCount();

  /// Get unread notification count
  Future<int> getUnreadNotificationCount();

  /// Save notification settings
  Future<void> saveNotificationSettings(NotificationSettings settings);

  /// Get notification history with filtering options
  Future<List<AppNotification>> getNotificationHistory({
    NotificationType? type,
    int? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
}