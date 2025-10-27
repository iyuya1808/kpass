import 'package:flutter/foundation.dart';
import 'package:kpass/features/notifications/data/services/local_notification_service.dart';
import 'package:kpass/features/notifications/data/services/fcm_service.dart';
import 'package:kpass/features/notifications/domain/entities/app_notification.dart';
import 'package:kpass/features/notifications/domain/entities/notification_settings.dart';
import 'package:kpass/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Hybrid notification service that combines local notifications and FCM
/// Provides fallback to local notifications when FCM is unavailable
class HybridNotificationService {
  final LocalNotificationService _localNotificationService;
  final FCMService _fcmService;
  final NotificationRepository _notificationRepository;

  bool _isInitialized = false;
  bool _fcmAvailable = false;
  Function(String?)? _onNotificationTapped;

  HybridNotificationService(
    this._localNotificationService,
    this._fcmService,
    this._notificationRepository,
  );

  /// Initialize the hybrid notification service
  Future<void> initialize({
    Function(String?)? onNotificationTapped,
  }) async {
    if (_isInitialized) return;

    try {
      _onNotificationTapped = onNotificationTapped;

      // Always initialize local notifications
      await _localNotificationService.initialize(
        onNotificationTapped: _handleNotificationTapped,
      );

      // Try to initialize FCM if available
      if (_fcmService.isAvailable) {
        try {
          await _fcmService.initialize(
            localNotificationService: _localNotificationService,
            notificationRepository: _notificationRepository,
            onMessageReceived: _handleFCMMessage,
            onMessageOpenedApp: _handleFCMMessageOpened,
            onTokenRefresh: _handleFCMTokenRefresh,
          );
          _fcmAvailable = true;
          
          if (kDebugMode) {
            print('FCM initialized successfully');
          }
        } catch (e) {
          _fcmAvailable = false;
          if (kDebugMode) {
            print('FCM initialization failed, using local notifications only: $e');
          }
        }
      } else {
        _fcmAvailable = false;
        if (kDebugMode) {
          print('FCM not available on this platform, using local notifications only');
        }
      }

      _isInitialized = true;
    } catch (e) {
      throw NotificationException(
        message: 'Failed to initialize hybrid notification service: ${e.toString()}',
        code: 'HYBRID_INIT_FAILED',
      );
    }
  }

  /// Check notification permissions
  Future<bool> hasPermissions() async {
    // Check local notification permissions first
    final localPermissions = await _localNotificationService.hasPermissions();
    
    if (_fcmAvailable) {
      // If FCM is available, check FCM permissions too
      try {
        final fcmSettings = await _fcmService.getNotificationSettings();
        return localPermissions && fcmSettings.isEnabled;
      } catch (e) {
        // If FCM permission check fails, fall back to local permissions
        return localPermissions;
      }
    }
    
    return localPermissions;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // Request local notification permissions
    final localPermissions = await _localNotificationService.requestPermissions();
    
    if (_fcmAvailable) {
      // If FCM is available, FCM permissions are handled during initialization
      return localPermissions && _fcmService.isInitialized;
    }
    
    return localPermissions;
  }

  /// Show immediate notification
  Future<void> showNotification(
    AppNotification notification,
    NotificationSettings settings,
  ) async {
    if (!_isInitialized) {
      throw NotificationException(
        message: 'Hybrid notification service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    try {
      // Always use local notifications for immediate display
      await _localNotificationService.showNotification(notification, settings);
      
      // Store notification in repository
      await _notificationRepository.addNotification(notification.markAsShown());
    } catch (e) {
      throw NotificationException(
        message: 'Failed to show notification: ${e.toString()}',
        code: 'SHOW_NOTIFICATION_FAILED',
      );
    }
  }

  /// Schedule notification for later
  Future<void> scheduleNotification(
    AppNotification notification,
    NotificationSettings settings,
  ) async {
    if (!_isInitialized) {
      throw NotificationException(
        message: 'Hybrid notification service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    try {
      // Use local notifications for scheduling
      // FCM doesn't support client-side scheduling
      await _localNotificationService.scheduleNotification(notification, settings);
      
      // Store notification in repository
      await _notificationRepository.addNotification(notification);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to schedule notification: ${e.toString()}',
        code: 'SCHEDULE_NOTIFICATION_FAILED',
      );
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      // Cancel local notification
      await _localNotificationService.cancelNotification(notificationId);
      
      // Remove from repository
      await _notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      throw NotificationException(
        message: 'Failed to cancel notification: ${e.toString()}',
        code: 'CANCEL_NOTIFICATION_FAILED',
      );
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      // Cancel all local notifications
      await _localNotificationService.cancelAllNotifications();
      
      // Clear repository
      await _notificationRepository.clearAllNotifications();
    } catch (e) {
      throw NotificationException(
        message: 'Failed to cancel all notifications: ${e.toString()}',
        code: 'CANCEL_ALL_FAILED',
      );
    }
  }

  /// Update notification settings and sync with FCM topics
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      // Save settings to repository
      await _notificationRepository.updateNotificationSettings(settings);
      
      // Update FCM topic subscriptions if FCM is available
      if (_fcmAvailable) {
        try {
          await _fcmService.updateTopicSubscriptions(settings);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to update FCM topic subscriptions: $e');
          }
          // Don't throw error, as local notifications can still work
        }
      }
    } catch (e) {
      throw NotificationException(
        message: 'Failed to update notification settings: ${e.toString()}',
        code: 'UPDATE_SETTINGS_FAILED',
      );
    }
  }

  /// Subscribe to course notifications
  Future<void> subscribeToCourse(int courseId) async {
    if (_fcmAvailable) {
      try {
        await _fcmService.subscribeToTopic('course_$courseId');
      } catch (e) {
        if (kDebugMode) {
          print('Failed to subscribe to course $courseId via FCM: $e');
        }
      }
    }
  }

  /// Unsubscribe from course notifications
  Future<void> unsubscribeFromCourse(int courseId) async {
    if (_fcmAvailable) {
      try {
        await _fcmService.unsubscribeFromTopic('course_$courseId');
      } catch (e) {
        if (kDebugMode) {
          print('Failed to unsubscribe from course $courseId via FCM: $e');
        }
      }
    }
  }

  /// Handle FCM message received in foreground
  void _handleFCMMessage(dynamic message) {
    try {
      if (kDebugMode) {
        print('FCM message received in hybrid service');
      }
      // FCM service already handles showing local notification
      // Additional processing can be added here if needed
    } catch (e) {
      if (kDebugMode) {
        print('Error handling FCM message: $e');
      }
    }
  }

  /// Handle FCM message when app is opened
  void _handleFCMMessageOpened(dynamic message) {
    try {
      if (kDebugMode) {
        print('FCM message opened app in hybrid service');
      }
      
      // Extract deep link and handle navigation
      if (message.data != null) {
        final deepLink = message.data['deep_link'] as String?;
        if (deepLink != null) {
          _handleNotificationTapped(deepLink);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling FCM message opened: $e');
      }
    }
  }

  /// Handle FCM token refresh
  void _handleFCMTokenRefresh(String? token) {
    try {
      if (kDebugMode) {
        print('FCM token refreshed in hybrid service: $token');
      }
      
      // Here you would typically send the new token to your backend
      // For now, we just log it
    } catch (e) {
      if (kDebugMode) {
        print('Error handling FCM token refresh: $e');
      }
    }
  }

  /// Handle notification tap
  void _handleNotificationTapped(String? payload) {
    try {
      if (_onNotificationTapped != null && payload != null) {
        _onNotificationTapped!(payload);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification tap: $e');
      }
    }
  }

  /// Get comprehensive notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final localStats = await _localNotificationService.getNotificationStatistics();
      final fcmStats = _fcmAvailable 
          ? await _fcmService.getFCMStatistics()
          : <String, dynamic>{};
      
      final totalNotifications = await _notificationRepository.getNotificationCount();
      final unreadNotifications = await _notificationRepository.getUnreadNotificationCount();

      return {
        'hybrid_service': {
          'is_initialized': _isInitialized,
          'fcm_available': _fcmAvailable,
          'local_notifications': localStats,
          'fcm': fcmStats,
        },
        'repository': {
          'total_notifications': totalNotifications,
          'unread_notifications': unreadNotifications,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get FCM token (if available)
  String? get fcmToken => _fcmAvailable ? _fcmService.token : null;

  /// Check if FCM is available and initialized
  bool get isFCMAvailable => _fcmAvailable && _fcmService.isInitialized;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if notification service is available
  bool get isAvailable => _localNotificationService.isAvailable;

  /// Get service status
  Map<String, dynamic> get status => {
    'is_initialized': _isInitialized,
    'fcm_available': _fcmAvailable,
    'fcm_token': fcmToken,
    'local_notifications_available': _localNotificationService.isAvailable,
  };

  /// Refresh FCM token if available
  Future<String?> refreshFCMToken() async {
    if (_fcmAvailable) {
      try {
        return await _fcmService.refreshToken();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to refresh FCM token: $e');
        }
      }
    }
    return null;
  }

  /// Delete FCM token if available
  Future<void> deleteFCMToken() async {
    if (_fcmAvailable) {
      try {
        await _fcmService.deleteToken();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete FCM token: $e');
        }
      }
    }
  }

  /// Get permission guidance message
  String getPermissionGuidanceMessage(bool hasPermission) {
    if (hasPermission) {
      if (_fcmAvailable) {
        return 'Notifications are enabled with cloud messaging support. You will receive real-time updates.';
      } else {
        return 'Local notifications are enabled. You will receive scheduled reminders.';
      }
    } else {
      return 'Notifications are disabled. Please enable them in settings to receive assignment reminders and updates.';
    }
  }

  /// Get notification status for a specific notification
  Future<Map<String, dynamic>> getNotificationStatus(String notificationId) async {
    try {
      final localStatus = await _localNotificationService.getNotificationStatus(notificationId);
      
      return {
        'notification_id': notificationId,
        'local_notification': localStatus,
        'fcm_available': _fcmAvailable,
        'service_initialized': _isInitialized,
      };
    } catch (e) {
      return {
        'notification_id': notificationId,
        'error': e.toString(),
      };
    }
  }
}