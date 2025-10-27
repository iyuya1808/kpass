import 'package:flutter/material.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/shared/models/models.dart';
import 'package:kpass/shared/widgets/canvas_webview_screen.dart';
import 'package:kpass/shared/widgets/custom_app_bar.dart';
import 'package:kpass/app/routes.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final int courseId;
  final int assignmentId;
  final String assignmentTitle;

  const AssignmentDetailScreen({
    super.key,
    required this.courseId,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final CanvasApiClient _apiClient = CanvasApiClient();
  Assignment? _assignment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 課題データとコース情報を並行して取得
      final futures = await Future.wait([
        _apiClient.getAssignment(widget.courseId, widget.assignmentId),
        _apiClient.getCourses(),
      ]);

      if (!mounted) return;

      final assignmentData = futures[0] as Map<String, dynamic>;
      final coursesData = futures[1] as List<dynamic>;

      // コース情報からcourse_nameを追加
      final courseId = assignmentData['course_id'] as int?;

      if (courseId != null) {
        try {
          final course = coursesData.firstWhere((c) => c['id'] == courseId);
          assignmentData['course_name'] = course['name'];
        } catch (e) {
          // コースが見つからない場合はcourse_nameを設定しない
        }
      }

      final assignment = Assignment.fromJson(assignmentData);

      setState(() {
        _assignment = assignment;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '課題の読み込みに失敗しました: $e';
        _isLoading = false;
      });
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

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);

      // WebView内部スキーム（about:, javascript:, data:, blob:など）は無視
      final internalSchemes = ['about', 'javascript', 'data', 'blob', 'file'];
      if (internalSchemes.contains(uri.scheme)) {
        return;
      }

      // http/https以外のスキーム（tel:, mailto:など）は外部アプリで開く
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        // メールアドレスの場合、端末のデフォルトメールアプリを開く
        if (uri.scheme == 'mailto') {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('メールアプリを開けませんでした')));
          }
          return;
        }

        // 電話番号の場合、端末の電話アプリを開く
        if (uri.scheme == 'tel') {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('電話アプリを開けませんでした')));
          }
          return;
        }

        // その他のカスタムURLスキーム
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('このURL（${uri.scheme}://）を開けませんでした')),
          );
        }
        return;
      }

      // 外部サービスの場合はアプリで開く試行
      if (_isExternalService(urlString)) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('URLを開く際にエラーが発生しました: $e')));
        return;
      }
    }

    // Canvas LMS内部またはアプリで開けない場合はWebViewで開く
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CanvasWebViewScreen(url: urlString, title: 'リンク'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.assignmentTitle,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('課題を読み込んでいます...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text('エラー', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton.icon(
                onPressed: _loadAssignment,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignment == null) {
      return const Center(child: Text('課題が見つかりません'));
    }

    return RefreshIndicator(
      onRefresh: _loadAssignment,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.defaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // コース名
              if (_assignment?.courseName != null &&
                  _assignment!.courseName!.isNotEmpty) ...[
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.courseDetail,
                      arguments: widget.courseId,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _assignment!.courseName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
              ],

              // Status badges
              _buildStatusBadges(),
              const SizedBox(height: AppConstants.defaultPadding),

              // Lock explanation
              if (_assignment!.lockedForUser == true &&
                  _assignment!.lockExplanation != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.orange),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Text(
                            _assignment!.lockExplanation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // Submit button (top)
              if (_assignment!.htmlUrl != null) ...[
                _buildSubmitButton(),
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // Description
              if (_assignment!.description != null &&
                  _assignment!.description!.isNotEmpty) ...[
                Text(
                  '説明',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      child: Html(
                        data: _assignment!.description,
                        onLinkTap: (url, attributes, element) {
                          if (url != null) {
                            _launchUrl(url);
                          }
                        },
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          "p": Style(
                            margin: Margins.only(bottom: 8),
                            fontSize: FontSize(16),
                            lineHeight: LineHeight.number(1.6),
                          ),
                          "a": Style(
                            color: theme.colorScheme.primary,
                            textDecoration: TextDecoration.underline,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // Assignment info card
              _buildInfoCard(),
              const SizedBox(height: AppConstants.defaultPadding),

              // Submission info
              _buildSubmissionInfo(),

              // Submit button (bottom)
              if (_assignment!.htmlUrl != null) ...[
                const SizedBox(height: AppConstants.largePadding),
                _buildSubmitButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadges() {
    final badges = <Widget>[];

    // 公開状態の表示
    if (_assignment!.published == true) {
      if (_assignment!.lockedForUser == true) {
        // 公開されているがロックされている場合は「閲覧のみ」
        badges.add(
          Chip(
            label: const Text('閲覧のみ'),
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: Colors.blue.shade900),
            avatar: Icon(Icons.visibility, size: 16, color: Colors.blue),
          ),
        );
      } else {
        // 通常の公開中（提出可能）
        badges.add(
          Chip(
            label: const Text('公開中'),
            backgroundColor: Colors.green.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: Colors.green.shade900),
            avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
          ),
        );
      }
    }

    // 提出がロックされている場合
    if (_assignment!.lockedForUser == true) {
      badges.add(
        Chip(
          label: const Text('提出不可'),
          backgroundColor: Colors.orange.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: Colors.orange.shade900),
          avatar: Icon(Icons.lock_clock, size: 16, color: Colors.orange),
        ),
      );
    }

    // 提出状況に応じたバッジを表示
    final submissionStatus = _assignment!.submissionStatus;
    final statusDescription = submissionStatus['statusDescription'] as String;
    final workflowState = submissionStatus['workflowState'] as String?;

    if (_assignment!.isSubmitted) {
      badges.add(
        Chip(
          label: Text(statusDescription),
          backgroundColor: Colors.green.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: Colors.green.shade900),
          avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
        ),
      );
    } else if (workflowState == 'draft') {
      badges.add(
        Chip(
          label: Text(statusDescription),
          backgroundColor: Colors.orange.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: Colors.orange.shade900),
          avatar: Icon(Icons.edit, size: 16, color: Colors.orange),
        ),
      );
    } else if (workflowState == 'unsubmitted' &&
        _assignment!.hasSubmittedSubmissions == true) {
      badges.add(
        Chip(
          label: const Text('提出物あり（未完了）'),
          backgroundColor: Colors.amber.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: Colors.amber.shade900),
          avatar: Icon(Icons.warning, size: 16, color: Colors.amber),
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }

  Widget _buildInfoCard() {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_assignment!.dueAt != null) ...[
                _buildInfoRow(
                  context,
                  Icons.event,
                  '提出期限',
                  dateFormat.format(_assignment!.dueAt!.toLocal()),
                  _assignment!.isOverdue
                      ? Colors.red
                      : _assignment!.isDueSoon
                      ? Colors.orange
                      : null,
                ),
                const Divider(height: AppConstants.defaultPadding),
              ],
              if (_assignment!.unlockAt != null) ...[
                _buildInfoRow(
                  context,
                  Icons.lock_open,
                  '公開日時',
                  dateFormat.format(_assignment!.unlockAt!.toLocal()),
                ),
                const Divider(height: AppConstants.defaultPadding),
              ],
              if (_assignment!.lockAt != null) ...[
                _buildInfoRow(
                  context,
                  Icons.lock_clock,
                  'ロック日時',
                  dateFormat.format(_assignment!.lockAt!.toLocal()),
                ),
                const Divider(height: AppConstants.defaultPadding),
              ],
              if (_assignment!.pointsPossible != null) ...[
                _buildInfoRow(
                  context,
                  Icons.grade,
                  '配点',
                  '${_assignment!.pointsPossible} 点',
                ),
                const Divider(height: AppConstants.defaultPadding),
              ],
              if (_assignment!.gradingType != null) ...[
                _buildInfoRow(
                  context,
                  Icons.assessment,
                  '採点方式',
                  _getGradingTypeDisplay(_assignment!.gradingType!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionInfo() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '提出情報',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              if (_assignment!.submissionTypes != null &&
                  _assignment!.submissionTypes!.isNotEmpty) ...[
                _buildInfoRow(
                  context,
                  Icons.upload_file,
                  '提出方法',
                  _getSubmissionTypesDisplay(_assignment!.submissionTypes!),
                ),
                if (_assignment!.allowedExtensions != null &&
                    _assignment!.allowedExtensions!.isNotEmpty) ...[
                  const Divider(height: AppConstants.defaultPadding),
                  _buildInfoRow(
                    context,
                    Icons.file_present,
                    '許可された拡張子',
                    _assignment!.allowedExtensions!
                        .map((e) => '.$e')
                        .join(', '),
                  ),
                ],
                const Divider(height: AppConstants.defaultPadding),
                _buildInfoRow(
                  context,
                  Icons.replay,
                  '提出回数',
                  _assignment!.allowedAttempts == -1
                      ? '無制限'
                      : '${_assignment!.allowedAttempts ?? 1} 回',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, [
    Color? color,
  ]) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        const SizedBox(width: AppConstants.smallPadding),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGradingTypeDisplay(String gradingType) {
    switch (gradingType) {
      case 'points':
        return '点数';
      case 'percent':
        return 'パーセント';
      case 'pass_fail':
        return '合格/不合格';
      case 'letter_grade':
        return 'レターグレード';
      case 'gpa_scale':
        return 'GPAスケール';
      case 'not_graded':
        return '採点なし';
      default:
        return gradingType;
    }
  }

  String _getSubmissionTypesDisplay(List<String> types) {
    return types
        .map((type) {
          switch (type) {
            case 'online_text_entry':
              return 'テキスト入力';
            case 'online_url':
              return 'URL';
            case 'online_upload':
              return 'ファイルアップロード';
            case 'media_recording':
              return 'メディア録画';
            case 'on_paper':
              return '用紙';
            case 'external_tool':
              return '外部ツール';
            case 'online_quiz':
              return 'オンラインクイズ';
            case 'discussion_topic':
              return 'ディスカッション';
            default:
              return type;
          }
        })
        .join(', ');
  }

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CanvasWebViewScreen(
                    url: _assignment!.htmlUrl!,
                    title: widget.assignmentTitle,
                  ),
            ),
          );
        },
        icon: const Icon(Icons.open_in_browser),
        label: const Text('提出ページ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.defaultPadding,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
