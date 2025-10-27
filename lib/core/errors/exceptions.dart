/// Base exception class for all custom exceptions in the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      message: 'No internet connection available',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      message: 'Request timeout',
      code: 'TIMEOUT',
    );
  }

  factory NetworkException.serverError(int statusCode, [String? message]) {
    return NetworkException(
      message: message ?? 'Server error occurred',
      code: 'SERVER_ERROR_$statusCode',
    );
  }

  factory NetworkException.badRequest([String? message]) {
    return NetworkException(
      message: message ?? 'Bad request',
      code: 'BAD_REQUEST',
    );
  }

  factory NetworkException.unauthorized([String? message]) {
    return NetworkException(
      message: message ?? 'Unauthorized access',
      code: 'UNAUTHORIZED',
    );
  }

  factory NetworkException.forbidden([String? message]) {
    return NetworkException(
      message: message ?? 'Access forbidden',
      code: 'FORBIDDEN',
    );
  }

  factory NetworkException.notFound([String? message]) {
    return NetworkException(
      message: message ?? 'Resource not found',
      code: 'NOT_FOUND',
    );
  }

  factory NetworkException.rateLimited([String? message]) {
    return NetworkException(
      message: message ?? 'Rate limit exceeded',
      code: 'RATE_LIMITED',
    );
  }
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.invalidToken() {
    return const AuthException(
      message: 'Invalid or expired access token',
      code: 'INVALID_TOKEN',
    );
  }

  factory AuthException.tokenExpired() {
    return const AuthException(
      message: 'Access token has expired',
      code: 'TOKEN_EXPIRED',
    );
  }

  factory AuthException.loginFailed([String? message]) {
    return AuthException(
      message: message ?? 'Login failed',
      code: 'LOGIN_FAILED',
    );
  }

  factory AuthException.tokenNotFound() {
    return const AuthException(
      message: 'No access token found',
      code: 'TOKEN_NOT_FOUND',
    );
  }

  factory AuthException.webViewError([String? message]) {
    return AuthException(
      message: message ?? 'WebView authentication failed',
      code: 'WEBVIEW_ERROR',
    );
  }

  factory AuthException.shibbolethError([String? message]) {
    return AuthException(
      message: message ?? 'Shibboleth authentication failed',
      code: 'SHIBBOLETH_ERROR',
    );
  }
}

/// Canvas API-related exceptions
class CanvasException extends AppException {
  const CanvasException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory CanvasException.apiError(String message, [String? code]) {
    return CanvasException(
      message: message,
      code: code ?? 'API_ERROR',
    );
  }

  factory CanvasException.courseNotFound(int courseId) {
    return CanvasException(
      message: 'Course with ID $courseId not found',
      code: 'COURSE_NOT_FOUND',
    );
  }

  factory CanvasException.assignmentNotFound(int assignmentId) {
    return CanvasException(
      message: 'Assignment with ID $assignmentId not found',
      code: 'ASSIGNMENT_NOT_FOUND',
    );
  }

  factory CanvasException.invalidResponse([String? message]) {
    return CanvasException(
      message: message ?? 'Invalid API response format',
      code: 'INVALID_RESPONSE',
    );
  }

  factory CanvasException.quotaExceeded() {
    return const CanvasException(
      message: 'API quota exceeded',
      code: 'QUOTA_EXCEEDED',
    );
  }
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.readError([String? message]) {
    return StorageException(
      message: message ?? 'Failed to read from storage',
      code: 'READ_ERROR',
    );
  }

  factory StorageException.writeError([String? message]) {
    return StorageException(
      message: message ?? 'Failed to write to storage',
      code: 'WRITE_ERROR',
    );
  }

  factory StorageException.deleteError([String? message]) {
    return StorageException(
      message: message ?? 'Failed to delete from storage',
      code: 'DELETE_ERROR',
    );
  }

  factory StorageException.encryptionError([String? message]) {
    return StorageException(
      message: message ?? 'Encryption/decryption failed',
      code: 'ENCRYPTION_ERROR',
    );
  }

  factory StorageException.storageUnavailable() {
    return const StorageException(
      message: 'Storage is not available',
      code: 'STORAGE_UNAVAILABLE',
    );
  }
}

/// Calendar-related exceptions
class CalendarException extends AppException {
  const CalendarException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory CalendarException.permissionDenied() {
    return const CalendarException(
      message: 'Calendar permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory CalendarException.eventCreationFailed([String? message]) {
    return CalendarException(
      message: message ?? 'Failed to create calendar event',
      code: 'EVENT_CREATION_FAILED',
    );
  }

  factory CalendarException.eventUpdateFailed([String? message]) {
    return CalendarException(
      message: message ?? 'Failed to update calendar event',
      code: 'EVENT_UPDATE_FAILED',
    );
  }

  factory CalendarException.eventDeletionFailed([String? message]) {
    return CalendarException(
      message: message ?? 'Failed to delete calendar event',
      code: 'EVENT_DELETION_FAILED',
    );
  }

  factory CalendarException.calendarNotFound() {
    return const CalendarException(
      message: 'Calendar not found',
      code: 'CALENDAR_NOT_FOUND',
    );
  }

  factory CalendarException.syncFailed([String? message]) {
    return CalendarException(
      message: message ?? 'Calendar synchronization failed',
      code: 'SYNC_FAILED',
    );
  }
}

/// Notification-related exceptions
class NotificationException extends AppException {
  const NotificationException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NotificationException.permissionDenied() {
    return const NotificationException(
      message: 'Notification permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory NotificationException.schedulingFailed([String? message]) {
    return NotificationException(
      message: message ?? 'Failed to schedule notification',
      code: 'SCHEDULING_FAILED',
    );
  }

  factory NotificationException.cancellationFailed([String? message]) {
    return NotificationException(
      message: message ?? 'Failed to cancel notification',
      code: 'CANCELLATION_FAILED',
    );
  }

  factory NotificationException.fcmError([String? message]) {
    return NotificationException(
      message: message ?? 'Firebase Cloud Messaging error',
      code: 'FCM_ERROR',
    );
  }

  factory NotificationException.initializationFailed() {
    return const NotificationException(
      message: 'Failed to initialize notification service',
      code: 'INITIALIZATION_FAILED',
    );
  }
}

/// Background sync-related exceptions
class BackgroundSyncException extends AppException {
  const BackgroundSyncException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory BackgroundSyncException.registrationFailed() {
    return const BackgroundSyncException(
      message: 'Failed to register background task',
      code: 'REGISTRATION_FAILED',
    );
  }

  factory BackgroundSyncException.executionFailed([String? message]) {
    return BackgroundSyncException(
      message: message ?? 'Background sync execution failed',
      code: 'EXECUTION_FAILED',
    );
  }

  factory BackgroundSyncException.batteryOptimizationEnabled() {
    return const BackgroundSyncException(
      message: 'Battery optimization is preventing background sync',
      code: 'BATTERY_OPTIMIZATION_ENABLED',
    );
  }

  factory BackgroundSyncException.permissionDenied() {
    return const BackgroundSyncException(
      message: 'Background processing permission denied',
      code: 'PERMISSION_DENIED',
    );
  }
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.invalidToken() {
    return const ValidationException(
      message: 'Invalid token format',
      code: 'INVALID_TOKEN_FORMAT',
    );
  }

  factory ValidationException.emptyField(String fieldName) {
    return ValidationException(
      message: '$fieldName cannot be empty',
      code: 'EMPTY_FIELD',
      fieldErrors: {fieldName: 'This field is required'},
    );
  }

  factory ValidationException.invalidEmail() {
    return const ValidationException(
      message: 'Invalid email format',
      code: 'INVALID_EMAIL',
      fieldErrors: {'email': 'Please enter a valid email address'},
    );
  }

  factory ValidationException.multipleFields(Map<String, String> errors) {
    return ValidationException(
      message: 'Multiple validation errors',
      code: 'MULTIPLE_VALIDATION_ERRORS',
      fieldErrors: errors,
    );
  }
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory CacheException.notFound(String key) {
    return CacheException(
      message: 'Cache entry not found for key: $key',
      code: 'CACHE_NOT_FOUND',
    );
  }

  factory CacheException.expired(String key) {
    return CacheException(
      message: 'Cache entry expired for key: $key',
      code: 'CACHE_EXPIRED',
    );
  }

  factory CacheException.corruptedData() {
    return const CacheException(
      message: 'Cached data is corrupted',
      code: 'CORRUPTED_DATA',
    );
  }

  factory CacheException.sizeLimitExceeded() {
    return const CacheException(
      message: 'Cache size limit exceeded',
      code: 'SIZE_LIMIT_EXCEEDED',
    );
  }
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory PermissionException.denied(String permission) {
    return PermissionException(
      message: '$permission permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory PermissionException.permanentlyDenied(String permission) {
    return PermissionException(
      message: '$permission permission permanently denied',
      code: 'PERMISSION_PERMANENTLY_DENIED',
    );
  }

  factory PermissionException.restricted(String permission) {
    return PermissionException(
      message: '$permission permission restricted',
      code: 'PERMISSION_RESTRICTED',
    );
  }
}

/// API-related exceptions
class ApiException extends AppException {
  final int statusCode;

  const ApiException({
    required super.message,
    required this.statusCode,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ApiException.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ApiException(
          message: message ?? 'Bad request',
          statusCode: statusCode,
          code: 'BAD_REQUEST',
        );
      case 401:
        return ApiException(
          message: message ?? 'Unauthorized',
          statusCode: statusCode,
          code: 'UNAUTHORIZED',
        );
      case 403:
        return ApiException(
          message: message ?? 'Forbidden',
          statusCode: statusCode,
          code: 'FORBIDDEN',
        );
      case 404:
        return ApiException(
          message: message ?? 'Not found',
          statusCode: statusCode,
          code: 'NOT_FOUND',
        );
      case 429:
        return ApiException(
          message: message ?? 'Rate limit exceeded',
          statusCode: statusCode,
          code: 'RATE_LIMITED',
        );
      case 500:
        return ApiException(
          message: message ?? 'Internal server error',
          statusCode: statusCode,
          code: 'INTERNAL_SERVER_ERROR',
        );
      default:
        return ApiException(
          message: message ?? 'API error',
          statusCode: statusCode,
          code: 'API_ERROR',
        );
    }
  }

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Repository-related exceptions
class RepositoryException extends AppException {
  const RepositoryException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory RepositoryException.dataNotFound(String resource) {
    return RepositoryException(
      message: '$resource not found',
      code: 'DATA_NOT_FOUND',
    );
  }

  factory RepositoryException.cacheError([String? message]) {
    return RepositoryException(
      message: message ?? 'Cache operation failed',
      code: 'CACHE_ERROR',
    );
  }

  factory RepositoryException.syncError([String? message]) {
    return RepositoryException(
      message: message ?? 'Data synchronization failed',
      code: 'SYNC_ERROR',
    );
  }

  factory RepositoryException.validationError([String? message]) {
    return RepositoryException(
      message: message ?? 'Data validation failed',
      code: 'VALIDATION_ERROR',
    );
  }
}