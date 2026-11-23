import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fenghuang_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'fenghuang_static_architecture.dart';
import 'shanshui_atmospheric_effects.dart';

typedef _RiverLanternSpec = ({
  double initialProgress,
  double laneOffset,
  double phase,
});

/// Dynamic Tuojiang River (`沱江`) layers for Fenghuang (`凤凰`):
/// shimmering golden/red reflections, drifting river mist, wooden punt boats
/// (`乌篷船`), 14 floating pink lotus river lanterns (`沱江河灯`), and ripples.
class FenghuangRiverLayers {
  const FenghuangRiverLayers._();

  static const int riverLanternPoolSize = 14;

  static final List<_RiverLanternSpec> _riverLanternSpecs = List.generate(
    riverLanternPoolSize,
    (index) {
      final random = math.Random(109 + index * 31);
      return (
        initialProgress: (index / riverLanternPoolSize + random.nextDouble() * 0.05) % 1.0,
        laneOffset: (random.nextDouble() - 0.5) * 210.0,
        phase: random.nextDouble() * math.pi * 2,
      );
    },
  );

  /// Returns active wooden punt boat count for [timeOfDay]
  /// (`1` moored/solitary at Dawn & Night, `2` at Day/Dusk).
  static int visibleBoatCount(ShanshuiTimeOfDay timeOfDay) {
    return (timeOfDay == ShanshuiTimeOfDay.day ||
            timeOfDay == ShanshuiTimeOfDay.dusk)
        ? 2
        : 1;
  }

  /// Returns active floating pink lotus river lanterns for [timeOfDay]
  /// (`14` at Dusk/Night, `0` at Dawn/Day).
  static int floatingLanternCount(ShanshuiTimeOfDay timeOfDay) {
    return (timeOfDay == ShanshuiTimeOfDay.dusk ||
            timeOfDay == ShanshuiTimeOfDay.night)
        ? riverLanternPoolSize
        : 0;
  }

  static Path _buildOpenRiverWaterClipPath() {
    return Path()
      ..moveTo(510, 548)
      ..lineTo(1000, 548)
      ..lineTo(1000, 582)
      ..lineTo(1084, 582)
      ..lineTo(1084, 633)
      ..lineTo(1186, 633)
      ..lineTo(1186, 699)
      ..lineTo(1299, 699)
      ..lineTo(1299, 785)
      ..lineTo(1402, 785)
      ..lineTo(1402, 876)
      ..lineTo(1500, 876)
      ..lineTo(1500, 1000)
      ..lineTo(0, 1000)
      ..lineTo(0, 876)
      ..lineTo(108, 876)
      ..lineTo(108, 785)
      ..lineTo(221, 785)
      ..lineTo(221, 699)
      ..lineTo(334, 699)
      ..lineTo(334, 633)
      ..lineTo(431, 633)
      ..lineTo(431, 582)
      ..lineTo(510, 582)
      ..close();
  }

  /// Paints shimmering Hongqiao, celestial, and bank stilt-house reflections
  /// clipped cleanly to the open Tuojiang water channel.
  static void paintRiverReflections(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required FenghuangPalette fenghuangPalette,
    required double animationTime,
    required double celX,
    required double lanternLevel,
  }) {
    const horizon = FenghuangStaticArchitecture.riverHorizonY;
    canvas.save();
    canvas.clipPath(_buildOpenRiverWaterClipPath());

    final centralPaint = Paint();
    final bankPaint = Paint();
    for (double ry = horizon + 8; ry < 985; ry += 8) {
      final prog = (ry - horizon) / 450.0;
      final wave = math.sin(animationTime * 2.8 + ry * 0.14) * (6 + prog * 14);

      if (lanternLevel > 0.25) {
        final alpha = ((0.38 - prog * 0.24) * lanternLevel).clamp(0.0, 1.0);
        centralPaint.color = Color.fromRGBO(255, 185, 70, alpha);
        final bridgeW = 280.0 - prog * 90.0;
        canvas.drawRect(
          Rect.fromLTWH(750.0 - bridgeW / 2 + wave, ry, bridgeW, 3.5),
          centralPaint,
        );
      } else {
        final alpha =
            (0.22 * (1 - prog * 0.6) * atmosphere.weather.celestialAlpha).clamp(0.0, 1.0);
        centralPaint.color = fenghuangPalette.celestialColor.withValues(alpha: alpha);
        final celW = 24.0 + prog * 60.0;
        canvas.drawRect(Rect.fromLTWH(celX - celW / 2 + wave, ry, celW, 2.5), centralPaint);
      }

      if (lanternLevel > 0.2) {
        final bankSpread = 160.0 + prog * 360.0;
        final bankAlpha =
            ((0.42 * lanternLevel) * (0.4 + prog * 0.6)).clamp(0.0, 1.0);
        bankPaint.color = Color.fromRGBO(255, 130, 45, bankAlpha);
        canvas.drawRect(
          Rect.fromLTWH(750.0 - bankSpread - 130.0 + wave, ry, 115.0, 4.0),
          bankPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(750.0 + bankSpread + 15.0 - wave, ry, 115.0, 4.0),
          bankPaint,
        );
      }
    }

    canvas.restore();
  }

  /// Paints drifting morning/cloudy/wet river mist across the emerald Tuojiang water.
  static void paintRiverMist(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required FenghuangPalette fenghuangPalette,
    required double animationTime,
    required double wind,
  }) {
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isWet = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    if (!isDawn && atmosphere.weather != ShanshuiWeather.cloudy && !isWet) {
      return;
    }

    final mistShift = (animationTime * 18 * wind) % 1500.0;
    final mistAlpha = (fenghuangPalette.riverMist.a * (isDawn ? 0.75 : 0.55)).clamp(0.0, 1.0);
    final mistPaint = Paint()
      ..color = fenghuangPalette.riverMist.withValues(alpha: mistAlpha);

    for (int band = -1; band <= 1; band++) {
      final mx = band * 1500.0 + mistShift;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx + 480, 565), width: 580, height: 52),
        mistPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx + 920, 605), width: 680, height: 64),
        mistPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx + 720, 665), width: 760, height: 56),
        mistPaint,
      );
    }
  }

  /// Paints the gliding wooden punt boats (`乌篷船`) with canopies, prow lanterns,
  /// and poling boatmen.
  static void paintTuojiangBoats(
    Canvas canvas, {
    required ShanshuiTimeOfDay timeOfDay,
    required double animationTime,
    required double lanternLevel,
    required bool hasSnowCover,
  }) {
    final isDawn = timeOfDay == ShanshuiTimeOfDay.dawn;
    final boat1X = 685.0 + math.sin(animationTime * 0.4) * 55.0;
    final boat1Y = 635.0 + math.sin(animationTime * 2.0) * 2.5;
    _paintSingleBoat(
      canvas,
      bx: boat1X,
      by: boat1Y,
      scale: 0.78,
      hasBoatman: !isDawn,
      hasSnowCover: hasSnowCover,
      lanternLevel: lanternLevel,
      animationTime: animationTime,
    );

    if (timeOfDay == ShanshuiTimeOfDay.day || timeOfDay == ShanshuiTimeOfDay.dusk) {
      final boat2X = 835.0 - math.cos(animationTime * 0.35) * 48.0;
      final boat2Y = 678.0 + math.cos(animationTime * 2.2) * 2.5;
      _paintSingleBoat(
        canvas,
        bx: boat2X,
        by: boat2Y,
        scale: 0.92,
        hasBoatman: true,
        hasSnowCover: hasSnowCover,
        lanternLevel: lanternLevel,
        animationTime: animationTime,
      );
    }
  }

  static void _paintSingleBoat(
    Canvas canvas, {
    required double bx,
    required double by,
    required double scale,
    required bool hasBoatman,
    required bool hasSnowCover,
    required double lanternLevel,
    required double animationTime,
  }) {
    canvas.save();
    canvas.translate(bx, by);
    canvas.scale(scale, scale);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 116, height: 18),
      Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final hullPath = Path()
      ..moveTo(-55, -6)
      ..quadraticBezierTo(0, 8, 55, -6)
      ..lineTo(42, 7)
      ..quadraticBezierTo(0, 12, -42, 7)
      ..close();
    final outlinePaint = Paint()
      ..color = const Color(0xFF1A0F08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(hullPath, Paint()..color = const Color(0xFF3B2314));
    canvas.drawPath(hullPath, outlinePaint);

    final canopyRect = Rect.fromCircle(center: const Offset(-4, 1), radius: 22);
    canvas.drawArc(
      canopyRect,
      math.pi,
      math.pi,
      true,
      Paint()..color = hasSnowCover ? const Color(0xFFE2E8F0) : const Color(0xFF5C432C),
    );
    canvas.drawArc(canopyRect, math.pi, math.pi, true, outlinePaint);

    if (lanternLevel > 0.25) {
      canvas.drawCircle(
        const Offset(-50, -5),
        14,
        Paint()..color = const Color.fromRGBO(255, 183, 3, 0.35),
      );
      canvas.drawCircle(const Offset(-50, -5), 4, Paint()..color = const Color(0xFFFFB703));
    }

    if (hasBoatman) {
      final figurePaint = Paint()..color = const Color(0xFF26201B);
      canvas.drawCircle(const Offset(36, -14), 4.5, figurePaint);
      canvas.drawRect(const Rect.fromLTWH(32, -9, 8, 12), figurePaint);
      final hatPath = Path()
        ..moveTo(27, -14)
        ..lineTo(36, -20)
        ..lineTo(45, -14)
        ..close();
      canvas.drawPath(hatPath, figurePaint);

      final poleSwing = math.sin(animationTime * 2.1) * 8.0;
      canvas.drawLine(
        const Offset(34, -6),
        Offset(54 + poleSwing, 16),
        Paint()
          ..color = const Color(0xFF8C6D46)
          ..strokeWidth = 2.0,
      );
    }

    canvas.restore();
  }

  /// Paints 14 floating pink lotus river lanterns (`沱江河灯`) drifting downriver
  /// during Dusk and Night hours.
  static void paintFloatingRiverLanterns(
    Canvas canvas, {
    required ShanshuiTimeOfDay timeOfDay,
    required double animationTime,
  }) {
    if (timeOfDay != ShanshuiTimeOfDay.dusk && timeOfDay != ShanshuiTimeOfDay.night) {
      return;
    }

    final petalPaint = Paint()..color = const Color(0xFFF472B6);
    final candlePaint = Paint()..color = const Color(0xFFFEF08A);

    for (final lantern in _riverLanternSpecs) {
      final progress = (lantern.initialProgress + animationTime * 0.048) % 1.0;
      final ry = 835.0 + progress * 155.0;
      final spread = 1.0 + progress * 1.4;
      final rx = 750.0 +
          lantern.laneOffset * spread +
          math.sin(animationTime * 1.5 + lantern.phase) * 12.0;
      final scale = 0.65 + progress * 0.55;

      canvas.save();
      canvas.translate(rx, ry);
      canvas.scale(scale, scale);

      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 4), width: 44, height: 18),
        Paint()
          ..shader = const RadialGradient(
            colors: [
              Color.fromRGBO(255, 230, 130, 0.85),
              Color.fromRGBO(255, 120, 40, 0.35),
              Color.fromRGBO(255, 120, 40, 0),
            ],
            stops: [0.05, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: const Offset(0, 2), radius: 22)),
      );

      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 9),
        petalPaint,
      );
      canvas.drawCircle(const Offset(0, -2), 3.0, candlePaint);
      canvas.restore();
    }
  }

  /// Paints interactive tap ripples and rain-spawned ripples across the river.
  static void paintRiverRipples(
    Canvas canvas, {
    required List<ShanshuiRipple> ripples,
    required bool isWetWeather,
    required bool isStormy,
    required double animationTime,
  }) {
    for (final ripple in ripples) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ripple.x, ripple.y),
          width: ripple.radius * 2,
          height: ripple.radius * 0.50,
        ),
        Paint()
          ..color = Color.fromRGBO(225, 245, 240, ripple.alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    if (isWetWeather) {
      canvas.save();
      canvas.clipPath(_buildOpenRiverWaterClipPath());
      ShanshuiAtmosphericEffects.drawRainPuddleRipples(
        canvas,
        time: animationTime,
        isStormy: isStormy,
        rippleColor: const Color(0xFFE1F5F0),
        minY: 580.0,
        spanY: 380.0,
        minXAt: (_) => 240.0,
        maxXAt: (_) => 1260.0,
        aspectRatio: 0.50,
        strokeWidth: 1.5,
        minRadius: 2.0,
        maxRadiusExpand: isStormy ? 26.0 : 20.0,
        baseAlpha: isStormy ? 0.55 : 0.36,
        seedMultiplier: 79,
      );
      canvas.restore();
    }
  }
}
