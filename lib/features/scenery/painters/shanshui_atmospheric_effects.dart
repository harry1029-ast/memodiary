import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../templates/services/stationery_geometry.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';

/// Placement and typography configuration for a realm's calligraphy colophon
/// (题跋), poetic couplet, and carved cinnabar seal (朱砂印).
@immutable
class SceneryCalligraphyConfig {
  final double titleX;
  final double titleY;
  final double titleStepY;
  final double titleFontSize;
  final double poemStartX;
  final double poemStartY;
  final double poemColumnStepX;
  final double poemStepY;
  final double poemFontSize;
  final double poemAlpha;
  final double sealX;
  final double? sealY;
  final double sealTopGap;
  final double sealSize;
  final double sealFontSize;
  final double sealAlpha;
  final double? sealStrokeWidth;
  final String fontFamily;
  final Color dayTextColor;
  final Color nightTextColor;
  final Color? dayShadowColor;
  final Color? nightShadowColor;
  final double shadowBlurRadius;

  const SceneryCalligraphyConfig({
    required this.titleX,
    required this.titleY,
    this.titleStepY = 30.0,
    this.titleFontSize = 26.0,
    required this.poemStartX,
    required this.poemStartY,
    this.poemColumnStepX = -28.0,
    this.poemStepY = 22.0,
    this.poemFontSize = 17.0,
    this.poemAlpha = 0.82,
    required this.sealX,
    this.sealY,
    this.sealTopGap = 8.0,
    this.sealSize = 36.0,
    this.sealFontSize = 12.0,
    this.sealAlpha = 1.0,
    this.sealStrokeWidth,
    this.fontFamily = 'serif',
    this.dayTextColor = const Color.fromRGBO(38, 28, 20, 0.86),
    this.nightTextColor = const Color.fromRGBO(248, 244, 232, 0.92),
    this.dayShadowColor = const Color(0xBFFFF8EB),
    this.nightShadowColor = const Color(0xBF000000),
    this.shadowBlurRadius = 6.0,
  });
}

/// Shared dynamic atmospheric rendering helpers (stormy lightning bolts,
/// seasonal particles & fireflies, rain puddle ripples, precipitation, and
/// carved cinnabar seals) across the five scenery realms.
class ShanshuiAtmosphericEffects {
  const ShanshuiAtmosphericEffects._();

  /// Renders a deterministic multi-segment jagged stormy lightning bolt in the sky.
  static void drawJaggedLightningBolt(
    Canvas canvas, {
    required double time,
    required double alpha,
    double startXMin = 520.0,
    double startXSpan = 460.0,
    double startY = 15.0,
    int segmentCount = 8,
    double horizontalSpread = 60.0,
    double verticalStepBase = 34.0,
    double verticalStepSpan = 26.0,
    bool includeOuterGlow = true,
    double strokeWidth = 3.0,
  }) {
    final strikeSeed = (time / 2.5).floor();
    final rng = math.Random(strikeSeed * 97 + 13);
    var currX = startXMin + rng.nextDouble() * startXSpan;
    var currY = startY;
    final boltPath = Path()..moveTo(currX, currY);

    for (int segment = 0; segment < segmentCount; segment++) {
      currX += (rng.nextDouble() - 0.5) * horizontalSpread;
      currY += verticalStepBase + rng.nextDouble() * verticalStepSpan;
      boltPath.lineTo(currX, currY);
    }

    if (includeOuterGlow) {
      canvas.drawPath(
        boltPath,
        Paint()
          ..color = Colors.lightBlueAccent.withValues(alpha: (alpha * 0.35).clamp(0.0, 1.0))
          ..strokeWidth = 7.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawPath(
      boltPath,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Renders deterministic expanding puddle ripples during rainy or stormy weather.
  static void drawRainPuddleRipples(
    Canvas canvas, {
    required double time,
    required bool isStormy,
    required Color rippleColor,
    required double minY,
    required double spanY,
    required double Function(double y) minXAt,
    required double Function(double y) maxXAt,
    required double aspectRatio,
    required double strokeWidth,
    required double minRadius,
    required double maxRadiusExpand,
    required double baseAlpha,
    int seedMultiplier = 73,
  }) {
    final period = isStormy ? 0.75 : 1.05;
    for (int slot = 0; slot < 14; slot++) {
      final rawTime = time + slot * 0.37;
      final cycle = (rawTime / period).floor();
      final age = (rawTime % period) / period;
      final rng = math.Random(slot * seedMultiplier + cycle * 19 + 7);
      final ry = minY + rng.nextDouble() * spanY;
      final leftBound = minXAt(ry);
      final rightBound = maxXAt(ry);
      final rx = leftBound + rng.nextDouble() * math.max(10.0, rightBound - leftBound);
      final radius = minRadius + age * maxRadiusExpand;
      final alpha = (1.0 - age) * baseAlpha;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rx, ry),
          width: radius * 2,
          height: radius * aspectRatio,
        ),
        Paint()
          ..color = rippleColor.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  /// Renders seasonal particles: upward-pulsing fireflies (`萤火虫`), snow, or
  /// rotating tilted elliptical petals/leaves.
  static void drawSeasonalParticles(
    Canvas canvas,
    List<ShanshuiParticle> particles, {
    required double time,
    required double wind,
    required bool isNight,
    required bool isDusk,
    required bool isFireflies,
    required bool isSnow,
    required Color color1,
    required Color color2,
  }) {
    for (final particle in particles) {
      final baseColor = particle.colorToggle ? color1 : color2;
      if (isFireflies) {
        final fx = ((particle.x + math.sin(time * 1.4 + particle.phase) * 18.0 * wind) % 1500.0 +
                1500.0) %
            1500.0;
        final fy = 980.0 - ((particle.y + time * 35.0) % 900.0);
        final pulse = 0.3 + 0.7 * math.sin(time * 2.6 + particle.phase).abs();
        final alpha = ((isNight || isDusk) ? pulse * 0.92 : pulse * 0.45).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(fx, fy),
          particle.size * 1.4,
          Paint()..color = baseColor.withValues(alpha: (alpha * 0.25).clamp(0.0, 1.0)),
        );
        canvas.drawCircle(
          Offset(fx, fy),
          particle.size * 0.7,
          Paint()..color = baseColor.withValues(alpha: alpha),
        );
      } else if (isSnow) {
        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size * 0.55,
          Paint()..color = baseColor.withValues(alpha: 0.85),
        );
      } else {
        canvas.save();
        canvas.translate(particle.x, particle.y);
        canvas.rotate(particle.angle);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size * 2,
            height: particle.size * 0.96,
          ),
          Paint()..color = baseColor.withValues(alpha: 0.85),
        );
        canvas.restore();
      }
    }
  }

  /// Renders rain streaks or snow flakes for rainy, stormy, and snowy weather.
  static void drawPrecipitation(
    Canvas canvas,
    List<ShanshuiWeatherDrop> drops, {
    required ShanshuiWeather weather,
    required Color rainColor,
    required double rainStrokeWidth,
    required double slantMultiplier,
    required double lengthMultiplier,
    required double snowAlpha,
  }) {
    if (weather == ShanshuiWeather.rainy || weather == ShanshuiWeather.stormy) {
      final isStorm = weather == ShanshuiWeather.stormy;
      final slantX = isStorm ? -6.5 : -2.6;
      final dropPaint = Paint()
        ..color = rainColor
        ..strokeWidth = rainStrokeWidth;
      for (final drop in drops) {
        canvas.drawLine(
          Offset(drop.x, drop.y),
          Offset(drop.x + slantX * slantMultiplier, drop.y + drop.len * lengthMultiplier),
          dropPaint,
        );
      }
    } else if (weather == ShanshuiWeather.snowy) {
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: snowAlpha);
      for (final drop in drops) {
        canvas.drawCircle(Offset(drop.x, drop.y), drop.size * 0.72, snowPaint);
      }
    }
  }

  /// Splits a poetic couplet into at most two vertical columns at natural
  /// sentence or clause boundaries, falling back to a balanced midpoint split.
  static List<String> splitPoemColumns(String rawPoem) {
    final stripPunct = RegExp(r'[，。、；：！？,\.\s]+');
    final sentences = rawPoem
        .split(RegExp(r'[。！？]+'))
        .map((part) => part.replaceAll(stripPunct, ''))
        .where((part) => part.isNotEmpty)
        .toList();
    if (sentences.length == 2) return sentences;

    final clauses = rawPoem
        .split(stripPunct)
        .where((part) => part.isNotEmpty)
        .toList();
    if (clauses.length == 2) return clauses;

    final clean = clauses.join();
    if (clean.isEmpty) return const [];
    if (clean.length < 2) return [clean];
    final mid = (clean.length / 2).ceil();
    return [clean.substring(0, mid), clean.substring(mid)];
  }

  /// Paints a realm's vertical title, optional poetic couplet, and R-to-L cinnabar seal.
  static void drawCalligraphyAndSeal(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required bool isNight,
    required bool fullPoem,
    required SceneryCalligraphyConfig config,
  }) {
    final title =
        atmosphere.season.nameZhFor(atmosphere.realm).replaceAll(' · ', '');
    final textColor = isNight ? config.nightTextColor : config.dayTextColor;
    final shadowColor =
        isNight ? config.nightShadowColor : config.dayShadowColor;
    final shadows = shadowColor == null
        ? null
        : [Shadow(color: shadowColor, blurRadius: config.shadowBlurRadius)];

    for (int index = 0; index < title.length; index++) {
      final tp = TextPainter(
        text: TextSpan(
          text: title[index],
          style: TextStyle(
            color: textColor,
            fontSize: config.titleFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: config.fontFamily,
            shadows: shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(config.titleX, config.titleY + index * config.titleStepY));
    }

    if (fullPoem) {
      final columns = splitPoemColumns(atmosphere.season.poemFor(atmosphere.realm));
      final poemStyle = TextStyle(
        color: textColor.withValues(alpha: config.poemAlpha),
        fontSize: config.poemFontSize,
        fontFamily: config.fontFamily,
        shadows: shadows,
      );
      for (int col = 0; col < columns.length; col++) {
        final colText = columns[col];
        final colX = config.poemStartX + col * config.poemColumnStepX;
        for (int row = 0; row < colText.length; row++) {
          final tp = TextPainter(
            text: TextSpan(text: colText[row], style: poemStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(colX, config.poemStartY + row * config.poemStepY));
        }
      }
    }

    final resolvedSealY =
        config.sealY ?? (config.titleY + title.length * config.titleStepY + config.sealTopGap);
    drawCinnabarSeal(
      canvas,
      x: config.sealX,
      y: resolvedSealY,
      size: config.sealSize,
      sealText: atmosphere.season.sealTextFor(atmosphere.realm),
      fontSize: config.sealFontSize,
      fontFamily: config.fontFamily,
      alpha: config.sealAlpha,
      strokeWidth: config.sealStrokeWidth,
    );
  }

  /// Renders a soft radial vignette across the normalized 1500x1000 scene frame.
  static void drawVignette(
    Canvas canvas, {
    required bool isNight,
    double radius = 0.85,
    double innerStop = 0.65,
    Color dayEdgeColor = const Color.fromRGBO(32, 22, 14, 0.22),
    Color nightEdgeColor = const Color.fromRGBO(4, 8, 14, 0.48),
  }) {
    const fullRect = Rect.fromLTWH(0, 0, 1500, 1000);
    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: radius,
          colors: [
            Colors.transparent,
            isNight ? nightEdgeColor : dayEdgeColor,
          ],
          stops: [innerStop, 1.0],
        ).createShader(fullRect),
    );
  }

  /// Renders a 2x2 carved square cinnabar seal stamp (`朱砂印`) in R-to-L columns.
  static void drawCinnabarSeal(
    Canvas canvas, {
    required double x,
    required double y,
    required double size,
    required String sealText,
    double fontSize = 12,
    String fontFamily = 'serif',
    double alpha = 1.0,
    double? strokeWidth,
  }) {
    final clampedAlpha = alpha.clamp(0.0, 1.0);
    final creamColor = const Color(0xFFF7F4EB).withValues(alpha: clampedAlpha);
    canvas.drawRect(
      Rect.fromLTWH(x, y, size, size),
      Paint()..color = const Color(0xFFB8332A).withValues(alpha: clampedAlpha),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 3, y + 3, size - 6, size - 6),
      Paint()
        ..color = creamColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth ?? (size >= 40 ? 1.5 : 1.4),
    );

    final layout = StationeryGeometry.buildSealLayout(text: sealText);
    final columns = [layout.colRight, layout.colLeft]
        .where((col) => col.isNotEmpty)
        .toList();
    if (columns.isEmpty) return;

    final sealStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: creamColor,
      fontFamily: fontFamily,
      height: 1.0,
    );

    final innerSize = size - 6.0;
    final colWidth = innerSize / columns.length;
    for (int colIndex = 0; colIndex < columns.length; colIndex++) {
      // Right-to-left traditional seal order: colRight sits on the right.
      final visualCol = (columns.length - 1) - colIndex;
      final colCenterX = x + 3.0 + (visualCol + 0.5) * colWidth;
      final chars = columns[colIndex];
      final rowHeight = innerSize / chars.length;
      for (int rowIndex = 0; rowIndex < chars.length; rowIndex++) {
        final tp = TextPainter(
          text: TextSpan(text: chars[rowIndex], style: sealStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final rowCenterY = y + 3.0 + (rowIndex + 0.5) * rowHeight;
        tp.paint(
          canvas,
          Offset(colCenterX - tp.width / 2, rowCenterY - tp.height / 2),
        );
      }
    }
  }
}
