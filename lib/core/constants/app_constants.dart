/// Application-wide constants for KPASS
class AppConstants {
  // App Information
  static const String appName = 'KPass';
  static const String appFullName = 'KPass（ケーパス）- Keio University K-LMS Client';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Canvas LMS client for Keio University students';

  // Canvas API Configuration
  static const String canvasBaseUrl = 'https://lms.keio.jp';
  static const String canvasApiPath = '/api/v1';
  static const String canvasApiUrl = '$canvasBaseUrl$canvasApiPath';

  // API Endpoints
  static const String userSelfEndpoint = '/users/self';
  static const String coursesEndpoint = '/courses';
  static const String assignmentsEndpoint = '/assignments';
  static const String calendarEventsEndpoint = '/calendar_events';
  static const String userCalendarEventsEndpoint =
      '/users/self/calendar_events';

  // Storage Keys
  static const String accessTokenKey = 'canvas_access_token';
  static const String sessionCookieKey = 'canvas_session_cookie';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String coursesDataKey = 'courses_data';
  static const String assignmentsDataKey = 'assignments_data';
  static const String lastSyncTimeKey = 'last_sync_time';

  // Notification Settings
  static const String notificationChannelId = 'kpass_assignments';
  static const String notificationChannelName = 'Assignment Reminders';
  static const String notificationChannelDescription =
      'Notifications for assignment deadlines';

  // Default Settings
  static const Duration defaultReminderTime = Duration(hours: 24);
  static const Duration defaultSyncInterval = Duration(hours: 1);
  static const int maxRetryAttempts = 3;
  static const Duration requestTimeout = Duration(seconds: 30);

  // Calendar Settings
  static const String calendarEventPrefix = '[KPASS]';
  static const String calendarEventDescription = 'Assignment from K-LMS';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Error Messages
  static const String networkErrorMessage =
      'Network connection error. Please check your internet connection.';
  static const String authErrorMessage =
      'Authentication failed. Please login again.';
  static const String tokenExpiredMessage =
      'Your session has expired. Please login again.';
  static const String permissionDeniedMessage =
      'Permission denied. Please grant the required permissions.';
  static const String unknownErrorMessage =
      'An unexpected error occurred. Please try again.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String syncSuccessMessage = 'Data synchronized successfully.';
  static const String calendarSyncSuccessMessage =
      'Calendar synchronized successfully.';
  static const String notificationScheduledMessage =
      'Reminder scheduled successfully.';

  // Validation
  static const int minTokenLength = 64;
  static const int maxTokenLength = 128;
  static const String tokenPattern = r'^[a-zA-Z0-9~]+$';

  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 6);
  static const int maxCacheSize = 50; // MB

  // Background Sync
  static const String backgroundTaskName = 'kpass_sync';
  static const Duration minBackgroundSyncInterval = Duration(minutes: 15);
  static const Duration maxBackgroundSyncInterval = Duration(hours: 24);

  // Accessibility
  static const double minTouchTargetSize = 44.0;
  static const double maxFontScale = 2.0;
  static const double minFontScale = 0.8;
}

/// URL constants for external links
class AppUrls {
  static const String keioUniversityUrl = 'https://www.keio.ac.jp';
  static const String canvasHelpUrl =
      'https://community.canvaslms.com/t5/Student-Guide/tkb-p/student';
  static const String privacyPolicyUrl =
      'https://www.keio.ac.jp/en/privacy-policy/';
  static const String termsOfServiceUrl = 'https://www.keio.ac.jp/en/terms/';
  static const String supportEmailUrl = 'mailto:support@keio.ac.jp';

  // Canvas Token Generation URLs
  static const String canvasTokenUrl =
      '${AppConstants.canvasBaseUrl}/profile/settings';
  static const String canvasApiDocUrl =
      'https://canvas.instructure.com/doc/api/';
}

/// Asset paths for images and icons
class AppAssets {
  // Images
  static const String logoPath = 'assets/images/kpass_logo.png';
  static const String keioLogoPath = 'assets/images/keio_logo.png';
  static const String splashImagePath = 'assets/images/splash_image.png';
  static const String emptyStatePath = 'assets/images/empty_state.png';
  static const String errorStatePath = 'assets/images/error_state.png';

  // Icons
  static const String assignmentIconPath = 'assets/icons/assignment.png';
  static const String courseIconPath = 'assets/icons/course.png';
  static const String calendarIconPath = 'assets/icons/calendar.png';
  static const String notificationIconPath = 'assets/icons/notification.png';
  static const String settingsIconPath = 'assets/icons/settings.png';
}

/// Regular expressions for validation
class AppRegex {
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp tokenRegex = RegExp(AppConstants.tokenPattern);

  static final RegExp urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
}

/// Environment-specific configurations
enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment currentEnvironment = Environment.development;

  static bool get isDevelopment =>
      currentEnvironment == Environment.development;
  static bool get isStaging => currentEnvironment == Environment.staging;
  static bool get isProduction => currentEnvironment == Environment.production;

  static bool get enableLogging => !isProduction;
  static bool get enableDebugMode => isDevelopment;
  static bool get enableCrashReporting => isProduction || isStaging;

  /// Verbose logging controls very chatty logs (HTTP dumps, storage reads)
  static const bool enableVerboseLogging = true;
}
