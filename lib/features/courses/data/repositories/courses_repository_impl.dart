import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';
import 'package:kpass/features/courses/data/datasources/courses_remote_data_source.dart';

/// Implementation of CoursesRepository
class CoursesRepositoryImpl implements CoursesRepository {
  final CoursesRemoteDataSource _remoteDataSource;
  final CoursesLocalDataSource _localDataSource;

  const CoursesRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<List<Course>> getCourses({bool forceRefresh = false}) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await _localDataSource.isCacheExpired()) {
        final cachedCourses = await _localDataSource.getCachedCourses();
        if (cachedCourses.isNotEmpty) {
          return ModelUtils.validateCourses(cachedCourses);
        }
      }

      // Fetch from remote and cache
      final remoteCourses = await _remoteDataSource.getCourses();
      await _localDataSource.cacheCourses(remoteCourses);
      
      return ModelUtils.validateCourses(remoteCourses);
    } on ApiException {
      // If remote fails, try to return cached data
      try {
        final cachedCourses = await _localDataSource.getCachedCourses();
        return ModelUtils.validateCourses(cachedCourses);
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<Course?> getCourse(int courseId, {bool forceRefresh = false}) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await _localDataSource.isCacheExpired()) {
        final cachedCourse = await _localDataSource.getCachedCourse(courseId);
        if (cachedCourse != null && cachedCourse.isValid()) {
          return cachedCourse;
        }
      }

      // Fetch from remote and cache
      final remoteCourse = await _remoteDataSource.getCourse(courseId);
      await _localDataSource.cacheCourse(remoteCourse);
      
      return remoteCourse.isValid() ? remoteCourse : null;
    } on ApiException {
      // If remote fails, try to return cached data
      try {
        final cachedCourse = await _localDataSource.getCachedCourse(courseId);
        return cachedCourse?.isValid() == true ? cachedCourse : null;
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get course $courseId: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Course>> getActiveCourses({bool forceRefresh = false}) async {
    try {
      final courses = await getCourses(forceRefresh: forceRefresh);
      return ModelUtils.filterActiveCourses(courses);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get active courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Course>> getFavoriteCourses({bool forceRefresh = false}) async {
    try {
      final courses = await getCourses(forceRefresh: forceRefresh);
      return courses.where((course) => course.isFavorite == true).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get favorite courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Course>> searchCourses(String query, {bool forceRefresh = false}) async {
    try {
      final courses = await getCourses(forceRefresh: forceRefresh);
      final lowercaseQuery = query.toLowerCase();
      
      return courses.where((course) {
        return course.name.toLowerCase().contains(lowercaseQuery) ||
               course.courseCode.toLowerCase().contains(lowercaseQuery) ||
               (course.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to search courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> refreshCourses() async {
    try {
      await getCourses(forceRefresh: true);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to refresh courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localDataSource.clearCache();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to clear cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<CacheStatus> getCacheStatus() async {
    try {
      final metadata = await _localDataSource.getCacheMetadata();
      final isExpired = await _localDataSource.isCacheExpired();
      final age = metadata.lastUpdated.millisecondsSinceEpoch > 0
          ? DateTime.now().difference(metadata.lastUpdated)
          : null;

      return CacheStatus(
        lastUpdated: metadata.lastUpdated.millisecondsSinceEpoch > 0 
            ? metadata.lastUpdated 
            : null,
        itemCount: metadata.itemCount,
        isExpired: isExpired,
        age: age,
      );
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get cache status: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> saveCourses(List<Course> courses) async {
    try {
      await _localDataSource.cacheCourses(courses);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to save courses: ${e.toString()}',
      );
    }
  }
}