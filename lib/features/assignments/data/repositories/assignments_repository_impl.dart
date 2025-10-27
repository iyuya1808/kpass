import 'package:kpass/shared/models/models.dart';
import 'package:kpass/core/errors/exceptions.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/features/assignments/data/datasources/assignments_remote_data_source.dart';

/// Implementation of AssignmentsRepository
class AssignmentsRepositoryImpl implements AssignmentsRepository {
  final AssignmentsRemoteDataSource _remoteDataSource;
  final AssignmentsLocalDataSource _localDataSource;

  const AssignmentsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<List<Assignment>> getAssignments({bool forceRefresh = false}) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await _localDataSource.isCacheExpired()) {
        final cachedAssignments = await _localDataSource.getCachedAssignments();
        if (cachedAssignments.isNotEmpty) {
          return ModelUtils.validateAssignments(cachedAssignments);
        }
      }

      // Fetch from remote and cache
      final remoteAssignments = await _remoteDataSource.getAssignments();
      await _localDataSource.cacheAssignments(remoteAssignments);
      
      return ModelUtils.validateAssignments(remoteAssignments);
    } on ApiException {
      // If remote fails, try to return cached data
      try {
        final cachedAssignments = await _localDataSource.getCachedAssignments();
        return ModelUtils.validateAssignments(cachedAssignments);
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsForCourse(
    int courseId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await _localDataSource.isCacheExpiredForCourse(courseId)) {
        final cachedAssignments = await _localDataSource.getCachedAssignmentsForCourse(courseId);
        if (cachedAssignments.isNotEmpty) {
          return ModelUtils.validateAssignments(cachedAssignments);
        }
      }

      // Fetch from remote and cache
      final remoteAssignments = await _remoteDataSource.getAssignmentsForCourse(courseId);
      await _localDataSource.cacheAssignmentsForCourse(courseId, remoteAssignments);
      
      return ModelUtils.validateAssignments(remoteAssignments);
    } on ApiException {
      // If remote fails, try to return cached data
      try {
        final cachedAssignments = await _localDataSource.getCachedAssignmentsForCourse(courseId);
        return ModelUtils.validateAssignments(cachedAssignments);
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignments for course $courseId: ${e.toString()}',
      );
    }
  }

  @override
  Future<Assignment?> getAssignment(int assignmentId, {bool forceRefresh = false}) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await _localDataSource.isCacheExpired()) {
        final cachedAssignment = await _localDataSource.getCachedAssignment(assignmentId);
        if (cachedAssignment != null && cachedAssignment.isValid()) {
          return cachedAssignment;
        }
      }

      // For Canvas API, we need to fetch all assignments to find the specific one
      // This is not efficient but Canvas API requires course context
      final allAssignments = await getAssignments(forceRefresh: forceRefresh);
      return allAssignments.where((assignment) => assignment.id == assignmentId).firstOrNull;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignment $assignmentId: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getAssignmentsDueSoon({
    Duration threshold = const Duration(days: 7),
    bool forceRefresh = false,
  }) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      return ModelUtils.filterAssignmentsDueSoon(assignments, threshold: threshold);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignments due soon: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getOverdueAssignments({bool forceRefresh = false}) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      return ModelUtils.filterOverdueAssignments(assignments);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get overdue assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getAvailableAssignments({bool forceRefresh = false}) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      return ModelUtils.filterAvailableAssignments(assignments);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get available assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getSubmittedAssignments({bool forceRefresh = false}) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      return assignments.where((assignment) => assignment.isSubmitted).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get submitted assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> searchAssignments(
    String query, {
    bool forceRefresh = false,
  }) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      final lowercaseQuery = query.toLowerCase();
      
      return assignments.where((assignment) {
        return assignment.name.toLowerCase().contains(lowercaseQuery) ||
               (assignment.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to search assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<int, List<Assignment>>> getAssignmentsGroupedByCourse({
    bool forceRefresh = false,
  }) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      return ModelUtils.groupAssignmentsByCourse(assignments);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignments grouped by course: ${e.toString()}',
      );
    }
  }

  @override
  Future<AssignmentStatistics> getAssignmentStatistics({
    bool forceRefresh = false,
  }) async {
    try {
      final assignments = await getAssignments(forceRefresh: forceRefresh);
      return ModelUtils.calculateAssignmentStatistics(assignments);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get assignment statistics: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> refreshAssignments() async {
    try {
      await getAssignments(forceRefresh: true);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to refresh assignments: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> refreshAssignmentsForCourse(int courseId) async {
    try {
      await getAssignmentsForCourse(courseId, forceRefresh: true);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to refresh assignments for course $courseId: ${e.toString()}',
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
  Future<void> clearCacheForCourse(int courseId) async {
    try {
      await _localDataSource.clearCacheForCourse(courseId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to clear cache for course $courseId: ${e.toString()}',
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
  Future<void> markAssignmentAsRead(int assignmentId) async {
    try {
      await _localDataSource.markAssignmentAsRead(assignmentId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to mark assignment $assignmentId as read: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> getUnreadAssignmentsCount() async {
    try {
      final assignments = await getAssignments();
      final readIds = await _localDataSource.getReadAssignmentIds();
      
      return assignments
          .where((assignment) => !readIds.contains(assignment.id))
          .length;
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to get unread assignments count: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> syncAssignmentWithCalendar(int assignmentId) async {
    try {
      // This will be implemented when calendar integration is added
      // For now, just mark as read to indicate user interaction
      await markAssignmentAsRead(assignmentId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to sync assignment $assignmentId with calendar: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> removeAssignmentFromCalendar(int assignmentId) async {
    try {
      // This will be implemented when calendar integration is added
      // For now, this is a no-op
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to remove assignment $assignmentId from calendar: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Assignment>> getAllAssignments({bool forceRefresh = false}) async {
    return getAssignments(forceRefresh: forceRefresh);
  }

  @override
  Future<void> saveAssignment(Assignment assignment) async {
    try {
      await _localDataSource.cacheAssignment(assignment);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to save assignment ${assignment.id}: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteAssignment(int assignmentId) async {
    try {
      await _localDataSource.deleteAssignment(assignmentId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to delete assignment $assignmentId: ${e.toString()}',
      );
    }
  }
}