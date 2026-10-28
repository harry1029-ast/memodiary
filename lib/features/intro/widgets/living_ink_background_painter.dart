import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter rendering the living atmospheric Chinese ink wash landscape
/// (孤山古亭, 钱塘春水, 凌空飞鹤, 平湖舟子, 摇曳墨竹, 《钱塘湖春行》题诗水印).
class LivingInkBackgroundPainter extends CustomPainter {
  final double coverOpenRatio; // 0.0 (closed) to 1.0 (fully open)
  final double animationTime; // Elapsed seconds from animation ticker

  LivingInkBackgroundPainter({
    required this.coverOpenRatio,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Luminous Xuan Paper Sky & Lake Reflection Gradient
    _paintBackgroundGradient(canvas, size);

    // Parallax calculations
    final farMountainParallax = -coverOpenRatio * 12.0;
    final leftCliffParallax = -coverOpenRatio * 7.0;
    final rightHillParallax = coverOpenRatio * 10.0;

    // 2. Far Horizon Misty Mountain Range
    canvas.save();
    canvas.translate(farMountainParallax, 0);
    _paintFarMountains(canvas, size);
    canvas.restore();

    // 3. Left Cliff Promontory & Classical Two-Tiered Pavilion (孤山古亭)
    canvas.save();
    canvas.translate(leftCliffParallax, 0);
    _paintLeftCliffAndPavilion(canvas, size);
    canvas.restore();

    // 4. Upper Drifting Mist Band
    _paintUpperMist(canvas, size);

    // 5. Midground Clustered Peaks & Right Dark Ink Hill with Crest Trees
    canvas.save();
    canvas.translate(rightHillParallax, 0);
    _paintRightHillAndPeaks(canvas, size);
    canvas.restore();

    // 6. Lake Surface Mist Layer
    _paintLakeMist(canvas, size);

    // 7. Vertical Calligraphic Poem Watermark (《钱塘湖春行》)
    _paintPoemWatermark(canvas, size);

    // 8. Distant Companion Crane
    _paintDistantCrane(canvas, size);

    // 9. Main Red-Crowned Ink Crane in Flight
    _paintMainFlyingCrane(canvas, size);

    // 10. Foreground Calm Lake, Punt Boat & Ferryboatman
    _paintFerryBoatman(canvas, size);

    // 11. Bottom-Right Swaying Ink Bamboo Stalks & Leaves
    _paintSwayingBamboo(canvas, size);
  }

  void _paintBackgroundGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFAF8F3),
          Color(0xFFF4F0E6),
          Color(0xFFEDE8DC),
          Color(0xFFF7F5EF),
          Color(0xFFEAE4D7),
        ],
        stops: [0.0, 0.30, 0.68, 0.84, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _paintFarMountains(Canvas canvas, Size size) {
    final w = size.width;
    final yBase = size.height * 0.22;

    final path = Path()
      ..moveTo(0, yBase * 0.85)
      ..quadraticBezierTo(w * 0.12, yBase * 0.72, w * 0.25, yBase * 0.80)
      ..quadraticBezierTo(w * 0.45, yBase * 0.68, w * 0.65, yBase * 0.78)
      ..quadraticBezierTo(w * 0.85, yBase * 0.65, w * 1.05, yBase * 0.75)
      ..lineTo(w * 1.05, yBase * 1.15)
      ..lineTo(0, yBase * 1.15)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8C908E).withValues(alpha: 0.38),
          const Color(0xFFB8BCBA).withValues(alpha: 0.16),
          const Color(0xFFF4F0E6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, yBase * 0.65, w, yBase * 0.5));

    canvas.drawPath(path, paint);

    // Misty Flat Shoal Island
    final shoalPath = Path()
      ..moveTo(w * 0.38, yBase * 0.95)
      ..quadraticBezierTo(w * 0.52, yBase * 0.84, w * 0.66, yBase * 0.90)
      ..quadraticBezierTo(w * 0.85, yBase * 0.88, w * 0.92, yBase * 0.96)
      ..lineTo(w * 0.35, yBase * 0.96)
      ..close();

    final shoalPaint = Paint()
      ..color = const Color(0xFF7E8280).withValues(alpha: 0.24);
    canvas.drawPath(shoalPath, shoalPaint);
  }

  void _paintLeftCliffAndPavilion(Canvas canvas, Size size) {
    final w = size.width;
    final yCliff = size.height * 0.20;

    // Cliff Path
    final cliffPath = Path()
      ..moveTo(0, yCliff * 0.85)
      ..quadraticBezierTo(w * 0.10, yCliff * 0.82, w * 0.18, yCliff * 0.92)
      ..quadraticBezierTo(w * 0.32, yCliff * 1.05, w * 0.38, yCliff * 1.30)
      ..lineTo(0, yCliff * 1.30)
      ..close();

    final cliffPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF484B49).withValues(alpha: 0.62),
          const Color(0xFF7C807E).withValues(alpha: 0.32),
          const Color(0xFFF4F0E6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, yCliff * 0.8, w * 0.4, yCliff * 0.5));

    canvas.drawPath(cliffPath, cliffPaint);

    // Classical Two-Tiered Pavilion on Cliff (飞檐双层古亭)
    final pavPaint = Paint()
      ..color = const Color(0xFF383B39).withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF383B39).withValues(alpha: 0.78)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final px = w * 0.05;
    final py = yCliff * 0.72;

    // Top Spire
    final spirePath = Path()
      ..moveTo(px + 12, py)
      ..lineTo(px + 13.5, py + 4)
      ..lineTo(px + 10.5, py + 4)
      ..close();
    canvas.drawPath(spirePath, pavPaint);

    // Upper Sweeping Eave
    final upperEave = Path()
      ..moveTo(px + 1, py + 10)
      ..quadraticBezierTo(px + 12, py + 2, px + 23, py + 10)
      ..lineTo(px + 21, py + 11.5)
      ..quadraticBezierTo(px + 12, py + 6, px + 3, py + 11.5)
      ..close();
    canvas.drawPath(upperEave, pavPaint);

    // Upper Pillars
    canvas.drawLine(Offset(px + 6, py + 11.5), Offset(px + 6, py + 18), linePaint);
    canvas.drawLine(Offset(px + 12, py + 11.5), Offset(px + 12, py + 18), linePaint);
    canvas.drawLine(Offset(px + 18, py + 11.5), Offset(px + 18, py + 18), linePaint);

    // Lower Wide Sweeping Eave (飞檐翘角)
    final lowerEave = Path()
      ..moveTo(px - 3, py + 19)
      ..quadraticBezierTo(px + 12, py + 10, px + 27, py + 19)
      ..lineTo(px + 25, py + 21)
      ..quadraticBezierTo(px + 12, py + 14, px - 1, py + 21)
      ..close();
    canvas.drawPath(lowerEave, pavPaint);

    // Lower Columns & Balustrade
    canvas.drawLine(Offset(px + 3, py + 21), Offset(px + 3, py + 31), linePaint);
    canvas.drawLine(Offset(px + 9, py + 21), Offset(px + 9, py + 31), linePaint);
    canvas.drawLine(Offset(px + 15, py + 21), Offset(px + 15, py + 31), linePaint);
    canvas.drawLine(Offset(px + 21, py + 21), Offset(px + 21, py + 31), linePaint);

    // Base Balustrade Rail
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px + 1, py + 30, 22, 2.5),
        const Radius.circular(1),
      ),
      pavPaint,
    );
  }

  void _paintUpperMist(Canvas canvas, Size size) {
    final mistShift = math.sin((animationTime / 9.0) * 2 * math.pi) * 16.0;
    final yMist = size.height * 0.23;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF7F5EF).withValues(alpha: 0.0),
          const Color(0xFFF7F5EF).withValues(alpha: 0.85),
          const Color(0xFFF7F5EF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(-20 + mistShift, yMist, size.width + 40, 36));

    canvas.drawRect(
      Rect.fromLTWH(-20 + mistShift, yMist, size.width + 40, 36),
      paint,
    );
  }

  void _paintRightHillAndPeaks(Canvas canvas, Size size) {
    final w = size.width;
    final yHill = size.height * 0.74;

    // Center Twin Misty Peaks
    final centerPeaks = Path()
      ..moveTo(w * 0.28, yHill)
      ..quadraticBezierTo(w * 0.36, yHill - 35, w * 0.44, yHill - 16)
      ..quadraticBezierTo(w * 0.50, yHill - 42, w * 0.58, yHill - 12)
      ..lineTo(w * 0.64, yHill)
      ..close();

    final centerPeakPaint = Paint()
      ..color = const Color(0xFF5E6260).withValues(alpha: 0.42);
    canvas.drawPath(centerPeaks, centerPeakPaint);

    // Right Dense Charcoal-Ink Hill (右岸浓墨山丘)
    final rightHill = Path()
      ..moveTo(w * 0.58, yHill)
      ..quadraticBezierTo(w * 0.72, yHill - 46, w * 0.84, yHill - 34)
      ..quadraticBezierTo(w * 0.94, yHill - 20, w * 1.02, yHill - 16)
      ..lineTo(w * 1.02, yHill + 10)
      ..lineTo(w * 0.55, yHill + 10)
      ..close();

    final rightHillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF262827).withValues(alpha: 0.78),
          const Color(0xFF4F5351).withValues(alpha: 0.48),
          const Color(0xFFF4F0E6).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(w * 0.55, yHill - 46, w * 0.5, 60));

    canvas.drawPath(rightHill, rightHillPaint);

    // Tiny Ink Trees Along Right Hill Crest (几处早莺争暖树)
    final treePaint = Paint()
      ..color = const Color(0xFF1F2120).withValues(alpha: 0.65);
    final treeStems = Paint()
      ..color = const Color(0xFF1F2120).withValues(alpha: 0.65)
      ..strokeWidth = 0.8;

    final treePoints = [
      Offset(w * 0.70, yHill - 42),
      Offset(w * 0.73, yHill - 45),
      Offset(w * 0.76, yHill - 46),
      Offset(w * 0.79, yHill - 45),
      Offset(w * 0.82, yHill - 43),
      Offset(w * 0.85, yHill - 38),
      Offset(w * 0.89, yHill - 32),
      Offset(w * 0.92, yHill - 26),
    ];

    for (final pt in treePoints) {
      canvas.drawCircle(pt, 2.0, treePaint);
      canvas.drawCircle(Offset(pt.dx + 1.5, pt.dy - 1.0), 1.5, treePaint);
      canvas.drawLine(pt, Offset(pt.dx, pt.dy + 3.5), treeStems);
    }
  }

  void _paintLakeMist(Canvas canvas, Size size) {
    final yLake = size.height * 0.73;
    final mistPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF7F5EF).withValues(alpha: 0.0),
          const Color(0xFFF7F5EF).withValues(alpha: 0.90),
          const Color(0xFFF7F5EF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, yLake - 15, size.width, 35));

    canvas.drawRect(Rect.fromLTWH(0, yLake - 15, size.width, 35), mistPaint);
  }

  void _paintPoemWatermark(Canvas canvas, Size size) {
    final opacity = (0.28 + coverOpenRatio * 0.42).clamp(0.0, 1.0);
    final textStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1E1D1A).withValues(alpha: opacity),
      letterSpacing: 3.0,
      height: 1.6,
      fontFamily: 'Noto Serif SC',
    );

    final titleStyle = textStyle.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    );

    final authorStyle = textStyle.copyWith(
      fontSize: 9.0,
      color: const Color(0xFF4A4740).withValues(alpha: opacity),
    );

    // Right-to-Left vertical columns
    final columns = [
      {'text': '《钱塘湖春行》', 'style': titleStyle, 'xRatio': 0.91, 'yRatio': 0.08},
      {'text': '唐·白居易', 'style': authorStyle, 'xRatio': 0.85, 'yRatio': 0.11},
      {'text': '孤山寺北贾亭西', 'style': textStyle, 'xRatio': 0.79, 'yRatio': 0.08},
      {'text': '水面初平云脚低', 'style': textStyle, 'xRatio': 0.73, 'yRatio': 0.10},
      {'text': '几处早莺争暖树', 'style': textStyle, 'xRatio': 0.67, 'yRatio': 0.09},
    ];

    for (final col in columns) {
      final text = col['text'] as String;
      final style = col['style'] as TextStyle;
      final xr = col['xRatio'] as double;
      final yr = col['yRatio'] as double;

      // Vertical layout character by character
      final chars = text.split('');
      double curY = size.height * yr;
      final curX = size.width * xr;

      for (final ch in chars) {
        final tp = TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(curX, curY));
        curY += tp.height + 2.5;
      }
    }
  }

  void _paintDistantCrane(Canvas canvas, Size size) {
    final t = (animationTime / 13.0) % 1.0;
    final x = size.width * 0.15 + t * (size.width * 0.65);
    final y = size.height * 0.16 - math.sin(t * math.pi) * 8.0;

    final paint = Paint()
      ..color = const Color(0xFF2E302F).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(x, y + 3)
      ..quadraticBezierTo(x + 5, y - 2, x + 10, y + 2)
      ..quadraticBezierTo(x + 15, y - 2, x + 20, y + 3)
      ..quadraticBezierTo(x + 15, y + 1, x + 10, y + 4)
      ..quadraticBezierTo(x + 5, y + 1, x, y + 3)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _paintMainFlyingCrane(Canvas canvas, Size size) {
    // 11-second linear flight across
    final flightT = (animationTime / 11.0) % 1.0;
    final x = -40.0 + flightT * (size.width + 80.0);
    final y = size.height * 0.17 - math.sin(flightT * math.pi) * 16.0;

    // Wing flapping cycle: 0.9s oscillation
    final wingPhase = math.sin((animationTime / 0.9) * 2 * math.pi);

    canvas.save();
    canvas.translate(x, y);

    // Trailing Legs
    final legPaint = Paint()
      ..color = const Color(0xFF2B2B29)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(6, 12), const Offset(-8, 16), legPaint);
    canvas.drawLine(const Offset(8, 13), const Offset(-5, 18), legPaint);

    // Black Tail Feathers
    final tailPaint = Paint()..color = const Color(0xFF1C1C1A);
    final tailPath = Path()
      ..moveTo(4, 10)
      ..quadraticBezierTo(0, 12, -2, 9)
      ..quadraticBezierTo(2, 7, 6, 8)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // White Feathered Body
    final bodyPaint = Paint()
      ..color = const Color(0xFFFAF8F3)
      ..style = PaintingStyle.fill;
    final bodyStroke = Paint()
      ..color = const Color(0xFF3A3935)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final bodyRect = Rect.fromCenter(center: const Offset(12, 9), width: 15, height: 7);
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, bodyStroke);

    // Slender S-Curved Neck & Head
    final neckPaint = Paint()
      ..color = const Color(0xFF1C1C1A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final neckPath = Path()
      ..moveTo(18, 8)
      ..quadraticBezierTo(24, 6, 29, 4);
    canvas.drawPath(neckPath, neckPaint);

    // Head with Cinnabar Crown (丹顶)
    canvas.drawCircle(const Offset(30, 3.5), 1.8, Paint()..color = const Color(0xFFFAF8F3));
    canvas.drawCircle(const Offset(29.6, 2.5), 1.1, Paint()..color = const Color(0xFFB83B2E));

    // Pointed Beak
    final beakPath = Path()
      ..moveTo(31, 3.2)
      ..lineTo(36, 2.5)
      ..lineTo(31, 4.2)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFF3A3832));

    // Flapping Wings with Upstroke/Downstroke Modulation
    final wingYMod = wingPhase * 12.0;

    final wingPaint = Paint()
      ..color = const Color(0xFFFAF8F3)
      ..style = PaintingStyle.fill;
    final wingStroke = Paint()
      ..color = const Color(0xFF2B2A27)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final wingTipPaint = Paint()..color = const Color(0xFF181816);

    final wingPath = Path()
      ..moveTo(10, 8)
      ..quadraticBezierTo(7, 8 - wingYMod * 1.5, 0, 8 - wingYMod * 2.0)
      ..quadraticBezierTo(8, 8 - wingYMod * 0.8, 14, 8)
      ..close();
    canvas.drawPath(wingPath, wingPaint);
    canvas.drawPath(wingPath, wingStroke);

    // Black Wingtip Feathers
    final tipPath = Path()
      ..moveTo(0, 8 - wingYMod * 2.0)
      ..quadraticBezierTo(4, 8 - wingYMod * 1.6, 7, 8 - wingYMod * 1.0)
      ..quadraticBezierTo(3, 8 - wingYMod * 1.0, 1, 8 - wingYMod * 1.6)
      ..close();
    canvas.drawPath(tipPath, wingTipPaint);

    canvas.restore();
  }

  void _paintFerryBoatman(Canvas canvas, Size size) {
    // 7-second gentle boat drift
    final driftX = math.sin((animationTime / 7.0) * 2 * math.pi) * 8.0;
    final driftY = math.sin((animationTime / 7.0) * 2 * math.pi) * 1.5;
    final rockAngle = math.sin((animationTime / 7.0) * 2 * math.pi) * 0.008;

    final bx = size.width * 0.32 + driftX;
    final by = size.height * 0.79 + driftY;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(rockAngle);

    // Water Ripples
    final ripT = (animationTime / 4.5) % 1.0;
    final ripScale = 0.7 + ripT * 0.45;
    final ripAlpha = ((1.0 - ripT) * 0.5).clamp(0.0, 1.0);

    final ripPaint = Paint()
      ..color = const Color(0xFF8A877F).withValues(alpha: ripAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 16), width: 95 * ripScale, height: 4.0),
      ripPaint,
    );

    // Inverted Soft Reflection in Water
    final reflectPaint = Paint()
      ..color = const Color(0xFF2A2B2A).withValues(alpha: 0.18);
    final reflectHull = Path()
      ..moveTo(15, 16)
      ..quadraticBezierTo(55, 23, 95, 15)
      ..lineTo(90, 20)
      ..lineTo(20, 20)
      ..close();
    canvas.drawPath(reflectHull, reflectPaint);

    // Long Sculling Oar (长橹入水)
    final oarAngle = math.sin((animationTime / 3.5) * 2 * math.pi) * 0.10;
    canvas.save();
    canvas.translate(40, 9);
    canvas.rotate(oarAngle);
    final oarPaint = Paint()
      ..color = const Color(0xFF2C2B29)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 0), const Offset(-38, 10), oarPaint);
    canvas.restore();

    // Ferryboatman in Conical Hat (斗笠蓑衣舟子)
    final manPaint = Paint()..color = const Color(0xFF2E2E2C);
    final robePath = Path()
      ..moveTo(36, 12)
      ..quadraticBezierTo(38, 5, 42, 5)
      ..lineTo(44, 12)
      ..close();
    canvas.drawPath(robePath, manPaint);

    // Conical Bamboo Hat (斗笠)
    final hatPath = Path()
      ..moveTo(35, 6)
      ..lineTo(40, 2)
      ..lineTo(45, 6)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = const Color(0xFF1E1E1C));

    // Traditional Arched Woven Canopy in Middle of Boat (乌篷)
    final canopyPaint = Paint()..color = const Color(0xFFE2DFD7);
    final canopyStroke = Paint()
      ..color = const Color(0xFF78756E)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final canopyPath = Path()
      ..moveTo(52, 12)
      ..lineTo(52, 4.5)
      ..quadraticBezierTo(65, 1.5, 78, 4.5)
      ..lineTo(78, 12)
      ..close();
    canvas.drawPath(canopyPath, canopyPaint);
    canvas.drawPath(canopyPath, canopyStroke);

    // Long Slender Punt Boat Hull (修长扁舟)
    final hullPaint = Paint()..color = const Color(0xFF1F201F);
    final hullPath = Path()
      ..moveTo(12, 11)
      ..quadraticBezierTo(55, 15, 102, 10)
      ..lineTo(96, 15)
      ..lineTo(18, 15)
      ..close();
    canvas.drawPath(hullPath, hullPaint);

    canvas.restore();
  }

  void _paintSwayingBamboo(Canvas canvas, Size size) {
    // Sway angle
    final swayAngle = math.sin((animationTime / 5.5) * 2 * math.pi) * 0.055;

    final bx = size.width * 0.90;
    final by = size.height * 0.88;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(swayAngle);

    final stemPaint = Paint()
      ..color = const Color(0xFF1C1C1A).withValues(alpha: 0.82)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()
      ..color = const Color(0xFF1C1C1A).withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    // Bamboo Stalk 1
    final s1 = Path()
      ..moveTo(25, 40)
      ..quadraticBezierTo(10, 0, -10, -50);
    canvas.drawPath(s1, stemPaint);

    // Bamboo Stalk 2
    final s2 = Path()
      ..moveTo(30, 50)
      ..quadraticBezierTo(18, 15, 0, -25);
    canvas.drawPath(s2, stemPaint..strokeWidth = 1.3);

    // Calligraphic Bamboo Leaves
    _drawBambooLeaf(canvas, const Offset(-10, -50), -0.7, leafPaint);
    _drawBambooLeaf(canvas, const Offset(-10, -50), -0.2, leafPaint);
    _drawBambooLeaf(canvas, const Offset(0, -25), -0.8, leafPaint);
    _drawBambooLeaf(canvas, const Offset(0, -25), -0.3, leafPaint);
    _drawBambooLeaf(canvas, const Offset(5, -10), -0.9, leafPaint);
    _drawBambooLeaf(canvas, const Offset(12, 10), -0.6, leafPaint);

    canvas.restore();
  }

  void _drawBambooLeaf(Canvas canvas, Offset origin, double angle, Paint paint) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(10, -3, 20, 0)
      ..quadraticBezierTo(10, 3, 0, 0)
      ..close();

    canvas.drawPath(leaf, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LivingInkBackgroundPainter oldDelegate) {
    return oldDelegate.coverOpenRatio != coverOpenRatio ||
        oldDelegate.animationTime != animationTime;
  }
}
