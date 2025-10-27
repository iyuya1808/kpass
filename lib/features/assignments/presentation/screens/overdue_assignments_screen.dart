import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/app/routes.dart';
import 'package:intl/intl.dart';

/// 期限超過課題一覧画面
class OverdueAssignmentsScreen extends StatefulWidget {
  const OverdueAssignmentsScreen({super.key});

  @override
  State<OverdueAssignmentsScreen> createState() =>
      _OverdueAssignmentsScreenState();
}

class _OverdueAssignmentsScreenState extends State<OverdueAssignmentsScreen> {
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

    // 非表示リストを最初に読み込む
    await assignmentsProvider.loadHiddenAssignments();

    // Load courses if not already loaded
    if (!coursesProvider.hasCourses) {
      await coursesProvider.loadCourses();
    }

    // Refresh assignments
    if (coursesProvider.hasCourses) {
      await assignmentsProvider.refresh(coursesProvider.courses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);

    // 期限超過の課題を取得し、期限日が新しい順（降順）にソート
    final overdueAssignments = assignmentsProvider.getOverdueAssignments();
    overdueAssignments.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return b.dueAt!.compareTo(a.dueAt!); // 新しい順
    });

    final isLoading = assignmentsProvider.isLoading;
    final isHiddenListInitialized = assignmentsProvider.isHiddenListInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('期限超過の課題'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除した課題',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.hiddenAssignments);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child:
            isLoading || !isHiddenListInitialized
                ? const Center(child: CircularProgressIndicator())
                : overdueAssignments.isEmpty
                ? EmptyStateWidget(
                  icon: Icons.check_circle_outline,
                  title: '期限超過の課題はありません',
                  message: 'すべての課題は期限内です。\nまたは正しく提出済みです。',
                  actionLabel: '更新',
                  onAction: _loadData,
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: overdueAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = overdueAssignments[index];
                    return _DismissibleAssignmentCard(
                      assignment: assignment,
                      onTap: () => _navigateToAssignmentDetail(assignment),
                      onDismissed: () => _hideAssignment(assignment),
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

  Future<void> _hideAssignment(Assignment assignment) async {
    final assignmentsProvider = Provider.of<AssignmentsProvider>(
      context,
      listen: false,
    );

    // 削除確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('課題を削除'),
            content: Text(
              '「${assignment.name}」をアプリ上から削除しますか？\n\n削除した課題は、右上の「ゴミ箱」マークから確認・復元できます。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await assignmentsProvider.hideAssignment(assignment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${assignment.name}」を削除しました'),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () {
                assignmentsProvider.unhideAssignment(assignment.id);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

/// スワイプで削除可能な課題カード
class _DismissibleAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _DismissibleAssignmentCard({
    required this.assignment,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('assignment_${assignment.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // onDismissedで確認ダイアログを表示するため、ここでは常にfalseを返す
        onDismissed();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.defaultPadding),
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              '削除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: _OverdueAssignmentCard(assignment: assignment, onTap: onTap),
    );
  }
}

/// 期限超過課題カードウィジェット（展開可能）
class _OverdueAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _OverdueAssignmentCard({required this.assignment, required this.onTap});

  String _formatOverdueDuration(DateTime dueDate) {
    final now = DateTime.now();
    final difference = now.difference(dueDate);

    if (difference.inDays == 0) {
      return '期限超過（今日）';
    } else if (difference.inDays == 1) {
      return '期限超過（1日前）';
    } else {
      return '期限超過（${difference.inDays}日前）';
    }
  }

  String _formatDueDate(DateTime dueDate) {
    return DateFormat('M月d日(E) HH:mm', 'ja').format(dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = assignment.dueAt;

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_late,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: Text(
            assignment.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                const SizedBox(height: 4),
              ],
              if (dueDate != null)
                Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      _formatOverdueDuration(dueDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          trailing: const Icon(Icons.expand_more, size: 24),
          onExpansionChanged: (_) {},
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.defaultPadding,
                0,
                AppConstants.defaultPadding,
                AppConstants.defaultPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: AppConstants.smallPadding),

                  // 期限日の詳細
                  if (dueDate != null) ...[
                    _buildInfoRow(
                      context,
                      Icons.access_time,
                      '期限日',
                      _formatDueDate(dueDate),
                      isError: true,
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                  ],

                  // ポイント
                  if (assignment.pointsPossible != null) ...[
                    _buildInfoRow(
                      context,
                      Icons.grade,
                      '配点',
                      '${assignment.pointsPossible}点',
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                  ],

                  // 提出タイプ
                  if (assignment.submissionTypes != null &&
                      assignment.submissionTypes!.isNotEmpty) ...[
                    _buildInfoRow(
                      context,
                      Icons.upload_file,
                      '提出方法',
                      _formatSubmissionTypes(assignment.submissionTypes!),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                  ],

                  // 詳細説明
                  if (assignment.description != null &&
                      assignment.description!.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      '説明',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _stripHtmlTags(assignment.description!),
                        style: theme.textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                  ],

                  // 詳細を見るボタン
                  const SizedBox(height: AppConstants.smallPadding),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('課題の詳細を見る'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final color = isError ? Colors.red : theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: isError ? Colors.red : null,
                    fontWeight: isError ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatSubmissionTypes(List<String> types) {
    final typeMap = {
      'online_text_entry': 'テキスト入力',
      'online_url': 'URL',
      'online_upload': 'ファイルアップロード',
      'media_recording': 'メディア録音',
      'on_paper': '紙',
      'external_tool': '外部ツール',
      'none': 'なし',
    };

    return types.map((type) => typeMap[type] ?? type).join('、');
  }

  String _stripHtmlTags(String html) {
    // 簡易的なHTMLタグ除去
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
