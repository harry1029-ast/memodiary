import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import '../services/export_service.dart';
import '../services/file_selector_service.dart';
import 'pdf_preview_screen.dart';

/// Modal dialog allowing users to choose export format and scope, saving in <= 3 taps.
class ExportDialog extends StatefulWidget {
  final AppDatabase database;
  final Entry? singleEntry;
  final FileSelectorService fileSelector;
  final MediaSandboxService? mediaService;

  const ExportDialog({
    super.key,
    required this.database,
    this.singleEntry,
    this.fileSelector = const NativeFileSelectorService(),
    this.mediaService,
  });

  static Future<void> show({
    required BuildContext context,
    required AppDatabase database,
    Entry? singleEntry,
    FileSelectorService? fileSelector,
    MediaSandboxService? mediaService,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        database: database,
        singleEntry: singleEntry,
        fileSelector: fileSelector ?? const NativeFileSelectorService(),
        mediaService: mediaService,
      ),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.markdown;
  late ExportScope _selectedScope;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedScope =
        widget.singleEntry != null ? ExportScope.single : ExportScope.all;
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      List<Entry> entriesToExport;
      if (_selectedScope == ExportScope.single && widget.singleEntry != null) {
        entriesToExport = [widget.singleEntry!];
      } else {
        entriesToExport = await widget.database.entriesDao.getAllActiveEntries();
      }

      if (entriesToExport.isEmpty) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('没有可导出的日记')),
        );
        Navigator.pop(context);
        return;
      }

      if (_selectedFormat == ExportFormat.pdf) {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => PdfPreviewScreen(
              singleEntry: _selectedScope == ExportScope.single ? widget.singleEntry : null,
              entries: _selectedScope == ExportScope.single ? null : entriesToExport,
              database: widget.database,
              mediaService: widget.mediaService,
            ),
          ),
        );
        return;
      }

      final savedPath = await ExportService.saveToFile(
        entries: entriesToExport,
        format: _selectedFormat,
        fileSelector: widget.fileSelector,
      );

      if (!mounted) return;

      if (savedPath != null) {
        Navigator.pop(context);
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '已导出 ${entriesToExport.length} 篇日记到 $savedPath',
            ),
          ),
        );
      } else {
        // User cancelled picker
        setState(() => _isExporting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出日记'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scope Selection (if opened with a specific entry)
            if (widget.singleEntry != null) ...[
              const Text(
                '导出范围',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              SegmentedButton<ExportScope>(
                segments: const [
                  ButtonSegment(
                    value: ExportScope.single,
                    label: Text('当前日记'),
                    icon: Icon(Icons.description_outlined),
                  ),
                  ButtonSegment(
                    value: ExportScope.all,
                    label: Text('全部日记'),
                    icon: Icon(Icons.folder_zip_outlined),
                  ),
                ],
                selected: {_selectedScope},
                onSelectionChanged: (val) {
                  setState(() => _selectedScope = val.first);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Format Selection
            const Text(
              '文件格式',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            RadioGroup<ExportFormat>(
              groupValue: _selectedFormat,
              onChanged: (val) {
                if (val != null) setState(() => _selectedFormat = val);
              },
              child: const Column(
                children: [
                  RadioListTile<ExportFormat>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('高清排版 PDF (.pdf)'),
                    subtitle: Text('保留信纸样式、照片和字体的矢量排版文件'),
                    value: ExportFormat.pdf,
                  ),
                  RadioListTile<ExportFormat>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Markdown (.md) 含元数据'),
                    subtitle: Text('适合导入 Obsidian、Notion 等工具，保留日期与标签'),
                    value: ExportFormat.markdown,
                  ),
                  RadioListTile<ExportFormat>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('纯文本 (.txt)'),
                    subtitle: Text('简洁易读的纯文本文档'),
                    value: ExportFormat.plainText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(_selectedFormat == ExportFormat.pdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.file_download_outlined),
          label: Text(_selectedFormat == ExportFormat.pdf
              ? '预览 PDF'
              : (_isExporting ? '导出中...' : '保存文件')),
        ),
      ],
    );
  }
}
