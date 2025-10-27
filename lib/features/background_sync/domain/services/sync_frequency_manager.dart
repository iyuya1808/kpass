import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Manages sync frequency based on user preferences, battery status, and network conditions
class SyncFrequencyManager {
  static const String _syncIntervalKey = 'sync_frequency_interval';
  static const String _adaptiveFrequencyKey = 'adaptive_frequency_enabled';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncHistoryKey = 'sync_history';
  static const String _batteryOptimizedKey = 'battery_optimized_sync';
  static const String _wifiOnlyKey = 'wifi_only_sync';

  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  final Battery _battery;
  final DeviceInfoPlugin _deviceInfo;

  SyncFrequencyManager({
    required SharedPreferences prefs,
    required Connectivity connectivity,
    required Battery battery,
    required DeviceInfoPlugin deviceInfo,
  }) : _prefs = prefs,
       _connectivity = connectivity,
       _battery = battery,
       _deviceInfo = deviceInfo;

  /// Available sync intervals
  static const List<Duration> availableIntervals = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 6),
    Duration(hours: 24),
  ];

  /// Get current sync interval
  Duration get currentInterval {
    final minutes = _prefs.getInt(_syncIntervalKey) ?? 60; // Default 1 hour
    return Duration(minutes: minutes);
  }

  /// Set sync interval
  Future<void> setSyncInterval(Duration interval) async {
    if (!availableIntervals.contains(interval)) {
      throw ArgumentError('Invalid sync interval: $interval');
    }

    await _prefs.setInt(_syncIntervalKey, interval.inMinutes);

    if (kDebugMode) {
      print('Sync interval set to: ${_formatDuration(interval)}');
    }
  }

  /// Check if adaptive frequency is enabled
  bool get isAdaptiveFrequencyEnabled {
    return _prefs.getBool(_adaptiveFrequencyKey) ?? true;
  }

  /// Enable/disable adaptive frequency
  Future<void> setAdaptiveFrequency(bool enabled) async {
    await _prefs.setBool(_adaptiveFrequencyKey, enabled);
  }

  /// Check if battery optimized sync is enabled
  bool get isBatteryOptimizedSyncEnabled {
    return _prefs.getBool(_batteryOptimizedKey) ?? true;
  }

  /// Enable/disable battery optimized sync
  Future<void> setBatteryOptimizedSync(bool enabled) async {
    await _prefs.setBool(_batteryOptimizedKey, enabled);
  }

  /// Check if WiFi-only sync is enabled
  bool get isWifiOnlySyncEnabled {
    return _prefs.getBool(_wifiOnlyKey) ?? false;
  }

  /// Enable/disable WiFi-only sync
  Future<void> setWifiOnlySync(bool enabled) async {
    await _prefs.setBool(_wifiOnlyKey, enabled);
  }

  /// Get the next sync time based on current settings
  Future<DateTime> getNextSyncTime() async {
    final lastSync = await getLastSyncTime();
    final interval = await getAdaptedSyncInterval();

    return lastSync.add(interval);
  }

  /// Get adapted sync interval based on current conditions
  Future<Duration> getAdaptedSyncInterval() async {
    Duration baseInterval = currentInterval;

    if (!isAdaptiveFrequencyEnabled) {
      return baseInterval;
    }

    try {
      // Check battery level and charging status
      if (isBatteryOptimizedSyncEnabled) {
        final batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;

        // Reduce frequency on low battery
        if (batteryLevel < 20 && batteryState != BatteryState.charging) {
          baseInterval = Duration(
            minutes: (baseInterval.inMinutes * 2).toInt().clamp(15, 1440),
          );
          if (kDebugMode) {
            print(
              'Sync interval increased due to low battery: ${_formatDuration(baseInterval)}',
            );
          }
        }

        // Increase frequency when charging
        if (batteryState == BatteryState.charging && batteryLevel > 50) {
          baseInterval = Duration(
            minutes: (baseInterval.inMinutes / 1.5).toInt().clamp(15, 1440),
          );
          if (kDebugMode) {
            print(
              'Sync interval decreased due to charging: ${_formatDuration(baseInterval)}',
            );
          }
        }
      }

      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();

      // Reduce frequency on mobile data if WiFi-only is not enabled
      if (connectivityResult == ConnectivityResult.mobile &&
          !isWifiOnlySyncEnabled) {
        baseInterval = Duration(
          minutes: (baseInterval.inMinutes * 1.5).toInt().clamp(15, 1440),
        );
        if (kDebugMode) {
          print(
            'Sync interval increased due to mobile data: ${_formatDuration(baseInterval)}',
          );
        }
      }

      // Check device performance characteristics
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Reduce frequency on older devices (API level < 26)
        if (androidInfo.version.sdkInt < 26) {
          baseInterval = Duration(
            minutes: (baseInterval.inMinutes * 1.3).toInt().clamp(15, 1440),
          );
          if (kDebugMode) {
            print(
              'Sync interval increased due to older Android version: ${_formatDuration(baseInterval)}',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adapting sync interval: $e');
      }
      // Return base interval on error
    }

    return baseInterval;
  }

  /// Check if sync should be performed now
  Future<bool> shouldSyncNow() async {
    try {
      // Check network connectivity requirements
      if (!await _hasRequiredConnectivity()) {
        return false;
      }

      // Check battery requirements
      if (!await _meetsBatteryRequirements()) {
        return false;
      }

      // Check time-based requirements
      final nextSyncTime = await getNextSyncTime();
      final now = DateTime.now();

      return now.isAfter(nextSyncTime) || now.isAtSameMomentAs(nextSyncTime);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking sync conditions: $e');
      }
      return false;
    }
  }

  /// Check if required network connectivity is available
  Future<bool> _hasRequiredConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // If WiFi-only is enabled, only allow WiFi
      if (isWifiOnlySyncEnabled &&
          connectivityResult != ConnectivityResult.wifi) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if battery requirements are met
  Future<bool> _meetsBatteryRequirements() async {
    try {
      if (!isBatteryOptimizedSyncEnabled) {
        return true; // No battery restrictions
      }

      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      // Don't sync on very low battery unless charging
      if (batteryLevel < 10 && batteryState != BatteryState.charging) {
        return false;
      }

      return true;
    } catch (e) {
      return true; // Allow sync on error
    }
  }

  /// Record sync completion
  Future<void> recordSyncCompletion({
    required bool success,
    Duration? duration,
    String? error,
  }) async {
    final now = DateTime.now();

    // Update last sync time
    await _prefs.setString(_lastSyncKey, now.toIso8601String());

    // Update sync history
    await _updateSyncHistory(
      SyncRecord(
        timestamp: now,
        success: success,
        duration: duration,
        error: error,
      ),
    );

    if (kDebugMode) {
      print('Sync completion recorded: success=$success, duration=$duration');
    }
  }

  /// Get last sync time
  Future<DateTime> getLastSyncTime() async {
    final lastSyncString = _prefs.getString(_lastSyncKey);
    if (lastSyncString != null) {
      try {
        return DateTime.parse(lastSyncString);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing last sync time: $e');
        }
      }
    }

    // Return a time in the past to trigger immediate sync
    return DateTime.now().subtract(const Duration(days: 1));
  }

  /// Get sync history
  Future<List<SyncRecord>> getSyncHistory({int? limit}) async {
    try {
      final historyJson = _prefs.getString(_syncHistoryKey);
      if (historyJson == null) return [];

      final historyList =
          (historyJson.split('|'))
              .where((entry) => entry.isNotEmpty)
              .map((entry) => SyncRecord.fromString(entry))
              .where((record) => record != null)
              .cast<SyncRecord>()
              .toList();

      // Sort by timestamp (newest first)
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (limit != null && historyList.length > limit) {
        return historyList.take(limit).toList();
      }

      return historyList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sync history: $e');
      }
      return [];
    }
  }

  /// Update sync history
  Future<void> _updateSyncHistory(SyncRecord record) async {
    try {
      final history = await getSyncHistory(limit: 99); // Keep last 99 records
      history.insert(0, record); // Add new record at the beginning

      final historyString = history.map((r) => r.toString()).join('|');

      await _prefs.setString(_syncHistoryKey, historyString);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating sync history: $e');
      }
    }
  }

  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics() async {
    final history = await getSyncHistory();
    final now = DateTime.now();

    // Last 24 hours
    final last24Hours =
        history
            .where((r) => now.difference(r.timestamp).inHours <= 24)
            .toList();

    // Last 7 days
    final last7Days =
        history.where((r) => now.difference(r.timestamp).inDays <= 7).toList();

    // Success rates
    final totalSyncs = history.length;
    final successfulSyncs = history.where((r) => r.success).length;
    final successRate = totalSyncs > 0 ? successfulSyncs / totalSyncs : 0.0;

    final last24HoursSuccessRate =
        last24Hours.isNotEmpty
            ? last24Hours.where((r) => r.success).length / last24Hours.length
            : 0.0;

    // Average duration
    final durationsWithValues =
        history
            .where((r) => r.duration != null)
            .map((r) => r.duration!)
            .toList();

    final averageDuration =
        durationsWithValues.isNotEmpty
            ? Duration(
              milliseconds:
                  durationsWithValues
                      .map((d) => d.inMilliseconds)
                      .reduce((a, b) => a + b) ~/
                  durationsWithValues.length,
            )
            : Duration.zero;

    return SyncStatistics(
      totalSyncs: totalSyncs,
      successfulSyncs: successfulSyncs,
      successRate: successRate,
      last24HoursSuccessRate: last24HoursSuccessRate,
      averageDuration: averageDuration,
      lastSyncTime: history.isNotEmpty ? history.first.timestamp : null,
      syncsLast24Hours: last24Hours.length,
      syncsLast7Days: last7Days.length,
    );
  }

  /// Get sync frequency recommendations
  Future<SyncFrequencyRecommendation> getFrequencyRecommendation() async {
    final stats = await getSyncStatistics();
    final batteryLevel = await _battery.batteryLevel;
    final connectivityResult = await _connectivity.checkConnectivity();

    Duration recommendedInterval = currentInterval;
    String reason = 'Current setting';

    // Recommend based on success rate
    if (stats.successRate < 0.7) {
      recommendedInterval = Duration(
        minutes: (currentInterval.inMinutes * 1.5).toInt().clamp(15, 1440),
      );
      reason = 'Low success rate detected';
    } else if (stats.successRate > 0.95 &&
        stats.averageDuration.inSeconds < 30) {
      recommendedInterval = Duration(
        minutes: (currentInterval.inMinutes / 1.2).toInt().clamp(15, 1440),
      );
      reason = 'High success rate with fast syncs';
    }

    // Adjust for battery
    if (batteryLevel < 30) {
      recommendedInterval = Duration(
        minutes: (recommendedInterval.inMinutes * 1.3).toInt().clamp(15, 1440),
      );
      reason = 'Low battery level';
    }

    // Adjust for connectivity
    if (connectivityResult == ConnectivityResult.mobile) {
      recommendedInterval = Duration(
        minutes: (recommendedInterval.inMinutes * 1.2).toInt().clamp(15, 1440),
      );
      reason = 'Mobile data connection';
    }

    return SyncFrequencyRecommendation(
      recommendedInterval: recommendedInterval,
      currentInterval: currentInterval,
      reason: reason,
      batteryLevel: batteryLevel,
      connectivityType: connectivityResult,
      successRate: stats.successRate,
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else {
      final days = duration.inDays;
      return '$days day${days == 1 ? '' : 's'}';
    }
  }

  /// Clear sync history
  Future<void> clearSyncHistory() async {
    await _prefs.remove(_syncHistoryKey);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await _prefs.remove(_syncIntervalKey);
    await _prefs.remove(_adaptiveFrequencyKey);
    await _prefs.remove(_batteryOptimizedKey);
    await _prefs.remove(_wifiOnlyKey);
  }
}

/// Represents a sync record
class SyncRecord {
  final DateTime timestamp;
  final bool success;
  final Duration? duration;
  final String? error;

  const SyncRecord({
    required this.timestamp,
    required this.success,
    this.duration,
    this.error,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()},$success,${duration?.inMilliseconds ?? ''},${error ?? ''}';
  }

  static SyncRecord? fromString(String str) {
    try {
      final parts = str.split(',');
      if (parts.length >= 2) {
        return SyncRecord(
          timestamp: DateTime.parse(parts[0]),
          success: parts[1] == 'true',
          duration:
              parts.length > 2 && parts[2].isNotEmpty
                  ? Duration(milliseconds: int.parse(parts[2]))
                  : null,
          error: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing sync record: $e');
      }
    }
    return null;
  }
}

/// Sync statistics
class SyncStatistics {
  final int totalSyncs;
  final int successfulSyncs;
  final double successRate;
  final double last24HoursSuccessRate;
  final Duration averageDuration;
  final DateTime? lastSyncTime;
  final int syncsLast24Hours;
  final int syncsLast7Days;

  const SyncStatistics({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.successRate,
    required this.last24HoursSuccessRate,
    required this.averageDuration,
    this.lastSyncTime,
    required this.syncsLast24Hours,
    required this.syncsLast7Days,
  });
}

/// Sync frequency recommendation
class SyncFrequencyRecommendation {
  final Duration recommendedInterval;
  final Duration currentInterval;
  final String reason;
  final int batteryLevel;
  final ConnectivityResult connectivityType;
  final double successRate;

  const SyncFrequencyRecommendation({
    required this.recommendedInterval,
    required this.currentInterval,
    required this.reason,
    required this.batteryLevel,
    required this.connectivityType,
    required this.successRate,
  });

  bool get shouldChange => recommendedInterval != currentInterval;
}
