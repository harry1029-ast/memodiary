import 'dart:convert';
import 'dart:io';
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
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/thought_spark_service.dart';
import '../widgets/dictation_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/entry_metadata_bar.dart';
import '../widgets/sandboxed_image_embed_builder.dart';
import '../widgets/sandboxed_video_embed_builder.dart';
import '../widgets/soundscape_modal.dart';
import '../widgets/thought_spark_banner.dart';
import '../widgets/typography_sheet.dart';

/// Full rich-text multimodal diary editor screen in classical Ink & Paper aesthetic.
/// Strictly decouples content (Quill Delta JSON) from presentation (Procedural Templates & Typography).
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
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  EditorAutosaveManager? _autosaveManager;

  Template? _currentTemplate;
  List<Template> _allTemplates = [];
  TypographySettings _typography = const TypographySettings();

  bool _isLoading = true;
  bool _showThoughtSpark = true;
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
    _loadEntryData();
  }

  @override
  void dispose() {
    _autosaveManager?.dispose();
    _controller?.dispose();
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
        (t) => t.id == entry.templateId,
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

      final autosave = EditorAutosaveManager(
        database: widget.database,
        entryId: widget.entryId,
        controller: controller,
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
    } catch (e, st) {
      debugPrint('Error loading entry editor data: $e\n$st');
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
        // Preserves contentDelta completely untouched!
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

  Future<void> _handleImagePick() async {
    final tokens = InkDiaryTheme.tokensOf(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: tokens.jiaomo),
              title: Text(
                '即时拓影 · Take Photo',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: tokens.jiaomo),
              title: Text(
                '相册选撷 · Photo Gallery',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert photo: $e')),
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
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.videocam_outlined, color: tokens.jiaomo),
              title: Text(
                '录制短影 · Record Video (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.video_library_outlined, color: tokens.jiaomo),
              title: Text(
                '相册选取短影 · Video Gallery (≤60s)',
                style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: tokens.jiaomo),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
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

      // Sandbox isolation: Copy to sandbox, validate duration <= 60s, generate poster
      final result = await widget.mediaSandboxService.copyAndSandboxVideo(
        File(picked.path),
      );

      // Insert into Quill Delta
      final index = _controller!.selection.baseOffset.clamp(
        0,
        _controller!.document.length - 1,
      );
      _controller!.document.insert(index, BlockEmbed.video(result.relativePath));

      // Record in media_attachments table
      await widget.database.attachMediaToEntry(
        id: const Uuid().v4(),
        entryId: widget.entryId,
        relativePath: result.relativePath,
        mediaType: 'video',
        thumbnailPath: result.thumbnailPath,
      );

      _autosaveManager?.saveDraft();
    } on VideoDurationExceededException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert video: $e')),
        );
      }
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
    setState(() {
      _showThoughtSpark = false;
    });
    _autosaveManager?.saveDraft(force: true);
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
    if (mounted) Navigator.pop(context);
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
          onPressed: _handleSaveAndExit,
        ),
        title: ValueListenableBuilder<AutosaveStatus>(
          valueListenable: _autosaveManager!.statusNotifier,
          builder: (context, status, _) {
            String label = 'Saved';
            Color dotColor = const Color(0xFF059669);
            if (status == AutosaveStatus.saving) {
              label = 'Saving...';
              dotColor = const Color(0xFFD97706);
            } else if (status == AutosaveStatus.unsaved) {
              label = 'Unsaved';
              dotColor = tokens.danmo;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.ricePaper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tokens.agedFiber,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontKaiti,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.nongmo,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          // 1. Writing Sanctum Soundscapes
          ListenableBuilder(
            listenable: _audioSanctumService,
            builder: (context, _) {
              final playing = _audioSanctumService.isPlaying;
              return IconButton(
                key: const Key('editor_appbar_soundscape_btn'),
                icon: Icon(
                  playing ? Icons.headphones_rounded : Icons.headphones_outlined,
                  color: playing ? tokens.cinnabar : tokens.nongmo,
                ),
                tooltip: '沉浸琴音·檐雨',
                onPressed: _handleOpenSoundscapes,
              );
            },
          ),
          // 2. Paper & Template Switcher
          IconButton(
            icon: Icon(Icons.style_outlined, color: tokens.nongmo),
            tooltip: 'Switch Template',
            onPressed: _handleTemplateSwitch,
          ),
          // 3. Typography Styles ('A')
          IconButton(
            icon: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: tokens.nongmo, width: 1.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            tooltip: 'Typography',
            onPressed: _handleTypographySettings,
          ),
          // 4. Seal & Complete Save (Cinnabar Checkmark)
          IconButton(
            icon: Icon(Icons.check, color: tokens.cinnabar),
            tooltip: '完成归卷',
            onPressed: _handleSaveAndExit,
          ),
        ],
      ),
      body: Column(
        children: [
          // Metadata Bar (Date, Mood, Weather, Time Capsule)
          EntryMetadataBar(
            entryDate: _entryDate,
            mood: _mood,
            weather: _weather,
            unlockAt: _unlockAt,
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
            onUnlockAtChanged: (val) {
              setState(() => _unlockAt = val);
              widget.database.updateEntryMetadata(widget.entryId, unlockAt: val);
            },
          ),

          // Thought Spark Inspiration Banner
          if (_showThoughtSpark)
            ThoughtSparkBanner(
              sparkService: _thoughtSparkService,
              onInsertPrompt: _handleInsertPrompt,
              onDismiss: () => setState(() => _showThoughtSpark = false),
            ),

          // Procedural Canvas Container wrapping Quill Editor with traditional watermark seal
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: TemplateCanvasContainer(
                    style: templateStyle,
                    child: Theme(
                      data: paperBaseTheme.copyWith(
                        textTheme: paperBaseTheme.textTheme.apply(
                          bodyColor: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF212121),
                          displayColor: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF212121),
                        ),
                      ),
                      child: QuillEditor(
                        controller: _controller!,
                        focusNode: _editorFocusNode,
                        scrollController: _editorScrollController,
                        config: QuillEditorConfig(
                          placeholder: '提笔落墨，且将心事付素笺... Write your heart out today...',
                          expands: true,
                          scrollable: true,
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
                          customStyles: DefaultStyles(
                            placeHolder: DefaultTextBlockStyle(
                              _typography.toTextStyle(
                                color: isPaperDark ? const Color(0xFFA69F93) : const Color(0x7F212121),
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            paragraph: DefaultTextBlockStyle(
                              _typography.toTextStyle(
                                color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF212121),
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h1: DefaultTextBlockStyle(
                              _typography.toTextStyle(
                                color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
                              ).copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(8, 4),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h2: DefaultTextBlockStyle(
                              _typography.toTextStyle(
                                color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
                              ).copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(6, 3),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            h3: DefaultTextBlockStyle(
                              _typography.toTextStyle(
                                color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
                              ).copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(4, 2),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                            quote: DefaultTextBlockStyle(
                              _typography.toTextStyle(
                                color: isPaperDark ? const Color(0xFFDCD6CA) : const Color(0xFF424242),
                              ).copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(4, 4),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
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

          // Fixed Bottom Formatting Toolbar
          ListenableBuilder(
            listenable: _audioSanctumService,
            builder: (context, _) => EditorToolbar(
              controller: _controller!,
              isDictating: _isDictating,
              isSoundscapePlaying: _audioSanctumService.isPlaying,
              onPickImage: _handleImagePick,
              onPickVideo: _handleVideoPick,
              onToggleDictation: () => setState(() => _isDictating = !_isDictating),
              onOpenTypography: _handleTypographySettings,
              onOpenTemplates: _handleTemplateSwitch,
              onOpenSoundscapes: _handleOpenSoundscapes,
            ),
          ),
        ],
      ),
    );
  }
}
