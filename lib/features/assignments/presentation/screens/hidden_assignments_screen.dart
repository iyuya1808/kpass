import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/app/routes.dart';
import 'package:intl/intl.dart';

/// 削除した課題一覧画面
class HiddenAssignmentsScreen extends StatefulWidget {
  const HiddenAssignmentsScreen({super.key});

  @override
  State<HiddenAssignmentsScreen> createState() =>
      _HiddenAssignmentsScreenState();
}

class _HiddenAssignmentsScreenState extends State<HiddenAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
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

    // 非表示リストを読み込む
    await assignmentsProvider.loadHiddenAssignments();

    // Load courses if not already loaded
    if (!coursesProvider.hasCourses) {
      await coursesProvider.loadCourses();
    }

    // Load assignments if needed
    if (!assignmentsProvider.hasAssignments && coursesProvider.hasCourses) {
      await assignmentsProvider.loadAssignments(coursesProvider.courses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);

    // 削除した課題を取得し、新しい順にソート
    final hiddenAssignments = assignmentsProvider.getHiddenAssignments();
    hiddenAssignments.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return b.dueAt!.compareTo(a.dueAt!);
    });

    final isLoading = assignmentsProvider.isLoading;
    final isHiddenListInitialized = assignmentsProvider.isHiddenListInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('削除した課題'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child:
            isLoading || !isHiddenListInitialized
                ? const Center(child: CircularProgressIndicator())
                : hiddenAssignments.isEmpty
                ? const EmptyStateWidget(
                  icon: Icons.delete_outline,
                  title: '削除した課題はありません',
                  message: '削除した課題がここに表示されます。',
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: hiddenAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = hiddenAssignments[index];
                    return _HiddenAssignmentCard(
                      assignment: assignment,
                      onRestore: () => _restoreAssignment(assignment),
                      onTap: () => _navigateToAssignmentDetail(assignment),
                    );
                  },
                ),
      ),
    );
  }

  void _navigateToAssignmentDetail(Assignment assignment) {
    Navigator.pushNamed(
      context,
      AppRoutes.assignmentDetail,
      arguments: {
        'courseId': assignment.courseId,
        'assignmentId': assignment.id,
        'assignmentTitle': assignment.name,
      },
    );
  }

  Future<void> _restoreAssignment(Assignment assignment) async {
    final assignmentsProvider = Provider.of<AssignmentsProvider>(
      context,
      listen: false,
    );

    await assignmentsProvider.unhideAssignment(assignment.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${assignment.name}」を復元しました'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// 削除した課題カードウィジェット
class _HiddenAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onRestore;
  final VoidCallback onTap;

  const _HiddenAssignmentCard({
    required this.assignment,
    required this.onRestore,
    required this.onTap,
  });

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return '期限なし';
    return DateFormat('M月d日(E) HH:mm', 'ja').format(dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = assignment.dueAt;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // アイコン
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),

              // 課題情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (assignment.courseName != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              assignment.courseName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
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
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 復元ボタン
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                tooltip: '復元',
                onPressed: onRestore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
