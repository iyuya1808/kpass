import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kpass/core/errors/failures.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/constants/app_constants.dart';

/// Service for secure storage operations using flutter_secure_storage
/// Handles encryption and decryption of sensitive data like access tokens
class SecureStorageService {
  // In-memory fallback for iOS Simulator keychain issues
  static final Map<String, String> _memoryStorage = {};

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'kpass_secure_prefs',
      preferencesKeyPrefix: 'kpass_',
    ),
    iOptions: IOSOptions(
      accountName: 'KPass',
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Store session cookie securely
  Future<Result<void>> storeSessionCookie(String cookie) async {
    try {
      if (cookie.isEmpty) {
        return Result.failure(
          const ValidationFailure(
            message: 'Session cookie cannot be empty',
            code: 'EMPTY_COOKIE',
          ),
        );
      }

      await _storage.write(key: AppConstants.sessionCookieKey, value: cookie);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Session cookie stored successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to store session cookie: $error',
        );
      }

      // iOS Simulator keychain error (-34018) - use in-memory storage as fallback
      if (error.toString().contains('-34018')) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'SecureStorageService: Using in-memory storage for iOS Simulator',
          );
        }
        _memoryStorage[AppConstants.sessionCookieKey] = cookie;
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.writeError('Failed to store session cookie: $error'),
      );
    }
  }

  /// Retrieve session cookie from secure storage
  Future<Result<String?>> getSessionCookie() async {
    try {
      final cookie = await _storage.read(key: AppConstants.sessionCookieKey);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'SecureStorageService: Session cookie retrieved ${cookie != null ? 'successfully' : '(not found)'}',
        );
      }

      return Result.success(cookie);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to retrieve session cookie: $error',
        );
      }

      // iOS Simulator keychain error (-34018) - check in-memory storage
      if (error.toString().contains('-34018')) {
        final memoryCookie = _memoryStorage[AppConstants.sessionCookieKey];
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'SecureStorageService: Retrieved from in-memory storage ${memoryCookie != null ? 'successfully' : '(not found)'}',
          );
        }
        return Result.success(memoryCookie);
      }

      return Result.failure(
        StorageFailure.readError('Failed to retrieve session cookie: $error'),
      );
    }
  }

  /// Delete session cookie from secure storage
  Future<Result<void>> deleteSessionCookie() async {
    try {
      await _storage.delete(key: AppConstants.sessionCookieKey);
      _memoryStorage.remove(AppConstants.sessionCookieKey);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Session cookie deleted successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to delete session cookie: $error',
        );
      }

      // iOS Simulator - remove from memory storage anyway
      if (error.toString().contains('-34018')) {
        _memoryStorage.remove(AppConstants.sessionCookieKey);
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to delete session cookie: $error'),
      );
    }
  }

  /// Store access token securely (deprecated - use storeSessionCookie instead)
  @Deprecated('Use storeSessionCookie for session-based authentication')
  Future<Result<void>> storeAccessToken(String token) async {
    try {
      if (token.isEmpty) {
        return Result.failure(
          const ValidationFailure(
            message: 'Access token cannot be empty',
            code: 'EMPTY_TOKEN',
          ),
        );
      }

      if (!_isValidTokenFormat(token)) {
        return Result.failure(ValidationFailure.invalidToken());
      }

      await _storage.write(key: AppConstants.accessTokenKey, value: token);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Access token stored successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to store access token: $error',
        );
      }

      // iOS Simulator keychain error (-34018) - use in-memory storage as fallback
      if (error.toString().contains('-34018')) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'SecureStorageService: Using in-memory storage for iOS Simulator',
          );
        }
        _memoryStorage[AppConstants.accessTokenKey] = token;
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.writeError('Failed to store access token: $error'),
      );
    }
  }

  /// Retrieve access token from secure storage
  Future<Result<String?>> getAccessToken() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'SecureStorageService: Access token retrieved ${token != null ? 'successfully' : '(not found)'}',
        );
      }

      return Result.success(token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to retrieve access token: $error',
        );
      }

      // iOS Simulator keychain error (-34018) - check in-memory storage
      if (error.toString().contains('-34018')) {
        final memoryToken = _memoryStorage[AppConstants.accessTokenKey];
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'SecureStorageService: Retrieved from in-memory storage ${memoryToken != null ? 'successfully' : '(not found)'}',
          );
        }
        return Result.success(memoryToken);
      }

      return Result.failure(
        StorageFailure.readError('Failed to retrieve access token: $error'),
      );
    }
  }

  /// Store user data securely
  Future<Result<void>> storeUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);

      await _storage.write(key: AppConstants.userDataKey, value: jsonString);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: User data stored successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to store user data: $error');
      }

      // iOS Simulator keychain error - use in-memory storage
      if (error.toString().contains('-34018')) {
        _memoryStorage[AppConstants.userDataKey] = jsonEncode(userData);
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.writeError('Failed to store user data: $error'),
      );
    }
  }

  /// Retrieve user data from secure storage
  Future<Result<Map<String, dynamic>?>> getUserData() async {
    try {
      final jsonString = await _storage.read(key: AppConstants.userDataKey);

      if (jsonString == null) {
        return const Result.success(null);
      }

      final userData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: User data retrieved successfully');
      }

      return Result.success(userData);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to retrieve user data: $error',
        );
      }

      // iOS Simulator keychain error - check in-memory storage
      if (error.toString().contains('-34018')) {
        final memoryData = _memoryStorage[AppConstants.userDataKey];
        if (memoryData != null) {
          final userData = jsonDecode(memoryData) as Map<String, dynamic>;
          return Result.success(userData);
        }
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.readError('Failed to retrieve user data: $error'),
      );
    }
  }

  /// Delete access token from secure storage
  Future<Result<void>> deleteAccessToken() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      _memoryStorage.remove(AppConstants.accessTokenKey);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Access token deleted successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to delete access token: $error',
        );
      }

      // iOS Simulator - remove from memory storage anyway
      if (error.toString().contains('-34018')) {
        _memoryStorage.remove(AppConstants.accessTokenKey);
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to delete access token: $error'),
      );
    }
  }

  /// Delete user data from secure storage
  Future<Result<void>> deleteUserData() async {
    try {
      await _storage.delete(key: AppConstants.userDataKey);
      _memoryStorage.remove(AppConstants.userDataKey);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: User data deleted successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to delete user data: $error');
      }

      // iOS Simulator - remove from memory storage anyway
      if (error.toString().contains('-34018')) {
        _memoryStorage.remove(AppConstants.userDataKey);
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to delete user data: $error'),
      );
    }
  }

  /// Store app settings securely
  Future<Result<void>> storeSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);

      await _storage.write(key: AppConstants.settingsKey, value: jsonString);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Settings stored successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to store settings: $error');
      }

      return Result.failure(
        StorageFailure.writeError('Failed to store settings: $error'),
      );
    }
  }

  /// Retrieve app settings from secure storage
  Future<Result<Map<String, dynamic>?>> getSettings() async {
    try {
      final jsonString = await _storage.read(key: AppConstants.settingsKey);

      if (jsonString == null) {
        return const Result.success(null);
      }

      final settings = jsonDecode(jsonString) as Map<String, dynamic>;

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Settings retrieved successfully');
      }

      return Result.success(settings);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to retrieve settings: $error');
      }

      return Result.failure(
        StorageFailure.readError('Failed to retrieve settings: $error'),
      );
    }
  }

  /// Store cached data with expiration
  Future<Result<void>> storeCachedData(
    String key,
    Map<String, dynamic> data, {
    Duration? expiration,
  }) async {
    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiration': expiration?.inMilliseconds,
      };

      final jsonString = jsonEncode(cacheEntry);

      await _storage.write(key: 'cache_$key', value: jsonString);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Cached data stored for key: $key');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to store cached data: $error');
      }

      return Result.failure(
        StorageFailure.writeError('Failed to store cached data: $error'),
      );
    }
  }

  /// Retrieve cached data with expiration check
  Future<Result<Map<String, dynamic>?>> getCachedData(String key) async {
    try {
      final jsonString = await _storage.read(key: 'cache_$key');

      if (jsonString == null) {
        return const Result.success(null);
      }

      final cacheEntry = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      final expirationMs = cacheEntry['expiration'] as int?;

      // Check if cache has expired
      if (expirationMs != null) {
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp + expirationMs,
        );

        if (DateTime.now().isAfter(expirationTime)) {
          // Cache expired, delete it
          await _storage.delete(key: 'cache_$key');

          if (kDebugMode && EnvironmentConfig.enableLogging) {
            debugPrint(
              'SecureStorageService: Cached data expired for key: $key',
            );
          }

          return Result.failure(CacheFailure.expired(key));
        }
      }

      final data = cacheEntry['data'] as Map<String, dynamic>;

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Cached data retrieved for key: $key');
      }

      return Result.success(data);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to retrieve cached data: $error',
        );
      }

      return Result.failure(
        StorageFailure.readError('Failed to retrieve cached data: $error'),
      );
    }
  }

  /// Delete specific cached data
  Future<Result<void>> deleteCachedData(String key) async {
    try {
      await _storage.delete(key: 'cache_$key');

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: Cached data deleted for key: $key');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to delete cached data: $error',
        );
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to delete cached data: $error'),
      );
    }
  }

  /// Clear all stored data (logout cleanup)
  Future<Result<void>> clearAll() async {
    try {
      await _storage.deleteAll();
      _memoryStorage.clear();

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('SecureStorageService: All data cleared successfully');
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to clear all data: $error');
      }

      // iOS Simulator - clear memory storage anyway
      if (error.toString().contains('-34018')) {
        _memoryStorage.clear();
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to clear all data: $error'),
      );
    }
  }

  /// Check if access token exists
  Future<Result<bool>> hasAccessToken() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      return Result.success(token != null && token.isNotEmpty);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'SecureStorageService: Failed to check access token: $error',
        );
      }

      return Result.failure(
        StorageFailure.readError('Failed to check access token: $error'),
      );
    }
  }

  /// Validate token format
  bool _isValidTokenFormat(String token) {
    // Canvas tokens are typically 64-128 characters long and contain alphanumeric characters and ~
    if (token.length < AppConstants.minTokenLength ||
        token.length > AppConstants.maxTokenLength) {
      return false;
    }

    // Check if token matches expected pattern
    final tokenRegex = RegExp(AppConstants.tokenPattern);
    return tokenRegex.hasMatch(token);
  }

  /// Get storage info for debugging
  Future<Result<Map<String, dynamic>>> getStorageInfo() async {
    try {
      final allKeys = await _storage.readAll();

      final info = {
        'totalKeys': allKeys.length,
        'hasAccessToken': allKeys.containsKey(AppConstants.accessTokenKey),
        'hasUserData': allKeys.containsKey(AppConstants.userDataKey),
        'hasSettings': allKeys.containsKey(AppConstants.settingsKey),
        'cacheKeys':
            allKeys.keys
                .where((key) => key.startsWith('cache_'))
                .map((key) => key.substring(6))
                .toList(),
      };

      return Result.success(info);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('SecureStorageService: Failed to get storage info: $error');
      }

      return Result.failure(
        StorageFailure.readError('Failed to get storage info: $error'),
      );
    }
  }

  /// Store proxy auth token securely
  Future<Result<void>> storeProxyAuthToken(String token) async {
    try {
      if (token.isEmpty) {
        return Result.failure(
          const ValidationFailure(
            message: 'Proxy auth token cannot be empty',
            code: 'EMPTY_TOKEN',
          ),
        );
      }

      await _storage.write(key: 'proxy_auth_token', value: token);

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'SecureStorageService: Proxy auth token stored successfully',
        );
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to store proxy auth token: $error',
        );
      }

      if (error.toString().contains('-34018')) {
        _memoryStorage['proxy_auth_token'] = token;
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.writeError('Failed to store proxy auth token: $error'),
      );
    }
  }

  /// Retrieve proxy auth token from secure storage
  Future<Result<String?>> getProxyAuthToken() async {
    try {
      final token = await _storage.read(key: 'proxy_auth_token');

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'SecureStorageService: Proxy auth token retrieved ${token != null ? 'successfully' : '(not found)'}',
        );
      }

      return Result.success(token);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to retrieve proxy auth token: $error',
        );
      }

      if (error.toString().contains('-34018')) {
        final memoryToken = _memoryStorage['proxy_auth_token'];
        return Result.success(memoryToken);
      }

      return Result.failure(
        StorageFailure.readError('Failed to retrieve proxy auth token: $error'),
      );
    }
  }

  /// Delete proxy auth token from secure storage
  Future<Result<void>> deleteProxyAuthToken() async {
    try {
      await _storage.delete(key: 'proxy_auth_token');
      _memoryStorage.remove('proxy_auth_token');

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'SecureStorageService: Proxy auth token deleted successfully',
        );
      }

      return const Result.success(null);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'SecureStorageService: Failed to delete proxy auth token: $error',
        );
      }

      if (error.toString().contains('-34018')) {
        _memoryStorage.remove('proxy_auth_token');
        return const Result.success(null);
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to delete proxy auth token: $error'),
      );
    }
  }

  /// Clean expired cache entries
  Future<Result<int>> cleanExpiredCache() async {
    try {
      final allKeys = await _storage.readAll();
      final cacheKeys = allKeys.keys.where((key) => key.startsWith('cache_'));
      int deletedCount = 0;

      for (final key in cacheKeys) {
        final jsonString = allKeys[key];
        if (jsonString == null) continue;

        try {
          final cacheEntry = jsonDecode(jsonString) as Map<String, dynamic>;
          final timestamp = cacheEntry['timestamp'] as int;
          final expirationMs = cacheEntry['expiration'] as int?;

          if (expirationMs != null) {
            final expirationTime = DateTime.fromMillisecondsSinceEpoch(
              timestamp + expirationMs,
            );

            if (DateTime.now().isAfter(expirationTime)) {
              await _storage.delete(key: key);
              deletedCount++;
            }
          }
        } catch (e) {
          // Invalid cache entry, delete it
          await _storage.delete(key: key);
          deletedCount++;
        }
      }

      if (kDebugMode) {
        debugPrint(
          'SecureStorageService: Cleaned $deletedCount expired cache entries',
        );
      }

      return Result.success(deletedCount);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'SecureStorageService: Failed to clean expired cache: $error',
        );
      }

      return Result.failure(
        StorageFailure.deleteError('Failed to clean expired cache: $error'),
      );
    }
  }
}
