import 'package:equatable/equatable.dart';
import 'package:kpass/features/auth/domain/entities/user.dart';

/// Token validation response from Canvas API
class TokenValidationResponse extends Equatable {
  final bool isValid;
  final User? user;
  final String? errorMessage;
  final String? errorCode;
  final DateTime? expiresAt;
  final List<String> scopes;
  final Map<String, dynamic>? rawResponse;

  const TokenValidationResponse({
    required this.isValid,
    this.user,
    this.errorMessage,
    this.errorCode,
    this.expiresAt,
    this.scopes = const [],
    this.rawResponse,
  });

  /// Valid token response
  const TokenValidationResponse.valid({
    required this.user,
    this.expiresAt,
    this.scopes = const [],
    this.rawResponse,
  })  : isValid = true,
        errorMessage = null,
        errorCode = null;

  /// Invalid token response
  const TokenValidationResponse.invalid({
    this.errorMessage,
    this.errorCode,
    this.rawResponse,
  })  : isValid = false,
        user = null,
        expiresAt = null,
        scopes = const [];

  /// Check if token has required scopes
  bool hasScope(String scope) => scopes.contains(scope);

  /// Check if token has any of the required scopes
  bool hasAnyScope(List<String> requiredScopes) {
    return requiredScopes.any((scope) => scopes.contains(scope));
  }

  /// Check if token has all required scopes
  bool hasAllScopes(List<String> requiredScopes) {
    return requiredScopes.every((scope) => scopes.contains(scope));
  }

  /// Check if token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if token will expire soon (within specified duration)
  bool willExpireSoon([Duration duration = const Duration(hours: 1)]) {
    if (expiresAt == null) return false;
    final threshold = DateTime.now().add(duration);
    return expiresAt!.isBefore(threshold);
  }

  /// Get time until expiration
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Get user-friendly error message
  String get userFriendlyErrorMessage {
    if (isValid) return '';
    
    switch (errorCode) {
      case 'invalid_token':
        return 'The access token is invalid or has expired.';
      case 'insufficient_scope':
        return 'The access token does not have sufficient permissions.';
      case 'token_expired':
        return 'The access token has expired.';
      case 'malformed_token':
        return 'The access token format is invalid.';
      case 'revoked_token':
        return 'The access token has been revoked.';
      default:
        return errorMessage ?? 'Token validation failed.';
    }
  }

  @override
  List<Object?> get props => [
        isValid,
        user,
        errorMessage,
        errorCode,
        expiresAt,
        scopes,
        rawResponse,
      ];

  @override
  String toString() {
    return 'TokenValidationResponse(isValid: $isValid, user: ${user?.name}, error: $errorMessage, scopes: $scopes)';
  }
}