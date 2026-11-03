import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../intro/utils/chinese_calendar_helper.dart';
import '../../../templates/models/template_style.dart';
import 'folio_leaf_model.dart';

/// Content blocks extracted from Quill Delta or plain text.
sealed class FolioContentBlock {}

class FolioTextBlock extends FolioContentBlock {
  final List<FolioHorizontalSegment> segments;
  FolioTextBlock({required this.segments});
}

class FolioMediaBlock extends FolioContentBlock {
  final String mediaType;
  final String relativePath;
  final String? caption;
  FolioMediaBlock({
    required this.mediaType,
    required this.relativePath,
    this.caption,
  });
}

/// Helper methods for parsing rich Quill Delta and diary metadata.
class FolioContentParser {
  const FolioContentParser._();

  static final RegExp _jiazhuRegex = RegExp(r'\{夹注:(.*?)\}');

  /// Parses Delta JSON or fallback plain text into structured content blocks.
  static List<FolioContentBlock> parseContentBlocks({
    required String contentDeltaJson,
    required String fallbackPlainText,
    required List<MediaAttachment> attachments,
  }) {
    final blocks = <FolioContentBlock>[];

    List<dynamic>? ops;
    if (contentDeltaJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentDeltaJson);
        if (decoded is List) {
          ops = decoded;
        } else if (decoded is Map && decoded['ops'] is List) {
          ops = decoded['ops'] as List;
        }
      } catch (_) {
        ops = null;
      }
    }

    if (ops == null || ops.isEmpty) {
      if (fallbackPlainText.trim().isNotEmpty) {
        final paragraphs = fallbackPlainText.split('\n');
        for (final paragraph in paragraphs) {
          final trimmed = paragraph.trimRight();
          if (trimmed.isEmpty) continue;
          blocks.add(_parsePlainParagraph(trimmed));
        }
      }
      return blocks;
    }

    var currentSegments = <FolioHorizontalSegment>[];

    void flushCurrentParagraph() {
      if (currentSegments.isNotEmpty) {
        blocks.add(FolioTextBlock(segments: List.of(currentSegments)));
        currentSegments = <FolioHorizontalSegment>[];
      }
    }

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = (op['attributes'] as Map?) ?? const {};

      // 1. Image Embed
      if (insert is Map && insert.containsKey('image')) {
        flushCurrentParagraph();
        blocks.add(
          FolioMediaBlock(
            mediaType: 'image',
            relativePath: insert['image'].toString(),
          ),
        );
        continue;
      }

      // 2. Video Embed
      if (insert is Map && insert.containsKey('video')) {
        flushCurrentParagraph();
        blocks.add(
          FolioMediaBlock(
            mediaType: 'video',
            relativePath: insert['video'].toString(),
          ),
        );
        continue;
      }

      // 3. Text Run
      if (insert is String) {
        final isBold = attributes['bold'] == true;
        final isItalic = attributes['italic'] == true;
        final isTodo = attributes['list'] == 'checked' || attributes['list'] == 'unchecked';
        final isChecked = attributes['list'] == 'checked';
        Color? color;
        if (attributes['color'] != null) {
          color = TemplateStyle.parseHexColor(attributes['color'].toString());
        }

        final segments = splitJiazhuSegments(
          rawText: insert,
          isBold: isBold,
          isItalic: isItalic,
          isTodo: isTodo,
          isChecked: isChecked,
          color: color,
        );

        for (final seg in segments) {
          if (seg.text.contains('\n') && !seg.isJiazhuNote) {
            final lines = seg.text.split('\n');
            for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
              final lineText = lines[lineIndex];
              if (lineText.isNotEmpty) {
                currentSegments.add(seg.copyWith(text: lineText));
              }
              if (lineIndex < lines.length - 1) {
                flushCurrentParagraph();
              }
            }
          } else {
            currentSegments.add(seg);
          }
        }
      }
    }

    flushCurrentParagraph();
    return blocks;
  }

  static FolioTextBlock _parsePlainParagraph(String text) {
    final segments = splitJiazhuSegments(rawText: text);
    return FolioTextBlock(segments: segments);
  }

  /// Splits a raw text string into plain text runs and `{夹注:...}` sub-notes.
  static List<FolioHorizontalSegment> splitJiazhuSegments({
    required String rawText,
    bool isBold = false,
    bool isItalic = false,
    bool isTodo = false,
    bool isChecked = false,
    Color? color,
  }) {
    final segments = <FolioHorizontalSegment>[];
    int currentIndex = 0;

    for (final match in _jiazhuRegex.allMatches(rawText)) {
      if (match.start > currentIndex) {
        segments.add(
          FolioHorizontalSegment(
            text: rawText.substring(currentIndex, match.start),
            isBold: isBold,
            isItalic: isItalic,
            isTodo: isTodo,
            isChecked: isChecked,
            color: color,
          ),
        );
      }
      final noteContent = match.group(1) ?? '';
      if (noteContent.isNotEmpty) {
        segments.add(
          FolioHorizontalSegment(
            text: noteContent,
            isJiazhuNote: true,
          ),
        );
      }
      currentIndex = match.end;
    }

    if (currentIndex < rawText.length) {
      segments.add(
        FolioHorizontalSegment(
          text: rawText.substring(currentIndex),
          isBold: isBold,
          isItalic: isItalic,
          isTodo: isTodo,
          isChecked: isChecked,
          color: color,
        ),
      );
    }

    return segments;
  }

  /// Extracts an opening reflection ribbon string from text or {夹注:...}.
  static String? extractOpeningReflection({
    required String plainText,
    String? title,
  }) {
    final match = _jiazhuRegex.firstMatch(plainText);
    if (match != null && match.group(1)?.isNotEmpty == true) {
      return '眉批夹注：${match.group(1)!.trim()}';
    }

    final trimmed = plainText.trim();
    if (trimmed.isEmpty) return null;

    final firstLine = trimmed.split('\n').first.trim();
    if (firstLine.isEmpty) return null;
    if (title != null && firstLine == title.trim()) {
      final lines = trimmed.split('\n');
      if (lines.length > 1 && lines[1].trim().isNotEmpty) {
        return '眉批夹注：${lines[1].trim()}';
      }
    }

    return '眉批夹注：$firstLine';
  }

  /// Formats classical lunar date with Ganzhi cyclical year, e.g. `岁次丙午 · 十月廿三`.
  static String formatFullLunarDate(DateTime date) {
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final stemIndex = (date.year - 4) % 10;
    final branchIndex = (date.year - 4) % 12;
    final ganzhi = '${stems[stemIndex]}${branches[branchIndex]}';
    final monthDay = ChineseCalendarHelper.formatMonthDay(date);
    return '岁次$ganzhi · $monthDay';
  }

  /// Formats Gregorian date with classical Shichen & Ke, e.g. `2026.11.23 · 亥时初刻`.
  static String formatGregorianDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final timeStr = _timeToShichenKe(date);
    return '$year.$month.$day · $timeStr';
  }

  static String _timeToShichenKe(DateTime date) {
    const shichenNames = [
      '子时', '丑时', '寅时', '卯时', '辰时', '巳时',
      '午时', '未时', '申时', '酉时', '戌时', '亥时',
    ];
    final hourIndex = ((date.hour + 1) ~/ 2) % 12;
    final shichen = shichenNames[hourIndex];

    const keNames = ['初刻', '一刻', '二刻', '三刻'];
    final keIndex = (date.minute ~/ 15).clamp(0, 3);
    final ke = keNames[keIndex];

    return '$shichen$ke';
  }

  /// Pads seal inscription to exactly 4 characters with '印' if shorter.
  static String normalizeSealText(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), '');
    final runes = clean.runes.map((rune) => String.fromCharCode(rune)).toList();
    if (runes.isEmpty) return '心迹安放';
    while (runes.length < 4) {
      runes.add('印');
    }
    return runes.take(4).join('');
  }
}

extension FolioHorizontalSegmentCopy on FolioHorizontalSegment {
  FolioHorizontalSegment copyWith({
    String? text,
    bool? isJiazhuNote,
    bool? isTodo,
    bool? isChecked,
    bool? isBold,
    bool? isItalic,
    Color? color,
  }) {
    return FolioHorizontalSegment(
      text: text ?? this.text,
      isJiazhuNote: isJiazhuNote ?? this.isJiazhuNote,
      isTodo: isTodo ?? this.isTodo,
      isChecked: isChecked ?? this.isChecked,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      color: color ?? this.color,
    );
  }
}
