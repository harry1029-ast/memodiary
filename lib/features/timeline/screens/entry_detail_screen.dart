import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/screens/entry_editor_screen.dart';
import '../../editor/services/audio_sanctum_service.dart';
import '../../editor/widgets/sandboxed_image_embed_builder.dart';
import '../../editor/widgets/sandboxed_video_embed_builder.dart';
import '../../editor/widgets/soundscape_modal.dart';
import '../../editor/widgets/typography_sheet.dart';
import '../../templates/models/template_style.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../../templates/widgets/template_switcher_sheet.dart';
import '../../import_export/widgets/export_dialog.dart';
import '../../import_export/widgets/pdf_preview_screen.dart';
import '../widgets/entry_summary_card.dart';

/// Read-only literati detail viewer displaying the entry inside its procedural canvas template
/// with rich-text styling, sandboxed media embeds, and traditional reader aesthetics.
class EntryDetailScreen extends StatefulWidget {
  final Entry? entry;
  final String? entryId;
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final AuthService? authService;
  final AudioSanctumService? audioSanctumService;
  final Future<void> Function(String text, {String? subject})? shareHandler;

  const EntryDetailScreen({
    super.key,
    this.entry,
    this.entryId,
    required this.database,
    required this.mediaService,
    this.authService,
    this.audioSanctumService,
    this.shareHandler,
  }) : assert(entry != null || entryId != null, 'Either entry or entryId must be provided');

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  Entry? _entry;
  AppDatabase get _db => widget.database;
  MediaSandboxService get _media => widget.mediaService;

  late final AuthService _authService;
  late final AudioSanctumService _audioSanctumService;
  Template? _template;
  quill.QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = true;
  bool _isSessionUnlocked = false;
  String? _pinError;
  TypographySettings _typography = const TypographySettings();

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _authService = widget.authService ?? AuthService();
    _audioSanctumService = widget.audioSanctumService ?? AudioSanctumService();
    _loadData();
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final targetId = _entry?.id ?? widget.entryId!;
      final freshEntry = await _db.getEntryById(targetId);
      if (freshEntry != null) {
        _entry = freshEntry;
      }

      final entry = _entry;
      if (entry == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Load active template
      _template = await _db.getTemplateById(entry.templateId);
      if (_template == null) {
        final allTemplates = await _db.getAllTemplates();
        if (allTemplates.isNotEmpty) {
          _template = allTemplates.first;
        }
      }

      if (_template != null) {
        _typography = TypographySettings.fromTemplate(_template!);
      }

      // Build read-only QuillController
      quill.Document doc;
      if (entry.contentDelta.isNotEmpty) {
        try {
          final decoded = jsonDecode(entry.contentDelta) as List<dynamic>;
          doc = quill.Document.fromJson(decoded);
        } catch (_) {
          doc = quill.Document()..insert(0, entry.plainText);
        }
      } else {
        doc = quill.Document()..insert(0, entry.plainText);
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

  bool get _isCurrentlyBlocked => _entry != null && _entry!.isLocked && !_isSessionUnlocked;

  Future<void> _handleUnlockWithPin() async {
    final entry = _entry;
    if (entry == null) return;

    final enteredPin = _pinController.text.trim();
    if (enteredPin.isEmpty) {
      setState(() => _pinError = '请输入印匣密码');
      return;
    }

    bool verified = false;
    if (entry.entryPinHash != null && entry.entryPinHash!.isNotEmpty) {
      verified = _authService.verifyEntryPin(enteredPin, entry.entryPinHash!);
    } else {
      verified = await _authService.verifyPin(enteredPin);
    }

    if (verified) {
      HapticFeedback.lightImpact();
      setState(() {
        _isSessionUnlocked = true;
        _pinError = null;
        _pinController.clear();
      });
    } else {
      setState(() => _pinError = 'Incorrect PIN');
    }
  }

  Future<void> _handleUnlockWithBiometrics() async {
    final authenticated = await _authService.authenticateBiometric(
      localizedReason: '解锁私密手稿',
    );
    if (authenticated && mounted) {
      HapticFeedback.lightImpact();
      setState(() {
        _isSessionUnlocked = true;
        _pinError = null;
      });
    }
  }

  Future<void> _handleToggleLock() async {
    final entry = _entry;
    if (entry == null) return;

    if (entry.isLocked) {
      // Permanently remove lock
      await _db.unlockEntryPermanently(entry.id);
      HapticFeedback.lightImpact();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已解除私密封缄')),
        );
      }
      return;
    }

    // Prompt user to set a 4-6 digit PIN for this entry
    final pinInputController = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('私密封缄 · Lock Entry'),
        content: TextField(
          key: const Key('lock_entry_pin_input'),
          controller: pinInputController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '设定 4-6 位密码',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm_lock_entry_btn'),
            onPressed: () {
              final text = pinInputController.text.trim();
              if (text.length >= 4) {
                Navigator.pop(dialogContext, text);
              }
            },
            child: const Text('落锁封存'),
          ),
        ],
      ),
    );

    if (pin != null && pin.length >= 4) {
      final pinHash = _authService.hashEntryPin(pin);
      await _db.lockEntry(entry.id, pinHash: pinHash);
      HapticFeedback.lightImpact();
      setState(() {
        _isSessionUnlocked = false;
      });
      await _loadData();
    }
  }

  Future<void> _handleSwitchTemplate() async {
    final entry = _entry;
    if (entry == null) return;

    final templates = await _db.getAllTemplates();
    if (!mounted) return;

    await TemplateSwitcherSheet.show(
      context: context,
      templates: templates,
      currentTemplateId: entry.templateId,
      database: _db,
      onTemplateSelected: (newTemplate) async {
        await _db.updateEntryTemplate(entry.id, newTemplate.id);
        setState(() {
          _template = newTemplate;
          _entry = entry.copyWith(templateId: newTemplate.id);
          _typography = TypographySettings.fromTemplate(newTemplate);
        });
      },
    );
  }

  Future<void> _handleOpenTypography() async {
    await TypographySheet.show(
      context: context,
      settings: _typography,
      onChanged: (newSettings) {
        setState(() {
          _typography = newSettings;
        });
      },
    );
  }

  Future<void> _handleOpenSoundscapes() async {
    await SoundscapeModal.show(
      context: context,
      sanctumService: _audioSanctumService,
    );
  }

  Future<void> _handleEdit() async {
    final entry = _entry;
    if (entry == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(
          database: _db,
          mediaSandboxService: _media,
          entryId: entry.id,
        ),
      ),
    );

    // Reload content upon returning from editor
    if (result == true || mounted) {
      await _loadData();
    }
  }

  Future<void> _handleShare() async {
    final entry = _entry;
    if (entry == null) return;

    final dateStr = DateFormat('yyyy-MM-dd EEEE').format(entry.entryDate);
    final titleStr = (entry.title?.trim().isNotEmpty ?? false)
        ? '${entry.title!.trim()}\n\n'
        : '';
    final fullShareText = '$titleStr$dateStr\n\n${entry.plainText}';

    if (widget.shareHandler != null) {
      await widget.shareHandler!(fullShareText, subject: entry.title);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: fullShareText,
          subject: entry.title,
        ),
      );
    }
  }

  Future<void> _handleSoftDelete() async {
    final entry = _entry;
    if (entry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: const Text(
          '此手稿将移入回收站，30 天内仍可完好还原，逾期将彻底化作飞灰。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('保留手稿'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.softDeleteEntry(entry.id);
      if (mounted) {
        Navigator.pop(context, true); // Pop detail screen and notify timeline
      }
    }
  }

  Widget _buildLockBarrier(InkDiaryTokens tokens) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: XuanPaperCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.cinnabarWash,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 32,
                  color: tokens.cinnabar,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'This Diary Entry is Locked',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '此卷已落锁封存',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 13,
                  color: tokens.danmo,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '请输入印匣密码或验证指纹，方可展卷阅览。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 13,
                  color: tokens.danmo,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: TextField(
                  key: const Key('entry_unlock_pin_field'),
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  onSubmitted: (_) => _handleUnlockWithPin(),
                  decoration: InputDecoration(
                    hintText: '输入印匣密码',
                    errorText: _pinError,
                    counterText: '',
                    filled: true,
                    fillColor: tokens.ricePaper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tokens.agedFiber),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('entry_unlock_submit_btn'),
                onPressed: _handleUnlockWithPin,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.jiaomo,
                  foregroundColor: tokens.xuanGround,
                ),
                icon: const Icon(Icons.key_rounded, size: 16),
                label: const Text('启封展卷'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('entry_unlock_biometric_btn'),
                onPressed: _handleUnlockWithBiometrics,
                icon: Icon(Icons.fingerprint_rounded, color: tokens.cinnabar),
                label: Text(
                  '生物指纹解印',
                  style: TextStyle(color: tokens.cinnabar),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        body: Center(
          child: CircularProgressIndicator(color: tokens.cinnabar),
        ),
      );
    }

    final entry = _entry;
    if (entry == null || _template == null || _quillController == null) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        appBar: AppBar(
          backgroundColor: tokens.xuanGround,
          leading: BackButton(color: tokens.jiaomo),
        ),
        body: Center(
          child: Text(
            '未找到对应日记手稿',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              color: tokens.danmo,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    if (_isCurrentlyBlocked) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        appBar: AppBar(
          backgroundColor: tokens.xuanGround,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            DateFormat('yyyy年M月d日').format(entry.entryDate),
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 16,
              color: tokens.jiaomo,
            ),
          ),
        ),
        body: _buildLockBarrier(tokens),
      );
    }

    final templateStyle = TemplateStyle.fromTemplate(_template!);
    final dateFormatted = DateFormat('yyyy年M月d日 · EEEE').format(entry.entryDate);
    final moodEmoji = entry.mood != null ? EntrySummaryCard.moodEmojis[entry.mood!] : null;
    final weatherIcon = entry.weather != null ? EntrySummaryCard.weatherIcons[entry.weather!] : null;
    final wordCount = entry.plainText.trim().length;
    final readMinutes = (wordCount / 200).ceil().clamp(1, 60);

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        backgroundColor: tokens.xuanGround,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: tokens.agedFiber,
            width: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
          tooltip: '返回',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '墨记 · 抚卷',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            Text(
              dateFormatted,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 11,
                color: tokens.danmo,
              ),
            ),
          ],
        ),
        actions: [
          // Ambient Soundscape capsule
          ListenableBuilder(
            listenable: _audioSanctumService,
            builder: (context, _) {
              final isPlaying = _audioSanctumService.isPlaying;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.headphones_rounded : Icons.headphones_outlined,
                  color: isPlaying ? tokens.cinnabar : tokens.nongmo,
                ),
                tooltip: '砚边琴韵',
                onPressed: _handleOpenSoundscapes,
              );
            },
          ),
          // Typography Settings
          IconButton(
            icon: Icon(Icons.format_size_rounded, color: tokens.nongmo),
            tooltip: '字法排印',
            onPressed: _handleOpenTypography,
          ),
          // PDF Export
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PdfPreviewScreen(
                    singleEntry: entry,
                    database: _db,
                    mediaService: _media,
                  ),
                ),
              );
            },
          ),
          // Delete icon button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _handleSoftDelete,
          ),
          // Lock Entry toggle
          IconButton(
            key: const Key('entry_detail_lock_toggle_btn'),
            icon: Icon(
              entry.isLocked ? Icons.lock : Icons.lock_outline,
              color: entry.entryPinHash != null ? tokens.cinnabar : tokens.nongmo,
            ),
            tooltip: entry.isLocked ? '解除私密封缄' : '私密封存',
            onPressed: _handleToggleLock,
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: tokens.nongmo),
            onSelected: (val) {
              switch (val) {
                case 'template':
                  _handleSwitchTemplate();
                  break;
                case 'pdf':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => PdfPreviewScreen(
                        singleEntry: entry,
                        database: _db,
                        mediaService: _media,
                      ),
                    ),
                  );
                  break;
                case 'export':
                  ExportDialog.show(
                    context: context,
                    database: _db,
                    singleEntry: entry,
                    mediaService: _media,
                  );
                  break;
                case 'delete':
                  _handleSoftDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'template',
                child: Text('更换素笺模板'),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Text('导出宣纸 PDF'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('纯文归档导出'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  '移入岁暮拾遗',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
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
              // Sanctuary Reading Card Ground
              XuanPaperCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solar term & seasonal markers ribbon
                    Row(
                      children: [
                        if (entry.isWeeklyReview) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: tokens.agedFiber,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: tokens.deckleBorder),
                            ),
                            child: Text(
                              entry.weekNumber != null ? 'W${entry.weekNumber} Review' : 'Weekly Review',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tokens.jiaomo,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        CinnabarSealBadge(
                          text: entry.isWeeklyReview ? '周录' : '岁在此时',
                          isRound: false,
                        ),
                        const SizedBox(width: 8),
                        if (moodEmoji != null) ...[
                          Text(moodEmoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                        ],
                        if (weatherIcon != null) ...[
                          Icon(
                            weatherIcon,
                            size: 16,
                            color: tokens.danmo,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            '$wordCount 字 · 读需 $readMinutes 分钟',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontKaiti,
                              fontSize: 12,
                              color: tokens.danmo,
                            ),
                          ),
                        ),
                        if (entry.isLocked)
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: tokens.cinnabar,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Main Title
                    if (entry.title?.trim().isNotEmpty ?? false) ...[
                      Text(
                        entry.title!.trim(),
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: tokens.jiaomo,
                          letterSpacing: 0.8,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: tokens.agedFiber,
                      ),
                      const SizedBox(height: 16),
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
                            mediaSandboxService: _media,
                          ),
                          SandboxedVideoEmbedBuilder(
                            mediaSandboxService: _media,
                          ),
                        ],
                        customStyles: quill.DefaultStyles(
                          paragraph: quill.DefaultTextBlockStyle(
                            _typography.toTextStyle(),
                            const quill.HorizontalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Authentic Cinnabar Seal Stamp Sign-off
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('yyyy年M月d日 记').format(entry.entryDate),
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontKaiti,
                                fontSize: 11,
                                color: tokens.danmo,
                              ),
                            ),
                            Text(
                              '拾光微澜 · 顿首',
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontKaiti,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tokens.nongmo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Soapstone Carved Cinnabar Seal Square
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tokens.cinnabar,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.cinnabar.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '静好\n岁月',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tokens.ricePaper,
                                height: 1.1,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
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
          border: Border(
            top: BorderSide(color: tokens.agedFiber, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.style_outlined, color: tokens.nongmo, size: 18),
                  label: Text('Template', style: TextStyle(color: tokens.jiaomo)),
                  onPressed: _handleSwitchTemplate,
                ),
                TextButton.icon(
                  icon: Icon(Icons.share_outlined, color: tokens.nongmo, size: 18),
                  label: Text('Share', style: TextStyle(color: tokens.jiaomo)),
                  onPressed: _handleShare,
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.jiaomo,
                    foregroundColor: tokens.xuanGround,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Entry'),
                  onPressed: _handleEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
