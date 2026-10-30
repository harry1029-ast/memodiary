import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/ink_diary_theme.dart';

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
  final IconData icon;
  final String label;
  final String subtitle;

  const WeatherOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

/// Authentic in-paper journal letterhead rendered directly on the upper lines
/// of the Journal Sheet, combining date/time, solar terms, weather, mood, and borderless title.
class JournalLetterhead extends StatelessWidget {
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final TextEditingController? titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;

  const JournalLetterhead({
    super.key,
    required this.entryDate,
    required this.mood,
    required this.weather,
    this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
  });

  static const List<MoodOption> moodOptions = [
    MoodOption(value: 1, emoji: '😢', label: '沉郁', subtitle: 'Down'),
    MoodOption(value: 2, emoji: '🙁', label: '倦怠', subtitle: 'Tired'),
    MoodOption(value: 3, emoji: '😐', label: '静穆', subtitle: 'Calm'),
    MoodOption(value: 4, emoji: '🙂', label: '怡然', subtitle: 'Happy'),
    MoodOption(value: 5, emoji: '😄', label: '欢欣', subtitle: 'Great'),
  ];

  static const List<WeatherOption> weatherOptions = [
    WeatherOption(value: 'sunny', icon: Icons.wb_sunny_outlined, label: '晴明', subtitle: 'Sunny'),
    WeatherOption(value: 'cloudy', icon: Icons.cloud_outlined, label: '阴翳', subtitle: 'Cloudy'),
    WeatherOption(value: 'rainy', icon: Icons.water_drop_outlined, label: '润雨', subtitle: 'Rainy'),
    WeatherOption(value: 'windy', icon: Icons.air_outlined, label: '朔风', subtitle: 'Windy'),
    WeatherOption(value: 'snowy', icon: Icons.ac_unit_outlined, label: '凝雪', subtitle: 'Snowy'),
  ];

  static const List<String> chineseWeekdays = [
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
  ];

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

  String _formatDateString(DateTime date) {
    final yearMonthDay = DateFormat('yyyy年M月d日').format(date);
    final weekdayName = chineseWeekdays[(date.weekday - 1).clamp(0, 6)];
    final solarTerm = calculateSolarTerm(date);
    return '$yearMonthDay $weekdayName · $solarTerm';
  }

  MoodOption _resolveMood(int? moodValue) {
    return moodOptions.firstWhere(
      (option) => option.value == moodValue,
      orElse: () => moodOptions[3], // Default 怡然
    );
  }

  WeatherOption _resolveWeather(String? weatherValue) {
    return weatherOptions.firstWhere(
      (option) => option.value == weatherValue,
      orElse: () => weatherOptions.first, // Default 晴明
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    HapticFeedback.selectionClick();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(entryDate),
    );

    if (pickedTime != null) {
      onDateChanged(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
    } else {
      onDateChanged(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        entryDate.hour,
        entryDate.minute,
      ));
    }
  }

  void _showSelectionModal({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    HapticFeedback.selectionClick();
    final tokens = InkDiaryTheme.tokensOf(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.danmo.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: tokens.cinnabar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoodPicker(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    _showSelectionModal(
      context: context,
      title: '心境感怀 · Select Mood',
      children: moodOptions.map((moodOption) {
        final isSelected = mood == moodOption.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onMoodChanged(moodOption.value);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? tokens.cinnabarWash : tokens.ricePaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? tokens.cinnabar : tokens.agedFiber,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  moodOption.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  moodOption.label,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? tokens.cinnabar : tokens.nongmo,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showWeatherPicker(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    _showSelectionModal(
      context: context,
      title: '天候气象 · Select Weather',
      children: weatherOptions.map((weatherOption) {
        final isSelected = weather == weatherOption.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onWeatherChanged(weatherOption.value);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? tokens.cinnabarWash : tokens.ricePaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? tokens.cinnabar : tokens.agedFiber,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  weatherOption.icon,
                  size: 26,
                  color: isSelected ? tokens.cinnabar : tokens.nongmo,
                ),
                const SizedBox(height: 4),
                Text(
                  weatherOption.label,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? tokens.cinnabar : tokens.nongmo,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final activeMood = _resolveMood(mood);
    final activeWeather = _resolveWeather(weather);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: Date & Day of Week & Solar Term, flanked by Weather & Mood
          Row(
            children: [
              // Date, Weekday & Solar Term tag
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _pickDate(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: tokens.danmo,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDateString(entryDate),
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.nongmo,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Weather Emblem
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _showWeatherPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activeWeather.icon,
                        size: 14,
                        color: tokens.danmo,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        activeWeather.label,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 12,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Mood Emblem
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _showMoodPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeMood.emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        activeMood.label,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 12,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Line 2: Borderless Stationery Title Field
          if (titleController != null)
            TextField(
              controller: titleController,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
                letterSpacing: 0.5,
              ),
              cursorColor: tokens.cinnabar,
              decoration: InputDecoration(
                hintText: '题名 · Title...',
                hintStyle: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: tokens.danmo.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
            ),

          const SizedBox(height: 6),

          // Subtle Deckle Stationery Divider
          Container(
            height: 0.8,
            color: tokens.deckleBorder.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
