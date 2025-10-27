import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:kpass/features/calendar/presentation/widgets/timetable_cell.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';
import 'package:kpass/shared/models/weekly_schedule.dart';
import 'package:kpass/shared/models/course.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/widgets/custom_app_bar.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/utils/period_calculator.dart';
import 'package:kpass/l10n/app_localizations.dart';

/// 週間時間割画面
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // 初回データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // タブ切り替え時にデータをチェック（初回は除く）
    if (_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDataIfNeeded();
      });
    }
  }

  Future<void> _loadDataIfNeeded() async {
    final calendarProvider = Provider.of<CalendarProvider>(
      context,
      listen: false,
    );
    final coursesProvider = Provider.of<CoursesProvider>(
      context,
      listen: false,
    );
    final assignmentsProvider = Provider.of<AssignmentsProvider>(
      context,
      listen: false,
    );

    try {
      // 既にローディング中または初期化済みの場合はスキップ
      if (calendarProvider.isLoadingWeeklySchedule) {
        return;
      }

      // データが空または初期化されていない場合は読み込み
      final shouldLoad =
          !calendarProvider.isWeeklyScheduleInitialized ||
          calendarProvider.weeklySchedule == null ||
          !calendarProvider.weeklySchedule!.hasCoursesThisWeek;

      if (shouldLoad) {
        // コースと課題データを取得
        final courses = coursesProvider.courses.cast<Course>();
        final assignments = assignmentsProvider.assignments.cast<Assignment>();

        await calendarProvider.loadWeeklySchedule(
          courses: courses,
          assignments: assignments,
        );
      }

      // 初期化完了フラグを設定
      if (!_hasInitialized) {
        _hasInitialized = true;
      }
    } catch (e) {
      // エラーが発生しても、既存のデータは保持される
      if (!_hasInitialized) {
        _hasInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: '週間時間割',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataIfNeeded,
            tooltip: '更新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDataIfNeeded,
        child: _buildBody(calendarProvider, theme, l10n),
      ),
    );
  }

  Widget _buildBody(
    CalendarProvider calendarProvider,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    // ローディング中の場合はローディング表示
    if (calendarProvider.isLoadingWeeklySchedule) {
      return _buildLoadingState(theme);
    }

    if (calendarProvider.error != null) {
      return _buildErrorState(calendarProvider.error!, theme, l10n);
    }

    final weeklySchedule = calendarProvider.weeklySchedule;
    if (weeklySchedule == null || !weeklySchedule.hasCoursesThisWeek) {
      return _buildEmptyState(theme, l10n);
    }

    return _buildTimetable(weeklySchedule, theme, l10n);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppConstants.defaultPadding),
          Text('時間割を読み込んでいます...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String error,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: AppConstants.defaultPadding),
          Text('エラーが発生しました', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          ElevatedButton(
            onPressed: _loadDataIfNeeded,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations? l10n) {
    return EmptyStateWidget(
      icon: Icons.calendar_view_week_outlined,
      title: '今週は授業がありません',
      message: 'Canvasから授業データを取得できませんでした。\nコースに登録されているか確認してください。',
      actionLabel: '更新',
      onAction: _loadDataIfNeeded,
    );
  }

  Widget _buildTimetable(
    WeeklySchedule weeklySchedule,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final currentPeriod = PeriodCalculator.getPeriodFromTime(now);

    return CustomScrollView(
      slivers: [
        // ヘッダー行（曜日）
        SliverToBoxAdapter(
          child: Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return _buildWeekdayHeader(
                theme,
                l10n,
                todayWeekday,
                settingsProvider.showWeekendsInTimetable,
              );
            },
          ),
        ),

        // 時間割テーブル
        SliverToBoxAdapter(
          child: Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return _buildTimetableGrid(
                weeklySchedule,
                theme,
                todayWeekday,
                currentPeriod,
                settingsProvider.showWeekendsInTimetable,
              );
            },
          ),
        ),

        // 下部の余白
        const SliverToBoxAdapter(
          child: SizedBox(height: AppConstants.largePadding),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(
    ThemeData theme,
    AppLocalizations? l10n,
    int todayWeekday,
    bool showWeekends,
  ) {
    const allWeekdays = [
      {'key': 'monday', 'label': '月', 'value': 1},
      {'key': 'tuesday', 'label': '火', 'value': 2},
      {'key': 'wednesday', 'label': '水', 'value': 3},
      {'key': 'thursday', 'label': '木', 'value': 4},
      {'key': 'friday', 'label': '金', 'value': 5},
      {'key': 'saturday', 'label': '土', 'value': 6},
      {'key': 'sunday', 'label': '日', 'value': 7},
    ];

    // 土日表示設定に応じて曜日をフィルタリング
    final weekdays =
        showWeekends ? allWeekdays : allWeekdays.take(5).toList(); // 月〜金のみ

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 時刻列のヘッダー（空）
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),

          // 曜日ヘッダー
          Expanded(
            child: Row(
              children:
                  weekdays.map((weekday) {
                    final isToday = weekday['value'] == todayWeekday;
                    return Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              isToday
                                  ? theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5)
                                  : null,
                          border: Border(
                            right: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            weekday['label'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.w500,
                              color:
                                  isToday
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid(
    WeeklySchedule weeklySchedule,
    ThemeData theme,
    int todayWeekday,
    int? currentPeriod,
    bool showWeekends,
  ) {
    final availablePeriods = weeklySchedule.availablePeriods;
    if (availablePeriods.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1限から最大時限まで表示
    final minPeriod = availablePeriods.first;
    final maxPeriod = availablePeriods.last;
    final allPeriods = List.generate(
      maxPeriod - minPeriod + 1,
      (index) => minPeriod + index,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children:
            allPeriods.map((period) {
              final periodTime = PeriodCalculator.getPeriodTime(period);
              final isCurrentPeriod = currentPeriod == period;

              return _buildPeriodRow(
                period,
                periodTime?.start ?? '--:--',
                weeklySchedule,
                theme,
                todayWeekday,
                isCurrentPeriod,
                showWeekends,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPeriodRow(
    int period,
    String time,
    WeeklySchedule weeklySchedule,
    ThemeData theme,
    int todayWeekday,
    bool isCurrentPeriod,
    bool showWeekends,
  ) {
    // 土日表示設定に応じて曜日をフィルタリング
    final weekdays =
        showWeekends
            ? [1, 2, 3, 4, 5, 6, 7] // 月〜日
            : [1, 2, 3, 4, 5]; // 月〜金のみ

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color:
            isCurrentPeriod
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                : null,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // 時刻列
          Container(
            width: 60,
            decoration: BoxDecoration(
              color:
                  isCurrentPeriod
                      ? theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      )
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$period限',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isCurrentPeriod
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color:
                          isCurrentPeriod
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 曜日列
          Expanded(
            child: Row(
              children:
                  weekdays.map((weekday) {
                    final course = weeklySchedule.getCourse(weekday, period);
                    final isToday = weekday == todayWeekday;

                    return Expanded(
                      child: TimetableCell(
                        course: course,
                        isToday: isToday,
                        isCurrentPeriod: isCurrentPeriod && isToday,
                        onTap:
                            course != null
                                ? () {
                                  // TODO: コース詳細画面への遷移
                                  _showCourseDetails(course);
                                }
                                : null,
                        onLongPress:
                            course != null
                                ? () {
                                  TimetableCellDetailsSheet.show(
                                    context,
                                    course,
                                  );
                                }
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseDetails(WeeklyCourse course) {
    // TODO: コース詳細画面への遷移を実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.courseName}の詳細画面（未実装）'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
