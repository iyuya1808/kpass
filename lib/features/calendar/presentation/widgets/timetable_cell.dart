import 'package:flutter/material.dart';
import 'package:kpass/shared/models/weekly_schedule.dart';
import 'package:kpass/core/constants/app_constants.dart';

/// 時間割テーブルの各セルを表現するウィジェット
class TimetableCell extends StatelessWidget {
  final WeeklyCourse? course;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isToday;
  final bool isCurrentPeriod;

  const TimetableCell({
    super.key,
    this.course,
    this.onTap,
    this.onLongPress,
    this.isToday = false,
    this.isCurrentPeriod = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (course == null) {
      // 空のセル
      return _buildEmptyCell(theme);
    }

    // 授業があるセル
    return _buildCourseCell(theme);
  }

  Widget _buildEmptyCell(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color:
            isToday
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                )
                : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(4),
            child:
                isToday && isCurrentPeriod
                    ? Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    )
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCell(ThemeData theme) {
    final course = this.course!;

    // コースカラーを生成（コースIDベース）
    final courseColor = _generateCourseColor(course.courseId, theme);

    return Container(
      decoration: BoxDecoration(
        color: courseColor.withValues(alpha: 0.1),
        border: Border.all(color: courseColor.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // コース名
                Expanded(
                  child: Text(
                    course.courseName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: courseColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 教室情報（あれば）
                if (course.location != null && course.location!.isNotEmpty)
                  Text(
                    course.location!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// コースIDから一意の色を生成
  Color _generateCourseColor(int courseId, ThemeData theme) {
    if (courseId == 0) {
      return theme.colorScheme.primary;
    }

    // コースIDをハッシュ化して色を生成
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return colors[courseId % colors.length];
  }
}

/// 時間割セルの詳細情報を表示するボトムシート
class TimetableCellDetailsSheet extends StatelessWidget {
  final WeeklyCourse course;

  const TimetableCellDetailsSheet({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(Icons.school, color: theme.colorScheme.primary),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Text(
                  course.courseName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // 詳細情報
          _buildDetailRow(context, Icons.schedule, '時限', course.periodLabel),

          _buildDetailRow(context, Icons.access_time, '時間', course.timeRange),

          _buildDetailRow(
            context,
            Icons.calendar_today,
            '曜日',
            course.weekdayName,
          ),

          if (course.location != null && course.location!.isNotEmpty)
            _buildDetailRow(context, Icons.location_on, '教室', course.location!),

          if (course.description != null && course.description!.isNotEmpty)
            _buildDetailRow(
              context,
              Icons.description,
              '説明',
              course.description!,
            ),

          const SizedBox(height: AppConstants.defaultPadding),

          // アクションボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: コース詳細画面への遷移
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('コース詳細を見る'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// ボトムシートを表示
  static void show(BuildContext context, WeeklyCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: TimetableCellDetailsSheet(course: course),
          ),
    );
  }
}
