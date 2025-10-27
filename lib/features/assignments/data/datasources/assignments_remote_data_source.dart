import 'package:kpass/shared/models/models.dart';

/// Remote data source interface for assignments
abstract class AssignmentsRemoteDataSource {
  /// Fetch all assignments from Canvas API
  Future<List<Assignment>> getAssignments();

  /// Fetch assignments for a specific course from Canvas API
  Future<List<Assignment>> getAssignmentsForCourse(int courseId);

  /// Fetch a specific assignment by ID from Canvas API
  Future<Assignment> getAssignment(int assignmentId);

  /// Fetch assignments with pagination support
  Future<List<Assignment>> getAssignmentsWithPagination({
    int page = 1,
    int perPage = 50,
  });

  /// Fetch assignments for a course with pagination
  Future<List<Assignment>> getAssignmentsForCourseWithPagination(
    int courseId, {
    int page = 1,
    int perPage = 50,
  });

  /// Fetch assignments with specific workflow states
  Future<List<Assignment>> getAssignmentsWithWorkflowState(
    List<String> workflowStates,
  );

  /// Fetch assignments due within a date range
  Future<List<Assignment>> getAssignmentsDueInRange(
    DateTime startDate,
    DateTime endDate,
  );
}

/// Local data source interface for assignments
abstract class AssignmentsLocalDataSource {
  /// Get cached assignments
  Future<List<Assignment>> getCachedAssignments();

  /// Get cached assignments for a specific course
  Future<List<Assignment>> getCachedAssignmentsForCourse(int courseId);

  /// Get a cached assignment by ID
  Future<Assignment?> getCachedAssignment(int assignmentId);

  /// Cache assignments data
  Future<void> cacheAssignments(List<Assignment> assignments);

  /// Cache assignments for a specific course
  Future<void> cacheAssignmentsForCourse(int courseId, List<Assignment> assignments);

  /// Cache a single assignment
  Future<void> cacheAssignment(Assignment assignment);

  /// Clear all cached assignments
  Future<void> clearCache();

  /// Clear cached assignments for a specific course
  Future<void> clearCacheForCourse(int courseId);

  /// Get cache metadata
  Future<CacheMetadata> getCacheMetadata();

  /// Get cache metadata for a specific course
  Future<CacheMetadata?> getCacheMetadataForCourse(int courseId);

  /// Update cache metadata
  Future<void> updateCacheMetadata(CacheMetadata metadata);

  /// Update cache metadata for a specific course
  Future<void> updateCacheMetadataForCourse(int courseId, CacheMetadata metadata);

  /// Check if cache is expired
  Future<bool> isCacheExpired();

  /// Check if cache for a specific course is expired
  Future<bool> isCacheExpiredForCourse(int courseId);

  /// Get cache size in bytes
  Future<int> getCacheSize();

  /// Mark assignment as read
  Future<void> markAssignmentAsRead(int assignmentId);

  /// Get read assignment IDs
  Future<Set<int>> getReadAssignmentIds();

  /// Clear read status for all assignments
  Future<void> clearReadStatus();

  /// Delete a specific assignment from cache
  Future<void> deleteAssignment(int assignmentId);
}