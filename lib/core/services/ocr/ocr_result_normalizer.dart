import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'ocr_models.dart';

/// Raw pixel-space line recognized by the native OCR platform channel.
///
/// Origin is top-left in pixel units relative to the decoded image.
@immutable
class RawOcrLine {
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  const RawOcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  static RawOcrLine? tryFromChannelMap(Object? rawLine) {
    if (rawLine is! Map<Object?, Object?>) {
      return null;
    }
    final rawText = rawLine['text'];
    final rawLeft = rawLine['left'];
    final rawTop = rawLine['top'];
    final rawWidth = rawLine['width'];
    final rawHeight = rawLine['height'];

    if (rawText is! String ||
        rawLeft is! num ||
        rawTop is! num ||
        rawWidth is! num ||
        rawHeight is! num) {
      return null;
    }

    return RawOcrLine(
      text: rawText,
      left: rawLeft.toDouble(),
      top: rawTop.toDouble(),
      width: rawWidth.toDouble(),
      height: rawHeight.toDouble(),
    );
  }
}

/// Pure normalizer converting pixel-space native OCR payloads into sanitized,
/// clamped, 4-decimal normalized [OcrResult] value objects.
class OcrResultNormalizer {
  const OcrResultNormalizer._();

  static final RegExp _controlCharsPattern = RegExp(r'[\x00-\x1F\x7F-\x9F]');

  /// Normalizes [rawLines] against [imageWidth] and [imageHeight].
  static OcrResult normalize({
    required num imageWidth,
    required num imageHeight,
    required List<RawOcrLine> rawLines,
  }) {
    final widthPx = imageWidth.toDouble();
    final heightPx = imageHeight.toDouble();
    if (!widthPx.isFinite || !heightPx.isFinite || widthPx <= 0 || heightPx <= 0) {
      return OcrResult.empty;
    }
    if (rawLines.isEmpty) {
      return OcrResult.empty;
    }

    final normalizedBlocks = <OcrLineBlock>[];
    for (final rawLine in rawLines) {
      final sanitizedText = sanitizeText(rawLine.text);
      if (sanitizedText.isEmpty) {
        continue;
      }

      final normalizedBox = _normalizeBox(
        leftPx: rawLine.left,
        topPx: rawLine.top,
        widthPx: rawLine.width,
        heightPx: rawLine.height,
        imageWidthPx: widthPx,
        imageHeightPx: heightPx,
      );
      if (normalizedBox == null) {
        continue;
      }

      normalizedBlocks.add(
        OcrLineBlock(
          text: sanitizedText,
          box: normalizedBox,
        ),
      );
    }

    if (normalizedBlocks.isEmpty) {
      return OcrResult.empty;
    }

    final plainText = normalizedBlocks
        .map((lineBlock) => lineBlock.text)
        .join('\n');

    return OcrResult(
      plainText: plainText,
      lines: List<OcrLineBlock>.unmodifiable(normalizedBlocks),
    );
  }

  /// Decodes and normalizes a raw `memodiary/ocr` method channel map payload.
  static OcrResult normalizeChannelPayload(Map<Object?, Object?>? payload) {
    if (payload == null) {
      return OcrResult.empty;
    }

    final rawImageWidth = payload['imageWidth'];
    final rawImageHeight = payload['imageHeight'];
    final rawLinesList = payload['lines'];

    if (rawImageWidth is! num ||
        rawImageHeight is! num ||
        rawLinesList is! List<Object?>) {
      return OcrResult.empty;
    }

    final parsedLines = <RawOcrLine>[];
    for (final rawItem in rawLinesList) {
      final parsedLine = RawOcrLine.tryFromChannelMap(rawItem);
      if (parsedLine != null) {
        parsedLines.add(parsedLine);
      }
    }

    return normalize(
      imageWidth: rawImageWidth,
      imageHeight: rawImageHeight,
      rawLines: parsedLines,
    );
  }

  /// Strips ASCII C0/C1 control characters and trims surrounding whitespace.
  static String sanitizeText(String rawText) {
    return rawText.replaceAll(_controlCharsPattern, '').trim();
  }

  static List<double>? _normalizeBox({
    required double leftPx,
    required double topPx,
    required double widthPx,
    required double heightPx,
    required double imageWidthPx,
    required double imageHeightPx,
  }) {
    if (!leftPx.isFinite ||
        !topPx.isFinite ||
        !widthPx.isFinite ||
        !heightPx.isFinite) {
      return null;
    }
    if (widthPx <= 0 || heightPx <= 0) {
      return null;
    }

    final clampedLeftPx = leftPx.clamp(0.0, imageWidthPx);
    final clampedRightPx = (leftPx + widthPx).clamp(0.0, imageWidthPx);
    final clampedTopPx = topPx.clamp(0.0, imageHeightPx);
    final clampedBottomPx = (topPx + heightPx).clamp(0.0, imageHeightPx);

    final visibleWidthPx = clampedRightPx - clampedLeftPx;
    final visibleHeightPx = clampedBottomPx - clampedTopPx;
    if (visibleWidthPx <= 0 || visibleHeightPx <= 0) {
      return null;
    }

    final normalizedLeft = _roundTo4Decimals(clampedLeftPx / imageWidthPx);
    final normalizedTop = _roundTo4Decimals(clampedTopPx / imageHeightPx);
    final normalizedWidth = _roundTo4Decimals(
      math.min(visibleWidthPx / imageWidthPx, 1.0 - normalizedLeft),
    );
    final normalizedHeight = _roundTo4Decimals(
      math.min(visibleHeightPx / imageHeightPx, 1.0 - normalizedTop),
    );

    if (normalizedWidth <= 0.0 || normalizedHeight <= 0.0) {
      return null;
    }

    return List<double>.unmodifiable(<double>[
      normalizedLeft,
      normalizedTop,
      normalizedWidth,
      normalizedHeight,
    ]);
  }

  static double _roundTo4Decimals(double value) {
    final clamped = value.clamp(0.0, 1.0);
    final rounded = double.parse(clamped.toStringAsFixed(4));
    return rounded == 0.0 ? 0.0 : rounded;
  }
}
