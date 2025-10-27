import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/services/canvas_endpoints.dart';
import 'package:kpass/core/utils/result.dart';
import 'package:kpass/core/errors/failures.dart';

/// Service class for Canvas API operations
/// Provides high-level methods for interacting with Canvas LMS API
class CanvasApiService {
  final CanvasApiClient _apiClient;

  CanvasApiService({
    CanvasApiClient? apiClient,
  }) : _apiClient = apiClient ?? CanvasApiClient();

  /// Get current user information
  Future<Result<Map<String, dynamic>>> getCurrentUser() async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting current user');
      }

      return await _apiClient.get<Map<String, dynamic>>(
        CanvasEndpoints.userSelf,
        fromJson: (json) => json,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get current user error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get current user: $error'),
      );
    }
  }

  /// Get user's courses with pagination support
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCourses({
    String? enrollmentState,
    List<String>? include,
    String? state,
    int? perPage,
    String? page,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting courses');
      }

      final params = CanvasEndpoints.buildCoursesParams(
        enrollmentState: enrollmentState ?? 'active',
        include: include ?? [
          'term',
          'course_image',
          'favorites',
          'sections',
          'total_students',
          'teachers'
        ],
        state: state,
        perPage: perPage,
      );

      return await _apiClient.getPaginated<Map<String, dynamic>>(
        CanvasEndpoints.courses,
        queryParameters: params,
        fromJson: (json) => json,
        page: page,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get courses error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get courses: $error'),
      );
    }
  }

  /// Get specific course by ID
  Future<Result<Map<String, dynamic>>> getCourse(int courseId) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting course $courseId');
      }

      final params = {
        'include[]': [
          'term',
          'course_image',
          'sections',
          'total_students',
          'teachers',
          'syllabus_body'
        ],
      };

      return await _apiClient.get<Map<String, dynamic>>(
        CanvasEndpoints.courseById(courseId),
        queryParameters: params,
        fromJson: (json) => json,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get course error: $error');
      }
      return Result.failure(
        CanvasFailure.courseNotFound(courseId),
      );
    }
  }

  /// Get assignments for a specific course
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCourseAssignments(
    int courseId, {
    List<String>? include,
    String? orderBy,
    String? searchTerm,
    DateTime? dueBefore,
    DateTime? dueAfter,
    int? perPage,
    String? page,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting assignments for course $courseId');
      }

      final params = CanvasEndpoints.buildAssignmentsParams(
        include: include ?? [
          'submission',
          'rubric_assessment',
          'assignment_visibility',
          'overrides',
          'observed_users'
        ],
        orderBy: orderBy ?? 'due_at',
        searchTerm: searchTerm,
        dueBefore: dueBefore,
        dueAfter: dueAfter,
        perPage: perPage,
      );

      return await _apiClient.getPaginated<Map<String, dynamic>>(
        CanvasEndpoints.courseAssignments(courseId),
        queryParameters: params,
        fromJson: (json) => json,
        page: page,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get course assignments error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get assignments for course $courseId: $error'),
      );
    }
  }

  /// Get specific assignment by ID
  Future<Result<Map<String, dynamic>>> getAssignment(
    int courseId,
    int assignmentId,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting assignment $assignmentId from course $courseId');
      }

      final params = {
        'include[]': [
          'submission',
          'rubric_assessment',
          'assignment_visibility',
          'overrides'
        ],
      };

      return await _apiClient.get<Map<String, dynamic>>(
        '${CanvasEndpoints.courseAssignments(courseId)}/$assignmentId',
        queryParameters: params,
        fromJson: (json) => json,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get assignment error: $error');
      }
      return Result.failure(
        CanvasFailure.assignmentNotFound(assignmentId),
      );
    }
  }

  /// Get user's calendar events
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCalendarEvents({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? contextCodes,
    List<String>? include,
    int? perPage,
    String? page,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting calendar events');
      }

      final params = CanvasEndpoints.buildCalendarParams(
        type: type,
        startDate: startDate,
        endDate: endDate,
        contextCodes: contextCodes,
        include: include ?? [
          'description',
          'child_events',
          'assignment',
          'course'
        ],
        perPage: perPage,
      );

      return await _apiClient.getPaginated<Map<String, dynamic>>(
        CanvasEndpoints.userCalendarEvents,
        queryParameters: params,
        fromJson: (json) => json,
        page: page,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get calendar events error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get calendar events: $error'),
      );
    }
  }

  /// Get planner items (Canvas Planner API)
  Future<Result<List<Map<String, dynamic>>>> getPlannerItems({
    DateTime? startDate,
    DateTime? endDate,
    String? contextCodes, // comma-separated if multiple
    String? filter,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting planner items');
      }

      final params = <String, dynamic>{};
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (contextCodes != null && contextCodes.isNotEmpty) params['context_codes[]'] = contextCodes.split(',');
      if (filter != null && filter.isNotEmpty) params['filter'] = filter; // e.g., new_activity

      final result = await _apiClient.get<List<dynamic>>(
        CanvasEndpoints.plannerItems,
        queryParameters: params,
      );

      if (result.isFailure) return Result.failure(result.failureOrNull!);

      final list = (result.valueOrNull ?? [])
          .cast<Map<String, dynamic>>();
      return Result.success(list);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get planner items error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get planner items: $error'),
      );
    }
  }

  /// Get upcoming assignments (assignments due in the next 7 days)
  Future<Result<List<Map<String, dynamic>>>> getUpcomingAssignments({
    int daysAhead = 7,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting upcoming assignments');
      }

      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      // Get calendar events for assignments
      final calendarResult = await getCalendarEvents(
        type: 'assignment',
        startDate: now,
        endDate: futureDate,
        perPage: 100,
      );

      if (calendarResult.isFailure) {
        return Result.failure(calendarResult.failureOrNull!);
      }

      final events = calendarResult.valueOrNull!.items;
      
      // Filter and sort by due date
      final upcomingAssignments = events
          .where((event) => event['assignment'] != null)
          .toList()
        ..sort((a, b) {
          final aDate = DateTime.tryParse(a['start_at'] ?? '') ?? DateTime.now();
          final bDate = DateTime.tryParse(b['start_at'] ?? '') ?? DateTime.now();
          return aDate.compareTo(bDate);
        });

      return Result.success(upcomingAssignments);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get upcoming assignments error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get upcoming assignments: $error'),
      );
    }
  }

  /// Get all assignments across all courses
  Future<Result<List<Map<String, dynamic>>>> getAllAssignments({
    DateTime? dueBefore,
    DateTime? dueAfter,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting all assignments');
      }

      // First get all courses
      final coursesResult = await getCourses(perPage: 100);
      if (coursesResult.isFailure) {
        return Result.failure(coursesResult.failureOrNull!);
      }

      final courses = coursesResult.valueOrNull!.items;
      final allAssignments = <Map<String, dynamic>>[];

      // Get assignments for each course
      for (final course in courses) {
        final courseId = course['id'] as int;
        
        final assignmentsResult = await getCourseAssignments(
          courseId,
          dueBefore: dueBefore,
          dueAfter: dueAfter,
          perPage: 100,
        );

        if (assignmentsResult.isSuccess) {
          final assignments = assignmentsResult.valueOrNull!.items;
          
          // Add course information to each assignment
          for (final assignment in assignments) {
            assignment['course'] = course;
          }
          
          allAssignments.addAll(assignments);
        }
      }

      // Sort by due date
      allAssignments.sort((a, b) {
        final aDate = DateTime.tryParse(a['due_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['due_at'] ?? '') ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      return Result.success(allAssignments);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get all assignments error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get all assignments: $error'),
      );
    }
  }

  /// Search for courses by name
  Future<Result<List<Map<String, dynamic>>>> searchCourses(String query) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Searching courses with query: $query');
      }

      final coursesResult = await getCourses(perPage: 100);
      if (coursesResult.isFailure) {
        return Result.failure(coursesResult.failureOrNull!);
      }

      final courses = coursesResult.valueOrNull!.items;
      
      // Filter courses by name or course code
      final filteredCourses = courses.where((course) {
        final name = (course['name'] as String? ?? '').toLowerCase();
        final courseCode = (course['course_code'] as String? ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) || courseCode.contains(searchQuery);
      }).toList();

      return Result.success(filteredCourses);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Search courses error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to search courses: $error'),
      );
    }
  }

  /// Get course announcements
  Future<Result<PaginatedResponse<Map<String, dynamic>>>> getCourseAnnouncements(
    int courseId, {
    int? perPage,
    String? page,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Getting announcements for course $courseId');
      }

      final params = <String, dynamic>{
        'only_announcements': true,
        'include[]': ['sections', 'sections_user_count'],
      };

      if (perPage != null) {
        params['per_page'] = perPage;
      }

      return await _apiClient.getPaginated<Map<String, dynamic>>(
        CanvasEndpoints.courseAnnouncements(courseId),
        queryParameters: params,
        fromJson: (json) => json,
        page: page,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CanvasApiService: Get course announcements error: $error');
      }
      return Result.failure(
        CanvasFailure.apiError('Failed to get announcements for course $courseId: $error'),
      );
    }
  }

  /// Test API connection
  Future<Result<Map<String, dynamic>>> testConnection() async {
    return await _apiClient.testConnection();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
}