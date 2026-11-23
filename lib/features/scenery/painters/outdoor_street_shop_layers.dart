import 'package:flutter/material.dart';
import '../models/outdoor_street_palette.dart';

/// Shopfront walls, dynamic window glows, billowing awnings, and foreground
/// market stall counters for the Outdoor Ancient Market Street (`街市`) realm.
class OutdoorStreetShopLayers {
  const OutdoorStreetShopLayers._();

  static final Path _leftWindowPath = Path()
    ..moveTo(25, 395)
    ..lineTo(215, 445)
    ..lineTo(215, 650)
    ..lineTo(25, 685)
    ..close();

  static final Path _rightWindowPath = Path()
    ..moveTo(1475, 395)
    ..lineTo(1285, 445)
    ..lineTo(1285, 650)
    ..lineTo(1475, 685)
    ..close();

  static const Rect _leftBannerRect = Rect.fromLTWH(212, 455, 34, 215);
  static const Rect _rightBannerRect = Rect.fromLTWH(1258, 458, 32, 195);

  /// Paints the static two-story shopfronts, signboards, banners, and eaves.
  static void paintShopfronts(
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
      ..moveTo(265, 250)
      ..lineTo(445, 325)
      ..lineTo(445, 675)
      ..lineTo(265, 745)
      ..close();
    canvas.drawPath(leftMid, Paint()..color = palette.wallPlaster);
    canvas.drawPath(leftMid, strokePaint);

    final leftFarMid = Path()
      ..moveTo(445, 405)
      ..lineTo(580, 445)
      ..lineTo(580, 610)
      ..lineTo(445, 665)
      ..close();
    canvas.drawPath(leftFarMid, Paint()..color = palette.wallPlasterDark);
    canvas.drawPath(leftFarMid, strokePaint);

    final rightMid = Path()
      ..moveTo(1235, 250)
      ..lineTo(1055, 325)
      ..lineTo(1055, 675)
      ..lineTo(1235, 745)
      ..close();
    canvas.drawPath(rightMid, Paint()..color = palette.wallPlaster);
    canvas.drawPath(rightMid, strokePaint);

    final rightFarMid = Path()
      ..moveTo(1055, 405)
      ..lineTo(920, 445)
      ..lineTo(920, 610)
      ..lineTo(1055, 665)
      ..close();
    canvas.drawPath(rightFarMid, Paint()..color = palette.wallPlasterDark);
    canvas.drawPath(rightFarMid, strokePaint);

    // Foreground Left & Right Grand Wooden Shopfronts
    final leftFore = Path()
      ..moveTo(0, 40)
      ..lineTo(275, 205)
      ..lineTo(275, 815)
      ..lineTo(0, 935)
      ..close();
    canvas.drawPath(leftFore, Paint()..color = palette.woodFrame);
    canvas.drawPath(leftFore, strokePaint);

    final rightFore = Path()
      ..moveTo(1500, 40)
      ..lineTo(1225, 205)
      ..lineTo(1225, 815)
      ..lineTo(1500, 935)
      ..close();
    canvas.drawPath(rightFore, Paint()..color = palette.woodFrame);
    canvas.drawPath(rightFore, strokePaint);

    // Base unlit lattice window backing & frames (dynamic glow layered at 60 FPS)
    final baseWinPaint = Paint()..color = const Color.fromRGBO(120, 95, 75, 0.45);
    canvas.drawPath(_leftWindowPath, baseWinPaint);
    canvas.drawPath(_leftWindowPath, strokePaint);
    canvas.drawPath(_rightWindowPath, baseWinPaint);
    canvas.drawPath(_rightWindowPath, strokePaint);

    // Left green/gold signboard
    final leftSign = Path()
      ..moveTo(0, 255)
      ..lineTo(232, 345)
      ..lineTo(232, 385)
      ..lineTo(0, 312)
      ..close();
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
      ..moveTo(1500, 210)
      ..lineTo(1360, 268)
      ..lineTo(1375, 342)
      ..lineTo(1500, 295)
      ..close();
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

    final lUpper = Path()
      ..moveTo(0, 0)
      ..lineTo(372, 15)
      ..quadraticBezierTo(340, 68, 235, 78)
      ..lineTo(0, 25)
      ..close();
    canvas.drawPath(lUpper, eavePaint);
    canvas.drawPath(lUpper, strokePaint);

    final lLower = Path()
      ..moveTo(0, 95)
      ..lineTo(255, 188)
      ..quadraticBezierTo(335, 212, 398, 178)
      ..quadraticBezierTo(375, 238, 255, 245)
      ..lineTo(0, 165)
      ..close();
    canvas.drawPath(lLower, eavePaint);
    canvas.drawPath(lLower, strokePaint);

    final rUpper = Path()
      ..moveTo(1500, 0)
      ..lineTo(1205, 15)
      ..quadraticBezierTo(1235, 65, 1335, 75)
      ..lineTo(1500, 25)
      ..close();
    canvas.drawPath(rUpper, eavePaint);
    canvas.drawPath(rUpper, strokePaint);

    final rLower = Path()
      ..moveTo(1500, 88)
      ..lineTo(1275, 198)
      ..quadraticBezierTo(1195, 222, 1142, 195)
      ..quadraticBezierTo(1168, 252, 1275, 258)
      ..lineTo(1500, 162)
      ..close();
    canvas.drawPath(rLower, eavePaint);
    canvas.drawPath(rLower, strokePaint);
  }

  /// Paints warm amber shopfront window glow when [lanternLevel] exceeds 0.3
  /// (covering Dawn, Dusk, Night, and Rainy/Stormy weather), masked clear of
  /// foreground vertical couplet banners.
  static void paintDynamicShopWindows(
    Canvas canvas, {
    required double lanternLevel,
  }) {
    if (lanternLevel <= 0.3) return;
    final glowAlpha = (0.45 + lanternLevel * 0.45).clamp(0.0, 0.95);
    final glowPaint = Paint()..color = Color.fromRGBO(255, 205, 115, glowAlpha);
    final frameStroke = Paint()
      ..color = const Color(0xFF2B1D14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final leftClipped = Path.combine(
      PathOperation.difference,
      _leftWindowPath,
      Path()..addRect(_leftBannerRect),
    );
    canvas.drawPath(leftClipped, glowPaint);
    canvas.drawPath(leftClipped, frameStroke);

    final rightClipped = Path.combine(
      PathOperation.difference,
      _rightWindowPath,
      Path()..addRect(_rightBannerRect),
    );
    canvas.drawPath(rightClipped, glowPaint);
    canvas.drawPath(rightClipped, frameStroke);
  }

  /// Paints the 6 slanted fabric market awnings with wind-billowing outer edges.
  static void paintBillowingAwnings(
    Canvas canvas, {
    required bool hasSnow,
    required double billow,
  }) {
    final strokePaint = Paint()
      ..color = const Color(0xFF2B1B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    void drawAwning(List<Offset> pts, Color color) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int index = 1; index < pts.length; index++) {
        final dy = index >= 2 ? pts[index].dy + billow : pts[index].dy;
        path.lineTo(pts[index].dx, dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = hasSnow ? const Color(0xFFF1F5F9) : color);
      canvas.drawPath(path, strokePaint);
    }

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

  /// Paints the foreground wooden stall counters, aprons, pastries, crates,
  /// noodle bowls, wooden stool, and basket/barrel so behind-counter vendors are
  /// naturally occluded while foreground walkers appear in front.
  static void paintForegroundStalls(Canvas canvas, {required bool isDawn}) {
    final strokePaint = Paint()
      ..color = const Color(0xFF2B1B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // --- LEFT STALL TABLE ---
    final leftTableTop = Path()
      ..moveTo(0, 710)
      ..lineTo(195, 665)
      ..lineTo(295, 695)
      ..lineTo(85, 765)
      ..close();
    canvas.drawPath(leftTableTop, Paint()..color = const Color(0xFF8C5E3C));
    canvas.drawPath(leftTableTop, strokePaint);

    final leftApron = Path()
      ..moveTo(0, 710)
      ..lineTo(85, 765)
      ..lineTo(295, 695)
      ..lineTo(295, 735)
      ..lineTo(85, 815)
      ..lineTo(0, 760)
      ..close();
    canvas.drawPath(leftApron, Paint()..color = const Color(0xFF6E472B));
    canvas.drawPath(leftApron, strokePaint);

    canvas.drawRect(const Rect.fromLTWH(78, 805, 12, 105), Paint()..color = const Color(0xFF6E472B));
    canvas.drawRect(const Rect.fromLTWH(78, 805, 12, 105), strokePaint);
    canvas.drawRect(const Rect.fromLTWH(278, 730, 10, 88), Paint()..color = const Color(0xFF6E472B));
    canvas.drawRect(const Rect.fromLTWH(278, 730, 10, 88), strokePaint);

    if (!isDawn) {
      final pastryPaint = Paint()..color = const Color(0xFFE0A958);
      const pastries = [
        [45.0, 712.0, 24.0, 10.0],
        [45.0, 702.0, 20.0, 9.0],
        [45.0, 693.0, 15.0, 8.0],
        [88.0, 718.0, 22.0, 9.0],
        [88.0, 709.0, 18.0, 8.0],
        [145.0, 705.0, 28.0, 10.0],
        [195.0, 692.0, 24.0, 9.0],
      ];
      for (final pastry in pastries) {
        final oval = Rect.fromCenter(
          center: Offset(pastry[0], pastry[1]),
          width: pastry[2] * 2,
          height: pastry[3] * 2,
        );
        canvas.drawOval(oval, pastryPaint);
        canvas.drawOval(oval, strokePaint);
      }
    }

    final cratePaint = Paint()..color = const Color(0xFF8C5E3C);
    canvas.drawRect(const Rect.fromLTWH(118, 825, 92, 65), cratePaint);
    canvas.drawRect(const Rect.fromLTWH(118, 825, 92, 65), strokePaint);
    canvas.drawRect(const Rect.fromLTWH(214, 805, 72, 58), cratePaint);
    canvas.drawRect(const Rect.fromLTWH(214, 805, 72, 58), strokePaint);

    final applePaint = Paint()..color = const Color(0xFFD94638);
    const apples = [
      Offset(135.0, 822.0),
      Offset(152.0, 818.0),
      Offset(170.0, 822.0),
      Offset(188.0, 820.0),
      Offset(145.0, 810.0),
      Offset(165.0, 808.0),
      Offset(182.0, 812.0),
    ];
    for (final apple in apples) {
      canvas.drawCircle(apple, 9.0, applePaint);
      canvas.drawCircle(apple, 9.0, strokePaint);
    }

    // --- RIGHT STALL COUNTER ---
    final rightCounterTop = Path()
      ..moveTo(1105, 678)
      ..lineTo(1235, 662)
      ..lineTo(1358, 718)
      ..lineTo(1228, 742)
      ..close();
    canvas.drawPath(rightCounterTop, cratePaint);
    canvas.drawPath(rightCounterTop, strokePaint);

    final rightCounterFront = Path()
      ..moveTo(1105, 678)
      ..lineTo(1228, 742)
      ..lineTo(1358, 718)
      ..lineTo(1358, 845)
      ..lineTo(1228, 865)
      ..lineTo(1105, 785)
      ..close();
    canvas.drawPath(rightCounterFront, Paint()..color = const Color(0xFF6E472B));
    canvas.drawPath(rightCounterFront, strokePaint);

    if (!isDawn) {
      const bowls = [
        (1185.0, 695.0, Color(0xFFE8EEF2)),
        (1218.0, 708.0, Color(0xFFF29F4B)),
        (1248.0, 720.0, Color(0xFFE8EEF2)),
        (1278.0, 715.0, Color(0xFFD95338)),
      ];
      for (final bowl in bowls) {
        final oval = Rect.fromCenter(center: Offset(bowl.$1, bowl.$2), width: 28, height: 14);
        canvas.drawOval(oval, Paint()..color = bowl.$3);
        canvas.drawOval(oval, strokePaint);
      }
    }

    const stoolRect = Rect.fromLTWH(1072, 745, 52, 85);
    canvas.drawRect(stoolRect, Paint()..color = const Color(0xFF754C2E));
    canvas.drawRect(stoolRect, strokePaint);

    const barrelRect = Rect.fromLTWH(1255, 815, 76, 78);
    canvas.drawRect(barrelRect, Paint()..color = const Color(0xFF755638));
    canvas.drawRect(barrelRect, strokePaint);

    const basketOval = Rect.fromLTWH(1259, 794, 68, 44);
    canvas.drawOval(basketOval, Paint()..color = const Color(0xFFC9A063));
    canvas.drawOval(basketOval, strokePaint);
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
    for (int index = 0; index < text.length; index++) {
      final tp = TextPainter(
        text: TextSpan(
          text: text[index],
          style: TextStyle(
            color: const Color(0xFF231610),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + w * 0.14, y + 4 + index * charSpacing));
    }
  }
}
