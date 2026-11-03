import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/dictation_service.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/models/template_style.dart';
import '../controllers/editor_autosave_manager.dart';
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/thought_spark_service.dart';
import '../widgets/dictation_bar.dart';
import '../widgets/editor_media_actions.dart';
import '../widgets/editor_paper_canvas.dart';
import '../widgets/editor_top_app_bar.dart';
import '../widgets/keepsake_scroll_view.dart';
import '../widgets/scholar_chest/scholar_chest_drawer.dart';
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

  bool _isLoading = true;
  bool _isDictating = false;
  bool _isDockCollapsed = false;

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
    await EditorMediaActions.handleImagePick(
      context: context,
      imagePicker: _imagePicker,
      controller: _controller,
      mediaSandboxService: widget.mediaSandboxService,
      database: widget.database,
      entryId: widget.entryId,
      autosaveManager: _autosaveManager,
    );
  }

  Future<void> _handleVideoPick() async {
    await EditorMediaActions.handleVideoPick(
      context: context,
      imagePicker: _imagePicker,
      controller: _controller,
      mediaSandboxService: widget.mediaSandboxService,
      database: widget.database,
      entryId: widget.entryId,
      autosaveManager: _autosaveManager,
    );
  }

  void _handleShuffleSpark() {
    EditorMediaActions.handleShuffleSpark(
      context: context,
      thoughtSparkService: _thoughtSparkService,
      onAdoptPrompt: _handleInsertPrompt,
    );
  }

  void _handleInsertPrompt(String prompt) {
    EditorMediaActions.handleInsertPrompt(
      controller: _controller,
      prompt: prompt,
      autosaveManager: _autosaveManager,
      onStateChanged: () => setState(() {}),
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
    final iconColor = isPaperDark ? const Color(0xFFDCD6CA) : const Color(0xFF2D2D2D);

    _updateHeaderHeight();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isPaperDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: paperColor,
        appBar: EditorTopAppBar(
          paperColor: paperColor,
          iconColor: iconColor,
          autosaveStatusNotifier: _autosaveManager!.statusNotifier,
          audioSanctumService: _audioSanctumService,
          unlockAt: _unlockAt,
          onSaveAndExit: _handleSaveAndExit,
          onOpenKeepsakeScroll: _openKeepsakeScroll,
          onOpenScholarChest: _openScholarChest,
        ),
        body: Column(
          children: [
            Expanded(
              child: EditorPaperCanvas(
                templateStyle: templateStyle,
                typography: _typography,
                paperBaseTheme: paperBaseTheme,
                inkColor: inkColor,
                isPaperDark: isPaperDark,
                scrollController: _editorScrollController,
                letterheadKey: _letterheadKey,
                headerHeight: _headerHeight,
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
                controller: _controller!,
                focusNode: _editorFocusNode,
                mediaSandboxService: widget.mediaSandboxService,
                onSaveDraft: () => _autosaveManager?.saveDraft(),
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
              inkColor: inkColor,
              isPaperDark: isPaperDark,
              initiallyCollapsed: _isDockCollapsed,
              onCollapsedChanged: (collapsed) => _isDockCollapsed = collapsed,
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
