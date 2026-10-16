import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import '../services/export_service.dart';
import '../services/file_selector_service.dart';

/// Modal dialog allowing users to choose export format and scope, saving in <= 3 taps.
class ExportDialog extends StatefulWidget {
  final AppDatabase database;
  final Entry? singleEntry;
  final FileSelectorService fileSelector;

  const ExportDialog({
    super.key,
    required this.database,
    this.singleEntry,
    this.fileSelector = const NativeFileSelectorService(),
  });

  static Future<void> show({
    required BuildContext context,
    required AppDatabase database,
    Entry? singleEntry,
    FileSelectorService? fileSelector,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        database: database,
        singleEntry: singleEntry,
        fileSelector: fileSelector ?? const NativeFileSelectorService(),
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
        entriesToExport = await widget.database.getAllActiveEntries();
      }

      if (entriesToExport.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No diary entries available to export.')),
        );
        Navigator.pop(context);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${entriesToExport.length} entries to $savedPath',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Diaries'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scope Selection (if opened with a specific entry)
            if (widget.singleEntry != null) ...[
              const Text(
                'Export Scope',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              SegmentedButton<ExportScope>(
                segments: const [
                  ButtonSegment(
                    value: ExportScope.single,
                    label: Text('This Entry'),
                    icon: Icon(Icons.description_outlined),
                  ),
                  ButtonSegment(
                    value: ExportScope.all,
                    label: Text('All Entries'),
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
              'File Format',
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
                    title: Text('Markdown (.md) with YAML Frontmatter'),
                    subtitle: Text('Best for Obsidian, Notion, Logseq, and preserving metadata tags.'),
                    value: ExportFormat.markdown,
                  ),
                  RadioListTile<ExportFormat>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Plain Text (.txt)'),
                    subtitle: Text('Clean human-readable formatted document.'),
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
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(_isExporting ? 'Exporting...' : 'Save File'),
        ),
      ],
    );
  }
}
