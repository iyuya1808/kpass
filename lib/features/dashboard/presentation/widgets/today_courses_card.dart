import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/shared/models/today_course.dart';
import 'package:kpass/shared/models/course.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/l10n/app_localizations.dart';
import 'package:kpass/core/constants/campus_constants.dart';

/// Card widget displaying today's courses
class TodayCoursesCard extends StatefulWidget {
  const TodayCoursesCard({super.key});

  @override
  State<TodayCoursesCard> createState() => _TodayCoursesCardState();
}

class _TodayCoursesCardState extends State<TodayCoursesCard> {
  @override
  void initState() {
    super.initState();
    // 初期化時にデータを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayCourses();
    });
  }

  Future<void> _loadTodayCourses() async {
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

    // まだ初期化されていない場合のみ読み込み
    if (!calendarProvider.isInitialized &&
        !calendarProvider.isLoadingTodayCourses) {
      await calendarProvider.loadTodayCourses(
        assignments: assignmentsProvider.assignments.cast<Assignment>(),
        courses: coursesProvider.courses.cast<Course>(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // 初期状態またはローディング中の場合はローディング表示
    final shouldShowLoading =
        calendarProvider.isLoadingTodayCourses ||
        (!calendarProvider.isInitialized &&
            calendarProvider.todayCourses.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with campus info
        _buildSectionHeader(
          context,
          l10n?.todayCourses ?? '本日の授業',
          calendarProvider.todayCourses.length,
          campus: settingsProvider.selectedCampus,
        ),
        const SizedBox(height: AppConstants.defaultPadding),

        // Today's courses content
        if (shouldShowLoading)
          _buildLoadingState(context)
        else if (calendarProvider.todayCourses.isEmpty)
          _buildEmptyState(context)
        else
          _buildCoursesList(context, calendarProvider.todayCourses),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count, {
    KeioCampus? campus,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
        ),
        if (campus != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              CampusConstants.getCampusDisplayName(campus),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ローディングアイコン
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),

          // ローディングテキスト
          Text(
            '本日の授業を取得中...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          Consumer<CalendarProvider>(
            builder: (context, calendarProvider, child) {
              return Text(
                calendarProvider.loadingMessage.isNotEmpty
                    ? calendarProvider.loadingMessage
                    : 'Canvasから授業データを読み込んでいます',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Text(
            '本日は授業がありません',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context, List<TodayCourse> courses) {
    return Column(
      children:
          courses.map((course) => _buildCourseItem(context, course)).toList(),
    );
  }

  Widget _buildCourseItem(BuildContext context, TodayCourse course) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.courseDetail,
            arguments: course.courseId,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period and time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smallPadding,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.periodDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  if (course.hasLocation) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        course.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),

              // Course name
              Text(
                course.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Next assignment (if any)
              if (course.hasNextAssignment) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.smallPadding,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '次回課題: ${course.nextAssignment!.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.nextAssignmentDueDate ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Status indicator
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                children: [
                  _buildStatusIndicator(context, course),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, TodayCourse course) {
    final theme = Theme.of(context);

    if (course.isCurrentlyInSession) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '授業中',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (course.hasEnded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '終了',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '予定',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }
}
