import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';
import '../cinnabar_signature_seal.dart';

/// Renders the terminal colophon (题跋落款) with date, mood/weather, and Cinnabar Signature Seal.
class KeepsakeColophon extends StatelessWidget {
  final Entry entry;
  final TemplateStyle style;
  final Color inkColor;
  final double columnWidth;

  const KeepsakeColophon({
    super.key,
    required this.entry,
    required this.style,
    required this.inkColor,
    this.columnWidth = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final ruleTint = style.tokens.ruleTint;
    final ruleColor = ruleTint.color.withValues(
      alpha: ruleTint == RuleInkTint.charcoal ? 0.20 : 0.35,
    );

    final dateFormatted = DateFormat('yyyy年M月d日').format(entry.entryDate);
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final dayOfWeek = '星期${weekdays[entry.entryDate.weekday - 1]}';

    final colophonDetails = <String>[];
    if (entry.isWeeklyReview) {
      colophonDetails.add('第${entry.weekNumber ?? ""}周复盘');
    }
    if (entry.mood != null) {
      colophonDetails.add('心绪 ${entry.mood}/5');
    }
    if (entry.weather != null && entry.weather!.trim().isNotEmpty) {
      colophonDetails.add('天象 ${entry.weather!.trim()}');
    }

    final fullColophonText = '$dateFormatted $dayOfWeek ${colophonDetails.join(" · ")}';

    return Container(
      width: columnWidth + 24.0,
      margin: const EdgeInsets.only(right: 8.0, left: 16.0),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: ruleColor, width: 0.6),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vertical Colophon Metadata
          Semantics(
            container: true,
            label: fullColophonText,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildVerticalRun('$dateFormatted $dayOfWeek'),
                if (colophonDetails.isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  _buildVerticalRun(colophonDetails.join(' ')),
                ],
              ],
            ),
          ),

          // User's Cinnabar Signature Seal
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CinnabarSignatureSeal(
              key: const Key('keepsake_signature_seal'),
              sealStyle: style.tokens.sealStyle,
              size: 46.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalRun(String text) {
    final chars = text.split('');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: chars.map((ch) {
        if (ch == ' ') return const SizedBox(height: 6.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.5),
          child: Text(
            ch,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 11.0,
              color: inkColor.withValues(alpha: 0.65),
              height: 1.0,
            ),
          ),
        );
      }).toList(),
    );
  }
}
