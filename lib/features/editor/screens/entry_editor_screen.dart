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
import '../controllers/editor_chrome_controller.dart';
import '../services/editor_settings_service.dart';
import '../controllers/editor_media_binding.dart';
import '../controllers/editor_pagination_handler.dart';
import '../controllers/writing_focus_guard.dart';
import '../models/letterhead_data.dart';
import '../models/stationery_sheet_configs.dart';
import '../models/typography_settings.dart';
import '../services/audio_sanctum_service.dart';
import '../services/editor_pagination_coordinator.dart';
import '../services/thought_spark_service.dart';
import '../widgets/editor_app_bar_slide.dart';
import '../widgets/editor_paper_canvas.dart';
import '../widgets/editor_media_actions.dart';
import '../widgets/editor_media_feedback.dart';
import '../widgets/editor_overlay_actions.dart';
import '../widgets/editor_top_app_bar.dart';
import '../widgets/editor_writing_panels.dart';
import '../widgets/scholar_chest/scholar_chest_drawer.dart';
import '../widgets/staged_exit_reminder_dialog.dart';

/// Full-Bleed rich-text multimodal diary editor in classical Ink & Paper stationery aesthetic.
/// Decouples content (Quill Delta JSON) from presentation (Procedural Templates & Discrete Sheets).
class EntryEditorScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaSandboxService;
  final String entryId;
  final DictationService? dictationService;
  final ThoughtSparkService? thoughtSparkService;
  final AudioSanctumService? audioSanctumService;
  final ImagePicker? imagePicker;
  final EditorSettingsService? editorSettings;

  const EntryEditorScreen({
    super.key,
    required this.database,
    required this.mediaSandboxService,
    required this.entryId,
    this.dictationService,
    this.thoughtSparkService,
    this.audioSanctumService,
    this.imagePicker,
    this.editorSettings,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final DictationService _dictationService;
  late final ThoughtSparkService _thoughtSparkService;
  late final AudioSanctumService _audioSanctumService;
  late final ImagePicker _imagePicker;

  late final EditorPaginationCoordinator _coordinator;
  final PageController _pageController = PageController();
  final TextEditingController _titleController = TextEditingController();
  EditorAutosaveManager? _autosaveManager;
  EditorPaginationHandler? _paginationHandler;
  EditorMediaBinding? _mediaBinding;

  final GlobalKey _letterheadKey = GlobalKey();
  double _headerHeight = 96.0;

  Template? _currentTemplate;
  TypographySettings _typography = const TypographySettings();

  bool _isLoading = true;
  late final EditorChromeController _chrome;

  DateTime _entryDate = DateTime.now();
  int? _mood;
  String? _weather;
  DateTime? _unlockAt;
  Entry? _entry;
  bool _isCenterAligned = false;
  late final WritingFocusGuard _focusGuard = WritingFocusGuard(
      sheets: () => _coordinator.sheets, isKeyboardVisible: () => _chrome.isKeyboardVisible);

  QuillController get _activeController =>
      _paginationHandler?.activeTextController ?? QuillController.basic();

  @override
  void initState() {
    super.initState();
    _dictationService = widget.dictationService ?? DictationService();
    _thoughtSparkService = widget.thoughtSparkService ?? ThoughtSparkService();
    _audioSanctumService = widget.audioSanctumService ?? AudioSanctumService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _chrome = EditorChromeController(settings: widget.editorSettings ?? EditorSettingsService());
    _chrome.addListener(_rebuild);
    _chrome.restorePreferences();
    _loadEntryData();
  }

  @override
  void dispose() {
    _chrome.dispose();
    _paginationHandler?.dispose();
    _mediaBinding?.dispose();
    _pageController.dispose();
    _coordinator.dispose();
    _autosaveManager?.dispose();
    _titleController.dispose();
    if (widget.dictationService == null) _dictationService.dispose();
    if (widget.audioSanctumService == null) _audioSanctumService.dispose();
    super.dispose();
  }

  void _rebuild() => mounted ? setState(() {}) : null;

  /// Collecting always opens the workstation so the new keepsake is seen landing.
  void _collectMedia({required bool isVideo}) {
    _focusGuard.release();
    _chrome.expandWorkstation();
    _mediaBinding!.pickMedia(context, isVideo: isVideo);
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
        (item) => item.id == entry.templateId,
        orElse: () => templates.first,
      );

      final derivedTypography = TypographySettings.fromTemplate(template);
      final templateStyle = TemplateStyle.fromTemplate(template);
      final attachments = await widget.database.getMediaForEntry(widget.entryId);
      _coordinator = EditorPaginationCoordinator(
        typography: derivedTypography,
        templateStyle: templateStyle,
      )..initializeFromDelta(
          entry.contentDelta,
          fallbackPlainText: entry.plainText,
          attachments: attachments,
        );
      _coordinator.onOverflowUnmount =
          (unmountedItems) => EditorMediaFeedback.showOverflowUnmountNotice(context, unmountedItems);
      if (entry.legacyMountsPending) {
        _coordinator.runLegacyMountPassOnFirstLayout(
          (didMount) => _persistLegacyMountPass(entry, didMount: didMount),
        );
      }

      _titleController.text = entry.title ?? '';

      final autosave = EditorAutosaveManager(
        database: widget.database,
        entryId: widget.entryId,
        coordinator: _coordinator,
        titleController: _titleController,
      );

      final handler = EditorPaginationHandler(
        coordinator: _coordinator,
        pageController: _pageController,
        autosaveManager: autosave,
        onStateChanged: _rebuild,
      );

      if (mounted) {
        setState(() {
          _currentTemplate = template;
          _autosaveManager = autosave;
          _paginationHandler = handler;
          _mediaBinding = EditorMediaBinding(
            database: widget.database,
            mediaSandboxService: widget.mediaSandboxService,
            entryId: widget.entryId,
            imagePicker: _imagePicker,
            coordinator: _coordinator,
            autosaveManager: autosave,
            onStateChanged: _rebuild,
          );
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

  /// Mounts a pre-SPEC-010 entry's unanchored attachments first-come and
  /// persists the markers once, so upgrading never empties sheets into the
  /// Staging Handscroll (ADR-0009).
  Future<void> _persistLegacyMountPass(Entry entry, {required bool didMount}) async {
    final contentDelta = didMount ? _coordinator.reSynthesize().$1 : entry.contentDelta;
    await widget.database.completeLegacyMountPass(entry.id, contentDelta: contentDelta);
  }

  void _toggleCenterAlignment() {
    final active = _paginationHandler?.ensureActiveTextSheet() ?? _activeController;
    setState(() => _isCenterAligned = !_isCenterAligned);
    active.formatSelection(
      _isCenterAligned ? Attribute.centerAlignment : Attribute.leftAlignment,
    );
    _autosaveManager?.markDirty();
  }

  Future<void> _openScholarChest([
    ScholarArtifactType initialArtifact = ScholarArtifactType.stationeryFan,
  ]) async {
    final activeTemplate = _currentTemplate;
    if (activeTemplate == null) return;

    await ScholarChestDrawer.show(
      context: context,
      database: widget.database,
      activeTemplateId: activeTemplate.id,
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
        _coordinator.updateTypography(
          _typography,
          newTemplateStyle: TemplateStyle.fromTemplate(newTemplate),
        );
        _paginationHandler?.attachSheetListeners();
        await widget.database.updateEntryTemplate(widget.entryId, newTemplate.id);
      },
      onTypographyChanged: (newTypography) {
        setState(() => _typography = newTypography);
        _coordinator.updateTypography(newTypography);
        _paginationHandler?.attachSheetListeners();
      },
      onLockChanged: (newUnlockAt) async {
        await widget.database.updateEntryUnlockAt(widget.entryId, newUnlockAt);
        if (mounted) setState(() => _unlockAt = newUnlockAt);
      },
      onToggleAlignment: _toggleCenterAlignment,
    );
  }

  void _openKeepsakeScroll() {
    EditorOverlayActions.openKeepsakeScroll(
      context: context,
      entry: _entry,
      currentTemplate: _currentTemplate,
      coordinator: _coordinator,
      titleController: _titleController,
      mediaSandboxService: widget.mediaSandboxService,
      database: widget.database,
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
    final active = _paginationHandler?.ensureActiveTextSheet() ?? _activeController;
    EditorMediaActions.handleInsertPrompt(
      controller: active,
      prompt: prompt,
      autosaveManager: _autosaveManager,
      onStateChanged: () => setState(() {}),
    );
  }

  Future<void> _handleSaveAndExit() async {
    HapticFeedback.lightImpact();
    final stagedCount = _coordinator.stagedItems.length;
    final shouldLeave = await StagedExitReminderDialog.confirmLeave(context,
        stagedCount: stagedCount, discardStaged: () async => _mediaBinding?.discardAllStaged());
    if (!mounted || !shouldLeave) return;
    await _autosaveManager?.saveDraft(force: true);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    if (_isLoading || _currentTemplate == null || _paginationHandler == null) {
      return Scaffold(
        backgroundColor: tokens.xuanGround,
        body: Center(
          child: CircularProgressIndicator(color: tokens.cinnabar),
        ),
      );
    }

    final themeConfig = StationerySheetThemeConfig.fromTemplateStyle(
      templateStyle: TemplateStyle.fromTemplate(_currentTemplate!),
      typography: _typography,
    );
    final isPaperDark = themeConfig.isPaperDark;
    final paperColor = themeConfig.templateStyle.backgroundColor;
    final inkColor = themeConfig.inkColor;
    final iconColor = themeConfig.iconColor;
    final currentSheetIndex = _paginationHandler!.currentSheetIndex;

    final letterheadConfig = StationeryLetterheadConfig(
      letterheadKey: _letterheadKey,
      headerHeight: _headerHeight,
      data: LetterheadData.resolve(entryDate: _entryDate, weather: _weather, mood: _mood),
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
    );

    _updateHeaderHeight();
    if (_chrome.syncKeyboardInset(MediaQuery.viewInsetsOf(context).bottom)) {
      _focusGuard.onKeyboardClosed(context);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isPaperDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: paperColor,
        appBar: EditorAppBarSlide(
          isAway: _chrome.isKeyboardVisible,
          stripColor: paperColor,
          onHiddenExtent: _chrome.syncAppBarHiddenExtent,
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
        ),
        body: Column(
          children: [
            Expanded(
              child: EditorPaperCanvas(
                themeConfig: themeConfig,
                letterheadConfig: letterheadConfig,
                mediaSandboxService: widget.mediaSandboxService,
                onSaveDraft: () => _autosaveManager?.saveDraft(),
                chrome: _chrome,
                coordinator: _coordinator,
                pageController: _pageController,
                currentSheetIndex: currentSheetIndex,
                totalSheets: _coordinator.totalSheets,
                onPreviousSheet: () => _paginationHandler!.goToSheet(currentSheetIndex - 1),
                onNextSheet: () => _paginationHandler!.goToSheet(currentSheetIndex + 1),
                onPageChanged: _paginationHandler!.handlePageChanged,
                onDeleteEphemera: _paginationHandler!.handleDeleteEphemera,
                deskMedia: EditorMediaFeedback.handlersFor(
                  context,
                  _mediaBinding!,
                  onCollect: () => _collectMedia(isVideo: false),
                  onDeskInteraction: _focusGuard.release,
                ),
                onMediaCaptionChanged: _mediaBinding!.updateCaption,
                saveStatus: _autosaveManager!.statusNotifier,
                onTapDeskOffSheet: _focusGuard.endWriting,
              ),
            ),
            EditorWritingPanels(
              chrome: _chrome,
              controller: _activeController,
              onEnsureTextController: () => _paginationHandler!.ensureActiveTextSheet(),
              dictationService: _dictationService,
              onPickImage: () => _collectMedia(isVideo: false),
              onPickVideo: () => _collectMedia(isVideo: true),
              onShuffleSpark: _handleShuffleSpark,
              paperColor: paperColor,
              inkColor: inkColor,
              isPaperDark: isPaperDark,
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
          setState(() => _headerHeight = height);
        }
      }
    });
  }
}
