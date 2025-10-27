import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:background_fetch/background_fetch.dart' as bg_fetch;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kpass/features/background_sync/domain/services/background_sync_coordinator.dart';

/// Service for managing background tasks across iOS and Android platforms
class BackgroundTaskService {
  static const String _syncTaskName = 'kpass_background_sync';
  static const String _lastSyncKey = 'last_background_sync';
  static const String _syncIntervalKey = 'background_sync_interval';
  static const String _batteryOptimizationKey = 'battery_optimization_disabled';
  
  bool _isInitialized = false;
  Function(String)? _onBackgroundSync;
  
  /// Initialize background task service
  Future<void> initialize({
    Function(String)? onBackgroundSync,
  }) async {
    if (_isInitialized) return;
    
    try {
      _onBackgroundSync = onBackgroundSync;
      
      if (Platform.isAndroid) {
        await _initializeWorkManager();
      } else if (Platform.isIOS) {
        await _initializeBackgroundFetch();
      }
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('BackgroundTaskService initialized for ${Platform.operatingSystem}');
      }
    } catch (e) {
      throw BackgroundTaskException(
        message: 'Failed to initialize background task service: ${e.toString()}',
        code: 'BACKGROUND_INIT_FAILED',
      );
    }
  }
  
  /// Initialize WorkManager for Android
  Future<void> _initializeWorkManager() async {
    await Workmanager().initialize(
      _workManagerCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    if (kDebugMode) {
      print('WorkManager initialized successfully');
    }
  }
  
  /// Initialize BackgroundFetch for iOS
  Future<void> _initializeBackgroundFetch() async {
    // Configure BackgroundFetch
    final status = await bg_fetch.BackgroundFetch.configure(
      bg_fetch.BackgroundFetchConfig(
        minimumFetchInterval: 15, // 15 minutes minimum
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: bg_fetch.NetworkType.ANY,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
      ),
      _backgroundFetchHeadlessTask,
      _backgroundFetchTimeout,
    );
    
    if (kDebugMode) {
      print('BackgroundFetch configured with status: $status');
    }
  }
  
  /// Register periodic background sync task
  Future<void> registerBackgroundSync({
    Duration interval = const Duration(hours: 1),
    bool requiresNetworkConnectivity = true,
    bool requiresBatteryNotLow = false,
  }) async {
    if (!_isInitialized) {
      throw BackgroundTaskException(
        message: 'Background task service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }
    
    try {
      // Store sync interval preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_syncIntervalKey, interval.inMinutes);
      
      if (Platform.isAndroid) {
        await _registerAndroidBackgroundSync(
          interval: interval,
          requiresNetworkConnectivity: requiresNetworkConnectivity,
          requiresBatteryNotLow: requiresBatteryNotLow,
        );
      } else if (Platform.isIOS) {
        await _registerIOSBackgroundSync(interval: interval);
      }
      
      if (kDebugMode) {
        print('Background sync registered with ${interval.inMinutes} minute interval');
      }
    } catch (e) {
      throw BackgroundTaskException(
        message: 'Failed to register background sync: ${e.toString()}',
        code: 'REGISTER_FAILED',
      );
    }
  }
  
  /// Register Android background sync using WorkManager
  Future<void> _registerAndroidBackgroundSync({
    required Duration interval,
    required bool requiresNetworkConnectivity,
    required bool requiresBatteryNotLow,
  }) async {
    // Cancel existing tasks first
    await Workmanager().cancelByUniqueName(_syncTaskName);
    
    // Register periodic task
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskName,
      frequency: interval,
      constraints: Constraints(
        networkType: requiresNetworkConnectivity 
            ? NetworkType.connected 
            : NetworkType.not_required,
        requiresBatteryNotLow: requiresBatteryNotLow,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
      ),
      inputData: {
        'sync_type': 'periodic',
        'interval_minutes': interval.inMinutes,
      },
    );
  }
  
  /// Register iOS background sync using BackgroundFetch
  Future<void> _registerIOSBackgroundSync({
    required Duration interval,
  }) async {
    // Start background fetch
    await bg_fetch.BackgroundFetch.start();
    
    if (kDebugMode) {
      print('iOS background fetch started with ${interval.inMinutes} minute interval');
    }
  }
  
  /// Cancel background sync tasks
  Future<void> cancelBackgroundSync() async {
    try {
      if (Platform.isAndroid) {
        await Workmanager().cancelByUniqueName(_syncTaskName);
      } else if (Platform.isIOS) {
        await bg_fetch.BackgroundFetch.stop();
      }
      
      if (kDebugMode) {
        print('Background sync cancelled');
      }
    } catch (e) {
      throw BackgroundTaskException(
        message: 'Failed to cancel background sync: ${e.toString()}',
        code: 'CANCEL_FAILED',
      );
    }
  }
  
  /// Check if background tasks are enabled and working
  Future<bool> isBackgroundSyncEnabled() async {
    try {
      if (Platform.isAndroid) {
        // Check if WorkManager tasks are registered
        // Note: WorkManager doesn't provide a direct way to check this
        // We'll use SharedPreferences to track registration state
        final prefs = await SharedPreferences.getInstance();
        return prefs.containsKey(_syncIntervalKey);
      } else if (Platform.isIOS) {
        final status = await bg_fetch.BackgroundFetch.status;
        // BackgroundFetch.status returns an int:
        // 0: restricted, 1: denied, 2: available
        return status == 2;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get background sync status information
  Future<Map<String, dynamic>> getBackgroundSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);
      final syncInterval = prefs.getInt(_syncIntervalKey) ?? 60;
      final batteryOptimizationDisabled = prefs.getBool(_batteryOptimizationKey) ?? false;
      
      Map<String, dynamic> status = {
        'is_enabled': await isBackgroundSyncEnabled(),
        'last_sync': lastSync,
        'sync_interval_minutes': syncInterval,
        'battery_optimization_disabled': batteryOptimizationDisabled,
        'platform': Platform.operatingSystem,
      };
      
      if (Platform.isAndroid) {
        status['workmanager_available'] = true;
      } else if (Platform.isIOS) {
        final fetchStatus = await bg_fetch.BackgroundFetch.status;
        status['background_fetch_status'] = fetchStatus.toString();
      }
      
      return status;
    } catch (e) {
      return {
        'error': e.toString(),
        'is_enabled': false,
      };
    }
  }
  
  /// Update sync interval
  Future<void> updateSyncInterval(Duration newInterval) async {
    if (!_isInitialized) {
      throw BackgroundTaskException(
        message: 'Background task service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }
    
    // Re-register with new interval
    await registerBackgroundSync(interval: newInterval);
  }
  
  /// Check network connectivity before sync
  Future<bool> hasNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  /// Record successful sync
  Future<void> recordSyncSuccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Failed to record sync success: $e');
      }
    }
  }
  
  /// Get time since last sync
  Future<Duration?> getTimeSinceLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      
      if (lastSyncString != null) {
        final lastSync = DateTime.parse(lastSyncString);
        return DateTime.now().difference(lastSync);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Check if it's time for next sync based on interval
  Future<bool> shouldPerformSync() async {
    try {
      final timeSinceLastSync = await getTimeSinceLastSync();
      if (timeSinceLastSync == null) return true; // First sync
      
      final prefs = await SharedPreferences.getInstance();
      final syncIntervalMinutes = prefs.getInt(_syncIntervalKey) ?? 60;
      final syncInterval = Duration(minutes: syncIntervalMinutes);
      
      return timeSinceLastSync >= syncInterval;
    } catch (e) {
      return true; // Default to allowing sync on error
    }
  }
  
  /// Perform immediate background sync (for testing)
  Future<void> performImmediateSync() async {
    if (!_isInitialized) {
      throw BackgroundTaskException(
        message: 'Background task service not initialized',
        code: 'NOT_INITIALIZED',
      );
    }
    
    try {
      if (_onBackgroundSync != null) {
        await _onBackgroundSync!('immediate_sync');
      }
      await recordSyncSuccess();
    } catch (e) {
      throw BackgroundTaskException(
        message: 'Failed to perform immediate sync: ${e.toString()}',
        code: 'IMMEDIATE_SYNC_FAILED',
      );
    }
  }
  
  /// Check battery optimization status (Android only)
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // This would require a platform channel to check actual battery optimization
      // For now, we'll use SharedPreferences to track user's manual setting
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_batteryOptimizationKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Mark battery optimization as disabled (user confirmation)
  Future<void> markBatteryOptimizationDisabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_batteryOptimizationKey, true);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to mark battery optimization as disabled: $e');
      }
    }
  }
  
  /// Get battery optimization guidance message
  String getBatteryOptimizationGuidance() {
    if (!Platform.isAndroid) {
      return 'Background sync is managed by iOS automatically.';
    }
    
    return 'For reliable background sync, please disable battery optimization for KPass in your device settings. '
           'Go to Settings > Battery > Battery Optimization > KPass > Don\'t optimize.';
  }
  
  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    _onBackgroundSync = null;
  }
}

/// WorkManager callback dispatcher for Android
@pragma('vm:entry-point')
void _workManagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        print('WorkManager task executed: $task with data: $inputData');
      }
      
      // Perform background sync logic here
      // This will be implemented in the next task (8.2)
      await _performBackgroundSyncTask(task, inputData);
      
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('WorkManager task failed: $e');
      }
      return Future.value(false);
    }
  });
}

/// Background fetch headless task for iOS
@pragma('vm:entry-point')
void _backgroundFetchHeadlessTask(bg_fetch.HeadlessTask task) async {
  try {
    final taskId = task.taskId;
    
    if (kDebugMode) {
      print('BackgroundFetch headless task executed: $taskId');
    }
    
    // Perform background sync logic here
    // This will be implemented in the next task (8.2)
    await _performBackgroundSyncTask(taskId, null);
    
    bg_fetch.BackgroundFetch.finish(taskId);
  } catch (e) {
    if (kDebugMode) {
      print('BackgroundFetch headless task failed: $e');
    }
    bg_fetch.BackgroundFetch.finish(task.taskId);
  }
}

/// Background fetch timeout handler for iOS
@pragma('vm:entry-point')
void _backgroundFetchTimeout(String taskId) {
  if (kDebugMode) {
    print('BackgroundFetch timeout: $taskId');
  }
  bg_fetch.BackgroundFetch.finish(taskId);
}

/// Perform background sync task logic
Future<void> _performBackgroundSyncTask(String taskId, Map<String, dynamic>? inputData) async {
  try {
    if (kDebugMode) {
      print('Performing background sync task: $taskId');
    }
    
    // Record sync attempt
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_background_sync', DateTime.now().toIso8601String());
    
    // Get the background sync coordinator
    final coordinator = await _getBackgroundSyncService() as BackgroundSyncCoordinator?;
    
    if (coordinator != null) {
      // Perform the actual sync
      final result = await coordinator.performSync();
      
      if (result.isSuccess) {
        if (kDebugMode) {
          print('Background sync completed successfully: $result');
        }
        
        // Record successful sync
        await prefs.setString('last_successful_sync', DateTime.now().toIso8601String());
        await prefs.setString('last_sync_result', result.toString());
      } else {
        if (kDebugMode) {
          print('Background sync failed: ${result.error}');
        }
        
        // Record failed sync
        await prefs.setString('last_sync_error', result.error ?? 'Unknown error');
      }
    } else {
      if (kDebugMode) {
        print('Background sync coordinator not available');
      }
    }
    
    if (kDebugMode) {
      print('Background sync task completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Background sync task failed: $e');
    }
    
    // Record error
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_error', e.toString());
    } catch (_) {
      // Ignore errors when recording errors
    }
    
    rethrow;
  }
}

/// Get background sync service instance
Future<dynamic> _getBackgroundSyncService() async {
  try {
    // Use the background sync coordinator
    final coordinator = BackgroundSyncCoordinator.instance;
    
    if (!coordinator.isReady) {
      await coordinator.initialize();
    }
    
    return coordinator;
  } catch (e) {
    if (kDebugMode) {
      print('Failed to get background sync service: $e');
    }
    return null;
  }
}

/// Custom exception for background task errors
class BackgroundTaskException implements Exception {
  final String message;
  final String code;
  
  const BackgroundTaskException({
    required this.message,
    required this.code,
  });
  
  @override
  String toString() => 'BackgroundTaskException($code): $message';
}