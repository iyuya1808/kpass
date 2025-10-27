import 'package:kpass/core/constants/campus_constants.dart';

/// Utility class for calculating university class periods from time
class PeriodCalculator {
  // デフォルトの時限表（日吉キャンパス）
  static Map<int, PeriodTime> get _defaultPeriodTimes =>
      Map<int, PeriodTime>.from(CampusPeriodSchedule.hiyoshiPeriods);

  /// 現在のキャンパス設定（デフォルトは日吉）
  static KeioCampus _currentCampus = KeioCampus.hiyoshi;

  /// キャンパスを設定
  static void setCampus(KeioCampus campus) {
    _currentCampus = campus;
  }

  /// 現在のキャンパスを取得
  static KeioCampus get currentCampus => _currentCampus;

  /// 現在のキャンパスの時限表を取得
  static Map<int, PeriodTime> get _periodTimes {
    final schedule = CampusPeriodSchedule.getScheduleForCampus(_currentCampus);
    if (schedule != null) {
      return Map<int, PeriodTime>.from(schedule);
    }
    return _defaultPeriodTimes;
  }

  /// Calculate period number from a given time
  /// Returns the closest period number, or null if no period matches
  static int? getPeriodFromTime(DateTime time) {
    final timeOfDay = TimeOfDay.fromDateTime(time);

    // Find the closest period by checking which period the time falls into
    for (final entry in _periodTimes.entries) {
      final periodTime = entry.value;
      if (_isTimeInPeriod(timeOfDay, periodTime)) {
        return entry.key;
      }
    }

    // If no exact match, find the closest period
    int? closestPeriod;
    int minDifference = 999999; // Large number

    for (final entry in _periodTimes.entries) {
      final periodTime = entry.value;
      final periodStart = _parseTime(periodTime.start);
      final difference = _timeDifference(timeOfDay, periodStart).abs();

      if (difference < minDifference) {
        minDifference = difference;
        closestPeriod = entry.key;
      }
    }

    return closestPeriod;
  }

  /// Get period label (e.g., "1限", "2限")
  static String getPeriodLabel(int period) {
    return '$period限';
  }

  /// Get period time range string (e.g., "09:00-10:30")
  static String getPeriodTimeRange(int period) {
    final periodTime = _periodTimes[period];
    if (periodTime == null) return '';
    return '${periodTime.start}-${periodTime.end}';
  }

  /// Get full period display string (e.g., "1限 (09:00-10:30)")
  static String getPeriodDisplay(int period) {
    final label = getPeriodLabel(period);
    final timeRange = getPeriodTimeRange(period);
    return '$label ($timeRange)';
  }

  /// Check if a time falls within a period
  static bool _isTimeInPeriod(TimeOfDay time, PeriodTime period) {
    final start = _parseTime(period.start);
    final end = _parseTime(period.end);

    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// Parse time string (HH:MM) to TimeOfDay
  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Calculate time difference in minutes
  static int _timeDifference(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 - minutes2;
  }

  /// Get all available periods
  static List<int> getAllPeriods() {
    return _periodTimes.keys.toList()..sort();
  }

  /// Check if a period number is valid
  static bool isValidPeriod(int period) {
    return _periodTimes.containsKey(period);
  }

  /// Get or create period time for any period number
  /// If the period doesn't exist in the predefined list, it will be calculated
  static PeriodTime? getPeriodTime(int period) {
    // 既存の時限がある場合はそれを返す
    if (_periodTimes.containsKey(period)) {
      return _periodTimes[period];
    }

    // 既存の時限がない場合は、標準的な時間間隔で計算
    if (period >= 1 && period <= 7) {
      // 最大7限まで対応
      return _calculatePeriodTime(period);
    }

    return null;
  }

  /// Calculate period time for periods not in the predefined list
  static PeriodTime? _calculatePeriodTime(int period) {
    // 慶應義塾大学の実際の時限に基づく計算
    const classDurationMinutes = 90; // 90分授業

    // 各時限の開始時間（分単位）
    const periodStartMinutes = {
      1: 9 * 60, // 09:00
      2: 10 * 60 + 45, // 10:45
      3: 13 * 60, // 13:00 (昼休み後)
      4: 14 * 60 + 45, // 14:45
      5: 16 * 60 + 30, // 16:30
      6: 18 * 60 + 15, // 18:15
      7: 20 * 60, // 20:00
    };

    final startMinutes = periodStartMinutes[period];
    if (startMinutes == null) {
      // 定義されていない時限の場合はnullを返す
      return null;
    }

    final endMinutes = startMinutes + classDurationMinutes;

    final startHour = startMinutes ~/ 60;
    final startMinute = startMinutes % 60;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;

    return PeriodTime(
      start:
          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
      end:
          '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
    );
  }
}

/// Time of day representation
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
