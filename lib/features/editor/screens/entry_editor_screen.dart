import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/dictation_service.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/models/template_style.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../../templates/widgets/template_switcher_sheet.dart';
import '../controllers/editor_autosave_manager.dart';
import '../models/thought_spark.dart';
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/baseline_metrics_calculator.dart';
import '../services/thought_spark_service.dart';
import '../widgets/dictation_bar.dart';
import '../widgets/ghost_prompt_view.dart';
import '../widgets/journal_letterhead.dart';
import '../widgets/sandboxed_image_embed_builder.dart';
import '../widgets/sandboxed_video_embed_builder.dart';
import '../widgets/soundscape_modal.dart';
import '../widgets/typography_sheet.dart';
import '../widgets/writing_dock.dart';

/// Full-Bleed rich-text multimodal diary editor in classical Ink & Paper stationery aesthetic.
/// Decouples content (Quill Delta JSON) from presentation (Procedural Templates & Typography).
class EntryEditorScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final DictationService? dictationService;
  final ThoughtSparkService? thoughtSparkService;
  final AudioSanctumService? audioSanctumService;
  final ImagePicker? imagePicker;

  const EntryEditorScreen({
    super.key,
    required this.database,
    required this.mediaSandboxService,
    required this.entryId,
    this.dictationService,
    this.thoughtSparkService,
    this.audioSanctumService,
    this.imagePicker,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final DictationService _dictationService;
  late final ThoughtSparkService _thoughtSparkService;
  late final AudioSanctumService _audioSanctumService;
  late final ImagePicker _imagePicker;

  QuillController? _controller;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  EditorAutosaveManager? _autosaveManager;

  final GlobalKey _letterheadKey = GlobalKey();
  double _headerHeight = 90.0;

  Template? _currentTemplate;
  List<Template> _allTemplates = [];
  TypographySettings _typography = const TypographySettings();
  late ThoughtSpark _spark;

  bool _isLoading = true;
  bool _isDictating = false;

  DateTime _entryDate = DateTime.now();
  int? _mood;
  String? _weather;
  DateTime? _unlockAt;

  @override
  void initState() {
    super.initState();
    _dictationService = widget.dictationService ?? DictationService();
    _thoughtSparkService = widget.thoughtSparkService ?? ThoughtSparkService();
    _audioSanctumService = widget.audioSanctumService ?? AudioSanctumService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _spark = _thoughtSparkService.getRandomSpark();
    _loadEntryData();
  }

  @override
  void dispose() {
    _autosaveManager?.dispose();
    _controller?.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _dictationService.dispose();
    _audioSanctumService.dispose();
    super.dispose();
  }

  Future<void> _loadEntryData() async {
    try {
      final entry = await widget.database.getEntryById(widget.entryId);
      if (entry == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final templates = await widget.database.select(widget.database.templates).get();
      final template = templates.firstWhere(
        (tpl) => tpl.id == entry.templateId,
        orElse: () => templates.first,
      );

      // Parse Quill Delta
      Document document;
      try {
        if (entry.contentDelta.trim().isEmpty) {
          document = Document();
        } else {
          final decoded = jsonDecode(entry.contentDelta);
          if (decoded is List) {
            document = Document.fromJson(decoded);
          } else {
            document = Document();
          }
        }
      } catch (_) {
        document = Document();
      }

      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );

      _titleController.text = entry.title ?? '';

      final autosave = EditorAutosaveManager(
        database: widget.database,
        entryId: widget.entryId,
        controller: controller,
        titleController: _titleController,
      );

      if (mounted) {
        setState(() {
          _currentTemplate = template;
          _allTemplates = templates;
          _controller = controller;
          _autosaveManager = autosave;
          _entryDate = entry.entryDate;
          _mood = entry.mood;
          _weather = entry.weather;
          _unlockAt = entry.unlockAt;
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error loading entry editor data: $error\n$stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleTemplateSwitch() async {
    if (_currentTemplate == null) return;
    final freshTemplates = await widget.database.getAllTemplates();
    if (!mounted) return;
    setState(() {
      _allTemplates = freshTemplates;
    });

    await TemplateSwitcherSheet.show(
      context: context,
      templates: _allTemplates,
      currentTemplateId: _currentTemplate!.id,
      database: widget.database,
      onTemplateSelected: (newTemplate) async {
        setState(() {
          _currentTemplate = newTemplate;
        });
        await widget.database.updateEntryTemplate(widget.entryId, newTemplate.id);
      },
    );
  }

  Future<void> _handleTypographySettings() async {
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

  Future<void> _handlePickTimeCapsule() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _unlockAt ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: '时光胶囊封缄至 · Seal Until Date',
    );

    if (pickedDate != null) {
      HapticFeedback.lightImpact();
      setState(() => _unlockAt = pickedDate);
      await widget.database.updateEntryMetadata(widget.entryId, unlockAt: pickedDate);
    }
  }

  Future<void> _handleImagePick() async {
    final tokens = InkDiaryTheme.tokensOf(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: tokens.jiaomo),
              title: Text(
                '即时拓影 · Take Photo',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: tokens.jiaomo),
              title: Text(
                '相册选撷 · Photo Gallery',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null || _controller == null) return;

      // Sandbox isolation: Compress to WebP and get relative path
      final relativePath = await widget.mediaSandboxService.copyAndCompressImage(
        File(picked.path),
      );

      // Insert into Quill Delta
      final index = _controller!.selection.baseOffset.clamp(
        0,
        _controller!.document.length - 1,
      );
      _controller!.document.insert(index, BlockEmbed.image(relativePath));

      // Record in media_attachments table
      await widget.database.attachMediaToEntry(
        id: const Uuid().v4(),
        entryId: widget.entryId,
        relativePath: relativePath,
        mediaType: 'image',
      );

      _autosaveManager?.saveDraft();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert photo: $error')),
        );
      }
    }
  }

  Future<void> _handleVideoPick() async {
    final tokens = InkDiaryTheme.tokensOf(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.videocam_outlined, color: tokens.jiaomo),
              title: Text(
                '录制短影 · Record Video (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.video_library_outlined, color: tokens.jiaomo),
              title: Text(
                '相册选取短影 · Video Gallery (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(modalContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null || _controller == null) return;

      final result = await widget.mediaSandboxService.copyAndSandboxVideo(
        File(picked.path),
      );

      final index = _controller!.selection.baseOffset.clamp(
        0,
        _controller!.document.length - 1,
      );
      _controller!.document.insert(index, BlockEmbed.video(result.relativePath));

      await widget.database.attachMediaToEntry(
        id: const Uuid().v4(),
        entryId: widget.entryId,
        relativePath: result.relativePath,
        mediaType: 'video',
        thumbnailPath: result.thumbnailPath,
      );

      _autosaveManager?.saveDraft();
    } on VideoDurationExceededException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert video: $error')),
        );
      }
    }
  }

  void _handleShuffleSpark() {
    HapticFeedback.selectionClick();
    setState(() {
      _spark = _thoughtSparkService.nextSpark();
    });

    // If entry has existing text, offer the refreshed prompt via a gentle floating action
    if (_controller != null && _controller!.document.toPlainText().trim().isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '“${_spark.localizedPrompt}”',
            style: const TextStyle(fontFamily: InkDiaryTheme.fontKaiti),
          ),
          action: SnackBarAction(
            label: '落墨插入',
            onPressed: () => _handleInsertPrompt(_spark.localizedPrompt),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleInsertPrompt(String prompt) {
    if (_controller == null) return;
    final index = _controller!.selection.baseOffset.clamp(
      0,
      _controller!.document.length - 1,
    );
    _controller!.document.insert(index, '【灵感拾遗】$prompt\n');
    _controller!.formatText(index, prompt.length + 6, Attribute.blockQuote);
    _autosaveManager?.saveDraft(force: true);
    setState(() {});
  }

  Future<void> _handleOpenSoundscapes() async {
    await SoundscapeModal.show(
      context: context,
      sanctumService: _audioSanctumService,
    );
  }

  Future<void> _handleSaveAndExit() async {
    HapticFeedback.lightImpact();
    await _autosaveManager?.saveDraft(force: true);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    if (_isLoading || _controller == null || _currentTemplate == null) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        body: Center(
          child: CircularProgressIndicator(color: tokens.cinnabar),
        ),
      );
    }

    final templateStyle = TemplateStyle.fromTemplate(_currentTemplate!);
    final isPaperDark =
        ThemeData.estimateBrightnessForColor(templateStyle.backgroundColor) == Brightness.dark;
    final paperBaseTheme = isPaperDark ? ThemeData.dark() : ThemeData.light();
    final paperColor = templateStyle.backgroundColor;
    final inkColor = isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF212121);
    final iconColor = isPaperDark ? const Color(0xFFDCD6CA) : tokens.nongmo;

    _updateHeaderHeight();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isPaperDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: paperColor,
        appBar: AppBar(
          backgroundColor: paperColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor, size: 22),
            tooltip: '返回 · Back',
            onPressed: _handleSaveAndExit,
          ),
          title: ValueListenableBuilder<AutosaveStatus>(
            valueListenable: _autosaveManager!.statusNotifier,
            builder: (statusContext, status, _) {
              String label = '已保存';
              Color dotColor = const Color(0xFF059669);
              if (status == AutosaveStatus.saving) {
                label = '存墨中...';
                dotColor = const Color(0xFFD97706);
              } else if (status == AutosaveStatus.unsaved) {
                label = '草稿未存';
                dotColor = tokens.danmo;
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontKaiti,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            // Cinnabar Seal & Complete Save
            IconButton(
              key: const Key('editor_seal_done_btn'),
              icon: Icon(Icons.check, color: tokens.cinnabar, size: 22),
              tooltip: '完成归卷 · Done',
              onPressed: _handleSaveAndExit,
            ),
            // Options Menu (Templates, Typography, Time Capsule, Soundscapes)
            PopupMenuButton<String>(
              key: const Key('editor_more_options_btn'),
              icon: Icon(Icons.more_horiz_rounded, color: iconColor, size: 22),
              tooltip: '更多设置 · Options',
              onSelected: (optionValue) {
                switch (optionValue) {
                  case 'template':
                    _handleTemplateSwitch();
                    break;
                  case 'typography':
                    _handleTypographySettings();
                    break;
                  case 'soundscape':
                    _handleOpenSoundscapes();
                    break;
                  case 'capsule':
                    _handlePickTimeCapsule();
                    break;
                }
              },
              itemBuilder: (menuContext) => [
                PopupMenuItem(
                  value: 'template',
                  child: Row(
                    children: [
                      Icon(Icons.style_outlined, size: 18, color: tokens.nongmo),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('更换素笺模板')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'typography',
                  child: Row(
                    children: [
                      Icon(Icons.font_download_outlined, size: 18, color: tokens.nongmo),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('字法排印')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'soundscape',
                  child: Row(
                    children: [
                      Icon(Icons.headphones_outlined, size: 18, color: tokens.nongmo),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('砚边琴韵')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'capsule',
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top_outlined, size: 18, color: tokens.nongmo),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('封缄时光胶囊')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Full-bleed paper canvas wrapping Letterhead + GhostPrompt + QuillEditor
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _editorScrollController,
                      builder: (context, _) {
                        final scrollOffset = _editorScrollController.hasClients
                            ? _editorScrollController.offset
                            : 0.0;
                        return TemplateCanvasContainer(
                          style: templateStyle,
                          typography: _typography,
                          scrollOffset: scrollOffset,
                          headerHeight: _headerHeight,
                          customPadding: EdgeInsets.zero,
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                  Theme(
                    data: paperBaseTheme.copyWith(
                      textTheme: paperBaseTheme.textTheme.apply(
                        bodyColor: inkColor,
                        displayColor: inkColor,
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _editorScrollController,
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. In-Paper Journal Letterhead & Ghost Prompt
                          Container(
                            key: _letterheadKey,
                            padding: EdgeInsets.symmetric(
                              horizontal: templateStyle.marginHorizontal.clamp(16.0, 36.0),
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                JournalLetterhead(
                                  entryDate: _entryDate,
                                  mood: _mood,
                                  weather: _weather,
                                  titleController: _titleController,
                                  onDateChanged: (val) {
                                    setState(() => _entryDate = val);
                                    widget.database.updateEntryMetadata(widget.entryId, entryDate: val);
                                  },
                                  onMoodChanged: (val) {
                                    setState(() => _mood = val);
                                    widget.database.updateEntryMetadata(widget.entryId, mood: val);
                                  },
                                  onWeatherChanged: (val) {
                                    setState(() => _weather = val);
                                    widget.database.updateEntryMetadata(widget.entryId, weather: val);
                                  },
                                ),
                                GhostPromptView(
                                  controller: _controller!,
                                  spark: _spark,
                                  onAdoptPrompt: () => _handleInsertPrompt(_spark.localizedPrompt),
                                  onShuffle: _handleShuffleSpark,
                                ),
                              ],
                            ),
                          ),

                          // 2. Quill Editor Content with 12px gutter from margin line
                          Padding(
                            padding: EdgeInsets.only(
                              left: templateStyle.marginHorizontal.clamp(16.0, 36.0) + 12.0,
                              right: templateStyle.marginHorizontal.clamp(16.0, 36.0),
                              bottom: 120.0,
                            ),
                            child: QuillEditor(
                              controller: _controller!,
                              focusNode: _editorFocusNode,
                              scrollController: _editorScrollController,
                              config: QuillEditorConfig(
                                placeholder: '提笔落墨，且将心事付素笺... Write your heart out today...',
                                expands: false,
                                scrollable: false,
                                embedBuilders: [
                                  SandboxedImageEmbedBuilder(
                                    mediaSandboxService: widget.mediaSandboxService,
                                    onImageRemoved: () => _autosaveManager?.saveDraft(),
                                  ),
                                  SandboxedVideoEmbedBuilder(
                                    mediaSandboxService: widget.mediaSandboxService,
                                    onVideoRemoved: () => _autosaveManager?.saveDraft(),
                                  ),
                                ],
                                customStyles: _buildQuillStyles(
                                  typography: _typography,
                                  inkColor: inkColor,
                                  isPaperDark: isPaperDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Traditional watermark seal at lower right corner
                  Positioned(
                    bottom: 24,
                    right: 20,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.16,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: tokens.cinnabar, width: 1.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '澄心\n寄墨',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tokens.cinnabar,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Dictation Bar when active
            if (_isDictating)
              DictationBar(
                controller: _controller!,
                dictationService: _dictationService,
                onClose: () => setState(() => _isDictating = false),
              ),

            // Bottom Progressive Writing Dock
            WritingDock(
              controller: _controller!,
              onPickImage: _handleImagePick,
              onPickVideo: _handleVideoPick,
              onToggleDictation: () => setState(() => _isDictating = !_isDictating),
              onShuffleSpark: _handleShuffleSpark,
              isDictating: _isDictating,
              backgroundColor: paperColor.withValues(alpha: 0.95),
            ),
          ],
        ),
      ),
    );
  }

  void _updateHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _letterheadKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final height = renderBox.size.height;
        if ((height - _headerHeight).abs() > 0.5) {
          setState(() {
            _headerHeight = height;
          });
        }
      }
    });
  }

  DefaultStyles _buildQuillStyles({
    required TypographySettings typography,
    required Color inkColor,
    required bool isPaperDark,
  }) {
    final baseStyle = typography.toTextStyle(color: inkColor);
    final rowHeight = BaselineMetricsCalculator.calculateLineHeight(baseStyle);

    final h1FontSize = 22.0;
    final h1TextHeight = h1FontSize * 1.2;
    final h1Padding = math.max(0.0, (rowHeight * 2 - h1TextHeight) / 2);

    final h2FontSize = 18.0;
    final h2TextHeight = h2FontSize * 1.2;
    final h2Padding = math.max(0.0, (rowHeight * 2 - h2TextHeight) / 2);

    final h3FontSize = 16.0;
    final h3TextHeight = h3FontSize * 1.2;
    final h3Padding = math.max(0.0, (rowHeight - h3TextHeight) / 2);

    return DefaultStyles(
      placeHolder: DefaultTextBlockStyle(
        typography.toTextStyle(
          color: isPaperDark ? const Color(0xFFA69F93) : const Color(0x7F212121),
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      paragraph: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontSize: h1FontSize,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
        ),
        const HorizontalSpacing(0, 0),
        VerticalSpacing(h1Padding, h1Padding),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontSize: h2FontSize,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
        ),
        const HorizontalSpacing(0, 0),
        VerticalSpacing(h2Padding, h2Padding),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontSize: h3FontSize,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
        ),
        const HorizontalSpacing(0, 0),
        VerticalSpacing(h3Padding, h3Padding),
        const VerticalSpacing(0, 0),
        null,
      ),
      quote: DefaultTextBlockStyle(
        baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: isPaperDark ? const Color(0xFFDCD6CA) : const Color(0xFF424242),
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }
}
