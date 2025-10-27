import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/app/routes.dart';
import 'package:intl/intl.dart';

/// 課題サマリーカードウィジェット
class AssignmentSummaryCard extends StatelessWidget {
  final List<Assignment> upcomingAssignments;
  final VoidCallback? onViewAll;
  final bool isLoading;

  const AssignmentSummaryCard({
    super.key,
    required this.upcomingAssignments,
    this.onViewAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      '期限が近い課題',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: AppConstants.smallPadding),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('すべて表示', style: TextStyle(fontSize: 14)),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (upcomingAssignments.isEmpty && !isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.defaultPadding,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        '期限が近い課題はありません',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isLoading)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    upcomingAssignments.length > 3
                        ? 3
                        : upcomingAssignments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final assignment = upcomingAssignments[index];
                  return _buildAssignmentItem(context, assignment);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentItem(BuildContext context, Assignment assignment) {
    final theme = Theme.of(context);
    final dueDate = assignment.dueAt;
    final now = DateTime.now();
    final isOverdue = dueDate != null && dueDate.isBefore(now);
    final isUrgent = dueDate != null && dueDate.difference(now).inHours < 24;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // アイコン部分
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isOverdue
                      ? Colors.red.withValues(alpha: 0.1)
                      : isUrgent
                      ? Colors.orange.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              assignment.isSubmitted ? Icons.check_circle : Icons.assignment,
              color:
                  isOverdue
                      ? Colors.red
                      : isUrgent
                      ? Colors.orange
                      : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 課題情報部分（タップ可能）
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.assignmentDetail,
                  arguments: {
                    'courseId': assignment.courseId,
                    'assignmentId': assignment.id,
                    'assignmentTitle': assignment.name,
                  },
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 授業名
                    if (assignment.courseName != null &&
                        assignment.courseName!.isNotEmpty)
                      Text(
                        assignment.courseName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // 課題名
                    Text(
                      assignment.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration:
                            assignment.isSubmitted
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 期限日
                    if (dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color:
                                isOverdue
                                    ? Colors.red
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(dueDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isOverdue
                                      ? Colors.red
                                      : isUrgent
                                      ? Colors.orange
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isUrgent ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 提出状況バッジまたは矢印
          assignment.isSubmitted
              ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.smallPadding,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '提出済み',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      final daysPast = difference.inDays.abs();
      if (daysPast == 0) {
        return '期限超過（今日）';
      } else if (daysPast == 1) {
        return '期限超過（昨日）';
      } else {
        return '期限超過（$daysPast日前）';
      }
    }

    if (difference.inHours < 24) {
      if (difference.inHours < 1) {
        return 'あと${difference.inMinutes}分';
      }
      return 'あと${difference.inHours}時間';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日後 ${DateFormat('HH:mm').format(dueDate)}';
    } else {
      return DateFormat('M月d日(E) HH:mm', 'ja').format(dueDate);
    }
  }
}
