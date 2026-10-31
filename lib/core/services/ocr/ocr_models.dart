import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a single recognized line of text and its normalized bounding box.
///
/// [box] contains `[left, top, width, height]` scaled to `0.0 .. 1.0` relative
/// to image dimensions, rounded to 4 decimal places.
@immutable
class OcrLineBlock {
  final String text;
  final List<double> box;

  const OcrLineBlock({
    required this.text,
    required this.box,
  });

  double get left => box[0];
  double get top => box[1];
  double get width => box[2];
  double get height => box[3];

  Map<String, Object> toJson() {
    return <String, Object>{
      'text': text,
      'box': box,
    };
  }

  static OcrLineBlock? tryFromJson(Object? rawJson) {
    if (rawJson is! Map<Object?, Object?>) {
      return null;
    }
    final rawText = rawJson['text'];
    final rawBox = rawJson['box'];
    if (rawText is! String || rawBox is! List<Object?> || rawBox.length != 4) {
      return null;
    }

    final parsedCoords = <double>[];
    for (final rawCoord in rawBox) {
      if (rawCoord is! num || !rawCoord.isFinite) {
        return null;
      }
      parsedCoords.add(rawCoord.toDouble());
    }

    return OcrLineBlock(
      text: rawText,
      box: List<double>.unmodifiable(parsedCoords),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OcrLineBlock &&
        other.text == text &&
        listEquals(other.box, box);
  }

  @override
  int get hashCode => Object.hash(text, Object.hashAll(box));

  @override
  String toString() => 'OcrLineBlock(text: "$text", box: $box)';
}

/// Immutable result of an on-device OCR extraction pass.
///
/// [OcrResult.empty] serves as the **OCR Sentinel** (`plainText == ''` and
/// `toBlocksJson() == '[]'`) persisted when an image contains zero recognizable
/// text or cannot be decoded.
@immutable
class OcrResult {
  final String plainText;
  final List<OcrLineBlock> lines;

  const OcrResult({
    required this.plainText,
    required this.lines,
  });

  /// Sentinel representing an already-scanned image with zero recognizable text.
  static const OcrResult empty = OcrResult(
    plainText: '',
    lines: <OcrLineBlock>[],
  );

  bool get isEmpty => plainText.isEmpty && lines.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Encodes [lines] into a compact JSON string suitable for `ocr_blocks_json`.
  String toBlocksJson() {
    if (lines.isEmpty) {
      return '[]';
    }
    final serialized = lines.map((block) => block.toJson()).toList(growable: false);
    return jsonEncode(serialized);
  }

  /// Parses `ocr_blocks_json` back into normalized [OcrLineBlock] instances.
  ///
  /// Gracefully returns an empty list on `null`, blank, or malformed JSON.
  static List<OcrLineBlock> parseBlocksJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return const <OcrLineBlock>[];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException {
      return const <OcrLineBlock>[];
    }

    if (decoded is! List<Object?>) {
      return const <OcrLineBlock>[];
    }

    final parsedBlocks = <OcrLineBlock>[];
    for (final rawItem in decoded) {
      final block = OcrLineBlock.tryFromJson(rawItem);
      if (block != null) {
        parsedBlocks.add(block);
      }
    }
    return List<OcrLineBlock>.unmodifiable(parsedBlocks);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OcrResult &&
        other.plainText == plainText &&
        listEquals(other.lines, lines);
  }

  @override
  int get hashCode => Object.hash(plainText, Object.hashAll(lines));

  @override
  String toString() => 'OcrResult(plainText: "$plainText", lines: ${lines.length})';
}
