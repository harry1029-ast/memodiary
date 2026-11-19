import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:memodiary/core/calendar/lunar_calendar.dart';

/// Seven canonical lunar-phase visual buckets across a 30-day synodic month.
enum LunarPhaseBucket {
  newCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  thirdQuarter,
  waningCrescent,
}

/// Maps a Chinese lunar day (`1..30`) into one of the seven [LunarPhaseBucket] phases.
///
/// Out-of-range values are clamped to `[1, 30]`; `null` defaults to [LunarPhaseBucket.newCrescent].
LunarPhaseBucket resolveLunarPhaseBucket(int? lunarDay) {
  if (lunarDay == null) return LunarPhaseBucket.newCrescent;
  final clampedDay = lunarDay.clamp(1, 30);
  if (clampedDay <= 5) return LunarPhaseBucket.newCrescent;
  if (clampedDay <= 10) return LunarPhaseBucket.firstQuarter;
  if (clampedDay <= 13) return LunarPhaseBucket.waxingGibbous;
  if (clampedDay <= 17) return LunarPhaseBucket.fullMoon;
  if (clampedDay <= 21) return LunarPhaseBucket.waningGibbous;
  if (clampedDay <= 25) return LunarPhaseBucket.thirdQuarter;
  return LunarPhaseBucket.waningCrescent;
}

/// Resolves the [LunarPhaseBucket] for a Gregorian [date] via [LunarCalendar],
/// falling back deterministically to `((date.day - 1) % 30) + 1` outside the table range.
LunarPhaseBucket resolveLunarPhaseForDate(DateTime date) {
  final lunarDay = LunarCalendar.fromSolar(date).day ?? (((date.day - 1) % 30) + 1);
  return resolveLunarPhaseBucket(lunarDay);
}

/// Miniature vector lunar-phase icon rendered atop each timeline waist tally.
class LunarPhaseGlyph extends StatelessWidget {
  final LunarPhaseBucket bucket;
  final Color color;
  final double size;

  const LunarPhaseGlyph({
    super.key,
    required this.bucket,
    required this.color,
    this.size = 9.5,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _LunarPhasePainter(
            bucket: bucket,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _LunarPhasePainter extends CustomPainter {
  final LunarPhaseBucket bucket;
  final Color color;

  const _LunarPhasePainter({
    required this.bucket,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;

    final radius = math.max(1.0, (side - 1.0) / 2);
    final center = Offset(size.width / 2, size.height / 2);
    final top = Offset(center.dx, center.dy - radius);
    final bottom = Offset(center.dx, center.dy + radius);

    final fillPaint = Paint()
      ..color = bucket == LunarPhaseBucket.fullMoon
          ? color.withValues(alpha: 0.92)
          : color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final ringAlpha = switch (bucket) {
      LunarPhaseBucket.fullMoon => 0.96,
      LunarPhaseBucket.waxingGibbous || LunarPhaseBucket.waningGibbous => 0.52,
      _ => 0.42,
    };
    final ringPaint = Paint()
      ..color = color.withValues(alpha: ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    if (bucket == LunarPhaseBucket.fullMoon) {
      canvas.drawCircle(center, radius, fillPaint);
    } else {
      canvas.drawPath(
        _buildLitPath(top: top, bottom: bottom, radius: radius),
        fillPaint,
      );
    }
    canvas.restore();

    canvas.drawCircle(center, radius, ringPaint);
  }

  Path _buildLitPath({
    required Offset top,
    required Offset bottom,
    required double radius,
  }) {
    final circular = Radius.circular(radius);
    switch (bucket) {
      case LunarPhaseBucket.newCrescent:
        return Path()
          ..moveTo(top.dx, top.dy)
          ..arcToPoint(bottom, radius: circular, clockwise: true)
          ..arcToPoint(
            top,
            radius: Radius.elliptical(radius * 0.45, radius),
            clockwise: false,
          )
          ..close();
      case LunarPhaseBucket.firstQuarter:
        return Path()
          ..moveTo(top.dx, top.dy)
          ..arcToPoint(bottom, radius: circular, clockwise: true)
          ..close();
      case LunarPhaseBucket.waxingGibbous:
        return Path()
          ..moveTo(top.dx, top.dy)
          ..arcToPoint(bottom, radius: circular, clockwise: true)
          ..arcToPoint(
            top,
            radius: Radius.elliptical(radius * 0.48, radius),
            clockwise: true,
          )
          ..close();
      case LunarPhaseBucket.fullMoon:
        return Path();
      case LunarPhaseBucket.waningGibbous:
        return Path()
          ..moveTo(top.dx, top.dy)
          ..arcToPoint(bottom, radius: circular, clockwise: false)
          ..arcToPoint(
            top,
            radius: Radius.elliptical(radius * 0.48, radius),
            clockwise: false,
          )
          ..close();
      case LunarPhaseBucket.thirdQuarter:
        return Path()
          ..moveTo(top.dx, top.dy)
          ..arcToPoint(bottom, radius: circular, clockwise: false)
          ..close();
      case LunarPhaseBucket.waningCrescent:
        return Path()
          ..moveTo(top.dx, top.dy)
          ..arcToPoint(bottom, radius: circular, clockwise: false)
          ..arcToPoint(
            top,
            radius: Radius.elliptical(radius * 0.45, radius),
            clockwise: true,
          )
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant _LunarPhasePainter oldDelegate) =>
      oldDelegate.bucket != bucket || oldDelegate.color != color;
}
