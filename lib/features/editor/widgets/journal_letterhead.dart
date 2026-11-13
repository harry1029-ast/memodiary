import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/letterhead_data.dart';
import 'letterhead_charm.dart';
import 'letterhead_date_block.dart';
import 'letterhead_pickers.dart';
import 'lunar_date_seal.dart';

/// Authentic in-paper journal letterhead rendered directly on the upper rows of
/// the opening Journal Sheet, exactly [rowCount] ruled rows of [rowHeight] tall:
/// the Lunar Date Seal at the left, a column holding the muted date lines above
/// a larger title anchored to the bottom row, and the vertical Weather and Mood
/// Charms at the right.
class JournalLetterhead extends StatelessWidget {
  /// Ruled rows the letterhead spans.
  static const int rowCount = kJournalLetterheadReservedRows;

  /// Largest text scale the letterhead honours, keeping it inside its rows.
  static const double maxTextScale = 1.3;

  /// The title honours less text scale than the date lines: at the smallest
  /// row height it shares its rows with two scaled date lines.
  static const double titleMaxTextScale = 1.15;

  static const double titleFontSize = 20;
  static const double _titleLineHeight = 1.2;

  /// Visible gap between the carved seal's edge and the text beside it.
  static const double sealToTextGap = 12;

  final LetterheadData data;
  final double rowHeight;
  final TextEditingController? titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;

  const JournalLetterhead({
    super.key,
    required this.data,
    required this.rowHeight,
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
    const sealInset = (LunarDateSeal.kTargetSize - LunarDateSeal.kSealSize) / 2;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: SizedBox(
        height: rowCount * rowHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // Subtle deckle stationery divider on the last ruled line.
              child: Container(
                height: 0.8,
                color: tokens.deckleBorder.withValues(alpha: 0.5),
              ),
            ),
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
                const SizedBox(width: sealToTextGap - sealInset),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: LetterheadDateBlock(data: data),
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(InkDiaryTokens tokens) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: titleMaxTextScale,
      child: TextField(
        controller: titleController,
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: titleFontSize,
          height: _titleLineHeight,
          fontWeight: FontWeight.bold,
          color: tokens.jiaomo,
          letterSpacing: 0.5,
        ),
        cursorColor: tokens.cinnabar,
        decoration: InputDecoration(
          hintText: '题名 · Title...',
          hintStyle: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: titleFontSize - 1,
            height: _titleLineHeight,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: tokens.danmo.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.only(bottom: 2),
        ),
      ),
    );
  }
}
