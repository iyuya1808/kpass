import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/proxy_api_client.dart';
import 'package:kpass/core/services/secure_storage_service.dart';
import 'package:kpass/features/auth/domain/entities/auth_result.dart';
import 'package:kpass/features/auth/data/models/user_model.dart';

/// Service for handling external browser authentication
class ExternalBrowserAuthService {
  final ProxyApiClient _apiClient;
  final SecureStorageService _secureStorage;

  ExternalBrowserAuthService({
    ProxyApiClient? apiClient,
    SecureStorageService? secureStorage,
  }) : _apiClient = apiClient ?? ProxyApiClient(),
       _secureStorage = secureStorage ?? SecureStorageService();

  /// Start external browser login process
  Future<AuthResult> startExternalBrowserLogin(String username) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Starting external browser login for user: ${username.substring(0, 3)}***',
        );
      }

      // Call proxy API to start external browser login
      final result = await _apiClient.startExternalBrowserLogin(username);

      if (result.isFailure) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Start external browser login failed: ${result.failureOrNull?.message}',
          );
        }
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              result.failureOrNull?.message ??
              'Failed to start external browser login',
        );
      }

      final data = result.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final loginUrl = data['loginUrl'] as String?;
      final sessionId = data['sessionId'] as String?;
      final userId = data['userId'] as String?;

      if (loginUrl == null || sessionId == null || userId == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server',
        );
      }

      // Launch external browser for authentication
      final authResult = await _authenticateWithExternalBrowser(
        loginUrl,
        sessionId,
      );

      if (authResult.isSuccess) {
        // Start polling for login completion
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint(
            'ExternalBrowserAuthService: External browser launched, starting polling for login completion',
          );
        }

        // Poll for login completion
        return await _pollForLoginCompletion(sessionId);
      } else {
        return authResult;
      }
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Start external browser login error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Start external browser login failed: $error',
      );
    }
  }

  /// Authenticate with external browser using flutter_web_auth
  Future<AuthResult> _authenticateWithExternalBrowser(
    String loginUrl,
    String sessionId,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Launching external browser for authentication',
        );
      }

      // Launch browser based on platform
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // For iOS, use external browser (Safari)
          if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
            debugPrint(
              'ExternalBrowserAuthService: Using external Safari for iOS',
            );
          }

          final uri = Uri.parse(loginUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // For other platforms, use FlutterWebAuth with timeout
          if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
            debugPrint(
              'ExternalBrowserAuthService: Using FlutterWebAuth for non-iOS platform',
            );
          }

          await FlutterWebAuth.authenticate(
            url: loginUrl,
            callbackUrlScheme: 'kpass',
          ).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
                debugPrint(
                  'ExternalBrowserAuthService: FlutterWebAuth timeout - continuing with polling',
                );
              }
              return 'kpass://timeout'; // Dummy callback to continue
            },
          );
        }
      } catch (e) {
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Browser launch error (expected): $e',
          );
        }
      }

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ExternalBrowserAuthService: External browser launched successfully',
        );
      }

      // Return success to indicate browser was launched
      return const AuthResult.success(user: null, token: null);
    } on PlatformException catch (e) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Platform exception during authentication: ${e.code} - ${e.message}',
        );
      }

      if (e.code == 'CANCELLED') {
        return const AuthResult.failure(
          type: AuthResultType.cancelled,
          errorMessage: 'Authentication was cancelled by user',
        );
      } else if (e.code == 'EUNKNOWN') {
        // iOS WebAuthenticationSession error - try alternative approach
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ExternalBrowserAuthService: iOS WebAuthenticationSession error, trying alternative approach',
          );
        }

        // For now, return a success result to continue the flow
        // In a real implementation, you might want to try url_launcher as fallback
        return const AuthResult.success(user: null, token: null);
      } else {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Authentication failed: ${e.message}',
        );
      }
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ExternalBrowserAuthService: Authentication error: $error');
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Authentication failed: $error',
      );
    }
  }

  /// Poll for login completion
  Future<AuthResult> _pollForLoginCompletion(String sessionId) async {
    const maxAttempts = 60; // 5 minutes with 5-second intervals
    const pollInterval = Duration(seconds: 5);

    if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
      debugPrint(
        'ExternalBrowserAuthService: Starting polling for session: $sessionId (max $maxAttempts attempts)',
      );
    }

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Polling attempt ${attempt + 1}/$maxAttempts for session: $sessionId',
          );
        }

        // Check login status
        final statusResult = await _apiClient.checkExternalBrowserLoginStatus(
          sessionId,
        );

        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Status check result: ${statusResult.isSuccess ? 'success' : 'failure'}',
          );
        }

        if (statusResult.isSuccess) {
          final data = statusResult.valueOrNull;
          final loggedIn = data?['loggedIn'] as bool?;

          if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
            debugPrint('ExternalBrowserAuthService: Login status: $loggedIn');
          }

          if (loggedIn == true) {
            if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
              debugPrint(
                'ExternalBrowserAuthService: Login detected, completing login process',
              );
            }

            // Complete the login process
            return await _completeExternalBrowserLogin(sessionId);
          }
        } else {
          if (kDebugMode && EnvironmentConfig.enableLogging) {
            debugPrint(
              'ExternalBrowserAuthService: Status check failed: ${statusResult.failureOrNull?.message}',
            );
          }
        }

        // Wait before next poll
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Waiting ${pollInterval.inSeconds} seconds before next poll...',
          );
        }
        await Future.delayed(pollInterval);
      } catch (error) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Polling error (attempt ${attempt + 1}): $error',
          );
        }

        // Continue polling even if there's an error
        await Future.delayed(pollInterval);
      }
    }

    // Timeout reached
    if (kDebugMode && EnvironmentConfig.enableLogging) {
      debugPrint(
        'ExternalBrowserAuthService: Polling timeout reached for session: $sessionId',
      );
    }

    return const AuthResult.failure(
      type: AuthResultType.cancelled,
      errorMessage: 'Login timeout. Please try again.',
    );
  }

  /// Complete external browser login process
  Future<AuthResult> _completeExternalBrowserLogin(String sessionId) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Completing external browser login for session: $sessionId',
        );
      }

      // For external browser login, the proxy server will handle browser automation
      // We don't need to send cookies as the server will extract them internally
      final emptyCookies = <Map<String, dynamic>>[];

      // Call proxy API to complete external browser login
      final result = await _apiClient.completeExternalBrowserLogin(sessionId, emptyCookies);

      if (result.isFailure) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ExternalBrowserAuthService: Complete external browser login failed: ${result.failureOrNull?.message}',
          );
        }
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              result.failureOrNull?.message ??
              'Failed to complete external browser login',
        );
      }

      // Extract response data
      final data = result.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server',
        );
      }

      // Store token
      final storeResult = await _secureStorage.storeProxyAuthToken(token);
      if (storeResult.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Failed to store authentication token',
        );
      }

      // Parse user data and store it
      final userModel = UserModel.fromCanvasJson(userData);
      await _secureStorage.storeUserData(userData);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ExternalBrowserAuthService: External browser login completed successfully for user: ${userModel.name}',
        );
      }

      return AuthResult.success(user: userModel.toEntity(), token: token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Complete external browser login error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Complete external browser login failed: $error',
      );
    }
  }

  /// Validate current session
  Future<AuthResult> validateSession() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ExternalBrowserAuthService: Validating session');
      }

      // Get stored token
      final tokenResult = await _secureStorage.getProxyAuthToken();
      if (tokenResult.isFailure) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'No stored authentication token found',
        );
      }

      // Call proxy API to validate session
      final result = await _apiClient.validateSession();

      if (result.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              result.failureOrNull?.message ?? 'Session validation failed',
        );
      }

      final data = result.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final userData = data['user'] as Map<String, dynamic>?;

      if (userData == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server',
        );
      }

      // Parse user data
      final userModel = UserModel.fromCanvasJson(userData);
      await _secureStorage.storeUserData(userData);

      final token = tokenResult.valueOrNull;
      if (token == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Stored token is null',
        );
      }

      return AuthResult.success(user: userModel.toEntity(), token: token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Validate session error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Session validation failed: $error',
      );
    }
  }

  /// Get stored session
  Future<AuthResult> getStoredSession() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ExternalBrowserAuthService: Getting stored session');
      }

      // Get stored token
      final tokenResult = await _secureStorage.getProxyAuthToken();
      if (tokenResult.isFailure) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'No stored authentication token found',
        );
      }

      // Get stored user data
      final userDataResult = await _secureStorage.getUserData();
      if (userDataResult.isFailure) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'No stored user data found',
        );
      }

      final userData = userDataResult.valueOrNull;
      if (userData == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Stored user data is null',
        );
      }

      final userModel = UserModel.fromCanvasJson(userData);
      final token = tokenResult.valueOrNull;
      if (token == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Stored token is null',
        );
      }

      return AuthResult.success(user: userModel.toEntity(), token: token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Get stored session error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Failed to get stored session: $error',
      );
    }
  }

  /// Logout
  Future<AuthResult> logout() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ExternalBrowserAuthService: Logging out');
      }

      // Get stored token
      final tokenResult = await _secureStorage.getProxyAuthToken();
      if (tokenResult.isSuccess) {
        // Call proxy API to logout
        await _apiClient.logout();
      }

      // Clear stored data
      await _secureStorage.deleteProxyAuthToken();
      await _secureStorage.deleteUserData();

      return const AuthResult.success(user: null, token: null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ExternalBrowserAuthService: Logout error: $error');
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Logout failed: $error',
      );
    }
  }

  /// Check proxy server connection
  Future<AuthResult> checkProxyConnection() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Checking proxy server connection',
        );
      }

      final result = await _apiClient.checkProxyConnection();

      if (result.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              result.failureOrNull?.message ?? 'Proxy server connection failed',
        );
      }

      return const AuthResult.success(user: null, token: null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Check proxy connection error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Proxy server connection check failed: $error',
      );
    }
  }

  /// Start manual login process (legacy)
  Future<AuthResult> startManualLogin(String username) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ExternalBrowserAuthService: Starting manual login');
      }

      final result = await _apiClient.startManualLogin(username);

      if (result.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              result.failureOrNull?.message ?? 'Failed to start manual login',
        );
      }

      final data = result.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final userId = data['userId'] as String?;
      final instructions = data['instructions'] as String?;

      if (userId == null || instructions == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              'Invalid response from server: missing userId or instructions',
        );
      }

      return AuthResult.manualLoginStarted(
        userId: userId,
        instructions: instructions,
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Start manual login error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Manual login failed: $error',
      );
    }
  }

  /// Complete manual login process (legacy)
  Future<AuthResult> completeManualLogin(String userId) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ExternalBrowserAuthService: Completing manual login');
      }

      final result = await _apiClient.completeManualLogin(userId);

      if (result.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              result.failureOrNull?.message ??
              'Failed to complete manual login',
        );
      }

      final data = result.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              'Invalid response from server: missing token or user data',
        );
      }

      // Store token
      final storeResult = await _secureStorage.storeProxyAuthToken(token);
      if (storeResult.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Failed to store authentication token',
        );
      }

      // Parse user data and store it
      final userModel = UserModel.fromCanvasJson(userData);
      await _secureStorage.storeUserData(userData);

      // Immediately validate session to fetch full Canvas profile
      final validated = await validateSession();
      if (validated.isSuccess) {
        final validatedUser = validated.user!;
        return AuthResult.success(user: validatedUser, token: token);
      }

      return AuthResult.success(user: userModel.toEntity(), token: token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ExternalBrowserAuthService: Complete manual login error: $error',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Complete manual login failed: $error',
      );
    }
  }

  /// Authenticate with username and password (legacy)
  Future<AuthResult> login(String username, String password) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ExternalBrowserAuthService: Starting legacy login');
      }

      final result = await _apiClient.login(username, password);

      if (result.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: result.failureOrNull?.message ?? 'Failed to login',
        );
      }

      final data = result.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              'Invalid response from server: missing token or user data',
        );
      }

      // Store token
      final storeResult = await _secureStorage.storeProxyAuthToken(token);
      if (storeResult.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Failed to store authentication token',
        );
      }

      // Parse user data and store it
      final userModel = UserModel.fromCanvasJson(userData);
      await _secureStorage.storeUserData(userData);

      return AuthResult.success(user: userModel.toEntity(), token: token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ExternalBrowserAuthService: Legacy login error: $error');
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Legacy login failed: $error',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    // No resources to dispose in this service
  }
}
