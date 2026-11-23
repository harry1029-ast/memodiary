import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fenghuang_palette.dart';
import '../models/shanshui_atmosphere.dart';
import 'fenghuang_architecture_layers.dart';

/// Static architectural and topographic renderer for Xiangxi Fenghuang (`凤凰`).
///
/// Draws NanHua & Wuling karst hills, the emerald Tuojiang River base gradient,
/// 7-tiered hexagonal white Wanming Pagoda (`万名塔`), 3-arch Hongqiao Wind &
/// Rain Covered Bridge (`虹桥风雨楼`), riverbank trees, and 10 perspective
/// multi-story wooden stilt houses (`湘西吊脚楼群`) into an immutable `ui.Picture`.
class FenghuangStaticArchitecture {
  const FenghuangStaticArchitecture._();

  static const double riverHorizonY = 535.0;
  static const double hongqiaoCenterX = 750.0;
  static const double hongqiaoWaterY = 548.0;
  static const double pagodaCenterX = 1015.0;
  static const double pagodaBaseY = 540.0;

  /// Effective illumination factor (`0.0..1.0`) combining time-of-day candle
  /// intensity with rainy/stormy darkening.
  static double effectiveLanternLevel(
    FenghuangPalette palette,
    ShanshuiWeather weather,
  ) {
    final isWetWeather =
        weather == ShanshuiWeather.rainy || weather == ShanshuiWeather.stormy;
    return (palette.candleIntensity + (isWetWeather ? 0.35 : 0.0)).clamp(0.0, 1.0);
  }

  /// Paints the static Fenghuang landscape and architecture into [canvas].
  static void paintStaticBackdrop(
    Canvas canvas,
    Size size, {
    required ShanshuiAtmosphereState atmosphere,
    required FenghuangPalette fenghuangPalette,
  }) {
    final hasSnowCover = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final lanternLevel = effectiveLanternLevel(fenghuangPalette, atmosphere.weather);

    _paintKarstHills(canvas, fenghuangPalette, hasSnowCover: hasSnowCover, isNight: isNight);
    _paintRiverBase(canvas, fenghuangPalette, isNight: isNight);
    _paintWanmingPagoda(
      canvas,
      hasSnowCover: hasSnowCover,
      isNight: isNight,
      lanternLevel: lanternLevel,
    );
    _paintHongqiaoBridge(
      canvas,
      hasSnowCover: hasSnowCover,
      isNight: isNight,
      lanternLevel: lanternLevel,
    );
    FenghuangArchitectureLayers.paintBankTreesAndStiltHouses(
      canvas,
      fenghuangPalette,
      hasSnowCover: hasSnowCover,
      lanternLevel: lanternLevel,
    );
  }

  static void _paintKarstHills(
    Canvas canvas,
    FenghuangPalette palette, {
    required bool hasSnowCover,
    required bool isNight,
  }) {
    const farRidge = [
      Offset(0, 480), Offset(180, 290), Offset(340, 235), Offset(490, 310),
      Offset(640, 195), Offset(780, 260), Offset(920, 180), Offset(1080, 275),
      Offset(1240, 210), Offset(1500, 320), Offset(1500, 520), Offset(0, 520),
    ];
    canvas.drawPath(
      Path()..addPolygon(farRidge, true),
      Paint()
        ..color = (hasSnowCover ? const Color(0xFFCBD5E1) : palette.mtnMid)
            .withValues(alpha: isNight ? 0.45 : 0.65),
    );

    const nearRidge = [
      Offset(0, 500), Offset(120, 340), Offset(290, 285), Offset(460, 355),
      Offset(610, 275), Offset(750, 330), Offset(890, 265), Offset(1050, 345),
      Offset(1220, 280), Offset(1500, 365), Offset(1500, riverHorizonY), Offset(0, riverHorizonY),
    ];
    canvas.drawPath(
      Path()..addPolygon(nearRidge, true),
      Paint()
        ..color = (hasSnowCover ? const Color(0xFFE2E8F0) : palette.mtnBase)
            .withValues(alpha: isNight ? 0.65 : 0.85),
    );
  }

  static void _paintRiverBase(
    Canvas canvas,
    FenghuangPalette palette, {
    required bool isNight,
  }) {
    const riverRect = Rect.fromLTWH(0, riverHorizonY, 1500, 1000 - riverHorizonY);
    final colors = isNight
        ? const [Color(0xFF132832), Color(0xFF0E1F28), Color(0xFF08131A)]
        : [palette.riverTop, palette.riverBottom, const Color(0xFF0F2E28)];
    canvas.drawRect(
      riverRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: isNight ? const [0.0, 0.5, 1.0] : const [0.0, 0.55, 1.0],
        ).createShader(riverRect),
    );
  }

  static void _paintWanmingPagoda(
    Canvas canvas, {
    required bool hasSnowCover,
    required bool isNight,
    required double lanternLevel,
  }) {
    canvas.drawRect(
      const Rect.fromLTWH(pagodaCenterX - 26, pagodaBaseY - 14, 52, 16),
      Paint()..color = const Color(0xFF5C5449),
    );

    final bodyPaint = Paint()
      ..color = isNight ? const Color(0xFFCBD5E1) : const Color(0xFFF5F2EB);
    final bodyStroke = Paint()
      ..color = const Color(0xFF2B231D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    double currentTopY = pagodaBaseY - 14;
    for (int tier = 0; tier < 7; tier++) {
      final tierW = 38.0 - tier * 4.2;
      final tierH = 16.0 - tier * 0.8;
      currentTopY -= tierH;
      final tierRect = Rect.fromLTWH(pagodaCenterX - tierW / 2, currentTopY, tierW, tierH);
      canvas.drawRect(tierRect, bodyPaint);
      canvas.drawRect(tierRect, bodyStroke);
      drawSweepingRoof(
        canvas,
        pagodaCenterX,
        currentTopY - 5,
        tierW * 0.8,
        tierW * 1.38,
        7,
        const Color(0xFF2D3136),
        hasSnowCover,
        lanternLevel,
      );
    }

    final spireBottomY = currentTopY - 5;
    canvas.drawLine(
      Offset(pagodaCenterX, spireBottomY),
      Offset(pagodaCenterX, spireBottomY - 20),
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..strokeWidth = 2.5,
    );
  }

  static void _paintHongqiaoBridge(
    Canvas canvas, {
    required bool hasSnowCover,
    required bool isNight,
    required double lanternLevel,
  }) {
    final pierPath = Path()
      ..moveTo(hongqiaoCenterX - 235, hongqiaoWaterY)
      ..lineTo(hongqiaoCenterX - 235, hongqiaoWaterY - 58)
      ..lineTo(hongqiaoCenterX + 235, hongqiaoWaterY - 58)
      ..lineTo(hongqiaoCenterX + 235, hongqiaoWaterY)
      ..arcTo(
        Rect.fromCircle(center: const Offset(hongqiaoCenterX + 125, hongqiaoWaterY), radius: 42),
        0, -math.pi, false,
      )
      ..arcTo(
        Rect.fromCircle(center: const Offset(hongqiaoCenterX, hongqiaoWaterY), radius: 52),
        0, -math.pi, false,
      )
      ..arcTo(
        Rect.fromCircle(center: const Offset(hongqiaoCenterX - 125, hongqiaoWaterY), radius: 42),
        0, -math.pi, false,
      )
      ..close();

    canvas.drawPath(
      pierPath,
      Paint()..color = isNight ? const Color(0xFF3D2E28) : const Color(0xFF7A4E3E),
    );
    final outlinePaint = Paint()
      ..color = const Color(0xFF241610)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(pierPath, outlinePaint);

    const corridorRect = Rect.fromLTWH(hongqiaoCenterX - 220, hongqiaoWaterY - 102, 440, 44);
    final timberPaint = Paint()..color = const Color(0xFF4A2C1B);
    canvas.drawRect(corridorRect, timberPaint);
    canvas.drawRect(corridorRect, outlinePaint);

    final windowColor =
        lanternLevel > 0.2 ? const Color(0xFFFFE094) : const Color(0xFF786250);
    final windowPaint = Paint()..color = windowColor;
    for (double bx = -195; bx <= 195; bx += 30) {
      canvas.drawRect(
        Rect.fromLTWH(hongqiaoCenterX + bx - 9, hongqiaoWaterY - 92, 18, 24),
        windowPaint,
      );
    }

    drawSweepingRoof(
      canvas, hongqiaoCenterX - 135, hongqiaoWaterY - 122, 130, 185, 22,
      const Color(0xFF2B2E33), hasSnowCover, lanternLevel,
    );
    drawSweepingRoof(
      canvas, hongqiaoCenterX + 135, hongqiaoWaterY - 122, 130, 185, 22,
      const Color(0xFF2B2E33), hasSnowCover, lanternLevel,
    );

    canvas.drawRect(
      const Rect.fromLTWH(hongqiaoCenterX - 68, hongqiaoWaterY - 134, 136, 32),
      timberPaint,
    );
    canvas.drawRect(
      const Rect.fromLTWH(hongqiaoCenterX - 48, hongqiaoWaterY - 128, 96, 20),
      Paint()
        ..color = lanternLevel > 0.2 ? const Color(0xFFFFE5A3) : const Color(0xFF786250),
    );
    drawSweepingRoof(
      canvas, hongqiaoCenterX, hongqiaoWaterY - 162, 95, 185, 30,
      const Color(0xFF2B2E33), hasSnowCover, lanternLevel,
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

  /// Paints a curved upturned Xiangxi roof with perspective tile ribs, snow
  /// blanket, and golden night roof-ridge lights when [nightLightLevel] > 0.35.
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
        ..strokeWidth = 2.0,
    );

    if (!isSnowCapped) {
      final ribPaint = Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.12)
        ..strokeWidth = 1.1;
      for (double rx = -halfBot + 10; rx < halfBot; rx += 11) {
        canvas.drawLine(
          Offset(cx + rx * (topW / botW), yTop + 2),
          Offset(cx + rx, yTop + height - 2),
          ribPaint,
        );
      }
    }

    if (nightLightLevel > 0.35) {
      final glowPath = Path()
        ..moveTo(cx - halfBot - 12, yTop + height * 0.46)
        ..quadraticBezierTo(cx, yTop + height + 3, cx + halfBot + 12, yTop + height * 0.46);
      canvas.drawPath(
        glowPath,
        Paint()
          ..color = Color.fromRGBO(255, 195, 75, (nightLightLevel * 0.88).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
  }
}
