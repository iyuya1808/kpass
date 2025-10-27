import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kpass/core/constants/app_constants.dart';
import 'package:kpass/core/services/canvas_api_client.dart';
import 'package:kpass/shared/models/models.dart' as models;
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

class FileViewerScreen extends StatefulWidget {
  final int courseId;
  final int fileId;
  final String fileTitle;

  const FileViewerScreen({
    super.key,
    required this.courseId,
    required this.fileId,
    required this.fileTitle,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  final CanvasApiClient _apiClient = CanvasApiClient();
  models.CanvasFile? _file;
  PdfDocument? _pdfDocument;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fileData = await _apiClient.getFile(widget.courseId, widget.fileId);

      if (!mounted) return;

      final file = models.CanvasFile.fromJson(fileData);

      // PDFファイルの場合、ダウンロードしてプレビュー
      if (file.isPdf) {
        await _loadPdf();
      }

      setState(() {
        _file = file;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'ファイルの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdf() async {
    try {
      // プロキシ経由でPDFをダウンロード
      final bytes = await _apiClient.downloadFile(widget.fileId);
      final uint8List = Uint8List.fromList(bytes);
      _pdfDocument = await PdfDocument.openData(uint8List);

      if (kDebugMode) {
        debugPrint('PDF loaded successfully, size: ${bytes.length}');
      }
    } catch (e) {
      debugPrint('PDF load error: $e');
      // PDFロードに失敗してもファイル情報は表示
    }
  }

  Future<void> _downloadFile() async {
    if (_file == null) return;

    try {
      final url = Uri.parse(_file!.url);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ファイルを開けませんでした')));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_file != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadFile,
              tooltip: 'ダウンロード',
            ),
        ],
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
            Text('ファイルを読み込んでいます...'),
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
                onPressed: _loadFile,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_file == null) {
      return const Center(child: Text('ファイルが見つかりません'));
    }

    // PDFプレビュー
    if (_file!.isPdf && _pdfDocument != null) {
      return SafeArea(
        child: PdfView(
          controller: PdfController(document: Future.value(_pdfDocument!)),
        ),
      );
    }

    // PDFだがロードに失敗、または他のファイルタイプ
    return _buildFileInfo();
  }

  Widget _buildFileInfo() {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ファイルアイコン
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getFileIcon(),
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),

            // ファイル名
            Text(
              _file!.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // ファイル情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.insert_drive_file,
                      'ファイルタイプ',
                      _file!.mimeClass ?? _file!.contentType ?? '不明',
                    ),
                    const Divider(height: AppConstants.defaultPadding),
                    _buildInfoRow(
                      context,
                      Icons.data_usage,
                      'ファイルサイズ',
                      _file!.formattedSize,
                    ),
                    if (_file!.createdAt != null) ...[
                      const Divider(height: AppConstants.defaultPadding),
                      _buildInfoRow(
                        context,
                        Icons.calendar_today,
                        'アップロード日',
                        '${_file!.createdAt!.year}/${_file!.createdAt!.month}/${_file!.createdAt!.day}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),

            // ダウンロードボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadFile,
                icon: const Icon(Icons.download),
                label: const Text('ダウンロード'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                ),
              ),
            ),

            if (_file!.isPdf && _pdfDocument == null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        'PDFのプレビューを読み込めませんでした。ダウンロードして開いてください。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        Icon(icon, size: 20, color: theme.colorScheme.primary),
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
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon() {
    if (_file == null) return Icons.insert_drive_file;

    if (_file!.isPdf) return Icons.picture_as_pdf;
    if (_file!.isImage) return Icons.image;

    final contentType = _file!.contentType?.toLowerCase() ?? '';
    final displayName = _file!.displayName.toLowerCase();

    if (contentType.contains('word') ||
        displayName.endsWith('.doc') ||
        displayName.endsWith('.docx')) {
      return Icons.description;
    }
    if (contentType.contains('excel') ||
        displayName.endsWith('.xls') ||
        displayName.endsWith('.xlsx')) {
      return Icons.table_chart;
    }
    if (contentType.contains('powerpoint') ||
        displayName.endsWith('.ppt') ||
        displayName.endsWith('.pptx')) {
      return Icons.slideshow;
    }
    if (contentType.contains('video') ||
        displayName.endsWith('.mp4') ||
        displayName.endsWith('.mov')) {
      return Icons.video_file;
    }
    if (contentType.contains('audio') ||
        displayName.endsWith('.mp3') ||
        displayName.endsWith('.wav')) {
      return Icons.audio_file;
    }
    if (contentType.contains('zip') ||
        displayName.endsWith('.zip') ||
        displayName.endsWith('.rar')) {
      return Icons.folder_zip;
    }

    return Icons.insert_drive_file;
  }
}
