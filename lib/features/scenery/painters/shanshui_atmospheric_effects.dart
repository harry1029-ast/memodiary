import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';

/// Shared dynamic atmospheric rendering helpers (stormy lightning bolts,
/// seasonal particles & fireflies, rain puddle ripples, precipitation, and
/// carved cinnabar seals) used by both Nature (`山水`) and Outdoor (`街市`).
class ShanshuiAtmosphericEffects {
  const ShanshuiAtmosphericEffects._();

  /// Renders a deterministic multi-segment jagged stormy lightning bolt in the sky.
  static void drawJaggedLightningBolt(
    Canvas canvas, {
    required double time,
    required double alpha,
  }) {
    final strikeSeed = (time / 2.5).floor();
    final rng = math.Random(strikeSeed * 97 + 13);
    var currX = 520.0 + rng.nextDouble() * 460.0;
    var currY = 15.0;
    final boltPath = Path()..moveTo(currX, currY);

    for (int segment = 0; segment < 8; segment++) {
      currX += (rng.nextDouble() - 0.5) * 60.0;
      currY += 34.0 + rng.nextDouble() * 26.0;
      boltPath.lineTo(currX, currY);
    }

    canvas.drawPath(
      boltPath,
      Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: (alpha * 0.35).clamp(0.0, 1.0))
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      boltPath,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..strokeWidth = 3.0
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

  /// Renders a 2x2 carved square cinnabar seal stamp (`朱砂印`).
  static void drawCinnabarSeal(
    Canvas canvas, {
    required double x,
    required double y,
    required double size,
    required String sealText,
    double fontSize = 12,
    double colStep = 0,
    double rowOffset1 = 5,
    double rowOffset2 = 18,
    double leftPad = 5,
    bool verticalColumns = false,
  }) {
    canvas.drawRect(Rect.fromLTWH(x, y, size, size), Paint()..color = const Color(0xFFB8332A));
    canvas.drawRect(
      Rect.fromLTWH(x + 3, y + 3, size - 6, size - 6),
      Paint()
        ..color = const Color(0xFFF7F4EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size >= 40 ? 1.5 : 1.4,
    );

    if (sealText.length < 4) return;

    final sealStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFF7F4EB),
      fontFamily: 'serif',
      height: verticalColumns ? 1.1 : null,
    );

    if (verticalColumns) {
      final col1 = '${sealText[0]}\n${sealText[1]}';
      final col2 = '${sealText[2]}\n${sealText[3]}';
      final p1 = TextPainter(
        text: TextSpan(text: col1, style: sealStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final p2 = TextPainter(
        text: TextSpan(text: col2, style: sealStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      p1.paint(canvas, Offset(x + leftPad, y + rowOffset1));
      p2.paint(canvas, Offset(x + leftPad + colStep, y + rowOffset1));
    } else {
      final tp1 = TextPainter(
        text: TextSpan(text: sealText.substring(0, 2), style: sealStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final tp2 = TextPainter(
        text: TextSpan(text: sealText.substring(2, 4), style: sealStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp1.paint(canvas, Offset(x + leftPad, y + rowOffset1));
      tp2.paint(canvas, Offset(x + leftPad, y + rowOffset2));
    }
  }
}
