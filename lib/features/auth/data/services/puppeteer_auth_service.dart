import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/proxy_api_client.dart';
import 'package:kpass/core/services/secure_storage_service.dart';
import 'package:kpass/features/auth/data/models/user_model.dart';
import 'package:kpass/features/auth/domain/entities/auth_result.dart';
import 'package:url_launcher/url_launcher.dart';

class PuppeteerAuthService {
  final ProxyApiClient _apiClient;
  final SecureStorageService _secureStorage;

  PuppeteerAuthService({
    ProxyApiClient? apiClient,
    SecureStorageService? secureStorage,
  }) : _apiClient = apiClient ?? ProxyApiClient(),
       _secureStorage = secureStorage ?? SecureStorageService();

  Future<AuthResult> startPuppeteerLogin(String username) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'PuppeteerAuthService: Starting puppeteer login for user: ${username.substring(0, 3)}***',
        );
      }

      final start = await _apiClient.startPuppeteerLogin(username);
      if (start.isFailure) {
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage:
              start.failureOrNull?.message ?? 'Failed to start puppeteer login',
        );
      }

      final data = start.valueOrNull;
      if (data == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: data is null',
        );
      }

      final sessionId = data['sessionId'] as String?;
      final manualControlUrl = data['manualControlUrl'] as String?;
      final remoteControlUrl = data['remoteControlUrl'] as String?;

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'PuppeteerAuthService: sessionId=$sessionId manualControlUrl=${manualControlUrl ?? 'n/a'} remoteControlUrl=${remoteControlUrl ?? 'n/a'}',
        );
      }

      if (sessionId == null) {
        return const AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: 'Invalid response from server: missing sessionId',
        );
      }

      // Open remote control URL in external browser (Safari on iOS)
      if (remoteControlUrl != null && remoteControlUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(remoteControlUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (kDebugMode && EnvironmentConfig.enableLogging) {
            debugPrint(
              'PuppeteerAuthService: Failed to open remoteControlUrl: $e',
            );
          }
        }
      }

      // Poll status
      return await _pollStatus(sessionId);
    } catch (e) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('PuppeteerAuthService: start error: $e');
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Start puppeteer login failed: $e',
      );
    }
  }

  Future<AuthResult> _pollStatus(String sessionId) async {
    const maxAttempts = 60; // up to ~5 minutes if 5s interval
    const pollInterval = Duration(seconds: 5);

    for (int i = 0; i < maxAttempts; i++) {
      try {
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint(
            'PuppeteerAuthService: Polling ${i + 1}/$maxAttempts for $sessionId',
          );
        }
        final statusRes = await _apiClient.getPuppeteerLoginStatus(sessionId);
        if (statusRes.isSuccess) {
          final payload = statusRes.valueOrNull ?? const {};
          final status = payload['status'] as String?;
          if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
            debugPrint('PuppeteerAuthService: Status=$status');
          }

          if (status == 'success') {
            final token = payload['token'] as String?;
            final userMap = payload['user'] as Map<String, dynamic>?;
            if (token == null || userMap == null) {
              return const AuthResult.failure(
                type: AuthResultType.unknown,
                errorMessage: 'Invalid success payload: missing token/user',
              );
            }
            final store = await _secureStorage.storeProxyAuthToken(token);
            if (store.isFailure) {
              return AuthResult.failure(
                type: AuthResultType.unknown,
                errorMessage: 'Failed to store token',
              );
            }
            await _secureStorage.storeUserData(userMap);
            final user = UserModel.fromCanvasJson(userMap).toEntity();
            return AuthResult.success(user: user, token: token);
          }

          if (status == 'failed') {
            final message = payload['error'] as String? ?? 'Login failed';
            return AuthResult.failure(
              type: AuthResultType.unknown,
              errorMessage: message,
            );
          }
        }
      } catch (_) {}
      await Future.delayed(pollInterval);
    }

    return const AuthResult.failure(
      type: AuthResultType.cancelled,
      errorMessage: 'Login timeout. Please try again.',
    );
  }

  Future<AuthResult> validateSession() async {
    final result = await _apiClient.validateSession();
    if (result.isFailure) {
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: result.failureOrNull?.message ?? 'Validate failed',
      );
    }
    final data = result.valueOrNull;
    if (data == null) {
      return const AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Invalid response',
      );
    }
    final userData = data['user'] as Map<String, dynamic>?;
    if (userData == null) {
      return const AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Invalid user payload',
      );
    }
    await _secureStorage.storeUserData(userData);
    final tokenRes = await _secureStorage.getProxyAuthToken();
    if (!tokenRes.isSuccess || tokenRes.valueOrNull == null) {
      return const AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Stored token not found',
      );
    }
    final user = UserModel.fromCanvasJson(userData).toEntity();
    return AuthResult.success(user: user, token: tokenRes.valueOrNull);
  }

  Future<AuthResult> getStoredSession() async {
    final tokenRes = await _secureStorage.getProxyAuthToken();
    if (!tokenRes.isSuccess || tokenRes.valueOrNull == null) {
      return const AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'No stored authentication token found',
      );
    }
    final userRes = await _secureStorage.getUserData();
    if (!userRes.isSuccess || userRes.valueOrNull == null) {
      return const AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'No stored user data found',
      );
    }
    final user = UserModel.fromCanvasJson(userRes.valueOrNull!).toEntity();
    return AuthResult.success(user: user, token: tokenRes.valueOrNull);
  }

  Future<AuthResult> logout() async {
    await _apiClient.logout();
    await _secureStorage.deleteProxyAuthToken();
    await _secureStorage.deleteUserData();
    return const AuthResult.success(user: null, token: null);
  }

  // Legacy/stub methods to maintain compatibility with AuthProvider
  Future<AuthResult> startManualLogin(String username) async {
    return const AuthResult.failure(
      type: AuthResultType.unknown,
      errorMessage: 'Manual login is no longer supported.',
    );
  }

  Future<AuthResult> completeManualLogin(String userId) async {
    return const AuthResult.failure(
      type: AuthResultType.unknown,
      errorMessage: 'Manual login completion is no longer supported.',
    );
  }

  Future<AuthResult> login(String username, String password) async {
    return const AuthResult.failure(
      type: AuthResultType.unknown,
      errorMessage: 'Credential login is deprecated. Use Puppeteer login.',
    );
  }

  /// Authenticate with username/password using server-side Puppeteer.
  Future<AuthResult> authenticateWithCredentials(
    String username,
    String password, {
    void Function(String step, String? detail)? onProgress,
  }) async {
    try {
      // Start progress polling while waiting for completion/inProgress states
      final pollStop = ValueNotifier<bool>(false);
      // Emit initial progress immediately for UI feedback
      if (onProgress != null) {
        onProgress('start', 'ログインを開始しています…');
      }
      Future<void> poll() async {
        while (!pollStop.value) {
          final pr = await _apiClient.getCredentialsLoginStatus(username);
          if (pr.isSuccess) {
            final data = pr.valueOrNull;
            if (data != null && onProgress != null) {
              onProgress(
                data['step']?.toString() ?? '',
                data['detail']?.toString(),
              );
              if (data['step'] == 'success' || data['step'] == 'failed') {
                pollStop.value = true;
              }
            }
          }
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }

      // Fire-and-forget
      unawaited(poll());

      // Send credentials request while polling is active
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('PuppeteerAuthService: Sending credentials login request');
        debugPrint(
          'PuppeteerAuthService: Username: ${username.substring(0, 3)}***',
        );
        debugPrint('PuppeteerAuthService: Password length: ${password.length}');
      }

      final result = await _apiClient.credentialsLogin(username, password);

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'PuppeteerAuthService: Credentials login result: ${result.isSuccess}',
        );
        if (result.isFailure) {
          debugPrint(
            'PuppeteerAuthService: Failure reason: ${result.failureOrNull?.message}',
          );
        }
      }

      if (result.isSuccess) {
        // Expect token and user in payload
        final data = result.valueOrNull ?? const <String, dynamic>{};
        final token = data['token'] as String?;
        final userMap = data['user'] as Map<String, dynamic>?;

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('PuppeteerAuthService: Authentication successful');
          debugPrint('PuppeteerAuthService: Token exists: ${token != null}');
          debugPrint(
            'PuppeteerAuthService: Token length: ${token?.length ?? 0}',
          );
          debugPrint(
            'PuppeteerAuthService: User data exists: ${userMap != null}',
          );
          debugPrint(
            'PuppeteerAuthService: User data keys: ${userMap?.keys.toList() ?? []}',
          );
        }

        if (token == null || userMap == null) {
          pollStop.value = true;
          return const AuthResult.failure(
            type: AuthResultType.unknown,
            errorMessage: 'Invalid success payload: missing token/user',
          );
        }
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('PuppeteerAuthService: Storing proxy auth token...');
        }

        final store = await _secureStorage.storeProxyAuthToken(token);

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'PuppeteerAuthService: Token storage result: ${store.isSuccess}',
          );
          if (store.isFailure) {
            debugPrint(
              'PuppeteerAuthService: Token storage error: ${store.failureOrNull?.message}',
            );
          }
        }

        if (store.isFailure) {
          pollStop.value = true;
          if (kDebugMode) {
            debugPrint(
              'PuppeteerAuthService: Failed to store token: ${store.failureOrNull?.message}',
            );
            if (defaultTargetPlatform == TargetPlatform.macOS) {
              debugPrint('PuppeteerAuthService: macOS token storage failed');
            }
          }
          return AuthResult.failure(
            type: AuthResultType.unknown,
            errorMessage:
                'Failed to store token: ${store.failureOrNull?.message}',
          );
        }

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('PuppeteerAuthService: Storing user data...');
        }

        final userStore = await _secureStorage.storeUserData(userMap);

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'PuppeteerAuthService: User data storage result: ${userStore.isSuccess}',
          );
          if (userStore.isFailure) {
            debugPrint(
              'PuppeteerAuthService: User data storage error: ${userStore.failureOrNull?.message}',
            );
          }
        }

        if (userStore.isFailure) {
          if (kDebugMode) {
            debugPrint(
              'PuppeteerAuthService: Failed to store user data: ${userStore.failureOrNull?.message}',
            );
            if (defaultTargetPlatform == TargetPlatform.macOS) {
              debugPrint(
                'PuppeteerAuthService: macOS user data storage failed',
              );
            }
          }
          // ユーザーデータの保存失敗は致命的ではないので続行
        }
        final user = UserModel.fromCanvasJson(userMap).toEntity();
        pollStop.value = true;
        return AuthResult.success(user: user, token: token);
      } else {
        pollStop.value = true;
        final message =
            result.failureOrNull?.message ?? 'Credentials login failed';
        if (kDebugMode) {
          debugPrint(
            'PuppeteerAuthService: credentials login failed: $message',
          );
        }
        return AuthResult.failure(
          type: AuthResultType.unknown,
          errorMessage: message,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PuppeteerAuthService: credentials login exception: $e');
      }
      return AuthResult.failure(
        type: AuthResultType.unknown,
        errorMessage: 'Credentials login request failed: $e',
      );
    }
  }

  Future<AuthResult> checkProxyConnection() =>
      _apiClient.checkProxyConnection().then(
        (r) =>
            r.isSuccess
                ? const AuthResult.success(user: null, token: null)
                : AuthResult.failure(
                  type: AuthResultType.unknown,
                  errorMessage: r.failureOrNull?.message ?? 'Proxy unreachable',
                ),
      );

  /// Test API access with a simple request
  Future<AuthResult> testApiAccess() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('PuppeteerAuthService: Testing API access');
      }

      // macOS診断を実行
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        await _apiClient.diagnoseMacOSNetwork();
      }

      // 簡単なAPIテストリクエスト（ユーザー情報の取得）
      final response = await _apiClient.get('/users/self');

      if (response.isSuccess) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('PuppeteerAuthService: API test successful');
        }
        return const AuthResult.success(user: null, token: null);
      } else {
        final failure = response.failureOrNull;
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'PuppeteerAuthService: API test failed: ${failure?.message}',
          );
        }
        return AuthResult.failure(
          type: AuthResultType.apiValidationFailed,
          errorMessage: failure?.message ?? 'API access test failed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PuppeteerAuthService: API test exception: $e');
      }
      return AuthResult.failure(
        type: AuthResultType.apiValidationFailed,
        errorMessage: 'API access test failed: $e',
      );
    }
  }

  void dispose() {}
}
