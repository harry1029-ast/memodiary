import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart' show EditorState;

import '../../../templates/widgets/template_canvas_painter.dart';
import '../../controllers/stationery_quill_controller.dart';
import '../../domain/stationery_sheet_descriptor.dart';
import '../../domain/stationery_sheet_geometry.dart';
import '../../ink_choreography/ink_choreography_config.dart';
import '../../ink_choreography/ink_choreography_controller.dart';
import '../../ink_choreography/ink_slot.dart';
import '../../ink_choreography/quill_composing_probe.dart';
import '../../ink_choreography/sheet_glyph_locator.dart';
import '../../ink_choreography/sheet_ink_choreographer.dart';
import '../../models/stationery_sheet_configs.dart';
import '../../services/audio_sanctum_service.dart';
import '../editor_quill_styles_builder.dart';
import 'sheet_ink_painters.dart';

/// The non-destructive Ink Choreography overlay of one Stationery Sheet
/// (SPEC-020 §4, ADR-0011). The editor underneath stays the single source of
/// truth for the text; this only hides freshly written characters behind the
/// sheet's own paper and writes them out.
///
/// It wraps the sheet card built by [cardBuilder] and adds two layers that
/// never take a pointer:
/// - the mask-and-ink layer, handed to [cardBuilder] to place inside the
///   card's clip, above the sheet body and below the Page Corner folds;
/// - the brush layer, an unclipped sibling above the card.
///
/// It hears the sheet's edits and IME composing range, runs one ticker only
/// while characters are being written and only on the active sheet, and
/// answers the preferences' full-sheet replay requests (全页挥毫). A tap on
/// the card, a keystroke, or a page turn ends a replay at once. Every sheet
/// gets the same wrapper, text sheet or not, so a page turn never remounts
/// an editor.
class SheetInkStage extends StatefulWidget {
  final StationerySheetDescriptor sheet;

  /// Whether this is the sheet the diarist is on. Only it animates.
  final bool isActive;
  final StationerySheetGeometry geometry;

  /// The Journal Letterhead's height on this sheet, as passed to the card's
  /// own paper.
  final double headerHeight;
  final StationerySheetThemeConfig themeConfig;
  final InkChoreographyController preferences;
  final AudioSanctumService audioSanctumService;

  /// Hears this sheet's IME start (true) or stop (false) composing.
  final ValueChanged<bool>? onComposingChanged;

  /// Builds the sheet card around the mask-and-ink layer.
  final Widget Function(Widget inkLayer) cardBuilder;

  const SheetInkStage({
    super.key,
    required this.sheet,
    required this.isActive,
    required this.geometry,
    required this.headerHeight,
    required this.themeConfig,
    required this.preferences,
    required this.audioSanctumService,
    required this.cardBuilder,
    this.onComposingChanged,
  });

  @override
  State<SheetInkStage> createState() => SheetInkStageState();
}

/// Public so tests can read what a sheet is writing through [ink] and
/// [isAnimating].
class SheetInkStageState extends State<SheetInkStage> with SingleTickerProviderStateMixin {
  final GlobalKey _inkLayerKey = GlobalKey();
  final GlobalKey _brushLayerKey = GlobalKey();
  final SheetPaperPicture _paperPicture = SheetPaperPicture();
  late final Ticker _ticker = createTicker(_onTick);
  late final QuillComposingProbe _composingProbe = QuillComposingProbe(onChanged: _onComposingRange);
  Duration _lastElapsed = Duration.zero;
  StationeryQuillController? _observedController;
  EditorState? _editorState;
  bool _isComposing = false;

  /// What this sheet is writing: its queue of characters and its brushes.
  late final SheetInkChoreographer ink = SheetInkChoreographer(
    config: () => widget.preferences.config,
    fontSize: () => widget.themeConfig.typography.fontSize,
    locate: _locate,
    hasFocus: () => _textSheet?.focusNode.hasFocus ?? false,
    plainText: () => _textSheet?.document.toPlainText() ?? '',
    onWake: _wake,
  );

  /// Whether the overlay's ticker is running.
  bool get isAnimating => _ticker.isActive;

  TextStationerySheet? get _textSheet {
    final sheet = widget.sheet;
    return sheet is TextStationerySheet ? sheet : null;
  }

  Color get _inkColor => widget.themeConfig.writingInkColor;

  TemplateCanvasPainter _paperOf(SheetInkStage stage) => TemplateCanvasPainter(
        style: stage.themeConfig.templateStyle,
        typography: stage.themeConfig.typography,
        headerHeight: stage.headerHeight,
        layoutMetrics: stage.geometry.metrics,
      );

  @override
  void initState() {
    super.initState();
    ink.addListener(_stopWhenIdle);
    _listenTo(widget.preferences);
    _observe(_textSheet);
  }

  void _listenTo(InkChoreographyController preferences) {
    preferences.addListener(_onPreferencesChanged);
    preferences.sheetReplayRequests.addListener(_onReplayRequested);
  }

  void _stopListeningTo(InkChoreographyController preferences) {
    preferences.removeListener(_onPreferencesChanged);
    preferences.sheetReplayRequests.removeListener(_onReplayRequested);
  }

  /// Turning live writing off reveals whatever was still being written. A
  /// replay goes on: it never depended on the saved mode.
  void _onPreferencesChanged() {
    if (widget.preferences.config.deliveryMode == InkDeliveryMode.off && !ink.isReplaying) ink.settleAll();
  }

  @override
  void didUpdateWidget(covariant SheetInkStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.preferences, widget.preferences)) {
      _stopListeningTo(oldWidget.preferences);
      _listenTo(widget.preferences);
    }
    final didTurnAway = oldWidget.isActive && !widget.isActive;
    final didChangePaper = oldWidget.geometry != widget.geometry ||
        oldWidget.headerHeight != widget.headerHeight ||
        oldWidget.themeConfig.inkColor != widget.themeConfig.inkColor ||
        oldWidget.themeConfig.typography.textColor != widget.themeConfig.typography.textColor ||
        _paperOf(widget).shouldRepaint(_paperOf(oldWidget));
    if (didTurnAway || didChangePaper || !identical(_textSheet?.controller, _observedController)) {
      ink.settleAll();
    }
    _observe(_textSheet);
  }

  @override
  void dispose() {
    _observe(null);
    _composingProbe.detach();
    _stopListeningTo(widget.preferences);
    _ticker.dispose();
    ink.dispose();
    _paperPicture.dispose();
    super.dispose();
  }

  /// Hears [sheet]'s edits in place of the sheet observed before.
  void _observe(TextStationerySheet? sheet) {
    final controller = sheet?.controller;
    final next = controller is StationeryQuillController ? controller : null;
    final previous = _observedController;
    if (identical(previous, next)) return;
    if (previous != null && identical(previous.editObserver, ink.tracker)) previous.editObserver = null;
    next?.editObserver = ink.tracker;
    _observedController = next;
  }

  /// The sheet's live editor, found under this stage rather than through
  /// `sheet.editorKey`: `QuillEditor` adopts its editor key once, so the key
  /// of a sheet descriptor that replaced another on the same page (a
  /// re-index after Auto-Spill, a re-layout) is never attached. Not callable
  /// while building.
  EditorState? _findEditor() {
    final controller = _textSheet?.controller;
    if (controller == null) return _editorState = null;
    final known = _editorState;
    if (known != null && known.mounted && identical(known.widget.controller, controller)) return known;
    EditorState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is EditorState) {
        final state = element.state as EditorState;
        if (identical(state.widget.controller, controller)) found = state;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return _editorState = found;
  }

  /// The sheet's editor is mounted only after this frame: bind to its
  /// composing range then (and again whenever its state was replaced).
  void _bindComposingProbeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composingProbe.attach(_findEditor());
    });
  }

  void _onComposingRange(TextRange range) {
    ink.tracker.onComposingChanged(range);
    final isComposing = range.isValid && !range.isCollapsed;
    if (isComposing == _isComposing) return;
    _isComposing = isComposing;
    widget.onComposingChanged?.call(isComposing);
  }

  InkGlyphGeometry? _locate(InkSlot slot) {
    final sheet = _textSheet;
    if (sheet == null) return null;
    final theme = widget.themeConfig;
    final geometry = widget.geometry;
    return SheetGlyphLocator(
      editorState: _findEditor(),
      inkLayer: _inkLayerKey.currentContext?.findRenderObject(),
      bodyTop: geometry.paperHeart.top + widget.headerHeight,
      lineStride: geometry.lineStridePx,
      textStyle: theme.typography.toTextStyle(color: theme.inkColor).copyWith(
            letterSpacing: EditorQuillStylesBuilder.calculateGridLetterSpacing(
              backgroundType: theme.templateStyle.type,
              lineStridePx: geometry.lineStridePx,
              fontSize: theme.typography.fontSize,
            ),
          ),
    ).locate(slot.offset, slot.character);
  }

  /// The ink layer's origin inside the brush layer.
  Offset _inkLayerOrigin() {
    final inkLayer = _inkLayerKey.currentContext?.findRenderObject();
    final brushLayer = _brushLayerKey.currentContext?.findRenderObject();
    if (inkLayer is! RenderBox || brushLayer is! RenderBox) return Offset.zero;
    return brushLayer.globalToLocal(inkLayer.localToGlobal(Offset.zero));
  }

  void _wake() {
    if (!mounted) return;
    if (!widget.isActive) {
      // Only the active sheet may animate: anything queued elsewhere is
      // revealed, once the edit that queued it has finished reporting.
      scheduleMicrotask(() {
        if (mounted && !widget.isActive) ink.settleAll();
      });
      return;
    }
    if (_ticker.isActive) return;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _stopWhenIdle() {
    if (ink.isIdle && _ticker.isActive) _ticker.stop();
  }

  void _onTick(Duration elapsed) {
    final strokeStarts = ink.advance(elapsed - _lastElapsed);
    _lastElapsed = elapsed;
    if (strokeStarts > 0) {
      widget.audioSanctumService.playBrushStroke(soundEnabled: widget.preferences.config.soundEnabled);
    }
  }

  void _onReplayRequested() {
    if (widget.isActive && _textSheet != null) ink.replay();
  }

  void _cancelReplay(PointerDownEvent event) {
    if (ink.isReplaying) ink.settleAll();
  }

  @override
  Widget build(BuildContext context) {
    _bindComposingProbeAfterFrame();
    final inkLayer = IgnorePointer(
      key: const Key('editor_ink_mask_layer'),
      child: RepaintBoundary(
        child: CustomPaint(
          key: _inkLayerKey,
          painter: SheetInkMaskPainter(
            ink: ink,
            paper: _paperOf(widget),
            paperPicture: _paperPicture,
            inkColor: _inkColor,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        // A Listener only watches: the editor's own gestures still win.
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _cancelReplay,
          child: widget.cardBuilder(inkLayer),
        ),
        Positioned.fill(
          child: IgnorePointer(
            key: const Key('editor_ink_brush_layer'),
            child: RepaintBoundary(
              child: CustomPaint(
                key: _brushLayerKey,
                painter: SheetInkBrushPainter(ink: ink, inkColor: _inkColor, inkLayerOrigin: _inkLayerOrigin),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
