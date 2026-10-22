import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/ink_metadata_pill.dart';

/// Classical Ink & Paper metadata bar providing date backdating,
/// mood selection, weather logging, and Time Capsule sealing.
class EntryMetadataBar extends StatelessWidget {
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final DateTime? unlockAt;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;
  final ValueChanged<DateTime?> onUnlockAtChanged;

  const EntryMetadataBar({
    super.key,
    required this.entryDate,
    required this.mood,
    required this.weather,
    required this.unlockAt,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
    required this.onUnlockAtChanged,
  });

  static const List<Map<String, dynamic>> moodOptions = [
    {'value': 1, 'emoji': '😢', 'label': '沉郁', 'subtitle': 'Down'},
    {'value': 2, 'emoji': '🙁', 'label': '倦怠', 'subtitle': 'Tired'},
    {'value': 3, 'emoji': '😐', 'label': '静穆', 'subtitle': 'Calm'},
    {'value': 4, 'emoji': '🙂', 'label': '怡然', 'subtitle': 'Happy'},
    {'value': 5, 'emoji': '😄', 'label': '欢欣', 'subtitle': 'Great'},
  ];

  static const List<Map<String, dynamic>> weatherOptions = [
    {'value': 'sunny', 'icon': Icons.wb_sunny_outlined, 'label': '晴明', 'subtitle': 'Sunny'},
    {'value': 'cloudy', 'icon': Icons.cloud_outlined, 'label': '阴翳', 'subtitle': 'Cloudy'},
    {'value': 'rainy', 'icon': Icons.water_drop_outlined, 'label': '润雨', 'subtitle': 'Rainy'},
    {'value': 'windy', 'icon': Icons.air_outlined, 'label': '朔风', 'subtitle': 'Windy'},
    {'value': 'snowy', 'icon': Icons.ac_unit_outlined, 'label': '凝雪', 'subtitle': 'Snowy'},
  ];

  Future<void> _pickDate(BuildContext context) async {
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

  void _showMoodPicker(BuildContext context) {
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
                    '心境感怀 · Select Mood',
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
                children: moodOptions.map((moodOption) {
                  final isSelected = mood == moodOption['value'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMoodChanged(moodOption['value'] as int);
                      Navigator.pop(bottomSheetContext);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.cinnabarWash
                            : tokens.ricePaper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? tokens.cinnabar
                              : tokens.agedFiber,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            moodOption['emoji'] as String,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            moodOption['label'] as String,
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
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherPicker(BuildContext context) {
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
                    '天候气象 · Select Weather',
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
                children: weatherOptions.map((weatherOption) {
                  final isSelected = weather == weatherOption['value'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onWeatherChanged(weatherOption['value'] as String);
                      Navigator.pop(bottomSheetContext);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.cinnabarWash
                            : tokens.ricePaper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? tokens.cinnabar
                              : tokens.agedFiber,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            weatherOption['icon'] as IconData,
                            size: 24,
                            color: isSelected ? tokens.cinnabar : tokens.nongmo,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weatherOption['label'] as String,
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
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTimeCapsule(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: unlockAt ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: '时光胶囊封缄至 · Seal Until Date',
    );

    if (pickedDate != null) {
      HapticFeedback.lightImpact();
      onUnlockAtChanged(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(entryDate);

    final currentMoodOption = moodOptions.cast<Map<String, dynamic>?>().firstWhere(
          (option) => option?['value'] == mood,
          orElse: () => null,
        );

    final currentWeatherOption = weatherOptions.cast<Map<String, dynamic>?>().firstWhere(
          (option) => option?['value'] == weather,
          orElse: () => null,
        );

    final moodLabel = currentMoodOption != null
        ? '心境 · ${currentMoodOption['label']}'
        : '心境';

    final weatherLabel = currentWeatherOption != null
        ? '天候 · ${currentWeatherOption['label']}'
        : '天候';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Date & Time Capsule Pill
          InkMetadataPill(
            icon: Icons.calendar_today_outlined,
            label: formattedDate,
            onTap: () => _pickDate(context),
            semanticLabel: '日记日期 $formattedDate',
          ),
          const SizedBox(width: 8),

          // Mood Pill
          InkMetadataPill(
            emoji: currentMoodOption != null ? (currentMoodOption['emoji'] as String) : '🙂',
            label: moodLabel,
            onTap: () => _showMoodPicker(context),
            semanticLabel: '选择心境 $moodLabel',
          ),
          const SizedBox(width: 8),

          // Weather Pill
          InkMetadataPill(
            icon: currentWeatherOption != null
                ? (currentWeatherOption['icon'] as IconData)
                : Icons.wb_sunny_outlined,
            label: weatherLabel,
            onTap: () => _showWeatherPicker(context),
            semanticLabel: '选择天候 $weatherLabel',
          ),
          const SizedBox(width: 8),

          // Time Capsule Pill
          InkMetadataPill(
            icon: unlockAt != null ? Icons.lock_clock : Icons.hourglass_empty,
            label: unlockAt != null
                ? '封缄 · ${DateFormat('MM-dd').format(unlockAt!)}'
                : '时光胶囊',
            isAccent: unlockAt != null,
            onTap: () => _pickTimeCapsule(context),
            semanticLabel: unlockAt != null ? '时光胶囊已设定' : '设定时光胶囊',
          ),
        ],
      ),
    );
  }
}
