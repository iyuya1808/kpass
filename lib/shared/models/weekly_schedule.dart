import 'package:equatable/equatable.dart';
import 'package:kpass/shared/models/calendar_event.dart';
import 'package:kpass/core/utils/period_calculator.dart';

/// 週間時間割の1コマを表現するクラス
class WeeklyCourse extends Equatable {
  final int weekday; // 1=月曜日, 2=火曜日, ..., 7=日曜日
  final int period; // 時限番号
  final String courseName;
  final int courseId;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;

  const WeeklyCourse({
    required this.weekday,
    required this.period,
    required this.courseName,
    required this.courseId,
    this.location,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  /// CalendarEventからWeeklyCourseを生成するファクトリーメソッド
  factory WeeklyCourse.fromCalendarEvent(CalendarEvent event) {
    final period = PeriodCalculator.getPeriodFromTime(event.startTime) ?? 1;
    final courseId = _extractCourseId(event.contextCode);

    return WeeklyCourse(
      weekday: event.startTime.weekday,
      period: period,
      courseName: event.title,
      courseId: courseId,
      location: event.location,
      startTime: event.startTime,
      endTime:
          event.endTime ??
          event.startTime.add(const Duration(hours: 1, minutes: 30)),
      description: event.description,
    );
  }

  /// コースIDをcontextCodeから抽出
  static int _extractCourseId(String? contextCode) {
    if (contextCode == null) return 0;

    if (contextCode.startsWith('course_')) {
      final idString = contextCode.substring(7);
      return int.tryParse(idString) ?? 0;
    }

    return 0;
  }

  /// 時限表示ラベルを取得
  String get periodLabel => PeriodCalculator.getPeriodLabel(period);

  /// 時間範囲表示を取得
  String get timeRange => PeriodCalculator.getPeriodTimeRange(period);

  /// 曜日名を取得
  String get weekdayName {
    const weekdayNames = {
      1: '月',
      2: '火',
      3: '水',
      4: '木',
      5: '金',
      6: '土',
      7: '日',
    };
    return weekdayNames[weekday] ?? '';
  }

  @override
  List<Object?> get props => [
    weekday,
    period,
    courseName,
    courseId,
    location,
    startTime,
    endTime,
    description,
  ];

  @override
  String toString() {
    return 'WeeklyCourse(weekday: $weekdayName, period: $period, courseName: $courseName)';
  }
}

/// 週間時間割全体を管理するクラス
class WeeklySchedule extends Equatable {
  /// 曜日 -> 時限 -> コースのマップ
  /// weekday: 1=月曜日, 2=火曜日, ..., 7=日曜日
  /// period: 時限番号
  final Map<int, Map<int, WeeklyCourse>> schedule;

  /// 存在する時限のリスト
  final List<int> availablePeriods;

  /// 表示対象の週の開始日（月曜日）
  final DateTime weekStart;

  const WeeklySchedule({
    required this.schedule,
    required this.availablePeriods,
    required this.weekStart,
  });

  /// CalendarEventのリストからWeeklyScheduleを生成するファクトリーメソッド
  factory WeeklySchedule.fromCalendarEvents(List<CalendarEvent> events) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    // コース関連イベントのみをフィルタリング
    final courseEvents =
        events.where((event) {
          return event.contextType == 'Course' &&
              !(event.isAllDay ?? false) &&
              event.isValid() &&
              event.isActive;
        }).toList();

    // 曜日別・時限別にグループ化
    final schedule = <int, Map<int, WeeklyCourse>>{};
    final periods = <int>{};

    for (final event in courseEvents) {
      final weeklyCourse = WeeklyCourse.fromCalendarEvent(event);
      final weekday = weeklyCourse.weekday;
      final period = weeklyCourse.period;

      // 曜日のマップを初期化
      schedule[weekday] ??= {};

      // 同じ時限に複数の授業がある場合は、最初のものを優先
      if (!schedule[weekday]!.containsKey(period)) {
        schedule[weekday]![period] = weeklyCourse;
        periods.add(period);
      }
    }

    // 時限をソート
    final sortedPeriods = periods.toList()..sort();

    return WeeklySchedule(
      schedule: schedule,
      availablePeriods: sortedPeriods,
      weekStart: weekStart,
    );
  }

  /// 指定された曜日・時限のコースを取得
  WeeklyCourse? getCourse(int weekday, int period) {
    return schedule[weekday]?[period];
  }

  /// 指定された曜日のコース一覧を取得
  List<WeeklyCourse> getCoursesForWeekday(int weekday) {
    final weekdaySchedule = schedule[weekday];
    if (weekdaySchedule == null) return [];

    return weekdaySchedule.values.toList()
      ..sort((a, b) => a.period.compareTo(b.period));
  }

  /// 指定された時限のコース一覧を取得（全曜日）
  List<WeeklyCourse> getCoursesForPeriod(int period) {
    final courses = <WeeklyCourse>[];

    for (final weekdaySchedule in schedule.values) {
      final course = weekdaySchedule[period];
      if (course != null) {
        courses.add(course);
      }
    }

    return courses..sort((a, b) => a.weekday.compareTo(b.weekday));
  }

  /// 指定された曜日に授業があるかチェック
  bool hasCoursesOnWeekday(int weekday) {
    return schedule[weekday]?.isNotEmpty ?? false;
  }

  /// 指定された時限に授業があるかチェック
  bool hasCoursesInPeriod(int period) {
    for (final weekdaySchedule in schedule.values) {
      if (weekdaySchedule.containsKey(period)) {
        return true;
      }
    }
    return false;
  }

  /// 今週に授業があるかチェック
  bool get hasCoursesThisWeek {
    return schedule.isNotEmpty;
  }

  /// 今週の授業総数を取得
  int get totalCourses {
    int count = 0;
    for (final weekdaySchedule in schedule.values) {
      count += weekdaySchedule.length;
    }
    return count;
  }

  /// 週の開始日（月曜日）を取得
  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// 週の終了日（日曜日）を取得
  DateTime get weekEnd {
    return weekStart.add(const Duration(days: 6));
  }

  /// 指定された日付が今週に含まれるかチェック
  bool isDateInThisWeek(DateTime date) {
    return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  @override
  List<Object?> get props => [schedule, availablePeriods, weekStart];

  @override
  String toString() {
    return 'WeeklySchedule(weekStart: $weekStart, totalCourses: $totalCourses, periods: $availablePeriods)';
  }
}
