import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KPass'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @todayCourses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Classes'**
  String get todayCourses;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No Due Date'**
  String get noDueDate;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @notSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not Submitted'**
  String get notSubmitted;

  /// No description provided for @syncCalendar.
  ///
  /// In en, this message translates to:
  /// **'Sync to Calendar'**
  String get syncCalendar;

  /// No description provided for @calendarSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced to Calendar'**
  String get calendarSynced;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder Set'**
  String get reminderSet;

  /// No description provided for @noAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments found'**
  String get noAssignments;

  /// No description provided for @noCourses.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCourses;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred'**
  String get networkError;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationError;

  /// No description provided for @tokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get tokenExpired;

  /// No description provided for @enterToken.
  ///
  /// In en, this message translates to:
  /// **'Enter Access Token'**
  String get enterToken;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your Canvas access token here'**
  String get tokenHint;

  /// No description provided for @validateToken.
  ///
  /// In en, this message translates to:
  /// **'Validate Token'**
  String get validateToken;

  /// No description provided for @tokenValid.
  ///
  /// In en, this message translates to:
  /// **'Token is valid'**
  String get tokenValid;

  /// No description provided for @tokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid token'**
  String get tokenInvalid;

  /// No description provided for @calendarPermission.
  ///
  /// In en, this message translates to:
  /// **'Calendar Permission'**
  String get calendarPermission;

  /// No description provided for @calendarPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'KPass needs calendar access to sync assignment deadlines'**
  String get calendarPermissionMessage;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'KPass needs notification access to remind you of deadlines'**
  String get notificationPermissionMessage;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grant;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @syncSettings.
  ///
  /// In en, this message translates to:
  /// **'Sync Settings'**
  String get syncSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @syncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Sync Frequency'**
  String get syncFrequency;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get oneHour;

  /// No description provided for @sixHours.
  ///
  /// In en, this message translates to:
  /// **'6 hours before'**
  String get sixHours;

  /// No description provided for @twentyFourHours.
  ///
  /// In en, this message translates to:
  /// **'24 hours before'**
  String get twentyFourHours;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableCalendarSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Calendar Sync'**
  String get enableCalendarSync;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication Failed'**
  String get authenticationFailed;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error Occurred'**
  String get errorOccurred;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgain;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get checkConnection;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get sessionExpiredMessage;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please grant the required permissions in settings.'**
  String get permissionDeniedMessage;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error occurred. Please try again later.'**
  String get serverError;

  /// No description provided for @requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimeout;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get tooManyRequests;

  /// No description provided for @resourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get resourceNotFound;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. You don\'t have permission to access this resource.'**
  String get accessDenied;

  /// No description provided for @invalidData.
  ///
  /// In en, this message translates to:
  /// **'Invalid data received from server.'**
  String get invalidData;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Storage error occurred. Please check available space.'**
  String get storageError;

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Calendar error occurred. Please check calendar permissions.'**
  String get calendarError;

  /// No description provided for @notificationError.
  ///
  /// In en, this message translates to:
  /// **'Notification error occurred. Please check notification permissions.'**
  String get notificationError;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Synchronization failed. Please try again.'**
  String get syncError;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation error occurred. Please check your input.'**
  String get validationError;

  /// No description provided for @configurationError.
  ///
  /// In en, this message translates to:
  /// **'Configuration error. Please contact support.'**
  String get configurationError;

  /// No description provided for @featureNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'This feature is not implemented yet.'**
  String get featureNotImplemented;

  /// No description provided for @backgroundSyncError.
  ///
  /// In en, this message translates to:
  /// **'Background sync failed. Please check your settings.'**
  String get backgroundSyncError;

  /// No description provided for @batteryOptimizationWarning.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization may prevent background sync.'**
  String get batteryOptimizationWarning;

  /// No description provided for @fcmError.
  ///
  /// In en, this message translates to:
  /// **'Push notification error. Local notifications will be used instead.'**
  String get fcmError;

  /// No description provided for @cacheError.
  ///
  /// In en, this message translates to:
  /// **'Cache error occurred. Data may be outdated.'**
  String get cacheError;

  /// No description provided for @encryptionError.
  ///
  /// In en, this message translates to:
  /// **'Security error occurred. Please restart the app.'**
  String get encryptionError;

  /// No description provided for @tokenFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid token format. Please check your token.'**
  String get tokenFormatError;

  /// No description provided for @courseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Course not found. It may have been removed or you may not have access.'**
  String get courseNotFound;

  /// No description provided for @assignmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assignment not found. It may have been removed or modified.'**
  String get assignmentNotFound;

  /// No description provided for @calendarEventError.
  ///
  /// In en, this message translates to:
  /// **'Failed to manage calendar event. Please check calendar permissions.'**
  String get calendarEventError;

  /// No description provided for @reminderError.
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule reminder. Please check notification permissions.'**
  String get reminderError;

  /// No description provided for @webViewError.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again or use manual token input.'**
  String get webViewError;

  /// No description provided for @shibbolethError.
  ///
  /// In en, this message translates to:
  /// **'University authentication failed. Please check your credentials.'**
  String get shibbolethError;

  /// No description provided for @manualTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Token Input'**
  String get manualTokenTitle;

  /// No description provided for @enterCanvasToken.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Canvas Access Token'**
  String get enterCanvasToken;

  /// No description provided for @tokenDescription.
  ///
  /// In en, this message translates to:
  /// **'You can generate an access token from your Canvas account settings. This token will be stored securely on your device.'**
  String get tokenDescription;

  /// No description provided for @accessToken.
  ///
  /// In en, this message translates to:
  /// **'Access Token'**
  String get accessToken;

  /// No description provided for @tokenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste your Canvas access token here...'**
  String get tokenPlaceholder;

  /// No description provided for @showToken.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get showToken;

  /// No description provided for @hideToken.
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get hideToken;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @validateAndSaveToken.
  ///
  /// In en, this message translates to:
  /// **'Validate & Save Token'**
  String get validateAndSaveToken;

  /// No description provided for @validating.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validating;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @howToGetToken.
  ///
  /// In en, this message translates to:
  /// **'How to get your access token'**
  String get howToGetToken;

  /// No description provided for @openCanvasSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Canvas Settings'**
  String get openCanvasSettings;

  /// No description provided for @tokenFormatValid.
  ///
  /// In en, this message translates to:
  /// **'Token format is valid'**
  String get tokenFormatValid;

  /// No description provided for @tokenCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your access token'**
  String get tokenCannotBeEmpty;

  /// No description provided for @tokenTooShort.
  ///
  /// In en, this message translates to:
  /// **'Token is too short. Please check and try again'**
  String get tokenTooShort;

  /// No description provided for @tokenTooLong.
  ///
  /// In en, this message translates to:
  /// **'Token is too long. Please check and try again'**
  String get tokenTooLong;

  /// No description provided for @tokenInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Token contains invalid characters. Only letters, numbers, and ~ are allowed'**
  String get tokenInvalidCharacters;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeUser(String userName);

  /// No description provided for @failedToPasteClipboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to paste from clipboard'**
  String get failedToPasteClipboard;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @canvasSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas Settings'**
  String get canvasSettingsTitle;

  /// No description provided for @tokenGenerationSteps.
  ///
  /// In en, this message translates to:
  /// **'To generate an access token:'**
  String get tokenGenerationSteps;

  /// No description provided for @tokenStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Go to Canvas Settings'**
  String get tokenStep1;

  /// No description provided for @tokenStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Click on \"Approved Integrations\"'**
  String get tokenStep2;

  /// No description provided for @tokenStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Click \"+ New Access Token\"'**
  String get tokenStep3;

  /// No description provided for @tokenStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Enter a purpose and generate'**
  String get tokenStep4;

  /// No description provided for @tokenStep5.
  ///
  /// In en, this message translates to:
  /// **'5. Copy the token and paste it here'**
  String get tokenStep5;

  /// No description provided for @tokenHint1.
  ///
  /// In en, this message translates to:
  /// **'Token should be 64-128 characters long'**
  String get tokenHint1;

  /// No description provided for @tokenHint2.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and ~ characters are allowed'**
  String get tokenHint2;

  /// No description provided for @tokenHint3.
  ///
  /// In en, this message translates to:
  /// **'You can find your token in Canvas Settings > Approved Integrations'**
  String get tokenHint3;

  /// No description provided for @tokenHint4.
  ///
  /// In en, this message translates to:
  /// **'Make sure to copy the entire token without spaces'**
  String get tokenHint4;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'You will receive assignment reminders'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Grant permission to receive notifications'**
  String get notificationPermissionDenied;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @connectedToFirebase.
  ///
  /// In en, this message translates to:
  /// **'Connected to Firebase'**
  String get connectedToFirebase;

  /// No description provided for @localNotificationsOnly.
  ///
  /// In en, this message translates to:
  /// **'Using local notifications only'**
  String get localNotificationsOnly;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @enableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on/off all notifications'**
  String get enableNotificationsSubtitle;

  /// No description provided for @assignmentReminders.
  ///
  /// In en, this message translates to:
  /// **'Assignment Reminders'**
  String get assignmentReminders;

  /// No description provided for @assignmentRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded before assignment deadlines'**
  String get assignmentRemindersSubtitle;

  /// No description provided for @newAssignmentNotifications.
  ///
  /// In en, this message translates to:
  /// **'New Assignment Notifications'**
  String get newAssignmentNotifications;

  /// No description provided for @newAssignmentNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when new assignments are posted'**
  String get newAssignmentNotificationsSubtitle;

  /// No description provided for @assignmentUpdateNotifications.
  ///
  /// In en, this message translates to:
  /// **'Assignment Update Notifications'**
  String get assignmentUpdateNotifications;

  /// No description provided for @assignmentUpdateNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when assignments are modified'**
  String get assignmentUpdateNotificationsSubtitle;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @soundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play sound for notifications'**
  String get soundSubtitle;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate for notifications'**
  String get vibrationSubtitle;

  /// No description provided for @reminderTiming.
  ///
  /// In en, this message translates to:
  /// **'Reminder Timing'**
  String get reminderTiming;

  /// No description provided for @reminderTimingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose when to receive assignment reminders before the due date'**
  String get reminderTimingSubtitle;

  /// No description provided for @fifteenMinutes.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get fifteenMinutes;

  /// No description provided for @thirtyMinutes.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get thirtyMinutes;

  /// No description provided for @twoHours.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get twoHours;

  /// No description provided for @fortyEightHours.
  ///
  /// In en, this message translates to:
  /// **'48 hours'**
  String get fortyEightHours;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get oneWeek;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set hours when you don\'t want to receive notifications'**
  String get quietHoursSubtitle;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @currentlyInQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Currently in quiet hours'**
  String get currentlyInQuietHours;

  /// No description provided for @notInQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Not in quiet hours'**
  String get notInQuietHours;

  /// No description provided for @courseNotifications.
  ///
  /// In en, this message translates to:
  /// **'Course Notifications'**
  String get courseNotifications;

  /// No description provided for @courseNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which courses to receive notifications for'**
  String get courseNotificationsSubtitle;

  /// No description provided for @noCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCoursesFound;

  /// No description provided for @syncCoursesToManage.
  ///
  /// In en, this message translates to:
  /// **'Sync your courses to manage notifications'**
  String get syncCoursesToManage;

  /// No description provided for @notificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Notification History'**
  String get notificationHistory;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @totalNotifications.
  ///
  /// In en, this message translates to:
  /// **'Total Notifications'**
  String get totalNotifications;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unread Notifications'**
  String get unreadNotifications;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity (7 days)'**
  String get recentActivity;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @serviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Service Status'**
  String get serviceStatus;

  /// No description provided for @notificationServiceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Notification service is available'**
  String get notificationServiceAvailable;

  /// No description provided for @notificationServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notification service is not available'**
  String get notificationServiceUnavailable;

  /// No description provided for @refreshPushToken.
  ///
  /// In en, this message translates to:
  /// **'Refresh Push Token'**
  String get refreshPushToken;

  /// No description provided for @refreshPushTokenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh Firebase messaging token'**
  String get refreshPushTokenSubtitle;

  /// No description provided for @viewStatistics.
  ///
  /// In en, this message translates to:
  /// **'View Statistics'**
  String get viewStatistics;

  /// No description provided for @viewStatisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed notification statistics'**
  String get viewStatisticsSubtitle;

  /// No description provided for @notificationStatistics.
  ///
  /// In en, this message translates to:
  /// **'Notification Statistics'**
  String get notificationStatistics;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent (7 days)'**
  String get recent;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @defaultReminder.
  ///
  /// In en, this message translates to:
  /// **'Default reminder'**
  String get defaultReminder;

  /// No description provided for @enabledCourses.
  ///
  /// In en, this message translates to:
  /// **'Enabled courses'**
  String get enabledCourses;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotifications;

  /// No description provided for @clearAllNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all notification history. This action cannot be undone.'**
  String get clearAllNotificationsMessage;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minuteAgo.
  ///
  /// In en, this message translates to:
  /// **'minute ago'**
  String get minuteAgo;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @hourAgo.
  ///
  /// In en, this message translates to:
  /// **'hour ago'**
  String get hourAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @dayAgo.
  ///
  /// In en, this message translates to:
  /// **'day ago'**
  String get dayAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @weeklyTimetable.
  ///
  /// In en, this message translates to:
  /// **'Weekly Timetable'**
  String get weeklyTimetable;

  /// No description provided for @noCoursesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No classes this week'**
  String get noCoursesThisWeek;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
