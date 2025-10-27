import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/secure_storage_service.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/errors/failures.dart';

/// HTTP client for Proxy API Server
/// Handles authentication and data fetching through the proxy
class ProxyApiClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  // Proxy API configuration
  // Development: 'http://10.41.228.219:3000/api'
  // Production (VPS): 'http://85.131.245.64:3000/api'
  // Local testing: 'http://localhost:3000/api'
  static const String _baseUrl = 'http://85.131.245.64:3000/api';

  // Request timeout configurations
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);
  static const Duration _sendTimeout = Duration(seconds: 10);

  // Retry configuration - より保守的な設定
  static const int _maxRetries = 2; // 3回から2回に削減
  static const Duration _retryDelay = Duration(seconds: 2); // 1秒から2秒に増加

  ProxyApiClient({SecureStorageService? secureStorage, Dio? dio})
    : _secureStorage = secureStorage ?? SecureStorageService() {
    _dio = dio ?? Dio();
    _setupDioConfiguration();
    _setupInterceptors();
  }

  /// Configure Dio with base settings
  void _setupDioConfiguration() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status != null &&
            (status < 400 || status == 401 || status == 403 || status == 429);
      },
    );
  }

  /// Setup interceptors for authentication, logging, and error handling
  void _setupInterceptors() {
    // Authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthenticationHeader(options);
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            if (kDebugMode) {
              debugPrint('ProxyApiClient: Received 401, token may be invalid');
            }
          }
          handler.next(error);
        },
      ),
    );

    // Logging interceptor: enable only when verbose logging is on
    if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) {
            debugPrint('ProxyApiClient: $object');
          },
        ),
      );
    }

    // Retry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            final retryResult = await _retryRequest(error.requestOptions);
            if (retryResult != null) {
              handler.resolve(retryResult);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Add authentication header to request
  Future<void> _addAuthenticationHeader(RequestOptions options) async {
    try {
      final tokenResult = await _secureStorage.getProxyAuthToken();
      if (tokenResult.isSuccess &&
          tokenResult.valueOrNull != null &&
          tokenResult.valueOrNull!.isNotEmpty) {
        final token = tokenResult.valueOrNull!;
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
          debugPrint('ProxyApiClient: Added bearer token header');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ProxyApiClient: Failed to add auth header: $error');
      }
    }
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        // より厳格なリトライ条件：429（レート制限）と5xxエラーのみ
        // 401、403、404などのクライアントエラーはリトライしない
        return statusCode != null && (statusCode == 429 || statusCode >= 500);
      default:
        return false;
    }
  }

  /// Retry failed request with exponential backoff
  Future<Response?> _retryRequest(RequestOptions options) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ProxyApiClient: Retry attempt $attempt for ${options.path}',
          );
        }

        // Use exponential backoff: 2s, 4s
        final delay = _retryDelay * (1 << (attempt - 1));
        await Future.delayed(delay);

        final retryOptions = RequestOptions(
          path: options.path,
          method: options.method,
          data: options.data,
          queryParameters: options.queryParameters,
          headers: options.headers,
          baseUrl: options.baseUrl,
          connectTimeout: options.connectTimeout,
          receiveTimeout: options.receiveTimeout,
          sendTimeout: options.sendTimeout,
        );

        return await _dio.fetch(retryOptions);
      } catch (error) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('ProxyApiClient: Retry attempt $attempt failed: $error');
        }

        if (attempt == _maxRetries) {
          break;
        }
      }
    }

    return null;
  }

  /// Start external browser login process
  Future<Result<Map<String, dynamic>>> startExternalBrowserLogin(
    String username,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Starting external browser login for user: ${username.substring(0, 3)}***',
        );
      }

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint(
          'ProxyApiClient: Making POST request to /auth/start-external-browser-login',
        );
      }

      final response = await _dio.post(
        '/auth/start-external-browser-login',
        data: {'username': username},
      );

      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ProxyApiClient: Received response: ${response.statusCode}');
      }

      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Start external browser login error: $error',
        );
      }
      return Result.failure(
        GeneralFailure.unknown(
          'Start external browser login request failed: $error',
        ),
      );
    }
  }

  /// Check external browser login status
  Future<Result<Map<String, dynamic>>> checkExternalBrowserLoginStatus(
    String sessionId,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Checking external browser login status for sessionId: $sessionId',
        );
      }

      final response = await _dio.get('/auth/check-login-status/$sessionId');

      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Check external browser login status error: $error',
        );
      }
      return Result.failure(
        GeneralFailure.unknown(
          'Check external browser login status request failed: $error',
        ),
      );
    }
  }

  /// Complete external browser login process
  Future<Result<Map<String, dynamic>>> completeExternalBrowserLogin(
    String sessionId,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Completing external browser login for sessionId: $sessionId',
        );
      }

      final response = await _dio.post(
        '/auth/complete-external-browser-login',
        data: {'sessionId': sessionId},
      );

      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Complete external browser login error: $error',
        );
      }
      return Result.failure(
        GeneralFailure.unknown(
          'Complete external browser login request failed: $error',
        ),
      );
    }
  }

  /// Start manual login process (legacy)
  Future<Result<Map<String, dynamic>>> startManualLogin(String username) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Starting manual login for user: ${username.substring(0, 3)}***',
        );
      }

      final response = await _dio.post(
        '/start-manual-login',
        data: {'username': username},
      );

      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Start manual login error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Start manual login request failed: $error'),
      );
    }
  }

  /// Complete manual login process (legacy)
  Future<Result<Map<String, dynamic>>> completeManualLogin(
    String userId,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Completing manual login for userId: $userId',
        );
      }

      final response = await _dio.post(
        '/complete-manual-login',
        data: {'userId': userId},
      );

      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Complete manual login error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Complete manual login request failed: $error'),
      );
    }
  }

  /// Legacy login method - redirects to manual login
  Future<Result<Map<String, dynamic>>> login(
    String username,
    String password,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Legacy login attempt for user: ${username.substring(0, 3)}***',
        );
      }

      final response = await _dio.post(
        '/login',
        data: {'username': username, 'password': password},
      );

      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Login error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Login request failed: $error'),
      );
    }
  }

  /// Logout
  Future<Result<void>> logout() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Logout');
      }

      await _dio.post('/logout');
      return const Result.success(null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Logout error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Logout request failed: $error'),
      );
    }
  }

  /// Validate session
  Future<Result<Map<String, dynamic>>> validateSession() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Validating session');
      }

      final response = await _dio.get('/validate');
      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Validate session error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Session validation failed: $error'),
      );
    }
  }

  /// Get current user
  Future<Result<Map<String, dynamic>>> getCurrentUser() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Getting current user');
      }

      final response = await _dio.get('/user');
      return _handleResponse<Map<String, dynamic>>(response, null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Get current user error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Get user request failed: $error'),
      );
    }
  }

  /// Perform GET request
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ProxyApiClient: GET $path');
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: GET error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('GET request failed: $error'),
      );
    }
  }

  /// Perform POST request
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ProxyApiClient: POST $path');
      }

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: POST error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('POST request failed: $error'),
      );
    }
  }

  /// Perform PUT request
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ProxyApiClient: PUT $path');
      }

      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: PUT error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('PUT request failed: $error'),
      );
    }
  }

  /// Perform DELETE request
  Future<Result<void>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableVerboseLogging) {
        debugPrint('ProxyApiClient: DELETE $path');
      }

      await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return const Result.success(null);
    } on DioException catch (dioError) {
      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: DELETE error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('DELETE request failed: $error'),
      );
    }
  }

  /// Handle API response and convert to Result
  Result<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      if (response.statusCode == 401) {
        return Result.failure(AuthFailure.invalidToken());
      }

      if (response.statusCode == 403) {
        return Result.failure(AuthFailure.insufficientPermissions());
      }

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        return Result.failure(
          NetworkFailure.serverError(
            response.statusCode!,
            'Server returned status ${response.statusCode}',
          ),
        );
      }

      // Handle Proxy API response format
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        if (responseData['success'] == false) {
          return Result.failure(
            GeneralFailure.unknown(responseData['error'] ?? 'Unknown error'),
          );
        }

        // Extract data from success response
        final data = responseData['data'] ?? responseData;

        if (fromJson != null) {
          if (data is Map<String, dynamic>) {
            final result = fromJson(data);
            return Result.success(result);
          } else if (data is List) {
            final result = fromJson({'items': data});
            return Result.success(result);
          }
        } else {
          return Result.success(data as T);
        }
      }

      return Result.success(responseData as T);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Response handling error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Failed to process response: $error'),
      );
    }
  }

  /// Map Dio errors to application failures
  Failure _mapDioError(DioException dioError) {
    if (kDebugMode && EnvironmentConfig.enableLogging) {
      debugPrint(
        'ProxyApiClient: DioException: ${dioError.type} - ${dioError.message}',
      );
    }

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure.timeout();

      case DioExceptionType.connectionError:
        return NetworkFailure.noConnection();

      case DioExceptionType.badResponse:
        final statusCode = dioError.response?.statusCode ?? 0;
        final message = dioError.response?.statusMessage ?? 'Unknown error';

        if (statusCode == 401) {
          return AuthFailure.invalidToken();
        } else if (statusCode == 403) {
          return AuthFailure.insufficientPermissions();
        } else if (statusCode == 429) {
          // Handle rate limiting
          final retryAfter = dioError.response?.headers.value('retry-after');
          final retryMessage =
              retryAfter != null
                  ? 'Too many requests. Please try again in $retryAfter seconds.'
                  : 'Too many requests. Please try again later.';
          return NetworkFailure.clientError(statusCode, retryMessage);
        } else if (statusCode >= 400 && statusCode < 500) {
          return NetworkFailure.clientError(statusCode, message);
        } else if (statusCode >= 500) {
          return NetworkFailure.serverError(statusCode, message);
        } else {
          return NetworkFailure.serverError(statusCode, message);
        }

      case DioExceptionType.cancel:
        return GeneralFailure.unknown('Request was cancelled');

      case DioExceptionType.badCertificate:
        return NetworkFailure.sslError();

      case DioExceptionType.unknown:
        return GeneralFailure.unknown(
          dioError.message ?? 'Unknown network error occurred',
        );
    }
  }

  /// Check if client has valid authentication
  Future<bool> isAuthenticated() async {
    try {
      final tokenResult = await _secureStorage.getProxyAuthToken();
      return tokenResult.isSuccess &&
          tokenResult.valueOrNull != null &&
          tokenResult.valueOrNull!.isNotEmpty;
    } catch (error) {
      return false;
    }
  }

  /// Check if proxy server is reachable
  Future<Result<bool>> checkProxyConnection() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Checking proxy server connection');
      }

      // Use a simple health check endpoint or ping
      final response = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint('ProxyApiClient: Proxy server is reachable');
        }
        return const Result.success(true);
      } else {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ProxyApiClient: Proxy server returned status: ${response.statusCode}',
          );
        }
        return const Result.success(false);
      }
    } on DioException catch (dioError) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'ProxyApiClient: Proxy connection check failed: ${dioError.message}',
        );
      }

      // Check if it's a connection error
      if (dioError.type == DioExceptionType.connectionError ||
          dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout) {
        return Result.failure(NetworkFailure.noConnection());
      }

      return Result.failure(_mapDioError(dioError));
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Proxy connection check error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Proxy connection check failed: $error'),
      );
    }
  }

  /// Download file as bytes
  Future<List<int>> downloadFile(String path) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Downloading file from $path');
      }

      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'ProxyApiClient: File downloaded, size=${response.data!.length}',
          );
        }
        return response.data!;
      }

      throw Exception('Failed to download file: status ${response.statusCode}');
    } on DioException catch (dioError) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Download error: ${dioError.message}');
      }
      throw Exception('Download failed: ${dioError.message}');
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('ProxyApiClient: Download error: $error');
      }
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
}
