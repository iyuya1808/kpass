import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/shared/models/models.dart' as models;
import 'package:kpass/shared/widgets/canvas_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PageViewerScreen extends StatefulWidget {
  final int courseId;
  final String pageUrl;
  final String pageTitle;

  const PageViewerScreen({
    super.key,
    required this.courseId,
    required this.pageUrl,
    required this.pageTitle,
  });

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  final CanvasApiClient _apiClient = CanvasApiClient();
  models.Page? _page;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pageData = await _apiClient.getPage(
        widget.courseId,
        widget.pageUrl,
      );

      if (!mounted) return;

      setState(() {
        _page = models.Page.fromJson(pageData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'ページの読み込みに失敗しました: $e';
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

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);

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
      if (_isExternalService(url)) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      debugPrint('URL launch error: $e');
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
          builder: (context) => CanvasWebViewScreen(url: url, title: 'リンク'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('ページを読み込んでいます...'),
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
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text('エラー', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton.icon(
                onPressed: _loadPage,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_page == null || _page!.body == null || _page!.body!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'コンテンツがありません',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'このページにはまだコンテンツが追加されていません。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPage,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Html(
            data: _page!.body!,
            onLinkTap: (url, attributes, element) {
              if (url != null) {
                _launchUrl(url);
              }
            },
            style: {
              "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              "p": Style(
                margin: Margins.only(bottom: 12),
                fontSize: FontSize(16),
                lineHeight: LineHeight.number(1.6),
              ),
              "h1": Style(
                fontSize: FontSize(24),
                fontWeight: FontWeight.bold,
                margin: Margins.only(top: 16, bottom: 12),
              ),
              "h2": Style(
                fontSize: FontSize(22),
                fontWeight: FontWeight.bold,
                margin: Margins.only(top: 14, bottom: 10),
              ),
              "h3": Style(
                fontSize: FontSize(20),
                fontWeight: FontWeight.bold,
                margin: Margins.only(top: 12, bottom: 8),
              ),
              "h4": Style(
                fontSize: FontSize(18),
                fontWeight: FontWeight.w600,
                margin: Margins.only(top: 10, bottom: 8),
              ),
              "ul": Style(
                margin: Margins.only(bottom: 12),
                padding: HtmlPaddings.only(left: 20),
              ),
              "ol": Style(
                margin: Margins.only(bottom: 12),
                padding: HtmlPaddings.only(left: 20),
              ),
              "li": Style(margin: Margins.only(bottom: 6)),
              "a": Style(
                color: Theme.of(context).colorScheme.primary,
                textDecoration: TextDecoration.underline,
              ),
              "blockquote": Style(
                margin: Margins.only(top: 12, bottom: 12, left: 16),
                padding: HtmlPaddings.only(left: 12),
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                ),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
              ),
              "code": Style(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                fontFamily: 'monospace',
              ),
              "pre": Style(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: HtmlPaddings.all(12),
                margin: Margins.only(top: 12, bottom: 12),
                fontFamily: 'monospace',
              ),
              "img": Style(margin: Margins.only(top: 8, bottom: 8)),
              "table": Style(
                margin: Margins.only(top: 12, bottom: 12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              "th": Style(
                padding: HtmlPaddings.all(8),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                fontWeight: FontWeight.bold,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              "td": Style(
                padding: HtmlPaddings.all(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}
