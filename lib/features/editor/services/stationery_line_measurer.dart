import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/mount_marker.dart';
import '../models/typography_settings.dart';
import '../widgets/editor_quill_styles_builder.dart';
import 'baseline_metrics_calculator.dart';
import 'editor_pagination_models.dart';

/// Represents a measured visual paragraph with its wrapped line count and total integer rows.
class MeasuredParagraph {
  final String text;
  final Map<String, dynamic>? blockAttributes;
  final int wrappedLines;
  final int rowWeight;
  final int totalRows;
  final List<int> lineBreakOffsets;

  const MeasuredParagraph({
    required this.text,
    this.blockAttributes,
    required this.wrappedLines,
    required this.rowWeight,
    required this.totalRows,
    required this.lineBreakOffsets,
  });
}

/// Deterministic wrapped visual line and row measurement engine for the paginated editor.
///
/// Accounts for:
/// - Active [TypographySettings] and [StrutStyle] line stride.
/// - Dynamic grid `letterSpacing` on grid and dotGrid stationery.
/// - [PaperHeart] inner content width.
/// - Integer row weights: `H1` and `H2` headings occupy 2 rows per wrapped line;
///   `H3`, body paragraphs, blockquotes, lists, and `{夹注:...}` occupy 1 row per wrapped line.
/// - Deterministic character-per-row fallback (17 chars/row) when width is unconstrained.
/// - UTF-16 surrogate pair and emoji rune boundary preservation.
class StationeryLineMeasurer {
  const StationeryLineMeasurer._();

  static const int kFallbackCharsPerRow = 17;

  /// Returns the integer row weight per visual wrapped line for the given block attributes.
  /// H1/H2 headings occupy 2 rows per line; everything else occupies 1 row per line.
  static int calculateRowWeight(Map<String, dynamic>? blockAttributes) {
    if (blockAttributes == null) return 1;
    final header = blockAttributes['header'];
    if (header == 1 || header == 2) {
      return 2;
    }
    return 1;
  }

  /// Calculates dynamic letter-spacing for orthogonal grid and dot-grid stationery.
  static double calculateGridLetterSpacing({
    required TemplateBackgroundType backgroundType,
    required double lineStridePx,
    required double fontSize,
  }) {
    return EditorQuillStylesBuilder.calculateGridLetterSpacing(
      backgroundType: backgroundType,
      lineStridePx: lineStridePx,
      fontSize: fontSize,
    );
  }

  /// Snaps [offset] backward if it falls in the middle of a UTF-16 surrogate pair
  /// to ensure emoji and multi-byte runes are never split.
  static int snapToSafeCodePointBoundary(String text, int offset) {
    if (offset <= 0) return 0;
    if (offset >= text.length) return text.length;

    final codeUnit = text.codeUnitAt(offset);
    // If offset points to a low surrogate (0xDC00..0xDFFF), step back to high surrogate
    if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
      return offset - 1;
    }
    return offset;
  }

  /// Measures a single paragraph with its wrapped line breaks and row metrics.
  static MeasuredParagraph measureParagraph({
    required String text,
    Map<String, dynamic>? blockAttributes,
    List<Operation>? inlineOperations,
    required TypographySettings typography,
    double? contentWidth,
    TemplateBackgroundType backgroundType = TemplateBackgroundType.lined,
    double? lineStridePx,
  }) {
    final effectiveStride = lineStridePx ??
        BaselineMetricsCalculator.calculateLineHeight(typography.toTextStyle());
    final rowWeight = calculateRowWeight(blockAttributes);

    // Strip trailing newline for measurement purposes
    final measurementText = text.endsWith('\n')
        ? text.substring(0, text.length - 1)
        : text;

    if (measurementText.isEmpty) {
      return MeasuredParagraph(
        text: text,
        blockAttributes: blockAttributes,
        wrappedLines: 1,
        rowWeight: rowWeight,
        totalRows: rowWeight,
        lineBreakOffsets: [text.length],
      );
    }

    final isConstrained = contentWidth != null &&
        contentWidth > 0 &&
        !contentWidth.isInfinite;

    if (!isConstrained) {
      return _measureParagraphFallback(
        originalText: text,
        measurementText: measurementText,
        blockAttributes: blockAttributes,
        rowWeight: rowWeight,
      );
    }

    return _measureParagraphWithTextPainter(
      originalText: text,
      measurementText: measurementText,
      blockAttributes: blockAttributes,
      inlineOperations: inlineOperations,
      typography: typography,
      contentWidth: contentWidth,
      backgroundType: backgroundType,
      lineStridePx: effectiveStride,
      rowWeight: rowWeight,
    );
  }

  static MeasuredParagraph _measureParagraphFallback({
    required String originalText,
    required String measurementText,
    Map<String, dynamic>? blockAttributes,
    required int rowWeight,
  }) {
    final charCount = measurementText.runes.length;
    final wrappedLines = math.max(
      1,
      (charCount / kFallbackCharsPerRow).ceil(),
    );

    final lineBreakOffsets = <int>[];
    int currentOffset = 0;
    for (int lineIndex = 0; lineIndex < wrappedLines; lineIndex++) {
      if (lineIndex == wrappedLines - 1) {
        lineBreakOffsets.add(originalText.length);
      } else {
        final targetOffset = math.min(
          measurementText.length,
          currentOffset + kFallbackCharsPerRow,
        );
        final safeOffset = snapToSafeCodePointBoundary(
          measurementText,
          targetOffset,
        );
        lineBreakOffsets.add(safeOffset);
        currentOffset = safeOffset;
      }
    }

    return MeasuredParagraph(
      text: originalText,
      blockAttributes: blockAttributes,
      wrappedLines: wrappedLines,
      rowWeight: rowWeight,
      totalRows: wrappedLines * rowWeight,
      lineBreakOffsets: lineBreakOffsets,
    );
  }

  static MeasuredParagraph _measureParagraphWithTextPainter({
    required String originalText,
    required String measurementText,
    Map<String, dynamic>? blockAttributes,
    List<Operation>? inlineOperations,
    required TypographySettings typography,
    required double contentWidth,
    required TemplateBackgroundType backgroundType,
    required double lineStridePx,
    required int rowWeight,
  }) {
    final dynamicLetterSpacing = calculateGridLetterSpacing(
      backgroundType: backgroundType,
      lineStridePx: lineStridePx,
      fontSize: typography.fontSize,
    );

    final header = blockAttributes?['header'];
    final double headerFontSize;
    final FontWeight headerFontWeight;

    if (header == 1) {
      headerFontSize = 22.0;
      headerFontWeight = FontWeight.bold;
    } else if (header == 2) {
      headerFontSize = 18.0;
      headerFontWeight = FontWeight.bold;
    } else if (header == 3) {
      headerFontSize = 16.0;
      headerFontWeight = FontWeight.bold;
    } else {
      headerFontSize = typography.fontSize;
      headerFontWeight = FontWeight.normal;
    }

    final baseStyle = typography.toTextStyle().copyWith(
          fontSize: headerFontSize,
          fontWeight: headerFontWeight,
          letterSpacing: dynamicLetterSpacing,
        );

    final TextSpan span;
    if (inlineOperations != null && inlineOperations.isNotEmpty) {
      final children = <TextSpan>[];
      for (final operation in inlineOperations) {
        if (operation.isInsert && operation.data is String) {
          final opText = operation.data as String;
          final cleanOpText = opText.endsWith('\n')
              ? opText.substring(0, opText.length - 1)
              : opText;
          if (cleanOpText.isEmpty) continue;

          final attrs = operation.attributes;
          TextStyle style = baseStyle;
          if (attrs != null) {
            if (attrs['bold'] == true) {
              style = style.copyWith(fontWeight: FontWeight.bold);
            }
            if (attrs['italic'] == true) {
              style = style.copyWith(fontStyle: FontStyle.italic);
            }
            if (attrs['color'] != null) {
              final parsedColor = TemplateStyle.parseHexColor(
                attrs['color'].toString(),
              );
              style = style.copyWith(color: parsedColor);
            }
          }
          children.add(TextSpan(text: cleanOpText, style: style));
        }
      }
      span = children.isNotEmpty
          ? TextSpan(children: children, style: baseStyle)
          : TextSpan(text: measurementText, style: baseStyle);
    } else {
      span = TextSpan(text: measurementText, style: baseStyle);
    }

    final strutStyle = EditorQuillStylesBuilder.buildStrutStyle(
      fontSize: headerFontSize,
      lineStridePx: lineStridePx,
    );

    final textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    );

    try {
      textPainter.layout(maxWidth: contentWidth);
      final metrics = textPainter.computeLineMetrics();
      final lineCount = math.max(1, metrics.length);

      final lineBreakOffsets = <int>[];
      int currentOffset = 0;

      for (int lineIndex = 0; lineIndex < lineCount; lineIndex++) {
        if (lineIndex == lineCount - 1) {
          lineBreakOffsets.add(originalText.length);
        } else {
          final lineBoundary = textPainter.getLineBoundary(
            TextPosition(offset: currentOffset),
          );
          var lineEnd = lineBoundary.end;
          if (lineEnd <= currentOffset) {
            lineEnd = math.min(measurementText.length, currentOffset + 1);
          }
          final safeEnd = snapToSafeCodePointBoundary(
            measurementText,
            lineEnd,
          );
          lineBreakOffsets.add(safeEnd);
          currentOffset = safeEnd;
        }
      }

      return MeasuredParagraph(
        text: originalText,
        blockAttributes: blockAttributes,
        wrappedLines: lineCount,
        rowWeight: rowWeight,
        totalRows: lineCount * rowWeight,
        lineBreakOffsets: lineBreakOffsets,
      );
    } catch (_) {
      return _measureParagraphFallback(
        originalText: originalText,
        measurementText: measurementText,
        blockAttributes: blockAttributes,
        rowWeight: rowWeight,
      );
    } finally {
      textPainter.dispose();
    }
  }

  /// Measures total integer rows for all paragraphs within a [Delta].
  static int measureDeltaRows({
    required Delta delta,
    required TypographySettings typography,
    double? contentWidth,
    TemplateBackgroundType backgroundType = TemplateBackgroundType.lined,
    double? lineStridePx,
  }) {
    int totalRows = 0;
    final paragraphs = extractParagraphsFromDelta(delta);

    for (final paragraph in paragraphs) {
      final measured = measureParagraph(
        text: paragraph.plainText,
        blockAttributes: paragraph.blockAttributes,
        inlineOperations: paragraph.operations,
        typography: typography,
        contentWidth: contentWidth,
        backgroundType: backgroundType,
        lineStridePx: lineStridePx,
      );
      totalRows += measured.totalRows;
    }

    return math.max(1, totalRows);
  }

  /// Tokenizes [delta] into newline-terminated [EditorTextBlock] paragraphs
  /// (keeping zero-height mount markers attached to their passage) and
  /// standalone [EditorEphemeraBlock] embeds.
  static List<EditorContentBlock> extractContentBlocks(Delta delta) {
    final blocks = <EditorContentBlock>[];
    var currentOps = <Operation>[];
    final textBuffer = StringBuffer();
    bool skipNextNewline = false;

    for (final operation in delta.operations) {
      if (!operation.isInsert) continue;

      if (MountMarker.mediaIdOf(operation) != null) {
        // Zero-height mount marker: travels with its paragraph (so a split or
        // spill carries it along) but occupies no row and adds no plain text.
        currentOps.add(operation);
        continue;
      }

      if (operation.data is Map) {
        final map = operation.data as Map;
        if (currentOps.isNotEmpty) {
          blocks.add(EditorTextBlock(
            delta: Delta.fromOperations(currentOps),
            plainText: textBuffer.toString(),
          ));
          currentOps = <Operation>[];
          textBuffer.clear();
        }
        if (map.containsKey('image') || map.containsKey('video')) {
          final isVideo = map.containsKey('video');
          blocks.add(EditorEphemeraBlock(
            mediaType: isVideo ? EphemeraMediaType.video : EphemeraMediaType.image,
            rawData: isVideo ? map['video'] : map['image'],
          ));
          skipNextNewline = true;
        }
        continue;
      }

      if (operation.data is String) {
        var text = operation.data as String;
        if (skipNextNewline && text.startsWith('\n')) {
          text = text.substring(1);
          skipNextNewline = false;
          if (text.isEmpty) {
            continue;
          }
        }
        skipNextNewline = false;

        if (!text.contains('\n')) {
          currentOps.add(Operation.insert(text, operation.attributes));
          textBuffer.write(text);
        } else {
          final lines = text.split('\n');
          for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
            final linePart = lines[lineIndex];
            if (linePart.isNotEmpty) {
              currentOps.add(Operation.insert(linePart, operation.attributes));
              textBuffer.write(linePart);
            }
            if (lineIndex < lines.length - 1) {
              textBuffer.write('\n');
              currentOps.add(Operation.insert('\n', operation.attributes));
              blocks.add(EditorTextBlock(
                delta: Delta.fromOperations(currentOps),
                plainText: textBuffer.toString(),
                blockAttributes: operation.attributes,
              ));
              currentOps = <Operation>[];
              textBuffer.clear();
            }
          }
        }
      }
    }

    if (currentOps.isNotEmpty || textBuffer.isNotEmpty) {
      blocks.add(EditorTextBlock(
        delta: Delta.fromOperations(currentOps),
        plainText: textBuffer.toString(),
      ));
    }

    return blocks;
  }

  /// Groups text operations of a [Delta] into contiguous [EditorTextBlock] paragraphs.
  static List<EditorTextBlock> extractParagraphsFromDelta(Delta delta) {
    return extractContentBlocks(delta).whereType<EditorTextBlock>().toList();
  }
}
