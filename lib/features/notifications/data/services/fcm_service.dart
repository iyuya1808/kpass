import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart' as app_notifications;
import 'package:kpass/features/notifications/data/services/local_notification_service.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Service for managing Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final firebase_messaging.FirebaseMessaging _firebaseMessaging = firebase_messaging.FirebaseMessaging.instance;
  LocalNotificationService? _localNotificationService;
  NotificationRepository? _notificationRepository;
  
  bool _isInitialized = false;
  String? _fcmToken;
  Function(firebase_messaging.RemoteMessage)? _onMessageReceived;
  Function(firebase_messaging.RemoteMessage)? _onMessageOpenedApp;
  Function(String?)? _onTokenRefresh;

  /// Initialize FCM service
  Future<void> initialize({
    LocalNotificationService? localNotificationService,
    NotificationRepository? notificationRepository,
    Function(firebase_messaging.RemoteMessage)? onMessageReceived,
    Function(firebase_messaging.RemoteMessage)? onMessageOpenedApp,
    Function(String?)? onTokenRefresh,
  }) async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already initialized
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      _localNotificationService = localNotificationService;
      _notificationRepository = notificationRepository;
      _onMessageReceived = onMessageReceived;
      _onMessageOpenedApp = onMessageOpenedApp;
      _onTokenRefresh = onTokenRefresh;

      // Request permission for notifications
      await _requestPermission();

      // Get initial FCM token
      await _getToken();

      // Set up message handlers
      await _setupMessageHandlers();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;
    } catch (e) {
      throw NotificationException(
        message: 'Failed to initialize FCM: ${e.toString()}',
        code: 'FCM_INIT_FAILED',
      );
    }
  }

  /// Request notification permissions
  Future<firebase_messaging.NotificationSettings> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('FCM Permission granted: ${settings.authorizationStatus}');
      }

      return settings;
    } catch (e) {
      throw NotificationException(
        message: 'Failed to request FCM permissions: ${e.toString()}',
        code: 'FCM_PERMISSION_FAILED',
      );
    }
  }

  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      return _fcmToken;
    } catch (e) {
      throw NotificationException(
        message: 'Failed to get FCM token: ${e.toString()}',
        code: 'FCM_TOKEN_FAILED',
      );
    }
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    firebase_messaging.FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    firebase_messaging.FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is opened from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(firebase_messaging.RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('Received foreground message: ${message.messageId}');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
      }

      // Convert FCM message to app notification and show locally
      await _showLocalNotificationFromFCM(message);

      // Call custom handler if provided
      _onMessageReceived?.call(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling foreground message: $e');
      }
    }
  }

  /// Handle messages when app is opened
  void _handleMessageOpenedApp(firebase_messaging.RemoteMessage message) {
    try {
      if (kDebugMode) {
        print('App opened from message: ${message.messageId}');
      }

      // Call custom handler if provided
      _onMessageOpenedApp?.call(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message opened app: $e');
      }
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    try {
      _fcmToken = token;
      
      if (kDebugMode) {
        print('FCM Token refreshed: $token');
      }

      // Call custom handler if provided
      _onTokenRefresh?.call(token);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling token refresh: $e');
      }
    }
  }

  /// Show local notification from FCM message
  Future<void> _showLocalNotificationFromFCM(firebase_messaging.RemoteMessage message) async {
    if (_localNotificationService == null || _notificationRepository == null) {
      return;
    }

    try {
      // Get notification settings
      final settings = await _notificationRepository!.getNotificationSettings();
      
      // Don't show if notifications are disabled
      if (!settings.isEnabled) return;

      // Create app notification from FCM message
      final appNotification = _createAppNotificationFromFCM(message);
      
      // Show local notification
      await _localNotificationService!.showNotification(appNotification, settings);
      
      // Store in repository
      await _notificationRepository!.addNotification(appNotification.markAsShown());
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification from FCM: $e');
      }
    }
  }

  /// Create app notification from FCM message
  AppNotification _createAppNotificationFromFCM(firebase_messaging.RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    
    // Determine notification type from data
    final typeString = data['type'] ?? 'sync_complete';
    final type = _parseNotificationType(typeString);
    
    // Extract IDs from data
    final assignmentId = data['assignment_id'] != null 
        ? int.tryParse(data['assignment_id']) 
        : null;
    final courseId = data['course_id'] != null 
        ? int.tryParse(data['course_id']) 
        : null;

    return AppNotification(
      id: 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
      title: notification?.title ?? 'Notification',
      body: notification?.body ?? 'You have a new notification',
      type: type,
      priority: _parseNotificationPriority(data['priority']),
      createdAt: DateTime.now(),
      assignmentId: assignmentId,
      courseId: courseId,
      deepLink: data['deep_link'],
      data: data,
    );
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'assignment_reminder':
        return NotificationType.assignmentReminder;
      case 'new_assignment':
        return NotificationType.newAssignment;
      case 'assignment_update':
        return NotificationType.assignmentUpdate;
      case 'sync_error':
        return NotificationType.syncError;
      default:
        return NotificationType.syncComplete;
    }
  }

  /// Parse notification priority from string
  NotificationPriority _parseNotificationPriority(String? priorityString) {
    if (priorityString == null) return NotificationPriority.normal;
    
    switch (priorityString.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to subscribe to topic $topic: ${e.toString()}',
        code: 'FCM_SUBSCRIBE_FAILED',
      );
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to unsubscribe from topic $topic: ${e.toString()}',
        code: 'FCM_UNSUBSCRIBE_FAILED',
      );
    }
  }

  /// Subscribe to course-specific topics
  Future<void> subscribeToCourseTopics(List<int> courseIds) async {
    for (final courseId in courseIds) {
      try {
        await subscribeToTopic('course_$courseId');
      } catch (e) {
        if (kDebugMode) {
          print('Failed to subscribe to course $courseId: $e');
        }
      }
    }
  }

  /// Unsubscribe from course-specific topics
  Future<void> unsubscribeFromCourseTopics(List<int> courseIds) async {
    for (final courseId in courseIds) {
      try {
        await unsubscribeFromTopic('course_$courseId');
      } catch (e) {
        if (kDebugMode) {
          print('Failed to unsubscribe from course $courseId: $e');
        }
      }
    }
  }

  /// Update topic subscriptions based on notification settings
  Future<void> updateTopicSubscriptions(app_notifications.NotificationSettings settings) async {
    try {
      // Subscribe to general topics if notifications are enabled
      if (settings.isEnabled) {
        await subscribeToTopic('general');
        
        if (settings.assignmentRemindersEnabled) {
          await subscribeToTopic('assignment_reminders');
        } else {
          await unsubscribeFromTopic('assignment_reminders');
        }
        
        if (settings.newAssignmentNotifications) {
          await subscribeToTopic('new_assignments');
        } else {
          await unsubscribeFromTopic('new_assignments');
        }
        
        if (settings.assignmentUpdateNotifications) {
          await subscribeToTopic('assignment_updates');
        } else {
          await unsubscribeFromTopic('assignment_updates');
        }
        
        // Subscribe to course-specific topics
        await subscribeToCourseTopics(settings.enabledCourseIds);
      } else {
        // Unsubscribe from all topics if notifications are disabled
        await unsubscribeFromTopic('general');
        await unsubscribeFromTopic('assignment_reminders');
        await unsubscribeFromTopic('new_assignments');
        await unsubscribeFromTopic('assignment_updates');
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to update topic subscriptions: ${e.toString()}',
        code: 'FCM_TOPIC_UPDATE_FAILED',
      );
    }
  }

  /// Set background message handler
  static Future<void> setBackgroundMessageHandler(
    Future<void> Function(firebase_messaging.RemoteMessage) handler,
  ) async {
    firebase_messaging.FirebaseMessaging.onBackgroundMessage(handler);
  }

  /// Check if FCM is available on this platform
  bool get isAvailable {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Get FCM statistics
  Future<Map<String, dynamic>> getFCMStatistics() async {
    return {
      'is_initialized': _isInitialized,
      'is_available': isAvailable,
      'has_token': _fcmToken != null,
      'token_length': _fcmToken?.length ?? 0,
    };
  }

  /// Refresh FCM token
  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      return await _getToken();
    } catch (e) {
      throw NotificationException(
        message: 'Failed to refresh FCM token: ${e.toString()}',
        code: 'FCM_TOKEN_REFRESH_FAILED',
      );
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      
      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to delete FCM token: ${e.toString()}',
        code: 'FCM_TOKEN_DELETE_FAILED',
      );
    }
  }

  /// Get notification settings from Firebase
  Future<app_notifications.NotificationSettings> getNotificationSettings() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      
      return app_notifications.NotificationSettings(
        isEnabled: settings.authorizationStatus == firebase_messaging.AuthorizationStatus.authorized,
        soundEnabled: settings.sound == firebase_messaging.AppleNotificationSetting.enabled,
        // Add other settings as needed
      );
    } catch (e) {
      throw NotificationException(
        message: 'Failed to get FCM notification settings: ${e.toString()}',
        code: 'FCM_SETTINGS_FAILED',
      );
    }
  }

  /// Handle notification tap from FCM
  void handleNotificationTap(Map<String, dynamic> data) {
    try {
      final deepLink = data['deep_link'] as String?;
      if (deepLink != null) {
        // Handle deep link navigation
        // This would typically use a navigation service or router
        if (kDebugMode) {
          print('FCM notification tapped with deep link: $deepLink');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling FCM notification tap: $e');
      }
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(firebase_messaging.RemoteMessage message) async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  // Handle background message processing here
  // Note: Limited processing capabilities in background
}