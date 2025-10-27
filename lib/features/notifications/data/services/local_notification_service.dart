import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Service for managing local notifications using flutter_local_notifications
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Function(String?)? _onNotificationTapped;

  /// Initialize the notification service
  Future<void> initialize({
    Function(String?)? onNotificationTapped,
  }) async {
    if (_isInitialized) return;

    _onNotificationTapped = onNotificationTapped;

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: null,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (initialized != true) {
      throw NotificationException(
        message: 'Failed to initialize local notifications',
        code: 'INIT_FAILED',
      );
    }

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
  }

  /// Handle notification tap response
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (_onNotificationTapped != null) {
      _onNotificationTapped!(payload);
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    // Assignment reminders channel
    final AndroidNotificationChannel assignmentChannel =
        AndroidNotificationChannel(
      'assignment_reminders',
      'Assignment Reminders',
      description: 'Notifications for upcoming assignment due dates',
      importance: Importance.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    // New assignments channel
    const AndroidNotificationChannel newAssignmentChannel =
        AndroidNotificationChannel(
      'new_assignments',
      'New Assignments',
      description: 'Notifications for newly posted assignments',
      importance: Importance.defaultImportance,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    // Assignment updates channel
    const AndroidNotificationChannel updateChannel =
        AndroidNotificationChannel(
      'assignment_updates',
      'Assignment Updates',
      description: 'Notifications for assignment changes and updates',
      importance: Importance.defaultImportance,
    );

    // Sync status channel
    const AndroidNotificationChannel syncChannel =
        AndroidNotificationChannel(
      'sync_status',
      'Sync Status',
      description: 'Notifications about sync operations and errors',
      importance: Importance.low,
    );

    // Create channels
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(assignmentChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(newAssignmentChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(updateChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(syncChannel);
  }

  /// Check notification permissions
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), check notification permission
      if (await Permission.notification.isGranted) {
        return true;
      }
      
      // For older Android versions, notifications are enabled by default
      return true;
    } else if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    
    return false;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), request notification permission
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    
    return false;
  }

  /// Show an immediate notification
  Future<void> showNotification(
    AppNotification notification,
    NotificationSettings settings,
  ) async {
    if (!_isInitialized) {
      throw NotificationException(
        message: 'Notification service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    if (!settings.isEnabled) return;

    // Check if notification should be shown for this course
    if (notification.courseId != null && 
        !settings.isCourseEnabled(notification.courseId!)) {
      return;
    }

    // Check quiet hours
    if (settings.isInQuietHours()) return;

    final notificationDetails = _buildNotificationDetails(
      notification,
      settings,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: notification.deepLink,
    );
  }

  /// Schedule a notification for later
  Future<void> scheduleNotification(
    AppNotification notification,
    NotificationSettings settings,
  ) async {
    if (!_isInitialized) {
      throw NotificationException(
        message: 'Notification service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    if (!settings.isEnabled || notification.scheduledAt == null) return;

    // Check if notification should be shown for this course
    if (notification.courseId != null && 
        !settings.isCourseEnabled(notification.courseId!)) {
      return;
    }

    final notificationDetails = _buildNotificationDetails(
      notification,
      settings,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      tz.TZDateTime.from(notification.scheduledAt!, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: notification.deepLink,
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Build platform-specific notification details
  NotificationDetails _buildNotificationDetails(
    AppNotification notification,
    NotificationSettings settings,
  ) {
    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: _mapPriorityToImportance(notification.priority),
      priority: _mapPriorityToPriority(notification.priority),
      playSound: settings.soundEnabled,
      enableVibration: settings.vibrationEnabled,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        notification.body,
        contentTitle: notification.title,
      ),
      actions: _buildNotificationActions(notification),
    );

    // iOS notification details
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: settings.soundEnabled,
      sound: settings.soundEnabled ? 'notification_sound.aiff' : null,
      badgeNumber: null,
      subtitle: _getNotificationSubtitle(notification),
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get channel ID for notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.assignmentReminder:
        return 'assignment_reminders';
      case NotificationType.newAssignment:
        return 'new_assignments';
      case NotificationType.assignmentUpdate:
        return 'assignment_updates';
      case NotificationType.syncComplete:
      case NotificationType.syncError:
        return 'sync_status';
    }
  }

  /// Get channel name for notification type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.assignmentReminder:
        return 'Assignment Reminders';
      case NotificationType.newAssignment:
        return 'New Assignments';
      case NotificationType.assignmentUpdate:
        return 'Assignment Updates';
      case NotificationType.syncComplete:
      case NotificationType.syncError:
        return 'Sync Status';
    }
  }

  /// Get channel description for notification type
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.assignmentReminder:
        return 'Notifications for upcoming assignment due dates';
      case NotificationType.newAssignment:
        return 'Notifications for newly posted assignments';
      case NotificationType.assignmentUpdate:
        return 'Notifications for assignment changes and updates';
      case NotificationType.syncComplete:
      case NotificationType.syncError:
        return 'Notifications about sync operations and errors';
    }
  }

  /// Map notification priority to Android importance
  Importance _mapPriorityToImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  /// Map notification priority to Android priority
  Priority _mapPriorityToPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  /// Build notification actions based on type
  List<AndroidNotificationAction>? _buildNotificationActions(
    AppNotification notification,
  ) {
    switch (notification.type) {
      case NotificationType.assignmentReminder:
        return [
          const AndroidNotificationAction(
            'view_assignment',
            'View Assignment',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Remind Later',
            showsUserInterface: false,
          ),
        ];
      case NotificationType.newAssignment:
        return [
          const AndroidNotificationAction(
            'view_assignment',
            'View Assignment',
            showsUserInterface: true,
          ),
        ];
      case NotificationType.assignmentUpdate:
        return [
          const AndroidNotificationAction(
            'view_changes',
            'View Changes',
            showsUserInterface: true,
          ),
        ];
      case NotificationType.syncError:
        return [
          const AndroidNotificationAction(
            'retry_sync',
            'Retry Sync',
            showsUserInterface: false,
          ),
        ];
      case NotificationType.syncComplete:
        return null;
    }
  }

  /// Get notification subtitle for iOS
  String? _getNotificationSubtitle(AppNotification notification) {
    if (notification.data?['course_name'] != null) {
      return notification.data!['course_name'] as String;
    }
    return null;
  }

  /// Get notification guidance message for permission status
  String getPermissionGuidanceMessage(bool hasPermission) {
    if (hasPermission) {
      return 'Notifications are enabled. You will receive reminders for assignments and updates.';
    } else {
      return 'Notifications are disabled. Please enable them in settings to receive assignment reminders.';
    }
  }

  /// Check if notifications are available on this platform
  bool get isAvailable {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    final pendingNotifications = await getPendingNotifications();
    
    return {
      'is_initialized': _isInitialized,
      'is_available': isAvailable,
      'has_permissions': await hasPermissions(),
      'pending_notifications_count': pendingNotifications.length,
      'pending_notifications': pendingNotifications.map((n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'payload': n.payload,
      }).toList(),
    };
  }

  /// Get status for a specific notification
  Future<Map<String, dynamic>> getNotificationStatus(String notificationId) async {
    final pendingNotifications = await getPendingNotifications();
    final notificationHashCode = notificationId.hashCode;
    
    final pendingNotification = pendingNotifications
        .where((n) => n.id == notificationHashCode)
        .firstOrNull;
    
    return {
      'notification_id': notificationId,
      'hash_code': notificationHashCode,
      'is_pending': pendingNotification != null,
      'pending_notification': pendingNotification != null ? {
        'id': pendingNotification.id,
        'title': pendingNotification.title,
        'body': pendingNotification.body,
        'payload': pendingNotification.payload,
      } : null,
      'service_initialized': _isInitialized,
      'has_permissions': await hasPermissions(),
    };
  }
}