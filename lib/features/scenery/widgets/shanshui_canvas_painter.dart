import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_palette.dart';
import '../models/shanshui_scenery_geometry.dart';

/// 11-layer procedural vector painter rendering the classical Chinese Shanshui
/// landscape painting in true vector coordinates ($1500 \times 1000$ internal space).
class ShanshuiCanvasPainter extends CustomPainter {
  final ShanshuiAtmosphereState atmosphere;
  final ShanshuiPalette palette;
  final double animationTime; // elapsed time in seconds
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
  final List<ShanshuiCrane> cranes;
  final List<ShanshuiRipple> ripples;
  final bool showCalligraphy;
  final bool fullPoem;
  final double lightningAlpha;

  const ShanshuiCanvasPainter({
    required this.atmosphere,
    required this.palette,
    required this.animationTime,
    required this.particles,
    required this.weatherDrops,
    required this.cranes,
    required this.ripples,
    this.showCalligraphy = true,
    this.fullPoem = true,
    this.lightningAlpha = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale canvas coordinates from 1500x1000 to destination size
    canvas.save();
    canvas.scale(size.width / 1500.0, size.height / 1000.0);

    final isWinter = atmosphere.season == ShanshuiSeason.winter;
    final isSnowWeather = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnowCover = isWinter || isSnowWeather;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final wind = atmosphere.weather.windFactor;
    final t = animationTime;

    // 1. Sky Gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.skyTop, palette.skyMid, palette.skyBottom],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 1500, 625));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 625), skyPaint);

    if (atmosphere.weather.skyOverlay != null) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1500, 625),
        Paint()..color = atmosphere.weather.skyOverlay!,
      );
    }

    // Stars at Night or Dawn
    if ((isNight || isDawn) &&
        (atmosphere.weather == ShanshuiWeather.sunny || isSnowWeather)) {
      final starCount = isDawn ? 18 : 42;
      final maxStarY = isDawn ? 220.0 : 360.0;
      for (int i = 0; i < starCount; i++) {
        final sx = ((i * 379) % 1460) + 20.0;
        final sy = ((i * 197) % maxStarY) + 20.0;
        final twinkle = (isDawn ? 0.15 : 0.25) + 0.45 * math.sin(t * 1.8 + i);
        canvas.drawCircle(
          Offset(sx, sy),
          (i % 3 == 0) ? 1.8 : 1.1,
          Paint()..color = Colors.white.withValues(alpha: twinkle.clamp(0.0, 1.0)),
        );
      }
    }

    // Sheet Lightning
    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.05) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1500, 625),
        Paint()..color = Color.fromRGBO(240, 246, 255, (lightningAlpha * 0.45).clamp(0.0, 1.0)),
      );
    }

    // 2. Celestial Body (Dawn Sun, Sun, or Moon)
    final celestialX = isDawn ? 655.0 : 695.0;
    final celestialY = isDawn ? 295.0 : (atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk ? 245.0 : 165.0);
    final celestialR = isDawn ? 54.0 : (atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk ? 58.0 : 48.0);

    // Celestial Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.celestialGlow.withValues(alpha: (palette.celestialGlow.a * atmosphere.weather.celestialAlpha).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(celestialX, celestialY), radius: celestialR * 3.4));
    canvas.drawCircle(Offset(celestialX, celestialY), celestialR * 3.4, haloPaint);

    // Celestial Disc
    final celestialAlphaVal = (isNight ? 0.94 : 0.86) * atmosphere.weather.celestialAlpha;
    canvas.drawCircle(
      Offset(celestialX, celestialY),
      celestialR,
      Paint()..color = palette.celestialColor.withValues(alpha: celestialAlphaVal.clamp(0.0, 1.0)),
    );

    // 3. Distant Layered Mountains
    _drawPolygon(canvas, ShanshuiGeometry.farMountain1, LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.farMtn.withValues(alpha: 0.55), palette.skyBottom.withValues(alpha: 0.55)],
    ).createShader(const Rect.fromLTWH(0, 160, 1500, 420)));

    _drawPolygon(canvas, ShanshuiGeometry.farMountain2, LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.midMtn.withValues(alpha: 0.65), palette.skyBottom.withValues(alpha: 0.65)],
    ).createShader(const Rect.fromLTWH(0, 190, 1500, 410)));

    // 4. Midground Karst Crags
    _drawKarstMass(canvas, ShanshuiGeometry.leftKarstBack, 68, palette.nearMtn, palette.midMtn, hasSnowCover);
    _drawKarstMass(canvas, ShanshuiGeometry.rightKarstPeaks, 210, palette.midMtn, palette.farMtn, hasSnowCover);
    _drawKarstMass(canvas, ShanshuiGeometry.leftKarstFront, 145, palette.cragStroke, palette.nearMtn, hasSnowCover);

    // Waterfall
    final wfX = 248.0;
    final wfY = 235.0;
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

    // Drifting Mist Band
    final mistShift = (t * 22 * wind) % 1500;
    final mistPaint = Paint()..color = palette.mistColor;
    for (int i = -1; i <= 1; i++) {
      final mx = i * 1500.0 - mistShift;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx + 300, 465), width: 580, height: 72 * atmosphere.weather.mistMultiplier),
        mistPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx + 820, 485), width: 720, height: 84 * atmosphere.weather.mistMultiplier),
        mistPaint,
      );
    }

    // 5. Center Island & Grand Pavilion
    _drawPolygon(canvas, ShanshuiGeometry.centerIslandHill, LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.nearMtn, palette.cragStroke],
    ).createShader(const Rect.fromLTWH(590, 510, 395, 135)));

    _drawCenterPavilion(canvas, 790.0, 522.0, hasSnowCover);

    // 6. Calm Mirror Lake
    const waterHorizonY = 622.0;
    final lakePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.waterTop, palette.skyBottom, palette.waterBottom],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(const Rect.fromLTWH(0, waterHorizonY, 1500, 1000 - waterHorizonY));
    canvas.drawRect(const Rect.fromLTWH(0, waterHorizonY, 1500, 1000 - waterHorizonY), lakePaint);

    // Lake Shimmer Reflection
    for (double wy = waterHorizonY + 12; wy < 940; wy += 9) {
      final progress = (wy - waterHorizonY) / 340.0;
      final shimmerW = (18 + progress * 75) + math.sin(t * 3.2 * wind + wy * 0.15) * 8;
      final shimmerAlpha = (isNight || isDawn ? 0.34 : 0.22) * (1 - progress * 0.7) * atmosphere.weather.celestialAlpha;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(celestialX, wy), width: shimmerW, height: 2.5),
        Paint()..color = palette.celestialColor.withValues(alpha: shimmerAlpha.clamp(0.0, 1.0)),
      );
    }

    // 7. Left Waterside Ancient Pavilion & Arched Bridge
    _drawLeftPavilionAndBridge(canvas, hasSnowCover);

    // 8. Right Waterside Study Pavilion
    _drawRightStudyPavilion(canvas, hasSnowCover);

    // 9. Trees & Seasonal Foliage
    _drawTreesAndFoliage(canvas, hasSnowCover, t, wind);

    // 10. Animated Ferryboat & Fisherman Skiff
    _drawBoats(canvas, t, wind, hasSnowCover);

    // Lake Click Ripples
    for (final ripple in ripples) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ripple.x, ripple.y), width: ripple.radius * 2, height: ripple.radius * 0.44),
        Paint()
          ..color = palette.rippleColor.withValues(alpha: ripple.alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // 11. Animated Flying Cranes
    for (final crane in cranes) {
      _drawCrane(canvas, crane, t, isNight);
    }

    // 12. Particles & Precipitation
    _drawAtmosphericParticles(canvas, t, wind);
    _drawPrecipitation(canvas);

    // 13. Calligraphy Colophon & Cinnabar Seal
    if (showCalligraphy) {
      _drawCalligraphy(canvas, isNight);
    }

    // Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, isNight ? const Color(0x66050A0E) : const Color(0x2E3A3026)],
        stops: const [0.55, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 1500, 1000));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 1000), vignettePaint);

    canvas.restore();
  }

  void _drawPolygon(Canvas canvas, List<Offset> points, Shader shader) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..shader = shader);
  }

  void _drawKarstMass(Canvas canvas, List<Offset> points, double gradTopY, Color topColor, Color botColor, bool hasSnowCover) {
    canvas.save();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, botColor, palette.skyBottom],
      stops: const [0.0, 0.72, 1.0],
    ).createShader(Rect.fromLTWH(0, gradTopY, 1500, 610 - gradTopY));
    canvas.drawPath(path, Paint()..shader = grad);

    // Clip and draw Cunfa rock ridges
    canvas.clipPath(path);
    for (int i = 1; i < points.length - 2; i++) {
      final vertex = points[i];
      final strokePath = Path()
        ..moveTo(vertex.dx, vertex.dy)
        ..quadraticBezierTo(vertex.dx - 18 + (i % 3) * 14, vertex.dy + 120, vertex.dx - 35 + (i % 2) * 30, vertex.dy + 290);
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = palette.cragStroke.withValues(alpha: 0.42)
          ..strokeWidth = 3.5 + (i % 4) * 2.5
          ..style = PaintingStyle.stroke,
      );

      final highlightPath = Path()
        ..moveTo(vertex.dx + 3, vertex.dy + 2)
        ..lineTo(vertex.dx + 28, vertex.dy + 95)
        ..lineTo(vertex.dx - 8, vertex.dy + 115)
        ..close();
      canvas.drawPath(
        highlightPath,
        Paint()..color = (hasSnowCover ? const Color(0xFFF7FAFC) : palette.cragHighlight).withValues(alpha: hasSnowCover ? 0.82 : 0.34),
      );
    }
    canvas.restore();
  }

  void _drawCurvedRoof(Canvas canvas, double cx, double yTop, double topW, double botW, double height, Color roofFill, Color highlightStroke, bool isWinter) {
    canvas.save();
    final halfTop = topW / 2;
    final halfBot = botW / 2;
    final path = Path()
      ..moveTo(cx - halfTop, yTop)
      ..lineTo(cx + halfTop, yTop)
      ..quadraticBezierTo(cx + halfTop + (halfBot - halfTop) * 0.55, yTop + height * 0.82, cx + halfBot, yTop + height * 0.62)
      ..lineTo(cx + halfBot - 8, yTop + height)
      ..quadraticBezierTo(cx, yTop + height + 4, cx - halfBot + 8, yTop + height)
      ..lineTo(cx - halfBot, yTop + height * 0.62)
      ..quadraticBezierTo(cx - halfTop - (halfBot - halfTop) * 0.55, yTop + height * 0.82, cx - halfTop, yTop)
      ..close();

    canvas.drawPath(path, Paint()..color = roofFill);

    // Snow on roof
    if (isWinter) {
      final snowPath = Path()
        ..moveTo(cx - halfTop - 4, yTop)
        ..lineTo(cx + halfTop + 4, yTop)
        ..quadraticBezierTo(cx + halfBot * 0.75, yTop + height * 0.72, cx + halfBot, yTop + height * 0.60)
        ..quadraticBezierTo(cx, yTop + height * 0.85, cx - halfBot, yTop + height * 0.60)
        ..quadraticBezierTo(cx - halfBot * 0.75, yTop + height * 0.72, cx - halfTop - 4, yTop)
        ..close();
      canvas.drawPath(snowPath, Paint()..color = const Color(0xE0F8FAFC));
    }
    canvas.restore();
  }

  void _drawCenterPavilion(Canvas canvas, double pavCX, double pavBaseY, bool hasSnowCover) {
    // Terrace platform
    canvas.drawRect(Rect.fromLTWH(pavCX - 68, pavBaseY - 8, 136, 12), Paint()..color = palette.cragStroke);
    // Lower hall & glowing windows
    canvas.drawRect(Rect.fromLTWH(pavCX - 50, pavBaseY - 38, 100, 30), Paint()..color = palette.windowGlow);
    // Lower eave
    _drawCurvedRoof(canvas, pavCX, pavBaseY - 58, 96, 156, 22, palette.roofColor, palette.roofHighlight, hasSnowCover);
    // Upper chamber
    canvas.drawRect(Rect.fromLTWH(pavCX - 32, pavBaseY - 80, 64, 22), Paint()..color = palette.windowGlow);
    // Upper pointed pagoda roof
    _drawCurvedRoof(canvas, pavCX, pavBaseY - 104, 28, 118, 26, palette.roofColor, palette.roofHighlight, hasSnowCover);
  }

  void _drawLeftPavilionAndBridge(Canvas canvas, bool hasSnowCover) {
    // Rocky embankment
    final bankPath = Path()
      ..moveTo(-20, 665)
      ..lineTo(395, 650)
      ..lineTo(435, 680)
      ..lineTo(-20, 710)
      ..close();
    canvas.drawPath(bankPath, Paint()..color = palette.cragStroke);

    // Arched Bridge
    final bridgePath = Path()
      ..moveTo(25, 668)
      ..quadraticBezierTo(105, 622, 185, 658)
      ..lineTo(185, 672)
      ..quadraticBezierTo(105, 638, 25, 682)
      ..close();
    canvas.drawPath(bridgePath, Paint()..color = palette.woodColor);

    // Two-Story Waterside Hall
    const hallX = 215.0;
    const hallY = 648.0;
    canvas.drawRect(const Rect.fromLTWH(hallX - 58, hallY - 48, 116, 42), Paint()..color = palette.windowGlow);
    _drawCurvedRoof(canvas, hallX + 55, hallY - 64, 52, 102, 22, palette.roofColor, palette.roofHighlight, hasSnowCover);
    _drawCurvedRoof(canvas, hallX - 10, hallY - 72, 92, 158, 26, palette.roofColor, palette.roofHighlight, hasSnowCover);
    // Second story
    canvas.drawRect(const Rect.fromLTWH(hallX - 42, hallY - 108, 64, 36), Paint()..color = palette.windowGlow);
    _drawCurvedRoof(canvas, hallX - 10, hallY - 138, 36, 126, 30, palette.roofColor, palette.roofHighlight, hasSnowCover);
  }

  void _drawRightStudyPavilion(Canvas canvas, bool hasSnowCover) {
    const rightPavX = 1145.0;
    const rightPavY = 640.0;
    // Deck
    canvas.drawRect(const Rect.fromLTWH(rightPavX - 65, rightPavY - 12, 145, 16), Paint()..color = palette.cragStroke);
    // Glowing study room
    canvas.drawRect(const Rect.fromLTWH(rightPavX - 48, rightPavY - 58, 108, 46), Paint()..color = palette.windowGlow);
    // Scholar silhouette
    canvas.drawCircle(const Offset(rightPavX + 8, rightPavY - 32), 5.5, Paint()..color = palette.trunkColor);
    final bodyPath = Path()
      ..moveTo(rightPavX - 2, rightPavY - 14)
      ..quadraticBezierTo(rightPavX + 8, rightPavY - 28, rightPavX + 18, rightPavY - 14)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = palette.trunkColor);
    // Roof
    _drawCurvedRoof(canvas, rightPavX + 4, rightPavY - 92, 82, 168, 34, palette.roofColor, palette.roofHighlight, hasSnowCover);
  }

  void _drawTreesAndFoliage(Canvas canvas, bool hasSnowCover, double t, double wind) {
    for (final cluster in ShanshuiGeometry.foliageClusters) {
      final color = cluster.role == FoliageRole.primary
          ? palette.foliagePrimary
          : cluster.role == FoliageRole.secondary
              ? palette.foliageSecondary
              : palette.foliageAccent;
      // Trunk
      canvas.drawLine(
        Offset(cluster.x, cluster.y + cluster.r + 28),
        Offset(cluster.x, cluster.y),
        Paint()
          ..color = palette.trunkColor
          ..strokeWidth = 3.5,
      );
      // Foliage blobs
      _drawFoliageDabs(canvas, cluster.x, cluster.y, cluster.r, color, hasSnowCover);
    }
  }

  void _drawFoliageDabs(Canvas canvas, double cx, double cy, double radius, Color color, bool hasSnowCover) {
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

  void _drawBoats(Canvas canvas, double t, double wind, bool hasSnowCover) {
    final boatDriftX = math.sin(t * 0.35 * math.min(1.6, wind)) * 42.0;
    final boatBobY = math.sin(t * 1.9 * wind) * 3.0;
    final boatX = 655.0 + boatDriftX;
    final boatY = 705.0 + boatBobY;

    canvas.save();
    canvas.translate(boatX, boatY);

    // Ferryboat hull
    final hullPath = Path()
      ..moveTo(-64, -8)
      ..quadraticBezierTo(-15, 8, 66, -6)
      ..lineTo(50, 7)
      ..quadraticBezierTo(0, 11, -50, 6)
      ..close();
    canvas.drawPath(hullPath, Paint()..color = palette.trunkColor);

    // Canopy
    canvas.drawArc(const Rect.fromLTWH(-30, -16, 36, 36), math.pi, math.pi, true, Paint()..color = hasSnowCover ? const Color(0xFF333A40) : const Color(0xFF3B322C));
    canvas.drawArc(const Rect.fromLTWH(0, -14, 32, 32), math.pi, math.pi, true, Paint()..color = hasSnowCover ? const Color(0xFF333A40) : const Color(0xFF3B322C));

    // Boatman
    final boatmanPath = Path()
      ..moveTo(42, 2)
      ..lineTo(45, -14)
      ..lineTo(50, 2)
      ..close();
    canvas.drawPath(boatmanPath, Paint()..color = palette.trunkColor);

    // Conical bamboo hat
    final hatPath = Path()
      ..moveTo(37, -14)
      ..lineTo(46, -20)
      ..lineTo(55, -14)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = palette.trunkColor);

    canvas.restore();
  }

  void _drawCrane(Canvas canvas, ShanshuiCrane crane, double t, bool isNight) {
    canvas.save();
    final cy = crane.y + math.sin(t * 2.2 + crane.phase) * crane.yAmp;
    canvas.translate(crane.x, cy);
    canvas.scale(crane.scale, crane.scale);

    final flap = math.sin(t * 6.2 + crane.phase);
    final wingTipY = -22.0 * flap - 6.0;

    // Body
    final bodyPath = Path()
      ..moveTo(-12, 3)
      ..quadraticBezierTo(0, -3, 12, 0)
      ..quadraticBezierTo(22, -4, 30, -8)
      ..lineTo(37, -7)
      ..lineTo(29, -4)
      ..quadraticBezierTo(18, 2, 4, 5)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = isNight ? const Color(0xFFF8FAFC) : const Color(0xFFFAF8F5));

    // Wing
    final wingPath = Path()
      ..moveTo(2, 1)
      ..quadraticBezierTo(10, wingTipY * 0.5, 18, wingTipY)
      ..quadraticBezierTo(4, wingTipY * 0.5 + 4, -6, 3)
      ..close();
    canvas.drawPath(wingPath, Paint()..color = isNight ? const Color(0xFFE2E8F0) : const Color(0xFF1F1F1F));

    // Red crown dot
    if (crane.isHero) {
      canvas.drawCircle(const Offset(29, -7.5), 2.2, Paint()..color = const Color(0xFFC83E31));
    }
    canvas.restore();
  }

  void _drawAtmosphericParticles(Canvas canvas, double t, double wind) {
    for (final pt in particles) {
      final color = pt.colorToggle ? palette.particleColor1 : palette.particleColor2;
      canvas.drawCircle(Offset(pt.x, pt.y), pt.size * 0.55, Paint()..color = color.withValues(alpha: 0.8));
    }
  }

  void _drawPrecipitation(Canvas canvas) {
    if (atmosphere.weather == ShanshuiWeather.rainy || atmosphere.weather == ShanshuiWeather.stormy) {
      final isStorm = atmosphere.weather == ShanshuiWeather.stormy;
      final slantX = isStorm ? -6.5 : -2.6;
      final paint = Paint()
        ..color = Color.fromRGBO(215, 230, 240, isStorm ? 0.42 : 0.35)
        ..strokeWidth = isStorm ? 1.8 : 1.2;

      for (final drop in weatherDrops) {
        canvas.drawLine(
          Offset(drop.x, drop.y),
          Offset(drop.x + slantX * 2.2, drop.y + drop.len * (isStorm ? 1.35 : 1.0)),
          paint,
        );
      }
    } else if (atmosphere.weather == ShanshuiWeather.snowy) {
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      for (final drop in weatherDrops) {
        canvas.drawCircle(Offset(drop.x, drop.y), drop.size * 0.72, snowPaint);
      }
    }
  }

  void _drawCalligraphy(Canvas canvas, bool isNight) {
    final textColor = isNight ? const Color(0xDDF1F5F9) : const Color(0xD1231F1C);

    // Vertical title in top-right
    final titleText = atmosphere.season.nameZh.replaceAll(' · ', '');
    final titleSpan = TextSpan(
      text: titleText.split('').join('\n'),
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontFamily: 'serif',
        height: 1.25,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, const Offset(1415, 75));

    // Poetic couplet in full mode
    if (fullPoem) {
      final poemSpan = TextSpan(
        text: atmosphere.season.poem.split('').join('\n'),
        style: TextStyle(
          fontSize: 18,
          color: textColor.withValues(alpha: 0.75),
          fontFamily: 'serif',
          height: 1.3,
        ),
      );
      final poemPainter = TextPainter(
        text: poemSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      poemPainter.paint(canvas, const Offset(1370, 80));
    }

    // Carved Cinnabar Seal Stamp
    const sealX = 1404.0;
    final sealY = 75.0 + titlePainter.height + 15.0;
    canvas.drawRect(
      Rect.fromLTWH(sealX, sealY, 40, 40),
      Paint()..color = const Color(0xFFB8332A),
    );
    canvas.drawRect(
      Rect.fromLTWH(sealX + 3, sealY + 3, 34, 34),
      Paint()
        ..color = const Color(0xFFF7F4EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 4-character seal text (2x2 grid)
    final sealChars = atmosphere.season.sealText;
    final sealCol1 = '${sealChars[0]}\n${sealChars[1]}';
    final sealCol2 = '${sealChars[2]}\n${sealChars[3]}';
    final sealStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFFF7F4EB),
      fontFamily: 'serif',
      height: 1.1,
    );

    final p1 = TextPainter(text: TextSpan(text: sealCol1, style: sealStyle), textDirection: TextDirection.ltr)..layout();
    final p2 = TextPainter(text: TextSpan(text: sealCol2, style: sealStyle), textDirection: TextDirection.ltr)..layout();
    p1.paint(canvas, Offset(sealX + 6, sealY + 7));
    p2.paint(canvas, Offset(sealX + 21, sealY + 7));
  }

  @override
  bool shouldRepaint(covariant ShanshuiCanvasPainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
        oldDelegate.atmosphere != atmosphere ||
        oldDelegate.ripples.length != ripples.length;
  }
}
