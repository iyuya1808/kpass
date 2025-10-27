import 'package:equatable/equatable.dart';
import 'package:kpass/features/auth/domain/entities/user.dart';

/// Authentication result types
enum AuthResultType {
  /// Authentication was successful
  success,

  /// Authentication failed due to invalid credentials
  invalidCredentials,

  /// Authentication failed due to network error
  networkError,

  /// Authentication failed due to server error
  serverError,

  /// Authentication was cancelled by user
  cancelled,

  /// Token validation failed
  tokenValidationFailed,

  /// WebView authentication failed
  webViewError,

  /// Shibboleth authentication failed
  shibbolethError,

  /// Manual login is required
  manualLoginRequired,

  /// Manual login has been started
  manualLoginStarted,

  /// External browser has been launched
  externalBrowserLaunched,

  /// Unknown error occurred
  unknown,
}

/// Result of an authentication attempt
class AuthResult extends Equatable {
  final AuthResultType type;
  final User? user;
  final String? token;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? additionalData;

  const AuthResult({
    required this.type,
    this.user,
    this.token,
    this.errorMessage,
    this.errorCode,
    this.additionalData,
  });

  /// Successful authentication result
  const AuthResult.success({
    required this.user,
    required this.token,
    this.additionalData,
  }) : type = AuthResultType.success,
       errorMessage = null,
       errorCode = null;

  /// Failed authentication result
  const AuthResult.failure({
    required this.type,
    this.errorMessage,
    this.errorCode,
    this.additionalData,
  }) : user = null,
       token = null;

  /// Invalid credentials result
  const AuthResult.invalidCredentials({
    this.errorMessage = 'Invalid credentials provided',
    this.errorCode,
  }) : type = AuthResultType.invalidCredentials,
       user = null,
       token = null,
       additionalData = null;

  /// Network error result
  const AuthResult.networkError({
    this.errorMessage = 'Network connection error',
    this.errorCode,
  }) : type = AuthResultType.networkError,
       user = null,
       token = null,
       additionalData = null;

  /// Server error result
  const AuthResult.serverError({
    this.errorMessage = 'Server error occurred',
    this.errorCode,
  }) : type = AuthResultType.serverError,
       user = null,
       token = null,
       additionalData = null;

  /// Cancelled result
  const AuthResult.cancelled()
    : type = AuthResultType.cancelled,
      user = null,
      token = null,
      errorMessage = 'Authentication was cancelled',
      errorCode = null,
      additionalData = null;

  /// Token validation failed result
  const AuthResult.tokenValidationFailed({
    this.errorMessage = 'Token validation failed',
    this.errorCode,
  }) : type = AuthResultType.tokenValidationFailed,
       user = null,
       token = null,
       additionalData = null;

  /// WebView error result
  const AuthResult.webViewError({
    this.errorMessage = 'WebView authentication failed',
    this.errorCode,
  }) : type = AuthResultType.webViewError,
       user = null,
       token = null,
       additionalData = null;

  /// Shibboleth error result
  const AuthResult.shibbolethError({
    this.errorMessage = 'Shibboleth authentication failed',
    this.errorCode,
  }) : type = AuthResultType.shibbolethError,
       user = null,
       token = null,
       additionalData = null;

  /// Manual login required result
  const AuthResult.manualLoginRequired({
    this.errorMessage = 'Manual login is required',
    this.errorCode,
    this.additionalData,
  }) : type = AuthResultType.manualLoginRequired,
       user = null,
       token = null;

  /// Manual login started result
  AuthResult.manualLoginStarted({
    required String userId,
    required String instructions,
    this.errorCode,
    Map<String, dynamic>? additionalData,
  }) : type = AuthResultType.manualLoginStarted,
       user = null,
       token = null,
       errorMessage = instructions,
       additionalData = {
         'userId': userId,
         'instructions': instructions,
         ...?additionalData,
       };

  /// External browser launched result
  const AuthResult.externalBrowserLaunched({
    this.errorMessage = 'External browser launched for authentication',
    this.errorCode,
    this.additionalData,
  }) : type = AuthResultType.externalBrowserLaunched,
       user = null,
       token = null;

  /// Unknown error result
  const AuthResult.unknown({
    this.errorMessage = 'Unknown error occurred',
    this.errorCode,
  }) : type = AuthResultType.unknown,
       user = null,
       token = null,
       additionalData = null;

  /// Check if authentication was successful
  bool get isSuccess => type == AuthResultType.success;

  /// Check if authentication failed
  bool get isFailure => !isSuccess;

  /// Check if error is retryable
  bool get isRetryable {
    switch (type) {
      case AuthResultType.networkError:
      case AuthResultType.serverError:
      case AuthResultType.unknown:
        return true;
      case AuthResultType.invalidCredentials:
      case AuthResultType.tokenValidationFailed:
      case AuthResultType.cancelled:
      case AuthResultType.webViewError:
      case AuthResultType.shibbolethError:
      case AuthResultType.manualLoginRequired:
      case AuthResultType.manualLoginStarted:
      case AuthResultType.externalBrowserLaunched:
      case AuthResultType.success:
        return false;
    }
  }

  /// Check if user action is required
  bool get requiresUserAction {
    switch (type) {
      case AuthResultType.invalidCredentials:
      case AuthResultType.tokenValidationFailed:
      case AuthResultType.webViewError:
      case AuthResultType.shibbolethError:
      case AuthResultType.manualLoginRequired:
      case AuthResultType.manualLoginStarted:
      case AuthResultType.externalBrowserLaunched:
        return true;
      case AuthResultType.networkError:
      case AuthResultType.serverError:
      case AuthResultType.cancelled:
      case AuthResultType.unknown:
      case AuthResultType.success:
        return false;
    }
  }

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (type) {
      case AuthResultType.success:
        return 'Authentication successful';
      case AuthResultType.invalidCredentials:
        return 'Invalid access token. Please check your token and try again.';
      case AuthResultType.networkError:
        return 'Network connection error. Please check your internet connection and try again.';
      case AuthResultType.serverError:
        return 'Server error occurred. Please try again later.';
      case AuthResultType.cancelled:
        return 'Authentication was cancelled.';
      case AuthResultType.tokenValidationFailed:
        return 'Token validation failed. Please check your token format.';
      case AuthResultType.webViewError:
        return 'Login failed. Please try again or use manual token input.';
      case AuthResultType.shibbolethError:
        return 'University authentication failed. Please check your credentials.';
      case AuthResultType.manualLoginRequired:
        return 'Manual login is required. Please use the manual login flow.';
      case AuthResultType.manualLoginStarted:
        return errorMessage ??
            'Please log in to K-LMS in the opened browser window.';
      case AuthResultType.externalBrowserLaunched:
        return errorMessage ?? 'External browser launched for authentication.';
      case AuthResultType.unknown:
        return errorMessage ?? 'An unknown error occurred. Please try again.';
    }
  }

  @override
  List<Object?> get props => [
    type,
    user,
    token,
    errorMessage,
    errorCode,
    additionalData,
  ];

  @override
  String toString() {
    return 'AuthResult(type: $type, success: $isSuccess, user: ${user?.name}, error: $errorMessage)';
  }
}
