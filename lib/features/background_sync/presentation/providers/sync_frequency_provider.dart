import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kpass/features/background_sync/domain/services/sync_frequency_manager.dart';
import 'package:kpass/features/background_sync/presentation/providers/background_sync_provider.dart';

/// Provider for managing sync frequency settings and monitoring
class SyncFrequencyProvider extends ChangeNotifier {
  final SyncFrequencyManager _frequencyManager;
  final BackgroundSyncProvider _backgroundSyncProvider;
  
  bool _isLoading = false;
  String? _error;
  SyncStatistics? _statistics;
  SyncFrequencyRecommendation? _recommendation;
  List<SyncRecord> _recentHistory = [];

  SyncFrequencyProvider(
    this._frequencyManager,
    this._backgroundSyncProvider,
  );

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  SyncStatistics? get statistics => _statistics;
  SyncFrequencyRecommendation? get recommendation => _recommendation;
  List<SyncRecord> get recentHistory => _recentHistory;

  /// Available sync intervals
  List<Duration> get availableIntervals => SyncFrequencyManager.availableIntervals;

  /// Current sync interval
  Duration get currentInterval => _frequencyManager.currentInterval;

  /// Adaptive frequency enabled
  bool get isAdaptiveFrequencyEnabled => _frequencyManager.isAdaptiveFrequencyEnabled;

  /// Battery optimized sync enabled
  bool get isBatteryOptimizedSyncEnabled => _frequencyManager.isBatteryOptimizedSyncEnabled;

  /// WiFi-only sync enabled
  bool get isWifiOnlySyncEnabled => _frequencyManager.isWifiOnlySyncEnabled;

  /// Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all data
  Future<void> _loadData() async {
    await Future.wait([
      _loadStatistics(),
      _loadRecommendation(),
      _loadRecentHistory(),
    ]);
  }

  /// Load sync statistics
  Future<void> _loadStatistics() async {
    try {
      _statistics = await _frequencyManager.getSyncStatistics();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sync statistics: $e');
      }
    }
  }

  /// Load frequency recommendation
  Future<void> _loadRecommendation() async {
    try {
      _recommendation = await _frequencyManager.getFrequencyRecommendation();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading frequency recommendation: $e');
      }
    }
  }

  /// Load recent sync history
  Future<void> _loadRecentHistory() async {
    try {
      _recentHistory = await _frequencyManager.getSyncHistory(limit: 20);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent history: $e');
      }
    }
  }

  /// Set sync interval
  Future<void> setSyncInterval(Duration interval) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _frequencyManager.setSyncInterval(interval);
      
      // Update background sync provider if it's enabled
      if (_backgroundSyncProvider.isEnabled) {
        await _backgroundSyncProvider.updateSyncInterval(interval);
      }
      
      await _loadRecommendation();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle adaptive frequency
  Future<void> toggleAdaptiveFrequency(bool enabled) async {
    try {
      await _frequencyManager.setAdaptiveFrequency(enabled);
      await _loadRecommendation();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle battery optimized sync
  Future<void> toggleBatteryOptimizedSync(bool enabled) async {
    try {
      await _frequencyManager.setBatteryOptimizedSync(enabled);
      await _loadRecommendation();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle WiFi-only sync
  Future<void> toggleWifiOnlySync(bool enabled) async {
    try {
      await _frequencyManager.setWifiOnlySync(enabled);
      await _loadRecommendation();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Apply recommended frequency
  Future<void> applyRecommendedFrequency() async {
    if (_recommendation?.shouldChange == true) {
      await setSyncInterval(_recommendation!.recommendedInterval);
    }
  }

  /// Check if sync should be performed now
  Future<bool> shouldSyncNow() async {
    try {
      return await _frequencyManager.shouldSyncNow();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get next sync time
  Future<DateTime> getNextSyncTime() async {
    try {
      return await _frequencyManager.getNextSyncTime();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return DateTime.now().add(currentInterval);
    }
  }

  /// Get adapted sync interval
  Future<Duration> getAdaptedSyncInterval() async {
    try {
      return await _frequencyManager.getAdaptedSyncInterval();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return currentInterval;
    }
  }

  /// Record sync completion
  Future<void> recordSyncCompletion({
    required bool success,
    Duration? duration,
    String? error,
  }) async {
    try {
      await _frequencyManager.recordSyncCompletion(
        success: success,
        duration: duration,
        error: error,
      );
      
      // Reload data to reflect the new sync
      await _loadData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear sync history
  Future<void> clearSyncHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _frequencyManager.clearSyncHistory();
      await _loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _frequencyManager.resetToDefaults();
      await _loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  /// Get sync status summary
  Map<String, dynamic> getSyncStatusSummary() {
    return {
      'current_interval': getSyncIntervalText(currentInterval),
      'adaptive_frequency': isAdaptiveFrequencyEnabled,
      'battery_optimized': isBatteryOptimizedSyncEnabled,
      'wifi_only': isWifiOnlySyncEnabled,
      'total_syncs': _statistics?.totalSyncs ?? 0,
      'success_rate': _statistics?.successRate ?? 0.0,
      'last_sync': _statistics?.lastSyncTime?.toIso8601String(),
      'recommendation_available': _recommendation?.shouldChange ?? false,
      'recommended_interval': _recommendation?.shouldChange == true
          ? getSyncIntervalText(_recommendation!.recommendedInterval)
          : null,
    };
  }

  /// Get battery and connectivity status
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final battery = Battery();
      final connectivity = Connectivity();
      
      final batteryLevel = await battery.batteryLevel;
      final batteryState = await battery.batteryState;
      final connectivityResult = await connectivity.checkConnectivity();
      
      return {
        'battery_level': batteryLevel,
        'battery_state': batteryState.toString(),
        'connectivity': connectivityResult.toString(),
        'can_sync_now': await shouldSyncNow(),
        'next_sync': (await getNextSyncTime()).toIso8601String(),
        'adapted_interval': getSyncIntervalText(await getAdaptedSyncInterval()),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Factory method to create provider with dependencies
  static Future<SyncFrequencyProvider> create(
    BackgroundSyncProvider backgroundSyncProvider,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = Connectivity();
    final battery = Battery();
    final deviceInfo = DeviceInfoPlugin();
    
    final frequencyManager = SyncFrequencyManager(
      prefs: prefs,
      connectivity: connectivity,
      battery: battery,
      deviceInfo: deviceInfo,
    );
    
    return SyncFrequencyProvider(frequencyManager, backgroundSyncProvider);
  }
}