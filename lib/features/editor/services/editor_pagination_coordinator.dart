import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/typography_settings.dart';
import 'editor_delta_partitioner.dart';
import '../models/mount_marker.dart';
import 'editor_pagination_models.dart';
import 'sheet_media_operations.dart';
import 'sheet_mount_resolver.dart';
import 'stationery_delta_synthesizer.dart';
import 'stationery_sheet_spill_mutator.dart';

export 'editor_pagination_models.dart';

/// Central coordinator bridging the continuous Quill Delta document in SQLite
/// and discrete, integer-locked Stationery Sheets in the authoring canvas.
class EditorPaginationCoordinator extends ChangeNotifier {
  final List<StationerySheetDescriptor> _sheets = <StationerySheetDescriptor>[];

  /// Items in the Staging Handscroll (no mount marker), in collect order.
  final List<SheetMediaItem> _stagedItems = <SheetMediaItem>[];
  final ValueNotifier<int> contentRevision = ValueNotifier<int>(0);
  int _activeSheetIndex = 0;
  bool _isDisposed = false;

  TypographySettings typography;
  TemplateStyle templateStyle;
  double? contentWidth;
  double? lineStridePx;
  bool isImeComposing = false;
  ValueChanged<AutoSpillResult>? onAutoSpill;

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
  });

  /// Media mutations (collect, mount, legacy ephemera sheet removal).
  late final SheetMediaOperations media = SheetMediaOperations(
    sheets: _sheets,
    stagedItems: _stagedItems,
    readActiveIndex: () => _activeSheetIndex,
    writeActiveIndex: (index) => _activeSheetIndex = index,
    onContentMutated: () {
      _markContentMutated();
      notifyListeners();
    },
  );

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
    media.adoptCollectOrder(attachments.map((attachment) => attachment.id));
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

    Delta unifiedDelta;
    if (contentDeltaJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentDeltaJson);
        final ops = decoded is List ? decoded : (decoded is Map ? decoded['ops'] : null);
        unifiedDelta = ops is List ? Delta.fromJson(ops) : (Delta()..insert('\n'));
      } catch (_) {
        unifiedDelta = Delta()..insert('\n');
      }
    } else if (fallbackPlainText != null && fallbackPlainText.trim().isNotEmpty) {
      unifiedDelta = Delta()..insert(fallbackPlainText);
      if (!fallbackPlainText.endsWith('\n')) unifiedDelta.insert('\n');
    } else {
      unifiedDelta = Delta()..insert('\n');
    }

    final partition = EditorDeltaPartitioner.partition(
      unifiedDelta: unifiedDelta,
      media: media,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
    );

    _sheets.addAll(partition.sheets);
    _adoptPartitionMounts(partition);
    _activeSheetIndex = 0;
    notifyListeners();
  }

  void _adoptPartitionMounts(EditorPartition partition) {
    _stagedItems
      ..clear()
      ..addAll(partition.stagedItems);
    _mounts.adoptPartition(partition);
  }

  /// Re-resolves which sheet shows each mounted item after the text changed:
  /// items follow the sheet their marker's passage now lies on, cascade past
  /// full sheets, and those pushed past the last sheet are unmounted (reported
  /// through [onOverflowUnmount]). A marker removed with its text stages its
  /// item; a marker restored by undo remounts it. Deferred while any sheet is
  /// composing, so IME input is never disturbed.
  void reflowMounts() {
    if (_isDisposed) return;
    if (_sheets.any((sheet) => isSheetComposing(sheet.sheetIndex))) return;

    final outcome = _mounts.reflow(_sheets, _stagedItems);
    media.orderStagedByCollect();
    if (outcome.didChange) {
      _markContentMutated();
      notifyListeners();
    }
    if (outcome.unmountedByOverflow.isNotEmpty) {
      onOverflowUnmount?.call(outcome.unmountedByOverflow);
    }
  }

  List<SheetMediaItem> _knownItems() => _mounts.knownItems(_sheets, _stagedItems);

  /// Synchronizes measured Paper Heart text width and stride outside `build()`,
  /// re-balancing sheets cleanly if dimensions changed significantly while not composing.
  void syncLayoutMetrics({
    required double contentWidth,
    required double lineStridePx,
  }) {
    if (_isDisposed) return;

    final widthChanged = this.contentWidth == null ||
        (this.contentWidth! - contentWidth).abs() > 1.0;
    final strideChanged = this.lineStridePx == null ||
        (this.lineStridePx! - lineStridePx).abs() > 0.5;

    this.contentWidth = contentWidth;
    this.lineStridePx = lineStridePx;

    final onLegacyMountPass = _onLegacyMountPass;
    if (onLegacyMountPass != null) {
      // Partitioned at the measured width, so placement matches what the
      // pre-marker editor showed; no separate re-balance is needed.
      _onLegacyMountPass = null;
      onLegacyMountPass(_mountLegacyAttachments());
      return;
    }

    if (!widthChanged && !strideChanged) return;
    if (_sheets.isEmpty) return;
    if (_sheets.length == 1 &&
        _sheets.first is OpeningSheet &&
        (_sheets.first as OpeningSheet).isEmpty) {
      return;
    }
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
    _adoptPartitionMounts(partition);
    _activeSheetIndex = previousIndex.clamp(0, _sheets.length - 1);

    final restoredSheet = _sheets[_activeSheetIndex];
    if (restoredSheet is TextStationerySheet) {
      final maxOffset = math.max(0, restoredSheet.document.length - 1);
      restoredSheet.controller.updateSelection(
        TextSelection.collapsed(offset: previousOffset.clamp(0, maxOffset)),
        ChangeSource.local,
      );
      if (hadFocus) {
        restoredSheet.focusNode.requestFocus();
      }
    }
    notifyListeners();
  }

  Delta synthesizeUnifiedDelta() => StationeryDeltaSynthesizer.synthesize(_sheets);

  /// Re-synthesizes the unified Delta JSON string and plain text representation,
  /// stripping mount markers that reference no known attachment (or repeat one).
  (String deltaJson, String plainText) reSynthesize() {
    final unified = SheetMountResolver.stripOrphanMarkers(
      synthesizeUnifiedDelta(),
      knownMediaIds: {for (final item in _knownItems()) item.id},
    );
    final hasMountMarkers = MountMarker.mediaIdsIn(unified).isNotEmpty;
    final plainText = Document.fromDelta(MountMarker.strip(unified)).toPlainText().trim();
    if (plainText.isEmpty &&
        !hasMountMarkers &&
        _sheets.every((sheet) => sheet is! EphemeraSheet)) {
      return ('[]', '');
    }
    return (jsonEncode(unified.toJson()), plainText);
  }

  /// Checks if [sheetIndex] exceeds row capacity, and if so, performs Auto-Spill.
  AutoSpillResult? checkAndPerformAutoSpill(int sheetIndex) {
    final outcome = StationerySheetSpillMutator.performAutoSpill(
      sheets: _sheets,
      sheetIndex: sheetIndex,
      currentActiveIndex: _activeSheetIndex,
      typography: typography,
      backgroundType: templateStyle.type,
      contentWidth: contentWidth,
      lineStridePx: lineStridePx,
      isSheetComposing: isSheetComposing,
    );
    if (outcome == null) return null;

    _activeSheetIndex = outcome.activeSheetIndex;
    reflowMounts();
    _markContentMutated();
    notifyListeners();
    onAutoSpill?.call(outcome.result);
    return outcome.result;
  }

  /// Handles backspace at offset 0 on a continuation sheet, triggering Spill-Back.
  SpillBackResult? handleSpillBack(int sheetIndex) {
    final outcome = StationerySheetSpillMutator.performSpillBack(
      sheets: _sheets,
      sheetIndex: sheetIndex,
      typography: typography,
      backgroundType: templateStyle.type,
      contentWidth: contentWidth,
      lineStridePx: lineStridePx,
      isSheetComposing: isSheetComposing,
    );
    if (outcome == null) return null;

    _activeSheetIndex = outcome.activeSheetIndex;
    if (outcome.didMutateContent) {
      reflowMounts();
      _markContentMutated();
    }
    notifyListeners();
    return outcome.result;
  }

  /// Auto-collapses trailing empty continuation sheets (`sheetIndex > 0`), preserving Sheet 1.
  bool collapseEmptyContinuationSheets({bool allowActive = false}) {
    bool didCollapse = false;
    for (int index = _sheets.length - 1; index > 0; index--) {
      if (!allowActive && index == _activeSheetIndex) break;
      final sheet = _sheets[index];
      if (sheet is TextStationerySheet && sheet.isEmpty) {
        if (!allowActive && sheet.focusNode.hasFocus) {
          break;
        }
        if (sheet.focusNode.hasFocus) {
          sheet.focusNode.unfocus();
        }
        _sheets.removeAt(index);
        sheet.dispose();
        didCollapse = true;
      } else {
        break;
      }
    }
    if (didCollapse) {
      StationerySheetSpillMutator.reindexSheets(_sheets);
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

  bool _mountLegacyAttachments() {
    if (_stagedItems.isEmpty) return false;
    final allMedia = _knownItems();
    final mountedDelta = EditorDeltaPartitioner.mountLegacyAttachments(
      unifiedDelta: synthesizeUnifiedDelta(),
      media: allMedia,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
    );
    _initialize(jsonEncode(mountedDelta.toJson()), media: allMedia);
    return true;
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
