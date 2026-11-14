import 'package:flutter/foundation.dart';
import 'delta_ops_decoder.dart';
import 'media_embed_data.dart';
import 'vertical_typography_mapper.dart';

/// Block-level semantic kind bound to a decoded [EntryTextBlock].
enum EntryBlockKind {
  paragraph,
  header1,
  header2,
  header3,
  blockquote,
  bulletList,
  orderedList,
  checkedList,
  uncheckedList,
}

/// An inline span within an [EntryTextBlock], preserving formatting attributes
/// or marking an `{夹注:...}` Interlinear Sub-Note span.
class EntryInlineRun {
  final String text;
  final bool isInterlinearNote;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrike;
  final String? colorHex;

  const EntryInlineRun({
    required this.text,
    this.isInterlinearNote = false,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrike = false,
    this.colorHex,
  });

  EntryInlineRun copyWith({
    String? text,
    bool? isInterlinearNote,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrike,
    String? colorHex,
  }) {
    return EntryInlineRun(
      text: text ?? this.text,
      isInterlinearNote: isInterlinearNote ?? this.isInterlinearNote,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrike: isStrike ?? this.isStrike,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryInlineRun &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          isInterlinearNote == other.isInterlinearNote &&
          isBold == other.isBold &&
          isItalic == other.isItalic &&
          isUnderline == other.isUnderline &&
          isStrike == other.isStrike &&
          colorHex == other.colorHex;

  @override
  int get hashCode => Object.hash(
        text,
        isInterlinearNote,
        isBold,
        isItalic,
        isUnderline,
        isStrike,
        colorHex,
      );

  @override
  String toString() =>
      'EntryInlineRun(text: $text, note: $isInterlinearNote, bold: $isBold, '
      'italic: $isItalic, underline: $isUnderline, strike: $isStrike, color: $colorHex)';
}

/// Base class for canonical decoded diary entry content blocks.
sealed class EntryContentBlock {
  const EntryContentBlock();
}

/// A line/paragraph block with semantic [kind], optional 1-based [orderedIndex],
/// and inline [runs] (empty [runs] represents an intentional blank line).
class EntryTextBlock extends EntryContentBlock {
  final EntryBlockKind kind;
  final int? orderedIndex;
  final List<EntryInlineRun> runs;

  const EntryTextBlock({
    this.kind = EntryBlockKind.paragraph,
    this.orderedIndex,
    required this.runs,
  });

  /// True when this block contains no non-whitespace text across all runs.
  bool get isBlank => runs.every((run) => run.text.trim().isEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTextBlock &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          orderedIndex == other.orderedIndex &&
          listEquals(runs, other.runs);

  @override
  int get hashCode => Object.hash(kind, orderedIndex, Object.hashAll(runs));

  @override
  String toString() =>
      'EntryTextBlock(kind: $kind, orderedIndex: $orderedIndex, runs: $runs)';
}

/// A normalized inline image or video block decoded from a Quill Delta embed.
class EntryMediaBlock extends EntryContentBlock {
  final bool isVideo;
  final MediaEmbedData media;

  const EntryMediaBlock({
    required this.isVideo,
    required this.media,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryMediaBlock &&
          runtimeType == other.runtimeType &&
          isVideo == other.isVideo &&
          media == other.media;

  @override
  int get hashCode => Object.hash(isVideo, media);

  @override
  String toString() => 'EntryMediaBlock(isVideo: $isVideo, media: $media)';
}

/// Canonical pure-Dart decoder converting Quill Delta JSON (or plain text
/// fallback) into structured [EntryContentBlock] items.
class EntryContentDecoder {
  const EntryContentDecoder._();

  /// Decodes a persisted Quill Delta JSON string (bare op-list or `{"ops": [...]}`)
  /// into canonical [EntryContentBlock]s, falling back to [fallbackPlainText].
  static List<EntryContentBlock> decode({
    required String contentDeltaJson,
    String fallbackPlainText = '',
  }) {
    return decodeOps(
      ops: decodeDeltaOps(contentDeltaJson),
      fallbackPlainText: fallbackPlainText,
    );
  }

  /// Decodes pre-parsed Quill Delta [ops] into canonical [EntryContentBlock]s,
  /// falling back to [fallbackPlainText] when [ops] is null or empty.
  static List<EntryContentBlock> decodeOps({
    required List<dynamic>? ops,
    String fallbackPlainText = '',
  }) {
    if (ops == null || ops.isEmpty) {
      return _decodeFallbackPlainText(fallbackPlainText);
    }

    final blocks = <EntryContentBlock>[];
    final currentRuns = <EntryInlineRun>[];
    int orderedListCounter = 1;

    void flushTextBlock(EntryBlockKind kind) {
      int? orderedIndex;
      if (kind == EntryBlockKind.orderedList) {
        orderedIndex = orderedListCounter++;
      } else {
        orderedListCounter = 1;
      }
      blocks.add(
        EntryTextBlock(
          kind: kind,
          orderedIndex: orderedIndex,
          runs: List<EntryInlineRun>.unmodifiable(currentRuns),
        ),
      );
      currentRuns.clear();
    }

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = (op['attributes'] as Map?) ?? const {};

      if (insert is Map) {
        if (insert.containsKey('image')) {
          if (currentRuns.isNotEmpty) {
            flushTextBlock(EntryBlockKind.paragraph);
          } else {
            orderedListCounter = 1;
          }
          blocks.add(
            EntryMediaBlock(
              isVideo: false,
              media: MediaEmbedData.fromRaw(insert['image']),
            ),
          );
        } else if (insert.containsKey('video')) {
          if (currentRuns.isNotEmpty) {
            flushTextBlock(EntryBlockKind.paragraph);
          } else {
            orderedListCounter = 1;
          }
          blocks.add(
            EntryMediaBlock(
              isVideo: true,
              media: MediaEmbedData.fromRaw(insert['video']),
            ),
          );
        }
        // Ignore {"mount": ...} and other non-media control embeds (e.g., divider).
        continue;
      }

      if (insert is String) {
        final isBold = attributes['bold'] == true;
        final isItalic = attributes['italic'] == true;
        final isUnderline = attributes['underline'] == true;
        final isStrike = attributes['strike'] == true;
        final colorHex = _parseColorHex(attributes['color']);
        final blockKind = _resolveBlockKind(attributes);

        final segments = insert.split('\n');
        for (int index = 0; index < segments.length; index++) {
          final segment = segments[index];
          if (segment.isNotEmpty) {
            currentRuns.addAll(
              _splitInterlinearRuns(
                text: segment,
                isBold: isBold,
                isItalic: isItalic,
                isUnderline: isUnderline,
                isStrike: isStrike,
                colorHex: colorHex,
              ),
            );
          }
          if (index < segments.length - 1) {
            flushTextBlock(blockKind);
          }
        }
      }
    }

    if (currentRuns.isNotEmpty) {
      flushTextBlock(EntryBlockKind.paragraph);
    }

    return blocks;
  }

  static String? _parseColorHex(dynamic rawColor) {
    final colorString = rawColor?.toString().trim();
    if (colorString == null || colorString.isEmpty) return null;
    return colorString;
  }

  static EntryBlockKind _resolveBlockKind(Map<dynamic, dynamic> attributes) {
    final headerLevel = attributes['header'];
    if (headerLevel is num) {
      switch (headerLevel.toInt()) {
        case 1:
          return EntryBlockKind.header1;
        case 2:
          return EntryBlockKind.header2;
        case 3:
          return EntryBlockKind.header3;
      }
    }
    if (attributes['blockquote'] == true) {
      return EntryBlockKind.blockquote;
    }
    switch (attributes['list']) {
      case 'bullet':
        return EntryBlockKind.bulletList;
      case 'ordered':
        return EntryBlockKind.orderedList;
      case 'checked':
        return EntryBlockKind.checkedList;
      case 'unchecked':
        return EntryBlockKind.uncheckedList;
      default:
        return EntryBlockKind.paragraph;
    }
  }

  static List<EntryContentBlock> _decodeFallbackPlainText(String plainText) {
    if (plainText.trim().isEmpty) return const [];
    final blocks = <EntryContentBlock>[];
    for (final rawLine in plainText.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        blocks.add(const EntryTextBlock(runs: []));
      } else {
        blocks.add(
          EntryTextBlock(
            runs: List<EntryInlineRun>.unmodifiable(
              _splitInterlinearRuns(text: line),
            ),
          ),
        );
      }
    }
    return blocks;
  }

  static List<EntryInlineRun> _splitInterlinearRuns({
    required String text,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isStrike = false,
    String? colorHex,
  }) {
    final runs = <EntryInlineRun>[];
    int currentIndex = 0;

    for (final match in VerticalTypographyMapper.interlinearRegex.allMatches(text)) {
      if (match.start > currentIndex) {
        runs.add(
          EntryInlineRun(
            text: text.substring(currentIndex, match.start),
            isBold: isBold,
            isItalic: isItalic,
            isUnderline: isUnderline,
            isStrike: isStrike,
            colorHex: colorHex,
          ),
        );
      }
      final noteContent = match.group(1) ?? '';
      if (noteContent.isNotEmpty) {
        runs.add(
          EntryInlineRun(
            text: noteContent,
            isInterlinearNote: true,
          ),
        );
      }
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      runs.add(
        EntryInlineRun(
          text: text.substring(currentIndex),
          isBold: isBold,
          isItalic: isItalic,
          isUnderline: isUnderline,
          isStrike: isStrike,
          colorHex: colorHex,
        ),
      );
    }

    return runs;
  }
}
