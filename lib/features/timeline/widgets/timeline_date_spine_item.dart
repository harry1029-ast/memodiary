import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/theme/shapes/classical_chinese_borders.dart';
import 'lunar_phase_glyph.dart';

/// Formats a Gregorian day of the month (1-31) with the `日` suffix
/// (e.g. 1 -> '1日', 25 -> '25日', 31 -> '31日').
String formatGregorianDay(int day) => '$day日';

/// Converts a calendar day of the month (1-31) into traditional Chinese numeral phrasing
/// (e.g. 1 -> '初一', 10 -> '初十', 15 -> '十五', 20 -> '二十', 25 -> '廿五', 31 -> '三十一').
String formatTraditionalChineseDay(int day) {
  const chineseDays = [
    '',
    '初一', '初二', '初三', '初四', '初五',
    '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五',
    '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五',
    '廿六', '廿七', '廿八', '廿九', '三十',
    '三十一',
  ];
  if (day >= 1 && day <= 31) {
    return chineseDays[day];
  }
  return '$day';
}

/// Formats weekday index (1-7) to traditional Chinese phrasing ('周一' - '周日').
String formatChineseWeekday(int weekday) {
  const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  if (weekday >= 1 && weekday <= 7) {
    return weekdays[weekday];
  }
  return '';
}

/// A timeline container item rendering an articulated vertical ink axis line (spine)
/// and a prominent calendar seal date badge along the left margin.
///
/// Derived from Stitch design (.stitch/designs/timeline_feed.html).
class TimelineDateSpineItem extends StatelessWidget {
  final DateTime date;
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted;
  final bool connectFromTop;
  final bool useLunarDay;
  final VoidCallback? onTapBadge;

  const TimelineDateSpineItem({
    super.key,
    required this.date,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.isHighlighted = false,
    this.connectFromTop = false,
    this.useLunarDay = false,
    this.onTapBadge,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    return Stack(
      children: [
        // 1. Continuous Vertical Axis Spine Line
        Positioned(
          left: 36,
          top: (isFirst && !connectFromTop) ? 20 : 0,
          bottom: isLast ? 36 : 0,
          child: Container(
            key: const Key('timeline_date_spine_line'),
            width: 2.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.0),
              gradient: isFirst
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.spineCordTop,
                        palette.deckleBorder,
                      ],
                    )
                  : null,
              color: isFirst ? null : palette.deckleBorder,
            ),
          ),
        ),

        // 2. Right-Offset Entry Card
        Padding(
          padding: const EdgeInsets.only(left: 68, right: 14, bottom: 12),
          child: child,
        ),

        // 3. Left Date Marker Stamp Badge (Carved Waist-Tally Seal) & Connecting Knot
        Positioned(
          left: 11,
          top: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWaistTallyBadge(palette: palette),
              const SizedBox(height: 3),
              // Connecting Diamond Node Knot (Pan-Chang Knot Node on the Silk Cord)
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? palette.accentPrimary
                        : palette.accentSecondaryDim,
                    border: Border.all(
                      color: palette.deskMat,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaistTallyBadge({
    required AtmospherePalette palette,
  }) {
    final borderColor = isHighlighted
        ? palette.tallyFeaturedBorder
        : palette.tallyBorder;

    final innerBorderColor = isHighlighted
        ? palette.tallyFeaturedText.withValues(alpha: 0.35)
        : palette.slipInnerFrameColor;

    final tallyBorder = WaistTallyBorder(
      cutSize: 7.0,
      cordHoleRadius: 2.2,
      borderColor: borderColor,
      borderWidth: 1.0,
      innerBorderColor: innerBorderColor,
    );

    final gradient = isHighlighted
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.tallyFeaturedTop, palette.tallyFeaturedBottom],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.tallyBgTop, palette.tallyBgBottom],
          );

    final shadowColor = isHighlighted
        ? palette.tallyFeaturedShadow
        : palette.slipShadowColor;

    final secondaryTextColor = isHighlighted
        ? palette.tallyFeaturedText.withValues(alpha: 0.88)
        : palette.textMuted;

    final dayTextColor = isHighlighted
        ? palette.tallyFeaturedText
        : palette.textPrimary;

    return Tooltip(
      message: '${date.year}年${date.month}月${date.day}日 ${formatChineseWeekday(date.weekday)}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: tallyBorder,
          onTap: onTapBadge,
          child: Container(
            width: 52,
            padding: const EdgeInsets.fromLTRB(2, 7.5, 2, 4),
            decoration: ShapeDecoration(
              shape: tallyBorder,
              gradient: gradient,
              shadows: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LunarPhaseGlyph(
                  key: const Key('waist_tally_lunar_phase'),
                  bucket: resolveLunarPhaseForDate(date),
                  color: isHighlighted
                      ? palette.tallyFeaturedText
                      : palette.accentPrimary,
                ),
                const SizedBox(height: 1.5),
                // Month label (clean sans-serif)
                Text(
                  '${date.month}月',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.1,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 1.0),
                // Day numeral (Gregorian by default; traditional lunar when toggled)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    useLunarDay
                        ? formatTraditionalChineseDay(date.day)
                        : formatGregorianDay(date.day),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      height: 1.15,
                      color: dayTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 1.0),
                // Weekday tag
                Text(
                  formatChineseWeekday(date.weekday),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
