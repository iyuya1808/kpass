import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/canvas_api_service.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/services/cache_service.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/errors/failures.dart';

/// Cache strategy for different types of data
enum CacheStrategy {
  /// Always try cache first, fallback to network
  cacheFirst,
  /// Always fetch from network, update cache
  networkFirst,
  /// Use cache only, no network requests
  cacheOnly,
  /// Use network only, no caching
  networkOnly,
}

/// Cache configuration for different data types
class CachePolicy {
  final Duration ttl;
  final CacheStrategy strategy;
  final bool allowStale;

  const CachePolicy({
    required this.ttl,
    this.strategy = CacheStrategy.cacheFirst,
    this.allowStale = false,
  });

  /// Policy for user data (short TTL, cache first)
  static const user = CachePolicy(
    ttl: Duration(minutes: 15),
    strategy: CacheStrategy.cacheFirst,
  );

  /// Policy for courses (medium TTL, cache first)
  static const courses = CachePolicy(
    ttl: Duration(hours: 1),
    strategy: CacheStrategy.cacheFirst,
  );

  /// Policy for assignments (short TTL, network first for freshness)
  static const assignments = CachePolicy(
    ttl: Duration(minutes: 30),
    strategy: CacheStrategy.networkFirst,
  );

  /// Policy for calendar events (short TTL, network first)
  static const calendar = CachePolicy(
    ttl: Duration(minutes: 15),
    strategy: CacheStrategy.networkFirst,
  );

  /// Policy for announcements (medium TTL, cache first)
  static const announcements = CachePolicy(
    ttl: Duration(hours: 2),
    strategy: CacheStrategy.cacheFirst,
  );
}

/// Cached Canvas API service with offline support
/// Wraps CanvasApiService with intelligent caching and offline fallbacks
class CachedCanvasApiService {
  final CanvasApiService _apiService;
  final CacheService _cacheService;

  CachedCanvasApiService({
    CanvasApiService? apiService,
    CacheService? cacheService,
  }) : _apiService = apiService ?? CanvasApiService(),
       _cacheService = cacheService ?? CacheService();

  /// Initialize the service
  Future<Result<void>> initialize() async {
    return await _cacheService.initialize();
  }

  /// Get current user with caching
  Future<Result<Map<String, dynamic>>> getCurrentUser({
    CachePolicy policy = CachePolicy.user,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'user_self';
    
    return await _executeWithCache(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getCurrentUser(),
    );
  }

  /// Get courses with caching and pagination support
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCourses({
    String? enrollmentState,
    List<String>? include,
    String? state,
    int? perPage,
    String? page,
    CachePolicy policy = CachePolicy.courses,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey('courses', {
      'enrollment_state': enrollmentState,
      'include': include?.join(','),
      'state': state,
      'per_page': perPage,
      'page': page,
    });

    return await _executeWithCachePaginated(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getCourses(
        enrollmentState: enrollmentState,
        include: include,
        state: state,
        perPage: perPage,
        page: page,
      ),
    );
  }

  /// Get specific course with caching
  Future<Result<Map<String, dynamic>>> getCourse(
    int courseId, {
    CachePolicy policy = CachePolicy.courses,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'course_$courseId';
    
    return await _executeWithCache(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getCourse(courseId),
    );
  }

  /// Get course assignments with caching
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCourseAssignments(
    int courseId, {
    List<String>? include,
    String? orderBy,
    String? searchTerm,
    DateTime? dueBefore,
    DateTime? dueAfter,
    int? perPage,
    String? page,
    CachePolicy policy = CachePolicy.assignments,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey('assignments_$courseId', {
      'include': include?.join(','),
      'order_by': orderBy,
      'search_term': searchTerm,
      'due_before': dueBefore?.toIso8601String(),
      'due_after': dueAfter?.toIso8601String(),
      'per_page': perPage,
      'page': page,
    });

    return await _executeWithCachePaginated(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getCourseAssignments(
        courseId,
        include: include,
        orderBy: orderBy,
        searchTerm: searchTerm,
        dueBefore: dueBefore,
        dueAfter: dueAfter,
        perPage: perPage,
        page: page,
      ),
    );
  }

  /// Get specific assignment with caching
  Future<Result<Map<String, dynamic>>> getAssignment(
    int courseId,
    int assignmentId, {
    CachePolicy policy = CachePolicy.assignments,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'assignment_${courseId}_$assignmentId';
    
    return await _executeWithCache(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getAssignment(courseId, assignmentId),
    );
  }

  /// Get calendar events with caching
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCalendarEvents({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? contextCodes,
    List<String>? include,
    int? perPage,
    String? page,
    CachePolicy policy = CachePolicy.calendar,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey('calendar_events', {
      'type': type,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'context_codes': contextCodes?.join(','),
      'include': include?.join(','),
      'per_page': perPage,
      'page': page,
    });

    return await _executeWithCachePaginated(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getCalendarEvents(
        type: type,
        startDate: startDate,
        endDate: endDate,
        contextCodes: contextCodes,
        include: include,
        perPage: perPage,
        page: page,
      ),
    );
  }

  /// Get upcoming assignments with caching
  Future<Result<List<Map<String, dynamic>>>> getUpcomingAssignments({
    int daysAhead = 7,
    CachePolicy policy = CachePolicy.assignments,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'upcoming_assignments_$daysAhead';
    
    return await _executeWithCacheList(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getUpcomingAssignments(daysAhead: daysAhead),
    );
  }

  /// Get all assignments with caching
  Future<Result<List<Map<String, dynamic>>>> getAllAssignments({
    DateTime? dueBefore,
    DateTime? dueAfter,
    CachePolicy policy = CachePolicy.assignments,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey('all_assignments', {
      'due_before': dueBefore?.toIso8601String(),
      'due_after': dueAfter?.toIso8601String(),
    });
    
    return await _executeWithCacheList(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getAllAssignments(
        dueBefore: dueBefore,
        dueAfter: dueAfter,
      ),
    );
  }

  /// Search courses with caching
  Future<Result<List<Map<String, dynamic>>>> searchCourses(
    String query, {
    CachePolicy policy = CachePolicy.courses,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'search_courses_${query.toLowerCase()}';
    
    return await _executeWithCacheList(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.searchCourses(query),
    );
  }

  /// Get course announcements with caching
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCourseAnnouncements(
    int courseId, {
    int? perPage,
    String? page,
    CachePolicy policy = CachePolicy.announcements,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey('announcements_$courseId', {
      'per_page': perPage,
      'page': page,
    });

    return await _executeWithCachePaginated(
      cacheKey: cacheKey,
      policy: policy,
      forceRefresh: forceRefresh,
      networkCall: () => _apiService.getCourseAnnouncements(
        courseId,
        perPage: perPage,
        page: page,
      ),
    );
  }

  /// Execute network call with cache for single objects
  Future<Result<T>> _executeWithCache<T extends Map<String, dynamic>>({
    required String cacheKey,
    required CachePolicy policy,
    required bool forceRefresh,
    required Future<Result<T>> Function() networkCall,
  }) async {
    // Handle cache-only strategy
    if (policy.strategy == CacheStrategy.cacheOnly) {
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        return Result.success(cacheResult.valueOrNull! as T);
      }
      return Result.failure(CacheFailure.notFound(cacheKey));
    }

    // Handle network-only strategy
    if (policy.strategy == CacheStrategy.networkOnly || forceRefresh) {
      return await networkCall();
    }

    // Handle cache-first strategy
    if (policy.strategy == CacheStrategy.cacheFirst) {
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        if (kDebugMode) {
          debugPrint('CachedCanvasApiService: Cache hit for $cacheKey');
        }
        return Result.success(cacheResult.valueOrNull! as T);
      }
    }

    // Fetch from network
    final networkResult = await networkCall();
    
    // Cache successful results
    if (networkResult.isSuccess) {
      await _cacheService.put(
        cacheKey,
        networkResult.valueOrNull!,
        ttl: policy.ttl,
      );
      
      if (kDebugMode) {
        debugPrint('CachedCanvasApiService: Cached result for $cacheKey');
      }
    } else if (policy.strategy == CacheStrategy.networkFirst && policy.allowStale) {
      // Fallback to stale cache if network fails
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        if (kDebugMode) {
          debugPrint('CachedCanvasApiService: Using stale cache for $cacheKey');
        }
        return Result.success(cacheResult.valueOrNull! as T);
      }
    }

    return networkResult;
  }

  /// Execute network call with cache for paginated responses
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> _executeWithCachePaginated({
    required String cacheKey,
    required CachePolicy policy,
    required bool forceRefresh,
    required Future<Result<PaginatedResponse<Map<String, dynamic>>>> Function() networkCall,
  }) async {
    // Handle cache-only strategy
    if (policy.strategy == CacheStrategy.cacheOnly) {
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        return Result.success(_deserializePaginatedResponse(cacheResult.valueOrNull!));
      }
      return Result.failure(CacheFailure.notFound(cacheKey));
    }

    // Handle network-only strategy
    if (policy.strategy == CacheStrategy.networkOnly || forceRefresh) {
      return await networkCall();
    }

    // Handle cache-first strategy
    if (policy.strategy == CacheStrategy.cacheFirst) {
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        if (kDebugMode) {
          debugPrint('CachedCanvasApiService: Cache hit for $cacheKey');
        }
        return Result.success(_deserializePaginatedResponse(cacheResult.valueOrNull!));
      }
    }

    // Fetch from network
    final networkResult = await networkCall();
    
    // Cache successful results
    if (networkResult.isSuccess) {
      await _cacheService.put(
        cacheKey,
        _serializePaginatedResponse(networkResult.valueOrNull!),
        ttl: policy.ttl,
      );
      
      if (kDebugMode) {
        debugPrint('CachedCanvasApiService: Cached paginated result for $cacheKey');
      }
    } else if (policy.strategy == CacheStrategy.networkFirst && policy.allowStale) {
      // Fallback to stale cache if network fails
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        if (kDebugMode) {
          debugPrint('CachedCanvasApiService: Using stale paginated cache for $cacheKey');
        }
        return Result.success(_deserializePaginatedResponse(cacheResult.valueOrNull!));
      }
    }

    return networkResult;
  }

  /// Execute network call with cache for lists
  Future<Result<List<Map<String, dynamic>>>> _executeWithCacheList({
    required String cacheKey,
    required CachePolicy policy,
    required bool forceRefresh,
    required Future<Result<List<Map<String, dynamic>>>> Function() networkCall,
  }) async {
    // Handle cache-only strategy
    if (policy.strategy == CacheStrategy.cacheOnly) {
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        final items = cacheResult.valueOrNull!['items'] as List<dynamic>;
        return Result.success(items.cast<Map<String, dynamic>>());
      }
      return Result.failure(CacheFailure.notFound(cacheKey));
    }

    // Handle network-only strategy
    if (policy.strategy == CacheStrategy.networkOnly || forceRefresh) {
      return await networkCall();
    }

    // Handle cache-first strategy
    if (policy.strategy == CacheStrategy.cacheFirst) {
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        if (kDebugMode) {
          debugPrint('CachedCanvasApiService: Cache hit for $cacheKey');
        }
        final items = cacheResult.valueOrNull!['items'] as List<dynamic>;
        return Result.success(items.cast<Map<String, dynamic>>());
      }
    }

    // Fetch from network
    final networkResult = await networkCall();
    
    // Cache successful results
    if (networkResult.isSuccess) {
      await _cacheService.put(
        cacheKey,
        {'items': networkResult.valueOrNull!},
        ttl: policy.ttl,
      );
      
      if (kDebugMode) {
        debugPrint('CachedCanvasApiService: Cached list result for $cacheKey');
      }
    } else if (policy.strategy == CacheStrategy.networkFirst && policy.allowStale) {
      // Fallback to stale cache if network fails
      final cacheResult = await _cacheService.get(cacheKey);
      if (cacheResult.isSuccess && cacheResult.valueOrNull != null) {
        if (kDebugMode) {
          debugPrint('CachedCanvasApiService: Using stale list cache for $cacheKey');
        }
        final items = cacheResult.valueOrNull!['items'] as List<dynamic>;
        return Result.success(items.cast<Map<String, dynamic>>());
      }
    }

    return networkResult;
  }

  /// Build cache key from parameters
  String _buildCacheKey(String prefix, Map<String, dynamic> params) {
    final filteredParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    
    return filteredParams.isEmpty ? prefix : '${prefix}_$filteredParams';
  }

  /// Serialize paginated response for caching
  Map<String, dynamic> _serializePaginatedResponse(PaginatedResponse<Map<String, dynamic>> response) {
    return {
      'items': response.items,
      'currentPage': response.currentPage,
      'nextPage': response.nextPage,
      'prevPage': response.prevPage,
      'firstPage': response.firstPage,
      'lastPage': response.lastPage,
      'totalCount': response.totalCount,
    };
  }

  /// Deserialize paginated response from cache
  PaginatedResponse<Map<String, dynamic>> _deserializePaginatedResponse(Map<String, dynamic> data) {
    return PaginatedResponse<Map<String, dynamic>>(
      items: (data['items'] as List<dynamic>).cast<Map<String, dynamic>>(),
      currentPage: data['currentPage'] as String?,
      nextPage: data['nextPage'] as String?,
      prevPage: data['prevPage'] as String?,
      firstPage: data['firstPage'] as String?,
      lastPage: data['lastPage'] as String?,
      totalCount: data['totalCount'] as int?,
    );
  }

  /// Invalidate cache for specific key or pattern
  Future<Result<void>> invalidateCache(String keyOrPattern) async {
    if (keyOrPattern.contains('*')) {
      // Pattern-based invalidation (simplified)
      final keysToRemove = <String>[];
      
      // This is a simplified implementation
      // In a real app, you might want to maintain an index of cache keys
      
      for (final key in keysToRemove) {
        await _cacheService.remove(key);
      }
    } else {
      await _cacheService.remove(keyOrPattern);
    }
    
    return const Result.success(null);
  }

  /// Clear all cache
  Future<Result<void>> clearCache() async {
    return await _cacheService.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Check if authenticated
  Future<bool> isAuthenticated() async {
    return await _apiService.isAuthenticated();
  }

  /// Test connection
  Future<Result<Map<String, dynamic>>> testConnection() async {
    return await _apiService.testConnection();
  }

  /// Dispose resources
  void dispose() {
    _apiService.dispose();
    _cacheService.dispose();
  }
}