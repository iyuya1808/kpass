import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/proxy_api_client.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/errors/failures.dart';
import 'package:dio/dio.dart';

/// HTTP client for Canvas LMS API via Proxy Server
/// All requests are routed through the Proxy API server
class CanvasApiClient {
  late final ProxyApiClient _proxyClient;

  CanvasApiClient({ProxyApiClient? proxyClient}) {
    _proxyClient = proxyClient ?? ProxyApiClient();
  }

  /// Perform GET request via Proxy API
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: GET $path via Proxy');
      }

      // Call proxy API
      return await _proxyClient.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        fromJson: fromJson,
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: GET error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('GET request failed: $error'),
      );
    }
  }

  /// Get paginated results from Canvas API via Proxy
  Future<Result<PaginatedResponse<T>>> getPaginated<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(Map<String, dynamic>) fromJson,
    int? perPage,
    String? page,
  }) async {
    try {
      final params = Map<String, dynamic>.from(queryParameters ?? {});

      if (perPage != null) {
        params['per_page'] = perPage;
      }
      if (page != null) {
        params['page'] = page;
      }

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: GET paginated $path via Proxy');
      }

      final result = await _proxyClient.get<dynamic>(
        path,
        queryParameters: params,
        options: options,
      );

      if (result.isFailure) {
        return Result.failure(result.failureOrNull!);
      }

      // Extract data from proxy response
      final data = result.valueOrNull;

      if (data is! List) {
        return Result.failure(
          GeneralFailure.unknown('Expected list response for paginated data'),
        );
      }

      // Convert list items
      final items =
          data
              .cast<Map<String, dynamic>>()
              .map((item) => fromJson(item))
              .toList();

      final paginatedResponse = PaginatedResponse<T>(
        items: items,
        currentPage: page,
        nextPage: null,
        prevPage: null,
        firstPage: null,
        lastPage: null,
        totalCount: null,
      );

      return Result.success(paginatedResponse);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Paginated GET error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Paginated request failed: $error'),
      );
    }
  }

  /// Check if client has valid authentication
  Future<bool> isAuthenticated() async {
    return await _proxyClient.isAuthenticated();
  }

  /// Test API connection and authentication
  Future<Result<Map<String, dynamic>>> testConnection() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Testing connection via Proxy');
      }

      final result = await _proxyClient.get<Map<String, dynamic>>(
        '/users/self',
      );

      if (result.isSuccess) {
        return Result.success({
          'status': 'connected',
          'user': result.valueOrNull,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return Result.failure(result.failureOrNull!);
    } catch (error) {
      return Result.failure(
        GeneralFailure.unknown('Connection test failed: $error'),
      );
    }
  }

  /// Get all courses for the authenticated user
  Future<List<dynamic>> getCourses({
    String? enrollmentState,
    List<String>? include,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Getting courses via Proxy');
      }

      final query = <String, dynamic>{};
      if (enrollmentState != null) {
        query['enrollment_state'] = enrollmentState;
      }
      if (include != null && include.isNotEmpty) {
        query['include[]'] = include;
      }
      // すべてのコースを取得するため、per_pageを大きく設定
      query['per_page'] = 200;

      final result = await _proxyClient.get<dynamic>(
        '/courses',
        queryParameters: query,
      );

      if (result.isSuccess && result.valueOrNull is List) {
        return result.valueOrNull as List<dynamic>;
      }

      throw Exception(
        'Failed to get courses: ${result.failureOrNull?.message}',
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get courses error: $error');
      }
      rethrow;
    }
  }

  /// Get assignments for a specific course
  Future<List<dynamic>> getAssignments(
    int courseId, {
    List<String>? include,
    int? perPage,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Getting assignments for course $courseId via Proxy',
        );
      }

      final query = <String, dynamic>{};
      if (include != null && include.isNotEmpty) {
        query['include[]'] = include;
      }
      query['order_by'] = 'due_at';
      query['per_page'] = perPage ?? 500; // 取得数を大幅に増やして期限が近い課題を確実に取得
      query['sort'] = 'due_at'; // 期限日順でソート

      final result = await _proxyClient.get<dynamic>(
        '/courses/$courseId/assignments',
        queryParameters: query,
      );

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        final ok = result.isSuccess;
        final typeName = result.valueOrNull.runtimeType.toString();
        final count =
            (result.valueOrNull is List)
                ? (result.valueOrNull as List).length
                : -1;
        debugPrint(
          'CanvasApiClient.getAssignments($courseId): success=$ok, type=$typeName, count=$count',
        );
        if (!ok) {
          debugPrint(
            'CanvasApiClient.getAssignments($courseId): failure=${result.failureOrNull?.message}',
          );
        }
      }

      if (result.isSuccess && result.valueOrNull is List) {
        return result.valueOrNull as List<dynamic>;
      }

      throw Exception(
        'Failed to get assignments: ${result.failureOrNull?.message}',
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get assignments error: $error');
      }
      rethrow;
    }
  }

  /// Get modules for a specific course
  Future<List<dynamic>> getModules(
    int courseId, {
    List<String>? include,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Getting modules for course $courseId via Proxy',
        );
      }

      final query = <String, dynamic>{};
      if (include != null && include.isNotEmpty) {
        query['include[]'] = include;
      }
      query['per_page'] = 100;

      final result = await _proxyClient.get<dynamic>(
        '/courses/$courseId/modules',
        queryParameters: query,
      );

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        final ok = result.isSuccess;
        final typeName = result.valueOrNull.runtimeType.toString();
        final count =
            (result.valueOrNull is List)
                ? (result.valueOrNull as List).length
                : -1;
        debugPrint(
          'CanvasApiClient.getModules($courseId): success=$ok, type=$typeName, count=$count',
        );
        if (!ok) {
          debugPrint(
            'CanvasApiClient.getModules($courseId): failure=${result.failureOrNull?.message}',
          );
        }
      }

      if (result.isSuccess && result.valueOrNull is List) {
        return result.valueOrNull as List<dynamic>;
      }

      throw Exception(
        'Failed to get modules: ${result.failureOrNull?.message}',
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get modules error: $error');
      }
      rethrow;
    }
  }

  /// Get page content for a specific course
  Future<Map<String, dynamic>> getPage(int courseId, String pageUrl) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Getting page $pageUrl for course $courseId via Proxy',
        );
      }

      final result = await _proxyClient.get<dynamic>(
        '/courses/$courseId/pages/$pageUrl',
      );

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        final ok = result.isSuccess;
        final typeName = result.valueOrNull.runtimeType.toString();
        debugPrint(
          'CanvasApiClient.getPage($courseId, $pageUrl): success=$ok, type=$typeName',
        );
        if (!ok) {
          debugPrint(
            'CanvasApiClient.getPage($courseId, $pageUrl): failure=${result.failureOrNull?.message}',
          );
        }
      }

      if (result.isSuccess && result.valueOrNull is Map) {
        return result.valueOrNull as Map<String, dynamic>;
      }

      throw Exception('Failed to get page: ${result.failureOrNull?.message}');
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get page error: $error');
      }
      rethrow;
    }
  }

  /// Get file information for a specific course
  Future<Map<String, dynamic>> getFile(int courseId, int fileId) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Getting file $fileId for course $courseId via Proxy',
        );
      }

      final result = await _proxyClient.get<dynamic>(
        '/courses/$courseId/files/$fileId',
      );

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        final ok = result.isSuccess;
        debugPrint('CanvasApiClient.getFile($courseId, $fileId): success=$ok');
      }

      if (result.isSuccess && result.valueOrNull is Map) {
        return result.valueOrNull as Map<String, dynamic>;
      }

      throw Exception('Failed to get file: ${result.failureOrNull?.message}');
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get file error: $error');
      }
      rethrow;
    }
  }

  /// Download file content (returns bytes)
  Future<List<int>> downloadFile(int fileId) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Downloading file $fileId via Proxy');
      }

      final bytes = await _proxyClient.downloadFile('/files/$fileId/download');

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient.downloadFile($fileId): success, size=${bytes.length}',
        );
      }

      return bytes;
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Download file error: $error');
      }
      rethrow;
    }
  }

  /// Get assignment details for a specific course
  Future<Map<String, dynamic>> getAssignment(
    int courseId,
    int assignmentId,
  ) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Getting assignment $assignmentId for course $courseId via Proxy',
        );
      }

      final result = await _proxyClient.get<dynamic>(
        '/courses/$courseId/assignments/$assignmentId',
      );

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        final ok = result.isSuccess;
        debugPrint(
          'CanvasApiClient.getAssignment($courseId, $assignmentId): success=$ok',
        );
      }

      if (result.isSuccess && result.valueOrNull is Map) {
        return result.valueOrNull as Map<String, dynamic>;
      }

      throw Exception(
        'Failed to get assignment: ${result.failureOrNull?.message}',
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get assignment error: $error');
      }
      rethrow;
    }
  }

  /// Get session cookies for WebView
  Future<Map<String, dynamic>> getSessionCookies() async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Getting session cookies for WebView');
      }

      final result = await _proxyClient.get<dynamic>('/session/cookies');

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        final ok = result.isSuccess;
        debugPrint('CanvasApiClient.getSessionCookies(): success=$ok');
      }

      if (result.isSuccess && result.valueOrNull is Map) {
        return result.valueOrNull as Map<String, dynamic>;
      }

      throw Exception(
        'Failed to get session cookies: ${result.failureOrNull?.message}',
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get session cookies error: $error');
      }
      rethrow;
    }
  }

  /// Perform POST request via Proxy API
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: POST $path via Proxy');
      }

      return await _proxyClient.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        fromJson: fromJson,
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: POST error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('POST request failed: $error'),
      );
    }
  }

  /// Perform PUT request via Proxy API
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: PUT $path via Proxy');
      }

      return await _proxyClient.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        fromJson: fromJson,
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: PUT error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('PUT request failed: $error'),
      );
    }
  }

  /// Perform DELETE request via Proxy API
  Future<Result<void>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: DELETE $path via Proxy');
      }

      return await _proxyClient.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: DELETE error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('DELETE request failed: $error'),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _proxyClient.dispose();
  }
}

/// Paginated response wrapper for Canvas API results
class PaginatedResponse<T> {
  final List<T> items;
  final String? currentPage;
  final String? nextPage;
  final String? prevPage;
  final String? firstPage;
  final String? lastPage;
  final int? totalCount;

  const PaginatedResponse({
    required this.items,
    this.currentPage,
    this.nextPage,
    this.prevPage,
    this.firstPage,
    this.lastPage,
    this.totalCount,
  });

  /// Check if there are more pages available
  bool get hasNextPage => nextPage != null;

  /// Check if there are previous pages available
  bool get hasPrevPage => prevPage != null;

  /// Get total number of items (if available)
  int get itemCount => items.length;

  /// Check if this is the first page
  bool get isFirstPage => prevPage == null;

  /// Check if this is the last page
  bool get isLastPage => nextPage == null;

  @override
  String toString() {
    return 'PaginatedResponse(items: ${items.length}, currentPage: $currentPage, hasNext: $hasNextPage, hasPrev: $hasPrevPage)';
  }
}

/// Extension to add specific Canvas API methods
extension CanvasApiMethods on CanvasApiClient {
  /// Get courses from Canvas API via Proxy
  Future<Result<List<Map<String, dynamic>>>> getCourses({
    String? enrollmentState,
    List<String>? include,
    int? perPage,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Getting courses via Proxy');
      }

      final queryParams = <String, dynamic>{};
      if (enrollmentState != null) {
        queryParams['enrollment_state'] = enrollmentState;
      }
      if (include != null && include.isNotEmpty) {
        queryParams['include[]'] = include;
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage;
      }

      final result = await get<dynamic>(
        '/courses',
        queryParameters: queryParams,
      );

      if (result.isSuccess && result.valueOrNull is List) {
        final List<dynamic> jsonList = result.valueOrNull as List<dynamic>;
        final List<Map<String, dynamic>> courses =
            jsonList.map((item) => item as Map<String, dynamic>).toList();
        return Result.success(courses);
      }

      return Result.failure(
        GeneralFailure.unknown(
          'Failed to get courses: ${result.failureOrNull?.message}',
        ),
      );
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get courses error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Get courses failed: $error'),
      );
    }
  }

  /// 複数のコースの課題を一括取得
  Future<Result<List<Map<String, dynamic>>>> getAllAssignments(
    List<String> courseIds, {
    List<String>? include,
    int? perPage,
  }) async {
    try {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Getting assignments for ${courseIds.length} courses',
        );
      }

      // Fetch assignments for all courses in parallel for better performance
      final fetchFutures =
          courseIds.map((courseId) {
            return _fetchAssignmentsWithRetry(
              int.parse(courseId),
              include: include,
              perPage: perPage,
              maxRetries: 2,
            );
          }).toList();

      final resultsPerCourse = await Future.wait(fetchFutures);
      final combined = <Map<String, dynamic>>[];
      int totalCourses = courseIds.length;
      int successfulCourses = 0;

      for (int i = 0; i < resultsPerCourse.length; i++) {
        final list = resultsPerCourse[i];
        if (list.isNotEmpty) {
          successfulCourses++;
        }
        combined.addAll(list);
      }

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint(
          'CanvasApiClient: Successfully loaded assignments from $successfulCourses/$totalCourses courses',
        );
        debugPrint(
          'CanvasApiClient: Total assignments loaded: ${combined.length}',
        );
      }

      return Result.success(combined);
    } catch (error) {
      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CanvasApiClient: Get all assignments error: $error');
      }
      return Result.failure(
        GeneralFailure.unknown('Get all assignments failed: $error'),
      );
    }
  }

  /// Fetch assignments for a single course with retry logic
  Future<List<Map<String, dynamic>>> _fetchAssignmentsWithRetry(
    int courseId, {
    List<String>? include,
    int? perPage,
    int maxRetries = 2,
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        final assignments = await getAssignments(
          courseId,
          include: include,
          perPage: perPage,
        );
        final result = assignments.cast<Map<String, dynamic>>();

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'CanvasApiClient: Course $courseId returned ${result.length} assignments',
          );
        }

        return result;
      } catch (error) {
        retryCount++;

        if (kDebugMode && EnvironmentConfig.enableLogging) {
          debugPrint(
            'CanvasApiClient: Failed to get assignments for course $courseId (attempt $retryCount): $error',
          );
        }

        // If this is the last retry, return empty list
        if (retryCount > maxRetries) {
          if (kDebugMode && EnvironmentConfig.enableLogging) {
            debugPrint(
              'CanvasApiClient: Giving up on course $courseId after $maxRetries retries',
            );
          }
          return <Map<String, dynamic>>[];
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    return <Map<String, dynamic>>[];
  }
}
