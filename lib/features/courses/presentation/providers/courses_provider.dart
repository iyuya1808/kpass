import 'package:flutter/foundation.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/shared/models/course.dart';

class CoursesProvider extends ChangeNotifier {
  final CanvasApiClient _apiClient;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSync;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get hasCourses => _courses.isNotEmpty;

  CoursesProvider({CanvasApiClient? apiClient})
    : _apiClient = apiClient ?? CanvasApiClient();

  /// Load courses from Canvas API
  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch courses from Canvas API
      final response = await _apiClient.get(
        '/courses',
        queryParameters: {
          'enrollment_state': 'active',
          'include[]': ['term', 'total_students', 'favorites'],
          'per_page': '100',
        },
      );

      if (!response.isSuccess || response.valueOrNull is! List) {
        throw Exception('Invalid response format for courses');
      }

      final coursesData = response.valueOrNull as List;
      _courses =
          coursesData
              .map((json) => Course.fromJson(json as Map<String, dynamic>))
              .where((course) => course.isValid() && course.isActive)
              .toList();

      // Sort by name
      _courses.sort((a, b) => a.name.compareTo(b.name));

      _lastSync = DateTime.now();
      _error = null;

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CoursesProvider: Loaded ${_courses.length} courses');
      }
    } catch (e) {
      _error = 'コースの取得中にエラーが発生しました: $e';

      if (kDebugMode && EnvironmentConfig.enableLogging) {
        debugPrint('CoursesProvider: Exception while loading courses: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh courses (clear cache and reload)
  Future<void> refresh() async {
    _courses = [];
    await loadCourses();
  }

  /// Get a specific course by ID
  Course? getCourseById(int courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
