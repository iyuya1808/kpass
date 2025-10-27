import 'package:equatable/equatable.dart';

/// Base failure class for representing errors in the domain layer
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() {
    return 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      message: 'No internet connection available',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Request timeout',
      code: 'TIMEOUT',
    );
  }

  factory NetworkFailure.serverError(int statusCode, [String? message]) {
    return NetworkFailure(
      message: message ?? 'Server error occurred',
      code: 'SERVER_ERROR_$statusCode',
      details: {'statusCode': statusCode},
    );
  }

  factory NetworkFailure.badRequest([String? message]) {
    return NetworkFailure(
      message: message ?? 'Bad request',
      code: 'BAD_REQUEST',
    );
  }

  factory NetworkFailure.unauthorized([String? message]) {
    return NetworkFailure(
      message: message ?? 'Unauthorized access',
      code: 'UNAUTHORIZED',
    );
  }

  factory NetworkFailure.forbidden([String? message]) {
    return NetworkFailure(
      message: message ?? 'Access forbidden',
      code: 'FORBIDDEN',
    );
  }

  factory NetworkFailure.notFound([String? message]) {
    return NetworkFailure(
      message: message ?? 'Resource not found',
      code: 'NOT_FOUND',
    );
  }

  factory NetworkFailure.rateLimited([String? message]) {
    return NetworkFailure(
      message: message ?? 'Rate limit exceeded',
      code: 'RATE_LIMITED',
    );
  }

  factory NetworkFailure.clientError(int statusCode, [String? message]) {
    return NetworkFailure(
      message: message ?? 'Client error occurred',
      code: 'CLIENT_ERROR_$statusCode',
      details: {'statusCode': statusCode},
    );
  }

  factory NetworkFailure.sslError([String? message]) {
    return NetworkFailure(
      message: message ?? 'SSL certificate error',
      code: 'SSL_ERROR',
    );
  }
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory AuthFailure.invalidToken() {
    return const AuthFailure(
      message: 'Invalid or expired access token',
      code: 'INVALID_TOKEN',
    );
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Access token has expired',
      code: 'TOKEN_EXPIRED',
    );
  }

  factory AuthFailure.loginFailed([String? message]) {
    return AuthFailure(
      message: message ?? 'Login failed',
      code: 'LOGIN_FAILED',
    );
  }

  factory AuthFailure.tokenNotFound() {
    return const AuthFailure(
      message: 'No access token found',
      code: 'TOKEN_NOT_FOUND',
    );
  }

  factory AuthFailure.webViewError([String? message]) {
    return AuthFailure(
      message: message ?? 'WebView authentication failed',
      code: 'WEBVIEW_ERROR',
    );
  }

  factory AuthFailure.shibbolethError([String? message]) {
    return AuthFailure(
      message: message ?? 'Shibboleth authentication failed',
      code: 'SHIBBOLETH_ERROR',
    );
  }

  factory AuthFailure.insufficientPermissions([String? message]) {
    return AuthFailure(
      message: message ?? 'Insufficient permissions',
      code: 'INSUFFICIENT_PERMISSIONS',
    );
  }
}

/// Canvas API-related failures
class CanvasFailure extends Failure {
  const CanvasFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory CanvasFailure.apiError(String message, [String? code]) {
    return CanvasFailure(
      message: message,
      code: code ?? 'API_ERROR',
    );
  }

  factory CanvasFailure.courseNotFound(int courseId) {
    return CanvasFailure(
      message: 'Course with ID $courseId not found',
      code: 'COURSE_NOT_FOUND',
      details: {'courseId': courseId},
    );
  }

  factory CanvasFailure.assignmentNotFound(int assignmentId) {
    return CanvasFailure(
      message: 'Assignment with ID $assignmentId not found',
      code: 'ASSIGNMENT_NOT_FOUND',
      details: {'assignmentId': assignmentId},
    );
  }

  factory CanvasFailure.invalidResponse([String? message]) {
    return CanvasFailure(
      message: message ?? 'Invalid API response format',
      code: 'INVALID_RESPONSE',
    );
  }

  factory CanvasFailure.quotaExceeded() {
    return const CanvasFailure(
      message: 'API quota exceeded',
      code: 'QUOTA_EXCEEDED',
    );
  }
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory StorageFailure.readError([String? message]) {
    return StorageFailure(
      message: message ?? 'Failed to read from storage',
      code: 'READ_ERROR',
    );
  }

  factory StorageFailure.writeError([String? message]) {
    return StorageFailure(
      message: message ?? 'Failed to write to storage',
      code: 'WRITE_ERROR',
    );
  }

  factory StorageFailure.deleteError([String? message]) {
    return StorageFailure(
      message: message ?? 'Failed to delete from storage',
      code: 'DELETE_ERROR',
    );
  }

  factory StorageFailure.encryptionError([String? message]) {
    return StorageFailure(
      message: message ?? 'Encryption/decryption failed',
      code: 'ENCRYPTION_ERROR',
    );
  }

  factory StorageFailure.storageUnavailable() {
    return const StorageFailure(
      message: 'Storage is not available',
      code: 'STORAGE_UNAVAILABLE',
    );
  }
}

/// Calendar-related failures
class CalendarFailure extends Failure {
  const CalendarFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory CalendarFailure.permissionDenied() {
    return const CalendarFailure(
      message: 'Calendar permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory CalendarFailure.eventCreationFailed([String? message]) {
    return CalendarFailure(
      message: message ?? 'Failed to create calendar event',
      code: 'EVENT_CREATION_FAILED',
    );
  }

  factory CalendarFailure.eventUpdateFailed([String? message]) {
    return CalendarFailure(
      message: message ?? 'Failed to update calendar event',
      code: 'EVENT_UPDATE_FAILED',
    );
  }

  factory CalendarFailure.eventDeletionFailed([String? message]) {
    return CalendarFailure(
      message: message ?? 'Failed to delete calendar event',
      code: 'EVENT_DELETION_FAILED',
    );
  }

  factory CalendarFailure.calendarNotFound() {
    return const CalendarFailure(
      message: 'Calendar not found',
      code: 'CALENDAR_NOT_FOUND',
    );
  }

  factory CalendarFailure.syncFailed([String? message]) {
    return CalendarFailure(
      message: message ?? 'Calendar synchronization failed',
      code: 'SYNC_FAILED',
    );
  }
}

/// Notification-related failures
class NotificationFailure extends Failure {
  const NotificationFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory NotificationFailure.permissionDenied() {
    return const NotificationFailure(
      message: 'Notification permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory NotificationFailure.schedulingFailed([String? message]) {
    return NotificationFailure(
      message: message ?? 'Failed to schedule notification',
      code: 'SCHEDULING_FAILED',
    );
  }

  factory NotificationFailure.cancellationFailed([String? message]) {
    return NotificationFailure(
      message: message ?? 'Failed to cancel notification',
      code: 'CANCELLATION_FAILED',
    );
  }

  factory NotificationFailure.fcmError([String? message]) {
    return NotificationFailure(
      message: message ?? 'Firebase Cloud Messaging error',
      code: 'FCM_ERROR',
    );
  }

  factory NotificationFailure.initializationFailed() {
    return const NotificationFailure(
      message: 'Failed to initialize notification service',
      code: 'INITIALIZATION_FAILED',
    );
  }
}

/// Background sync-related failures
class BackgroundSyncFailure extends Failure {
  const BackgroundSyncFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory BackgroundSyncFailure.registrationFailed() {
    return const BackgroundSyncFailure(
      message: 'Failed to register background task',
      code: 'REGISTRATION_FAILED',
    );
  }

  factory BackgroundSyncFailure.executionFailed([String? message]) {
    return BackgroundSyncFailure(
      message: message ?? 'Background sync execution failed',
      code: 'EXECUTION_FAILED',
    );
  }

  factory BackgroundSyncFailure.batteryOptimizationEnabled() {
    return const BackgroundSyncFailure(
      message: 'Battery optimization is preventing background sync',
      code: 'BATTERY_OPTIMIZATION_ENABLED',
    );
  }

  factory BackgroundSyncFailure.permissionDenied() {
    return const BackgroundSyncFailure(
      message: 'Background processing permission denied',
      code: 'PERMISSION_DENIED',
    );
  }
}

/// Validation-related failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    this.fieldErrors,
    super.details,
  });

  factory ValidationFailure.invalidToken() {
    return const ValidationFailure(
      message: 'Invalid token format',
      code: 'INVALID_TOKEN_FORMAT',
    );
  }

  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName cannot be empty',
      code: 'EMPTY_FIELD',
      fieldErrors: {fieldName: 'This field is required'},
    );
  }

  factory ValidationFailure.invalidEmail() {
    return const ValidationFailure(
      message: 'Invalid email format',
      code: 'INVALID_EMAIL',
      fieldErrors: {'email': 'Please enter a valid email address'},
    );
  }

  factory ValidationFailure.multipleFields(Map<String, String> errors) {
    return ValidationFailure(
      message: 'Multiple validation errors',
      code: 'MULTIPLE_VALIDATION_ERRORS',
      fieldErrors: errors,
    );
  }

  @override
  List<Object?> get props => [message, code, details, fieldErrors];
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory CacheFailure.notFound(String key) {
    return CacheFailure(
      message: 'Cache entry not found for key: $key',
      code: 'CACHE_NOT_FOUND',
      details: {'key': key},
    );
  }

  factory CacheFailure.expired(String key) {
    return CacheFailure(
      message: 'Cache entry expired for key: $key',
      code: 'CACHE_EXPIRED',
      details: {'key': key},
    );
  }

  factory CacheFailure.corruptedData() {
    return const CacheFailure(
      message: 'Cached data is corrupted',
      code: 'CORRUPTED_DATA',
    );
  }

  factory CacheFailure.sizeLimitExceeded() {
    return const CacheFailure(
      message: 'Cache size limit exceeded',
      code: 'SIZE_LIMIT_EXCEEDED',
    );
  }
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory PermissionFailure.denied(String permission) {
    return PermissionFailure(
      message: '$permission permission denied',
      code: 'PERMISSION_DENIED',
      details: {'permission': permission},
    );
  }

  factory PermissionFailure.permanentlyDenied(String permission) {
    return PermissionFailure(
      message: '$permission permission permanently denied',
      code: 'PERMISSION_PERMANENTLY_DENIED',
      details: {'permission': permission},
    );
  }

  factory PermissionFailure.restricted(String permission) {
    return PermissionFailure(
      message: '$permission permission restricted',
      code: 'PERMISSION_RESTRICTED',
      details: {'permission': permission},
    );
  }
}

/// General application failures
class GeneralFailure extends Failure {
  const GeneralFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory GeneralFailure.unknown([String? message]) {
    return GeneralFailure(
      message: message ?? 'An unknown error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }

  factory GeneralFailure.notImplemented([String? feature]) {
    return GeneralFailure(
      message: feature != null 
        ? '$feature is not implemented yet'
        : 'Feature not implemented',
      code: 'NOT_IMPLEMENTED',
    );
  }

  factory GeneralFailure.configurationError([String? message]) {
    return GeneralFailure(
      message: message ?? 'Configuration error',
      code: 'CONFIGURATION_ERROR',
    );
  }
}