import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/features/courses/presentation/providers/courses_provider.dart';
import 'package:kpass/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/app/routes.dart';
import 'package:intl/intl.dart';
import 'package:kpass/shared/widgets/canvas_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Module> _modules = [];
  bool _isLoadingModules = false;
  String? _modulesError;
  final CanvasApiClient _apiClient = CanvasApiClient();
  final Map<int, bool> _moduleExpanded = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadModules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    if (!mounted) return;

    setState(() {
      _isLoadingModules = true;
      _modulesError = null;
    });

    try {
      final modulesData = await _apiClient.getModules(
        widget.courseId,
        include: ['items'],
      );

      if (!mounted) return;

      setState(() {
        _modules =
            modulesData
                .map((json) => Module.fromJson(json as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.position.compareTo(b.position));
        // 全モジュールをデフォルトで展開状態に
        for (var module in _modules) {
          _moduleExpanded[module.id] = true;
        }
        _isLoadingModules = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _modulesError = 'モジュールの読み込みに失敗しました: $e';
        _isLoadingModules = false;
      });
    }
  }

  void _showCourseInfo(Course course) {
    showDialog(
      context: context,
      builder: (context) => _CourseInfoDialog(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coursesProvider = Provider.of<CoursesProvider>(context);
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);

    final course = coursesProvider.getCourseById(widget.courseId);

    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('コースが見つかりません')),
        body: const Center(child: Text('このコースは存在しないか、削除されました。')),
      );
    }

    final courseAssignments =
        assignmentsProvider.assignments
            .where((a) => a.courseId == widget.courseId)
            .toList()
          ..sort((a, b) {
            if (a.dueAt == null && b.dueAt == null) return 0;
            if (a.dueAt == null) return 1;
            if (b.dueAt == null) return -1;
            return a.dueAt!.compareTo(b.dueAt!);
          });

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCourseInfo(course),
            tooltip: 'コース情報',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
            alpha: 0.7,
          ),
          tabs: const [
            Tab(text: 'モジュール', icon: Icon(Icons.folder_outlined)),
            Tab(text: '課題', icon: Icon(Icons.assignment_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // モジュールタブ
          _buildModulesTab(),
          // 課題タブ
          _buildAssignmentsTab(courseAssignments),
        ],
      ),
    );
  }

  Widget _buildModulesTab() {
    if (_isLoadingModules) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('モジュールを読み込んでいます...'),
          ],
        ),
      );
    }

    if (_modulesError != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'エラー',
        message: _modulesError!,
        actionLabel: '再試行',
        onAction: _loadModules,
      );
    }

    if (_modules.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.folder_outlined,
        title: 'モジュールがありません',
        message: 'このコースにはまだモジュールが作成されていません。',
        actionLabel: '更新',
        onAction: _loadModules,
      );
    }

    // 全て展開されているかチェック
    final allExpanded = _modules.every((m) => _moduleExpanded[m.id] == true);

    return RefreshIndicator(
      onRefresh: _loadModules,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
        ),
        itemCount: _modules.length + 1, // +1 for the button
        itemBuilder: (context, index) {
          // 最初のアイテムはボタン
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.smallPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final newState = !allExpanded;
                        for (var module in _modules) {
                          _moduleExpanded[module.id] = newState;
                        }
                      });
                    },
                    icon: Icon(
                      allExpanded ? Icons.unfold_less : Icons.unfold_more,
                      size: 16,
                    ),
                    label: Text(
                      allExpanded ? '全て折りたたみ' : '全て展開',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // モジュールカード
          final module = _modules[index - 1];
          return _ModuleCard(
            module: module,
            isExpanded: _moduleExpanded[module.id] ?? true,
            onToggleExpanded: (value) {
              setState(() {
                _moduleExpanded[module.id] = value;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildAssignmentsTab(List<Assignment> assignments) {
    if (assignments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: '課題がありません',
        message: 'このコースにはまだ課題がありません。',
        actionLabel: '更新',
        onAction: () {
          final coursesProvider = Provider.of<CoursesProvider>(
            context,
            listen: false,
          );
          final assignmentsProvider = Provider.of<AssignmentsProvider>(
            context,
            listen: false,
          );
          assignmentsProvider.loadAssignments(coursesProvider.courses);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final coursesProvider = Provider.of<CoursesProvider>(
          context,
          listen: false,
        );
        final assignmentsProvider = Provider.of<AssignmentsProvider>(
          context,
          listen: false,
        );
        await assignmentsProvider.loadAssignments(coursesProvider.courses);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          return _AssignmentCard(assignment: assignments[index]);
        },
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final Module module;
  final bool isExpanded;
  final ValueChanged<bool> onToggleExpanded;

  const _ModuleCard({
    required this.module,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  Color get _stateColor {
    switch (widget.module.state) {
      case 'completed':
        return Colors.green;
      case 'locked':
        return Colors.grey;
      case 'unlocked':
      case 'started':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData get _stateIcon {
    switch (widget.module.state) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'locked':
        return Icons.lock;
      case 'unlocked':
      case 'started':
        return Icons.lock_open;
      default:
        return Icons.help_outline;
    }
  }

  String get _stateText {
    switch (widget.module.state) {
      case 'completed':
        return '公開中';
      case 'locked':
        return 'ロック中';
      case 'unlocked':
      case 'started':
        return '利用可能';
      default:
        return widget.module.state ?? '不明';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.module.items ?? [];

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // モジュールヘッダー
          Container(
            color: Colors.grey[200],
            child: InkWell(
              onTap: () {
                widget.onToggleExpanded(!widget.isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _stateColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_stateIcon, color: _stateColor, size: 24),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap:
                                widget.module.isLocked
                                    ? null
                                    : () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.moduleDetail,
                                        arguments: widget.module,
                                      );
                                    },
                            child: Text(
                              widget.module.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _stateColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _stateText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _stateColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.module.itemsCount}件',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (widget.module.completedAt != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '公開日: ${DateFormat('yyyy/MM/dd').format(widget.module.completedAt!)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // アイテムリスト（展開時）
          if (widget.isExpanded && items.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                itemBuilder: (context, index) {
                  return _ModuleItemTile(
                    item: items[index],
                    module: widget.module,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ModuleItemTile extends StatelessWidget {
  final ModuleItem item;
  final Module module;

  const _ModuleItemTile({required this.item, required this.module});

  int get courseId {
    // moduleのitemsUrlからcourseIdを抽出
    // 例: "https://lms.keio.jp/api/v1/courses/122312/modules/2161766/items"
    final match = RegExp(r'/courses/(\d+)/').firstMatch(module.itemsUrl ?? '');
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0; // Fallback
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'page':
        return Icons.description;
      case 'file':
        return Icons.insert_drive_file;
      case 'discussion':
        return Icons.forum;
      case 'externalurl':
        return Icons.link;
      case 'quiz':
        return Icons.quiz;
      case 'subheader':
        return Icons.title;
      default:
        return Icons.article;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Colors.blue;
      case 'page':
        return Colors.green;
      case 'file':
        return Colors.purple;
      case 'discussion':
        return Colors.orange;
      case 'externalurl':
        return Colors.teal;
      case 'quiz':
        return Colors.red;
      case 'subheader':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return '課題';
      case 'page':
        return 'ページ';
      case 'file':
        return 'ファイル';
      case 'discussion':
        return 'ディスカッション';
      case 'externalurl':
        return '外部リンク';
      case 'quiz':
        return 'クイズ';
      case 'subheader':
        return 'セクション';
      default:
        return type;
    }
  }

  Future<void> _handleItemTap(BuildContext context) async {
    final type = item.type.toLowerCase();

    // SubHeaderはタップ不可
    if (type == 'subheader') {
      return;
    }

    // Pageタイプの場合はアプリ内でページビューアを開く
    if (type == 'page' && item.pageUrl != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.pageViewer,
        arguments: {
          'courseId': courseId,
          'pageUrl': item.pageUrl!,
          'pageTitle': item.title ?? 'ページ',
        },
      );
      return;
    }

    // Fileタイプの場合はアプリ内でファイルビューアを開く
    if (type == 'file' && item.contentId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.fileViewer,
        arguments: {
          'courseId': courseId,
          'fileId': item.contentId!,
          'fileTitle': item.title ?? 'ファイル',
        },
      );
      return;
    }

    // Assignmentタイプの場合はアプリ内で課題詳細を開く
    if (type == 'assignment' && item.contentId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.assignmentDetail,
        arguments: {
          'courseId': courseId,
          'assignmentId': item.contentId!,
          'assignmentTitle': item.title ?? '課題',
        },
      );
      return;
    }

    // 外部URLの場合はブラウザで開く
    if (type == 'externalurl' && item.externalUrl != null) {
      await _launchUrlSafely(context, item.externalUrl!);
      return;
    }

    // その他のタイプ：Canvas URLで開く
    if (item.htmlUrl != null) {
      await _launchUrlSafely(context, item.htmlUrl!);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('このアイテムは開けません')));
      }
    }
  }

  bool _isExternalService(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // 外部サービスのドメインリスト
      final externalDomains = [
        'drive.google.com',
        'docs.google.com',
        'sheets.google.com',
        'slides.google.com',
        'forms.google.com',
        'youtube.com',
        'youtu.be',
        'dropbox.com',
        'onedrive.live.com',
      ];

      return externalDomains.any((domain) => host.contains(domain));
    } catch (e) {
      return false;
    }
  }

  Future<void> _launchUrlSafely(BuildContext context, String urlString) async {
    try {
      final url = Uri.parse(urlString);

      if (!url.hasScheme) {
        throw Exception('無効なURL');
      }

      // WebView内部スキーム（about:, javascript:, data:, blob:など）は無視
      final internalSchemes = ['about', 'javascript', 'data', 'blob', 'file'];
      if (internalSchemes.contains(url.scheme)) {
        return;
      }

      // http/https以外のスキーム（tel:, mailto:など）は外部アプリで開く
      if (!url.isScheme('http') && !url.isScheme('https')) {
        // メールアドレスの場合、端末のデフォルトメールアプリを開く
        if (url.scheme == 'mailto') {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('メールアプリを開けませんでした')));
          }
          return;
        }

        // 電話番号の場合、端末の電話アプリを開く
        if (url.scheme == 'tel') {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('電話アプリを開けませんでした')));
          }
          return;
        }

        // その他のカスタムURLスキーム
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('このURL（${url.scheme}://）を開けませんでした')),
          );
        }
        return;
      }

      // 外部サービスの場合はアプリで開く試行
      if (_isExternalService(urlString)) {
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (e) {
          // アプリで開けない場合は下でWebViewで開く
        }
      }

      // Canvas LMS内部またはアプリで開けない場合はWebViewで開く
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CanvasWebViewScreen(url: urlString, title: 'リンク'),
          ),
        );
      }
    } catch (e) {
      debugPrint('URL launch error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('URLを開けませんでした: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = item.type.toLowerCase();
    final color = _getColorForType(type);
    final icon = _getIconForType(type);
    final typeLabel = _getTypeLabel(type);
    final isClickable = type != 'subheader';

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      enabled: isClickable,
      onTap: isClickable ? () => _handleItemTap(context) : null,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        item.title ?? '名称未設定',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: type == 'subheader' ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        typeLabel,
        style: theme.textTheme.bodySmall?.copyWith(color: color, fontSize: 11),
      ),
      trailing:
          isClickable
              ? Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              )
              : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 0,
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (assignment.isSubmitted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = '提出済み';
    } else if (assignment.submission != null &&
        assignment.submission!['workflow_state'] == 'draft') {
      statusColor = Colors.orange;
      statusIcon = Icons.edit;
      statusText = '下書き保存';
    } else if (assignment.hasSubmittedSubmissions == true &&
        !assignment.isSubmitted) {
      statusColor = Colors.amber;
      statusIcon = Icons.warning;
      statusText = '提出物あり（未完了）';
    } else if (assignment.isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = '期限超過';
    } else if (assignment.dueAt != null &&
        assignment.dueAt!.difference(now).inDays <= 7) {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
      statusText = '期限近';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.assignment;
      statusText = '未提出';
    }

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to assignment detail
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
              if (assignment.dueAt != null) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '期限: ${DateFormat('yyyy/MM/dd HH:mm').format(assignment.dueAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (assignment.pointsPossible != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '配点: ${assignment.pointsPossible}点',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseInfoDialog extends StatelessWidget {
  final Course course;

  const _CourseInfoDialog({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('コース情報')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(icon: Icons.school, label: 'コース名', value: course.name),
            const SizedBox(height: AppConstants.defaultPadding),
            _InfoRow(
              icon: Icons.code,
              label: 'コースコード',
              value: course.courseCode,
            ),
            if (course.description != null &&
                course.description!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _InfoRow(
                icon: Icons.description,
                label: '説明',
                value: course.description!,
              ),
            ],
            if (course.startAt != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _InfoRow(
                icon: Icons.event,
                label: '開始日',
                value: DateFormat('yyyy年MM月dd日').format(course.startAt!),
              ),
            ],
            if (course.endAt != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _InfoRow(
                icon: Icons.event_busy,
                label: '終了日',
                value: DateFormat('yyyy年MM月dd日').format(course.endAt!),
              ),
            ],
            if (course.enrollmentCount != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _InfoRow(
                icon: Icons.people,
                label: '受講者数',
                value: '${course.enrollmentCount}人',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
