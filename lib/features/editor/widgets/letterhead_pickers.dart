import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import 'journal_letterhead_models.dart';

/// The date/time, mood and weather pickers opened from the Journal Letterhead's
/// seal and charms.
abstract final class LetterheadPickers {
  /// Picks a date, then a time; the time falls back to [entryDate]'s when dismissed.
  static Future<void> pickDate({
    required BuildContext context,
    required DateTime entryDate,
    required ValueChanged<DateTime> onDateChanged,
  }) async {
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

    onDateChanged(DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? entryDate.hour,
      pickedTime?.minute ?? entryDate.minute,
    ));
  }

  static void showMoodPicker({
    required BuildContext context,
    required int? mood,
    required ValueChanged<int?> onMoodChanged,
  }) {
    final tokens = InkDiaryTheme.tokensOf(context);

    _showSelectionModal(
      context: context,
      title: '心境感怀 · Select Mood',
      children: JournalLetterheadUtils.moodOptions.map((moodOption) {
        final isSelected = mood == moodOption.value;
        return _OptionTile(
          isSelected: isSelected,
          label: moodOption.label,
          onTap: () {
            HapticFeedback.lightImpact();
            onMoodChanged(moodOption.value);
            Navigator.pop(context);
          },
          glyph: Text(moodOption.emoji, style: const TextStyle(fontSize: 26)),
          tokens: tokens,
        );
      }).toList(),
    );
  }

  static void showWeatherPicker({
    required BuildContext context,
    required String? weather,
    required ValueChanged<String?> onWeatherChanged,
  }) {
    final tokens = InkDiaryTheme.tokensOf(context);

    _showSelectionModal(
      context: context,
      title: '天候气象 · Select Weather',
      children: JournalLetterheadUtils.weatherOptions.map((weatherOption) {
        final isSelected = weather == weatherOption.value;
        return _OptionTile(
          isSelected: isSelected,
          label: weatherOption.label,
          onTap: () {
            HapticFeedback.lightImpact();
            onWeatherChanged(weatherOption.value);
            Navigator.pop(context);
          },
          glyph: Icon(
            weatherOption.icon,
            size: 26,
            color: isSelected ? tokens.cinnabar : tokens.nongmo,
          ),
          tokens: tokens,
        );
      }).toList(),
    );
  }

  static void _showSelectionModal({
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
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tokens.jiaomo,
                      ),
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
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.isSelected,
    required this.label,
    required this.onTap,
    required this.glyph,
    required this.tokens,
  });

  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final Widget glyph;
  final InkDiaryTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            glyph,
            const SizedBox(height: 4),
            Text(
              label,
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
  }
}
