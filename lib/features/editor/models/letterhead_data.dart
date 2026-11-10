import 'package:flutter/foundation.dart';

import '../../../core/calendar/lunar_calendar.dart';
import '../widgets/journal_letterhead_models.dart';

/// Immutable front-matter of Sheet 1's Journal Letterhead: the solar date, its
/// lunar date and solar term, and the entry's weather and mood.
@immutable
class LetterheadData {
  const LetterheadData({
    required this.entryDate,
    required this.lunarDate,
    required this.solarTerm,
    required this.weather,
    required this.mood,
  });

  /// Derives the lunar date and solar term from [entryDate].
  factory LetterheadData.resolve({
    required DateTime entryDate,
    String? weather,
    int? mood,
  }) {
    return LetterheadData(
      entryDate: entryDate,
      lunarDate: LunarCalendar.fromSolar(entryDate),
      solarTerm: JournalLetterheadUtils.calculateSolarTerm(entryDate),
      weather: weather,
      mood: mood,
    );
  }

  final DateTime entryDate;
  final LunarDate lunarDate;
  final String solarTerm;

  /// The stored weather value, or null when the diarist has not chosen one.
  final String? weather;

  /// The stored mood value, or null when the diarist has not chosen one.
  final int? mood;

  WeatherOption get weatherOption => JournalLetterheadUtils.resolveWeather(weather);

  MoodOption get moodOption => JournalLetterheadUtils.resolveMood(mood);

  /// Date line 1, e.g. `2026年11月10日 周二`.
  String get solarDateLine {
    final weekdayName = JournalLetterheadUtils.chineseWeekdays[(entryDate.weekday - 1).clamp(0, 6)];
    return '${entryDate.year}年${entryDate.month}月${entryDate.day}日 $weekdayName';
  }

  /// The stem-branch year, shown on the right column of the seal.
  String get sealYearText => lunarDate.stemBranchYear;

  /// The seasonal month, shown on the left column of the seal; null out of range.
  String? get sealMonthText => lunarDate.seasonalMonthName;

  /// The lunar day, e.g. `初二`; null out of range.
  String? get lunarDayName => lunarDate.dayName;

  /// The lunar month and day, e.g. `十月初二`; null out of range.
  String? get lunarDayLine => lunarDate.monthDayName;

  /// Date line 2 when the solar term is shown, e.g. `十月初二 · 立冬`; null out of range.
  String? get lunarLineWithTerm {
    final dayLine = lunarDayLine;
    return dayLine == null ? null : '$dayLine · $solarTerm';
  }

  /// Label for the tappable seal, e.g. `岁次丙午 孟冬初二，轻触修改日期`.
  String get sealSemanticsLabel {
    final monthText = sealMonthText;
    final dayText = lunarDayName;
    if (monthText == null || dayText == null) {
      return '岁次$sealYearText，轻触修改日期';
    }
    return '岁次$sealYearText $monthText$dayText，轻触修改日期';
  }

  /// Label for the date block, e.g. `2026年11月10日 周二，农历十月初二，立冬`.
  String get dateSemanticsLabel {
    final dayLine = lunarDayLine;
    if (dayLine == null) return '$solarDateLine，$solarTerm';
    return '$solarDateLine，农历$dayLine，$solarTerm';
  }

  /// Label for the Weather Charm, e.g. `天气晴明，轻触修改`.
  String get weatherSemanticsLabel => '天气${weatherOption.label}，轻触修改';

  /// Label for the Mood Charm, e.g. `心情怡然，轻触修改`.
  String get moodSemanticsLabel => '心情${moodOption.label}，轻触修改';

  @override
  bool operator ==(Object other) =>
      other is LetterheadData &&
      other.entryDate == entryDate &&
      other.lunarDate == lunarDate &&
      other.solarTerm == solarTerm &&
      other.weather == weather &&
      other.mood == mood;

  @override
  int get hashCode => Object.hash(entryDate, lunarDate, solarTerm, weather, mood);
}
