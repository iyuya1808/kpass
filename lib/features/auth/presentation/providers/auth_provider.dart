import 'package:flutter/foundation.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/auth/data/services/external_browser_auth_service.dart';
import 'package:kpass/features/auth/domain/entities/auth_state.dart';
import 'package:kpass/features/auth/domain/entities/auth_result.dart';
import 'package:kpass/features/auth/domain/entities/user.dart';

class AuthProvider extends ChangeNotifier {
  final ExternalBrowserAuthService _authService;
  bool _isCompletingLogin = false;

  AuthState _authState = const AuthState.initial();

  AuthProvider({ExternalBrowserAuthService? authService})
    : _authService = authService ?? ExternalBrowserAuthService() {
    _initialize();
  }

  // Getters
  AuthState get authState => _authState;
  bool get isInitializing => _authState.isInitializing;
  bool get isAuthenticated => _authState.isAuthenticated;
  bool get isAuthenticating => _authState.isAuthenticating;
  User? get user => _authState.user;
  String? get token => _authState.token;
  String? get errorMessage => _authState.errorMessage;
  bool get hasError => _authState.hasError;

  /// Initialize authentication state
  Future<void> _initialize() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Initializing authentication state');
      }

      // First check if proxy server is reachable
      final proxyConnectionResult = await _authService.checkProxyConnection();

      if (proxyConnectionResult.isFailure) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'AuthProvider: Proxy server connection failed: ${proxyConnectionResult.userFriendlyMessage}',
          );
        }

        _updateState(
          AuthState.failed(
            errorMessage: 'プロキシサーバーに接続できません。プロキシサーバーが起動していることを確認してください。',
          ),
        );
        return;
      }

      // Clean expired cache entries on startup
      await _cleanExpiredCache();

      // Check for stored session cookie and validate it
      final result = await _authService.getStoredSession();

      if (result.isSuccess && result.user != null) {
        _updateState(
          AuthState.authenticated(user: result.user!, token: result.token!),
        );

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'AuthProvider: User authenticated from stored session: ${result.user!.name}',
          );
        }
      } else {
        _updateState(const AuthState.unauthenticated());

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'AuthProvider: No valid stored session found - user needs to login',
          );
        }
      }
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Initialization error: $error');
      }

      _updateState(
        AuthState.failed(errorMessage: 'Failed to initialize: $error'),
      );
    }
  }

  /// Start external browser login process
  Future<AuthResult> startExternalBrowserLogin(String username) async {
    try {
      _updateState(const AuthState.authenticating());

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Starting external browser login');
      }

      // Call external browser auth service
      final result = await _authService.startExternalBrowserLogin(username);

      await _handleAuthResult(result);

      return result;
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Start external browser login error: $error');
      }

      final result = AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Start external browser login failed: $error',
      );
      _updateState(
        AuthState.failed(
          errorMessage: 'Start external browser login failed: $error',
        ),
      );
      return result;
    }
  }

  /// Start manual login process (legacy)
  Future<AuthResult> startManualLogin(String username) async {
    try {
      _updateState(const AuthState.authenticating());

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Starting manual login');
      }

      // Call proxy auth service
      final result = await _authService.startManualLogin(username);

      if (result.type == AuthResultType.manualLoginStarted) {
        _updateState(const AuthState.authenticating());
      } else {
        await _handleAuthResult(result);
      }

      return result;
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Start manual login error: $error');
      }

      final result = AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Start manual login failed: $error',
      );
      _updateState(
        AuthState.failed(errorMessage: 'Start manual login failed: $error'),
      );
      return result;
    }
  }

  /// Complete manual login process (legacy)
  Future<AuthResult> completeManualLogin(String userId) async {
    // Prevent duplicate requests
    if (_isCompletingLogin) {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'AuthProvider: Login completion already in progress, ignoring duplicate request',
        );
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Login completion already in progress',
      );
    }

    try {
      _isCompletingLogin = true;

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Completing manual login');
      }

      // Call proxy auth service
      final result = await _authService.completeManualLogin(userId);

      await _handleAuthResult(result);

      return result;
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Complete manual login error: $error');
      }

      final result = AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Complete manual login failed: $error',
      );
      _updateState(
        AuthState.failed(errorMessage: 'Complete manual login failed: $error'),
      );
      return result;
    } finally {
      _isCompletingLogin = false;
    }
  }

  /// Authenticate with username and password (Proxy API) - Legacy method
  Future<AuthResult> authenticateWithCredentials(
    String username,
    String password,
  ) async {
    try {
      _updateState(const AuthState.authenticating());

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Starting credential authentication');
      }

      // Call proxy auth service
      final result = await _authService.login(username, password);

      await _handleAuthResult(result);

      return result;
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Credential authentication error: $error');
      }

      final result = AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Authentication failed: $error',
      );
      _updateState(
        AuthState.failed(errorMessage: 'Authentication failed: $error'),
      );
      return result;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Logging out user');
      }

      // Clear stored data
      final result = await _authService.logout();

      if (result.isSuccess) {
        _updateState(const AuthState.unauthenticated());

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('AuthProvider: Logout successful');
        }
      } else {
        _updateState(
          AuthState.failed(
            errorMessage: 'Logout failed: ${result.errorMessage}',
          ),
        );
      }
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Logout error: $error');
      }

      _updateState(AuthState.failed(errorMessage: 'Logout failed: $error'));
    }
  }

  /// Refresh authentication state
  Future<void> refresh() async {
    if (_authState.token != null) {
      try {
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint('AuthProvider: Refreshing authentication state');
        }

        // Validate session
        final result = await _authService.validateSession();

        if (result.isSuccess) {
          _updateState(
            AuthState.authenticated(
              user: result.user!,
              token: _authState.token!,
            ),
          );
        } else {
          // Session is no longer valid
          await logout();
        }
      } catch (error) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('AuthProvider: Refresh error: $error');
        }

        _updateState(AuthState.failed(errorMessage: 'Refresh failed: $error'));
      }
    }
  }

  /// Clear error state
  void clearError() {
    if (_authState.hasError) {
      _updateState(const AuthState.unauthenticated());
    }
  }

  /// Check authentication status and refresh if needed
  Future<bool> checkAuthenticationStatus() async {
    if (!isAuthenticated) {
      return false;
    }

    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Checking authentication status');
      }

      // Validate session
      final result = await _authService.validateSession();

      if (result.isSuccess) {
        // Update user data if it has changed
        if (result.user != null) {
          _updateState(
            AuthState.authenticated(
              user: result.user!,
              token: _authState.token!,
            ),
          );
        }
        return true;
      } else {
        // Session is no longer valid
        await logout();
        return false;
      }
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Authentication status check error: $error');
      }
      return false;
    }
  }

  /// Get authentication state for persistence
  Map<String, dynamic>? getAuthStateForPersistence() {
    if (!isAuthenticated || user == null || token == null) {
      return null;
    }

    return {
      'user_id': user!.id,
      'user_name': user!.name,
      'token_length': token!.length,
      'authenticated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      // This is handled by the secure storage service during initialization
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('AuthProvider: Cache cleanup handled by storage service');
      }
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('AuthProvider: Failed to clean expired cache: $error');
      }
    }
  }

  /// Handle authentication result
  Future<void> _handleAuthResult(AuthResult result) async {
    if (result.isSuccess) {
      _updateState(
        AuthState.authenticated(user: result.user!, token: result.token!),
      );
    } else {
      _updateState(AuthState.failed(errorMessage: result.userFriendlyMessage));
    }
  }

  /// Update state and notify listeners
  void _updateState(AuthState newState) {
    _authState = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
