import 'package:flutter/material.dart';

/// Immutable typed model for literati mood options
@immutable
class MoodOption {
  final int value;
  final String emoji;
  final String label;
  final String subtitle;

  const MoodOption({
    required this.value,
    required this.emoji,
    required this.label,
    required this.subtitle,
  });
}

/// Immutable typed model for literati weather options
@immutable
class WeatherOption {
  final String value;
  final String emoji;
  final IconData icon;
  final String label;
  final String subtitle;

  const WeatherOption({
    required this.value,
    required this.emoji,
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

/// Date formatting and solar term helpers for the journal letterhead
abstract final class JournalLetterheadUtils {
  /// Weekday names for date line 1 (`周一` ... `周日`), indexed by `DateTime.weekday - 1`.
  static const List<String> chineseWeekdays = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static const List<MoodOption> moodOptions = [
    MoodOption(value: 1, emoji: '😢', label: '沉郁', subtitle: 'Down'),
    MoodOption(value: 2, emoji: '🙁', label: '倦怠', subtitle: 'Tired'),
    MoodOption(value: 3, emoji: '😐', label: '静穆', subtitle: 'Calm'),
    MoodOption(value: 4, emoji: '🙂', label: '怡然', subtitle: 'Happy'),
    MoodOption(value: 5, emoji: '😄', label: '欢欣', subtitle: 'Great'),
  ];

  static const List<WeatherOption> weatherOptions = [
    WeatherOption(value: 'sunny', emoji: '☀️', icon: Icons.wb_sunny_outlined, label: '晴明', subtitle: 'Sunny'),
    WeatherOption(value: 'cloudy', emoji: '☁️', icon: Icons.cloud_outlined, label: '阴翳', subtitle: 'Cloudy'),
    WeatherOption(value: 'rainy', emoji: '🌧️', icon: Icons.water_drop_outlined, label: '润雨', subtitle: 'Rainy'),
    WeatherOption(value: 'windy', emoji: '🍃', icon: Icons.air_outlined, label: '朔风', subtitle: 'Windy'),
    WeatherOption(value: 'snowy', emoji: '❄️', icon: Icons.ac_unit_outlined, label: '凝雪', subtitle: 'Snowy'),
  ];

  /// The mood for [moodValue], defaulting to 怡然 when unset or unknown.
  static MoodOption resolveMood(int? moodValue) => moodOptions.firstWhere(
        (option) => option.value == moodValue,
        orElse: () => moodOptions[3],
      );

  /// The weather for [weatherValue], defaulting to 晴明 when unset or unknown.
  static WeatherOption resolveWeather(String? weatherValue) => weatherOptions.firstWhere(
        (option) => option.value == weatherValue,
        orElse: () => weatherOptions.first,
      );

  /// Deterministic approximation of 24 Chinese solar terms (节气)
  static String calculateSolarTerm(DateTime date) {
    final month = date.month;
    final day = date.day;
    switch (month) {
      case 1:
        return day < 6 ? '冬至' : (day < 20 ? '小寒' : '大寒');
      case 2:
        return day < 4 ? '大寒' : (day < 19 ? '立春' : '雨水');
      case 3:
        return day < 6 ? '雨水' : (day < 21 ? '惊蛰' : '春分');
      case 4:
        return day < 5 ? '春分' : (day < 20 ? '清明' : '谷雨');
      case 5:
        return day < 6 ? '谷雨' : (day < 21 ? '立夏' : '小满');
      case 6:
        return day < 6 ? '小满' : (day < 21 ? '芒种' : '夏至');
      case 7:
        return day < 7 ? '夏至' : (day < 23 ? '小暑' : '大暑');
      case 8:
        return day < 8 ? '大暑' : (day < 23 ? '立秋' : '处暑');
      case 9:
        return day < 8 ? '处暑' : (day < 23 ? '白露' : '秋分');
      case 10:
        return day < 8 ? '秋分' : (day < 23 ? '寒露' : '霜降');
      case 11:
        return day < 7 ? '霜降' : (day < 22 ? '立冬' : '小雪');
      case 12:
        return day < 7 ? '小雪' : (day < 22 ? '大雪' : '冬至');
      default:
        return '清和';
    }
  }
}
