import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'package:kpass/core/errors/failures.dart';
import 'package:kpass/core/constants/app_constants.dart';

/// Utility class for handling and converting errors/exceptions
class ErrorHandler {
  /// Convert exceptions to failures for the domain layer
  static Failure handleException(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ErrorHandler: Converting exception to failure');
      debugPrint('Exception type: ${error.runtimeType}');
      debugPrint('Exception: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }

    // Handle custom app exceptions
    if (error is AppException) {
      return _convertAppExceptionToFailure(error);
    }

    // Handle Dio exceptions (HTTP client)
    if (error is DioException) {
      return _convertDioExceptionToFailure(error);
    }

    // Handle socket exceptions (network)
    if (error is SocketException) {
      return NetworkFailure.noConnection();
    }

    // Handle timeout exceptions
    if (error is TimeoutException) {
      return NetworkFailure.timeout();
    }

    // Handle format exceptions (JSON parsing)
    if (error is FormatException) {
      return CanvasFailure.invalidResponse(error.message);
    }

    // Handle type errors
    if (error is TypeError) {
      return CanvasFailure.invalidResponse('Data type mismatch: ${error.toString()}');
    }

    // Handle argument errors
    if (error is ArgumentError) {
      return ValidationFailure(
        message: 'Invalid argument: ${error.message}',
        code: 'INVALID_ARGUMENT',
      );
    }

    // Handle state errors
    if (error is StateError) {
      return GeneralFailure(
        message: 'Invalid state: ${error.message}',
        code: 'INVALID_STATE',
      );
    }

    // Handle unsupported errors
    if (error is UnsupportedError) {
      return GeneralFailure.notImplemented(error.message);
    }

    // Default case for unknown errors
    return GeneralFailure.unknown(error.toString());
  }

  /// Convert app exceptions to failures
  static Failure _convertAppExceptionToFailure(AppException exception) {
    return switch (exception) {
      NetworkException() => NetworkFailure(
          message: exception.message,
          code: exception.code,
        ),
      AuthException() => AuthFailure(
          message: exception.message,
          code: exception.code,
        ),
      CanvasException() => CanvasFailure(
          message: exception.message,
          code: exception.code,
        ),
      StorageException() => StorageFailure(
          message: exception.message,
          code: exception.code,
        ),
      CalendarException() => CalendarFailure(
          message: exception.message,
          code: exception.code,
        ),
      NotificationException() => NotificationFailure(
          message: exception.message,
          code: exception.code,
        ),
      BackgroundSyncException() => BackgroundSyncFailure(
          message: exception.message,
          code: exception.code,
        ),
      ValidationException() => ValidationFailure(
          message: exception.message,
          code: exception.code,
          fieldErrors: exception.fieldErrors,
        ),
      CacheException() => CacheFailure(
          message: exception.message,
          code: exception.code,
        ),
      PermissionException() => PermissionFailure(
          message: exception.message,
          code: exception.code,
        ),
      _ => GeneralFailure(
          message: exception.message,
          code: exception.code,
        ),
    };
  }

  /// Convert Dio exceptions to network failures
  static NetworkFailure _convertDioExceptionToFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure.timeout();

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return NetworkFailure.noConnection();
        }
        return NetworkFailure(
          message: 'Connection error: ${error.message}',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 
                       error.response?.statusMessage ?? 
                       error.message;

        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              return NetworkFailure.badRequest(message);
            case 401:
              return NetworkFailure.unauthorized(message);
            case 403:
              return NetworkFailure.forbidden(message);
            case 404:
              return NetworkFailure.notFound(message);
            case 429:
              return NetworkFailure.rateLimited(message);
            case >= 500:
              return NetworkFailure.serverError(statusCode, message);
            default:
              return NetworkFailure.serverError(statusCode, message);
          }
        }
        return NetworkFailure(
          message: message ?? 'Bad response',
          code: 'BAD_RESPONSE',
        );

      case DioExceptionType.cancel:
        return const NetworkFailure(
          message: 'Request was cancelled',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'Bad certificate',
          code: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkFailure.noConnection();
        }
        return NetworkFailure(
          message: error.message ?? 'Unknown network error',
          code: 'UNKNOWN_NETWORK_ERROR',
        );
    }
  }

  /// Get user-friendly error message from failure
  static String getErrorMessage(Failure failure) {
    // Return localized error messages based on failure type and code
    return switch (failure) {
      NetworkFailure() => _getNetworkErrorMessage(failure),
      AuthFailure() => _getAuthErrorMessage(failure),
      CanvasFailure() => _getCanvasErrorMessage(failure),
      StorageFailure() => _getStorageErrorMessage(failure),
      CalendarFailure() => _getCalendarErrorMessage(failure),
      NotificationFailure() => _getNotificationErrorMessage(failure),
      ValidationFailure() => _getValidationErrorMessage(failure),
      PermissionFailure() => _getPermissionErrorMessage(failure),
      _ => failure.message.isNotEmpty 
          ? failure.message 
          : AppConstants.unknownErrorMessage,
    };
  }

  static String _getNetworkErrorMessage(NetworkFailure failure) {
    switch (failure.code) {
      case 'NO_CONNECTION':
        return AppConstants.networkErrorMessage;
      case 'TIMEOUT':
        return 'Request timed out. Please try again.';
      case 'UNAUTHORIZED':
        return AppConstants.authErrorMessage;
      case 'FORBIDDEN':
        return 'Access denied. You don\'t have permission to access this resource.';
      case 'NOT_FOUND':
        return 'The requested resource was not found.';
      case 'RATE_LIMITED':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        if (failure.code?.startsWith('SERVER_ERROR_') == true) {
          return 'Server error occurred. Please try again later.';
        }
        return failure.message.isNotEmpty 
          ? failure.message 
          : AppConstants.networkErrorMessage;
    }
  }

  static String _getAuthErrorMessage(AuthFailure failure) {
    switch (failure.code) {
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        return AppConstants.tokenExpiredMessage;
      case 'TOKEN_NOT_FOUND':
        return 'Please log in to continue.';
      case 'LOGIN_FAILED':
        return AppConstants.authErrorMessage;
      case 'WEBVIEW_ERROR':
        return 'Login failed. Please try again or use manual token input.';
      case 'SHIBBOLETH_ERROR':
        return 'University authentication failed. Please check your credentials.';
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : AppConstants.authErrorMessage;
    }
  }

  static String _getCanvasErrorMessage(CanvasFailure failure) {
    switch (failure.code) {
      case 'COURSE_NOT_FOUND':
        return 'Course not found. It may have been removed or you may not have access.';
      case 'ASSIGNMENT_NOT_FOUND':
        return 'Assignment not found. It may have been removed or modified.';
      case 'INVALID_RESPONSE':
        return 'Invalid response from server. Please try again.';
      case 'QUOTA_EXCEEDED':
        return 'API limit exceeded. Please wait a moment and try again.';
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : 'Canvas API error occurred.';
    }
  }

  static String _getStorageErrorMessage(StorageFailure failure) {
    switch (failure.code) {
      case 'READ_ERROR':
        return 'Failed to read data. Please try again.';
      case 'WRITE_ERROR':
        return 'Failed to save data. Please check available storage space.';
      case 'DELETE_ERROR':
        return 'Failed to delete data. Please try again.';
      case 'ENCRYPTION_ERROR':
        return 'Security error occurred. Please restart the app.';
      case 'STORAGE_UNAVAILABLE':
        return 'Storage is not available. Please check device storage.';
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : 'Storage error occurred.';
    }
  }

  static String _getCalendarErrorMessage(CalendarFailure failure) {
    switch (failure.code) {
      case 'PERMISSION_DENIED':
        return AppConstants.permissionDeniedMessage;
      case 'EVENT_CREATION_FAILED':
        return 'Failed to create calendar event. Please check calendar permissions.';
      case 'EVENT_UPDATE_FAILED':
        return 'Failed to update calendar event. Please try again.';
      case 'EVENT_DELETION_FAILED':
        return 'Failed to delete calendar event. Please try again.';
      case 'CALENDAR_NOT_FOUND':
        return 'Calendar not found. Please check your calendar settings.';
      case 'SYNC_FAILED':
        return 'Calendar synchronization failed. Please try again.';
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : 'Calendar error occurred.';
    }
  }

  static String _getNotificationErrorMessage(NotificationFailure failure) {
    switch (failure.code) {
      case 'PERMISSION_DENIED':
        return AppConstants.permissionDeniedMessage;
      case 'SCHEDULING_FAILED':
        return 'Failed to schedule notification. Please check notification permissions.';
      case 'CANCELLATION_FAILED':
        return 'Failed to cancel notification. Please try again.';
      case 'FCM_ERROR':
        return 'Push notification error occurred. Local notifications will be used instead.';
      case 'INITIALIZATION_FAILED':
        return 'Failed to initialize notifications. Please restart the app.';
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : 'Notification error occurred.';
    }
  }

  static String _getValidationErrorMessage(ValidationFailure failure) {
    if (failure.fieldErrors?.isNotEmpty == true) {
      return failure.fieldErrors!.values.first;
    }
    return failure.message.isNotEmpty 
      ? failure.message 
      : 'Validation error occurred.';
  }

  static String _getPermissionErrorMessage(PermissionFailure failure) {
    switch (failure.code) {
      case 'PERMISSION_DENIED':
        return '${failure.details?['permission'] ?? 'Required'} permission denied. Please grant permission in settings.';
      case 'PERMISSION_PERMANENTLY_DENIED':
        return '${failure.details?['permission'] ?? 'Required'} permission permanently denied. Please enable it in app settings.';
      case 'PERMISSION_RESTRICTED':
        return '${failure.details?['permission'] ?? 'Required'} permission restricted. Please check device settings.';
      default:
        return failure.message.isNotEmpty 
          ? failure.message 
          : AppConstants.permissionDeniedMessage;
    }
  }

  /// Check if failure requires user action (like re-authentication)
  static bool requiresUserAction(Failure failure) {
    if (failure is AuthFailure) {
      return failure.code == 'TOKEN_EXPIRED' || 
             failure.code == 'INVALID_TOKEN' ||
             failure.code == 'TOKEN_NOT_FOUND';
    }
    
    if (failure is NetworkFailure) {
      return failure.code == 'UNAUTHORIZED';
    }
    
    if (failure is PermissionFailure) {
      return failure.code == 'PERMISSION_DENIED' ||
             failure.code == 'PERMISSION_PERMANENTLY_DENIED';
    }
    
    return false;
  }

  /// Check if failure is retryable
  static bool isRetryable(Failure failure) {
    if (failure is NetworkFailure) {
      return failure.code == 'TIMEOUT' ||
             failure.code == 'NO_CONNECTION' ||
             failure.code?.startsWith('SERVER_ERROR_5') == true;
    }
    
    if (failure is CanvasFailure) {
      return failure.code == 'QUOTA_EXCEEDED';
    }
    
    return false;
  }

  /// Log error for debugging and crash reporting
  static void logError(dynamic error, [StackTrace? stackTrace, Map<String, dynamic>? context]) {
    if (kDebugMode) {
      debugPrint('=== ERROR LOG ===');
      debugPrint('Error: $error');
      debugPrint('Type: ${error.runtimeType}');
      if (context != null) {
        debugPrint('Context: $context');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
      debugPrint('================');
    }
    
    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // CrashReporting.recordError(error, stackTrace, context);
  }
}