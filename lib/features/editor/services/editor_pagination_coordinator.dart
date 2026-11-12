import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import '../controllers/stationery_quill_controller.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/typography_settings.dart';
import 'editor_delta_partitioner.dart';
import '../models/mount_marker.dart';
import 'editor_pagination_models.dart';
import 'sheet_mount_resolver.dart';
import 'stationery_delta_synthesizer.dart';
import 'stationery_sheet_spill_mutator.dart';

export 'editor_pagination_models.dart';

part 'sheet_media_operations.dart';

/// Central coordinator bridging the continuous Quill Delta document in SQLite
/// and discrete, integer-locked Stationery Sheets in the authoring canvas.
class EditorPaginationCoordinator extends ChangeNotifier {
  final List<StationerySheetDescriptor> _sheets = <StationerySheetDescriptor>[];

  /// Items in the Staging Handscroll (no mount marker), in collect order.
  final List<SheetMediaItem> _stagedItems = <SheetMediaItem>[];
  final ValueNotifier<int> contentRevision = ValueNotifier<int>(0);
  int _activeSheetIndex = 0;
  bool _isDisposed = false;
  bool _isMutatingSheets = false;

  TypographySettings typography;
  TemplateStyle templateStyle;
  double? contentWidth;
  double? lineStridePx;
  /// The rows each sheet holds, following the rows ruled in its Paper Heart.
  SheetRowCapacity rowCapacity;
  bool isImeComposing = false;
  ValueChanged<AutoSpillResult>? onAutoSpill;
  ValueChanged<SpillBackResult>? onSpillBack;

  /// Receives items that reflow pushed past the last sheet's capacity and that
  /// were therefore unmounted back to the Staging Handscroll.
  ValueChanged<List<SheetMediaItem>>? onOverflowUnmount;

  final MountReflowTracker _mounts = MountReflowTracker();

  EditorPaginationCoordinator({
    this.typography = const TypographySettings(),
    this.templateStyle = const TemplateStyle(
      type: TemplateBackgroundType.lined,
      backgroundColor: Color(0xFFFBF8F1),
      lineSpacing: 1.5,
      marginHorizontal: 24.0,
    ),
    this.contentWidth,
    this.lineStridePx,
    this.rowCapacity = SheetRowCapacity.folioLeaf,
  });

  /// Most items the Staging Handscroll holds at once.
  static const int kHandscrollCapacity = _SheetMediaOperations.kHandscrollCapacity;

  late final _SheetMediaOperations _media = _SheetMediaOperations(this);

  /// Free slots left in the Staging Handscroll.
  int get handscrollRoom => _media.handscrollRoom;

  /// Collects [item] into the Staging Handscroll, after every earlier item.
  bool collectMedia(SheetMediaItem item) => _media.collect(item);

  /// Mounts the staged item [mediaId] onto the active text sheet.
  bool mountOnActiveSheet(String mediaId) => _media.mountOnActiveSheet(mediaId);

  /// Unmounts [mediaId] and returns it to the Staging Handscroll in collect order.
  bool unmountMedia(String mediaId) => _media.unmount(mediaId);

  /// Removes the staged item [mediaId] from the Staging Handscroll.
  SheetMediaItem? removeStaged(String mediaId) => _media.removeStaged(mediaId);

  /// Restores an erased [item] back into the Staging Handscroll in collect order.
  void restoreStaged(SheetMediaItem item) => _media.restoreStaged(item);

  /// Updates the in-memory caption of [mediaId], whether staged or mounted.
  bool updateCaption(String mediaId, String newCaption) =>
      _media.updateCaption(mediaId, newCaption);

  /// Removes an ephemera sheet at [sheetIndex], maintaining contiguous indexing.
  void removeEphemeraSheet(int sheetIndex) =>
      _media.removeEphemeraSheet(sheetIndex);

  List<StationerySheetDescriptor> get sheets => List.unmodifiable(_sheets);

  /// Items waiting in the Staging Handscroll, in collect order.
  List<SheetMediaItem> get stagedItems => List.unmodifiable(_stagedItems);
  int get totalSheets => _sheets.length;
  int get activeSheetIndex => _activeSheetIndex;

  set activeSheetIndex(int value) {
    if (value >= 0 && value < _sheets.length && value != _activeSheetIndex) {
      _activeSheetIndex = value;
      notifyListeners();
    }
  }

  void _markContentMutated() {
    contentRevision.value++;
  }

  void _notifyContentMutated() {
    contentRevision.value++;
    notifyListeners();
  }

  /// Whether active mobile IME composition is currently underway on [sheetIndex].
  bool isSheetComposing(int sheetIndex) {
    if (isImeComposing) return true;
    if (sheetIndex < 0 || sheetIndex >= _sheets.length) return false;
    final sheet = _sheets[sheetIndex];
    if (sheet is! TextStationerySheet) return false;
    final composing = sheet.controller.plainTextEditingValue.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  /// Populates the coordinator from a raw continuous Quill Delta JSON array.
  ///
  /// [attachments] are resolved against the Delta's mount markers: referenced
  /// ones are mounted on their sheets, the rest are staged in collect order.
  void initializeFromDelta(
    String contentDeltaJson, {
    String? fallbackPlainText,
    List<MediaAttachment> attachments = const [],
  }) {
    _media.adoptCollectOrder(attachments.map((attachment) => attachment.id));
    _initialize(
      contentDeltaJson,
      fallbackPlainText: fallbackPlainText,
      media: attachments.map(SheetMediaItem.fromMediaAttachment).toList(),
    );
  }

  void _initialize(
    String contentDeltaJson, {
    String? fallbackPlainText,
    required List<SheetMediaItem> media,
  }) {
    for (final sheet in _sheets) {
      sheet.dispose();
    }
    _sheets.clear();

    final unifiedDelta = StationeryDeltaSynthesizer.decode(
      contentDeltaJson,
      fallbackPlainText: fallbackPlainText,
    );

    final partition = EditorDeltaPartitioner.partition(
      unifiedDelta: unifiedDelta,
      media: media,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
      rowCapacity: rowCapacity,
    );

    _sheets.addAll(partition.sheets);
    _media.adoptPartitionMounts(partition);
    _activeSheetIndex = 0;
    notifyListeners();
  }

  /// Re-resolves which sheet shows each mounted item after the text changed.
  void reflowMounts() => _media.reflowMounts();

  List<SheetMediaItem> _knownItems() => _mounts.knownItems(_sheets, _stagedItems);

  /// Synchronizes measured Paper Heart text width, stride and [visibleRows]
  /// (the rows ruled inside it) outside `build()`, re-balancing sheets cleanly
  /// if they changed while not composing.
  void syncLayoutMetrics({
    required double contentWidth,
    required double lineStridePx,
    required int visibleRows,
  }) {
    if (_isDisposed) return;

    final widthChanged = this.contentWidth == null ||
        (this.contentWidth! - contentWidth).abs() > 1.0;
    final strideChanged = this.lineStridePx == null ||
        (this.lineStridePx! - lineStridePx).abs() > 0.5;
    final capacityChanged = rowCapacity.visibleRows != visibleRows;

    this.contentWidth = contentWidth;
    this.lineStridePx = lineStridePx;
    rowCapacity = SheetRowCapacity(visibleRows: visibleRows);

    final onLegacyMountPass = _onLegacyMountPass;
    if (onLegacyMountPass != null) {
      // Partitioned at the measured width, so placement matches what the
      // pre-marker editor showed; no separate re-balance is needed.
      _onLegacyMountPass = null;
      onLegacyMountPass(_media.mountLegacyAttachments());
      return;
    }

    if (!widthChanged && !strideChanged && !capacityChanged) return;
    if (_sheets case [] || [OpeningSheet(isEmpty: true)]) return;
    if (_sheets.any((sheet) =>
        isSheetComposing(sheet.sheetIndex) ||
        (sheet is TextStationerySheet && sheet.focusNode.hasFocus))) {
      return;
    }

    final unifiedDelta = synthesizeUnifiedDelta();
    final partition = EditorDeltaPartitioner.partition(
      unifiedDelta: unifiedDelta,
      media: _knownItems(),
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
      rowCapacity: rowCapacity,
    );
    final partitioned = partition.sheets;

    if (StationerySheetSpillMutator.areSheetsEquivalent(_sheets, partitioned)) {
      for (final candidate in partitioned) {
        candidate.dispose();
      }
      return;
    }

    final previousIndex = _activeSheetIndex.clamp(0, _sheets.length - 1);
    final previousSheet = _sheets[previousIndex];
    final previousOffset = previousSheet is TextStationerySheet
        ? previousSheet.controller.selection.baseOffset
        : 0;
    final hadFocus = previousSheet is TextStationerySheet
        ? previousSheet.focusNode.hasFocus
        : false;

    for (final sheet in _sheets) {
      sheet.dispose();
    }
    _sheets
      ..clear()
      ..addAll(partitioned);
    _media.adoptPartitionMounts(partition);
    _activeSheetIndex = previousIndex.clamp(0, _sheets.length - 1);

    final restoredSheet = _sheets[_activeSheetIndex];
    if (restoredSheet is TextStationerySheet) {
      final maxOffset = math.max(0, restoredSheet.document.length - 1);
      restoredSheet.editWithoutKeyboard(() {
        restoredSheet.controller.updateSelection(
          TextSelection.collapsed(offset: previousOffset.clamp(0, maxOffset)),
          ChangeSource.local,
        );
      });
      if (hadFocus) {
        restoredSheet.focusNode.requestFocus();
      }
    }
    notifyListeners();
  }

  Delta synthesizeUnifiedDelta() => StationeryDeltaSynthesizer.synthesize(_sheets);

  /// Re-synthesizes the unified Delta JSON string and plain text representation,
  /// stripping mount markers that reference no known attachment (or repeat one).
  (String deltaJson, String plainText) reSynthesize() =>
      StationeryDeltaSynthesizer.reSynthesize(
        _sheets,
        knownMediaIds: {for (final item in _knownItems()) item.id},
      );

  /// Checks if [sheetIndex] exceeds row capacity, and if so, performs Auto-Spill.
  AutoSpillResult? checkAndPerformAutoSpill(int sheetIndex) {
    if (_isMutatingSheets) return null;
    _isMutatingSheets = true;
    late final ({AutoSpillResult result, int activeSheetIndex})? outcome;
    try {
      outcome = StationerySheetSpillMutator.performAutoSpill(
        sheets: _sheets,
        sheetIndex: sheetIndex,
        currentActiveIndex: _activeSheetIndex,
        typography: typography,
        backgroundType: templateStyle.type,
        contentWidth: contentWidth,
        lineStridePx: lineStridePx,
        rowCapacity: rowCapacity,
        isSheetComposing: isSheetComposing,
      );
      if (outcome == null) return null;

      _media.bindLeadingBackspaceCallbacks();
      _activeSheetIndex = outcome.activeSheetIndex;
      reflowMounts();
      _markContentMutated();
    } finally {
      _isMutatingSheets = false;
    }
    notifyListeners();
    onAutoSpill?.call(outcome.result);
    return outcome.result;
  }

  /// Handles backspace at offset 0 on a continuation sheet, triggering Spill-Back.
  SpillBackResult? handleSpillBack(int sheetIndex) {
    if (_isMutatingSheets) return null;
    _isMutatingSheets = true;
    late final ({SpillBackResult result, int activeSheetIndex, bool didMutateContent})? outcome;
    try {
      _mounts.rememberMounted(_sheets);
      outcome = StationerySheetSpillMutator.performSpillBack(
        sheets: _sheets,
        sheetIndex: sheetIndex,
        typography: typography,
        backgroundType: templateStyle.type,
        contentWidth: contentWidth,
        lineStridePx: lineStridePx,
        rowCapacity: rowCapacity,
        isSheetComposing: isSheetComposing,
      );
      if (outcome == null) return null;

      _media.bindLeadingBackspaceCallbacks();
      _activeSheetIndex = outcome.activeSheetIndex;
      if (outcome.didMutateContent) {
        reflowMounts();
        _markContentMutated();
      }
    } finally {
      _isMutatingSheets = false;
    }
    notifyListeners();
    onSpillBack?.call(outcome.result);
    return outcome.result;
  }

  /// Auto-collapses trailing empty continuation sheets (`sheetIndex > 0`), preserving Sheet 1.
  bool collapseEmptyContinuationSheets({bool allowActive = false}) {
    bool didCollapse = false;
    for (int index = _sheets.length - 1; index > 0; index--) {
      if (!allowActive && index == _activeSheetIndex) break;
      final sheet = _sheets[index];
      if (sheet is TextStationerySheet && sheet.isEmpty) {
        if (!allowActive && sheet.focusNode.hasFocus) break;
        if (sheet.focusNode.hasFocus) sheet.focusNode.unfocus();
        _sheets.removeAt(index);
        sheet.dispose();
        didCollapse = true;
      } else {
        break;
      }
    }
    if (didCollapse) {
      StationerySheetSpillMutator.reindexSheets(_sheets);
      _media.bindLeadingBackspaceCallbacks();
      _activeSheetIndex = _activeSheetIndex.clamp(0, _sheets.length - 1);
      // A collapsed sheet may have shown items cascaded from earlier sheets.
      reflowMounts();
      _markContentMutated();
      notifyListeners();
    }
    return didCollapse;
  }

  /// Updates typography, re-balancing all sheets without mutating content or formatting.
  void updateTypography(
    TypographySettings newTypography, {
    double? newContentWidth,
    TemplateStyle? newTemplateStyle,
    double? newLineStridePx,
  }) {
    final unifiedDelta = synthesizeUnifiedDelta();
    final allMedia = _knownItems();

    typography = newTypography;
    if (newContentWidth != null) contentWidth = newContentWidth;
    if (newTemplateStyle != null) templateStyle = newTemplateStyle;
    if (newLineStridePx != null) lineStridePx = newLineStridePx;

    _initialize(jsonEncode(unifiedDelta.toJson()), media: allMedia);
  }

  void Function(bool didMount)? _onLegacyMountPass;

  /// Schedules the legacy mounting pass (ADR-0009) for the first
  /// [syncLayoutMetrics], once the Paper Heart width and stride are measured:
  /// every staged item is then mounted first-come by writing its marker into
  /// the Delta, as the pre-marker editor placed them. [onComplete] receives
  /// whether any marker was written.
  void runLegacyMountPassOnFirstLayout(void Function(bool didMount) onComplete) {
    _onLegacyMountPass = onComplete;
  }

  /// Finds or creates a text-bearing sheet immediately following [fromIndex].
  TextStationerySheet getOrCreateFollowingTextSheet(int fromIndex) {
    for (int sheetIndex = fromIndex + 1; sheetIndex < _sheets.length; sheetIndex++) {
      final candidate = _sheets[sheetIndex];
      if (candidate is TextStationerySheet) {
        return candidate;
      }
    }
    final newIndex = _sheets.length;
    final continuation = ContinuationSheet.empty(sheetIndex: newIndex);
    _sheets.add(continuation);
    StationerySheetSpillMutator.reindexSheets(_sheets);
    _media.bindLeadingBackspaceCallbacks();
    notifyListeners();
    return continuation;
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final sheet in _sheets) {
      sheet.dispose();
    }
    _sheets.clear();
    contentRevision.dispose();
    super.dispose();
  }
}
