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

    for (final op in sourceDelta.operations) {
      if (!op.isInsert) continue;

      if (op.data is Map) {
        // Embed node has length 1
        if (currentOffset + 1 <= splitOffset) {
          firstSlice.push(op);
        } else {
          secondSlice.push(op);
        }
        currentOffset += 1;
        continue;
      }

      if (op.data is String) {
        final text = op.data as String;
        final opLength = text.length;

        if (currentOffset + opLength <= splitOffset) {
          firstSlice.push(op);
          currentOffset += opLength;
        } else if (currentOffset < splitOffset &&
            currentOffset + opLength > splitOffset) {
          final cutPoint = splitOffset - currentOffset;
          final safeCutPoint = StationeryLineMeasurer.snapToSafeCodePointBoundary(
            text,
            cutPoint,
          );

          final part1 = text.substring(0, safeCutPoint);
          final part2 = text.substring(safeCutPoint);

          if (part1.isNotEmpty) {
            firstSlice.push(Operation.insert(part1, op.attributes));
          }
          if (part2.isNotEmpty) {
            secondSlice.push(Operation.insert(part2, op.attributes));
          }
          currentOffset += opLength;
        } else {
          secondSlice.push(op);
          currentOffset += opLength;
        }
      }
    }

    bool hasTrailingSoftNewline = false;

    // Ensure firstSlice ends with newline for valid Quill document
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

    // Ensure secondSlice ends with newline for valid Quill document
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
  /// If [firstSliceHasSoftNewline] is true, strips the trailing soft newline
  /// and automatically normalizes adjacent text operations with identical attributes.
  static Delta mergeDeltaSlices({
    required Delta firstSlice,
    required Delta secondSlice,
    bool firstSliceHasSoftNewline = false,
  }) {
    final combined = Delta();

    if (firstSliceHasSoftNewline && firstSlice.isNotEmpty) {
      for (int index = 0; index < firstSlice.operations.length; index++) {
        final op = firstSlice.operations[index];
        final isLast = index == firstSlice.operations.length - 1;

        if (isLast && op.isInsert && op.data is String) {
          final text = op.data as String;
          if (text.endsWith('\n')) {
            final stripped = text.substring(0, text.length - 1);
            if (stripped.isNotEmpty) {
              combined.push(Operation.insert(stripped, op.attributes));
            }
          } else {
            combined.push(op);
          }
        } else {
          combined.push(op);
        }
      }
    } else {
      for (final op in firstSlice.operations) {
        combined.push(op);
      }
    }

    for (final op in secondSlice.operations) {
      combined.push(op);
    }

    return combined;
  }

  /// Extracts overflowing content from [sheetDelta] when it exceeds [rowCapacity].
  ///
  /// Returns [SheetOverflowResult] containing the remaining delta that fits,
  /// the overflowing delta to spill onto the next sheet, and split metadata.
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
    int cumulativeCharacterOffset = 0;

    final headDelta = Delta();
    final tailDelta = Delta();
    bool isOverflowing = false;
    int splitOffset = 0;
    bool hasTrailingSoftNewline = false;

    for (final paragraph in paragraphs) {
      if (isOverflowing) {
        for (final op in paragraph.operations) {
          tailDelta.push(op);
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
        // Fits fully
        for (final op in paragraph.operations) {
          headDelta.push(op);
        }
        remainingRows -= measured.totalRows;
        cumulativeCharacterOffset += paragraph.plainText.length;
      } else {
        // Overflows this sheet!
        isOverflowing = true;
        final linesThatFit = math.max(0, remainingRows ~/ measured.rowWeight);

        if (linesThatFit == 0) {
          // No lines of this paragraph fit; entire paragraph moves to tail
          splitOffset = cumulativeCharacterOffset;
          hasTrailingSoftNewline = false;
          for (final op in paragraph.operations) {
            tailDelta.push(op);
          }
        } else {
          // Some visual lines fit
          final lineBreakIndex = math.min(
            linesThatFit - 1,
            measured.lineBreakOffsets.length - 1,
          );
          final paragraphCutOffset = measured.lineBreakOffsets[lineBreakIndex];
          splitOffset = cumulativeCharacterOffset + paragraphCutOffset;

          final paragraphDelta = Delta();
          for (final op in paragraph.operations) {
            paragraphDelta.push(op);
          }

          final split = splitDeltaAtCharacterOffset(
            sourceDelta: paragraphDelta,
            splitOffset: paragraphCutOffset,
            trailingParagraphAttributes: paragraph.blockAttributes,
          );

          for (final op in split.firstSlice.operations) {
            headDelta.push(op);
          }
          for (final op in split.secondSlice.operations) {
            tailDelta.push(op);
          }
          hasTrailingSoftNewline = split.hasTrailingSoftNewline;
        }
      }
    }

    if (!isOverflowing) {
      return SheetOverflowResult(
        remainingDelta: sheetDelta,
        overflowingDelta: Delta(),
        splitOffset: cumulativeCharacterOffset,
        hasTrailingSoftNewline: false,
      );
    }

    // Ensure valid terminating newlines
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
