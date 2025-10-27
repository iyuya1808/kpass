import 'package:kpass/shared/models/models.dart';

/// Remote data source interface for courses
abstract class CoursesRemoteDataSource {
  /// Fetch all courses from Canvas API
  Future<List<Course>> getCourses();

  /// Fetch a specific course by ID from Canvas API
  Future<Course> getCourse(int courseId);

  /// Fetch courses with pagination support
  Future<List<Course>> getCoursesWithPagination({
    int page = 1,
    int perPage = 50,
  });

  /// Fetch courses with specific enrollment states
  Future<List<Course>> getCoursesWithEnrollmentState(
    List<String> enrollmentStates,
  );
}

/// Local data source interface for courses
abstract class CoursesLocalDataSource {
  /// Get cached courses
  Future<List<Course>> getCachedCourses();

  /// Get a cached course by ID
  Future<Course?> getCachedCourse(int courseId);

  /// Cache courses data
  Future<void> cacheCourses(List<Course> courses);

  /// Cache a single course
  Future<void> cacheCourse(Course course);

  /// Clear all cached courses
  Future<void> clearCache();

  /// Get cache metadata
  Future<CacheMetadata> getCacheMetadata();

  /// Update cache metadata
  Future<void> updateCacheMetadata(CacheMetadata metadata);

  /// Check if cache is expired
  Future<bool> isCacheExpired();

  /// Get cache size in bytes
  Future<int> getCacheSize();
}