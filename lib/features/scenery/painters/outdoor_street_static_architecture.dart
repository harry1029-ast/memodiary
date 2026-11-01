import 'package:flutter/material.dart';
import '../models/outdoor_street_palette.dart';
import '../models/shanshui_atmosphere.dart';

/// Static architectural geometry renderer for the Outdoor Ancient Market Street (`市井`).
///
/// Records the complex static elements (towering Cunfa mountain peak, base groves,
/// stone-paved avenue, four-pillar Paifang gate, two-story shopfronts with plaques &
/// couplets, slanted fabric awnings, and wooden market stall counters) into an
/// immutable `ui.Picture` layer to maintain 60 FPS performance.
class OutdoorStreetStaticArchitecture {
  const OutdoorStreetStaticArchitecture._();

  /// Paints the full static background and architectural geometry onto [canvas]
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
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;

    _paintMountains(canvas, streetPalette, hasSnow: hasSnow, isNight: isNight);
    _paintAvenue(canvas, streetPalette, hasSnow: hasSnow, isNight: isNight);
    _paintPaifangGate(canvas, streetPalette, hasSnow: hasSnow, isNight: isNight);
    _paintShopfronts(canvas, streetPalette, hasSnow: hasSnow, isNight: isNight);
    _paintAwnings(canvas, hasSnow: hasSnow);
    _paintStalls(canvas, isDawn: isDawn);
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
    // Secondary distant peaks
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

    // Central Hero Peak
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

    // Sunlit right ridge highlight & Cunfa contour lines
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

    final cragLines = [
      [const Offset(725, 86), const Offset(685, 195), const Offset(610, 340)],
      [const Offset(745, 90), const Offset(740, 210), const Offset(775, 345)],
      [const Offset(760, 95), const Offset(825, 225), const Offset(895, 355)],
      [const Offset(678, 108), const Offset(615, 220), const Offset(520, 350)],
      [const Offset(818, 152), const Offset(875, 260), const Offset(975, 365)],
    ];
    for (final line in cragLines) {
      final p = Path()..moveTo(line[0].dx, line[0].dy);
      for (int i = 1; i < line.length; i++) {
        p.lineTo(line[i].dx, line[i].dy);
      }
      canvas.drawPath(p, cragPaint);
    }
    canvas.restore();

    // Base tree groves framing the Paifang gate
    final treeGroves = const [
      [445.0, 345.0, 42.0], [495.0, 365.0, 46.0], [545.0, 392.0, 44.0], [595.0, 415.0, 38.0],
      [910.0, 412.0, 40.0], [965.0, 388.0, 46.0], [1025.0, 365.0, 44.0],
    ];
    for (int i = 0; i < treeGroves.length; i++) {
      final t = treeGroves[i];
      final col = i % 3 == 0
          ? palette.foliagePrimary
          : i % 3 == 1
              ? palette.foliageSecondary
              : palette.foliageAccent;
      _paintFoliageCluster(canvas, t[0], t[1], t[2], col, hasSnow: hasSnow);
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
    for (int i = 0; i < blobs.length; i++) {
      canvas.drawCircle(blobs[i], radii[i], fillPaint);
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
    Canvas canvas,
    OutdoorStreetPalette palette, {
    required bool hasSnow,
    required bool isNight,
  }) {
    final streetPath = Path()
      ..moveTo(560, 580)
      ..lineTo(940, 580)
      ..lineTo(1500, 940)
      ..lineTo(1500, 1000)
      ..lineTo(0, 1000)
      ..lineTo(0, 940)
      ..close();

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

    // Clip inside street to draw flagstone grid
    canvas.save();
    canvas.clipPath(streetPath);

    final seamPaint = Paint()
      ..color = isNight
          ? const Color.fromRGBO(15, 12, 10, 0.48)
          : const Color.fromRGBO(95, 75, 55, 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Longitudinal converging seams
    for (int i = -11; i <= 11; i++) {
      canvas.drawLine(
        Offset(750.0 + i * 18.0, 580.0),
        Offset(750.0 + i * 95.0, 1000.0),
        seamPaint,
      );
    }

    // Horizontal flagstone rows with perspective spacing
    final stoneRows = const [592.0, 606.0, 622.0, 640.0, 661.0, 685.0, 713.0, 745.0, 782.0, 825.0, 875.0, 932.0, 992.0];
    for (final ry in stoneRows) {
      canvas.drawLine(Offset(0, ry), Offset(1500, ry), seamPaint);
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

    // Distant inner gateway opening
    canvas.drawRect(
      const Rect.fromLTWH(pfCX - 55, pfBaseY - 95, 110, 95),
      Paint()..color = isNight ? const Color(0xFF5C4033) : const Color(0xFFD99B66),
    );
    canvas.drawRect(
      const Rect.fromLTWH(pfCX - 62, pfBaseY - 105, 124, 12),
      Paint()..color = isNight ? const Color(0xFF2B211B) : const Color(0xFF4A3525),
    );

    // Inner arch
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

    // 4 Cinnabar pillars with stone drum bases (抱鼓石)
    final pillarXs = const [pfCX - 135, pfCX - 62, pfCX + 62, pfCX + 135];
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

    for (int i = 0; i < pillarXs.length; i++) {
      final pxCol = pillarXs[i];
      final isMain = i == 1 || i == 2;
      final topY = isMain ? pfBaseY - 185 : pfBaseY - 145;

      // Stone drum base
      final drumRect = Rect.fromLTWH(pxCol - 10, pfBaseY - 22, 20, 22);
      canvas.drawRect(drumRect, drumPaint);
      canvas.drawRect(drumRect, drumStroke);

      // Cinnabar column
      final colRect = Rect.fromLTWH(pxCol - 6, topY, 12, pfBaseY - 22 - topY);
      canvas.drawRect(colRect, pillarPaint);
      canvas.drawRect(colRect, pillarStroke);
    }

    // Horizontal crossbeams & center gold plaque
    final beamRect1 = const Rect.fromLTWH(pfCX - 142, pfBaseY - 142, 284, 24);
    canvas.drawRect(beamRect1, Paint()..color = const Color(0xFF6E422E));
    canvas.drawRect(beamRect1, pillarStroke);

    final beamRect2 = const Rect.fromLTWH(pfCX - 68, pfBaseY - 182, 136, 36);
    canvas.drawRect(beamRect2, pillarPaint);
    canvas.drawRect(beamRect2, pillarStroke);

    final goldPlaque = const Rect.fromLTWH(pfCX - 36, pfBaseY - 172, 72, 18);
    canvas.drawRect(goldPlaque, Paint()..color = const Color(0xFFD4AF37));
    canvas.drawRect(goldPlaque, pillarStroke);

    // Upturned sweeping roofs
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
  }

  // ===========================================================================
  // 4. Two-Story Shopfronts, Signboards, Couplets & Eaves
  // ===========================================================================
  static void _paintShopfronts(
    Canvas canvas,
    OutdoorStreetPalette palette, {
    required bool hasSnow,
    required bool isNight,
  }) {
    final strokePaint = Paint()
      ..color = const Color(0xFF2B1D14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Mid-ground Left and Right Buildings
    final leftMid = Path()
      ..moveTo(265, 250)..lineTo(445, 325)..lineTo(445, 675)..lineTo(265, 745)..close();
    canvas.drawPath(leftMid, Paint()..color = palette.wallPlaster);
    canvas.drawPath(leftMid, strokePaint);

    final leftFarMid = Path()
      ..moveTo(445, 405)..lineTo(580, 445)..lineTo(580, 610)..lineTo(445, 665)..close();
    canvas.drawPath(leftFarMid, Paint()..color = palette.wallPlasterDark);
    canvas.drawPath(leftFarMid, strokePaint);

    final rightMid = Path()
      ..moveTo(1235, 250)..lineTo(1055, 325)..lineTo(1055, 675)..lineTo(1235, 745)..close();
    canvas.drawPath(rightMid, Paint()..color = palette.wallPlaster);
    canvas.drawPath(rightMid, strokePaint);

    final rightFarMid = Path()
      ..moveTo(1055, 405)..lineTo(920, 445)..lineTo(920, 610)..lineTo(1055, 665)..close();
    canvas.drawPath(rightFarMid, Paint()..color = palette.wallPlasterDark);
    canvas.drawPath(rightFarMid, strokePaint);

    // Foreground Left & Right Grand Wooden Shopfronts
    final leftFore = Path()
      ..moveTo(0, 40)..lineTo(275, 205)..lineTo(275, 815)..lineTo(0, 935)..close();
    canvas.drawPath(leftFore, Paint()..color = palette.woodFrame);
    canvas.drawPath(leftFore, strokePaint);

    final rightFore = Path()
      ..moveTo(1500, 40)..lineTo(1225, 205)..lineTo(1225, 815)..lineTo(1500, 935)..close();
    canvas.drawPath(rightFore, Paint()..color = palette.woodFrame);
    canvas.drawPath(rightFore, strokePaint);

    // Glowing lattice windows
    final winGlow = isNight
        ? const Color.fromRGBO(255, 205, 115, 0.75)
        : const Color.fromRGBO(120, 95, 75, 0.45);
    final winPaint = Paint()..color = winGlow;

    final leftWin = Path()
      ..moveTo(25, 395)..lineTo(215, 445)..lineTo(215, 650)..lineTo(25, 685)..close();
    canvas.drawPath(leftWin, winPaint);
    canvas.drawPath(leftWin, strokePaint);

    final rightWin = Path()
      ..moveTo(1475, 395)..lineTo(1285, 445)..lineTo(1285, 650)..lineTo(1475, 685)..close();
    canvas.drawPath(rightWin, winPaint);
    canvas.drawPath(rightWin, strokePaint);

    // Left green/gold signboard
    final leftSign = Path()
      ..moveTo(0, 255)..lineTo(232, 345)..lineTo(232, 385)..lineTo(0, 312)..close();
    canvas.drawPath(leftSign, Paint()..color = const Color(0xFF527A58));
    canvas.drawPath(
      leftSign,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Right wooden plaque: 拾光茶肆
    final rightSign = Path()
      ..moveTo(1500, 210)..lineTo(1360, 268)..lineTo(1375, 342)..lineTo(1500, 295)..close();
    canvas.drawPath(rightSign, Paint()..color = const Color(0xFFC9B28C));
    canvas.drawPath(
      rightSign,
      Paint()
        ..color = const Color(0xFF3B281B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    _paintPlaqueText(canvas, '拾光茶肆', const Offset(1395, 312), angle: -0.34);

    // Vertical red banners
    _paintVerticalBanner(canvas, 212, 455, 34, 215, '云笺糕点香');
    _paintVerticalBanner(canvas, 318, 468, 22, 135, '四时鲜果');
    _paintVerticalBanner(canvas, 438, 495, 18, 105, '清茶');
    _paintVerticalBanner(canvas, 1258, 458, 32, 195, '竹炉汤沸红');
    _paintVerticalBanner(canvas, 1145, 475, 22, 130, '江南美馔');

    // Sweeping upturned tiled eaves
    final roofColor = hasSnow
        ? const Color(0xFFF1F5F9)
        : isNight
            ? const Color(0xFF33363A)
            : const Color(0xFF524B42);
    final eavePaint = Paint()..color = roofColor;

    // Left upper eave
    final lUpper = Path()
      ..moveTo(0, 0)..lineTo(372, 15)
      ..quadraticBezierTo(340, 68, 235, 78)..lineTo(0, 25)..close();
    canvas.drawPath(lUpper, eavePaint);
    canvas.drawPath(lUpper, strokePaint);

    // Left lower sweeping eave with upturned tip
    final lLower = Path()
      ..moveTo(0, 95)..lineTo(255, 188)
      ..quadraticBezierTo(335, 212, 398, 178)
      ..quadraticBezierTo(375, 238, 255, 245)..lineTo(0, 165)..close();
    canvas.drawPath(lLower, eavePaint);
    canvas.drawPath(lLower, strokePaint);

    // Right upper eave
    final rUpper = Path()
      ..moveTo(1500, 0)..lineTo(1205, 15)
      ..quadraticBezierTo(1235, 65, 1335, 75)..lineTo(1500, 25)..close();
    canvas.drawPath(rUpper, eavePaint);
    canvas.drawPath(rUpper, strokePaint);

    // Right lower sweeping eave with upturned tip
    final rLower = Path()
      ..moveTo(1500, 88)..lineTo(1275, 198)
      ..quadraticBezierTo(1195, 222, 1142, 195)
      ..quadraticBezierTo(1168, 252, 1275, 258)..lineTo(1500, 162)..close();
    canvas.drawPath(rLower, eavePaint);
    canvas.drawPath(rLower, strokePaint);
  }

  static void _paintPlaqueText(Canvas canvas, String text, Offset pos, {required double angle}) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF2B1D14),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  static void _paintVerticalBanner(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    String text,
  ) {
    final rect = Rect.fromLTWH(x, y, w, h);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFC83E2B));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF2B1810)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final fontSize = (w * 0.72).clamp(10.0, 22.0);
    final charSpacing = h / (text.length + 0.4);
    for (int i = 0; i < text.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: TextStyle(
            color: const Color(0xFF231610),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + w * 0.14, y + 4 + i * charSpacing));
    }
  }

  // ===========================================================================
  // 5. Slanted Fabric Market Awnings
  // ===========================================================================
  static void _paintAwnings(Canvas canvas, {required bool hasSnow}) {
    final strokePaint = Paint()
      ..color = const Color(0xFF2B1B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    void drawAwning(List<Offset> pts, Color color) {
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
      p.close();
      canvas.drawPath(p, Paint()..color = hasSnow ? const Color(0xFFF1F5F9) : color);
      canvas.drawPath(p, strokePaint);
    }

    // Left awnings
    drawAwning(
      const [Offset(0, 325), Offset(235, 392), Offset(388, 468), Offset(165, 455)],
      const Color(0xFFF0AE5A),
    );
    drawAwning(
      const [Offset(375, 445), Offset(485, 482), Offset(568, 535), Offset(465, 528)],
      const Color(0xFFE07A68),
    );
    drawAwning(
      const [Offset(515, 488), Offset(585, 508), Offset(635, 536), Offset(565, 532)],
      const Color(0xFFF2C166),
    );

    // Right support pole
    canvas.drawLine(
      const Offset(1362, 375),
      const Offset(1362, 875),
      Paint()
        ..color = const Color(0xFF3B2516)
        ..strokeWidth = 5.0,
    );

    // Right awnings
    drawAwning(
      const [Offset(1358, 372), Offset(1165, 438), Offset(1055, 478), Offset(1225, 468)],
      const Color(0xFFD95B48),
    );
    drawAwning(
      const [Offset(1105, 468), Offset(1005, 495), Offset(935, 525), Offset(1028, 520)],
      const Color(0xFFF2C166),
    );
    drawAwning(
      const [Offset(985, 502), Offset(930, 518), Offset(882, 538), Offset(940, 534)],
      const Color(0xFFE07A68),
    );
  }

  // ===========================================================================
  // 6. Left & Right Market Stalls, Merchandise, Baskets & Furniture
  // ===========================================================================
  static void _paintStalls(Canvas canvas, {required bool isDawn}) {
    final strokePaint = Paint()
      ..color = const Color(0xFF2B1B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // --- LEFT STALL TABLE ---
    final leftTableTop = Path()
      ..moveTo(0, 710)..lineTo(195, 665)..lineTo(295, 695)..lineTo(85, 765)..close();
    canvas.drawPath(leftTableTop, Paint()..color = const Color(0xFF8C5E3C));
    canvas.drawPath(leftTableTop, strokePaint);

    final leftApron = Path()
      ..moveTo(0, 710)..lineTo(85, 765)..lineTo(295, 695)
      ..lineTo(295, 735)..lineTo(85, 815)..lineTo(0, 760)..close();
    canvas.drawPath(leftApron, Paint()..color = const Color(0xFF6E472B));
    canvas.drawPath(leftApron, strokePaint);

    canvas.drawRect(const Rect.fromLTWH(78, 805, 12, 105), Paint()..color = const Color(0xFF6E472B));
    canvas.drawRect(const Rect.fromLTWH(78, 805, 12, 105), strokePaint);
    canvas.drawRect(const Rect.fromLTWH(278, 730, 10, 88), Paint()..color = const Color(0xFF6E472B));
    canvas.drawRect(const Rect.fromLTWH(278, 730, 10, 88), strokePaint);

    // Left stall pastries (displayed if not dawn)
    if (!isDawn) {
      final pastryPaint = Paint()..color = const Color(0xFFE0A958);
      final pastries = const [
        [45.0, 712.0, 24.0, 10.0], [45.0, 702.0, 20.0, 9.0], [45.0, 693.0, 15.0, 8.0],
        [88.0, 718.0, 22.0, 9.0], [88.0, 709.0, 18.0, 8.0],
        [145.0, 705.0, 28.0, 10.0], [195.0, 692.0, 24.0, 9.0],
      ];
      for (final p in pastries) {
        final oval = Rect.fromCenter(center: Offset(p[0], p[1]), width: p[2] * 2, height: p[3] * 2);
        canvas.drawOval(oval, pastryPaint);
        canvas.drawOval(oval, strokePaint);
      }
    }

    // Wooden Crates of Red Apples/Persimmons
    final cratePaint = Paint()..color = const Color(0xFF8C5E3C);
    canvas.drawRect(const Rect.fromLTWH(118, 825, 92, 65), cratePaint);
    canvas.drawRect(const Rect.fromLTWH(118, 825, 92, 65), strokePaint);
    canvas.drawRect(const Rect.fromLTWH(214, 805, 72, 58), cratePaint);
    canvas.drawRect(const Rect.fromLTWH(214, 805, 72, 58), strokePaint);

    final applePaint = Paint()..color = const Color(0xFFD94638);
    final apples = const [
      [135.0, 822.0], [152.0, 818.0], [170.0, 822.0], [188.0, 820.0],
      [145.0, 810.0], [165.0, 808.0], [182.0, 812.0],
    ];
    for (final a in apples) {
      canvas.drawCircle(Offset(a[0], a[1]), 9.0, applePaint);
      canvas.drawCircle(Offset(a[0], a[1]), 9.0, strokePaint);
    }

    // --- RIGHT STALL COUNTER ---
    final rightCounterTop = Path()
      ..moveTo(1105, 678)..lineTo(1235, 662)..lineTo(1358, 718)..lineTo(1228, 742)..close();
    canvas.drawPath(rightCounterTop, cratePaint);
    canvas.drawPath(rightCounterTop, strokePaint);

    final rightCounterFront = Path()
      ..moveTo(1105, 678)..lineTo(1228, 742)..lineTo(1358, 718)
      ..lineTo(1358, 845)..lineTo(1228, 865)..lineTo(1105, 785)..close();
    canvas.drawPath(rightCounterFront, Paint()..color = const Color(0xFF6E472B));
    canvas.drawPath(rightCounterFront, strokePaint);

    // Bowls of hot noodles & teacups (if not dawn)
    if (!isDawn) {
      final bowls = const [
        [1185.0, 695.0, Color(0xFFE8EEF2)],
        [1218.0, 708.0, Color(0xFFF29F4B)],
        [1248.0, 720.0, Color(0xFFE8EEF2)],
        [1278.0, 715.0, Color(0xFFD95338)],
      ];
      for (final b in bowls) {
        final oval = Rect.fromCenter(center: Offset(b[0] as double, b[1] as double), width: 28, height: 14);
        canvas.drawOval(oval, Paint()..color = b[2] as Color);
        canvas.drawOval(oval, strokePaint);
      }
    }

    // Wooden Stool on Left of Right Counter
    final stoolRect = const Rect.fromLTWH(1072, 745, 52, 85);
    canvas.drawRect(stoolRect, Paint()..color = const Color(0xFF754C2E));
    canvas.drawRect(stoolRect, strokePaint);

    // Woven Bamboo Basket & Wooden Barrel
    final barrelRect = const Rect.fromLTWH(1255, 815, 76, 78);
    canvas.drawRect(barrelRect, Paint()..color = const Color(0xFF755638));
    canvas.drawRect(barrelRect, strokePaint);

    final basketOval = const Rect.fromLTWH(1259, 794, 68, 44);
    canvas.drawOval(basketOval, Paint()..color = const Color(0xFFC9A063));
    canvas.drawOval(basketOval, strokePaint);
  }
}
