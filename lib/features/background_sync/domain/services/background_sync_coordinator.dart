import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kpass/features/background_sync/domain/services/background_sync_service.dart';
import 'package:kpass/features/courses/domain/repositories/courses_repository.dart';
import 'package:kpass/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:kpass/features/calendar/data/services/calendar_service.dart';
import 'package:kpass/features/notifications/presentation/providers/notification_provider.dart';
import 'package:kpass/core/errors/exceptions.dart';

/// Coordinator for managing background synchronization
class BackgroundSyncCoordinator {
  static BackgroundSyncCoordinator? _instance;
  BackgroundSyncService? _syncService;
  bool _isInitialized = false;

  BackgroundSyncCoordinator._();

  static BackgroundSyncCoordinator get instance {
    _instance ??= BackgroundSyncCoordinator._();
    return _instance!;
  }

  /// Initialize the background sync coordinator
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('Initializing BackgroundSyncCoordinator...');
      }

      // Initialize dependencies if not already done
      await _initializeDependencies();

      // Create the background sync service
      _syncService = BackgroundSyncService(
        coursesRepository: GetIt.instance<CoursesRepository>(),
        assignmentsRepository: GetIt.instance<AssignmentsRepository>(),
        calendarService: GetIt.instance<CalendarService>(),
        notificationProvider: GetIt.instance<NotificationProvider>(),
        connectivity: GetIt.instance<Connectivity>(),
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('BackgroundSyncCoordinator initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize BackgroundSyncCoordinator: $e');
      }
      throw BackgroundSyncException(
        message: 'Failed to initialize background sync coordinator: ${e.toString()}',
        code: 'COORDINATOR_INIT_FAILED',
      );
    }
  }

  /// Initialize dependencies if they're not already registered
  Future<void> _initializeDependencies() async {
    final getIt = GetIt.instance;

    // Register Connectivity if not already registered
    if (!getIt.isRegistered<Connectivity>()) {
      getIt.registerLazySingleton<Connectivity>(() => Connectivity());
    }

    // Note: Other dependencies should be registered during app initialization
    // This is just a fallback to ensure we have the basic dependencies
  }

  /// Perform background synchronization
  Future<BackgroundSyncResult> performSync({bool forceFullSync = false}) async {
    if (!_isInitialized) {
      throw BackgroundSyncException(
        message: 'Background sync coordinator not initialized',
        code: 'NOT_INITIALIZED',
      );
    }

    if (_syncService == null) {
      throw BackgroundSyncException(
        message: 'Background sync service not available',
        code: 'SERVICE_NOT_AVAILABLE',
      );
    }

    try {
      if (kDebugMode) {
        print('Starting background sync via coordinator...');
      }

      final result = await _syncService!.performBackgroundSync(
        forceFullSync: forceFullSync,
      );

      if (kDebugMode) {
        print('Background sync completed via coordinator: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Background sync failed via coordinator: $e');
      }
      rethrow;
    }
  }

  /// Check if the coordinator is ready for sync
  bool get isReady => _isInitialized && _syncService != null;

  /// Get sync service for direct access (if needed)
  BackgroundSyncService? get syncService => _syncService;

  /// Dispose resources
  void dispose() {
    _syncService = null;
    _isInitialized = false;
    if (kDebugMode) {
      print('BackgroundSyncCoordinator disposed');
    }
  }

  /// Reset the singleton instance (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Global function for background sync execution
/// This can be called from background tasks
Future<BackgroundSyncResult> executeBackgroundSync({
  bool forceFullSync = false,
}) async {
  try {
    final coordinator = BackgroundSyncCoordinator.instance;
    
    if (!coordinator.isReady) {
      await coordinator.initialize();
    }
    
    return await coordinator.performSync(forceFullSync: forceFullSync);
  } catch (e) {
    if (kDebugMode) {
      print('Global background sync execution failed: $e');
    }
    
    // Return a failed result instead of throwing
    return BackgroundSyncResult()
      ..isSuccess = false
      ..error = e.toString()
      ..completedAt = DateTime.now();
  }
}