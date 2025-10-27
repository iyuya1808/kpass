import 'package:flutter/material.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/shared/models/module.dart';
import 'package:kpass/shared/widgets/empty_state_widget.dart';
import 'package:kpass/app/routes.dart';
import 'package:kpass/shared/widgets/canvas_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ModuleDetailScreen extends StatelessWidget {
  final Module module;

  const ModuleDetailScreen({super.key, required this.module});

  // Extract courseId from module items or use a passed parameter
  int get courseId {
    // If items exist, we can extract courseId from the module's items_url
    // Format: https://lms.keio.jp/api/v1/courses/132294/modules/2154670/items
    if (module.itemsUrl != null) {
      final match = RegExp(r'/courses/(\d+)/').firstMatch(module.itemsUrl!);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return 0; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = module.items ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(module.name),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // アイテムリスト
          Expanded(
            child: SafeArea(
              top: false,
              child:
                  items.isEmpty
                      ? EmptyStateWidget(
                        icon: Icons.inbox_outlined,
                        title: 'アイテムがありません',
                        message: 'このモジュールにはまだアイテムが追加されていません。',
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(
                          AppConstants.defaultPadding,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _ModuleItemCard(
                            item: items[index],
                            screen: this,
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItemCard extends StatelessWidget {
  final ModuleItem item;
  final ModuleDetailScreen screen;

  const _ModuleItemCard({required this.item, required this.screen});

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'page':
        return Icons.description;
      case 'file':
        return Icons.attach_file;
      case 'discussion':
        return Icons.forum;
      case 'externalurl':
        return Icons.link;
      case 'externaltool':
        return Icons.extension;
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
      case 'externaltool':
        return Colors.indigo;
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
      case 'externaltool':
        return '外部ツール';
      case 'quiz':
        return 'クイズ';
      case 'subheader':
        return 'セクション';
      default:
        return type;
    }
  }

  Future<void> _handleItemTap(
    BuildContext context,
    ModuleDetailScreen screen,
  ) async {
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
          'courseId': screen.courseId,
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
          'courseId': screen.courseId,
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
          'courseId': screen.courseId,
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

    // 外部ツールの場合はCanvas URLで開く
    if (type == 'externaltool' && item.htmlUrl != null) {
      await _launchUrlSafely(context, item.htmlUrl!);
      return;
    }

    // その他のタイプ：Canvas URLで開く（今後、各タイプ専用画面を実装予定）
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
    final isSubHeader = type == 'subheader';
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    // SubHeaderは特別なスタイル
    if (isSubHeader) {
      return Padding(
        padding: const EdgeInsets.only(
          top: AppConstants.defaultPadding,
          bottom: AppConstants.smallPadding,
        ),
        child: Row(
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
            Expanded(
              child: Text(
                item.title ?? 'セクション',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 通常のアイテム
    return Card(
      elevation: AppConstants.cardElevation,
      margin: EdgeInsets.only(
        bottom: AppConstants.defaultPadding,
        left: item.indent * 16.0,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleItemTap(context, screen),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? 'タイトルなし',
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                (type == 'externalurl' || type == 'externaltool')
                    ? Icons.open_in_new
                    : Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
