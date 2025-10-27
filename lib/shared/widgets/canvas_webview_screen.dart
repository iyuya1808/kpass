import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const CanvasWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<CanvasWebViewScreen> createState() => _CanvasWebViewScreenState();
}

class _CanvasWebViewScreenState extends State<CanvasWebViewScreen> {
  final CanvasApiClient _apiClient = CanvasApiClient();
  WebViewController? _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // プロキシサーバーからセッションクッキーを取得
      final sessionData = await _apiClient.getSessionCookies();
      final cookies = sessionData['cookies'] as List<dynamic>;

      // WebViewControllerを初期化
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.white)
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (NavigationRequest request) {
                  // サポートされていないURLスキームをチェック
                  final uri = Uri.parse(request.url);

                  // WebView内部スキーム（about:, javascript:, data:, blob:など）はそのまま処理
                  final internalSchemes = [
                    'about',
                    'javascript',
                    'data',
                    'blob',
                    'file',
                  ];
                  if (internalSchemes.contains(uri.scheme)) {
                    return NavigationDecision.navigate;
                  }

                  // http/https はWebViewで開く
                  if (uri.scheme == 'http' || uri.scheme == 'https') {
                    return NavigationDecision.navigate;
                  }

                  // mailto, tel などの外部アプリスキームは外部で開く
                  _launchExternalUrl(request.url);
                  return NavigationDecision.prevent;
                },
                onPageStarted: (String url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                    });
                  }
                },
                onPageFinished: (String url) async {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                  _updateNavigationState();
                },
                onWebResourceError: (WebResourceError error) {
                  debugPrint('WebView error: ${error.description}');
                  if (mounted && error.description.contains('未対応')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('このURLは外部アプリで開く必要があります'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            );

      // クッキーをセット
      final cookieManager = WebViewCookieManager();
      for (final cookie in cookies) {
        final cookieMap = cookie as Map<String, dynamic>;
        await cookieManager.setCookie(
          WebViewCookie(
            name: cookieMap['name'] as String,
            value: cookieMap['value'] as String,
            domain: cookieMap['domain'] as String,
            path: cookieMap['path'] as String,
          ),
        );
      }

      // ページを読み込み
      await _controller!.loadRequest(Uri.parse(widget.url));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('WebView initialization error: $e');
      if (mounted) {
        setState(() {
          _error = 'セッションの読み込みに失敗しました: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateNavigationState() async {
    if (_controller == null) return;

    final canGoBack = await _controller!.canGoBack();
    final canGoForward = await _controller!.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && _canGoBack) {
      await _controller!.goBack();
      return false;
    }
    return true;
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ブラウザで開けませんでした')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // メールアドレスの場合、端末のデフォルトメールアプリを開く
      if (uri.scheme == 'mailto') {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('メールアプリを開けませんでした')));
          }
        }
        return;
      }

      // 電話番号の場合、端末の電話アプリを開く
      if (uri.scheme == 'tel') {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('電話アプリを開けませんでした')));
          }
        }
        return;
      }

      // その他のカスタムURLスキーム
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('このURL（${uri.scheme}://）を開けませんでした')),
          );
        }
      }
    } catch (e) {
      debugPrint('URL launch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('URLを開く際にエラーが発生しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions:
              _error == null && _controller != null
                  ? [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed:
                          _canGoBack
                              ? () async {
                                await _controller!.goBack();
                                await _updateNavigationState();
                              }
                              : null,
                      tooltip: '戻る',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed:
                          _canGoForward
                              ? () async {
                                await _controller!.goForward();
                                await _updateNavigationState();
                              }
                              : null,
                      tooltip: '進む',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _controller!.reload();
                      },
                      tooltip: '再読み込み',
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_browser),
                      onPressed: _openInBrowser,
                      tooltip: 'ブラウザで開く',
                    ),
                  ]
                  : null,
        ),
        body: SafeArea(
          top: false,
          child:
              _error != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text('エラー', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              _initializeWebView();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  )
                  : _controller == null
                  ? Container(
                    color: Colors.white,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                  : Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (_isLoading)
                        Container(
                          color: Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
