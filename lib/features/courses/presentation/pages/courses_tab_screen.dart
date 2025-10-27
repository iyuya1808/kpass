import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/dashboard/presentation/widgets/course_card.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/shared/widgets/custom_app_bar.dart';
import 'package:kpass/shared/models/course_extensions.dart';
import 'package:kpass/shared/models/course.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/l10n/app_localizations.dart';

/// コース一覧画面
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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
        title: l10n?.courses ?? 'コース一覧',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
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
                    // コースセクション
                    _buildSectionHeader(
                      context,
                      'マイコース',
                      courses.length,
                      isLoading: coursesProvider.isLoading,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // コースリスト
                    ...courses.map((course) {
                      final courseWithStats = CourseWithStats.fromCourse(
                        course,
                        assignments,
                      );
                      return CourseCard(
                        course: courseWithStats,
                        isLoadingAssignments: assignmentsProvider.isLoading,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.courseDetail,
                            arguments: course.id,
                          );
                        },
                      );
                    }),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.smallPadding,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
