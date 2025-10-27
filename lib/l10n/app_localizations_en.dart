// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KPass';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get courses => 'Courses';

  @override
  String get assignments => 'Assignments';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get todayCourses => 'Today\'s Classes';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get dueDate => 'Due Date';

  @override
  String get noDueDate => 'No Due Date';

  @override
  String get submitted => 'Submitted';

  @override
  String get notSubmitted => 'Not Submitted';

  @override
  String get syncCalendar => 'Sync to Calendar';

  @override
  String get calendarSynced => 'Synced to Calendar';

  @override
  String get reminderSet => 'Reminder Set';

  @override
  String get noAssignments => 'No assignments found';

  @override
  String get noCourses => 'No courses found';

  @override
  String get networkError => 'Network error occurred';

  @override
  String get authenticationError => 'Authentication failed';

  @override
  String get tokenExpired => 'Session expired. Please login again.';

  @override
  String get enterToken => 'Enter Access Token';

  @override
  String get tokenHint => 'Paste your Canvas access token here';

  @override
  String get validateToken => 'Validate Token';

  @override
  String get tokenValid => 'Token is valid';

  @override
  String get tokenInvalid => 'Invalid token';

  @override
  String get calendarPermission => 'Calendar Permission';

  @override
  String get calendarPermissionMessage => 'KPass needs calendar access to sync assignment deadlines';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get notificationPermissionMessage => 'KPass needs notification access to remind you of deadlines';

  @override
  String get grant => 'Grant';

  @override
  String get deny => 'Deny';

  @override
  String get syncSettings => 'Sync Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get syncFrequency => 'Sync Frequency';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get oneHour => '1 hour before';

  @override
  String get sixHours => '6 hours before';

  @override
  String get twentyFourHours => '24 hours before';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableCalendarSync => 'Enable Calendar Sync';

  @override
  String get close => 'Close';

  @override
  String get action => 'Action';

  @override
  String get connectionError => 'Connection Error';

  @override
  String get authenticationFailed => 'Authentication Failed';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get errorOccurred => 'Error Occurred';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get tryAgain => 'Please try again';

  @override
  String get checkConnection => 'Please check your internet connection';

  @override
  String get sessionExpiredMessage => 'Your session has expired. Please login again.';

  @override
  String get permissionDeniedMessage => 'Permission denied. Please grant the required permissions in settings.';

  @override
  String get serverError => 'Server error occurred. Please try again later.';

  @override
  String get requestTimeout => 'Request timed out. Please try again.';

  @override
  String get tooManyRequests => 'Too many requests. Please wait a moment and try again.';

  @override
  String get resourceNotFound => 'The requested resource was not found.';

  @override
  String get accessDenied => 'Access denied. You don\'t have permission to access this resource.';

  @override
  String get invalidData => 'Invalid data received from server.';

  @override
  String get storageError => 'Storage error occurred. Please check available space.';

  @override
  String get calendarError => 'Calendar error occurred. Please check calendar permissions.';

  @override
  String get notificationError => 'Notification error occurred. Please check notification permissions.';

  @override
  String get syncError => 'Synchronization failed. Please try again.';

  @override
  String get validationError => 'Validation error occurred. Please check your input.';

  @override
  String get configurationError => 'Configuration error. Please contact support.';

  @override
  String get featureNotImplemented => 'This feature is not implemented yet.';

  @override
  String get backgroundSyncError => 'Background sync failed. Please check your settings.';

  @override
  String get batteryOptimizationWarning => 'Battery optimization may prevent background sync.';

  @override
  String get fcmError => 'Push notification error. Local notifications will be used instead.';

  @override
  String get cacheError => 'Cache error occurred. Data may be outdated.';

  @override
  String get encryptionError => 'Security error occurred. Please restart the app.';

  @override
  String get tokenFormatError => 'Invalid token format. Please check your token.';

  @override
  String get courseNotFound => 'Course not found. It may have been removed or you may not have access.';

  @override
  String get assignmentNotFound => 'Assignment not found. It may have been removed or modified.';

  @override
  String get calendarEventError => 'Failed to manage calendar event. Please check calendar permissions.';

  @override
  String get reminderError => 'Failed to schedule reminder. Please check notification permissions.';

  @override
  String get webViewError => 'Login failed. Please try again or use manual token input.';

  @override
  String get shibbolethError => 'University authentication failed. Please check your credentials.';

  @override
  String get manualTokenTitle => 'Manual Token Input';

  @override
  String get enterCanvasToken => 'Enter Your Canvas Access Token';

  @override
  String get tokenDescription => 'You can generate an access token from your Canvas account settings. This token will be stored securely on your device.';

  @override
  String get accessToken => 'Access Token';

  @override
  String get tokenPlaceholder => 'Paste your Canvas access token here...';

  @override
  String get showToken => 'Show token';

  @override
  String get hideToken => 'Hide token';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get validateAndSaveToken => 'Validate & Save Token';

  @override
  String get validating => 'Validating...';

  @override
  String get clear => 'Clear';

  @override
  String get howToGetToken => 'How to get your access token';

  @override
  String get openCanvasSettings => 'Open Canvas Settings';

  @override
  String get tokenFormatValid => 'Token format is valid';

  @override
  String get tokenCannotBeEmpty => 'Please enter your access token';

  @override
  String get tokenTooShort => 'Token is too short. Please check and try again';

  @override
  String get tokenTooLong => 'Token is too long. Please check and try again';

  @override
  String get tokenInvalidCharacters => 'Token contains invalid characters. Only letters, numbers, and ~ are allowed';

  @override
  String welcomeUser(String userName) {
    return 'Welcome, $userName!';
  }

  @override
  String get failedToPasteClipboard => 'Failed to paste from clipboard';

  @override
  String get unexpectedError => 'An unexpected error occurred. Please try again.';

  @override
  String get canvasSettingsTitle => 'Canvas Settings';

  @override
  String get tokenGenerationSteps => 'To generate an access token:';

  @override
  String get tokenStep1 => '1. Go to Canvas Settings';

  @override
  String get tokenStep2 => '2. Click on \"Approved Integrations\"';

  @override
  String get tokenStep3 => '3. Click \"+ New Access Token\"';

  @override
  String get tokenStep4 => '4. Enter a purpose and generate';

  @override
  String get tokenStep5 => '5. Copy the token and paste it here';

  @override
  String get tokenHint1 => 'Token should be 64-128 characters long';

  @override
  String get tokenHint2 => 'Only letters, numbers, and ~ characters are allowed';

  @override
  String get tokenHint3 => 'You can find your token in Canvas Settings > Approved Integrations';

  @override
  String get tokenHint4 => 'Make sure to copy the entire token without spaces';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get permissions => 'Permissions';

  @override
  String get notificationsEnabled => 'Notifications Enabled';

  @override
  String get notificationsDisabled => 'Notifications Disabled';

  @override
  String get notificationPermissionGranted => 'You will receive assignment reminders';

  @override
  String get notificationPermissionDenied => 'Grant permission to receive notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get connectedToFirebase => 'Connected to Firebase';

  @override
  String get localNotificationsOnly => 'Using local notifications only';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get enableNotificationsSubtitle => 'Turn on/off all notifications';

  @override
  String get assignmentReminders => 'Assignment Reminders';

  @override
  String get assignmentRemindersSubtitle => 'Get reminded before assignment deadlines';

  @override
  String get newAssignmentNotifications => 'New Assignment Notifications';

  @override
  String get newAssignmentNotificationsSubtitle => 'Get notified when new assignments are posted';

  @override
  String get assignmentUpdateNotifications => 'Assignment Update Notifications';

  @override
  String get assignmentUpdateNotificationsSubtitle => 'Get notified when assignments are modified';

  @override
  String get sound => 'Sound';

  @override
  String get soundSubtitle => 'Play sound for notifications';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationSubtitle => 'Vibrate for notifications';

  @override
  String get reminderTiming => 'Reminder Timing';

  @override
  String get reminderTimingSubtitle => 'Choose when to receive assignment reminders before the due date';

  @override
  String get fifteenMinutes => '15 minutes';

  @override
  String get thirtyMinutes => '30 minutes';

  @override
  String get twoHours => '2 hours';

  @override
  String get fortyEightHours => '48 hours';

  @override
  String get oneWeek => '1 week';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursSubtitle => 'Set hours when you don\'t want to receive notifications';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get notSet => 'Not set';

  @override
  String get currentlyInQuietHours => 'Currently in quiet hours';

  @override
  String get notInQuietHours => 'Not in quiet hours';

  @override
  String get courseNotifications => 'Course Notifications';

  @override
  String get courseNotificationsSubtitle => 'Choose which courses to receive notifications for';

  @override
  String get noCoursesFound => 'No courses found';

  @override
  String get syncCoursesToManage => 'Sync your courses to manage notifications';

  @override
  String get notificationHistory => 'Notification History';

  @override
  String get viewAll => 'View All';

  @override
  String get totalNotifications => 'Total Notifications';

  @override
  String get unreadNotifications => 'Unread Notifications';

  @override
  String get recentActivity => 'Recent Activity (7 days)';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get clearAll => 'Clear All';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get serviceStatus => 'Service Status';

  @override
  String get notificationServiceAvailable => 'Notification service is available';

  @override
  String get notificationServiceUnavailable => 'Notification service is not available';

  @override
  String get refreshPushToken => 'Refresh Push Token';

  @override
  String get refreshPushTokenSubtitle => 'Refresh Firebase messaging token';

  @override
  String get viewStatistics => 'View Statistics';

  @override
  String get viewStatisticsSubtitle => 'Detailed notification statistics';

  @override
  String get notificationStatistics => 'Notification Statistics';

  @override
  String get total => 'Total';

  @override
  String get unread => 'Unread';

  @override
  String get recent => 'Recent (7 days)';

  @override
  String get enabled => 'Enabled';

  @override
  String get reminders => 'Reminders';

  @override
  String get defaultReminder => 'Default reminder';

  @override
  String get enabledCourses => 'Enabled courses';

  @override
  String get clearAllNotifications => 'Clear All Notifications';

  @override
  String get clearAllNotificationsMessage => 'This will permanently delete all notification history. This action cannot be undone.';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get justNow => 'Just now';

  @override
  String get minuteAgo => 'minute ago';

  @override
  String get minutesAgo => 'minutes ago';

  @override
  String get hourAgo => 'hour ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get dayAgo => 'day ago';

  @override
  String get daysAgo => 'days ago';

  @override
  String get timetable => 'Timetable';

  @override
  String get weeklyTimetable => 'Weekly Timetable';

  @override
  String get noCoursesThisWeek => 'No classes this week';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';
}
