import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_palette.dart';
import '../models/shanshui_scenery_geometry.dart';

/// Landscape architecture, foliage, boat, and crane rendering helpers for the
/// Nature (`山水`) realm painter.
class ShanshuiNatureLayers {
  const ShanshuiNatureLayers._();

  /// Paints the far mountains, Cunfa karst crags, waterfall, and drifting mist.
  static void drawMountainsAndMist(
    Canvas canvas,
    ShanshuiPalette palette, {
    required double time,
    required double wind,
    required double mistMultiplier,
    required bool hasSnowCover,
  }) {
    drawPolygon(
      canvas,
      ShanshuiGeometry.farMountain1,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.farMtn.withValues(alpha: 0.55), palette.skyBottom.withValues(alpha: 0.55)],
      ).createShader(const Rect.fromLTWH(0, 160, 1500, 420)),
    );

    drawPolygon(
      canvas,
      ShanshuiGeometry.farMountain2,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.midMtn.withValues(alpha: 0.65), palette.skyBottom.withValues(alpha: 0.65)],
      ).createShader(const Rect.fromLTWH(0, 190, 1500, 410)),
    );

    drawKarstMass(
      canvas,
      ShanshuiGeometry.leftKarstBack,
      68,
      palette.nearMtn,
      palette.midMtn,
      palette,
      hasSnowCover: hasSnowCover,
    );
    drawKarstMass(
      canvas,
      ShanshuiGeometry.rightKarstPeaks,
      210,
      palette.midMtn,
      palette.farMtn,
      palette,
      hasSnowCover: hasSnowCover,
    );
    drawKarstMass(
      canvas,
      ShanshuiGeometry.leftKarstFront,
      145,
      palette.cragStroke,
      palette.nearMtn,
      palette,
      hasSnowCover: hasSnowCover,
    );

    const wfX = 248.0;
    const wfY = 235.0;
    final waterfallPath = Path()
      ..moveTo(wfX, wfY)
      ..quadraticBezierTo(wfX - 8, wfY + 85, wfX + 6, wfY + 185);
    canvas.drawPath(
      waterfallPath,
      Paint()
        ..color = hasSnowCover ? const Color(0xFFF8FAFC) : const Color(0xD9FAFAF7)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke,
    );

    final mistShift = (time * 22 * wind) % 1500;
    final mistPaint = Paint()..color = palette.mistColor;
    for (int bandIndex = -1; bandIndex <= 1; bandIndex++) {
      final mx = bandIndex * 1500.0 - mistShift;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mx + 300, 465),
          width: 580,
          height: 72 * mistMultiplier,
        ),
        mistPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mx + 820, 485),
          width: 720,
          height: 84 * mistMultiplier,
        ),
        mistPaint,
      );
    }
  }

  /// Paints a polygonal mountain layer shaded with [shader].
  static void drawPolygon(Canvas canvas, List<Offset> points, Shader shader) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..shader = shader);
  }

  /// Paints a Cunfa-textured karst massif with sunlit facets and snow highlights.
  static void drawKarstMass(
    Canvas canvas,
    List<Offset> points,
    double gradTopY,
    Color topColor,
    Color botColor,
    ShanshuiPalette palette, {
    required bool hasSnowCover,
  }) {
    canvas.save();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    path.close();

    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, botColor, palette.skyBottom],
      stops: const [0.0, 0.72, 1.0],
    ).createShader(Rect.fromLTWH(0, gradTopY, 1500, 610 - gradTopY));
    canvas.drawPath(path, Paint()..shader = grad);

    canvas.clipPath(path);
    for (int index = 1; index < points.length - 2; index++) {
      final vertex = points[index];
      final strokePath = Path()
        ..moveTo(vertex.dx, vertex.dy)
        ..quadraticBezierTo(
          vertex.dx - 18 + (index % 3) * 14,
          vertex.dy + 120,
          vertex.dx - 35 + (index % 2) * 30,
          vertex.dy + 290,
        );
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = palette.cragStroke.withValues(alpha: 0.42)
          ..strokeWidth = 3.5 + (index % 4) * 2.5
          ..style = PaintingStyle.stroke,
      );

      final highlightPath = Path()
        ..moveTo(vertex.dx + 3, vertex.dy + 2)
        ..lineTo(vertex.dx + 28, vertex.dy + 95)
        ..lineTo(vertex.dx - 8, vertex.dy + 115)
        ..close();
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = (hasSnowCover ? const Color(0xFFF7FAFC) : palette.cragHighlight)
              .withValues(alpha: hasSnowCover ? 0.82 : 0.34),
      );
    }
    canvas.restore();
  }

  static void drawCurvedRoof(
    Canvas canvas,
    double cx,
    double yTop,
    double topW,
    double botW,
    double height,
    Color roofFill,
    bool isWinter,
  ) {
    canvas.save();
    final halfTop = topW / 2;
    final halfBot = botW / 2;
    final path = Path()
      ..moveTo(cx - halfTop, yTop)
      ..lineTo(cx + halfTop, yTop)
      ..quadraticBezierTo(
        cx + halfTop + (halfBot - halfTop) * 0.55,
        yTop + height * 0.82,
        cx + halfBot,
        yTop + height * 0.62,
      )
      ..lineTo(cx + halfBot - 8, yTop + height)
      ..quadraticBezierTo(cx, yTop + height + 4, cx - halfBot + 8, yTop + height)
      ..lineTo(cx - halfBot, yTop + height * 0.62)
      ..quadraticBezierTo(
        cx - halfTop - (halfBot - halfTop) * 0.55,
        yTop + height * 0.82,
        cx - halfTop,
        yTop,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = roofFill);

    if (isWinter) {
      final snowPath = Path()
        ..moveTo(cx - halfTop - 4, yTop)
        ..lineTo(cx + halfTop + 4, yTop)
        ..quadraticBezierTo(
          cx + halfBot * 0.75,
          yTop + height * 0.72,
          cx + halfBot,
          yTop + height * 0.60,
        )
        ..quadraticBezierTo(cx, yTop + height * 0.85, cx - halfBot, yTop + height * 0.60)
        ..quadraticBezierTo(
          cx - halfBot * 0.75,
          yTop + height * 0.72,
          cx - halfTop - 4,
          yTop,
        )
        ..close();
      canvas.drawPath(snowPath, Paint()..color = const Color(0xE0F8FAFC));
    }
    canvas.restore();
  }

  static void drawCenterPavilion(
    Canvas canvas,
    double pavCX,
    double pavBaseY,
    ShanshuiPalette palette, {
    required bool hasSnowCover,
  }) {
    canvas.drawRect(
      Rect.fromLTWH(pavCX - 68, pavBaseY - 8, 136, 12),
      Paint()..color = palette.cragStroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(pavCX - 50, pavBaseY - 38, 100, 30),
      Paint()..color = palette.windowGlow,
    );
    drawCurvedRoof(
      canvas,
      pavCX,
      pavBaseY - 58,
      96,
      156,
      22,
      palette.roofColor,
      hasSnowCover,
    );
    canvas.drawRect(
      Rect.fromLTWH(pavCX - 32, pavBaseY - 80, 64, 22),
      Paint()..color = palette.windowGlow,
    );
    drawCurvedRoof(
      canvas,
      pavCX,
      pavBaseY - 104,
      28,
      118,
      26,
      palette.roofColor,
      hasSnowCover,
    );
  }

  static void drawLeftPavilionAndBridge(
    Canvas canvas,
    ShanshuiPalette palette, {
    required bool hasSnowCover,
  }) {
    final bankPath = Path()
      ..moveTo(-20, 665)
      ..lineTo(395, 650)
      ..lineTo(435, 680)
      ..lineTo(-20, 710)
      ..close();
    canvas.drawPath(bankPath, Paint()..color = palette.cragStroke);

    final bridgePath = Path()
      ..moveTo(25, 668)
      ..quadraticBezierTo(105, 622, 185, 658)
      ..lineTo(185, 672)
      ..quadraticBezierTo(105, 638, 25, 682)
      ..close();
    canvas.drawPath(bridgePath, Paint()..color = palette.woodColor);

    const hallX = 215.0;
    const hallY = 648.0;
    canvas.drawRect(
      const Rect.fromLTWH(hallX - 58, hallY - 48, 116, 42),
      Paint()..color = palette.windowGlow,
    );
    drawCurvedRoof(canvas, hallX + 55, hallY - 64, 52, 102, 22, palette.roofColor, hasSnowCover);
    drawCurvedRoof(canvas, hallX - 10, hallY - 72, 92, 158, 26, palette.roofColor, hasSnowCover);
    canvas.drawRect(
      const Rect.fromLTWH(hallX - 42, hallY - 108, 64, 36),
      Paint()..color = palette.windowGlow,
    );
    drawCurvedRoof(canvas, hallX - 10, hallY - 138, 36, 126, 30, palette.roofColor, hasSnowCover);
  }

  static void drawRightStudyPavilion(
    Canvas canvas,
    ShanshuiPalette palette, {
    required bool hasSnowCover,
  }) {
    const rightPavX = 1145.0;
    const rightPavY = 640.0;
    canvas.drawRect(
      const Rect.fromLTWH(rightPavX - 65, rightPavY - 12, 145, 16),
      Paint()..color = palette.cragStroke,
    );
    canvas.drawRect(
      const Rect.fromLTWH(rightPavX - 48, rightPavY - 58, 108, 46),
      Paint()..color = palette.windowGlow,
    );
    canvas.drawCircle(
      const Offset(rightPavX + 8, rightPavY - 32),
      5.5,
      Paint()..color = palette.trunkColor,
    );
    final bodyPath = Path()
      ..moveTo(rightPavX - 2, rightPavY - 14)
      ..quadraticBezierTo(rightPavX + 8, rightPavY - 28, rightPavX + 18, rightPavY - 14)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = palette.trunkColor);
    drawCurvedRoof(
      canvas,
      rightPavX + 4,
      rightPavY - 92,
      82,
      168,
      34,
      palette.roofColor,
      hasSnowCover,
    );
  }

  static void drawTreesAndFoliage(
    Canvas canvas,
    ShanshuiPalette palette, {
    required bool hasSnowCover,
  }) {
    for (final cluster in ShanshuiGeometry.foliageClusters) {
      final color = cluster.role == FoliageRole.primary
          ? palette.foliagePrimary
          : cluster.role == FoliageRole.secondary
              ? palette.foliageSecondary
              : palette.foliageAccent;
      canvas.drawLine(
        Offset(cluster.x, cluster.y + cluster.r + 28),
        Offset(cluster.x, cluster.y),
        Paint()
          ..color = palette.trunkColor
          ..strokeWidth = 3.5,
      );
      _drawFoliageDabs(canvas, cluster.x, cluster.y, cluster.r, color, hasSnowCover);
    }
  }

  static void _drawFoliageDabs(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Color color,
    bool hasSnowCover,
  ) {
    final paint = Paint()..color = color.withValues(alpha: 0.86);
    canvas.drawCircle(Offset(cx, cy), radius, paint);
    canvas.drawCircle(Offset(cx - radius * 0.55, cy + radius * 0.15), radius * 0.75, paint);
    canvas.drawCircle(Offset(cx + radius * 0.55, cy + radius * 0.2), radius * 0.72, paint);

    if (hasSnowCover) {
      final snowPaint = Paint()..color = const Color(0xFAF8FAFC);
      canvas.drawCircle(Offset(cx, cy - radius * 0.35), radius * 0.65, snowPaint);
      canvas.drawCircle(Offset(cx - radius * 0.45, cy), radius * 0.48, snowPaint);
    }
  }

  static void drawBoats(
    Canvas canvas,
    ShanshuiPalette palette, {
    required double time,
    required double wind,
    required bool hasSnowCover,
  }) {
    final boatDriftX = math.sin(time * 0.35 * math.min(1.6, wind)) * 42.0;
    final boatBobY = math.sin(time * 1.9 * wind) * 3.0;
    final boatX = 655.0 + boatDriftX;
    final boatY = 705.0 + boatBobY;

    canvas.save();
    canvas.translate(boatX, boatY);

    final hullPath = Path()
      ..moveTo(-64, -8)
      ..quadraticBezierTo(-15, 8, 66, -6)
      ..lineTo(50, 7)
      ..quadraticBezierTo(0, 11, -50, 6)
      ..close();
    canvas.drawPath(hullPath, Paint()..color = palette.trunkColor);

    final canopyColor = hasSnowCover ? const Color(0xFF333A40) : const Color(0xFF3B322C);
    canvas.drawArc(
      const Rect.fromLTWH(-30, -16, 36, 36),
      math.pi,
      math.pi,
      true,
      Paint()..color = canopyColor,
    );
    canvas.drawArc(
      const Rect.fromLTWH(0, -14, 32, 32),
      math.pi,
      math.pi,
      true,
      Paint()..color = canopyColor,
    );

    final boatmanPath = Path()
      ..moveTo(42, 2)
      ..lineTo(45, -14)
      ..lineTo(50, 2)
      ..close();
    canvas.drawPath(boatmanPath, Paint()..color = palette.trunkColor);

    final hatPath = Path()
      ..moveTo(37, -14)
      ..lineTo(46, -20)
      ..lineTo(55, -14)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = palette.trunkColor);

    canvas.restore();
  }

  static void drawCrane(Canvas canvas, ShanshuiCrane crane, double time, bool isNight) {
    canvas.save();
    final cy = crane.y + math.sin(time * 2.2 + crane.phase) * crane.yAmp;
    canvas.translate(crane.x, cy);
    canvas.scale(crane.scale, crane.scale);

    final flap = math.sin(time * 6.2 + crane.phase);
    final wingTipY = -22.0 * flap - 6.0;

    final bodyPath = Path()
      ..moveTo(-12, 3)
      ..quadraticBezierTo(0, -3, 12, 0)
      ..quadraticBezierTo(22, -4, 30, -8)
      ..lineTo(37, -7)
      ..lineTo(29, -4)
      ..quadraticBezierTo(18, 2, 4, 5)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()..color = isNight ? const Color(0xFFF8FAFC) : const Color(0xFFFAF8F5),
    );

    final wingPath = Path()
      ..moveTo(2, 1)
      ..quadraticBezierTo(10, wingTipY * 0.5, 18, wingTipY)
      ..quadraticBezierTo(4, wingTipY * 0.5 + 4, -6, 3)
      ..close();
    canvas.drawPath(
      wingPath,
      Paint()..color = isNight ? const Color(0xFFE2E8F0) : const Color(0xFF1F1F1F),
    );

    if (crane.isHero) {
      canvas.drawCircle(const Offset(29, -7.5), 2.2, Paint()..color = const Color(0xFFC83E31));
    }
    canvas.restore();
  }
}
