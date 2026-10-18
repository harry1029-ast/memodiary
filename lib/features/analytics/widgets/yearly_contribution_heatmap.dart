import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders a 52-week × 7-day yearly contribution heatmap using a single [CustomPainter].
class YearlyContributionHeatmap extends StatelessWidget {
  final Map<String, int> dailyActivityMap;
  final DateTime? referenceDate;
  final Color? baseColor;

  const YearlyContributionHeatmap({
    super.key,
    required this.dailyActivityMap,
    this.referenceDate,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = baseColor ?? theme.colorScheme.primary;
    final emptyColor = theme.colorScheme.surfaceContainerHighest.withAlpha(140);
    final endDate = referenceDate ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: CustomPaint(
              key: const Key('yearly_contribution_heatmap_canvas'),
              size: const Size(52 * 14.0 + 28.0, 7 * 14.0 + 20.0),
              painter: HeatmapGridPainter(
                dailyActivityMap: dailyActivityMap,
                endDate: endDate,
                activeColor: activeColor,
                emptyColor: emptyColor,
                labelColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            for (final level in [0, 1, 2, 3])
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: HeatmapGridPainter.colorForCount(
                    level,
                    activeColor: activeColor,
                    emptyColor: emptyColor,
                  ),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              'More',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// CustomPainter drawing a 52-week × 7-day grid of rounded activity cells.
class HeatmapGridPainter extends CustomPainter {
  final Map<String, int> dailyActivityMap;
  final DateTime endDate;
  final Color activeColor;
  final Color emptyColor;
  final Color labelColor;

  static const int weeksCount = 52;
  static const int daysPerWeek = 7;
  static const double cellSize = 11.0;
  static const double cellGap = 3.0;
  static const double leftAxisWidth = 26.0;
  static const double topAxisHeight = 18.0;

  HeatmapGridPainter({
    required this.dailyActivityMap,
    required this.endDate,
    required this.activeColor,
    required this.emptyColor,
    required this.labelColor,
  });

  static Color colorForCount(
    int count, {
    required Color activeColor,
    required Color emptyColor,
  }) {
    if (count <= 0) return emptyColor;
    if (count == 1) return activeColor.withAlpha(110);
    if (count == 2) return activeColor.withAlpha(185);
    return activeColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    // Align end column to include normalizedEnd at its weekday row (Mon=0..Sun=6)
    final endWeekdayIndex = normalizedEnd.weekday - 1; // 0 = Mon, 6 = Sun
    final lastWeekMonday =
        normalizedEnd.subtract(Duration(days: endWeekdayIndex));
    final firstWeekMonday =
        lastWeekMonday.subtract(const Duration(days: (weeksCount - 1) * 7));

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final monthFormatter = DateFormat('MMM');
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw weekday labels (Mon, Wed, Fri)
    const dayLabels = {0: 'M', 2: 'W', 4: 'F'};
    dayLabels.forEach((row, text) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 9, color: labelColor),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final dy = topAxisHeight + row * (cellSize + cellGap) + 1;
      tp.paint(canvas, Offset(4, dy));
    });

    int? lastLabeledMonth;

    for (int col = 0; col < weeksCount; col++) {
      final weekStart = firstWeekMonday.add(Duration(days: col * 7));
      final dx = leftAxisWidth + col * (cellSize + cellGap);

      // Draw month header when month changes
      if (weekStart.month != lastLabeledMonth && col < weeksCount - 1) {
        lastLabeledMonth = weekStart.month;
        final monthTp = TextPainter(
          text: TextSpan(
            text: monthFormatter.format(weekStart),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        monthTp.paint(canvas, Offset(dx, 2));
      }

      for (int row = 0; row < daysPerWeek; row++) {
        final cellDate = weekStart.add(Duration(days: row));
        if (cellDate.isAfter(normalizedEnd)) continue;

        final key = dateFormatter.format(cellDate);
        final count = dailyActivityMap[key] ?? 0;

        paint.color = colorForCount(
          count,
          activeColor: activeColor,
          emptyColor: emptyColor,
        );

        final dy = topAxisHeight + row * (cellSize + cellGap);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, dy, cellSize, cellSize),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapGridPainter oldDelegate) {
    return oldDelegate.dailyActivityMap != dailyActivityMap ||
        oldDelegate.endDate != endDate ||
        oldDelegate.activeColor != activeColor;
  }
}
