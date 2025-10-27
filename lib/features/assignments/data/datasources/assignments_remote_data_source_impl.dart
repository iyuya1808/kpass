import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'assignments_remote_data_source.dart';

/// Implementation of AssignmentsRemoteDataSource using Canvas API
class AssignmentsRemoteDataSourceImpl implements AssignmentsRemoteDataSource {
  final CanvasApiClient _apiClient;

  const AssignmentsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Assignment>> getAssignments() async {
    try {
      // Get all courses first, then fetch assignments for each
      final coursesResponse = await _apiClient.get(
        '/courses',
        queryParameters: {'enrollment_state': 'active', 'per_page': '100'},
      );

      if (!coursesResponse.isSuccess || coursesResponse.valueOrNull is! List) {
        throw const ApiException(
          message: 'Invalid response format for courses',
          statusCode: 200,
        );
      }

      final courses = coursesResponse.valueOrNull as List;
      final List<Assignment> allAssignments = [];

      // Fetch assignments for each course
      for (final courseJson in courses) {
        final courseId = courseJson['id'] as int;
        try {
          final courseAssignments = await getAssignmentsForCourse(courseId);
          allAssignments.addAll(courseAssignments);
        } catch (e) {
          // Continue with other courses if one fails
          continue;
        }
      }

      return allAssignments;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch assignments: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsForCourse(int courseId) async {
    try {
      final response = await _apiClient.get(
        '/courses/$courseId/assignments',
        queryParameters: {
          'include[]': ['submission', 'assignment_visibility', 'overrides'],
          'per_page': '100',
        },
      );

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => Assignment.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for assignments',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message:
            'Failed to fetch assignments for course $courseId: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<Assignment> getAssignment(int assignmentId) async {
    try {
      // We need to find which course this assignment belongs to
      // This is a limitation of Canvas API - we need course context
      throw const ApiException(
        message:
            'Getting assignment by ID requires course context. Use getAssignmentsForCourse instead.',
        statusCode: 400,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch assignment $assignmentId: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsWithPagination({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Get all courses first, then fetch assignments for each with pagination
      final coursesResponse = await _apiClient.get(
        '/courses',
        queryParameters: {'enrollment_state': 'active', 'per_page': '100'},
      );

      if (!coursesResponse.isSuccess || coursesResponse.valueOrNull is! List) {
        throw const ApiException(
          message: 'Invalid response format for courses',
          statusCode: 200,
        );
      }

      final courses = coursesResponse.valueOrNull as List;
      final List<Assignment> allAssignments = [];

      // Fetch assignments for each course with pagination
      for (final courseJson in courses) {
        final courseId = courseJson['id'] as int;
        try {
          final courseAssignments = await getAssignmentsForCourseWithPagination(
            courseId,
            page: page,
            perPage: perPage,
          );
          allAssignments.addAll(courseAssignments);
        } catch (e) {
          // Continue with other courses if one fails
          continue;
        }
      }

      return allAssignments;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch assignments with pagination: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsForCourseWithPagination(
    int courseId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/courses/$courseId/assignments',
        queryParameters: {
          'include[]': ['submission', 'assignment_visibility', 'overrides'],
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => Assignment.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for assignments with pagination',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message:
            'Failed to fetch assignments for course $courseId with pagination: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsWithWorkflowState(
    List<String> workflowStates,
  ) async {
    try {
      final allAssignments = await getAssignments();
      return allAssignments
          .where(
            (assignment) => workflowStates.contains(assignment.workflowState),
          )
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message:
            'Failed to fetch assignments with workflow state: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsDueInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allAssignments = await getAssignments();
      return allAssignments.where((assignment) {
        if (assignment.dueAt == null) return false;
        return assignment.dueAt!.isAfter(startDate) &&
            assignment.dueAt!.isBefore(endDate);
      }).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch assignments due in range: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
