import 'package:kpass/shared/models/models.dart';

/// Repository interface for managing assignment data
abstract class AssignmentsRepository {
  /// Get all assignments for the authenticated user
  /// Returns cached data if available and [forceRefresh] is false
  Future<List<Assignment>> getAssignments({bool forceRefresh = false});

  /// Get assignments for a specific course
  Future<List<Assignment>> getAssignmentsForCourse(
    int courseId, {
    bool forceRefresh = false,
  });

  /// Get a specific assignment by ID
  Future<Assignment?> getAssignment(int assignmentId, {bool forceRefresh = false});

  /// Get assignments that are due soon (within specified duration)
  Future<List<Assignment>> getAssignmentsDueSoon({
    Duration threshold = const Duration(days: 7),
    bool forceRefresh = false,
  });

  /// Get overdue assignments
  Future<List<Assignment>> getOverdueAssignments({bool forceRefresh = false});

  /// Get available assignments (can be submitted)
  Future<List<Assignment>> getAvailableAssignments({bool forceRefresh = false});

  /// Get submitted assignments
  Future<List<Assignment>> getSubmittedAssignments({bool forceRefresh = false});

  /// Search assignments by name or description
  Future<List<Assignment>> searchAssignments(
    String query, {
    bool forceRefresh = false,
  });

  /// Get assignments grouped by course
  Future<Map<int, List<Assignment>>> getAssignmentsGroupedByCourse({
    bool forceRefresh = false,
  });

  /// Get assignment statistics
  Future<AssignmentStatistics> getAssignmentStatistics({
    bool forceRefresh = false,
  });

  /// Refresh assignment data from remote source
  Future<void> refreshAssignments();

  /// Refresh assignments for a specific course
  Future<void> refreshAssignmentsForCourse(int courseId);

  /// Clear cached assignment data
  Future<void> clearCache();

  /// Clear cached assignment data for a specific course
  Future<void> clearCacheForCourse(int courseId);

  /// Get cache status information
  Future<CacheStatus> getCacheStatus();

  /// Mark assignment as read/viewed
  Future<void> markAssignmentAsRead(int assignmentId);

  /// Get unread assignments count
  Future<int> getUnreadAssignmentsCount();

  /// Sync assignment with calendar (if calendar integration is enabled)
  Future<void> syncAssignmentWithCalendar(int assignmentId);

  /// Remove assignment from calendar
  Future<void> removeAssignmentFromCalendar(int assignmentId);

  /// Get all assignments (alias for getAssignments for backwards compatibility)
  Future<List<Assignment>> getAllAssignments({bool forceRefresh = false});

  /// Save an assignment to local storage
  Future<void> saveAssignment(Assignment assignment);

  /// Delete an assignment from local storage
  Future<void> deleteAssignment(int assignmentId);
}