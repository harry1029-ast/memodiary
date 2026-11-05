import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/typography_settings.dart';
import 'editor_pagination_models.dart';
import 'stationery_delta_splitter.dart';
import 'stationery_line_measurer.dart';

/// Encapsulates multi-sheet Auto-Spill cascades, Spill-Back budget merges,
/// mid-sheet media splits, and equivalence checks for [EditorPaginationCoordinator].
class StationerySheetSpillMutator {
  const StationerySheetSpillMutator._();

  static void reindexSheets(List<StationerySheetDescriptor> sheets) {
    for (int index = 0; index < sheets.length; index++) {
      sheets[index] = sheets[index].copyWithIndex(index);
    }
  }

  static bool areSheetsEquivalent(
    List<StationerySheetDescriptor> current,
    List<StationerySheetDescriptor> candidate,
  ) {
    if (current.length != candidate.length) return false;
    for (int index = 0; index < current.length; index++) {
      final left = current[index];
      final right = candidate[index];
      if (left.runtimeType != right.runtimeType) return false;
      if (left is TextStationerySheet && right is TextStationerySheet) {
        if (left.delta != right.delta ||
            left.hasTrailingSoftNewline != right.hasTrailingSoftNewline) {
          return false;
        }
        if (left.mediaAttachments.length != right.mediaAttachments.length) {
          return false;
        }
        for (int itemIndex = 0; itemIndex < left.mediaAttachments.length; itemIndex++) {
          if (left.mediaAttachments[itemIndex] != right.mediaAttachments[itemIndex]) {
            return false;
          }
        }
      } else if (left is EphemeraSheet && right is EphemeraSheet) {
        if (left.mediaType != right.mediaType ||
            left.sandboxedRelativePath != right.sandboxedRelativePath ||
            left.caption != right.caption) {
          return false;
        }
      }
    }
    return true;
  }

  /// Performs single or cascading Auto-Spill from [sheetIndex], returning the
  /// final [AutoSpillResult] and updated `activeSheetIndex` if overflow occurred.
  static ({AutoSpillResult result, int activeSheetIndex})? performAutoSpill({
    required List<StationerySheetDescriptor> sheets,
    required int sheetIndex,
    required int currentActiveIndex,
    required TypographySettings typography,
    required TemplateBackgroundType backgroundType,
    required double? contentWidth,
    required double? lineStridePx,
    required bool Function(int index) isSheetComposing,
  }) {
    if (sheetIndex < 0 || sheetIndex >= sheets.length) return null;
    final sheet = sheets[sheetIndex];
    if (sheet is! TextStationerySheet || isSheetComposing(sheetIndex)) {
      return null;
    }

    final currentRows = StationeryLineMeasurer.measureDeltaRows(
      delta: sheet.delta,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: backgroundType,
      lineStridePx: lineStridePx,
    );
    if (currentRows <= sheet.rowCapacity) return null;

    final overflow = StationeryDeltaSplitter.extractOverflow(
      sheetDelta: sheet.delta,
      rowCapacity: sheet.rowCapacity,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: backgroundType,
      lineStridePx: lineStridePx,
    );

    if (overflow.overflowingDelta.isEmpty) {
      return null;
    }

    final currentCaret = sheet.controller.selection.baseOffset;
    final caretMovedToOverflow = currentCaret > overflow.splitOffset;

    sheet.setDelta(overflow.remainingDelta);
    sheet.hasTrailingSoftNewline = overflow.hasTrailingSoftNewline;

    final destinationIndex = sheetIndex + 1;
    bool didAllocateNew = false;

    if (destinationIndex >= sheets.length ||
        sheets[destinationIndex] is! TextStationerySheet) {
      final newSheet = ContinuationSheet.empty(sheetIndex: destinationIndex);
      sheets.insert(destinationIndex, newSheet);
      didAllocateNew = true;
      reindexSheets(sheets);
    }

    final destinationSheet = sheets[destinationIndex] as TextStationerySheet;
    final mergedDelta = StationeryDeltaSplitter.mergeDeltaSlices(
      firstSlice: overflow.overflowingDelta,
      secondSlice: destinationSheet.delta,
      firstSliceHasSoftNewline: overflow.hasTrailingSoftNewline,
    );

    int nextActiveIndex = currentActiveIndex;
    int destinationCaretOffset = 0;
    if (caretMovedToOverflow) {
      destinationCaretOffset = math.max(0, currentCaret - overflow.splitOffset);
      nextActiveIndex = destinationIndex;
      destinationSheet.setDelta(
        mergedDelta,
        selection: TextSelection.collapsed(offset: destinationCaretOffset),
      );
    } else {
      destinationSheet.setDelta(mergedDelta);
    }

    final cascaded = performAutoSpill(
      sheets: sheets,
      sheetIndex: destinationIndex,
      currentActiveIndex: nextActiveIndex,
      typography: typography,
      backgroundType: backgroundType,
      contentWidth: contentWidth,
      lineStridePx: lineStridePx,
      isSheetComposing: isSheetComposing,
    );

    int finalDestinationIndex = destinationIndex;
    int finalCaretOffset = destinationCaretOffset;
    bool finalDidAllocate =
        didAllocateNew || (cascaded?.result.didAllocateNewSheet ?? false);

    if (cascaded != null) {
      nextActiveIndex = cascaded.activeSheetIndex;
      if (caretMovedToOverflow &&
          nextActiveIndex == cascaded.result.destinationSheetIndex) {
        finalDestinationIndex = cascaded.result.destinationSheetIndex;
        finalCaretOffset = cascaded.result.destinationCaretOffset;
      }
    }

    return (
      result: AutoSpillResult(
        sourceSheetIndex: sheetIndex,
        destinationSheetIndex: finalDestinationIndex,
        destinationCaretOffset: finalCaretOffset,
        didAllocateNewSheet: finalDidAllocate,
      ),
      activeSheetIndex: nextActiveIndex,
    );
  }

  /// Performs Spill-Back from [sheetIndex] onto its nearest preceding text sheet,
  /// re-spilling excess lines so `precedingSheet.rowCapacity` is never exceeded.
  static ({
    SpillBackResult result,
    int activeSheetIndex,
    bool didMutateContent,
  })? performSpillBack({
    required List<StationerySheetDescriptor> sheets,
    required int sheetIndex,
    required TypographySettings typography,
    required TemplateBackgroundType backgroundType,
    required double? contentWidth,
    required double? lineStridePx,
    required bool Function(int index) isSheetComposing,
  }) {
    if (sheetIndex <= 0 || sheetIndex >= sheets.length) return null;
    final currentSheet = sheets[sheetIndex];
    if (currentSheet is! TextStationerySheet) return null;

    int precedingIndex = -1;
    for (int scanIndex = sheetIndex - 1; scanIndex >= 0; scanIndex--) {
      if (sheets[scanIndex] is TextStationerySheet) {
        precedingIndex = scanIndex;
        break;
      }
    }
    if (precedingIndex < 0) return null;

    final precedingSheet = sheets[precedingIndex] as TextStationerySheet;
    final precedingDocLength = math.max(0, precedingSheet.document.length - 1);

    if (currentSheet.isEmpty) {
      sheets.removeAt(sheetIndex);
      currentSheet.dispose();
      reindexSheets(sheets);
      precedingSheet.controller.updateSelection(
        TextSelection.collapsed(offset: precedingDocLength),
        ChangeSource.local,
      );
      return (
        result: SpillBackResult(
          sourceSheetIndex: sheetIndex,
          destinationSheetIndex: precedingIndex,
          destinationCaretOffset: precedingDocLength,
          didCollapse: true,
        ),
        activeSheetIndex: precedingIndex,
        didMutateContent: true,
      );
    }

    final precedingRows = StationeryLineMeasurer.measureDeltaRows(
      delta: precedingSheet.delta,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: backgroundType,
      lineStridePx: lineStridePx,
    );
    final availableRows = math.max(0, precedingSheet.rowCapacity - precedingRows);

    if (availableRows > 0) {
      final merged = StationeryDeltaSplitter.mergeDeltaSlices(
        firstSlice: precedingSheet.delta,
        secondSlice: currentSheet.delta,
        firstSliceHasSoftNewline: precedingSheet.hasTrailingSoftNewline,
      );
      precedingSheet.hasTrailingSoftNewline = currentSheet.hasTrailingSoftNewline;
      precedingSheet.setDelta(
        merged,
        selection: TextSelection.collapsed(offset: precedingDocLength),
      );
      sheets.removeAt(sheetIndex);
      currentSheet.dispose();
      reindexSheets(sheets);

      final reSpilled = performAutoSpill(
        sheets: sheets,
        sheetIndex: precedingIndex,
        currentActiveIndex: precedingIndex,
        typography: typography,
        backgroundType: backgroundType,
        contentWidth: contentWidth,
        lineStridePx: lineStridePx,
        isSheetComposing: isSheetComposing,
      );

      final clampedCaret = precedingDocLength
          .clamp(0, math.max(0, precedingSheet.document.length - 1))
          .toInt();
      precedingSheet.controller.updateSelection(
        TextSelection.collapsed(offset: clampedCaret),
        ChangeSource.local,
      );

      return (
        result: SpillBackResult(
          sourceSheetIndex: sheetIndex,
          destinationSheetIndex: precedingIndex,
          destinationCaretOffset: clampedCaret,
          didCollapse: reSpilled == null,
        ),
        activeSheetIndex: precedingIndex,
        didMutateContent: true,
      );
    }

    precedingSheet.controller.updateSelection(
      TextSelection.collapsed(offset: precedingDocLength),
      ChangeSource.local,
    );
    return (
      result: SpillBackResult(
        sourceSheetIndex: sheetIndex,
        destinationSheetIndex: precedingIndex,
        destinationCaretOffset: precedingDocLength,
        didCollapse: false,
      ),
      activeSheetIndex: precedingIndex,
      didMutateContent: false,
    );
  }
}
