import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/settings/presentation/providers/settings_provider.dart';
import 'package:kpass/shared/models/assignment.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/shared/widgets/upcoming_assignments_days_dialog.dart';
import 'package:kpass/app/routes.dart';
import 'package:intl/intl.dart';

/// 期限が近い課題一覧画面
class UpcomingAssignmentsScreen extends StatefulWidget {
  const UpcomingAssignmentsScreen({super.key});

  @override
  State<UpcomingAssignmentsScreen> createState() =>
      _UpcomingAssignmentsScreenState();
}

class _UpcomingAssignmentsScreenState extends State<UpcomingAssignmentsScreen> {
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

  List<Assignment> _getAllAssignments(AssignmentsProvider provider) {
    final availableAssignments =
        provider.isHiddenListInitialized
            ? provider.assignments
            : provider.allAssignments;

    final allAssignments = <Assignment>[];

    for (final assignment in availableAssignments) {
      try {
        if (assignment.dueAt == null) continue;

        // 期限超過も含めて全課題を表示
        allAssignments.add(assignment);
      } catch (e) {
        // 個別の課題の処理エラーは無視して続行
      }
    }

    // 期限が近い順（昇順）でソート（期限超過は最後）
    allAssignments.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;

      final now = DateTime.now();
      final aIsOverdue = a.dueAt!.isBefore(now);
      final bIsOverdue = b.dueAt!.isBefore(now);

      // 期限超過でない課題を優先
      if (aIsOverdue && !bIsOverdue) return 1;
      if (!aIsOverdue && bIsOverdue) return -1;

      // 同じ状態なら期限順
      return a.dueAt!.compareTo(b.dueAt!);
    });

    return allAssignments;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final allAssignments = _getAllAssignments(assignmentsProvider);
    final isLoading = assignmentsProvider.isLoading;
    final isHiddenListInitialized = assignmentsProvider.isHiddenListInitialized;
    final isPartialData = assignmentsProvider.isPartialData;
    final dataCompleteness = assignmentsProvider.dataCompleteness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('全課題一覧'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '表示範囲設定',
            onPressed: () {
              UpcomingAssignmentsDaysDialog.show(context, settingsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // データ取得状況の表示
            if (isPartialData && !isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                color: Colors.orange.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        '一部のコースから課題を取得できませんでした（${(dataCompleteness * 100).toInt()}%完了）',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: Text(
                        '再試行',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // メインコンテンツ
            Expanded(
              child:
                  isLoading || !isHiddenListInitialized
                      ? const Center(child: CircularProgressIndicator())
                      : allAssignments.isEmpty
                      ? EmptyStateWidget(
                        icon: Icons.check_circle_outline,
                        title: '課題はありません',
                        message: '期限を迎える課題はありません。\nまたは正しく提出済みです。',
                        actionLabel: '更新',
                        onAction: _loadData,
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(
                          AppConstants.defaultPadding,
                        ),
                        itemCount: allAssignments.length,
                        itemBuilder: (context, index) {
                          final assignment = allAssignments[index];
                          return _UpcomingAssignmentCard(
                            assignment: assignment,
                            onTap:
                                () => _navigateToAssignmentDetail(assignment),
                          );
                        },
                      ),
            ),
          ],
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
}

/// 期限が近い課題カードウィジェット（展開可能）
class _UpcomingAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _UpcomingAssignmentCard({
    required this.assignment,
    required this.onTap,
  });

  Color _getIconColor(ThemeData theme) {
    final dueDate = assignment.dueAt;
    if (dueDate == null) return theme.colorScheme.primary;

    final now = DateTime.now();
    final hoursUntilDue = dueDate.difference(now).inHours;

    if (assignment.isSubmitted) {
      return Colors.green;
    } else if (hoursUntilDue < 24) {
      return Colors.orange;
    } else {
      return theme.colorScheme.primary;
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    final dueDate = assignment.dueAt;
    if (dueDate == null)
      return theme.colorScheme.primary.withValues(alpha: 0.1);

    final now = DateTime.now();
    final hoursUntilDue = dueDate.difference(now).inHours;

    if (assignment.isSubmitted) {
      return Colors.green.withValues(alpha: 0.1);
    } else if (hoursUntilDue < 24) {
      return Colors.orange.withValues(alpha: 0.1);
    } else {
      return theme.colorScheme.primary.withValues(alpha: 0.1);
    }
  }

  IconData _getIcon() {
    return assignment.isSubmitted ? Icons.check_circle : Icons.assignment;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

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
              color: _getBackgroundColor(theme),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIcon(), color: _getIconColor(theme), size: 24),
          ),
          title: Text(
            assignment.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              decoration:
                  assignment.isSubmitted ? TextDecoration.lineThrough : null,
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
                    Icon(Icons.event, size: 14, color: _getIconColor(theme)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(dueDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getIconColor(theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (assignment.isSubmitted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
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
                      DateFormat('M月d日(E) HH:mm', 'ja').format(dueDate),
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
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
                TextSpan(text: value),
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
