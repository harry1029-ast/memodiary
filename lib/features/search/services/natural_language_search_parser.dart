import 'package:intl/intl.dart';
import '../models/search_filters.dart';

/// Categories of constraints that can be extracted from a natural language query.
enum ConstraintKind {
  dateRange,
  weeklyReview,
  hasImage,
  weather,
}

/// A single semantic constraint detected by [NaturalLanguageSearchParser].
class DetectedConstraint {
  final ConstraintKind kind;
  final String matchedText;
  final String label;

  const DetectedConstraint({
    required this.kind,
    required this.matchedText,
    required this.label,
  });
}

/// Result of parsing a natural language search query.
class ParsedSearchQuery {
  final String originalQuery;
  final String keywords;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? weather;
  final bool weeklyReviewOnly;
  final bool hasImage;
  final List<DetectedConstraint> detected;

  const ParsedSearchQuery({
    required this.originalQuery,
    required this.keywords,
    this.startDate,
    this.endDate,
    this.weather,
    this.weeklyReviewOnly = false,
    this.hasImage = false,
    this.detected = const [],
  });

  bool get hasDetectedConstraints => detected.isNotEmpty;

  /// Applies the detected natural language constraints onto [base] filters,
  /// overriding matching filter dimensions.
  SearchFilters applyTo(SearchFilters base) {
    return base.copyWith(
      dateType: startDate != null && endDate != null
          ? DateFilterType.custom
          : base.dateType,
      customStart: startDate ?? base.customStart,
      customEnd: endDate ?? base.customEnd,
      weather: weather ?? base.weather,
      hasImage: hasImage ? true : base.hasImage,
      weeklyReviewOnly: weeklyReviewOnly ? true : base.weeklyReviewOnly,
    );
  }
}

/// Pure-Dart, 100% offline parser that extracts temporal, holiday, category, media,
/// and weather constraints from Chinese and English search queries.
class NaturalLanguageSearchParser {
  const NaturalLanguageSearchParser();

  static const Map<String, int> _chineseMonths = {
    '一': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
    '十': 10,
    '十一': 11,
    '十二': 12,
  };

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

  /// Parses [query] relative to [now] (defaults to `DateTime.now()`).
  /// Any [ConstraintKind] present in [ignoredKinds] will not be extracted,
  /// allowing users to dismiss "Understood as" chips and fall back to literal text search.
  ParsedSearchQuery parse(
    String query, {
    DateTime? now,
    Set<ConstraintKind> ignoredKinds = const {},
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return ParsedSearchQuery(originalQuery: query, keywords: '');
    }

    final ref = now ?? DateTime.now();
    String working = trimmed;
    final detected = <DetectedConstraint>[];

    DateTime? startDate;
    DateTime? endDate;
    bool weeklyReviewOnly = false;
    bool hasImage = false;
    String? weather;

    // 1. Temporal & Holiday Extraction
    if (!ignoredKinds.contains(ConstraintKind.dateRange)) {
      final temporalMatch = _extractTemporal(working, ref);
      if (temporalMatch != null) {
        startDate = temporalMatch.start;
        endDate = temporalMatch.end;
        working = temporalMatch.remaining;
        detected.add(
          DetectedConstraint(
            kind: ConstraintKind.dateRange,
            matchedText: temporalMatch.matchedText,
            label: _formatDateRangeLabel(startDate, endDate),
          ),
        );
      }
    }

    // 2. Category: Weekly Review
    if (!ignoredKinds.contains(ConstraintKind.weeklyReview)) {
      final weeklyRegex = RegExp(
        r'(所有周记|全部周记|周记|周报|all\s+weekly\s+reviews?|weekly\s+reviews?)',
        caseSensitive: false,
      );
      final match = weeklyRegex.firstMatch(working);
      if (match != null) {
        weeklyReviewOnly = true;
        final matchedStr = match.group(0)!;
        working = working.replaceFirst(matchedStr, ' ');
        detected.add(
          DetectedConstraint(
            kind: ConstraintKind.weeklyReview,
            matchedText: matchedStr,
            label: 'Weekly Review',
          ),
        );
      }
    }

    // 3. Media: Has Image / Photos
    if (!ignoredKinds.contains(ConstraintKind.hasImage)) {
      final imageRegex = RegExp(
        r'(带图片的?|有图片的?|带照片的?|有照片的?|带图的?|有图的?|with\s+photos?|with\s+pictures?|with\s+images?)',
        caseSensitive: false,
      );
      final match = imageRegex.firstMatch(working);
      if (match != null) {
        hasImage = true;
        final matchedStr = match.group(0)!;
        working = working.replaceFirst(matchedStr, ' ');
        detected.add(
          DetectedConstraint(
            kind: ConstraintKind.hasImage,
            matchedText: matchedStr,
            label: 'With Photos',
          ),
        );
      }
    }

    // 4. Weather Extraction
    if (!ignoredKinds.contains(ConstraintKind.weather)) {
      final weatherMatch = _extractWeather(working);
      if (weatherMatch != null) {
        weather = weatherMatch.weatherValue;
        working = weatherMatch.remaining;
        detected.add(
          DetectedConstraint(
            kind: ConstraintKind.weather,
            matchedText: weatherMatch.matchedText,
            label: 'Weather: $weather',
          ),
        );
      }
    }

    // 5. Strip conversational stop-phrases ONLY if at least one constraint was detected
    if (detected.isNotEmpty) {
      working = _stripStopPhrases(working);
    }

    // Normalize whitespace
    final cleanedKeywords =
        working.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedSearchQuery(
      originalQuery: query,
      keywords: cleanedKeywords,
      startDate: startDate,
      endDate: endDate,
      weather: weather,
      weeklyReviewOnly: weeklyReviewOnly,
      hasImage: hasImage,
      detected: detected,
    );
  }

  static String _formatDateRangeLabel(DateTime start, DateTime end) {
    final fmt = DateFormat('yyyy-MM-dd');
    final s = fmt.format(start);
    final e = fmt.format(end);
    return s == e ? s : '$s – $e';
  }

  static _TemporalExtraction? _extractTemporal(String input, DateTime now) {
    // A. Holidays with optional year prefix (Chinese):
    // e.g. 去年国庆, 今年国庆, 前年国庆, 2025年国庆, 国庆节, 国庆, 元旦, 情人节, 五一, 劳动节, 圣诞节, 圣诞
    final zhHolidayRegex = RegExp(
      r'(?:(去年|今年|前年|(\d{4})\s*年)\s*的?\s*)?(国庆节?|元旦节?|情人节|五一劳动节|劳动节|五一|圣诞节?)',
    );
    final zhHolidayMatch = zhHolidayRegex.firstMatch(input);
    if (zhHolidayMatch != null) {
      final matched = zhHolidayMatch.group(0)!;
      final yearSpec = zhHolidayMatch.group(1);
      final explicitYearStr = zhHolidayMatch.group(2);
      final holidayName = zhHolidayMatch.group(3)!;

      final range = _resolveHolidayRange(
        holidayKey: holidayName,
        yearSpec: yearSpec,
        explicitYear:
            explicitYearStr != null ? int.tryParse(explicitYearStr) : null,
        now: now,
      );
      if (range != null) {
        return _TemporalExtraction(
          start: range.start,
          end: range.end,
          matchedText: matched,
          remaining: input.replaceFirst(matched, ' '),
        );
      }
    }

    // B. Holidays in English:
    // e.g. last year national day, this year christmas, national day 2025, christmas
    final enHolidayRegex = RegExp(
      r"\b(?:(last\s+year|this\s+year)\s+)?(national\s+day|new\s+year'?s?\s*day|new\s+year|valentine'?s?\s*day|valentine|labou?r\s+day|christmas(?:\s+day)?)(?:\s+(\d{4}))?\b",
      caseSensitive: false,
    );
    final enHolidayMatch = enHolidayRegex.firstMatch(input);
    if (enHolidayMatch != null) {
      final matched = enHolidayMatch.group(0)!;
      final relYear = enHolidayMatch.group(1)?.toLowerCase();
      final holidayName = enHolidayMatch.group(2)!.toLowerCase();
      final explicitYearStr = enHolidayMatch.group(3);

      String? yearSpec;
      if (relYear != null) {
        yearSpec = relYear.contains('last') ? '去年' : '今年';
      }

      final range = _resolveHolidayRange(
        holidayKey: holidayName,
        yearSpec: yearSpec,
        explicitYear:
            explicitYearStr != null ? int.tryParse(explicitYearStr) : null,
        now: now,
      );
      if (range != null) {
        return _TemporalExtraction(
          start: range.start,
          end: range.end,
          matchedText: matched,
          remaining: input.replaceFirst(matched, ' '),
        );
      }
    }

    // C. Year + Month (Chinese): e.g. 2025年10月, 去年10月, 今年3月, 前年12月
    final zhYearMonthRegex = RegExp(
      r'(去年|今年|前年|(\d{4})\s*年)\s*的?\s*(1[0-2]|0?[1-9]|十一|十二|十|[一二三四五六七八九])\s*月份?',
    );
    final zhYmMatch = zhYearMonthRegex.firstMatch(input);
    if (zhYmMatch != null) {
      final matched = zhYmMatch.group(0)!;
      final yearSpec = zhYmMatch.group(1)!;
      final explicitYearStr = zhYmMatch.group(2);
      final monthToken = zhYmMatch.group(3)!;

      final year = _resolveYear(yearSpec, explicitYearStr, now.year);
      final month = int.tryParse(monthToken) ?? _chineseMonths[monthToken]!;
      final range = _monthRange(year, month);
      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    // D. ISO Year-Month: e.g. 2025-10
    final isoYmRegex = RegExp(r'\b(\d{4})-(1[0-2]|0[1-9])\b');
    final isoYmMatch = isoYmRegex.firstMatch(input);
    if (isoYmMatch != null) {
      final matched = isoYmMatch.group(0)!;
      final year = int.parse(isoYmMatch.group(1)!);
      final month = int.parse(isoYmMatch.group(2)!);
      final range = _monthRange(year, month);
      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    // E. English Month + Year: e.g. October 2025, in Oct 2025
    final enMonthYearRegex = RegExp(
      r'\b(?:in\s+)?(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sept|sep|october|oct|november|nov|december|dec)\s+(\d{4})\b',
      caseSensitive: false,
    );
    final enMyMatch = enMonthYearRegex.firstMatch(input);
    if (enMyMatch != null) {
      final matched = enMyMatch.group(0)!;
      final monthName = enMyMatch.group(1)!.toLowerCase();
      final year = int.parse(enMyMatch.group(2)!);
      final month = _englishMonths[monthName]!;
      final range = _monthRange(year, month);
      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    // F. Relative Month / Week (Chinese & English)
    final relMonthWeekRegex = RegExp(
      r'(上个月|上月|这个月|本月|上周|上星期|上礼拜|本周|这周|这星期|这礼拜|last\s+month|this\s+month|last\s+week|this\s+week)',
      caseSensitive: false,
    );
    final relMwMatch = relMonthWeekRegex.firstMatch(input);
    if (relMwMatch != null) {
      final matched = relMwMatch.group(0)!;
      final token = matched.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      late ({DateTime start, DateTime end}) range;

      if (token == '上个月' || token == '上月' || token == 'last month') {
        final prevMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        range = _monthRange(prevMonthYear, prevMonth);
      } else if (token == '这个月' || token == '本月' || token == 'this month') {
        range = _monthRange(now.year, now.month);
      } else if (token == '上周' ||
          token == '上星期' ||
          token == '上礼拜' ||
          token == 'last week') {
        final thisMonday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final lastMonday = thisMonday.subtract(const Duration(days: 7));
        final lastSunday = lastMonday.add(
          const Duration(
            days: 6,
            hours: 23,
            minutes: 59,
            seconds: 59,
            milliseconds: 999,
          ),
        );
        range = (start: lastMonday, end: lastSunday);
      } else {
        // this week / 本周 / 这周
        final thisMonday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final thisSunday = thisMonday.add(
          const Duration(
            days: 6,
            hours: 23,
            minutes: 59,
            seconds: 59,
            milliseconds: 999,
          ),
        );
        range = (start: thisMonday, end: thisSunday);
      }

      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    // G. Bare Month (Chinese): e.g. 10月, 12月份, 十月 -> resolves to most-recent-past occurrence
    final zhBareMonthRegex = RegExp(
      r'(1[0-2]|0?[1-9]|十一|十二|十|[一二三四五六七八九])\s*月份?',
    );
    final zhBmMatch = zhBareMonthRegex.firstMatch(input);
    if (zhBmMatch != null) {
      final matched = zhBmMatch.group(0)!;
      final monthToken = zhBmMatch.group(1)!;
      final month = int.tryParse(monthToken) ?? _chineseMonths[monthToken]!;
      final targetYear = month <= now.month ? now.year : now.year - 1;
      final range = _monthRange(targetYear, month);
      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    // H. Bare Month (English): e.g. October, in Oct -> resolves to most-recent-past occurrence
    final enBareMonthRegex = RegExp(
      r'\b(?:in\s+)?(january|jan|february|feb|march|mar|april|apr|june|jun|july|jul|august|aug|september|sept|sep|october|oct|november|nov|december|dec)\b',
      caseSensitive: false,
    );
    final enBmMatch = enBareMonthRegex.firstMatch(input);
    if (enBmMatch != null) {
      final matched = enBmMatch.group(0)!;
      final monthName = enBmMatch.group(1)!.toLowerCase();
      final month = _englishMonths[monthName]!;
      final targetYear = month <= now.month ? now.year : now.year - 1;
      final range = _monthRange(targetYear, month);
      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    // I. Full Year (Chinese or English): e.g. 去年, 今年, 前年, 2025年, last year, this year
    final yearOnlyRegex = RegExp(
      r'(去年|今年|前年|(\d{4})\s*年|\blast\s+year\b|\bthis\s+year\b)',
      caseSensitive: false,
    );
    final yearMatch = yearOnlyRegex.firstMatch(input);
    if (yearMatch != null) {
      final matched = yearMatch.group(0)!;
      final explicitYearStr = yearMatch.group(2);
      final targetYear = _resolveYear(matched.toLowerCase(), explicitYearStr, now.year);
      final range = (
        start: DateTime(targetYear, 1, 1, 0, 0, 0),
        end: DateTime(targetYear, 12, 31, 23, 59, 59, 999),
      );
      return _TemporalExtraction(
        start: range.start,
        end: range.end,
        matchedText: matched,
        remaining: input.replaceFirst(matched, ' '),
      );
    }

    return null;
  }

  static int _resolveYear(
    String yearSpec,
    String? explicitYearStr,
    int currentYear,
  ) {
    if (explicitYearStr != null) {
      return int.parse(explicitYearStr);
    }
    if (yearSpec.contains('去年') || yearSpec.contains('last')) {
      return currentYear - 1;
    }
    if (yearSpec.contains('前年')) {
      return currentYear - 2;
    }
    return currentYear;
  }

  static ({DateTime start, DateTime end}) _monthRange(int year, int month) {
    final start = DateTime(year, month, 1, 0, 0, 0);
    final nextMonth =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final end = nextMonth.subtract(const Duration(milliseconds: 1));
    return (start: start, end: end);
  }

  static ({DateTime start, DateTime end})? _resolveHolidayRange({
    required String holidayKey,
    required String? yearSpec,
    required int? explicitYear,
    required DateTime now,
  }) {
    int resolveHolidayYear(int holidayMonth, int holidayStartDay) {
      if (explicitYear != null) return explicitYear;
      if (yearSpec != null) {
        if (yearSpec.contains('去年')) return now.year - 1;
        if (yearSpec.contains('前年')) return now.year - 2;
        if (yearSpec.contains('今年')) return now.year;
      }
      // Bare holiday resolves to most recent occurrence
      final thisYearStart = DateTime(now.year, holidayMonth, holidayStartDay);
      return now.isBefore(thisYearStart) ? now.year - 1 : now.year;
    }

    if (holidayKey.startsWith('国庆') || holidayKey.contains('national')) {
      final y = resolveHolidayYear(10, 1);
      return (
        start: DateTime(y, 10, 1, 0, 0, 0),
        end: DateTime(y, 10, 7, 23, 59, 59, 999),
      );
    }
    if (holidayKey.startsWith('元旦') || holidayKey.contains('new year')) {
      final y = resolveHolidayYear(1, 1);
      return (
        start: DateTime(y, 1, 1, 0, 0, 0),
        end: DateTime(y, 1, 3, 23, 59, 59, 999),
      );
    }
    if (holidayKey.contains('情人') || holidayKey.contains('valentine')) {
      final y = resolveHolidayYear(2, 14);
      return (
        start: DateTime(y, 2, 14, 0, 0, 0),
        end: DateTime(y, 2, 14, 23, 59, 59, 999),
      );
    }
    if (holidayKey.contains('五一') ||
        holidayKey.contains('劳动') ||
        holidayKey.contains('labor') ||
        holidayKey.contains('labour')) {
      final y = resolveHolidayYear(5, 1);
      return (
        start: DateTime(y, 5, 1, 0, 0, 0),
        end: DateTime(y, 5, 5, 23, 59, 59, 999),
      );
    }
    if (holidayKey.startsWith('圣诞') || holidayKey.contains('christmas')) {
      final y = resolveHolidayYear(12, 24);
      return (
        start: DateTime(y, 12, 24, 0, 0, 0),
        end: DateTime(y, 12, 25, 23, 59, 59, 999),
      );
    }
    return null;
  }

  static _WeatherExtraction? _extractWeather(String input) {
    // 1. Multi-character Chinese & English weather words (safe to match anywhere)
    final multiCharPatterns = <(RegExp, String)>[
      (RegExp(r'(晴天|晴朗|\bsunny\b)', caseSensitive: false), 'sunny'),
      (RegExp(r'(雨天|下雨|大雨|小雨|暴雨|\brainy\b)', caseSensitive: false), 'rainy'),
      (RegExp(r'(多云|阴天|\bcloudy\b)', caseSensitive: false), 'cloudy'),
      (RegExp(r'(雪天|下雪|大雪|小雪|\bsnowy\b)', caseSensitive: false), 'snowy'),
      (RegExp(r'(大风|刮风|微风|\bwindy\b)', caseSensitive: false), 'windy'),
    ];

    for (final (regex, value) in multiCharPatterns) {
      final match = regex.firstMatch(input);
      if (match != null) {
        final matched = match.group(0)!;
        return _WeatherExtraction(
          weatherValue: value,
          matchedText: matched,
          remaining: input.replaceFirst(matched, ' '),
        );
      }
    }

    // 2. Single-character Chinese weather tokens ONLY when standalone (surrounded by start/end/space)
    // Prevents matching "雪" inside "雪糕" or "雨" inside "雨伞".
    final singleCharRegex = RegExp(r'(?:^|\s)(晴|雨|雪|阴)(?=\s|$)');
    final singleMatch = singleCharRegex.firstMatch(input);
    if (singleMatch != null) {
      final token = singleMatch.group(1)!;
      final value = switch (token) {
        '晴' => 'sunny',
        '雨' => 'rainy',
        '雪' => 'snowy',
        '阴' => 'cloudy',
        _ => 'sunny',
      };
      return _WeatherExtraction(
        weatherValue: value,
        matchedText: token,
        remaining: input.replaceFirst(token, ' '),
      );
    }

    return null;
  }

  static String _stripStopPhrases(String input) {
    var result = input;
    final zhStopPhrases = [
      '发生的事情',
      '发生的事',
      '发生了什么',
      '的事情',
      '的事',
      '的日记',
      '写的日记',
      '所有',
      '全部',
    ];
    for (final phrase in zhStopPhrases) {
      result = result.replaceAll(phrase, ' ');
    }

    result = result.replaceAll(
      RegExp(
        r'\b(what\s+happened|entries|diary|diaries|all|in|during|on)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    // Strip dangling leading or trailing '的'
    result = result.trim();
    if (result.startsWith('的')) {
      result = result.substring(1).trim();
    }
    if (result.endsWith('的')) {
      result = result.substring(0, result.length - 1).trim();
    }
    return result;
  }
}

class _TemporalExtraction {
  final DateTime start;
  final DateTime end;
  final String matchedText;
  final String remaining;

  const _TemporalExtraction({
    required this.start,
    required this.end,
    required this.matchedText,
    required this.remaining,
  });
}

class _WeatherExtraction {
  final String weatherValue;
  final String matchedText;
  final String remaining;

  const _WeatherExtraction({
    required this.weatherValue,
    required this.matchedText,
    required this.remaining,
  });
}

