import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/shapes/classical_chinese_borders.dart';

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
  final VoidCallback? onTapBadge;

  const TimelineDateSpineItem({
    super.key,
    required this.date,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.isHighlighted = false,
    this.onTapBadge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Continuous Vertical Axis Spine Line
        Positioned(
          left: 36,
          top: isFirst ? 20 : 0,
          bottom: isLast ? 36 : 0,
          child: Container(
            width: 2.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.0),
              gradient: isFirst
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tokens.cinnabar.withValues(alpha: 0.8),
                        tokens.deckleBorder,
                      ],
                    )
                  : null,
              color: isFirst ? null : tokens.deckleBorder,
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
              _buildWaistTallyBadge(
                context: context,
                tokens: tokens,
                isDark: isDark,
              ),
              const SizedBox(height: 3),
              // Connecting Diamond Node Knot (Pan-Chang Knot Node on the Silk Cord)
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? tokens.cinnabar
                        : (isDark ? tokens.danmo : const Color(0xFFB5A487)),
                    border: Border.all(
                      color: tokens.xuanGround,
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
    required BuildContext context,
    required InkDiaryTokens tokens,
    required bool isDark,
  }) {
    final borderColor = isHighlighted
        ? const Color(0xFF6E180F)
        : (isDark ? tokens.deckleBorder : const Color(0xFFB5A487));

    final innerBorderColor = isHighlighted
        ? const Color(0xFFF8ECE0).withValues(alpha: 0.35)
        : (isDark
            ? tokens.qingmo.withValues(alpha: 0.25)
            : const Color(0xFFFCF9F2).withValues(alpha: 0.8));

    final tallyBorder = WaistTallyBorder(
      cutSize: 7.0,
      cordHoleRadius: 2.2,
      borderColor: borderColor,
      borderWidth: 1.0,
      innerBorderColor: innerBorderColor,
    );

    final gradient = isHighlighted
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC23E30), Color(0xFFA42B1E)],
          )
        : (isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E2B27), Color(0xFF1F1D1A)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7F2E6), Color(0xFFE5D7BC)],
              ));

    final shadowColor = isHighlighted
        ? const Color(0xFFA82E21).withValues(alpha: 0.35)
        : const Color(0xFF2A261E).withValues(alpha: isDark ? 0.3 : 0.1);

    return Tooltip(
      message: '${date.year}年${date.month}月${date.day}日 ${formatChineseWeekday(date.weekday)}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: tallyBorder,
          onTap: onTapBadge,
          child: Container(
            width: 52,
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
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
                // Month label (clean sans-serif)
                Text(
                  '${date.month}月',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.1,
                    color: isHighlighted
                        ? const Color(0xFFFDE8E5)
                        : tokens.danmo,
                  ),
                ),
                const SizedBox(height: 1.0),
                // Traditional Chinese day numeral
                Text(
                  formatTraditionalChineseDay(date.day),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1.15,
                    color: isHighlighted
                        ? Colors.white
                        : tokens.jiaomo,
                  ),
                ),
                const SizedBox(height: 1.0),
                // Weekday tag
                Text(
                  formatChineseWeekday(date.weekday),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: isHighlighted
                        ? const Color(0xFFFCE2DF).withValues(alpha: 0.9)
                        : tokens.danmo,
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
