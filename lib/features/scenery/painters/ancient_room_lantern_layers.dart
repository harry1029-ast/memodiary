import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import 'ancient_room_lighting_layers.dart';

/// Dynamic lantern, banner, chandelier, and winter hearth painters for the
/// Indoor Tea Hall (`室内`).
class AncientRoomLanternLayers {
  const AncientRoomLanternLayers._();

  /// Paints the twin swaying cream-silk banners (`双垂幔`) flanking the Moon Gate.
  static void paintHangingBanners(
    Canvas canvas, {
    required bool isNight,
    required double animationTime,
    required double windFactor,
  }) {
    _paintSingleBanner(
      canvas,
      x: 432,
      y: 228,
      width: 108,
      height: 225,
      isNight: isNight,
      animationTime: animationTime,
      windFactor: windFactor,
    );
    _paintSingleBanner(
      canvas,
      x: 898,
      y: 228,
      width: 108,
      height: 225,
      isNight: isNight,
      animationTime: animationTime,
      windFactor: windFactor,
    );
  }

  static void _paintSingleBanner(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required double height,
    required bool isNight,
    required double animationTime,
    required double windFactor,
  }) {
    final swayX =
        math.sin(animationTime * 1.5 * windFactor + x * 0.01) * (3.5 * windFactor);

    final bannerPath = Path()
      ..moveTo(x, y)
      ..lineTo(x + width, y)
      ..lineTo(x + width + swayX, y + height - 42)
      ..quadraticBezierTo(
        x + width * 0.5 + swayX * 1.2,
        y + height + 18,
        x + swayX,
        y + height - 42,
      )
      ..close();

    canvas.drawPath(
      bannerPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, y),
          Offset(x, y + height),
          isNight
              ? const [Color(0xD9B9AFA0), Color(0xCC91877A)]
              : const [Color(0xEBFAF4E8), Color(0xE0EBE0CD)],
        ),
    );
    canvas.drawPath(
      bannerPath,
      Paint()
        ..color = const Color(0xFF8C5832)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    // Classical Dark-Ink Cloud & Floral Medallion Embroidery
    final medX = x + width * 0.5 + swayX * 0.5;
    final medY = y + height * 0.45;
    final medPath = Path()
      ..moveTo(medX, medY - 36)
      ..quadraticBezierTo(medX + 22, medY - 10, medX + 14, medY + 18)
      ..quadraticBezierTo(medX, medY + 34, medX - 14, medY + 18)
      ..quadraticBezierTo(medX - 22, medY - 10, medX, medY - 36)
      ..close();
    canvas.drawPath(medPath, Paint()..color = const Color(0xFF2B1D16));

    canvas.drawCircle(
      Offset(medX, medY),
      26.0,
      Paint()
        ..color = const Color(0xFF5E4332)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  /// Paints the glowing silk shade, red silk tassels, and candle flame of the
  /// left tall wooden floor palace lantern (`左壁落地宫灯` at x=335).
  static void paintFloorPalaceLanternShade(
    Canvas canvas,
    AncientRoomPalette palette, {
    required double candleLevel,
    required double flicker,
  }) {
    const flX = 335.0;

    // Red Silk Tassels hanging from top crossbar
    final tasselPaint = Paint()
      ..color = const Color(0xFFB8332A)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(flX - 36, 402), const Offset(flX - 36, 465), tasselPaint);
    canvas.drawLine(const Offset(flX + 36, 406), const Offset(flX + 36, 468), tasselPaint);

    // Tall Silk Ribbed Lantern Shade
    const shadeRect = Rect.fromLTWH(flX - 22, 535 - 92, 44, 184);
    canvas.drawOval(
      shadeRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(flX - 20, 440),
          const Offset(flX + 20, 620),
          candleLevel > 0.2
              ? const [Color(0xFFFFEAB3), Color(0xFFFFC46B), Color(0xFFE08A3C)]
              : const [Color(0xFFE8D8C0), Color(0xFFDEC8A8), Color(0xFFC4AC8C)],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawOval(
      shadeRect,
      Paint()
        ..color = palette.woodMid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    AncientRoomLightingLayers.paintCandleGlow(
      canvas,
      const Offset(flX, 535),
      165.0,
      candleLevel * 0.95,
      flicker,
      showFlame: true,
    );
  }

  /// Paints the foreground hero painted plum-blossom table lantern (`前景梅花彩绘座灯`).
  static void paintTablePlumLantern(
    Canvas canvas, {
    required double candleLevel,
    required double flicker,
  }) {
    const tlX = 465.0;
    const tlY = 835.0;

    // Warm candlelight pool cast onto rosewood table
    AncientRoomLightingLayers.paintCandleGlow(
      canvas,
      const Offset(tlX, tlY + 45),
      220.0,
      candleLevel,
      flicker,
      showFlame: false,
    );

    // Dark carved wood base stand
    const baseRect = Rect.fromLTWH(tlX - 58, tlY + 95 - 22, 116, 44);
    canvas.drawOval(baseRect, Paint()..color = const Color(0xFF1F110A));
    canvas.drawOval(
      baseRect,
      Paint()
        ..color = const Color(0xFF6E4228)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Cylindrical Xuan-Silk Lantern Body
    final bodyPath = Path()
      ..moveTo(tlX - 56, tlY - 72)
      ..quadraticBezierTo(tlX, tlY - 92, tlX + 56, tlY - 72)
      ..lineTo(tlX + 52, tlY + 82)
      ..quadraticBezierTo(tlX, tlY + 102, tlX - 52, tlY + 82)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(tlX - 58, tlY),
          const Offset(tlX + 58, tlY),
          candleLevel > 0.2
              ? const [Color(0xFFF5DCA8), Color(0xFFFFF6DC), Color(0xFFD9AE6C)]
              : const [Color(0xFFE5DCCB), Color(0xFFF5EFE4), Color(0xFFC2B6A3)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Inner flickering candle flame visible through translucent silk shade
    AncientRoomLightingLayers.paintCandleGlow(
      canvas,
      const Offset(tlX, tlY + 18),
      140.0,
      candleLevel,
      flicker,
      showFlame: true,
    );

    // Hand-painted Ink Branch & Red Plum Blossoms
    final inkBranchPaint = Paint()
      ..color = const Color(0xFF2B1E18)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final inkBranchPath = Path()
      ..moveTo(tlX - 42, tlY + 45)
      ..quadraticBezierTo(tlX - 5, tlY + 5, tlX + 38, tlY - 38)
      ..moveTo(tlX - 8, tlY + 10)
      ..quadraticBezierTo(tlX + 18, tlY + 18, tlX + 36, tlY + 8);
    canvas.drawPath(inkBranchPath, inkBranchPaint);

    const blossoms = [
      (tlX + 15, tlY - 18, 6.5),
      (tlX + 32, tlY - 32, 5.5),
      (tlX - 12, tlY + 15, 6.0),
      (tlX + 26, tlY + 10, 5.0),
    ];
    for (final (bx, by, radius) in blossoms) {
      canvas.drawCircle(
        Offset(bx, by),
        radius,
        Paint()..color = const Color(0xFFC83E3B),
      );
      canvas.drawCircle(
        Offset(bx - 2, by - 2),
        radius * 0.45,
        Paint()..color = const Color(0xFFF9B8C2),
      );
    }

    // Vertical wire ribs & top rim
    final wirePaint = Paint()
      ..color = const Color(0xFF382214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final rxOff in const [-32.0, 0.0, 32.0]) {
      canvas.drawLine(
        Offset(tlX + rxOff, tlY - 80),
        Offset(tlX + rxOff * 0.94, tlY + 90),
        wirePaint,
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(tlX - 55, tlY - 72 - 14, 110, 28),
      wirePaint,
    );
  }

  /// Paints the top center swaying woven bamboo chandelier (`顶部竹编彩绘吊灯`).
  static void paintBambooChandelier(
    Canvas canvas, {
    required double candleLevel,
    required double flicker,
    required double animationTime,
    required double windFactor,
  }) {
    final chX = 720.0 + math.sin(animationTime * 1.1 * windFactor) * (2.5 * windFactor);
    const chY = 215.0;

    // Suspension rod from top beam
    canvas.drawLine(
      const Offset(720, 0),
      Offset(chX, chY - 82),
      Paint()
        ..color = const Color(0xFF1A0F0A)
        ..strokeWidth = 3.5,
    );

    // Upper woven bamboo crown
    final crownPath = Path()
      ..moveTo(chX - 32, chY - 82)
      ..lineTo(chX + 32, chY - 82)
      ..lineTo(chX + 55, chY - 38)
      ..lineTo(chX - 55, chY - 38)
      ..close();
    canvas.drawPath(
      crownPath,
      Paint()
        ..color = candleLevel > 0.2
            ? const Color(0xFFE8B368)
            : const Color(0xFFC49A62),
    );
    canvas.drawPath(
      crownPath,
      Paint()
        ..color = const Color(0xFF5C3A1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Wide outer woven bamboo ring
    final ringRect = Rect.fromCenter(
      center: Offset(chX, chY - 8),
      width: 184,
      height: 68,
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = candleLevel > 0.2
            ? const Color.fromRGBO(242, 196, 126, 0.88)
            : const Color.fromRGBO(210, 180, 135, 0.85),
    );
    final rimPaint = Paint()
      ..color = const Color(0xFF6E4522)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(ringRect, rimPaint);

    // Glowing inner silk bowl
    final bowlRect = Rect.fromCenter(
      center: Offset(chX, chY),
      width: 144,
      height: 56,
    );
    canvas.drawOval(
      bowlRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(chX, chY),
          72.0,
          [
            candleLevel > 0.2
                ? const Color(0xFFFFFDF2)
                : const Color(0xFFF5EFE4),
            candleLevel > 0.2
                ? const Color(0xFFFFE39E)
                : const Color(0xFFE2D4C0),
            const Color(0xFFC49358),
          ],
          const [8.0 / 72.0, 0.65, 1.0],
        ),
    );
    canvas.drawOval(bowlRect, rimPaint);

    // Bamboo ribs across chandelier
    final ribPaint = Paint()
      ..color = const Color.fromRGBO(92, 58, 30, 0.45)
      ..strokeWidth = 1.4;
    for (int ribIndex = -4; ribIndex <= 4; ribIndex++) {
      canvas.drawLine(
        Offset(chX + ribIndex * 7.0, chY - 82),
        Offset(chX + ribIndex * 20.0, chY + 4),
        ribPaint,
      );
    }

    AncientRoomLightingLayers.paintCandleGlow(
      canvas,
      Offset(chX, chY + 5),
      240.0,
      candleLevel * 0.9,
      flicker,
      showFlame: false,
    );
  }

  /// Paints the conditional Winter/Snow red-clay charcoal brazier (`红泥小火炉`).
  static void paintWinterCharcoalBrazier(
    Canvas canvas, {
    required double animationTime,
    required double flicker,
  }) {
    const brazierX = 760.0;
    const brazierY = 740.0;

    const bodyRect = Rect.fromLTWH(brazierX - 34, brazierY - 22, 68, 44);
    canvas.drawOval(bodyRect, Paint()..color = const Color(0xFF8F3626));
    canvas.drawOval(
      bodyRect,
      Paint()
        ..color = const Color(0xFF4A1A10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    final emberPulse = 0.75 + 0.25 * math.sin(animationTime * 5.2);
    canvas.drawOval(
      const Rect.fromLTWH(brazierX - 24, brazierY - 6 - 10, 48, 20),
      Paint()..color = Color.fromRGBO(255, 110, 30, emberPulse),
    );

    AncientRoomLightingLayers.paintCandleGlow(
      canvas,
      const Offset(brazierX, brazierY - 8),
      95.0,
      0.85,
      flicker,
      showFlame: false,
    );
  }
}
