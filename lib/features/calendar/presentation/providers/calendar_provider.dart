import 'package:flutter/foundation.dart';
import 'package:kpass/core/services/proxy_api_client.dart';
import 'package:kpass/shared/models/calendar_event.dart';
import 'package:kpass/shared/models/today_course.dart';
import 'package:kpass/shared/models/weekly_schedule.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/models/course.dart';
import 'package:kpass/core/utils/period_calculator.dart';

class CalendarProvider extends ChangeNotifier {
  final ProxyApiClient _apiClient;

  List<CalendarEvent> _events = [];
  List<TodayCourse> _todayCourses = [];
  WeeklySchedule? _weeklySchedule;
  bool _isLoading = false;
  bool _isLoadingTodayCourses = false;
  bool _isLoadingWeeklySchedule = false;
  bool _isInitialized = false;
  bool _isWeeklyScheduleInitialized = false;
  String _loadingMessage = '';
  String? _error;
  DateTime? _lastSync;

  List<CalendarEvent> get events => _events;
  List<TodayCourse> get todayCourses => _todayCourses;
  WeeklySchedule? get weeklySchedule => _weeklySchedule;
  bool get isLoading => _isLoading;
  bool get isLoadingTodayCourses => _isLoadingTodayCourses;
  bool get isLoadingWeeklySchedule => _isLoadingWeeklySchedule;
  bool get isInitialized => _isInitialized;
  bool get isWeeklyScheduleInitialized => _isWeeklyScheduleInitialized;
  String get loadingMessage => _loadingMessage;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get hasEvents => _events.isNotEmpty;
  bool get hasTodayCourses => _todayCourses.isNotEmpty;
  bool get hasWeeklySchedule =>
      _weeklySchedule != null && _weeklySchedule!.hasCoursesThisWeek;

  CalendarProvider({ProxyApiClient? apiClient})
    : _apiClient = apiClient ?? ProxyApiClient();

  /// Load all calendar events
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('CalendarProvider: Starting to load calendar events...');
      }

      final response = await _apiClient.get<List<Map<String, dynamic>>>(
        '/calendar_events',
        queryParameters: {
          'type': 'event',
          'per_page': '100',
          'start_date':
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String(),
          'end_date':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
        fromJson: (data) => data as List<Map<String, dynamic>>,
      );

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: API response success: ${response.isSuccess}',
        );
        debugPrint(
          'CalendarProvider: API response type: ${response.valueOrNull.runtimeType}',
        );
        if (response.valueOrNull is List) {
          debugPrint(
            'CalendarProvider: Raw events count: ${(response.valueOrNull as List).length}',
          );
        }
      }

      if (!response.isSuccess) {
        final failure = response.failureOrNull;
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: API request failed: ${failure?.message} (${failure?.runtimeType})',
          );
        }
        throw Exception(
          'API request failed: ${failure?.message ?? 'Unknown error'}',
        );
      }

      if (response.valueOrNull is! List) {
        throw Exception(
          'Invalid response format for calendar events: ${response.valueOrNull.runtimeType}',
        );
      }

      final eventsData = response.valueOrNull as List<Map<String, dynamic>>;

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Processing ${eventsData.length} raw events...',
        );
        for (int i = 0; i < eventsData.length && i < 3; i++) {
          final event = eventsData[i];
          debugPrint(
            'CalendarProvider: Event $i: ${event['title']} - ${event['start_at']} - ${event['context_type']}',
          );
        }
      }

      _events =
          eventsData.map((json) => CalendarEvent.fromJson(json)).where((event) {
            final isValid = event.isValid();
            final isActive = event.isActive;
            if (kDebugMode && (!isValid || !isActive)) {
              debugPrint(
                'CalendarProvider: Filtered out event: ${event.title} (valid: $isValid, active: $isActive)',
              );
            }
            return isValid && isActive;
          }).toList();

      _lastSync = DateTime.now();
      _error = null;

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Loaded ${_events.length} events after filtering',
        );
        for (final event in _events.take(3)) {
          debugPrint(
            'CalendarProvider: Final event: ${event.title} - ${event.startTime} - ${event.contextType}',
          );
        }
      }
    } catch (e) {
      _error = 'カレンダーイベントの取得中にエラーが発生しました: $e';

      if (kDebugMode) {
        debugPrint('CalendarProvider: Exception while loading events: $e');
        debugPrint('CalendarProvider: Exception type: ${e.runtimeType}');
        if (e is Exception) {
          debugPrint('CalendarProvider: Exception message: ${e.toString()}');
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load today's courses from calendar events
  Future<void> loadTodayCourses({
    List<Assignment>? assignments,
    List<Course>? courses,
  }) async {
    _isLoadingTodayCourses = true;
    _loadingMessage = 'カレンダーイベントを取得中...';
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('CalendarProvider: Starting to load today courses...');
      }

      // First load events if not already loaded
      if (_events.isEmpty) {
        _loadingMessage = 'Canvasからカレンダーデータを取得中...';
        notifyListeners();
        await loadEvents();
      }

      _loadingMessage = '本日の授業を検索中...';
      notifyListeners();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Looking for events on ${today.toIso8601String().split('T')[0]}',
        );
        debugPrint(
          'CalendarProvider: Total events available: ${_events.length}',
        );
      }

      // Filter events for today that are course-related
      final todayEvents =
          _events.where((event) {
            final eventDate = DateTime(
              event.startTime.year,
              event.startTime.month,
              event.startTime.day,
            );

            final isToday = eventDate.isAtSameMomentAs(today);
            final isCourse = event.contextType == 'Course';
            final isNotAllDay = !(event.isAllDay ?? false);

            if (kDebugMode) {
              debugPrint(
                'CalendarProvider: Event ${event.title}: isToday=$isToday, isCourse=$isCourse, isNotAllDay=$isNotAllDay, contextType=${event.contextType}, isAllDay=${event.isAllDay}',
              );
            }

            return isToday && isCourse && isNotAllDay;
          }).toList();

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Found ${todayEvents.length} today events',
        );
      }

      // Convert to TodayCourse objects
      final todayCoursesList = <TodayCourse>[];

      for (final event in todayEvents) {
        try {
          if (kDebugMode) {
            debugPrint(
              'CalendarProvider: Processing event: ${event.title} at ${event.startTime}',
            );
          }

          // Find next assignment for this course
          Assignment? nextAssignment;
          if (assignments != null) {
            final courseId = _extractCourseId(event.contextCode);
            if (courseId > 0) {
              final courseAssignments =
                  assignments
                      .where((a) => a.courseId == courseId && !a.isOverdue)
                      .toList();

              if (courseAssignments.isNotEmpty) {
                courseAssignments.sort((a, b) {
                  if (a.dueAt == null && b.dueAt == null) return 0;
                  if (a.dueAt == null) return 1;
                  if (b.dueAt == null) return -1;
                  return a.dueAt!.compareTo(b.dueAt!);
                });
                nextAssignment = courseAssignments.first;
              }
            }
          }

          final todayCourse = TodayCourse.fromCalendarEvent(
            event,
            nextAssignment: nextAssignment,
          );

          todayCoursesList.add(todayCourse);

          if (kDebugMode) {
            debugPrint(
              'CalendarProvider: Successfully created TodayCourse: ${todayCourse.courseName} (Period ${todayCourse.period})',
            );
          }
        } catch (e) {
          // Skip events that can't be converted to TodayCourse
          if (kDebugMode) {
            debugPrint('CalendarProvider: Skipping event ${event.title}: $e');
          }
        }
      }

      // Sort by period number
      todayCoursesList.sort((a, b) => a.period.compareTo(b.period));

      _todayCourses = todayCoursesList;

      // If no calendar events found, try to create mock courses for testing
      if (_todayCourses.isEmpty && courses != null) {
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: No calendar events found, creating mock courses for testing...',
          );
        }

        _loadingMessage = 'コース情報から授業を生成中...';
        notifyListeners();

        // Create mock courses for testing (this is temporary for debugging)
        final mockCourses = _createMockTodayCourses(courses, assignments);
        _todayCourses.addAll(mockCourses);

        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Created ${mockCourses.length} mock courses for testing',
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Loaded ${_todayCourses.length} today courses',
        );
        for (final course in _todayCourses) {
          debugPrint(
            'CalendarProvider: Today course: ${course.courseName} - ${course.periodDisplay}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Exception while loading today courses: $e',
        );
      }
    } finally {
      _isLoadingTodayCourses = false;
      _isInitialized = true;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  /// Extract course ID from context code (e.g., "course_12345" -> 12345)
  int _extractCourseId(String? contextCode) {
    if (contextCode == null) return 0;

    if (contextCode.startsWith('course_')) {
      final idString = contextCode.substring(7);
      return int.tryParse(idString) ?? 0;
    }

    return 0;
  }

  /// Extract period number from course name (e.g., "[月1]" -> 1, "[火2]" -> 2)
  int? _extractPeriodFromCourseName(String courseName) {
    if (kDebugMode) {
      debugPrint('CalendarProvider: Extracting period from: $courseName');
    }

    // パターン1: [曜日数字] または [曜日数字 曜日数字] を探す
    final regex1 = RegExp(r'\[([月火水木金土日])(\d+)(?:\s+[月火水木金土日]\d+)*\]');
    final match1 = regex1.firstMatch(courseName);

    if (match1 != null) {
      final periodStr = match1.group(2);
      if (periodStr != null) {
        final period = int.tryParse(periodStr);
        if (kDebugMode) {
          debugPrint('CalendarProvider: Found period $period from pattern 1');
        }
        return period;
      }
    }

    // パターン2: 秋[曜日数字] または 秋[曜日数字 曜日数字] を探す
    final regex2 = RegExp(r'秋\[([月火水木金土日])(\d+)(?:\s+[月火水木金土日]\d+)*\]');
    final match2 = regex2.firstMatch(courseName);

    if (match2 != null) {
      final periodStr = match2.group(2);
      if (periodStr != null) {
        final period = int.tryParse(periodStr);
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Found period $period from pattern 2 (秋学期)',
          );
        }
        return period;
      }
    }

    // パターン3: 春[曜日数字] または 春[曜日数字 曜日数字] を探す
    final regex3 = RegExp(r'春\[([月火水木金土日])(\d+)(?:\s+[月火水木金土日]\d+)*\]');
    final match3 = regex3.firstMatch(courseName);

    if (match3 != null) {
      final periodStr = match3.group(2);
      if (periodStr != null) {
        final period = int.tryParse(periodStr);
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Found period $period from pattern 3 (春学期)',
          );
        }
        return period;
      }
    }

    // パターン4: 数字限 を探す
    final regex4 = RegExp(r'(\d+)限');
    final match4 = regex4.firstMatch(courseName);

    if (match4 != null) {
      final periodStr = match4.group(1);
      if (periodStr != null) {
        final period = int.tryParse(periodStr);
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Found period $period from pattern 4 (直接表記)',
          );
        }
        return period;
      }
    }

    // パターン5: 数字時限 を探す
    final regex5 = RegExp(r'(\d+)時限');
    final match5 = regex5.firstMatch(courseName);

    if (match5 != null) {
      final periodStr = match5.group(1);
      if (periodStr != null) {
        final period = int.tryParse(periodStr);
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Found period $period from pattern 5 (時限表記)',
          );
        }
        return period;
      }
    }

    if (kDebugMode) {
      debugPrint('CalendarProvider: No period pattern matched');
    }
    return null;
  }

  /// Extract all period numbers from course name (e.g., "[金1 金2]" -> [1, 2])
  List<int> _extractAllPeriodsFromCourseName(String courseName) {
    if (kDebugMode) {
      debugPrint('CalendarProvider: Extracting all periods from: $courseName');
    }

    final periods = <int>[];

    // パターン1: [曜日数字 曜日数字 ...] を探す
    final regex1 = RegExp(r'\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match1 = regex1.firstMatch(courseName);

    if (match1 != null) {
      // 最初の時限
      final firstPeriodStr = match1.group(2);
      if (firstPeriodStr != null) {
        final firstPeriod = int.tryParse(firstPeriodStr);
        if (firstPeriod != null) {
          periods.add(firstPeriod);
        }
      }

      // 追加の時限を探す
      final allMatches = regex1.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final periodStr = match.group(i + 1);
          if (periodStr != null) {
            final period = int.tryParse(periodStr);
            if (period != null && !periods.contains(period)) {
              periods.add(period);
            }
          }
        }
      }
    }

    // パターン2: 秋[曜日数字 曜日数字 ...] を探す
    final regex2 = RegExp(r'秋\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match2 = regex2.firstMatch(courseName);

    if (match2 != null) {
      // 最初の時限
      final firstPeriodStr = match2.group(2);
      if (firstPeriodStr != null) {
        final firstPeriod = int.tryParse(firstPeriodStr);
        if (firstPeriod != null && !periods.contains(firstPeriod)) {
          periods.add(firstPeriod);
        }
      }

      // 追加の時限を探す
      final allMatches = regex2.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final periodStr = match.group(i + 1);
          if (periodStr != null) {
            final period = int.tryParse(periodStr);
            if (period != null && !periods.contains(period)) {
              periods.add(period);
            }
          }
        }
      }
    }

    // パターン3: 春[曜日数字 曜日数字 ...] を探す
    final regex3 = RegExp(r'春\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match3 = regex3.firstMatch(courseName);

    if (match3 != null) {
      // 最初の時限
      final firstPeriodStr = match3.group(2);
      if (firstPeriodStr != null) {
        final firstPeriod = int.tryParse(firstPeriodStr);
        if (firstPeriod != null && !periods.contains(firstPeriod)) {
          periods.add(firstPeriod);
        }
      }

      // 追加の時限を探す
      final allMatches = regex3.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final periodStr = match.group(i + 1);
          if (periodStr != null) {
            final period = int.tryParse(periodStr);
            if (period != null && !periods.contains(period)) {
              periods.add(period);
            }
          }
        }
      }
    }

    // 単一時限のパターンも試す
    if (periods.isEmpty) {
      final singlePeriod = _extractPeriodFromCourseName(courseName);
      if (singlePeriod != null) {
        periods.add(singlePeriod);
      }
    }

    periods.sort();

    if (kDebugMode) {
      debugPrint('CalendarProvider: Found periods: $periods');
    }

    return periods;
  }

  /// Extract location from course name (e.g., "[日吉 23]" -> "日吉 23")
  String? _extractLocationFromCourseName(String courseName) {
    // パターン: [場所] を探す
    final regex = RegExp(r'\[([^\]]+)\]');
    final matches = regex.allMatches(courseName);

    for (final match in matches) {
      final content = match.group(1);
      if (content != null && !content.contains(RegExp(r'[月火水木金土日]\d+'))) {
        // 曜日+数字のパターンでない場合、教室情報とみなす
        return content;
      }
    }

    return null;
  }

  /// Load weekly schedule from calendar events
  Future<void> loadWeeklySchedule({
    List<Course>? courses,
    List<Assignment>? assignments,
  }) async {
    // 既にローディング中の場合はスキップ
    if (_isLoadingWeeklySchedule) {
      return;
    }

    _isLoadingWeeklySchedule = true;
    _loadingMessage = '週間時間割を取得中...';
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('CalendarProvider: Starting to load weekly schedule...');
      }

      // First load events if not already loaded
      if (_events.isEmpty) {
        _loadingMessage = 'Canvasからカレンダーデータを取得中...';
        notifyListeners();
        await loadEvents();
      }

      _loadingMessage = '週間時間割を生成中...';
      notifyListeners();

      // Generate weekly schedule from events
      _weeklySchedule = WeeklySchedule.fromCalendarEvents(_events);

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Generated weekly schedule with ${_weeklySchedule?.totalCourses ?? 0} courses',
        );
        debugPrint(
          'CalendarProvider: Available periods: ${_weeklySchedule?.availablePeriods ?? []}',
        );
      }

      // If no calendar events found, try to create mock weekly schedule for testing
      if ((_weeklySchedule == null || !_weeklySchedule!.hasCoursesThisWeek) &&
          courses != null) {
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: No calendar events found, creating mock weekly schedule for testing...',
          );
        }

        _loadingMessage = 'コース情報から週間時間割を生成中...';
        notifyListeners();

        // Create mock weekly schedule from courses
        _weeklySchedule = _createMockWeeklySchedule(courses, assignments);

        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Created mock weekly schedule with ${_weeklySchedule?.totalCourses ?? 0} courses',
          );
        }
      }
    } catch (e) {
      _error = '週間時間割の取得中にエラーが発生しました: $e';

      if (kDebugMode) {
        debugPrint(
          'CalendarProvider: Exception while loading weekly schedule: $e',
        );
      }
    } finally {
      _isLoadingWeeklySchedule = false;
      _isWeeklyScheduleInitialized = true;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  /// Refresh calendar data
  Future<void> refresh() async {
    _events = [];
    _todayCourses = [];
    _weeklySchedule = null;
    _isWeeklyScheduleInitialized = false;
    await loadEvents();
  }

  /// Create mock today courses for testing when no calendar events are available
  List<TodayCourse> _createMockTodayCourses(
    List<Course> courses,
    List<Assignment>? assignments,
  ) {
    final mockCourses = <TodayCourse>[];
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1=月曜日, 2=火曜日, ..., 7=日曜日

    // 曜日名のマッピング
    final weekdayNames = {
      1: '月',
      2: '火',
      3: '水',
      4: '木',
      5: '金',
      6: '土',
      7: '日',
    };

    final todayWeekdayName = weekdayNames[todayWeekday]!;

    if (kDebugMode) {
      debugPrint(
        'CalendarProvider: Today is $todayWeekdayName曜日 (weekday: $todayWeekday)',
      );
    }

    // 今日の曜日と一致するコースをフィルタリング
    final todayCourses =
        courses.where((course) {
          final courseName = course.name;

          // パターン1: [曜日数字] 形式をチェック
          final hasWeekdayPattern1 = courseName.contains('[$todayWeekdayName');

          // パターン2: 秋[曜日数字] 形式をチェック
          final hasWeekdayPattern2 = courseName.contains('秋[$todayWeekdayName');

          // パターン3: 春[曜日数字] 形式をチェック
          final hasWeekdayPattern3 = courseName.contains('春[$todayWeekdayName');

          // パターン4: 直接的な曜日表記をチェック
          final hasDirectWeekday =
              courseName.contains('$todayWeekdayName曜日') ||
              courseName.contains('$todayWeekdayName限');

          return hasWeekdayPattern1 ||
              hasWeekdayPattern2 ||
              hasWeekdayPattern3 ||
              hasDirectWeekday;
        }).toList();

    if (kDebugMode) {
      debugPrint(
        'CalendarProvider: Found ${todayCourses.length} courses for $todayWeekdayName曜日',
      );
      for (final course in todayCourses) {
        debugPrint('CalendarProvider: Today course: ${course.name}');
      }

      // 他の曜日のコースも確認
      final allWeekdays = ['月', '火', '水', '木', '金', '土', '日'];
      for (final weekday in allWeekdays) {
        if (weekday != todayWeekdayName) {
          final otherDayCourses =
              courses.where((course) {
                final courseName = course.name;
                return courseName.contains('[$weekday') ||
                    courseName.contains('秋[$weekday') ||
                    courseName.contains('春[$weekday');
              }).length;
          if (otherDayCourses > 0) {
            debugPrint(
              'CalendarProvider: Found $otherDayCourses courses for $weekday曜日',
            );
          }
        }
      }
    }

    // 今日のコースから時限順にソートして表示
    final sortedTodayCourses = <MapEntry<int, Course>>[];

    for (final course in todayCourses) {
      final periods = _extractAllPeriodsFromCourseName(course.name);
      if (periods.isNotEmpty) {
        for (final period in periods) {
          sortedTodayCourses.add(MapEntry(period, course));
          if (kDebugMode) {
            debugPrint(
              'CalendarProvider: Added course: ${course.name} -> Period $period',
            );
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'CalendarProvider: Failed to extract period from: ${course.name}',
          );
        }
      }
    }

    // 時限順にソート
    sortedTodayCourses.sort((a, b) => a.key.compareTo(b.key));

    // すべてのコースを表示（制限を解除）
    final coursesToShow = sortedTodayCourses;

    for (final entry in coursesToShow) {
      final period = entry.key;
      final course = entry.value;

      // Create mock start time for this period
      final periodTime = PeriodCalculator.getPeriodTime(period);
      if (periodTime != null) {
        final startTimeParts = periodTime.start.split(':');
        final startTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(startTimeParts[0]),
          int.parse(startTimeParts[1]),
        );

        final endTimeParts = periodTime.end.split(':');
        final endTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );

        // Find next assignment for this course
        Assignment? nextAssignment;
        if (assignments != null) {
          final courseAssignments =
              assignments
                  .where((a) => a.courseId == course.id && !a.isOverdue)
                  .toList();

          if (courseAssignments.isNotEmpty) {
            courseAssignments.sort((a, b) {
              if (a.dueAt == null && b.dueAt == null) return 0;
              if (a.dueAt == null) return 1;
              if (b.dueAt == null) return -1;
              return a.dueAt!.compareTo(b.dueAt!);
            });
            nextAssignment = courseAssignments.first;
          }
        }

        // コース名から教室情報を抽出
        final location = _extractLocationFromCourseName(course.name);

        final mockCourse = TodayCourse(
          period: period,
          periodLabel: PeriodCalculator.getPeriodLabel(period),
          timeRange: PeriodCalculator.getPeriodTimeRange(period),
          courseName: course.displayName,
          courseId: course.id,
          location: location,
          nextAssignment: nextAssignment,
          startTime: startTime,
          endTime: endTime,
          description: '本日の授業',
        );

        mockCourses.add(mockCourse);
      }
    }

    return mockCourses;
  }

  /// Create mock weekly schedule for testing when no calendar events are available
  WeeklySchedule _createMockWeeklySchedule(
    List<Course> courses,
    List<Assignment>? assignments,
  ) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    // 曜日名のマッピング
    final weekdayNames = {
      1: '月',
      2: '火',
      3: '水',
      4: '木',
      5: '金',
      6: '土',
      7: '日',
    };

    // 曜日別・時限別にグループ化
    final schedule = <int, Map<int, WeeklyCourse>>{};
    final periods = <int>{};

    if (kDebugMode) {
      debugPrint(
        'CalendarProvider: Creating mock weekly schedule from ${courses.length} courses',
      );
    }

    // 各曜日について処理
    for (int weekday = 1; weekday <= 7; weekday++) {
      final weekdayName = weekdayNames[weekday]!;

      // その曜日のコースをフィルタリング
      final weekdayCourses =
          courses.where((course) {
            final courseName = course.name;

            // コース名から曜日を抽出して、現在の曜日と一致するかチェック
            final courseWeekdays = _extractWeekdaysFromCourseName(courseName);
            final hasWeekdayMatch = courseWeekdays.contains(weekdayName);

            if (kDebugMode && hasWeekdayMatch) {
              debugPrint(
                'CalendarProvider: Course "${course.name}" matches $weekdayName曜日 (weekday: $weekday) - courseWeekdays: $courseWeekdays',
              );
            }

            return hasWeekdayMatch;
          }).toList();

      if (weekdayCourses.isNotEmpty) {
        schedule[weekday] = {};

        for (final course in weekdayCourses) {
          // この曜日に対応する時限のみを抽出
          final coursePeriods = _extractPeriodsForWeekday(
            course.name,
            weekdayName,
          );

          for (final period in coursePeriods) {
            // 同じ時限に複数の授業がある場合は、最初のものを優先
            if (!schedule[weekday]!.containsKey(period)) {
              // Create mock start time for this period
              final periodTime = PeriodCalculator.getPeriodTime(period);
              if (periodTime != null) {
                final startTimeParts = periodTime.start.split(':');
                final startTime = DateTime(
                  weekStart.year,
                  weekStart.month,
                  weekStart.day + (weekday - 1), // 曜日オフセット
                  int.parse(startTimeParts[0]),
                  int.parse(startTimeParts[1]),
                );

                final endTimeParts = periodTime.end.split(':');
                final endTime = DateTime(
                  weekStart.year,
                  weekStart.month,
                  weekStart.day + (weekday - 1),
                  int.parse(endTimeParts[0]),
                  int.parse(endTimeParts[1]),
                );

                // コース名から教室情報を抽出
                final location = _extractLocationFromCourseName(course.name);

                final weeklyCourse = WeeklyCourse(
                  weekday: weekday,
                  period: period,
                  courseName: course.displayName,
                  courseId: course.id,
                  location: location,
                  startTime: startTime,
                  endTime: endTime,
                  description: '週間授業',
                );

                schedule[weekday]![period] = weeklyCourse;
                periods.add(period);

                if (kDebugMode) {
                  debugPrint(
                    'CalendarProvider: Added weekly course: ${course.name} -> $weekdayName曜日 $period限',
                  );
                }
              }
            }
          }
        }
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

  /// 指定された曜日の時限のみを抽出
  List<int> _extractPeriodsForWeekday(String courseName, String weekdayName) {
    final periods = <int>[];

    // パターン1: [曜日数字] または [曜日数字 曜日数字 ...] を探す
    final regex1 = RegExp(r'\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match1 = regex1.firstMatch(courseName);

    if (match1 != null) {
      // 最初の曜日と時限
      final firstWeekday = match1.group(1);
      final firstPeriodStr = match1.group(2);

      if (firstWeekday == weekdayName && firstPeriodStr != null) {
        final period = int.tryParse(firstPeriodStr);
        if (period != null) {
          periods.add(period);
        }
      }

      // 追加の曜日と時限を探す
      final allMatches = regex1.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final weekday = match.group(i);
          final periodStr = match.group(i + 1);
          if (weekday == weekdayName && periodStr != null) {
            final period = int.tryParse(periodStr);
            if (period != null && !periods.contains(period)) {
              periods.add(period);
            }
          }
        }
      }
    }

    // パターン2: 秋[曜日数字 曜日数字 ...] を探す
    final regex2 = RegExp(r'秋\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match2 = regex2.firstMatch(courseName);

    if (match2 != null) {
      // 最初の曜日と時限
      final firstWeekday = match2.group(1);
      final firstPeriodStr = match2.group(2);

      if (firstWeekday == weekdayName && firstPeriodStr != null) {
        final period = int.tryParse(firstPeriodStr);
        if (period != null && !periods.contains(period)) {
          periods.add(period);
        }
      }

      // 追加の曜日と時限を探す
      final allMatches = regex2.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final weekday = match.group(i);
          final periodStr = match.group(i + 1);
          if (weekday == weekdayName && periodStr != null) {
            final period = int.tryParse(periodStr);
            if (period != null && !periods.contains(period)) {
              periods.add(period);
            }
          }
        }
      }
    }

    // パターン3: 春[曜日数字 曜日数字 ...] を探す
    final regex3 = RegExp(r'春\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match3 = regex3.firstMatch(courseName);

    if (match3 != null) {
      // 最初の曜日と時限
      final firstWeekday = match3.group(1);
      final firstPeriodStr = match3.group(2);

      if (firstWeekday == weekdayName && firstPeriodStr != null) {
        final period = int.tryParse(firstPeriodStr);
        if (period != null && !periods.contains(period)) {
          periods.add(period);
        }
      }

      // 追加の曜日と時限を探す
      final allMatches = regex3.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final weekday = match.group(i);
          final periodStr = match.group(i + 1);
          if (weekday == weekdayName && periodStr != null) {
            final period = int.tryParse(periodStr);
            if (period != null && !periods.contains(period)) {
              periods.add(period);
            }
          }
        }
      }
    }

    periods.sort();
    return periods;
  }

  /// コース名から曜日を抽出
  List<String> _extractWeekdaysFromCourseName(String courseName) {
    final weekdays = <String>[];

    // パターン1: [曜日数字] または [曜日数字 曜日数字 ...] を探す
    final regex1 = RegExp(r'\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match1 = regex1.firstMatch(courseName);

    if (match1 != null) {
      // 最初の曜日
      final firstWeekday = match1.group(1);
      if (firstWeekday != null) {
        weekdays.add(firstWeekday);
      }

      // 追加の曜日を探す
      final allMatches = regex1.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final weekday = match.group(i);
          if (weekday != null && !weekdays.contains(weekday)) {
            weekdays.add(weekday);
          }
        }
      }
    }

    // パターン2: 秋[曜日数字 曜日数字 ...] を探す
    final regex2 = RegExp(r'秋\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match2 = regex2.firstMatch(courseName);

    if (match2 != null) {
      // 最初の曜日
      final firstWeekday = match2.group(1);
      if (firstWeekday != null && !weekdays.contains(firstWeekday)) {
        weekdays.add(firstWeekday);
      }

      // 追加の曜日を探す
      final allMatches = regex2.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final weekday = match.group(i);
          if (weekday != null && !weekdays.contains(weekday)) {
            weekdays.add(weekday);
          }
        }
      }
    }

    // パターン3: 春[曜日数字 曜日数字 ...] を探す
    final regex3 = RegExp(r'春\[([月火水木金土日])(\d+)(?:\s+([月火水木金土日])(\d+))*\]');
    final match3 = regex3.firstMatch(courseName);

    if (match3 != null) {
      // 最初の曜日
      final firstWeekday = match3.group(1);
      if (firstWeekday != null && !weekdays.contains(firstWeekday)) {
        weekdays.add(firstWeekday);
      }

      // 追加の曜日を探す
      final allMatches = regex3.allMatches(courseName);
      for (final match in allMatches) {
        for (int i = 3; i < match.groupCount; i += 2) {
          final weekday = match.group(i);
          if (weekday != null && !weekdays.contains(weekday)) {
            weekdays.add(weekday);
          }
        }
      }
    }

    return weekdays;
  }

  /// 週の開始日（月曜日）を取得
  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
