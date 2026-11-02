import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../../../core/services/dictation_service.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/template_canvas_container.dart';
import '../controllers/editor_autosave_manager.dart';
import '../models/thought_spark.dart';
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/thought_spark_service.dart';
import '../widgets/dictation_bar.dart';
import '../widgets/cinnabar_signature_seal.dart';
import '../widgets/editor_quill_styles_builder.dart';
import '../widgets/integer_snapped_letterhead.dart';
import '../widgets/keepsake_scroll_view.dart';
import '../widgets/scholar_chest/scholar_chest_drawer.dart';
import '../widgets/journal_letterhead.dart';
import '../widgets/sandboxed_image_embed_builder.dart';
import '../widgets/sandboxed_video_embed_builder.dart';
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
  TypographySettings _typography = const TypographySettings();
  late ThoughtSpark _spark;

  bool _isLoading = true;
  bool _isDictating = false;

  DateTime _entryDate = DateTime.now();
  int? _mood;
  String? _weather;
  DateTime? _unlockAt;
  Entry? _entry;
  bool _isCenterAligned = false;

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
    if (widget.dictationService == null) {
      _dictationService.dispose();
    }
    if (widget.audioSanctumService == null) {
      _audioSanctumService.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEntryData() async {
    try {
      final entry = await widget.database.getEntryById(widget.entryId);
      if (entry == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _entry = entry;

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

      final derivedTypography = TypographySettings.fromTemplate(template);

      if (mounted) {
        setState(() {
          _currentTemplate = template;
          _controller = controller;
          _autosaveManager = autosave;
          _entryDate = entry.entryDate;
          _mood = entry.mood;
          _weather = entry.weather;
          _unlockAt = entry.unlockAt;
          _typography = derivedTypography;
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

  void _toggleCenterAlignment() {
    if (_controller == null) return;
    setState(() {
      _isCenterAligned = !_isCenterAligned;
    });
    _controller!.formatSelection(
      _isCenterAligned ? Attribute.centerAlignment : Attribute.leftAlignment,
    );
  }

  Future<void> _openScholarChest([ScholarArtifactType initialArtifact = ScholarArtifactType.stationeryFan]) async {
    if (_currentTemplate == null) return;
    await ScholarChestDrawer.show(
      context: context,
      database: widget.database,
      activeTemplateId: _currentTemplate!.id,
      typography: _typography,
      audioSanctumService: _audioSanctumService,
      unlockAt: _unlockAt,
      isCenterAligned: _isCenterAligned,
      initialArtifact: initialArtifact,
      onSelectTemplate: (newTemplate) async {
        setState(() {
          _currentTemplate = newTemplate;
          _typography = TypographySettings.fromTemplate(newTemplate);
        });
        await widget.database.updateEntryTemplate(widget.entryId, newTemplate.id);
      },
      onTypographyChanged: (newTypography) {
        setState(() {
          _typography = newTypography;
        });
      },
      onLockChanged: (newUnlockAt) async {
        await widget.database.updateEntryUnlockAt(widget.entryId, newUnlockAt);
        if (mounted) {
          setState(() {
            _unlockAt = newUnlockAt;
          });
        }
      },
      onToggleAlignment: _toggleCenterAlignment,
    );
  }

  void _openKeepsakeScroll() {
    if (_entry == null || _currentTemplate == null) return;
    final templateStyle = TemplateStyle.fromTemplate(_currentTemplate!);
    final currentDelta = jsonEncode(_controller?.document.toDelta().toJson() ?? []);
    final currentPlain = _controller?.document.toPlainText() ?? _entry!.plainText;
    final currentTitle = _titleController.text.trim();

    final previewEntry = _entry!.copyWith(
      title: Value(currentTitle),
      contentDelta: currentDelta,
      plainText: currentPlain,
      templateId: _currentTemplate!.id,
    );

    KeepsakeScrollView.show(
      context: context,
      entry: previewEntry,
      style: templateStyle,
      mediaService: widget.mediaSandboxService,
      database: widget.database,
    );
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '“${_spark.localizedPrompt}”',
          style: const TextStyle(fontFamily: InkDiaryTheme.fontKaiti),
        ),
        action: SnackBarAction(
          label: '由此题落墨',
          onPressed: () => _handleInsertPrompt(_spark.localizedPrompt),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
            // Ambient soundscape pill indicator (when playing)
            ListenableBuilder(
              listenable: _audioSanctumService,
              builder: (context, _) {
                if (!_audioSanctumService.isPlaying) return const SizedBox.shrink();
                return GestureDetector(
                  key: const Key('top_bar_soundscape_pill'),
                  onTap: () => _openScholarChest(ScholarArtifactType.guqinZither),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.cinnabar.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, size: 12, color: tokens.cinnabar),
                        const SizedBox(width: 3),
                        Text(
                          '清音',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 10,
                            color: tokens.cinnabar,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Time Capsule lock pill indicator (when locked in the future)
            if (_unlockAt != null && _unlockAt!.isAfter(DateTime.now()))
              GestureDetector(
                key: const Key('top_bar_lock_pill'),
                onTap: () => _openScholarChest(ScholarArtifactType.fishLock),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 11, color: Color(0xFF8A5A2B)),
                      const SizedBox(width: 3),
                      Text(
                        '封缄',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 10,
                          color: const Color(0xFF8A5A2B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Keepsake Scroll View Action
            IconButton(
              key: const Key('top_bar_keepsake_scroll_button'),
              icon: Icon(Icons.auto_stories_outlined, color: iconColor, size: 22),
              tooltip: '卷轴赏鉴 · Keepsake Scroll',
              onPressed: _openKeepsakeScroll,
            ),

            // Scholar's Stationery Chest Emblem Button with Live Status Badge
            ListenableBuilder(
              listenable: _audioSanctumService,
              builder: (listenableContext, childWidget) {
                final isPlayingSoundscape = _audioSanctumService.isPlaying;
                final isCapsuleLocked = _unlockAt != null && _unlockAt!.isAfter(DateTime.now());
                final hasBadge = isPlayingSoundscape || isCapsuleLocked;

                return Badge(
                  isLabelVisible: hasBadge,
                  backgroundColor: isPlayingSoundscape ? tokens.cinnabar : const Color(0xFFD4AF37),
                  smallSize: 8,
                  alignment: const AlignmentDirectional(0.8, -0.8),
                  child: IconButton(
                    key: const Key('top_bar_scholar_chest_button'),
                    icon: Icon(Icons.all_inbox_outlined, color: iconColor, size: 22),
                    tooltip: '文房百宝匣 · 锦盒书案',
                    onPressed: () => _openScholarChest(),
                  ),
                );
              },
            ),

            // Cinnabar Seal & Complete Save
            IconButton(
              key: const Key('editor_seal_done_btn'),
              icon: Icon(Icons.check, color: tokens.cinnabar, size: 22),
              tooltip: '完成归卷 · Done',
              onPressed: _handleSaveAndExit,
            ),
          ],
        ),
        body: Column(
          children: [
            // Full-bleed paper canvas wrapping Letterhead + GhostPrompt + QuillEditor
            Expanded(
              child: LayoutBuilder(
                builder: (layoutContext, layoutConstraints) {
                  final mediaQuery = MediaQuery.of(layoutContext);
                  final unconstrainedScreenHeight = mediaQuery.size.height -
                      mediaQuery.padding.top -
                      mediaQuery.padding.bottom -
                      kToolbarHeight -
                      56.0;
                  final baseCanvasHeight = math.max(layoutConstraints.maxHeight, unconstrainedScreenHeight);
                  final scrollExtent = _editorScrollController.hasClients
                      ? _editorScrollController.position.maxScrollExtent
                      : 0.0;
                  final totalPaperHeight = math.max(baseCanvasHeight, baseCanvasHeight + scrollExtent);
                  final canvasSize = Size(layoutConstraints.maxWidth, totalPaperHeight);

                  final metrics = StationeryLayoutCalculator.calculate(
                    canvasSize: canvasSize,
                    style: templateStyle,
                    typography: _typography,
                    compactMargins: true,
                  );
                  final activeRowHeight = metrics.lineStridePx;

                  // Inner content padding from Paper Heart border
                  final double innerContentPaddingLeft;
                  if (templateStyle.type == TemplateBackgroundType.grid ||
                      templateStyle.type == TemplateBackgroundType.dotGrid) {
                    innerContentPaddingLeft = 0.0;
                  } else if (templateStyle.type == TemplateBackgroundType.lined) {
                    innerContentPaddingLeft = 32.0;
                  } else {
                    innerContentPaddingLeft = 20.0;
                  }
                  final double innerContentPaddingRight = (templateStyle.type == TemplateBackgroundType.grid ||
                          templateStyle.type == TemplateBackgroundType.dotGrid)
                      ? 0.0
                      : 20.0;

                  final horizontalLeft = metrics.innerFrameRect.left + innerContentPaddingLeft;
                  final horizontalRight = math.max(0.0, layoutConstraints.maxWidth - metrics.innerFrameRect.right) +
                      innerContentPaddingRight;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _editorScrollController,
                          builder: (canvasContext, scrollChild) {
                            final scrollOffset = _editorScrollController.hasClients
                                ? _editorScrollController.offset
                                : 0.0;
                            return TemplateCanvasContainer(
                              style: templateStyle,
                              typography: _typography,
                              scrollOffset: scrollOffset,
                              headerHeight: _headerHeight,
                              layoutMetrics: metrics,
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
                          padding: EdgeInsets.only(top: metrics.heavenMarginPx),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. In-Paper Journal Letterhead wrapped inside IntegerSnappedLetterhead
                              IntegerSnappedLetterhead(
                                key: _letterheadKey,
                                lineStridePx: activeRowHeight,
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: horizontalLeft,
                                    right: horizontalRight,
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: JournalLetterhead(
                                    entryDate: _entryDate,
                                    mood: _mood,
                                    weather: _weather,
                                    titleController: _titleController,
                                    onDateChanged: (selectedDate) {
                                      setState(() => _entryDate = selectedDate);
                                      widget.database.updateEntryMetadata(widget.entryId, entryDate: selectedDate);
                                    },
                                    onMoodChanged: (selectedMood) {
                                      setState(() => _mood = selectedMood);
                                      widget.database.updateEntryMetadata(widget.entryId, mood: selectedMood);
                                    },
                                    onWeatherChanged: (selectedWeather) {
                                      setState(() => _weather = selectedWeather);
                                      widget.database.updateEntryMetadata(widget.entryId, weather: selectedWeather);
                                    },
                                  ),
                                ),
                              ),

                              // 2. Quill Editor Content with contextual margin alignment
                              Padding(
                                padding: EdgeInsets.only(
                                  left: horizontalLeft,
                                  right: horizontalRight,
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
                                        onEmbedMutated: (mutatedBlock) => _autosaveManager?.saveDraft(),
                                        rowHeight: activeRowHeight,
                                      ),
                                      SandboxedVideoEmbedBuilder(
                                        mediaSandboxService: widget.mediaSandboxService,
                                        onVideoRemoved: () => _autosaveManager?.saveDraft(),
                                        onEmbedMutated: (mutatedBlock) => _autosaveManager?.saveDraft(),
                                        rowHeight: activeRowHeight,
                                      ),
                                    ],
                                    customStyles: EditorQuillStylesBuilder.build(
                                      typography: _typography,
                                      inkColor: inkColor,
                                      isPaperDark: isPaperDark,
                                      lineStridePx: activeRowHeight,
                                      backgroundType: templateStyle.type,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Live Cinnabar Signature Seal at colophon
                      Positioned(
                        bottom: 24,
                        right: 20,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.38,
                            child: CinnabarSignatureSeal(
                              sealStyle: templateStyle.tokens.sealStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
              onOpenChest: () => _openScholarChest(),
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
}
