import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'courses_remote_data_source.dart';

/// Implementation of CoursesLocalDataSource using file system
class CoursesLocalDataSourceImpl implements CoursesLocalDataSource {
  static const String _coursesFileName = 'courses_cache.json';
  static const String _metadataFileName = 'courses_metadata.json';
  static const Duration _defaultCacheExpiry = Duration(hours: 6);

  @override
  Future<List<Course>> getCachedCourses() async {
    try {
      final file = await _getCoursesFile();
      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final coursesJson = jsonData['courses'] as List?;

      if (coursesJson == null) {
        return [];
      }

      return coursesJson
          .map((courseJson) => Course.fromJson(courseJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<Course?> getCachedCourse(int courseId) async {
    try {
      final courses = await getCachedCourses();
      return courses.where((course) => course.id == courseId).firstOrNull;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached course $courseId: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheCourses(List<Course> courses) async {
    try {
      final file = await _getCoursesFile();
      final cacheData = {
        'courses': courses.map((course) => course.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.encode(cacheData));

      // Update metadata
      final metadata = CacheMetadata(
        lastUpdated: DateTime.now(),
        itemCount: courses.length,
      );
      await updateCacheMetadata(metadata);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache courses: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheCourse(Course course) async {
    try {
      final courses = await getCachedCourses();
      final existingIndex = courses.indexWhere((c) => c.id == course.id);
      
      if (existingIndex >= 0) {
        courses[existingIndex] = course;
      } else {
        courses.add(course);
      }

      await cacheCourses(courses);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache course ${course.id}: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final coursesFile = await _getCoursesFile();
      final metadataFile = await _getMetadataFile();

      if (await coursesFile.exists()) {
        await coursesFile.delete();
      }

      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<CacheMetadata> getCacheMetadata() async {
    try {
      final file = await _getMetadataFile();
      if (!await file.exists()) {
        return CacheMetadata(
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
          itemCount: 0,
        );
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return CacheMetadata.fromJson(jsonData);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cache metadata: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateCacheMetadata(CacheMetadata metadata) async {
    try {
      final file = await _getMetadataFile();
      await file.writeAsString(json.encode(metadata.toJson()));
    } catch (e) {
      throw CacheException(
        message: 'Failed to update cache metadata: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isCacheExpired() async {
    try {
      final metadata = await getCacheMetadata();
      return metadata.isExpired(maxAge: _defaultCacheExpiry);
    } catch (e) {
      return true; // Consider cache expired if we can't read metadata
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      final coursesFile = await _getCoursesFile();
      final metadataFile = await _getMetadataFile();

      int size = 0;
      if (await coursesFile.exists()) {
        size += await coursesFile.length();
      }
      if (await metadataFile.exists()) {
        size += await metadataFile.length();
      }

      return size;
    } catch (e) {
      return 0;
    }
  }

  Future<File> _getCoursesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_coursesFileName');
  }

  Future<File> _getMetadataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_metadataFileName');
  }
}