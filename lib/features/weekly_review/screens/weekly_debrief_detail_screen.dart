import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/screens/entry_editor_screen.dart';
import '../../editor/widgets/sandboxed_image_embed_builder.dart';
import '../../editor/widgets/sandboxed_video_embed_builder.dart';
import '../../templates/models/template_style.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../../templates/widgets/template_switcher_sheet.dart';

/// Dedicated literati weekly debrief detail viewer matching weekly_debrief_detail.html
class WeeklyDebriefDetailScreen extends StatefulWidget {
  final Entry debriefEntry;
  final List<Entry> weekEntries;
  final int year;
  final int weekNumber;
  final AppDatabase database;
  final MediaSandboxService mediaService;

  const WeeklyDebriefDetailScreen({
    super.key,
    required this.debriefEntry,
    required this.weekEntries,
    required this.year,
    required this.weekNumber,
    required this.database,
    required this.mediaService,
  });

  @override
  State<WeeklyDebriefDetailScreen> createState() => _WeeklyDebriefDetailScreenState();
}

class _WeeklyDebriefDetailScreenState extends State<WeeklyDebriefDetailScreen> {
  late Entry _debrief;
  Template? _template;
  quill.QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _debrief = widget.debriefEntry;
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
      final fresh = await widget.database.getEntryById(_debrief.id);
      if (fresh != null) {
        _debrief = fresh;
      }

      _template = await widget.database.getTemplateById(_debrief.templateId);
      if (_template == null) {
        final all = await widget.database.getAllTemplates();
        if (all.isNotEmpty) _template = all.first;
      }

      quill.Document doc;
      if (_debrief.contentDelta.isNotEmpty) {
        try {
          final decoded = jsonDecode(_debrief.contentDelta) as List<dynamic>;
          doc = quill.Document.fromJson(decoded);
        } catch (_) {
          doc = quill.Document()..insert(0, _debrief.plainText);
        }
      } else {
        doc = quill.Document()..insert(0, _debrief.plainText);
      }

      _quillController?.dispose();
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e, st) {
      debugPrint('Error loading debrief: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(
          database: widget.database,
          mediaSandboxService: widget.mediaService,
          entryId: _debrief.id,
        ),
      ),
    );

    if (result == true || mounted) {
      await _loadData();
    }
  }

  Future<void> _handleShare() async {
    final title = _debrief.title?.trim().isNotEmpty == true
        ? '${_debrief.title!.trim()}\n\n'
        : '第${widget.weekNumber}周 · 周志复盘\n\n';
    final shareText = '$title${_debrief.plainText}';

    await SharePlus.instance.share(
      ShareParams(text: shareText, subject: '第${widget.weekNumber}周 复盘长卷'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    if (_isLoading || _template == null || _quillController == null) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        body: Center(child: CircularProgressIndicator(color: tokens.cinnabar)),
      );
    }

    final templateStyle = TemplateStyle.fromTemplate(_template!);
    final typography = TypographySettings.fromTemplate(_template!);
    final totalWords = widget.weekEntries.fold<int>(
      0,
      (sum, e) => sum + e.plainText.trim().length,
    ) + _debrief.plainText.trim().length;

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        backgroundColor: tokens.xuanGround,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: tokens.agedFiber, width: 1.0),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
          tooltip: '返回',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '周述长卷',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'WEEKLY DEBRIEF · NO. ${widget.weekNumber}',
              style: TextStyle(
                fontSize: 10,
                color: tokens.danmo,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.style_outlined, color: tokens.nongmo),
            tooltip: '更换信笺',
            onPressed: () async {
              final templates = await widget.database.getAllTemplates();
              if (!context.mounted) return;
              await TemplateSwitcherSheet.show(
                context: context,
                templates: templates,
                currentTemplateId: _debrief.templateId,
                database: widget.database,
                onTemplateSelected: (newT) async {
                  await widget.database.updateEntryTemplate(_debrief.id, newT.id);
                  setState(() {
                    _template = newT;
                  });
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: tokens.nongmo),
            tooltip: '分享',
            onPressed: _handleShare,
          ),
        ],
      ),
      body: TemplateCanvasContainer(
        style: templateStyle,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seasonal Solar Term & Meta Banner
              XuanPaperCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(18),
                backgroundColor: tokens.ricePaper,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tokens.agedFiber.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '第${widget.weekNumber}周',
                                  style: TextStyle(
                                    fontFamily: InkDiaryTheme.fontNotoSerif,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.nongmo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.cinnabar,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.year}年 · 周述复盘',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontKaiti,
                                  fontSize: 12,
                                  color: tokens.cinnabar,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_debrief.title?.trim().isNotEmpty ?? false)
                                ? _debrief.title!.trim()
                                : '第${widget.weekNumber}周 · 凝思复盘录',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: tokens.jiaomo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('M月d日 EEEE 结撰').format(_debrief.entryDate),
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontKaiti,
                              fontSize: 12,
                              color: tokens.danmo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CinnabarSealBadge(text: '复盘已讫', isRound: false),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Executive Weekly Synthesis: Metrics Row
              XuanPaperCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.jiaomo),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '周度提炼 · 墨核',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'SUMMARY',
                          style: TextStyle(fontSize: 10, color: tokens.danmo, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricTile('${widget.weekEntries.length}', '篇佳构', tokens),
                        _buildMetricTile('$totalWords', '言心迹', tokens),
                        _buildMetricTile('${widget.weekEntries.length}/7', '着墨节律', tokens),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rich Text Content
              XuanPaperCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '壹',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tokens.cinnabar,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '拾得 · 所获与微光',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          SandboxedImageEmbedBuilder(mediaSandboxService: widget.mediaService),
                          SandboxedVideoEmbedBuilder(mediaSandboxService: widget.mediaService),
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
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tokens.xuanGround.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: tokens.agedFiber)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.share_outlined, color: tokens.nongmo, size: 18),
                  label: Text('长卷分享', style: TextStyle(color: tokens.jiaomo)),
                  onPressed: _handleShare,
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.jiaomo,
                    foregroundColor: tokens.xuanGround,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('续修复盘'),
                  onPressed: _handleEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String value, String label, InkDiaryTokens tokens) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: tokens.ricePaper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.agedFiber),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 11,
              color: tokens.danmo,
            ),
          ),
        ],
      ),
    );
  }
}
