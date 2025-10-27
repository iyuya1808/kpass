import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'courses_remote_data_source.dart';

/// Implementation of CoursesRemoteDataSource using Canvas API
class CoursesRemoteDataSourceImpl implements CoursesRemoteDataSource {
  final CanvasApiClient _apiClient;

  const CoursesRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Course>> getCourses() async {
    try {
      final response = await _apiClient.get(
        '/courses',
        queryParameters: {
          'enrollment_state': 'active',
          'include[]': ['term', 'total_students', 'teachers', 'enrollments'],
          'per_page': '100',
        },
      );

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for courses',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch courses: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<Course> getCourse(int courseId) async {
    try {
      final response = await _apiClient.get(
        '/courses/$courseId',
        queryParameters: {
          'include[]': ['term', 'total_students', 'teachers', 'enrollments'],
        },
      );

      if (response.isSuccess && response.valueOrNull is Map<String, dynamic>) {
        return Course.fromJson(response.valueOrNull as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Invalid response format for course',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch course $courseId: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Course>> getCoursesWithPagination({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/courses',
        queryParameters: {
          'enrollment_state': 'active',
          'include[]': ['term', 'total_students', 'teachers', 'enrollments'],
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for courses with pagination',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch courses with pagination: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  @override
  Future<List<Course>> getCoursesWithEnrollmentState(
    List<String> enrollmentStates,
  ) async {
    try {
      final response = await _apiClient.get(
        '/courses',
        queryParameters: {
          'enrollment_state': enrollmentStates.join(','),
          'include[]': ['term', 'total_students', 'teachers', 'enrollments'],
          'per_page': '100',
        },
      );

      if (response.isSuccess && response.valueOrNull is List) {
        return (response.valueOrNull as List)
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Invalid response format for courses with enrollment state',
        statusCode: 200,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message:
            'Failed to fetch courses with enrollment state: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
