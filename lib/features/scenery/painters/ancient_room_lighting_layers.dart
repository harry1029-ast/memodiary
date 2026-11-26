import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'ancient_room_furniture_layers.dart';

/// Dynamic lighting, atmospheric glow, smoke, particle, and calligraphy
/// rendering helpers for the Indoor Tea Hall (`室内`).
class AncientRoomLightingLayers {
  const AncientRoomLightingLayers._();

  /// Paints dual `BlendMode.screen` volumetric rays and floor light pools.
  static void paintVolumetricLightBeams(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required AncientRoomPalette palette,
  }) {
    final beamAlpha = atmosphere.weather.indoorBeamMultiplier;
    if (beamAlpha <= 0.04) return;

    final beamColor = palette.lightBeamColor.withValues(
      alpha: (palette.lightBeamColor.a * beamAlpha).clamp(0.0, 1.0),
    );

    // Volumetric Ray 1: Streaming from Left Moon Window onto table & floor
    final ray1Path = Path()
      ..moveTo(45, 210)
      ..lineTo(220, 320)
      ..lineTo(1060, 950)
      ..lineTo(240, 990)
      ..close();
    canvas.drawPath(
      ray1Path,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          const Offset(65, 360),
          const Offset(880, 920),
          [beamColor, beamColor, const Color(0x00FFFFFF)],
          const [0.0, 0.65, 1.0],
        ),
    );

    // Volumetric Ray 2: Streaming through Center Moon Gate onto floor
    final ray2Path = Path()
      ..moveTo(605, 580)
      ..lineTo(835, 580)
      ..lineTo(1020, 890)
      ..lineTo(520, 890)
      ..close();
    canvas.drawPath(
      ray2Path,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          const Offset(720, 480),
          const Offset(760, 880),
          [beamColor, const Color(0x00FFFFFF)],
        ),
    );

    // 2 Elliptical floor light pools clipped clear of the foreground tea table
    canvas.save();
    final floorClip = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(0, 620, 1500, 380))
      ..addPath(AncientRoomFurnitureLayers.buildTeaTableSurfacePath(), Offset.zero);
    canvas.clipPath(floorClip);

    final poolPaint = Paint()
      ..blendMode = BlendMode.screen
      ..color = palette.floorPatchColor.withValues(
        alpha: (palette.floorPatchColor.a * beamAlpha).clamp(0.0, 1.0),
      );

    canvas.save();
    canvas.translate(690, 845);
    canvas.rotate(0.12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 520, height: 150),
      poolPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(735, 695);
    canvas.rotate(0.05);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 290, height: 84),
      poolPaint,
    );
    canvas.restore();

    canvas.restore();
  }

  /// Paints curling incense smoke & tea steam particle spheres.
  static void paintSmokeAndSteam(
    Canvas canvas, {
    required double animationTime,
    required double windFactor,
    required bool isNight,
  }) {
    for (int index = 0; index < 28; index++) {
      final isTea = index.isOdd;
      final progress = ((index / 28.0) + animationTime * 0.21) % 1.0;
      final phase = index * 2.39996;
      final startX = isTea ? 595.0 : 612.0;
      final startY = isTea ? 702.0 : 805.0;
      final riseH = isTea ? 85.0 : 155.0;
      final waveX = math.sin(
            progress * math.pi * 3.0 + animationTime * 1.8 + phase,
          ) *
          (8.0 + progress * 22.0 * windFactor);
      final curX = startX + waveX;
      final curY = startY - progress * riseH;
      final alpha = (math.sin(progress * math.pi) * (isTea ? 0.25 : 0.34))
          .clamp(0.0, 1.0);
      final color = isNight
          ? Color.fromRGBO(215, 225, 235, alpha)
          : Color.fromRGBO(245, 240, 232, alpha);
      canvas.drawCircle(
        Offset(curX, curY),
        3.0 + progress * 14.0,
        Paint()..color = color,
      );
    }
  }

  /// Paints ambient room wash, weather dimming, lightning flash, and
  /// `BlendMode.screen` 4-lamp halo re-reinforcement.
  static void paintAmbientAndScreenHalos(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required AncientRoomPalette palette,
    required double lightningAlpha,
    required double candleLevel,
    required double flicker1,
    required double flicker2,
    required double chandelierX,
  }) {
    const fullRoomRect = Rect.fromLTWH(0, 0, 1500, 1000);
    canvas.drawRect(fullRoomRect, Paint()..color = palette.ambientOverlay);

    final dimming = atmosphere.weather.ambientDimming;
    if (dimming > 0.0) {
      canvas.drawRect(
        fullRoomRect,
        Paint()..color = Color.fromRGBO(14, 20, 28, dimming),
      );
    }

    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.03) {
      canvas.drawRect(
        fullRoomRect,
        Paint()
          ..color = Color.fromRGBO(
            225,
            240,
            255,
            (lightningAlpha * 0.28).clamp(0.0, 0.5),
          ),
      );
    }

    if (candleLevel > 0.35) {
      paintCandleGlow(
        canvas,
        const Offset(465, 850),
        260.0,
        candleLevel * 0.65,
        flicker1,
        showFlame: false,
        blendMode: BlendMode.screen,
      );
      paintCandleGlow(
        canvas,
        const Offset(335, 535),
        190.0,
        candleLevel * 0.55,
        flicker2,
        showFlame: false,
        blendMode: BlendMode.screen,
      );
      paintCandleGlow(
        canvas,
        Offset(chandelierX, 215),
        250.0,
        candleLevel * 0.50,
        flicker2,
        showFlame: false,
        blendMode: BlendMode.screen,
      );
      paintCandleGlow(
        canvas,
        const Offset(1286, 415),
        145.0,
        candleLevel * 0.50,
        flicker1,
        showFlame: false,
        blendMode: BlendMode.screen,
      );
    }
  }

  /// Paints sparkling golden indoor dust motes and rotating elliptical petals.
  static void paintIndoorParticles(
    Canvas canvas, {
    required List<ShanshuiParticle> particles,
    required AncientRoomPalette palette,
    required double animationTime,
    required bool isNight,
  }) {
    for (int index = 0; index < particles.length; index++) {
      final particle = particles[index];
      final isPetal = index % 3 == 0;
      if (isPetal) {
        canvas.save();
        canvas.translate(particle.x, particle.y);
        canvas.rotate(particle.angle);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size * 2.3,
            height: particle.size * 1.1,
          ),
          Paint()..color = palette.particleColor1.withValues(alpha: 0.78),
        );
        canvas.restore();
      } else {
        final sparkle = 0.2 +
            0.6 * math.sin(animationTime * 2.2 + particle.phase).abs();
        final moteColor = isNight
            ? const Color(0xFFFFE599)
            : const Color(0xFFFFF8DC);
        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size * 0.42,
          Paint()..color = moteColor.withValues(alpha: (sparkle * 0.65).clamp(0.0, 1.0)),
        );
      }
    }
  }

  /// Paints a multi-stop radial candle/lantern halo and optional flickering flame.
  static void paintCandleGlow(
    Canvas canvas,
    Offset center,
    double baseRadius,
    double intensity,
    double flicker, {
    bool showFlame = true,
    BlendMode? blendMode,
  }) {
    if (intensity <= 0.05) return;

    final clampedIntensity = intensity.clamp(0.0, 1.0);
    final radius = baseRadius * (0.94 + flicker * 0.08);
    final innerStop = (4.0 / radius).clamp(0.0, 0.25);

    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Color.fromRGBO(255, 240, 185, (0.85 * clampedIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 175, 75, (0.46 * clampedIntensity).clamp(0.0, 1.0)),
          Color.fromRGBO(235, 115, 35, (0.16 * clampedIntensity).clamp(0.0, 1.0)),
          const Color.fromRGBO(235, 115, 35, 0.0),
        ],
        [innerStop, 0.28, 0.65, 1.0],
      );
    if (blendMode != null) {
      glowPaint.blendMode = blendMode;
    }
    canvas.drawCircle(center, radius, glowPaint);

    if (showFlame) {
      final flameHeight = 14.0 + flicker * 4.0;
      final flameLean = flicker * 2.5;
      final flamePath = Path()
        ..moveTo(center.dx, center.dy + 4.0)
        ..quadraticBezierTo(
          center.dx - 5.0,
          center.dy - flameHeight * 0.4,
          center.dx + flameLean,
          center.dy - flameHeight,
        )
        ..quadraticBezierTo(
          center.dx + 5.0,
          center.dy - flameHeight * 0.4,
          center.dx,
          center.dy + 4.0,
        )
        ..close();
      canvas.drawPath(
        flamePath,
        Paint()
          ..color = Color.fromRGBO(
            255,
            245,
            200,
            (0.95 * clampedIntensity).clamp(0.0, 1.0),
          ),
      );
    }
  }
}
