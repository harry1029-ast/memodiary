import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/west_lake_palette.dart';

/// Static architectural and topographic geometry renderer for Hangzhou West Lake (`西湖`).
///
/// Renders distant northern hills, Baochu Pagoda, wooded Xizhao Hill, 5-story
/// octagonal Leifeng Pagoda, and the West Lake water base gradient into an
/// immutable `ui.Picture` backdrop.
class WestLakeStaticArchitecture {
  const WestLakeStaticArchitecture._();

  static const double waterHorizonY = 515.0;
  static const double leifengX = 1075.0;
  static const double leifengBaseY = 352.0;

  /// Effective illumination factor (`0.0..1.0`) combining time-of-day candle
  /// intensity with rainy/stormy darkening.
  static double effectiveLanternLevel(
    WestLakePalette palette,
    ShanshuiWeather weather,
  ) {
    final isWetWeather =
        weather == ShanshuiWeather.rainy || weather == ShanshuiWeather.stormy;
    return (palette.candleIntensity + (isWetWeather ? 0.35 : 0.0)).clamp(0.0, 1.0);
  }

  /// Paints the static hills, Baochu Pagoda, Xizhao Hill, Leifeng Pagoda, and
  /// West Lake water base gradient for caching inside a `ui.Picture`.
  static void paintStaticBackdrop(
    Canvas canvas,
    Size size, {
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
  }) {
    final hasSnowCover = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final lanternLevel = effectiveLanternLevel(westLakePalette, atmosphere.weather);

    _paintHillsAndBaochu(canvas, westLakePalette, hasSnowCover: hasSnowCover, isNight: isNight);
    _paintXizhaoHillAndLeifeng(
      canvas,
      westLakePalette,
      hasSnowCover: hasSnowCover,
      isDusk: isDusk,
      lanternLevel: lanternLevel,
    );
    _paintLakeBase(canvas, westLakePalette, isNight: isNight);
  }

  static void _paintHillsAndBaochu(
    Canvas canvas,
    WestLakePalette palette, {
    required bool hasSnowCover,
    required bool isNight,
  }) {
    const farHills = [
      Offset(0, 515), Offset(95, 360), Offset(210, 315), Offset(335, 345),
      Offset(445, 285), Offset(555, 365), Offset(685, 395), Offset(820, 355),
      Offset(945, 390), Offset(1120, 310), Offset(1285, 355), Offset(1410, 395),
      Offset(1500, 420), Offset(1500, 520), Offset(0, 520),
    ];
    final hillColor = hasSnowCover ? const Color(0xFFCBD5E1) : palette.mtnMid;
    canvas.drawPath(
      Path()..addPolygon(farHills, true),
      Paint()..color = hillColor.withValues(alpha: isNight ? 0.52 : 0.72),
    );

    // Slender Baochu Pagoda on Baoshi Hill (宝石山保俶塔)
    const bcX = 445.0;
    const bcY = 288.0;
    final baochuBody = Path()
      ..moveTo(bcX - 6, bcY)
      ..lineTo(bcX - 3.5, bcY - 48)
      ..lineTo(bcX + 3.5, bcY - 48)
      ..lineTo(bcX + 6, bcY)
      ..close();
    final baochuColor = isNight ? const Color(0xFF94A3B8) : const Color(0xFF786E65);
    canvas.drawPath(baochuBody, Paint()..color = baochuColor.withValues(alpha: 0.85));
    canvas.drawLine(
      const Offset(bcX, bcY - 48),
      const Offset(bcX, bcY - 64),
      Paint()
        ..color = const Color(0xFF3B3530).withValues(alpha: 0.85)
        ..strokeWidth = 1.5,
    );
  }

  static void _paintXizhaoHillAndLeifeng(
    Canvas canvas,
    WestLakePalette palette, {
    required bool hasSnowCover,
    required bool isDusk,
    required double lanternLevel,
  }) {
    const xizhaoPoints = [
      Offset(775, 520), Offset(865, 445), Offset(965, 378), Offset(1075, 342),
      Offset(1165, 355), Offset(1285, 415), Offset(1420, 465), Offset(1500, 490),
      Offset(1500, 525), Offset(775, 525),
    ];
    canvas.drawPath(
      Path()..addPolygon(xizhaoPoints, true),
      Paint()..color = hasSnowCover ? const Color(0xFFE2E8F0) : palette.mtnBase,
    );

    const clusters = [
      (955.0, 398.0, 34.0),
      (1010.0, 375.0, 38.0),
      (1145.0, 372.0, 40.0),
      (1205.0, 395.0, 36.0),
      (1265.0, 420.0, 34.0),
    ];
    for (int index = 0; index < clusters.length; index++) {
      final (tx, ty, tr) = clusters[index];
      final col = index.isEven ? palette.foliagePrimary : palette.foliageSecondary;
      paintFoliageCluster(canvas, tx, ty, tr, col, hasSnowCover);
    }

    // Golden dusk/night backlight behind Leifeng Pagoda (雷峰夕照)
    if (isDusk || lanternLevel > 0.3) {
      final alpha = isDusk ? 0.65 : 0.45 * lanternLevel;
      final glowRect = Rect.fromCircle(center: const Offset(leifengX, leifengBaseY - 75), radius: 135);
      canvas.drawCircle(
        const Offset(leifengX, leifengBaseY - 75),
        135,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.fromRGBO(255, 195, 75, alpha),
              const Color.fromRGBO(255, 140, 40, 0),
            ],
          ).createShader(glowRect),
      );
    }

    canvas.drawRect(
      const Rect.fromLTWH(leifengX - 42, leifengBaseY - 12, 84, 14),
      Paint()..color = const Color(0xFF4A433C),
    );

    final wallFill = Paint()
      ..color = lanternLevel > 0.22 ? const Color(0xFFFFE396) : const Color(0xFF6E4730);
    final wallStroke = Paint()
      ..color = const Color(0xFF2B1B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int tier = 0; tier < 5; tier++) {
      final tw = 64.0 - tier * 8.5;
      final th = 22.0 - tier * 1.4;
      final ty = leifengBaseY - 12 - (tier + 1) * th - tier * 4;
      final storyRect = Rect.fromLTWH(leifengX - tw / 2, ty, tw, th);
      canvas.drawRect(storyRect, wallFill);
      canvas.drawRect(storyRect, wallStroke);

      for (final colFrac in const [-0.35, 0.0, 0.35]) {
        final colX = leifengX + tw * colFrac;
        canvas.drawLine(Offset(colX, ty), Offset(colX, ty + th), wallStroke);
      }

      drawSweepingRoof(
        canvas, leifengX, ty - 8, tw * 0.85, tw * 1.48, 11,
        const Color(0xFF362D26), hasSnowCover, lanternLevel,
      );
    }

    const spireBaseY = leifengBaseY - 142.0;
    canvas.drawLine(
      const Offset(leifengX, spireBaseY),
      const Offset(leifengX, spireBaseY - 26),
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..strokeWidth = 3.2,
    );
    canvas.drawCircle(const Offset(leifengX, spireBaseY - 12), 4, Paint()..color = const Color(0xFFF5C542));
  }

  static void _paintLakeBase(Canvas canvas, WestLakePalette palette, {required bool isNight}) {
    const lakeRect = Rect.fromLTWH(0, waterHorizonY, 1500, 1000 - waterHorizonY);
    final colors = isNight
        ? const [Color(0xFF162C38), Color(0xFF10212B), Color(0xFF09151C)]
        : [palette.lakeTop, palette.lakeBottom, const Color(0xFF12332E)];
    canvas.drawRect(
      lakeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(lakeRect),
    );
  }

  /// Paints an organic 5-blob foliage cluster with optional winter snow cap.
  static void paintFoliageCluster(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Color color,
    bool isSnowCapped,
  ) {
    final fill = Paint()..color = color.withValues(alpha: 0.9);
    final blobs = [
      (0.0, 0.0, radius),
      (-radius * 0.55, radius * 0.15, radius * 0.76),
      (radius * 0.55, radius * 0.18, radius * 0.72),
      (0.0, -radius * 0.45, radius * 0.68),
      (-radius * 0.35, -radius * 0.28, radius * 0.62),
    ];
    for (final (bx, by, br) in blobs) {
      canvas.drawCircle(Offset(cx + bx, cy + by), br, fill);
    }

    if (isSnowCapped) {
      final snowPaint = Paint()..color = const Color(0xFFF8FAFC).withValues(alpha: 0.94);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy - radius * 0.32), radius: radius * 0.65),
        math.pi, math.pi, true, snowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - radius * 0.45, cy - radius * 0.05), radius: radius * 0.48),
        math.pi, math.pi, true, snowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + radius * 0.45, cy), radius: radius * 0.48),
        math.pi, math.pi, true, snowPaint,
      );
    }
  }

  /// Paints a curved upturned Jiangnan roof with optional snow cover and night
  /// golden eave contour lighting.
  static void drawSweepingRoof(
    Canvas canvas,
    double cx,
    double yTop,
    double topW,
    double botW,
    double height,
    Color roofFill,
    bool isSnowCapped,
    double nightLightLevel,
  ) {
    final halfTop = topW / 2;
    final halfBot = botW / 2;
    final path = Path()
      ..moveTo(cx - halfTop, yTop)
      ..lineTo(cx + halfTop, yTop)
      ..quadraticBezierTo(cx + halfTop + (halfBot - halfTop) * 0.55, yTop + height * 0.85, cx + halfBot + 14, yTop + height * 0.42)
      ..lineTo(cx + halfBot, yTop + height)
      ..lineTo(cx - halfBot, yTop + height)
      ..lineTo(cx - halfBot - 14, yTop + height * 0.42)
      ..quadraticBezierTo(cx - halfTop - (halfBot - halfTop) * 0.55, yTop + height * 0.85, cx - halfTop, yTop)
      ..close();

    canvas.drawPath(path, Paint()..color = isSnowCapped ? const Color(0xFFF1F5F9) : roofFill);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1C140E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    if (nightLightLevel > 0.35) {
      final glowPath = Path()
        ..moveTo(cx - halfBot - 12, yTop + height * 0.46)
        ..quadraticBezierTo(cx, yTop + height + 3, cx + halfBot + 12, yTop + height * 0.46);
      canvas.drawPath(
        glowPath,
        Paint()
          ..color = Color.fromRGBO(255, 200, 85, (nightLightLevel * 0.88).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }
}
