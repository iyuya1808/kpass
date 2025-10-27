import 'package:kpass/shared/models/models.dart';

/// Repository interface for managing course data
abstract class CoursesRepository {
  /// Get all courses for the authenticated user
  /// Returns cached data if available and [forceRefresh] is false
  Future<List<Course>> getCourses({bool forceRefresh = false});

  /// Get a specific course by ID
  /// Returns cached data if available and [forceRefresh] is false
  Future<Course?> getCourse(int courseId, {bool forceRefresh = false});

  /// Get courses that are currently active
  Future<List<Course>> getActiveCourses({bool forceRefresh = false});

  /// Get favorite courses
  Future<List<Course>> getFavoriteCourses({bool forceRefresh = false});

  /// Search courses by name or course code
  Future<List<Course>> searchCourses(String query, {bool forceRefresh = false});

  /// Refresh course data from remote source
  Future<void> refreshCourses();

  /// Clear cached course data
  Future<void> clearCache();

  /// Get cache status information
  Future<CacheStatus> getCacheStatus();

  /// Save courses to local storage
  Future<void> saveCourses(List<Course> courses);
}