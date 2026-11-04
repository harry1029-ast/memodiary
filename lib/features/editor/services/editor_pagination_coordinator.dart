import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/media_embed_data.dart';
import '../models/typography_settings.dart';
import 'editor_delta_partitioner.dart';
import 'editor_pagination_models.dart';
import 'stationery_delta_synthesizer.dart';
import 'stationery_sheet_spill_mutator.dart';

export 'editor_pagination_models.dart';

/// Central coordinator bridging the continuous Quill Delta document in SQLite
/// and discrete, integer-locked Stationery Sheets in the authoring canvas.
class EditorPaginationCoordinator extends ChangeNotifier {
  final List<StationerySheetDescriptor> _sheets = <StationerySheetDescriptor>[];
  final ValueNotifier<int> contentRevision = ValueNotifier<int>(0);
  int _activeSheetIndex = 0;
  bool _isDisposed = false;

  TypographySettings typography;
  TemplateStyle templateStyle;
  double? contentWidth;
  double? lineStridePx;
  bool isImeComposing = false;
  ValueChanged<AutoSpillResult>? onAutoSpill;

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

  List<StationerySheetDescriptor> get sheets => List.unmodifiable(_sheets);
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
  void initializeFromDelta(
    String contentDeltaJson, {
    String? fallbackPlainText,
    List<MediaAttachment> attachments = const [],
  }) {
    for (final sheet in _sheets) {
      sheet.dispose();
    }
    _sheets.clear();

    Delta unifiedDelta;
    if (contentDeltaJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentDeltaJson);
        if (decoded is List) {
          unifiedDelta = Delta.fromJson(decoded);
        } else if (decoded is Map && decoded['ops'] is List) {
          unifiedDelta = Delta.fromJson(decoded['ops'] as List);
        } else {
          unifiedDelta = Delta()..insert('\n');
        }
      } catch (_) {
        unifiedDelta = Delta()..insert('\n');
      }
    } else if (fallbackPlainText != null && fallbackPlainText.trim().isNotEmpty) {
      unifiedDelta = Delta()..insert(fallbackPlainText);
      if (!fallbackPlainText.endsWith('\n')) {
        unifiedDelta.insert('\n');
      }
    } else {
      unifiedDelta = Delta()..insert('\n');
    }

    final partitioned = EditorDeltaPartitioner.partition(
      unifiedDelta: unifiedDelta,
      attachments: attachments,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
    );

    _sheets.addAll(partitioned);
    _activeSheetIndex = 0;
    notifyListeners();
  }

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
    final partitioned = EditorDeltaPartitioner.partition(
      unifiedDelta: unifiedDelta,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
    );

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

  /// Re-synthesizes the unified Delta JSON string and plain text representation.
  (String deltaJson, String plainText) reSynthesize() {
    final unified = synthesizeUnifiedDelta();
    final plainText = Document.fromDelta(unified).toPlainText().trim();
    if (plainText.isEmpty && _sheets.every((sheet) => sheet is! EphemeraSheet)) {
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
    typography = newTypography;
    if (newContentWidth != null) contentWidth = newContentWidth;
    if (newTemplateStyle != null) templateStyle = newTemplateStyle;
    if (newLineStridePx != null) lineStridePx = newLineStridePx;

    initializeFromDelta(jsonEncode(unifiedDelta.toJson()));
  }

  /// Inserts a new ephemera sheet at [atIndex] or after the active sheet.
  void insertEphemeraSheet({
    required EphemeraMediaType mediaType,
    required MediaEmbedData mediaData,
    int? atIndex,
  }) {
    final targetIndex = (atIndex ?? (_activeSheetIndex + 1)).clamp(0, _sheets.length);
    _sheets.insert(
      targetIndex,
      EphemeraSheet(
        sheetIndex: targetIndex,
        mediaType: mediaType,
        mediaData: mediaData,
      ),
    );
    StationerySheetSpillMutator.reindexSheets(_sheets);
    _activeSheetIndex = targetIndex;
    _markContentMutated();
    notifyListeners();
  }

  /// Inserts media at the active selection, splitting mid-sheet prose cleanly.
  void insertMediaAtCurrentSelection({
    required EphemeraMediaType mediaType,
    required MediaEmbedData mediaData,
  }) {
    if (_sheets.isEmpty) {
      _sheets.add(OpeningSheet.empty(sheetIndex: 0));
    }
    final activeIndex = _activeSheetIndex.clamp(0, _sheets.length - 1);
    _activeSheetIndex = StationerySheetSpillMutator.insertMediaAtSelection(
      sheets: _sheets,
      activeIndex: activeIndex,
      mediaType: mediaType,
      mediaData: mediaData,
    );
    _markContentMutated();
    notifyListeners();
  }

  /// Removes an ephemera sheet at [sheetIndex], maintaining contiguous indexing.
  void removeEphemeraSheet(int sheetIndex) {
    if (sheetIndex < 0 || sheetIndex >= _sheets.length) return;
    final sheet = _sheets[sheetIndex];
    if (sheet is EphemeraSheet) {
      _sheets.removeAt(sheetIndex);
      sheet.dispose();
      StationerySheetSpillMutator.reindexSheets(_sheets);
      _activeSheetIndex = _activeSheetIndex.clamp(0, _sheets.length - 1);
      _markContentMutated();
      notifyListeners();
    }
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
