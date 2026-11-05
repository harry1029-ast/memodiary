import 'dart:math' as math;
import 'package:flutter_quill/quill_delta.dart';
import '../../templates/models/template_style.dart';
import '../models/typography_settings.dart';
import 'stationery_line_measurer.dart';

/// Value object representing the outcome of a virtual Delta split.
class DeltaSplitResult {
  final Delta firstSlice;
  final Delta secondSlice;
  final bool hasTrailingSoftNewline;

  const DeltaSplitResult({
    required this.firstSlice,
    required this.secondSlice,
    required this.hasTrailingSoftNewline,
  });
}

/// Result of extracting overflowing trailing content from a stationery sheet.
class SheetOverflowResult {
  final Delta remainingDelta;
  final Delta overflowingDelta;
  final int splitOffset;
  final bool hasTrailingSoftNewline;

  const SheetOverflowResult({
    required this.remainingDelta,
    required this.overflowingDelta,
    required this.splitOffset,
    required this.hasTrailingSoftNewline,
  });
}

/// Pure service handling lossless splitting and bidirectional re-merging
/// of Quill Delta operations across Stationery Sheets without dropping attributes
/// or splitting UTF-16 surrogate pairs.
class StationeryDeltaSplitter {
  const StationeryDeltaSplitter._();

  /// Appends [source] operations onto [target], optionally stripping a single
  /// trailing artificial soft newline from [source]'s final string insert operation.
  static void appendDeltaStrippingSoftNewline({
    required Delta target,
    required Delta source,
    required bool stripTrailingSoftNewline,
  }) {
    if (!stripTrailingSoftNewline || source.isEmpty) {
      for (final operation in source.operations) {
        target.push(operation);
      }
      return;
    }

    for (int opIndex = 0; opIndex < source.operations.length; opIndex++) {
      final operation = source.operations[opIndex];
      final isLast = opIndex == source.operations.length - 1;

      if (isLast && operation.isInsert && operation.data is String) {
        final text = operation.data as String;
        if (text.endsWith('\n')) {
          final stripped = text.substring(0, text.length - 1);
          if (stripped.isNotEmpty) {
            target.push(Operation.insert(stripped, operation.attributes));
          }
        } else {
          target.push(operation);
        }
      } else {
        target.push(operation);
      }
    }
  }

  /// Maps a plain-text [textOffset] (which excludes mount markers) to the
  /// matching Delta offset, where each marker takes one position. Markers at
  /// or before the offset stay with the leading slice, so an item mounted at
  /// the end of a sheet's text stays on that sheet.
  static int deltaOffsetOfTextOffset(Delta delta, int textOffset) {
    var textCount = 0;
    var deltaCount = 0;
    for (final operation in delta.operations) {
      if (!operation.isInsert) continue;
      final data = operation.data;
      if (data is String) {
        final remaining = textOffset - textCount;
        if (remaining < data.length) return deltaCount + remaining;
        textCount += data.length;
        deltaCount += data.length;
      } else {
        deltaCount += 1;
      }
    }
    return deltaCount;
  }

  /// Splits [sourceDelta] at character [splitOffset].
  ///
  /// If the split occurs mid-paragraph, an artificial soft newline is appended
  /// to [firstSlice] to satisfy Quill's trailing-newline invariant, and
  /// [hasTrailingSoftNewline] is set to true.
  static DeltaSplitResult splitDeltaAtCharacterOffset({
    required Delta sourceDelta,
    required int splitOffset,
    Map<String, dynamic>? trailingParagraphAttributes,
  }) {
    final firstSlice = Delta();
    final secondSlice = Delta();
    int currentOffset = 0;

    for (final operation in sourceDelta.operations) {
      if (!operation.isInsert) continue;

      if (operation.data is Map) {
        if (currentOffset + 1 <= splitOffset) {
          firstSlice.push(operation);
        } else {
          secondSlice.push(operation);
        }
        currentOffset += 1;
        continue;
      }

      if (operation.data is String) {
        final text = operation.data as String;
        final opLength = text.length;

        if (currentOffset + opLength <= splitOffset) {
          firstSlice.push(operation);
          currentOffset += opLength;
        } else if (currentOffset < splitOffset &&
            currentOffset + opLength > splitOffset) {
          final cutPoint = splitOffset - currentOffset;
          var safeCutPoint = StationeryLineMeasurer.snapToSafeCodePointBoundary(
            text,
            cutPoint,
          );
          if (cutPoint > 0 && safeCutPoint == 0 && text.isNotEmpty) {
            safeCutPoint = math.min(text.length, cutPoint + 1);
          }

          final part1 = text.substring(0, safeCutPoint);
          final part2 = text.substring(safeCutPoint);

          if (part1.isNotEmpty) {
            firstSlice.push(Operation.insert(part1, operation.attributes));
          }
          if (part2.isNotEmpty) {
            secondSlice.push(Operation.insert(part2, operation.attributes));
          }
          currentOffset += opLength;
        } else {
          secondSlice.push(operation);
          currentOffset += opLength;
        }
      }
    }

    bool hasTrailingSoftNewline = false;

    if (firstSlice.isEmpty) {
      firstSlice.push(Operation.insert('\n', trailingParagraphAttributes));
      hasTrailingSoftNewline = true;
    } else {
      final lastOp = firstSlice.operations.last;
      if (lastOp.data is String && (lastOp.data as String).endsWith('\n')) {
        hasTrailingSoftNewline = false;
      } else {
        firstSlice.push(Operation.insert('\n', trailingParagraphAttributes));
        hasTrailingSoftNewline = true;
      }
    }

    if (secondSlice.isEmpty) {
      secondSlice.push(Operation.insert('\n'));
    } else {
      final lastOp = secondSlice.operations.last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        secondSlice.push(Operation.insert('\n'));
      }
    }

    return DeltaSplitResult(
      firstSlice: firstSlice,
      secondSlice: secondSlice,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }

  /// Merges [firstSlice] and [secondSlice] back into a single continuous Delta.
  static Delta mergeDeltaSlices({
    required Delta firstSlice,
    required Delta secondSlice,
    bool firstSliceHasSoftNewline = false,
  }) {
    final combined = Delta();
    appendDeltaStrippingSoftNewline(
      target: combined,
      source: firstSlice,
      stripTrailingSoftNewline: firstSliceHasSoftNewline,
    );
    for (final operation in secondSlice.operations) {
      combined.push(operation);
    }
    return combined;
  }

  /// Extracts overflowing content from [sheetDelta] when it exceeds [rowCapacity].
  static SheetOverflowResult extractOverflow({
    required Delta sheetDelta,
    required int rowCapacity,
    required TypographySettings typography,
    double? contentWidth,
    TemplateBackgroundType backgroundType = TemplateBackgroundType.lined,
    double? lineStridePx,
  }) {
    final paragraphs = StationeryLineMeasurer.extractParagraphsFromDelta(
      sheetDelta,
    );
    int remainingRows = rowCapacity;
    int cumulativeDocumentOffset = 0;

    final headDelta = Delta();
    final tailDelta = Delta();
    bool isOverflowing = false;
    int splitOffset = 0;
    bool hasTrailingSoftNewline = false;

    for (final paragraph in paragraphs) {
      if (isOverflowing) {
        for (final operation in paragraph.operations) {
          tailDelta.push(operation);
        }
        continue;
      }

      final measured = StationeryLineMeasurer.measureParagraph(
        text: paragraph.plainText,
        blockAttributes: paragraph.blockAttributes,
        inlineOperations: paragraph.operations,
        typography: typography,
        contentWidth: contentWidth,
        backgroundType: backgroundType,
        lineStridePx: lineStridePx,
      );

      if (measured.totalRows <= remainingRows) {
        for (final operation in paragraph.operations) {
          headDelta.push(operation);
        }
        remainingRows -= measured.totalRows;
        // Document offsets, where each mount marker takes one position.
        cumulativeDocumentOffset += paragraph.operations.fold<int>(
          0,
          (sum, operation) => sum + (operation.length ?? 0),
        );
      } else {
        isOverflowing = true;
        final rawLinesThatFit = math.max(0, remainingRows ~/ measured.rowWeight);
        final linesThatFit =
            (rawLinesThatFit == 0 && headDelta.isEmpty) ? 1 : rawLinesThatFit;

        if (linesThatFit == 0) {
          splitOffset = cumulativeDocumentOffset;
          hasTrailingSoftNewline = false;
          for (final operation in paragraph.operations) {
            tailDelta.push(operation);
          }
        } else {
          final lineBreakIndex = math.min(
            linesThatFit - 1,
            measured.lineBreakOffsets.length - 1,
          );
          var paragraphCutOffset = measured.lineBreakOffsets[lineBreakIndex];
          if (paragraphCutOffset <= 0 && paragraph.plainText.isNotEmpty) {
            paragraphCutOffset = math.min(paragraph.plainText.length, 1);
          }
          final paragraphDelta = Delta();
          for (final operation in paragraph.operations) {
            paragraphDelta.push(operation);
          }
          final paragraphDeltaCut = deltaOffsetOfTextOffset(paragraphDelta, paragraphCutOffset);
          splitOffset = cumulativeDocumentOffset + paragraphDeltaCut;

          final split = splitDeltaAtCharacterOffset(
            sourceDelta: paragraphDelta,
            splitOffset: paragraphDeltaCut,
            trailingParagraphAttributes: paragraph.blockAttributes,
          );

          for (final operation in split.firstSlice.operations) {
            headDelta.push(operation);
          }
          for (final operation in split.secondSlice.operations) {
            tailDelta.push(operation);
          }
          hasTrailingSoftNewline = split.hasTrailingSoftNewline;
        }
      }
    }

    if (!isOverflowing) {
      return SheetOverflowResult(
        remainingDelta: sheetDelta,
        overflowingDelta: Delta(),
        splitOffset: cumulativeDocumentOffset,
        hasTrailingSoftNewline: false,
      );
    }

    if (headDelta.isEmpty) {
      headDelta.push(Operation.insert('\n'));
    } else {
      final lastOp = headDelta.operations.last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        headDelta.push(Operation.insert('\n'));
        hasTrailingSoftNewline = true;
      }
    }

    if (tailDelta.isEmpty) {
      tailDelta.push(Operation.insert('\n'));
    } else {
      final lastOp = tailDelta.operations.last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        tailDelta.push(Operation.insert('\n'));
      }
    }

    return SheetOverflowResult(
      remainingDelta: headDelta,
      overflowingDelta: tailDelta,
      splitOffset: splitOffset,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }
}
