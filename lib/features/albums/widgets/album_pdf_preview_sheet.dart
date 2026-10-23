import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/ink_metadata_pill.dart';
import '../models/album_spread.dart';
import '../services/album_pdf_exporter.dart';

/// Bottom sheet allowing the user to select the PDF photobook format
/// ([AlbumPdfPageFormat.a4Landscape] vs [AlbumPdfPageFormat.square]),
/// save the generated vector PDF locally, or share/print it via the OS sheet.
class AlbumPdfPreviewSheet extends StatefulWidget {
  final AlbumCollection collection;
  final List<AlbumSpread> spreads;
  final MediaSandboxService mediaService;
  final Future<Uint8List> Function(Uint8List)? imageTranscoder;
  final Future<String> Function(Uint8List bytes, String fileName)?
      customSaveHandler;
  final Future<void> Function(Uint8List bytes, String fileName)?
      customShareHandler;

  const AlbumPdfPreviewSheet({
    super.key,
    required this.collection,
    required this.spreads,
    required this.mediaService,
    this.imageTranscoder,
    this.customSaveHandler,
    this.customShareHandler,
  });

  static Future<void> show(
    BuildContext context, {
    required AlbumCollection collection,
    required List<AlbumSpread> spreads,
    required MediaSandboxService mediaService,
    Future<Uint8List> Function(Uint8List)? imageTranscoder,
    Future<String> Function(Uint8List bytes, String fileName)?
        customSaveHandler,
    Future<void> Function(Uint8List bytes, String fileName)? customShareHandler,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AlbumPdfPreviewSheet(
        collection: collection,
        spreads: spreads,
        mediaService: mediaService,
        imageTranscoder: imageTranscoder,
        customSaveHandler: customSaveHandler,
        customShareHandler: customShareHandler,
      ),
    );
  }

  @override
  State<AlbumPdfPreviewSheet> createState() => _AlbumPdfPreviewSheetState();
}

class _AlbumPdfPreviewSheetState extends State<AlbumPdfPreviewSheet> {
  AlbumPdfPageFormat _selectedFormat = AlbumPdfPageFormat.a4Landscape;
  bool _isGenerating = false;

  String _buildSafeFileName() {
    final sanitizedTitle = widget.collection.title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    final baseName = sanitizedTitle.isEmpty ? 'travel_album' : sanitizedTitle;
    final suffix =
        _selectedFormat == AlbumPdfPageFormat.a4Landscape ? 'A4' : 'Square';
    return '${baseName}_$suffix.pdf';
  }

  Future<Uint8List> _generateBytes() {
    return AlbumPdfExporter.generatePhotobookFromSpreads(
      spreads: widget.spreads,
      mediaService: widget.mediaService,
      format: _selectedFormat,
      imageTranscoder: widget.imageTranscoder,
    );
  }

  Future<void> _handleSaveLocal() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final bytes = await _generateBytes();
      final fileName = _buildSafeFileName();

      String savedPath;
      if (widget.customSaveHandler != null) {
        savedPath = await widget.customSaveHandler!(bytes, fileName);
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        savedPath = path_pkg.join(docsDir.path, fileName);
        final outFile = File(savedPath);
        outFile.writeAsBytesSync(bytes, flush: true);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画册 PDF 已保存：$savedPath'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出 PDF 失败：$error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _handleSharePdf() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final bytes = await _generateBytes();
      final fileName = _buildSafeFileName();

      if (widget.customShareHandler != null) {
        await widget.customShareHandler!(bytes, fileName);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享 PDF 失败：$error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return Container(
      key: const Key('album_pdf_preview_sheet'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: tokens.xuanGround,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.deckleBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '导出旅行影像纪念册 PDF',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '矢量宣纸装帧 · 双线书页边栏 · 朱砂印章',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 12,
                color: tokens.danmo,
              ),
            ),
            const SizedBox(height: 12),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  InkMetadataPill(
                    icon: Icons.auto_stories_outlined,
                    label: '共 ${widget.spreads.length} 页画幅',
                    isAccent: true,
                    maxWidth: 150,
                  ),
                  InkMetadataPill(
                    icon: Icons.lock_outline,
                    label: '100% 离线合成',
                    maxWidth: 140,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '选择画册开本',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.nongmo,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    tokens: tokens,
                    format: AlbumPdfPageFormat.a4Landscape,
                    key: const Key('pdf_format_a4_landscape'),
                    icon: Icons.crop_landscape,
                    title: 'A4 横版画册',
                    subtitle: '297 × 210 mm',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormatOption(
                    tokens: tokens,
                    format: AlbumPdfPageFormat.square,
                    key: const Key('pdf_format_square'),
                    icon: Icons.crop_square,
                    title: '方册画幅',
                    subtitle: '210 × 210 mm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.cinnabar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '正在编排宣纸画册...',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('album_pdf_save_button'),
                      onPressed: _handleSaveLocal,
                      icon: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: tokens.nongmo,
                      ),
                      label: Text(
                        '保存至本地',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          color: tokens.nongmo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('album_pdf_share_button'),
                      onPressed: _handleSharePdf,
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.cinnabar,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text(
                        '分享 / 打印',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required InkDiaryTokens tokens,
    required AlbumPdfPageFormat format,
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedFormat == format;

    return GestureDetector(
      key: key,
      onTap: () {
        setState(() => _selectedFormat = format);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? tokens.cinnabarWash : tokens.xuanPureLeaf,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? tokens.cinnabar : tokens.deckleBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? tokens.cinnabar : tokens.danmo,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? tokens.cinnabar : tokens.jiaomo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontLiterata,
                fontSize: 11,
                color: tokens.danmo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

