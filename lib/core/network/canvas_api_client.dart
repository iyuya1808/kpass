import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/errors/failures.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/services/native_cookie_service.dart';
import 'package:kpass/core/services/secure_storage_service.dart';

/// Canvas LMS API Client
/// 
/// Based on Canvas API documentation:
/// https://canvas.instructure.com/doc/api/
class CanvasApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  CanvasApiClient({
    Dio? dio,
    SecureStorageService? secureStorage,
  })  : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? SecureStorageService() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = AppConstants.canvasApiUrl;
    _dio.options.connectTimeout = AppConstants.requestTimeout;
    _dio.options.receiveTimeout = AppConstants.requestTimeout;
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor(_secureStorage));
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorHandlerInterceptor());
  }

  /// Get user's courses
  /// 
  /// Endpoint: GET /api/v1/courses
  /// Params:
  ///   - enrollment_state: active (default)
  ///   - include[]: term, total_students, favorites
  ///   - per_page: 100 (max)
  Future<Result<List<Map<String, dynamic>>>> getCourses({
    String enrollmentState = 'active',
    List<String>? include,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'enrollment_state': enrollmentState,
        'per_page': perPage.toString(),
      };

      if (include != null && include.isNotEmpty) {
        queryParams['include[]'] = include;
      }

      final response = await _dio.get(
        AppConstants.coursesEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final courses = (response.data as List)
            .cast<Map<String, dynamic>>();

        if (kDebugMode) {
          debugPrint('CanvasApiClient: Retrieved ${courses.length} courses');
        }

        return Result.success(courses);
      } else {
        return Result.failure(
          CanvasFailure.apiError('Invalid response format'),
        );
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (error) {
      return Result.failure(
        CanvasFailure.apiError('Failed to fetch courses: $error'),
      );
    }
  }

  /// Get assignments for a specific course
  /// 
  /// Endpoint: GET /api/v1/courses/{course_id}/assignments
  Future<Result<List<Map<String, dynamic>>>> getCourseAssignments(
    int courseId, {
    List<String>? include,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage.toString(),
      };

      if (include != null && include.isNotEmpty) {
        queryParams['include[]'] = include;
      }

      final response = await _dio.get(
        '${AppConstants.coursesEndpoint}/$courseId${AppConstants.assignmentsEndpoint}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final assignments = (response.data as List)
            .cast<Map<String, dynamic>>();

        if (kDebugMode) {
          debugPrint('CanvasApiClient: Retrieved ${assignments.length} assignments for course $courseId');
        }

        return Result.success(assignments);
      } else {
        return Result.failure(
          CanvasFailure.apiError('Invalid response format'),
        );
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (error) {
      return Result.failure(
        CanvasFailure.apiError('Failed to fetch assignments: $error'),
      );
    }
  }

  /// Get all assignments for the current user
  /// 
  /// Endpoint: GET /api/v1/courses/{course_id}/assignments
  /// (called for each course)
  Future<Result<List<Map<String, dynamic>>>> getAllAssignments(
    List<int> courseIds, {
    List<String>? include,
  }) async {
    try {
      final allAssignments = <Map<String, dynamic>>[];

      for (final courseId in courseIds) {
        final result = await getCourseAssignments(
          courseId,
          include: include,
        );

        if (result.isSuccess) {
          allAssignments.addAll(result.valueOrNull!);
        } else {
          if (kDebugMode) {
            debugPrint('CanvasApiClient: Failed to fetch assignments for course $courseId');
          }
        }
      }

      return Result.success(allAssignments);
    } catch (error) {
      return Result.failure(
        CanvasFailure.apiError('Failed to fetch all assignments: $error'),
      );
    }
  }

  /// Get calendar events
  /// 
  /// Endpoint: GET /api/v1/calendar_events
  Future<Result<List<Map<String, dynamic>>>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? type,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage,
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type.join(',');
      }

      final response = await _dio.get(
        AppConstants.userCalendarEventsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final events = (response.data as List)
            .cast<Map<String, dynamic>>();

        if (kDebugMode) {
          debugPrint('CanvasApiClient: Retrieved ${events.length} calendar events');
        }

        return Result.success(events);
      } else {
        return Result.failure(
          CanvasFailure.apiError('Invalid response format'),
        );
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (error) {
      return Result.failure(
        CanvasFailure.apiError('Failed to fetch calendar events: $error'),
      );
    }
  }

  Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure.timeout();

      case DioExceptionType.connectionError:
        return NetworkFailure.noConnection();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return AuthFailure.invalidToken();
        } else if (statusCode == 403) {
          return AuthFailure.insufficientPermissions();
        } else if (statusCode == 404) {
          return CanvasFailure.apiError('Resource not found', 'NOT_FOUND');
        } else if (statusCode == 429) {
          return CanvasFailure.quotaExceeded();
        } else {
          return NetworkFailure.serverError(
            statusCode ?? 500,
            error.response?.statusMessage ?? 'Server error',
          );
        }

      case DioExceptionType.cancel:
        return const GeneralFailure(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      default:
        return GeneralFailure.unknown(error.message ?? 'Unknown error');
    }
  }
}

/// Authentication interceptor to add session cookie to requests
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  _AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Prefer native cookie store (HttpOnly含む) + 保存済みCookieを多段マージ
      String? cookie;
      final mergeMap = <String, String>{};

      // 1) 保存済みCookie
      final stored = await _secureStorage.getSessionCookie();
      if (stored.isSuccess && stored.valueOrNull != null && stored.valueOrNull!.isNotEmpty) {
        for (final part in stored.valueOrNull!.split(';')) {
          final idx = part.indexOf('=');
          if (idx > 0) {
            final k = part.substring(0, idx).trim();
            final v = part.substring(idx + 1).trim();
            if (k.isNotEmpty) mergeMap[k] = v;
          }
        }
      }

      // 2) ネイティブCookie（URLバリエーションで収集）
      final urls = <String>[
        AppConstants.canvasBaseUrl,
        '${AppConstants.canvasBaseUrl}/',
        '${AppConstants.canvasBaseUrl}${AppConstants.userSelfEndpoint}',
        '${AppConstants.canvasBaseUrl}/courses',
      ];
      for (final u in urls) {
        try {
          final native = await NativeCookieService.getCookiesForUrl(u);
          if (native != null && native.isNotEmpty) {
            for (final part in native.split(';')) {
              final idx = part.indexOf('=');
              if (idx > 0) {
                final k = part.substring(0, idx).trim();
                final v = part.substring(idx + 1).trim();
                if (k.isNotEmpty) mergeMap[k] = v; // 後勝ち（より具体的なURLの値を優先）
              }
            }
          }
        } catch (_) {}
      }

      // 重要Cookieがあるか簡易チェック（存在しなくても送るが、ログで可視化）
      final essentialKeys = ['_normandy_session', '_legacy_normandy_session', 'log_session_id', '_csrf_token'];
      cookie = mergeMap.entries.map((e) => '${e.key}=${e.value}').join('; ');

      if (cookie.isNotEmpty) {
        options.headers['Cookie'] = cookie;
        if (kDebugMode) {
          debugPrint('AuthInterceptor: Added session cookie to request');
          debugPrint('AuthInterceptor: Cookie header: $cookie');
          final missing = essentialKeys.where((k) => !mergeMap.containsKey(k)).toList();
          if (missing.isNotEmpty) {
            debugPrint('AuthInterceptor: Missing possible essential cookies: $missing');
          }
        }
      } else {
        // Fallback to token-based auth for backward compatibility
        final tokenResult = await _secureStorage.getAccessToken();
        if (tokenResult.isSuccess && tokenResult.valueOrNull != null && tokenResult.valueOrNull!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${tokenResult.valueOrNull}';
          if (kDebugMode) {
            debugPrint('AuthInterceptor: Added Bearer token to request (fallback)');
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AuthInterceptor: Failed to add authentication: $error');
      }
    }

    handler.next(options);
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
      debugPrint('  Headers: ${options.headers}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('  Query: ${options.queryParameters}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ ${err.requestOptions.method} ${err.requestOptions.uri}');
      debugPrint('  Error: ${err.message}');
      if (err.response != null) {
        debugPrint('  Status: ${err.response?.statusCode}');
      }
    }
    handler.next(err);
  }
}

/// Error handler interceptor
class _ErrorHandlerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Add custom error handling here if needed
    handler.next(err);
  }
}

