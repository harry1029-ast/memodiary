import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/sandboxed_image_embed_builder.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import 'package:memodiary/features/templates/widgets/template_switcher_sheet.dart';
import 'package:memodiary/features/import_export/widgets/export_dialog.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';

/// Read-only detail viewer displaying the entry inside its procedural canvas template
/// with rich-text styling, sandboxed media embeds, and quick management actions.
class EntryDetailScreen extends StatefulWidget {
  final Entry entry;
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final Future<void> Function(String text, {String? subject})? shareHandler;

  const EntryDetailScreen({
    super.key,
    required this.entry,
    required this.database,
    required this.mediaService,
    this.shareHandler,
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late Entry _entry;
  Template? _template;
  quill.QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _loadData();
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Refresh entry from database if available
      final freshEntry = await widget.database.getEntryById(_entry.id);
      if (freshEntry != null) {
        _entry = freshEntry;
      }

      // Load active template
      _template = await widget.database.getTemplateById(_entry.templateId);
      if (_template == null) {
        final allTemplates = await widget.database.getAllTemplates();
        if (allTemplates.isNotEmpty) {
          _template = allTemplates.first;
        }
      }

      // Build read-only QuillController
      quill.Document doc;
      if (_entry.contentDelta.isNotEmpty) {
        try {
          final decoded = jsonDecode(_entry.contentDelta);
          doc = quill.Document.fromJson(decoded);
        } catch (_) {
          doc = quill.Document()..insert(0, _entry.plainText);
        }
      } else {
        doc = quill.Document()..insert(0, _entry.plainText);
      }

      _quillController?.dispose();
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      debugPrint('Error loading entry detail: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSwitchTemplate() async {
    final templates = await widget.database.getAllTemplates();
    if (!mounted) return;

    await TemplateSwitcherSheet.show(
      context: context,
      templates: templates,
      currentTemplateId: _entry.templateId,
      database: widget.database,
      onTemplateSelected: (newTemplate) async {
        await widget.database.updateEntryTemplate(_entry.id, newTemplate.id);
        setState(() {
          _template = newTemplate;
          _entry = _entry.copyWith(templateId: newTemplate.id);
        });
      },
    );
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(
          database: widget.database,
          mediaSandboxService: widget.mediaService,
          entryId: _entry.id,
        ),
      ),
    );

    // Reload content upon returning from editor
    if (result == true || mounted) {
      await _loadData();
    }
  }

  Future<void> _handleShare() async {
    final dateStr = DateFormat('yyyy-MM-dd EEEE').format(_entry.entryDate);
    final titleStr = (_entry.title?.trim().isNotEmpty ?? false)
        ? '${_entry.title!.trim()}\n\n'
        : '';
    final fullShareText = '$titleStr$dateStr\n\n${_entry.plainText}';

    if (widget.shareHandler != null) {
      await widget.shareHandler!(fullShareText, subject: _entry.title);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: fullShareText,
          subject: _entry.title,
        ),
      );
    }
  }

  Future<void> _handleSoftDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: const Text(
          'This entry will be moved to the Recycle Bin and permanently deleted after 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.database.softDeleteEntry(_entry.id);
      if (mounted) {
        Navigator.pop(context, true); // Pop detail screen and notify timeline
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _template == null || _quillController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final templateStyle = TemplateStyle.fromTemplate(_template!);
    final typography = TypographySettings.fromTemplate(_template!);
    final dateFormatted =
        DateFormat('EEEE, MMMM d, y · h:mm a').format(_entry.entryDate);
    final moodEmoji =
        _entry.mood != null ? EntrySummaryCard.moodEmojis[_entry.mood!] : null;
    final weatherIcon = _entry.weather != null
        ? EntrySummaryCard.weatherIcons[_entry.weather!]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMM d, y').format(_entry.entryDate),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Switch Template',
            onPressed: _handleSwitchTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _handleShare,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export',
            onPressed: () {
              ExportDialog.show(
                context: context,
                database: widget.database,
                singleEntry: _entry,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _handleSoftDelete,
          ),
        ],
      ),
      body: TemplateCanvasContainer(
        style: templateStyle,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metadata Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateFormatted,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_entry.isWeeklyReview) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _entry.weekNumber != null
                            ? 'W${_entry.weekNumber} Review'
                            : 'Weekly Review',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (moodEmoji != null) ...[
                    Text(moodEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                  ],
                  if (weatherIcon != null) ...[
                    Icon(
                      weatherIcon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Title
              if (_entry.title?.trim().isNotEmpty ?? false) ...[
                Text(
                  _entry.title!.trim(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: theme.colorScheme.outlineVariant.withAlpha(100),
                  thickness: 1,
                ),
                const SizedBox(height: 12),
              ],

              // Read-Only Quill Rich Text Editor
              quill.QuillEditor(
                controller: _quillController!,
                focusNode: _focusNode,
                scrollController: ScrollController(),
                config: quill.QuillEditorConfig(
                  checkBoxReadOnly: true,
                  autoFocus: false,
                  expands: false,
                  scrollable: false,
                  padding: EdgeInsets.zero,
                  embedBuilders: [
                    SandboxedImageEmbedBuilder(
                      mediaSandboxService: widget.mediaService,
                    ),
                  ],
                  customStyles: quill.DefaultStyles(
                    paragraph: quill.DefaultTextBlockStyle(
                      typography.toTextStyle(),
                      const quill.HorizontalSpacing(0, 0),
                      const quill.VerticalSpacing(0, 0),
                      const quill.VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.style_outlined),
              label: const Text('Template'),
              onPressed: _handleSwitchTemplate,
            ),
            TextButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
              onPressed: _handleShare,
            ),
            FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Entry'),
              onPressed: _handleEdit,
            ),
          ],
        ),
      ),
    );
  }
}
