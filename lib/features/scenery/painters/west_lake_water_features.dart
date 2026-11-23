import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'shanshui_atmospheric_effects.dart';
import 'west_lake_static_architecture.dart';

/// Dynamic lake features for Hangzhou West Lake (`西湖`): Three Pools Mirroring
/// the Moon, pleasure boat & punt, seasonal Quyuan Lotus Cove, and water ripples.
class WestLakeWaterFeatures {
  const WestLakeWaterFeatures._();

  /// Paints the 3 hollow stone gourd pagodas of Three Pools Mirroring the Moon
  /// (`三潭印月`), including glowing round candle windows and 3 shimmering water
  /// moon reflections when [lanternLevel] > 0.22.
  static void paintThreePoolsPagodas(
    Canvas canvas, {
    required double animationTime,
    required double lanternLevel,
    required bool hasSnowCover,
  }) {
    const pagodas = [(515.0, 655.0, 0.72), (375.0, 712.0, 0.88), (645.0, 725.0, 0.94)];
    for (final (px, py, scale) in pagodas) {
      _paintSinglePoolPagoda(
        canvas, px, py, scale,
        animationTime: animationTime,
        lanternLevel: lanternLevel,
        hasSnowCover: hasSnowCover,
      );
    }
  }

  static void _paintSinglePoolPagoda(
    Canvas canvas,
    double x,
    double y,
    double scale, {
    required double animationTime,
    required double lanternLevel,
    required bool hasSnowCover,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    final rippleW = (34 + math.sin(animationTime * 2 + x) * 4) * 2;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: rippleW, height: 14),
      Paint()
        ..color = const Color.fromRGBO(235, 248, 245, 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    canvas.save();
    canvas.scale(1.0, -0.55);
    final reflPaint = Paint()..color = const Color(0xFF2B3538).withValues(alpha: 0.28);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 32), width: 36, height: 44), reflPaint);
    canvas.drawRect(const Rect.fromLTWH(-6, 50, 12, 35), reflPaint);
    canvas.restore();

    if (lanternLevel > 0.22) {
      const moonOffsets = [-14.0, 0.0, 14.0];
      for (int index = 0; index < moonOffsets.length; index++) {
        final waveX = math.sin(animationTime * 3.1 + index) * 2.5;
        final center = Offset(moonOffsets[index] + waveX, 18);
        final moonRect = Rect.fromCenter(center: center, width: 28, height: 12);
        canvas.drawOval(
          moonRect,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.fromRGBO(255, 238, 160, 0.9 * lanternLevel),
                Color.fromRGBO(255, 175, 65, 0.4 * lanternLevel),
                const Color.fromRGBO(255, 175, 65, 0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(Rect.fromCircle(center: center, radius: 16)),
        );
      }
    }

    const stoneDark = Color(0xFF4A5254);
    const stoneMid = Color(0xFF6E787A);
    final stoneLight = hasSnowCover ? const Color(0xFFF8FAFC) : const Color(0xFF9AA4A6);
    final stroke = Paint()
      ..color = const Color(0xFF2B3133)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 48, height: 12), Paint()..color = stoneDark);
    canvas.drawRect(const Rect.fromLTWH(-12, -14, 24, 14), Paint()..color = stoneMid);

    final bellyRect = Rect.fromCenter(center: const Offset(0, -32), width: 40, height: 36);
    canvas.drawOval(
      bellyRect,
      Paint()
        ..shader = LinearGradient(
          colors: [stoneDark, stoneLight, stoneDark],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(bellyRect),
    );
    canvas.drawOval(bellyRect, stroke);

    for (final wx in const [-10.0, 0.0, 10.0]) {
      final center = Offset(wx, -32);
      if (lanternLevel > 0.22) {
        canvas.drawCircle(
          center,
          9.0,
          Paint()
            ..color = Color.fromRGBO(255, 183, 3, 0.35 * lanternLevel)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(center, 3.8, Paint()..color = const Color(0xFFFFF5B8));
      } else {
        canvas.drawCircle(center, 3.8, Paint()..color = const Color(0xFF2B3436));
      }
    }

    canvas.drawRect(const Rect.fromLTWH(-9, -62, 18, 14), Paint()..color = stoneMid);
    final eaveFill = Paint()..color = hasSnowCover ? const Color(0xFFF8FAFC) : stoneLight;
    for (int tier = 0; tier < 3; tier++) {
      final ey = -52.0 - tier * 7;
      final ew = 22.0 - tier * 3;
      final eaveRect = Rect.fromCenter(center: Offset(0, ey), width: ew * 2, height: 7);
      canvas.drawOval(eaveRect, eaveFill);
      canvas.drawOval(eaveRect, stroke);
    }

    final finialFill = Paint()..color = stoneMid;
    canvas.drawCircle(const Offset(0, -73), 6, finialFill);
    canvas.drawCircle(const Offset(0, -81), 4, finialFill);
    canvas.drawLine(const Offset(0, -85), const Offset(0, -92), stroke);

    canvas.restore();
  }

  /// Paints the West Lake carved pleasure boat (`西湖画舫`) and hand-rowed punt (`手划船`).
  static void paintBoats(
    Canvas canvas, {
    required double animationTime,
    required double lanternLevel,
    required bool hasSnowCover,
    required bool isDawn,
  }) {
    final boat1X = 695.0 + math.sin(animationTime * 0.32) * 48;
    final boat1Y = 592.0 + math.sin(animationTime * 1.9) * 2;
    canvas.save();
    canvas.translate(boat1X, boat1Y);
    canvas.scale(0.76, 0.76);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 10), width: 184, height: 22),
      Paint()
        ..color = const Color.fromRGBO(235, 248, 245, 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final hull1 = Path()
      ..moveTo(-82, -4)
      ..quadraticBezierTo(0, 10, 82, -4)
      ..lineTo(66, 10)
      ..quadraticBezierTo(0, 14, -66, 10)
      ..close();
    canvas.drawPath(hull1, Paint()..color = const Color(0xFF3B2114));

    const cabinRect = Rect.fromLTWH(-46, -28, 92, 24);
    canvas.drawRect(
      cabinRect,
      Paint()..color = lanternLevel > 0.2 ? const Color(0xFFFFE39E) : const Color(0xFFE6D8C3),
    );
    final cabinStroke = Paint()
      ..color = const Color(0xFF4A2816)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cabinRect, cabinStroke);
    for (double wx = -30; wx <= 30; wx += 20) {
      canvas.drawLine(Offset(wx, -28), Offset(wx, -4), cabinStroke);
    }

    WestLakeStaticArchitecture.drawSweepingRoof(
      canvas, 0, -44, 68, 124, 18, const Color(0xFF2B2F33), hasSnowCover, lanternLevel,
    );

    if (lanternLevel > 0.2) {
      final lanternPaint = Paint()..color = const Color(0xFFFF5733);
      canvas.drawCircle(const Offset(-56, -22), 4.5, lanternPaint);
      canvas.drawCircle(const Offset(56, -22), 4.5, lanternPaint);
    }
    canvas.restore();

    final skiffX = 795.0 - math.cos(animationTime * 0.4) * 38;
    final skiffY = 782.0 + math.cos(animationTime * 2.1) * 2.2;
    canvas.save();
    canvas.translate(skiffX, skiffY);
    canvas.scale(0.88, 0.88);

    final hull2 = Path()
      ..moveTo(-48, -5)
      ..quadraticBezierTo(0, 7, 48, -5)
      ..lineTo(36, 7)
      ..quadraticBezierTo(0, 11, -36, 7)
      ..close();
    canvas.drawPath(hull2, Paint()..color = const Color(0xFF3B2314));
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-4, 0), radius: 20),
      math.pi, math.pi, true,
      Paint()..color = hasSnowCover ? const Color(0xFFF1F5F9) : const Color(0xFF6E5239),
    );

    if (!isDawn) {
      final boatmanPaint = Paint()..color = const Color(0xFF26201B);
      canvas.drawCircle(const Offset(30, -13), 4.2, boatmanPaint);
      canvas.drawRect(const Rect.fromLTWH(26, -8, 8, 10), boatmanPaint);
      final oarSwing = math.sin(animationTime * 2.2) * 8;
      canvas.drawLine(
        const Offset(30, -4),
        Offset(48 + oarSwing, 15),
        Paint()
          ..color = const Color(0xFF7A5C3C)
          ..strokeWidth = 2.0,
      );
    }
    canvas.restore();
  }

  /// Paints foreground Quyuan Lotus Cove (`曲院风荷` / `留得枯荷听雨声`).
  static void paintQuyuanLotusCove(
    Canvas canvas, {
    required ShanshuiSeason season,
    required bool hasSnowCover,
    required double animationTime,
  }) {
    const patches = [
      (95.0, 885.0, 42.0), (175.0, 915.0, 48.0), (265.0, 892.0, 38.0),
      (345.0, 935.0, 45.0), (435.0, 910.0, 36.0), (525.0, 945.0, 44.0),
      (1225.0, 895.0, 42.0), (1335.0, 925.0, 48.0), (1435.0, 900.0, 40.0),
    ];

    for (int index = 0; index < patches.length; index++) {
      final (lx, ly, lr) = patches[index];
      if (hasSnowCover) {
        final stem = Path()
          ..moveTo(lx, ly + 18)
          ..lineTo(lx - 8, ly - 24)
          ..lineTo(lx + 12, ly - 12);
        canvas.drawPath(
          stem,
          Paint()
            ..color = const Color(0xFF3A2E28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
        canvas.drawLine(
          Offset(lx, ly + 18),
          Offset(lx - 8, ly + 42),
          Paint()
            ..color = const Color.fromRGBO(40, 35, 30, 0.35)
            ..strokeWidth = 2.6,
        );
        canvas.drawCircle(Offset(lx - 8, ly - 24), 5, Paint()..color = const Color(0xFF4A3B32));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(lx, ly + 12), width: lr * 1.1, height: lr * 0.32),
          Paint()..color = const Color(0xFFF8FAFC),
        );
      } else {
        final padCol = season == ShanshuiSeason.fall
            ? (index.isEven ? const Color(0xFF9E7B42) : const Color(0xFF6E7A4E))
            : (index.isEven ? const Color(0xFF245E43) : const Color(0xFF3B7D5B));
        final padRect = Rect.fromCenter(center: Offset(lx, ly), width: lr * 2, height: lr * 0.64);
        canvas.drawOval(padRect, Paint()..color = padCol);
        canvas.drawOval(
          padRect,
          Paint()
            ..color = const Color.fromRGBO(20, 45, 32, 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );

        if ((season == ShanshuiSeason.summer || season == ShanshuiSeason.spring) && index.isEven) {
          final flX = lx + 6;
          final flY = ly - 14 + math.sin(animationTime * 2 + index) * 2;
          _paintRotatedPetal(canvas, flX - 5, flY, 6, 12, -0.3, const Color(0xFFF48FB1));
          _paintRotatedPetal(canvas, flX + 5, flY, 6, 12, 0.3, const Color(0xFFF48FB1));
          canvas.drawOval(
            Rect.fromCenter(center: Offset(flX, flY - 2), width: 11, height: 26),
            Paint()..color = const Color(0xFFFCE4EC),
          );
        }
      }
    }
  }

  static void _paintRotatedPetal(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
    double angle,
    Color color,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), Paint()..color = color);
    canvas.restore();
  }

  /// Paints interactive touch ripples and deterministic rain-drop lake ripples.
  static void paintLakeRipples(
    Canvas canvas, {
    required List<ShanshuiRipple> ripples,
    required bool isWetWeather,
    required bool isStormy,
    required double animationTime,
  }) {
    for (final ripple in ripples) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ripple.x, ripple.y), width: ripple.radius * 2, height: ripple.radius * 0.48),
        Paint()
          ..color = Color.fromRGBO(225, 245, 240, ripple.alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    if (isWetWeather) {
      ShanshuiAtmosphericEffects.drawRainPuddleRipples(
        canvas,
        time: animationTime,
        isStormy: isStormy,
        rippleColor: const Color(0xFFE1F5F0),
        minY: 550.0,
        spanY: 410.0,
        minXAt: (_) => 150.0,
        maxXAt: (_) => 1350.0,
        aspectRatio: 0.48,
        strokeWidth: 1.5,
        minRadius: 2.0,
        maxRadiusExpand: isStormy ? 26.0 : 20.0,
        baseAlpha: isStormy ? 0.55 : 0.36,
        seedMultiplier: 89,
      );
    }
  }
}
