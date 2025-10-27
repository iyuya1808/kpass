import 'package:equatable/equatable.dart';
import 'package:kpass/features/auth/domain/entities/user.dart';

/// Authentication state enumeration
enum AuthStatus {
  /// Initial state, checking for existing authentication
  initial,

  /// User is authenticated and has valid token
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Authentication is in progress
  authenticating,

  /// Authentication failed
  failed,

  /// Token has expired and needs refresh
  tokenExpired,
}

/// Authentication state containing user info and status
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;
  final DateTime? tokenExpiresAt;
  final bool isInitializing;
  final Map<String, dynamic>? additionalData;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
    this.tokenExpiresAt,
    this.isInitializing = false,
    this.additionalData,
  });

  /// Initial state
  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      token = null,
      errorMessage = null,
      tokenExpiresAt = null,
      isInitializing = true,
      additionalData = null;

  /// Authenticated state
  const AuthState.authenticated({
    required this.user,
    required this.token,
    this.tokenExpiresAt,
    this.additionalData,
  }) : status = AuthStatus.authenticated,
       errorMessage = null,
       isInitializing = false;

  /// Unauthenticated state
  const AuthState.unauthenticated({this.errorMessage, this.additionalData})
    : status = AuthStatus.unauthenticated,
      user = null,
      token = null,
      tokenExpiresAt = null,
      isInitializing = false;

  /// Authenticating state
  const AuthState.authenticating()
    : status = AuthStatus.authenticating,
      user = null,
      token = null,
      errorMessage = null,
      tokenExpiresAt = null,
      isInitializing = false,
      additionalData = null;

  /// Failed state
  const AuthState.failed({required this.errorMessage, this.additionalData})
    : status = AuthStatus.failed,
      user = null,
      token = null,
      tokenExpiresAt = null,
      isInitializing = false;

  /// Token expired state
  const AuthState.tokenExpired({this.user, this.additionalData})
    : status = AuthStatus.tokenExpired,
      token = null,
      errorMessage = 'Token has expired',
      tokenExpiresAt = null,
      isInitializing = false;

  /// Check if user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null && token != null;

  /// Check if authentication is in progress
  bool get isAuthenticating => status == AuthStatus.authenticating;

  /// Check if there's an error
  bool get hasError => errorMessage != null;

  /// Check if token is expired or about to expire
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  /// Check if token will expire soon (within 1 hour)
  bool get isTokenExpiringSoon {
    if (tokenExpiresAt == null) return false;
    final oneHourFromNow = DateTime.now().add(const Duration(hours: 1));
    return tokenExpiresAt!.isBefore(oneHourFromNow);
  }

  /// Copy with new values
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
    DateTime? tokenExpiresAt,
    bool? isInitializing,
    Map<String, dynamic>? additionalData,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isInitializing: isInitializing ?? this.isInitializing,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    token,
    errorMessage,
    tokenExpiresAt,
    isInitializing,
    additionalData,
  ];

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.name}, hasToken: ${token != null}, error: $errorMessage)';
  }
}
