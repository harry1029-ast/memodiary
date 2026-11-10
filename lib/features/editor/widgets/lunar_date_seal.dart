import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../models/letterhead_data.dart';

/// The carved cinnabar Lunar Date Seal (岁时印) at the left of the Journal
/// Letterhead: a 38x38 two-by-two character grid read right column first, with
/// the stem-branch year on the right and the seasonal month on the left. Out of
/// the lunar data range only the year column is carved. Tapping it edits the
/// entry date.
class LunarDateSeal extends StatelessWidget {
  const LunarDateSeal({super.key, required this.data, required this.onTap});

  static const double sealSize = 38;
  static const double targetSize = 44;

  final LetterheadData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    return Semantics(
      button: true,
      label: data.sealSemanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        key: const Key('letterhead_date_seal_target'),
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: SizedBox(
          width: targetSize,
          height: targetSize,
          child: Center(
            child: Transform.rotate(
              angle: -3 * math.pi / 180,
              child: MediaQuery.withNoTextScaling(
                child: _SealFace(data: data, color: tokens.cinnabar),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SealFace extends StatelessWidget {
  const _SealFace({required this.data, required this.color});

  final LetterheadData data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('letterhead_date_seal'),
      width: LunarDateSeal.sealSize,
      height: LunarDateSeal.sealSize,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(child: _SealColumn(text: data.sealMonthText, color: color)),
          Expanded(child: _SealColumn(text: data.sealYearText, color: color)),
        ],
      ),
    );
  }
}

class _SealColumn extends StatelessWidget {
  const _SealColumn({required this.text, required this.color});

  final String? text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final characters = (text ?? '').split('');
    return Column(
      children: [
        for (final character in characters)
          Expanded(
            child: Center(
              child: Text(
                character,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontMaShanZheng,
                  fontSize: 13,
                  height: 1,
                  color: color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
