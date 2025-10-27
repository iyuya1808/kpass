import 'package:flutter/material.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/shared/models/course_extensions.dart';

/// コースカードウィジェット
class CourseCard extends StatelessWidget {
  final CourseWithStats course;
  final VoidCallback? onTap;
  final bool isLoadingAssignments;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.isLoadingAssignments = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCourseColor(course.id),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              if (isLoadingAssignments)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: AppConstants.smallPadding / 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '課題を読み込み中...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    _buildStatChip(
                      context,
                      icon: Icons.assignment,
                      label: '課題',
                      value: '${course.assignmentsCount}',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    _buildStatChip(
                      context,
                      icon: Icons.event,
                      label: '期限近',
                      value: '${course.upcomingAssignmentsCount}',
                      color:
                          course.upcomingAssignmentsCount > 0
                              ? Colors.orange
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                    if (course.overdueCount > 0) ...[
                      const SizedBox(width: AppConstants.smallPadding),
                      _buildStatChip(
                        context,
                        icon: Icons.warning,
                        label: '超過',
                        value: '${course.overdueCount}',
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCourseColor(int courseId) {
    final colors = [
      const Color(0xFFEB5757), // Red
      const Color(0xFFF2994A), // Orange
      const Color(0xFFF2C94C), // Yellow
      const Color(0xFF27AE60), // Green
      const Color(0xFF2F80ED), // Blue
      const Color(0xFF9B51E0), // Purple
    ];
    return colors[courseId % colors.length];
  }
}
