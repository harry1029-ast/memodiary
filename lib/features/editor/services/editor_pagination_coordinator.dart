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
import 'stationery_delta_splitter.dart';
import 'stationery_delta_synthesizer.dart';
import 'stationery_line_measurer.dart';

export 'editor_pagination_models.dart';

/// Central coordinator bridging the continuous Quill Delta document in SQLite
/// and discrete, integer-locked Stationery Sheets in the authoring canvas.
class EditorPaginationCoordinator extends ChangeNotifier {
  final List<StationerySheetDescriptor> _sheets = <StationerySheetDescriptor>[];
  int _activeSheetIndex = 0;

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

  /// Ordered list of active stationery sheets.
  List<StationerySheetDescriptor> get sheets => List.unmodifiable(_sheets);

  /// Total sheet count.
  int get totalSheets => _sheets.length;

  /// Current 0-based index of the visible stationery sheet.
  int get activeSheetIndex => _activeSheetIndex;

  set activeSheetIndex(int value) {
    if (value >= 0 && value < _sheets.length && value != _activeSheetIndex) {
      _activeSheetIndex = value;
      notifyListeners();
    }
  }

  /// Whether active mobile IME composition is currently underway on the given sheet.
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

  /// Synthesizes all active sheets back into a single continuous Quill Delta.
  Delta synthesizeUnifiedDelta() => StationeryDeltaSynthesizer.synthesize(_sheets);

  /// Re-synthesizes the unified Delta JSON string and segmented plain text representation.
  (String deltaJson, String plainText) reSynthesize() {
    final unified = synthesizeUnifiedDelta();
    final plainText = Document.fromDelta(unified).toPlainText().trim();
    if (plainText.isEmpty && _sheets.every((sheet) => sheet is! EphemeraSheet)) {
      return ('[]', '');
    }
    final jsonStr = jsonEncode(unified.toJson());
    return (jsonStr, plainText);
  }

  /// Checks if [sheetIndex] exceeds row capacity, and if so, performs Auto-Spill.
  AutoSpillResult? checkAndPerformAutoSpill(int sheetIndex) {
    if (sheetIndex < 0 || sheetIndex >= _sheets.length) return null;
    final sheet = _sheets[sheetIndex];
    if (sheet is! TextStationerySheet) return null;

    if (isSheetComposing(sheetIndex)) {
      return null;
    }

    final currentRows = StationeryLineMeasurer.measureDeltaRows(
      delta: sheet.delta,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: templateStyle.type,
      lineStridePx: lineStridePx,
    );

    if (currentRows <= sheet.rowCapacity) {
      return null;
    }

    final overflow = StationeryDeltaSplitter.extractOverflow(
      sheetDelta: sheet.delta,
      rowCapacity: sheet.rowCapacity,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: templateStyle.type,
      lineStridePx: lineStridePx,
    );

    if (overflow.overflowingDelta.isEmpty ||
        (overflow.overflowingDelta.length == 1 &&
            overflow.overflowingDelta.first.data == '\n')) {
      return null;
    }

    final currentCaret = sheet.controller.selection.baseOffset;
    sheet.setDelta(overflow.remainingDelta);
    sheet.hasTrailingSoftNewline = overflow.hasTrailingSoftNewline;

    int destinationIndex = sheetIndex + 1;
    bool didAllocateNew = false;

    if (destinationIndex >= _sheets.length ||
        _sheets[destinationIndex] is! TextStationerySheet) {
      final newSheet = ContinuationSheet.empty(sheetIndex: destinationIndex);
      _sheets.insert(destinationIndex, newSheet);
      didAllocateNew = true;
      _reindexSheets();
    }

    final destinationSheet = _sheets[destinationIndex] as TextStationerySheet;
    final mergedDelta = StationeryDeltaSplitter.mergeDeltaSlices(
      firstSlice: overflow.overflowingDelta,
      secondSlice: destinationSheet.delta,
      firstSliceHasSoftNewline: overflow.hasTrailingSoftNewline,
    );
    destinationSheet.setDelta(mergedDelta);

    int destinationCaretOffset = 0;
    if (currentCaret > overflow.splitOffset) {
      destinationCaretOffset = math.max(0, currentCaret - overflow.splitOffset);
      _activeSheetIndex = destinationIndex;
      destinationSheet.controller.updateSelection(
        TextSelection.collapsed(offset: destinationCaretOffset),
        ChangeSource.local,
      );
    }

    checkAndPerformAutoSpill(destinationIndex);
    notifyListeners();

    final result = AutoSpillResult(
      sourceSheetIndex: sheetIndex,
      destinationSheetIndex: destinationIndex,
      destinationCaretOffset: destinationCaretOffset,
      didAllocateNewSheet: didAllocateNew,
    );
    onAutoSpill?.call(result);
    return result;
  }

  /// Handles backspace at offset 0 on a continuation sheet, triggering Spill-Back.
  SpillBackResult? handleSpillBack(int sheetIndex) {
    if (sheetIndex <= 0 || sheetIndex >= _sheets.length) return null;
    final currentSheet = _sheets[sheetIndex];
    if (currentSheet is! TextStationerySheet) return null;

    int precedingIndex = -1;
    for (int i = sheetIndex - 1; i >= 0; i--) {
      if (_sheets[i] is TextStationerySheet) {
        precedingIndex = i;
        break;
      }
    }
    if (precedingIndex < 0) return null;

    final precedingSheet = _sheets[precedingIndex] as TextStationerySheet;
    final precedingDocLength = math.max(0, precedingSheet.document.length - 1);

    if (currentSheet.isEmpty) {
      _sheets.removeAt(sheetIndex);
      currentSheet.dispose();
      _reindexSheets();
      _activeSheetIndex = precedingIndex;
      precedingSheet.controller.updateSelection(
        TextSelection.collapsed(offset: precedingDocLength),
        ChangeSource.local,
      );
      notifyListeners();
      return SpillBackResult(
        sourceSheetIndex: sheetIndex,
        destinationSheetIndex: precedingIndex,
        destinationCaretOffset: precedingDocLength,
        didCollapse: true,
      );
    }

    final precedingRows = StationeryLineMeasurer.measureDeltaRows(
      delta: precedingSheet.delta,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: templateStyle.type,
      lineStridePx: lineStridePx,
    );
    final availableRows = math.max(0, precedingSheet.rowCapacity - precedingRows);

    if (availableRows > 0) {
      final merged = StationeryDeltaSplitter.mergeDeltaSlices(
        firstSlice: precedingSheet.delta,
        secondSlice: currentSheet.delta,
        firstSliceHasSoftNewline: precedingSheet.hasTrailingSoftNewline,
      );
      precedingSheet.setDelta(merged);
      _sheets.removeAt(sheetIndex);
      currentSheet.dispose();
      _reindexSheets();
      _activeSheetIndex = precedingIndex;
      precedingSheet.controller.updateSelection(
        TextSelection.collapsed(offset: precedingDocLength),
        ChangeSource.local,
      );
      notifyListeners();
      return SpillBackResult(
        sourceSheetIndex: sheetIndex,
        destinationSheetIndex: precedingIndex,
        destinationCaretOffset: precedingDocLength,
        didCollapse: true,
      );
    }

    _activeSheetIndex = precedingIndex;
    precedingSheet.controller.updateSelection(
      TextSelection.collapsed(offset: precedingDocLength),
      ChangeSource.local,
    );
    notifyListeners();
    return SpillBackResult(
      sourceSheetIndex: sheetIndex,
      destinationSheetIndex: precedingIndex,
      destinationCaretOffset: precedingDocLength,
      didCollapse: false,
    );
  }

  /// Auto-collapses empty continuation sheets (`sheetIndex > 0`), preserving Sheet 1.
  bool collapseEmptyContinuationSheets() {
    bool didCollapse = false;
    for (int index = _sheets.length - 1; index > 0; index--) {
      final sheet = _sheets[index];
      if (sheet is TextStationerySheet && sheet.isEmpty) {
        _sheets.removeAt(index);
        sheet.dispose();
        didCollapse = true;
      }
    }
    if (didCollapse) {
      _reindexSheets();
      _activeSheetIndex = _activeSheetIndex.clamp(0, _sheets.length - 1);
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
    required String mediaType,
    required MediaEmbedData mediaData,
    int? atIndex,
  }) {
    final targetIndex = atIndex ?? (_activeSheetIndex + 1);
    final ephemera = EphemeraSheet(
      sheetIndex: targetIndex,
      mediaType: mediaType,
      mediaData: mediaData,
    );
    _sheets.insert(targetIndex, ephemera);
    _reindexSheets();
    _activeSheetIndex = targetIndex;
    notifyListeners();
  }

  /// Removes an ephemera sheet at [sheetIndex], maintaining contiguous indexing.
  void removeEphemeraSheet(int sheetIndex) {
    if (sheetIndex < 0 || sheetIndex >= _sheets.length) return;
    final sheet = _sheets[sheetIndex];
    if (sheet is EphemeraSheet) {
      _sheets.removeAt(sheetIndex);
      sheet.dispose();
      _reindexSheets();
      _activeSheetIndex = _activeSheetIndex.clamp(0, _sheets.length - 1);
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
    _reindexSheets();
    notifyListeners();
    return continuation;
  }

  void _reindexSheets() {
    for (int index = 0; index < _sheets.length; index++) {
      _sheets[index] = _sheets[index].copyWithIndex(index);
    }
  }

  @override
  void dispose() {
    for (final sheet in _sheets) {
      sheet.dispose();
    }
    _sheets.clear();
    super.dispose();
  }
}
