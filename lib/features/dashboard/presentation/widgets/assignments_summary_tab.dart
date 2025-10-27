import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';
import 'package:kpass/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:kpass/features/dashboard/presentation/widgets/assignment_summary_card.dart';
import 'package:kpass/features/dashboard/presentation/widgets/today_courses_card.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/shared/widgets/custom_app_bar.dart';
import 'package:kpass/shared/models/course.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/l10n/app_localizations.dart';

/// 課題サマリータブ
class AssignmentsSummaryTab extends StatefulWidget {
  const AssignmentsSummaryTab({super.key});

  @override
  State<AssignmentsSummaryTab> createState() => _AssignmentsSummaryTabState();
}

class _AssignmentsSummaryTabState extends State<AssignmentsSummaryTab> {
  @override
  void initState() {
    super.initState();
    // 初回データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final coursesProvider = Provider.of<CoursesProvider>(
      context,
      listen: false,
    );
    final assignmentsProvider = Provider.of<AssignmentsProvider>(
      context,
      listen: false,
    );
    final calendarProvider = Provider.of<CalendarProvider>(
      context,
      listen: false,
    );

    try {
      // 非表示リストを最初に読み込む（完了まで待つ）
      if (!assignmentsProvider.isHiddenListInitialized) {
        await assignmentsProvider.loadHiddenAssignments();
      }

      // First load courses
      if (!coursesProvider.hasCourses) {
        await coursesProvider.loadCourses();
      }

      // Then load assignments based on courses
      if (coursesProvider.hasCourses) {
        await assignmentsProvider.loadAssignments(coursesProvider.courses);
      }

      // Load today's courses with assignments
      await calendarProvider.loadTodayCourses(
        assignments: assignmentsProvider.assignments.cast<Assignment>(),
        courses: coursesProvider.courses.cast<Course>(),
      );
    } catch (e) {
      // エラーが発生しても、既存のデータは保持される
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final coursesProvider = Provider.of<CoursesProvider>(context);
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);

    final courses = coursesProvider.courses.cast<Course>();
    final assignments = assignmentsProvider.assignments.cast<Assignment>();
    final isLoading =
        coursesProvider.isLoading || assignmentsProvider.isLoading;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n?.dashboard ?? 'ダッシュボード',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
            tooltip: '通知',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // コンテンツエリア
            if (isLoading && courses.isEmpty)
              SliverFillRemaining(child: _buildLoadingState())
            else if (courses.isEmpty && !isLoading)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.school_outlined,
                  title: 'コースがありません',
                  message: 'まだコースが登録されていません。\nK-LMSでコースに登録してください。',
                  actionLabel: '更新',
                  onAction: _loadData,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 課題サマリー
                    _buildAssignmentsSummary(context, assignments),
                    const SizedBox(height: AppConstants.largePadding),

                    // 本日の授業
                    const TodayCoursesCard(),
                    const SizedBox(height: AppConstants.largePadding),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsSummary(
    BuildContext context,
    List<Assignment> assignments,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // 期限前の課題（設定可能な日数以内）- 提出済みも含める
    // 非表示リストが初期化済みの場合はフィルタ済みデータを使用
    // 初期化中または未初期化の場合は全データを使用（一時的な状態）
    final availableAssignments =
        assignmentsProvider.isHiddenListInitialized
            ? assignments
            : assignmentsProvider.allAssignments;

    final upcomingAssignments = <Assignment>[];
    final daysLimit = settingsProvider.upcomingAssignmentsDays;
    for (final assignment in availableAssignments) {
      try {
        if (assignment.dueAt == null) continue;
        // 提出済み課題も表示（提出状況は別途表示）
        // if (assignment.isSubmitted) continue;
        // 期限前の課題のみ（期限超過は除外）
        if (assignment.isOverdue) continue;
        final daysUntilDue = assignment.dueAt!.difference(now).inDays;
        if (daysUntilDue >= 0 && daysUntilDue <= daysLimit) {
          upcomingAssignments.add(assignment);
        }
      } catch (e) {
        // 個別の課題の処理エラーは無視して続行
      }
    }

    // 期限日順でソート
    upcomingAssignments.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });

    // 期限が近いのに表示されない課題をチェック
    final allUpcoming = <Assignment>[];
    for (final assignment in availableAssignments) {
      try {
        if (assignment.dueAt == null) continue;
        final daysUntilDue = assignment.dueAt!.difference(now).inDays;
        if (daysUntilDue >= 0 && daysUntilDue <= daysLimit) {
          allUpcoming.add(assignment);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'AssignmentsSummaryTab: Error checking upcoming assignment ${assignment.name}: $e',
          );
        }
      }
    }

    // 期限超過の課題（非表示フィルター済み）
    final overdueAssignments = assignmentsProvider.getOverdueAssignments();
    final overdueCount = overdueAssignments.length;
    final hasError = assignmentsProvider.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdueCount > 0 && !assignmentsProvider.isLoading)
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.overdueAssignments);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              margin: const EdgeInsets.only(
                bottom: AppConstants.defaultPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '期限超過の課題があります',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$overdueCount件の課題が期限を過ぎています',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        // エラー状態の表示
        if (hasError && !assignmentsProvider.isLoading)
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '課題の取得でエラーが発生しました',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '一部の課題が表示されない可能性があります',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: _loadData,
                  tooltip: '再読み込み',
                ),
              ],
            ),
          ),
        AssignmentSummaryCard(
          upcomingAssignments: upcomingAssignments,
          isLoading: assignmentsProvider.isLoading,
          onViewAll: () {
            Navigator.pushNamed(context, AppRoutes.upcomingAssignments);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppConstants.defaultPadding),
          Text('データを読み込んでいます...'),
        ],
      ),
    );
  }
}
