import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/background_task_service.dart';

/// Provider for managing background synchronization settings and status
class BackgroundSyncProvider extends ChangeNotifier {
  final BackgroundTaskService _backgroundTaskService;
  
  bool _isEnabled = false;
  Duration _syncInterval = const Duration(hours: 1);
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _status = {};
  bool _batteryOptimizationDisabled = false;
  DateTime? _lastSync;
  
  BackgroundSyncProvider(this._backgroundTaskService);
  
  // Getters
  bool get isEnabled => _isEnabled;
  Duration get syncInterval => _syncInterval;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get status => _status;
  bool get batteryOptimizationDisabled => _batteryOptimizationDisabled;
  DateTime? get lastSync => _lastSync;
  
  /// Available sync interval options
  List<Duration> get availableSyncIntervals => [
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 6),
    const Duration(hours: 24),
  ];
  
  /// Get sync interval display text
  String getSyncIntervalText(Duration interval) {
    if (interval.inMinutes < 60) {
      return '${interval.inMinutes} minutes';
    } else if (interval.inHours < 24) {
      return '${interval.inHours} hour${interval.inHours == 1 ? '' : 's'}';
    } else {
      final days = interval.inDays;
      return '$days day${days == 1 ? '' : 's'}';
    }
  }
  
  /// Initialize background sync provider
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _backgroundTaskService.initialize(
        onBackgroundSync: _handleBackgroundSync,
      );
      
      await _loadStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load current background sync status
  Future<void> _loadStatus() async {
    try {
      _status = await _backgroundTaskService.getBackgroundSyncStatus();
      _isEnabled = _status['is_enabled'] ?? false;
      _batteryOptimizationDisabled = _status['battery_optimization_disabled'] ?? false;
      
      final syncIntervalMinutes = _status['sync_interval_minutes'] ?? 60;
      _syncInterval = Duration(minutes: syncIntervalMinutes);
      
      final lastSyncString = _status['last_sync'];
      if (lastSyncString != null) {
        _lastSync = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      throw BackgroundTaskException(
        message: 'Failed to load background sync status: ${e.toString()}',
        code: 'STATUS_LOAD_FAILED',
      );
    }
  }
  
  /// Enable background synchronization
  Future<void> enableBackgroundSync({
    Duration? interval,
    bool requiresNetworkConnectivity = true,
    bool requiresBatteryNotLow = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final syncInterval = interval ?? _syncInterval;
      
      await _backgroundTaskService.registerBackgroundSync(
        interval: syncInterval,
        requiresNetworkConnectivity: requiresNetworkConnectivity,
        requiresBatteryNotLow: requiresBatteryNotLow,
      );
      
      _isEnabled = true;
      _syncInterval = syncInterval;
      
      await _loadStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Disable background synchronization
  Future<void> disableBackgroundSync() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _backgroundTaskService.cancelBackgroundSync();
      _isEnabled = false;
      
      await _loadStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update sync interval
  Future<void> updateSyncInterval(Duration newInterval) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_isEnabled) {
        await _backgroundTaskService.updateSyncInterval(newInterval);
      }
      
      _syncInterval = newInterval;
      await _loadStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record sync completion for frequency management
  Future<void> recordSyncCompletion({
    required bool success,
    Duration? duration,
    String? error,
  }) async {
    try {
      // This method can be called by the sync frequency provider
      // to record sync results for adaptive frequency management
      if (kDebugMode) {
        print('Sync completion recorded: success=$success, duration=$duration');
      }
      
      await _loadStatus();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Perform immediate sync for testing
  Future<void> performImmediateSync() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _backgroundTaskService.performImmediateSync();
      await _loadStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Check network connectivity
  Future<bool> checkNetworkConnectivity() async {
    try {
      return await _backgroundTaskService.hasNetworkConnectivity();
    } catch (e) {
      return false;
    }
  }
  
  /// Mark battery optimization as disabled
  Future<void> markBatteryOptimizationDisabled() async {
    try {
      await _backgroundTaskService.markBatteryOptimizationDisabled();
      _batteryOptimizationDisabled = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Get battery optimization guidance
  String getBatteryOptimizationGuidance() {
    return _backgroundTaskService.getBatteryOptimizationGuidance();
  }
  
  /// Get time since last sync
  Future<String?> getTimeSinceLastSyncText() async {
    try {
      final timeSinceLastSync = await _backgroundTaskService.getTimeSinceLastSync();
      if (timeSinceLastSync == null) return null;
      
      if (timeSinceLastSync.inDays > 0) {
        return '${timeSinceLastSync.inDays} day${timeSinceLastSync.inDays == 1 ? '' : 's'} ago';
      } else if (timeSinceLastSync.inHours > 0) {
        return '${timeSinceLastSync.inHours} hour${timeSinceLastSync.inHours == 1 ? '' : 's'} ago';
      } else if (timeSinceLastSync.inMinutes > 0) {
        return '${timeSinceLastSync.inMinutes} minute${timeSinceLastSync.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Check if sync should be performed
  Future<bool> shouldPerformSync() async {
    try {
      return await _backgroundTaskService.shouldPerformSync();
    } catch (e) {
      return false;
    }
  }
  
  /// Handle background sync callback
  Future<void> _handleBackgroundSync(String taskId) async {
    try {
      if (kDebugMode) {
        print('Background sync triggered: $taskId');
      }
      
      // This will be implemented in task 8.2
      // For now, just record the sync attempt
      await _backgroundTaskService.recordSyncSuccess();
      
      // Update status
      await _loadStatus();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Refresh status
  Future<void> refreshStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Get sync status summary
  Map<String, dynamic> getSyncStatusSummary() {
    return {
      'is_enabled': _isEnabled,
      'sync_interval': getSyncIntervalText(_syncInterval),
      'last_sync': _lastSync?.toIso8601String(),
      'battery_optimization_disabled': _batteryOptimizationDisabled,
      'platform': _status['platform'],
      'has_error': _error != null,
      'error': _error,
    };
  }
  
  /// Validate sync interval
  bool isValidSyncInterval(Duration interval) {
    // Minimum 15 minutes, maximum 24 hours
    return interval.inMinutes >= 15 && interval.inHours <= 24;
  }
  
  /// Get recommended sync interval based on usage
  Duration getRecommendedSyncInterval() {
    // Default to 1 hour for balanced performance and battery usage
    return const Duration(hours: 1);
  }
  
  /// Check if background sync is supported on current platform
  bool get isBackgroundSyncSupported {
    return _status['workmanager_available'] == true || 
           _status['background_fetch_status'] != null;
  }
  
  @override
  void dispose() {
    _backgroundTaskService.dispose();
    super.dispose();
  }
}