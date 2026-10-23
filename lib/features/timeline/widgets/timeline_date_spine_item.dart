import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';

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

        // 3. Left Date Marker Stamp Badge & Connecting Ink Pip
        Positioned(
          left: 12,
          top: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: '${date.year}年${date.month}月${date.day}日 ${formatChineseWeekday(date.weekday)}',
                child: InkWell(
                  onTap: onTapBadge,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? tokens.cinnabar
                          : (isDark ? tokens.xuanPureLeaf : tokens.agedFiber),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHighlighted
                            ? tokens.cinnabar
                            : tokens.deckleBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isHighlighted
                              ? tokens.cinnabar.withValues(alpha: 0.28)
                              : tokens.jiaomo.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Month label
                        Text(
                          '${date.month}月',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            height: 1.1,
                            color: isHighlighted
                                ? tokens.cinnabarWash
                                : tokens.danmo,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        // Traditional Chinese day numeral
                        Text(
                          formatTraditionalChineseDay(date.day),
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            height: 1.15,
                            color: isHighlighted
                                ? Colors.white
                                : tokens.jiaomo,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        // Weekday tag
                        Text(
                          formatChineseWeekday(date.weekday),
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 8.5,
                            height: 1.1,
                            color: isHighlighted
                                ? tokens.cinnabarWash.withValues(alpha: 0.85)
                                : tokens.danmo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Connecting Ink Pip Dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHighlighted
                      ? tokens.cinnabar
                      : (isDark ? tokens.danmo : tokens.qingmo),
                  border: Border.all(
                    color: tokens.xuanGround,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
