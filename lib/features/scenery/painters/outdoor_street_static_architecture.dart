import 'package:flutter/material.dart';
import '../models/outdoor_street_palette.dart';
import '../models/shanshui_atmosphere.dart';
import 'outdoor_street_shop_layers.dart';

/// Static architectural geometry renderer for the Outdoor Ancient Market Street (`街市`).
///
/// Records static elements (towering Cunfa mountain peak, base groves,
/// stone-paved avenue, four-pillar Paifang gate with roof tile ribs, and
/// two-story shopfronts with plaques & couplets) into an immutable `ui.Picture`
/// layer to maintain 60 FPS performance.
class OutdoorStreetStaticArchitecture {
  const OutdoorStreetStaticArchitecture._();

  /// Stone-paved market avenue trapezoid in 1500x1000 vector coordinates.
  static Path buildAvenuePath() {
    return Path()
      ..moveTo(560, 580)
      ..lineTo(940, 580)
      ..lineTo(1500, 940)
      ..lineTo(1500, 1000)
      ..lineTo(0, 1000)
      ..lineTo(0, 940)
      ..close();
  }

  /// Paints the static background and architectural geometry onto [canvas]
  /// normalized to standard 1500 x 1000 coordinates.
  static void paintStaticArchitecture(
    Canvas canvas,
    Size size, {
    required ShanshuiAtmosphereState atmosphere,
    required OutdoorStreetPalette streetPalette,
  }) {
    final isWinter = atmosphere.season == ShanshuiSeason.winter;
    final isSnowy = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnow = isWinter || isSnowy;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;

    _paintMountains(canvas, streetPalette, hasSnow: hasSnow, isNight: isNight);
    _paintAvenue(canvas, hasSnow: hasSnow, isNight: isNight);
    _paintPaifangGate(canvas, streetPalette, hasSnow: hasSnow, isNight: isNight);
    OutdoorStreetShopLayers.paintShopfronts(
      canvas,
      streetPalette,
      hasSnow: hasSnow,
      isNight: isNight,
    );
  }

  // ===========================================================================
  // 1. Mountains, Cunfa Crags & Base Foliage Groves
  // ===========================================================================
  static void _paintMountains(
    Canvas canvas,
    OutdoorStreetPalette palette, {
    required bool hasSnow,
    required bool isNight,
  }) {
    final leftPeak = Path()
      ..moveTo(280, 420)
      ..lineTo(455, 212)
      ..lineTo(535, 275)
      ..lineTo(580, 420)
      ..close();

    final rightPeak = Path()
      ..moveTo(920, 420)
      ..lineTo(985, 222)
      ..lineTo(1045, 205)
      ..lineTo(1220, 315)
      ..lineTo(1250, 420)
      ..close();

    final secPeakPaint = Paint()
      ..color = hasSnow ? const Color(0xFFCBD5E1) : palette.mtnMid
      ..style = PaintingStyle.fill;
    final secPeakStroke = Paint()
      ..color = const Color(0xFF2B231D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(leftPeak, secPeakPaint);
    canvas.drawPath(leftPeak, secPeakStroke);
    canvas.drawPath(rightPeak, secPeakPaint);
    canvas.drawPath(rightPeak, secPeakStroke);

    final mainPeakPath = Path()
      ..moveTo(375, 460)
      ..lineTo(490, 295)
      ..lineTo(585, 195)
      ..lineTo(678, 108)
      ..lineTo(725, 86)
      ..lineTo(765, 92)
      ..lineTo(818, 152)
      ..lineTo(915, 245)
      ..lineTo(1035, 345)
      ..lineTo(1140, 460)
      ..close();

    final mtnGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: hasSnow
          ? const [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFF64748B)]
          : [palette.mtnTop, palette.mtnMid, palette.mtnBase],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(const Rect.fromLTWH(0, 85, 1500, 375));

    canvas.drawPath(mainPeakPath, Paint()..shader = mtnGrad);
    canvas.drawPath(
      mainPeakPath,
      Paint()
        ..color = const Color(0xFF2B221B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    canvas.save();
    canvas.clipPath(mainPeakPath);

    final highlightPath = Path()
      ..moveTo(725, 86)
      ..lineTo(765, 92)
      ..lineTo(960, 340)
      ..lineTo(815, 360)
      ..close();
    final highlightPaint = Paint()
      ..color = hasSnow
          ? const Color.fromRGBO(255, 255, 255, 0.85)
          : isNight
              ? const Color.fromRGBO(180, 205, 230, 0.16)
              : const Color.fromRGBO(245, 222, 175, 0.38);
    canvas.drawPath(highlightPath, highlightPaint);

    final cragPaint = Paint()
      ..color = palette.mtnCrag.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    const cragLines = [
      [Offset(725, 86), Offset(685, 195), Offset(610, 340)],
      [Offset(745, 90), Offset(740, 210), Offset(775, 345)],
      [Offset(760, 95), Offset(825, 225), Offset(895, 355)],
      [Offset(678, 108), Offset(615, 220), Offset(520, 350)],
      [Offset(818, 152), Offset(875, 260), Offset(975, 365)],
    ];
    for (final line in cragLines) {
      final path = Path()..moveTo(line[0].dx, line[0].dy);
      for (int index = 1; index < line.length; index++) {
        path.lineTo(line[index].dx, line[index].dy);
      }
      canvas.drawPath(path, cragPaint);
    }
    canvas.restore();

    const treeGroves = [
      [445.0, 345.0, 42.0],
      [495.0, 365.0, 46.0],
      [545.0, 392.0, 44.0],
      [595.0, 415.0, 38.0],
      [910.0, 412.0, 40.0],
      [965.0, 388.0, 46.0],
      [1025.0, 365.0, 44.0],
    ];
    for (int index = 0; index < treeGroves.length; index++) {
      final grove = treeGroves[index];
      final col = index % 3 == 0
          ? palette.foliagePrimary
          : index % 3 == 1
              ? palette.foliageSecondary
              : palette.foliageAccent;
      _paintFoliageCluster(canvas, grove[0], grove[1], grove[2], col, hasSnow: hasSnow);
    }
  }

  static void _paintFoliageCluster(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Color color, {
    required bool hasSnow,
  }) {
    final fillPaint = Paint()..color = color.withValues(alpha: 0.92);
    final blobs = [
      Offset(cx, cy),
      Offset(cx - r * 0.55, cy + r * 0.15),
      Offset(cx + r * 0.55, cy + r * 0.18),
      Offset(cx, cy - r * 0.45),
      Offset(cx - r * 0.35, cy - r * 0.28),
    ];
    final radii = [r, r * 0.76, r * 0.72, r * 0.68, r * 0.62];
    for (int index = 0; index < blobs.length; index++) {
      canvas.drawCircle(blobs[index], radii[index], fillPaint);
    }

    final outlinePaint = Paint()
      ..color = const Color.fromRGBO(35, 25, 20, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy - r * 0.2), radius: r * 0.85),
      0.9 * 3.14159,
      1.2 * 3.14159,
      false,
      outlinePaint,
    );

    if (hasSnow) {
      final snowPaint = Paint()..color = const Color(0xFFF8FAFC).withValues(alpha: 0.94);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy - r * 0.32), radius: r * 0.65),
        3.14159,
        3.14159,
        true,
        snowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - r * 0.45, cy - r * 0.05), radius: r * 0.48),
        3.14159,
        3.14159,
        true,
        snowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + r * 0.45, cy), radius: r * 0.48),
        3.14159,
        3.14159,
        true,
        snowPaint,
      );
    }
  }

  // ===========================================================================
  // 2. Perspective Stone-Paved Market Avenue
  // ===========================================================================
  static void _paintAvenue(
    Canvas canvas, {
    required bool hasSnow,
    required bool isNight,
  }) {
    final streetPath = buildAvenuePath();

    final streetGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: hasSnow
          ? const [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)]
          : isNight
              ? const [Color(0xFF4A4642), Color(0xFF383430), Color(0xFF262320)]
              : const [Color(0xFFF5DEC0), Color(0xFFDFC3A0), Color(0xFFB89B7A)],
      stops: const [0.0, 0.48, 1.0],
    ).createShader(const Rect.fromLTWH(0, 580, 1500, 420));

    canvas.drawPath(streetPath, Paint()..shader = streetGrad);

    canvas.save();
    canvas.clipPath(streetPath);

    final seamPaint = Paint()
      ..color = isNight
          ? const Color.fromRGBO(15, 12, 10, 0.48)
          : const Color.fromRGBO(95, 75, 55, 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (int index = -11; index <= 11; index++) {
      canvas.drawLine(
        Offset(750.0 + index * 18.0, 580.0),
        Offset(750.0 + index * 95.0, 1000.0),
        seamPaint,
      );
    }

    const stoneRows = [
      592.0, 606.0, 622.0, 640.0, 661.0, 685.0, 713.0, 745.0, 782.0, 825.0, 875.0, 932.0, 992.0,
    ];
    for (final rowY in stoneRows) {
      canvas.drawLine(Offset(0, rowY), Offset(1500, rowY), seamPaint);
    }

    canvas.restore();
  }

  // ===========================================================================
  // 3. Central Ceremonial Paifang Archway Gate
  // ===========================================================================
  static void _paintPaifangGate(
    Canvas canvas,
    OutdoorStreetPalette palette, {
    required bool hasSnow,
    required bool isNight,
  }) {
    const pfCX = 750.0;
    const pfBaseY = 586.0;

    canvas.drawRect(
      const Rect.fromLTWH(pfCX - 55, pfBaseY - 95, 110, 95),
      Paint()..color = isNight ? const Color(0xFF5C4033) : const Color(0xFFD99B66),
    );
    canvas.drawRect(
      const Rect.fromLTWH(pfCX - 62, pfBaseY - 105, 124, 12),
      Paint()..color = isNight ? const Color(0xFF2B211B) : const Color(0xFF4A3525),
    );

    final archPath = Path()
      ..arcTo(
        const Rect.fromLTWH(pfCX - 22, pfBaseY - 54, 44, 44),
        3.14159,
        3.14159,
        false,
      )
      ..lineTo(pfCX + 22, pfBaseY)
      ..lineTo(pfCX - 22, pfBaseY)
      ..close();
    canvas.drawPath(archPath, Paint()..color = palette.skyBottom);

    const pillarXs = [pfCX - 135, pfCX - 62, pfCX + 62, pfCX + 135];
    final drumPaint = Paint()..color = const Color(0xFF8C8275);
    final drumStroke = Paint()
      ..color = const Color(0xFF2B1810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final pillarPaint = Paint()..color = const Color(0xFF8F3226);
    final pillarStroke = Paint()
      ..color = const Color(0xFF2B1810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int index = 0; index < pillarXs.length; index++) {
      final pxCol = pillarXs[index];
      final isMain = index == 1 || index == 2;
      final topY = isMain ? pfBaseY - 185 : pfBaseY - 145;

      final drumRect = Rect.fromLTWH(pxCol - 10, pfBaseY - 22, 20, 22);
      canvas.drawRect(drumRect, drumPaint);
      canvas.drawRect(drumRect, drumStroke);

      final colRect = Rect.fromLTWH(pxCol - 6, topY, 12, pfBaseY - 22 - topY);
      canvas.drawRect(colRect, pillarPaint);
      canvas.drawRect(colRect, pillarStroke);
    }

    const beamRect1 = Rect.fromLTWH(pfCX - 142, pfBaseY - 142, 284, 24);
    canvas.drawRect(beamRect1, Paint()..color = const Color(0xFF6E422E));
    canvas.drawRect(beamRect1, pillarStroke);

    const beamRect2 = Rect.fromLTWH(pfCX - 68, pfBaseY - 182, 136, 36);
    canvas.drawRect(beamRect2, pillarPaint);
    canvas.drawRect(beamRect2, pillarStroke);

    const goldPlaque = Rect.fromLTWH(pfCX - 36, pfBaseY - 172, 72, 18);
    canvas.drawRect(goldPlaque, Paint()..color = const Color(0xFFD4AF37));
    canvas.drawRect(goldPlaque, pillarStroke);

    _paintPaifangRoof(canvas, pfCX - 102, pfBaseY - 166, 72, 96, 24, hasSnow: hasSnow);
    _paintPaifangRoof(canvas, pfCX + 102, pfBaseY - 166, 72, 96, 24, hasSnow: hasSnow);
    _paintPaifangRoof(canvas, pfCX, pfBaseY - 224, 138, 215, 42, hasSnow: hasSnow);
  }

  static void _paintPaifangRoof(
    Canvas canvas,
    double cx,
    double yTop,
    double topW,
    double botW,
    double h, {
    required bool hasSnow,
  }) {
    final roof = Path()
      ..moveTo(cx - topW / 2, yTop)
      ..lineTo(cx + topW / 2, yTop)
      ..quadraticBezierTo(cx + botW * 0.42, yTop + h * 0.85, cx + botW / 2 + 16, yTop + h * 0.35)
      ..lineTo(cx + botW / 2, yTop + h)
      ..lineTo(cx - botW / 2, yTop + h)
      ..lineTo(cx - botW / 2 - 16, yTop + h * 0.35)
      ..quadraticBezierTo(cx - botW * 0.42, yTop + h * 0.85, cx - topW / 2, yTop)
      ..close();

    canvas.drawPath(
      roof,
      Paint()..color = hasSnow ? const Color(0xFFF8FAFC) : const Color(0xFF786A58),
    );
    canvas.drawPath(
      roof,
      Paint()
        ..color = const Color(0xFF2B2118)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    if (!hasSnow) {
      final ribPaint = Paint()
        ..color = const Color.fromRGBO(45, 35, 25, 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (double rx = -botW / 2 + 10; rx < botW / 2; rx += 10) {
        canvas.drawLine(
          Offset(cx + rx * (topW / botW), yTop + 2),
          Offset(cx + rx, yTop + h - 2),
          ribPaint,
        );
      }
    }
  }
}
