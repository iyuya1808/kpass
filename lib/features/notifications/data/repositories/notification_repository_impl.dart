import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Implementation of NotificationRepository using SharedPreferences
class NotificationRepositoryImpl implements NotificationRepository {
  static const String _settingsKey = 'notification_settings';
  static const String _notificationsKey = 'notifications';
  
  final SharedPreferences _prefs;

  const NotificationRepositoryImpl(this._prefs);

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson == null) {
        // Return default settings if none exist
        return const NotificationSettings();
      }
      
      final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
      return NotificationSettings.fromJson(settingsMap);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to load notification settings: ${e.toString()}',
        code: 'SETTINGS_LOAD_FAILED',
      );
    }
  }

  @override
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final settingsJson = json.encode(settings.toJson());
      await _prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to save notification settings: ${e.toString()}',
        code: 'SETTINGS_SAVE_FAILED',
      );
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final notificationsJson = _prefs.getString(_notificationsKey);
      if (notificationsJson == null) {
        return [];
      }
      
      final notificationsList = json.decode(notificationsJson) as List<dynamic>;
      return notificationsList
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NotificationException(
        message: 'Failed to load notifications: ${e.toString()}',
        code: 'NOTIFICATIONS_LOAD_FAILED',
      );
    }
  }

  @override
  Future<List<AppNotification>> getUnreadNotifications() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).toList();
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    try {
      final notifications = await getNotifications();
      
      // Check if notification already exists
      final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex != -1) {
        // Update existing notification
        notifications[existingIndex] = notification;
      } else {
        // Add new notification
        notifications.add(notification);
      }
      
      // Keep only the most recent 100 notifications
      if (notifications.length > 100) {
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifications.removeRange(100, notifications.length);
      }
      
      await _saveNotifications(notifications);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to add notification: ${e.toString()}',
        code: 'NOTIFICATION_ADD_FAILED',
      );
    }
  }

  @override
  Future<void> updateNotification(AppNotification notification) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notification.id);
      
      if (index == -1) {
        throw NotificationException(
          message: 'Notification not found: ${notification.id}',
          code: 'NOTIFICATION_NOT_FOUND',
        );
      }
      
      notifications[index] = notification;
      await _saveNotifications(notifications);
    } catch (e) {
      if (e is NotificationException) rethrow;
      throw NotificationException(
        message: 'Failed to update notification: ${e.toString()}',
        code: 'NOTIFICATION_UPDATE_FAILED',
      );
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((notification) => notification.id == notificationId);
      await _saveNotifications(notifications);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to delete notification: ${e.toString()}',
        code: 'NOTIFICATION_DELETE_FAILED',
      );
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index != -1) {
        notifications[index] = notifications[index].markAsRead();
        await _saveNotifications(notifications);
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to mark notification as read: ${e.toString()}',
        code: 'NOTIFICATION_MARK_READ_FAILED',
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final notifications = await getNotifications();
      final updatedNotifications = notifications
          .map((notification) => notification.markAsRead())
          .toList();
      await _saveNotifications(updatedNotifications);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to mark all notifications as read: ${e.toString()}',
        code: 'NOTIFICATIONS_MARK_ALL_READ_FAILED',
      );
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      await _prefs.remove(_notificationsKey);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to clear notifications: ${e.toString()}',
        code: 'NOTIFICATIONS_CLEAR_FAILED',
      );
    }
  }

  @override
  Future<List<AppNotification>> getNotificationsForCourse(int courseId) async {
    final notifications = await getNotifications();
    return notifications
        .where((notification) => notification.courseId == courseId)
        .toList();
  }

  @override
  Future<List<AppNotification>> getNotificationsByType(NotificationType type) async {
    final notifications = await getNotifications();
    return notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  @override
  Future<bool> notificationExists(String notificationId) async {
    final notifications = await getNotifications();
    return notifications.any((notification) => notification.id == notificationId);
  }

  @override
  Future<int> getNotificationCount() async {
    final notifications = await getNotifications();
    return notifications.length;
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    final notifications = await getUnreadNotifications();
    return notifications.length;
  }

  @override
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    await updateNotificationSettings(settings);
  }

  @override
  Future<List<AppNotification>> getNotificationHistory({
    NotificationType? type,
    int? courseId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var notifications = await getNotifications();
      
      // Apply filters
      if (type != null) {
        notifications = notifications.where((n) => n.type == type).toList();
      }
      
      if (courseId != null) {
        notifications = notifications.where((n) => n.courseId == courseId).toList();
      }
      
      if (startDate != null) {
        notifications = notifications.where((n) => n.createdAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        notifications = notifications.where((n) => n.createdAt.isBefore(endDate)).toList();
      }
      
      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Apply limit
      if (limit != null && notifications.length > limit) {
        notifications = notifications.take(limit).toList();
      }
      
      return notifications;
    } catch (e) {
      throw NotificationException(
        message: 'Failed to get notification history: ${e.toString()}',
        code: 'NOTIFICATION_HISTORY_FAILED',
      );
    }
  }

  /// Save notifications to SharedPreferences
  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    try {
      final notificationsJson = json.encode(
        notifications.map((notification) => notification.toJson()).toList(),
      );
      await _prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to save notifications: ${e.toString()}',
        code: 'NOTIFICATIONS_SAVE_FAILED',
      );
    }
  }
}