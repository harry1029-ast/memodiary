import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:uuid/uuid.dart';
import '../models/import_candidate_entry.dart';

/// Pure Dart date parser and document splitter engine.
/// Runs inside background Isolate workers with zero platform channel dependencies.
class DateParserEngine {
  static const Uuid _uuid = Uuid();

  /// English month lookup map
  static const Map<String, int> _englishMonths = {
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  /// Chinese weekdays mapping to DateTime weekday integers (1=Mon, 7=Sun)
  static const Map<String, int> _chineseWeekdays = {
    '一': DateTime.monday,
    '二': DateTime.tuesday,
    '三': DateTime.wednesday,
    '四': DateTime.thursday,
    '五': DateTime.friday,
    '六': DateTime.saturday,
    '日': DateTime.sunday,
    '天': DateTime.sunday,
  };

  /// Weather keyword & emoji detection
  static String? detectWeather(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('sunny') || line.contains('晴') || line.contains('☀️') || line.contains('🌞')) {
      return 'sunny';
    }
    if (lower.contains('cloudy') || line.contains('多云') || line.contains('阴') || line.contains('⛅') || line.contains('☁️')) {
      return 'cloudy';
    }
    if (lower.contains('rainy') || line.contains('雨') || line.contains('🌧️') || line.contains('☔')) {
      return 'rainy';
    }
    if (lower.contains('windy') || line.contains('风') || line.contains('大风') || line.contains('💨')) {
      return 'windy';
    }
    if (lower.contains('snowy') || line.contains('雪') || line.contains('❄️') || line.contains('🌨️')) {
      return 'snowy';
    }
    return null;
  }

  /// Mood emoji & keyword detection (1 to 5)
  static int? detectMood(String line) {
    final lower = line.toLowerCase();
    if (line.contains('😄') || line.contains('😆') || line.contains('😁') || lower.contains('great') || line.contains('极好') || line.contains('太棒')) {
      return 5;
    }
    if (line.contains('🙂') || line.contains('😊') || line.contains('😀') || lower.contains('happy') || line.contains('开心') || line.contains('愉快')) {
      return 4;
    }
    if (line.contains('😐') || line.contains('😶') || lower.contains('calm') || line.contains('平静') || line.contains('一般')) {
      return 3;
    }
    if (line.contains('🙁') || line.contains('😕') || lower.contains('tired') || line.contains('累') || line.contains('疲惫')) {
      return 2;
    }
    if (line.contains('😢') || line.contains('😭') || line.contains('😞') || lower.contains('down') || line.contains('难过') || line.contains('伤心')) {
      return 1;
    }
    return null;
  }

  /// Asynchronously parses a document inside a background Isolate worker
  /// to maintain 60 FPS on the UI thread.
  static Future<List<ImportCandidateEntry>> parseDocumentInIsolate({
    required String text,
    DateTime? referenceDate,
    int? defaultYear,
  }) async {
    final ref = referenceDate ?? DateTime.now();
    final year = defaultYear ?? ref.year;

    // In Flutter test harness, background isolates freeze test fake async zones.
    // Run direct synchronous pure Dart parser.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return parseDocument(
        text: text,
        referenceDate: ref,
        defaultYear: year,
      );
    }

    try {
      return await Isolate.run(
        () => parseDocument(
          text: text,
          referenceDate: ref,
          defaultYear: year,
        ),
      );
    } catch (_) {
      return parseDocument(
        text: text,
        referenceDate: ref,
        defaultYear: year,
      );
    }
  }

  /// Pure Dart document parser and entry splitter.
  /// Scans line-by-line for contextual date header anchors and splits multi-entry documents.
  static List<ImportCandidateEntry> parseDocument({
    required String text,
    DateTime? referenceDate,
    int? defaultYear,
  }) {
    final refDate = referenceDate ?? DateTime.now();
    final dYear = defaultYear ?? refDate.year;

    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty || text.trim().isEmpty) {
      return [];
    }

    final candidates = <ImportCandidateEntry>[];

    DateTime? currentDate;
    DateParseConfidence currentConfidence = DateParseConfidence.none;
    String currentTitle = '';
    final currentBodyLines = <String>[];
    int? currentMood;
    String? currentWeather;
    bool hasFoundAnchor = false;

    void commitCurrentEntry() {
      final bodyText = currentBodyLines.join('\n').trim();
      if (bodyText.isEmpty && currentTitle.isEmpty && currentDate == null) {
        return;
      }

      String effectiveTitle = currentTitle.trim();
      String effectiveBody = bodyText;

      // If title is empty, use first non-empty body line as title
      if (effectiveTitle.isEmpty && currentBodyLines.isNotEmpty) {
        for (int i = 0; i < currentBodyLines.length; i++) {
          final l = currentBodyLines[i].trim();
          if (l.isNotEmpty) {
            effectiveTitle = l.replaceFirst(RegExp(r'^#+\s*'), '');
            effectiveBody = currentBodyLines.sublist(i + 1).join('\n').trim();
            break;
          }
        }
      }

      // Delta JSON guarantee: must strictly terminate with '\n'
      final deltaJson = jsonEncode([
        {'insert': '$effectiveBody\n'}
      ]);

      candidates.add(
        ImportCandidateEntry(
          id: _uuid.v4(),
          parsedDate: currentDate ?? refDate,
          title: effectiveTitle,
          plainText: effectiveBody,
          contentDelta: deltaJson,
          confidence: currentConfidence,
          mood: currentMood,
          weather: currentWeather,
          isSelected: true,
        ),
      );

      // Reset
      currentDate = null;
      currentConfidence = DateParseConfidence.none;
      currentTitle = '';
      currentBodyLines.clear();
      currentMood = null;
      currentWeather = null;
    }

    for (final rawLine in lines) {
      final trimmedLine = rawLine.trim();

      // Check if line qualifies as a contextual date header anchor
      final anchorResult = tryParseDateAnchor(
        line: trimmedLine,
        referenceDate: refDate,
        defaultYear: dYear,
      );

      if (anchorResult != null) {
        // We found a new entry boundary! Commit previous entry if any.
        if (hasFoundAnchor || currentBodyLines.isNotEmpty || currentTitle.isNotEmpty) {
          commitCurrentEntry();
        }

        hasFoundAnchor = true;
        currentDate = anchorResult.date;
        currentConfidence = anchorResult.confidence;
        currentTitle = anchorResult.remainingTitle ?? '';
        currentMood = anchorResult.mood;
        currentWeather = anchorResult.weather;
      } else {
        // Ordinary content line
        currentBodyLines.add(rawLine);
      }
    }

    // If no anchors were detected across the entire document, wrap whole file as single entry
    if (!hasFoundAnchor) {
      if (text.trim().isNotEmpty) {
        final nonBlank = lines.firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => 'Imported Entry',
        );
        candidates.add(
          ImportCandidateEntry(
            id: _uuid.v4(),
            parsedDate: refDate,
            title: nonBlank.replaceFirst(RegExp(r'^#+\s*'), '').trim(),
            plainText: text.trim(),
            contentDelta: jsonEncode([
              {'insert': '${text.trim()}\n'}
            ]),
            confidence: DateParseConfidence.none,
            isSelected: true,
          ),
        );
      }
      return candidates;
    }

    // Commit final pending entry
    commitCurrentEntry();

    return candidates;
  }

  /// Attempts to parse a line as a contextual date header anchor.
  /// Enforces line-start anchors to prevent false positives in the middle of sentences.
  static DateAnchorResult? tryParseDateAnchor({
    required String line,
    required DateTime referenceDate,
    required int defaultYear,
  }) {
    if (line.isEmpty) return null;

    // Strip markdown headers (#, ##), bullets (-, *), bold markers (**)
    String stripped = line
        .replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '')
        .replaceFirst(RegExp(r'^\s*[-*]\s+'), '')
        .trim();

    // Strip optional "Date:", "日期:", "时间:" prefix
    stripped = stripped.replaceFirst(RegExp(r'^(?:date|日期|时间)[:：]\s*', caseSensitive: false), '').trim();

    final weather = detectWeather(line);
    final mood = detectMood(line);

    // 1. ISO 8601 & Numeric: YYYY-MM-DD or YYYY/MM/DD or YYYY.MM.DD
    final isoMatch = RegExp(
      r'^(20\d\d|19\d\d)[-/.](0?[1-9]|1[0-2])[-/.](0?[1-9]|[12]\d|3[01])(?:\s+([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?)?(?:\s+(.*))?$',
    ).firstMatch(stripped);

    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      final hh = isoMatch.group(4) != null ? int.parse(isoMatch.group(4)!) : 12;
      final mm = isoMatch.group(5) != null ? int.parse(isoMatch.group(5)!) : 0;
      final ss = isoMatch.group(6) != null ? int.parse(isoMatch.group(6)!) : 0;

      final parsed = _safeDateTime(y, m, d, hh, mm, ss);
      if (parsed != null) {
        return DateAnchorResult(
          date: parsed,
          confidence: DateParseConfidence.high,
          remainingTitle: _cleanRemainingTitle(isoMatch.group(7)),
          mood: mood,
          weather: weather,
        );
      }
    }

    // 2. Chinese Full Date: YYYY年MM月DD日
    final cnFullMatch = RegExp(
      r'^(20\d\d|19\d\d)\s*年\s*(0?[1-9]|1[0-2])\s*月\s*(0?[1-9]|[12]\d|3[01])\s*[日号]?(?:\s*(?:星期|周)[一二三四五六日天])?(?:\s+([01]?\d|2[0-3])(?::|点)([0-5]\d))?(?:\s+(.*))?$',
    ).firstMatch(stripped);

    if (cnFullMatch != null) {
      final y = int.parse(cnFullMatch.group(1)!);
      final m = int.parse(cnFullMatch.group(2)!);
      final d = int.parse(cnFullMatch.group(3)!);
      final hh = cnFullMatch.group(4) != null ? int.parse(cnFullMatch.group(4)!) : 12;
      final mm = cnFullMatch.group(5) != null ? int.parse(cnFullMatch.group(5)!) : 0;

      final parsed = _safeDateTime(y, m, d, hh, mm, 0);
      if (parsed != null) {
        return DateAnchorResult(
          date: parsed,
          confidence: DateParseConfidence.high,
          remainingTitle: _cleanRemainingTitle(cnFullMatch.group(6)),
          mood: mood,
          weather: weather,
        );
      }
    }

    // 3. Chinese Month/Day: MM月DD日 (Inferred Year)
    final cnMonthDayMatch = RegExp(
      r'^(0?[1-9]|1[0-2])\s*月\s*(0?[1-9]|[12]\d|3[01])\s*[日号]?(?:\s*(?:星期|周)[一二三四五六日天])?(?:\s+([01]?\d|2[0-3])(?::|点)([0-5]\d))?(?:\s+(.*))?$',
    ).firstMatch(stripped);

    if (cnMonthDayMatch != null) {
      final m = int.parse(cnMonthDayMatch.group(1)!);
      final d = int.parse(cnMonthDayMatch.group(2)!);
      final hh = cnMonthDayMatch.group(3) != null ? int.parse(cnMonthDayMatch.group(3)!) : 12;
      final mm = cnMonthDayMatch.group(4) != null ? int.parse(cnMonthDayMatch.group(4)!) : 0;

      final parsed = _safeDateTime(defaultYear, m, d, hh, mm, 0);
      if (parsed != null) {
        return DateAnchorResult(
          date: parsed,
          confidence: DateParseConfidence.medium,
          remainingTitle: _cleanRemainingTitle(cnMonthDayMatch.group(5)),
          mood: mood,
          weather: weather,
        );
      }
    }

    // 4. Western Formats: "October 16, 2026", "16 Oct 2026", "Oct 16 2026"
    final westMonthNameMatch = RegExp(
      r'^(?:([a-zA-Z]+)\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(20\d\d|19\d\d)|(\d{1,2})(?:st|nd|rd|th)?\s+([a-zA-Z]+),?\s+(20\d\d|19\d\d))(?:\s+(.*))?$',
    ).firstMatch(stripped);

    if (westMonthNameMatch != null) {
      String mStr;
      int d;
      int y;
      if (westMonthNameMatch.group(1) != null) {
        mStr = westMonthNameMatch.group(1)!.toLowerCase();
        d = int.parse(westMonthNameMatch.group(2)!);
        y = int.parse(westMonthNameMatch.group(3)!);
      } else {
        d = int.parse(westMonthNameMatch.group(4)!);
        mStr = westMonthNameMatch.group(5)!.toLowerCase();
        y = int.parse(westMonthNameMatch.group(6)!);
      }

      final monthInt = _englishMonths[mStr];
      if (monthInt != null) {
        final parsed = _safeDateTime(y, monthInt, d, 12, 0, 0);
        if (parsed != null) {
          final titleRemainder = westMonthNameMatch.group(7);
          return DateAnchorResult(
            date: parsed,
            confidence: DateParseConfidence.high,
            remainingTitle: _cleanRemainingTitle(titleRemainder),
            mood: mood,
            weather: weather,
          );
        }
      }
    }

    // 5. Western Numeric: MM/DD/YYYY or DD/MM/YYYY
    final westNumericMatch = RegExp(
      r'^(0?[1-9]|1[0-2])/(0?[1-9]|[12]\d|3[01])/(20\d\d|19\d\d)(?:\s+(.*))?$',
    ).firstMatch(stripped);

    if (westNumericMatch != null) {
      final m = int.parse(westNumericMatch.group(1)!);
      final d = int.parse(westNumericMatch.group(2)!);
      final y = int.parse(westNumericMatch.group(3)!);

      final parsed = _safeDateTime(y, m, d, 12, 0, 0);
      if (parsed != null) {
        return DateAnchorResult(
          date: parsed,
          confidence: DateParseConfidence.high,
          remainingTitle: _cleanRemainingTitle(westNumericMatch.group(4)),
          mood: mood,
          weather: weather,
        );
      }
    }

    // 6. Relative Date Markers: "今天", "昨天", "前天", "大前天", "上周六", etc.
    final relResult = _tryParseRelativeMarker(stripped, referenceDate);
    if (relResult != null) {
      return DateAnchorResult(
        date: relResult.date,
        confidence: DateParseConfidence.medium,
        remainingTitle: _cleanRemainingTitle(relResult.remainingTitle),
        mood: mood,
        weather: weather,
      );
    }

    return null;
  }

  /// Cleans remainingTitle by stripping detected weather keywords and mood/weather emojis
  static String? _cleanRemainingTitle(String? rawTitle) {
    if (rawTitle == null || rawTitle.trim().isEmpty) return null;
    String clean = rawTitle.trim();

    // Strip weather emojis and mood emojis
    for (final emoji in [
      '☀️', '🌞', '⛅', '☁️', '🌧️', '☔', '💨', '❄️', '🌨️',
      '😄', '😆', '😁', '🙂', '😊', '😀', '😐', '😶', '🙁', '😕', '😢', '😭', '😞',
    ]) {
      clean = clean.replaceAll(emoji, ' ');
    }

    // Strip weather keywords at start
    clean = clean.replaceFirst(
      RegExp(r'^(?:晴天?|多云|阴天?|大雨|小雨|雨天?|大雪|小雪|雪天?|大风|风|sunny|cloudy|rainy|windy|snowy)\s*', caseSensitive: false),
      '',
    );

    // Strip weather keywords at end
    clean = clean.replaceFirst(
      RegExp(r'\s*(?:晴天?|多云|阴天?|大雨|小雨|雨天?|大雪|小雪|雪天?|大风|风|sunny|cloudy|rainy|windy|snowy)$', caseSensitive: false),
      '',
    );

    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.isEmpty ? null : clean;
  }

  static _RelResult? _tryParseRelativeMarker(String line, DateTime ref) {
    final lower = line.toLowerCase();

    if (line.startsWith('今天') || lower.startsWith('today')) {
      final remainder = line.replaceFirst(RegExp(r'^(?:今天|today)\s*', caseSensitive: false), '');
      return _RelResult(DateTime(ref.year, ref.month, ref.day, 12, 0), remainder.trim());
    }

    if (line.startsWith('昨天') || lower.startsWith('yesterday')) {
      final target = ref.subtract(const Duration(days: 1));
      final remainder = line.replaceFirst(RegExp(r'^(?:昨天|yesterday)\s*', caseSensitive: false), '');
      return _RelResult(DateTime(target.year, target.month, target.day, 12, 0), remainder.trim());
    }

    if (line.startsWith('前天')) {
      final target = ref.subtract(const Duration(days: 2));
      final remainder = line.replaceFirst(RegExp(r'^前天\s*'), '');
      return _RelResult(DateTime(target.year, target.month, target.day, 12, 0), remainder.trim());
    }

    if (line.startsWith('大前天')) {
      final target = ref.subtract(const Duration(days: 3));
      final remainder = line.replaceFirst(RegExp(r'^大前天\s*'), '');
      return _RelResult(DateTime(target.year, target.month, target.day, 12, 0), remainder.trim());
    }

    // "上周X" (e.g. 上周一, 上周六)
    final lastWeekMatch = RegExp(r'^上周([一二三四五六日天])(?:\s+(.*))?$').firstMatch(line);
    if (lastWeekMatch != null) {
      final targetDay = _chineseWeekdays[lastWeekMatch.group(1)!]!;
      // Calculate days back to that day of previous week
      final currentWeekday = ref.weekday;
      final daysAgo = currentWeekday + (7 - targetDay);
      final target = ref.subtract(Duration(days: daysAgo));
      return _RelResult(
        DateTime(target.year, target.month, target.day, 12, 0),
        lastWeekMatch.group(2)?.trim(),
      );
    }

    return null;
  }

  static DateTime? _safeDateTime(int y, int m, int d, int hh, int mm, int ss) {
    try {
      final dt = DateTime(y, m, d, hh, mm, ss);
      // Guard against month/day overflow (e.g. Feb 31 becoming Mar 3)
      if (dt.year == y && dt.month == m && dt.day == d) {
        return dt;
      }
    } catch (_) {}
    return null;
  }
}

class DateAnchorResult {
  final DateTime date;
  final DateParseConfidence confidence;
  final String? remainingTitle;
  final int? mood;
  final String? weather;

  const DateAnchorResult({
    required this.date,
    required this.confidence,
    this.remainingTitle,
    this.mood,
    this.weather,
  });
}

class _RelResult {
  final DateTime date;
  final String? remainingTitle;

  const _RelResult(this.date, this.remainingTitle);
}

