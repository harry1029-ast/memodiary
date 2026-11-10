import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../models/letterhead_data.dart';
import 'letterhead_charm.dart';
import 'letterhead_date_block.dart';
import 'letterhead_pickers.dart';
import 'lunar_date_seal.dart';

/// Authentic in-paper journal letterhead rendered directly on the upper rows of
/// the opening Journal Sheet: the Lunar Date Seal at the left, a column of date
/// line 1, date line 2 and the borderless title, and the vertical Weather and
/// Mood Charms at the right.
class JournalLetterhead extends StatelessWidget {
  /// Largest text scale the letterhead honours, keeping it inside its rows.
  static const double maxTextScale = 1.3;

  final LetterheadData data;
  final TextEditingController? titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;

  const JournalLetterhead({
    super.key,
    required this.data,
    this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final weatherOption = data.weatherOption;
    final moodOption = data.moodOption;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LunarDateSeal(
                  data: data,
                  onTap: () => LetterheadPickers.pickDate(
                    context: context,
                    entryDate: data.entryDate,
                    onDateChanged: onDateChanged,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LetterheadDateBlock(data: data),
                      if (titleController != null) _buildTitleField(tokens),
                    ],
                  ),
                ),
                LetterheadCharm(
                  keyPrefix: 'letterhead_weather_charm',
                  emoji: weatherOption.emoji,
                  label: weatherOption.label,
                  semanticsLabel: data.weatherSemanticsLabel,
                  onTap: () => LetterheadPickers.showWeatherPicker(
                    context: context,
                    weather: data.weather,
                    onWeatherChanged: onWeatherChanged,
                  ),
                ),
                LetterheadCharm(
                  keyPrefix: 'letterhead_mood_charm',
                  emoji: moodOption.emoji,
                  label: moodOption.label,
                  semanticsLabel: data.moodSemanticsLabel,
                  onTap: () => LetterheadPickers.showMoodPicker(
                    context: context,
                    mood: data.mood,
                    onMoodChanged: onMoodChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Subtle deckle stationery divider
            Container(
              height: 0.8,
              color: tokens.deckleBorder.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(InkDiaryTokens tokens) {
    return TextField(
      controller: titleController,
      style: TextStyle(
        fontFamily: InkDiaryTheme.fontNotoSerif,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: tokens.jiaomo,
        letterSpacing: 0.5,
      ),
      cursorColor: tokens.cinnabar,
      decoration: InputDecoration(
        hintText: '题名 · Title...',
        hintStyle: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: tokens.danmo.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
      ),
    );
  }
}
