import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'assignments_remote_data_source.dart';

/// Implementation of AssignmentsLocalDataSource using file system
class AssignmentsLocalDataSourceImpl implements AssignmentsLocalDataSource {
  static const String _assignmentsFileName = 'assignments_cache.json';
  static const String _metadataFileName = 'assignments_metadata.json';
  static const String _readStatusFileName = 'assignments_read_status.json';
  static const Duration _defaultCacheExpiry = Duration(hours: 3);

  @override
  Future<List<Assignment>> getCachedAssignments() async {
    try {
      final file = await _getAssignmentsFile();
      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final assignmentsJson = jsonData['assignments'] as List?;

      if (assignmentsJson == null) {
        return [];
      }

      return assignmentsJson
          .map((assignmentJson) => Assignment.fromJson(assignmentJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getCachedAssignmentsForCourse(int courseId) async {
    try {
      final assignments = await getCachedAssignments();
      return assignments.where((assignment) => assignment.courseId == courseId).toList();
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached assignments for course $courseId: ${e.toString()}',
      );
    }
  }

  @override
  Future<Assignment?> getCachedAssignment(int assignmentId) async {
    try {
      final assignments = await getCachedAssignments();
      return assignments.where((assignment) => assignment.id == assignmentId).firstOrNull;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read cached assignment $assignmentId: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheAssignments(List<Assignment> assignments) async {
    try {
      final file = await _getAssignmentsFile();
      final cacheData = {
        'assignments': assignments.map((assignment) => assignment.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.encode(cacheData));

      // Update metadata
      final metadata = CacheMetadata(
        lastUpdated: DateTime.now(),
        itemCount: assignments.length,
      );
      await updateCacheMetadata(metadata);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheAssignmentsForCourse(int courseId, List<Assignment> assignments) async {
    try {
      // Get existing assignments and replace those for this course
      final existingAssignments = await getCachedAssignments();
      final otherCourseAssignments = existingAssignments
          .where((assignment) => assignment.courseId != courseId)
          .toList();
      
      final allAssignments = [...otherCourseAssignments, ...assignments];
      await cacheAssignments(allAssignments);

      // Update course-specific metadata
      final metadata = CacheMetadata(
        lastUpdated: DateTime.now(),
        itemCount: assignments.length,
        additionalData: {'courseId': courseId},
      );
      await updateCacheMetadataForCourse(courseId, metadata);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache assignments for course $courseId: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheAssignment(Assignment assignment) async {
    try {
      final assignments = await getCachedAssignments();
      final existingIndex = assignments.indexWhere((a) => a.id == assignment.id);
      
      if (existingIndex >= 0) {
        assignments[existingIndex] = assignment;
      } else {
        assignments.add(assignment);
      }

      await cacheAssignments(assignments);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cache assignment ${assignment.id}: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final assignmentsFile = await _getAssignmentsFile();
      final metadataFile = await _getMetadataFile();

      if (await assignmentsFile.exists()) {
        await assignmentsFile.delete();
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
  Future<void> clearCacheForCourse(int courseId) async {
    try {
      final assignments = await getCachedAssignments();
      final otherCourseAssignments = assignments
          .where((assignment) => assignment.courseId != courseId)
          .toList();
      
      await cacheAssignments(otherCourseAssignments);
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear cache for course $courseId: ${e.toString()}',
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
  Future<CacheMetadata?> getCacheMetadataForCourse(int courseId) async {
    try {
      final file = await _getCourseMetadataFile(courseId);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return CacheMetadata.fromJson(jsonData);
    } catch (e) {
      return null;
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
  Future<void> updateCacheMetadataForCourse(int courseId, CacheMetadata metadata) async {
    try {
      final file = await _getCourseMetadataFile(courseId);
      await file.writeAsString(json.encode(metadata.toJson()));
    } catch (e) {
      throw CacheException(
        message: 'Failed to update cache metadata for course $courseId: ${e.toString()}',
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
  Future<bool> isCacheExpiredForCourse(int courseId) async {
    try {
      final metadata = await getCacheMetadataForCourse(courseId);
      if (metadata == null) return true;
      return metadata.isExpired(maxAge: _defaultCacheExpiry);
    } catch (e) {
      return true; // Consider cache expired if we can't read metadata
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      final assignmentsFile = await _getAssignmentsFile();
      final metadataFile = await _getMetadataFile();
      final readStatusFile = await _getReadStatusFile();

      int size = 0;
      if (await assignmentsFile.exists()) {
        size += (await assignmentsFile.length()).toInt();
      }
      if (await metadataFile.exists()) {
        size += (await metadataFile.length()).toInt();
      }
      if (await readStatusFile.exists()) {
        size += (await readStatusFile.length()).toInt();
      }

      return size;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> markAssignmentAsRead(int assignmentId) async {
    try {
      final readIds = await getReadAssignmentIds();
      readIds.add(assignmentId);
      
      final file = await _getReadStatusFile();
      final data = {
        'readAssignmentIds': readIds.toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await file.writeAsString(json.encode(data));
    } catch (e) {
      throw CacheException(
        message: 'Failed to mark assignment $assignmentId as read: ${e.toString()}',
      );
    }
  }

  @override
  Future<Set<int>> getReadAssignmentIds() async {
    try {
      final file = await _getReadStatusFile();
      if (!await file.exists()) {
        return <int>{};
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final readIds = jsonData['readAssignmentIds'] as List?;

      if (readIds == null) {
        return <int>{};
      }

      return readIds.cast<int>().toSet();
    } catch (e) {
      return <int>{};
    }
  }

  @override
  Future<void> clearReadStatus() async {
    try {
      final file = await _getReadStatusFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear read status: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteAssignment(int assignmentId) async {
    try {
      // Get all cached assignments
      final assignments = await getCachedAssignments();
      
      // Remove the assignment with the specified ID
      final updatedAssignments = assignments.where((assignment) => assignment.id != assignmentId).toList();
      
      // Save the updated list
      await cacheAssignments(updatedAssignments);
    } catch (e) {
      throw CacheException(
        message: 'Failed to delete assignment $assignmentId: ${e.toString()}',
      );
    }
  }

  Future<File> _getAssignmentsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_assignmentsFileName');
  }

  Future<File> _getMetadataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_metadataFileName');
  }

  Future<File> _getCourseMetadataFile(int courseId) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/assignments_metadata_course_$courseId.json');
  }

  Future<File> _getReadStatusFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_readStatusFileName');
  }
}