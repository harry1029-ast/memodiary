import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/shanshui_atmosphere.dart';

/// Static architectural geometry renderer for the Indoor Scholar Tea Hall (`雅室`).
///
/// Records the complex static elements (Shoji doors, ceiling beams, Moon Window frame,
/// rosewood floorboards, right slat partition, Moon Gate ring, and tea table furniture)
/// into a reusable immutable `ui.Picture` layer to maintain 60 FPS rendering.
class AncientRoomStaticArchitecture {
  const AncientRoomStaticArchitecture._();

  /// Paints the full static background and architectural geometry onto [canvas]
  /// normalized to standard 1500 x 1000 coordinates.
  static void paintStaticArchitecture(
    Canvas canvas,
    Size size, {
    required ShanshuiAtmosphereState atmosphere,
    required AncientRoomPalette roomPalette,
  }) {
    final isWinter = atmosphere.season == ShanshuiSeason.winter;
    final isSnowy = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnow = isWinter || isSnowy;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;

    _paintShojiDoors(canvas, roomPalette, isNight: isNight);
    _paintCeilingBeams(canvas, roomPalette);
    _paintWallsAndMoonWindowCasing(canvas, roomPalette, hasSnow: hasSnow);
    _paintFloorboards(canvas, roomPalette);
    _paintRightPartition(canvas, roomPalette);
    _paintMoonGate(canvas, roomPalette);
    _paintFurnitureAndVessels(canvas, roomPalette, hasSnow: hasSnow);
  }

  /// 1. Rear Shoji lattice doors and courtyard foliage silhouettes.
  static void _paintShojiDoors(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool isNight,
  }) {
    final shojiRect = const Rect.fromLTWH(360, 180, 780, 460);
    final shojiPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.shojiTop, palette.shojiBottom],
      ).createShader(shojiRect);
    canvas.drawRect(shojiRect, shojiPaint);

    // Diffused courtyard tree silhouettes behind translucent paper
    final silhouettePaint = Paint()
      ..color = isNight
          ? const Color.fromRGBO(15, 25, 35, 0.32)
          : const Color.fromRGBO(65, 85, 70, 0.16);
    canvas.drawCircle(const Offset(460, 440), 75, silhouettePaint);
    canvas.drawCircle(const Offset(520, 410), 90, silhouettePaint);
    canvas.drawCircle(const Offset(920, 430), 85, silhouettePaint);

    // 6 tall Shoji door frames with fine horizontal and vertical muntins
    final framePaint = Paint()
      ..color = palette.woodMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final muntinPaint = Paint()
      ..color = palette.woodMid.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (double sx = 410; sx <= 1010; sx += 100) {
      canvas.drawRect(Rect.fromLTWH(sx, 260, 100, 325), framePaint);
      for (double sy = 285; sy < 580; sy += 24) {
        canvas.drawLine(Offset(sx, sy), Offset(sx + 100, sy), muntinPaint);
      }
      canvas.drawLine(Offset(sx + 50, 260), Offset(sx + 50, 585), muntinPaint);
    }

    // Inner room hanging silk lantern behind Moon Gate
    final lanternCordPaint = Paint()
      ..color = palette.woodDark
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(750, 260), const Offset(750, 335), lanternCordPaint);

    final innerLanternPaint = Paint()
      ..color = palette.candleIntensity > 0.3
          ? const Color(0xFFFFE0A3)
          : const Color(0xFFE6D7C3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(734, 335, 32, 54),
        const Radius.circular(6),
      ),
      innerLanternPaint,
    );
  }

  /// 2. Perspective ceiling rafters and heavy transverse timber beam.
  static void _paintCeilingBeams(Canvas canvas, AncientRoomPalette palette) {
    final beamPaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.fill;

    // Heavy transverse structural beam
    canvas.drawRect(const Rect.fromLTWH(0, 160, 1500, 40), beamPaint);

    // Ceiling planks above the beam
    final ceilingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.woodDark, palette.woodMid],
      ).createShader(const Rect.fromLTWH(0, 0, 1500, 160));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 160), ceilingPaint);

    // Perspective rafters
    final rafterPaint = Paint()
      ..color = palette.woodHighlight.withValues(alpha: 0.4)
      ..strokeWidth = 4.0;
    final vanishingPoint = const Offset(750, 400);
    for (double rx = 100; rx <= 1400; rx += 140) {
      canvas.drawLine(Offset(rx, 0), Offset(rx * 0.7 + vanishingPoint.dx * 0.3, 160), rafterPaint);
    }
  }

  /// 3. Perspective Xuan-plaster walls and left circular Moon Window casing.
  static void _paintWallsAndMoonWindowCasing(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool hasSnow,
  }) {
    // Left perspective plaster wall
    final leftWallPath = Path()
      ..moveTo(0, 0)
      ..lineTo(360, 160)
      ..lineTo(360, 640)
      ..lineTo(0, 1000)
      ..close();

    final leftWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.wallLeft, palette.wallLeft.withValues(alpha: 0.88)],
      ).createShader(const Rect.fromLTWH(0, 0, 360, 1000));
    canvas.drawPath(leftWallPath, leftWallPaint);

    // Left circular Moon Window outer casing (clipped live view rendered dynamically)
    final windowCenter = const Offset(205, 415);
    const radiusX = 145.0;
    const radiusY = 175.0;

    final casingPaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0;
    canvas.drawOval(
      Rect.fromCenter(center: windowCenter, width: radiusX * 2, height: radiusY * 2),
      casingPaint,
    );

    // Inner rim highlight
    final innerRimPaint = Paint()
      ..color = palette.woodHighlight.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(
      Rect.fromCenter(center: windowCenter, width: (radiusX - 11) * 2, height: (radiusY - 11) * 2),
      innerRimPaint,
    );

    // Winter sill snow accumulation
    if (hasSnow) {
      final snowPaint = Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill;
      final snowPath = Path()
        ..moveTo(windowCenter.dx - radiusX * 0.75, windowCenter.dy + radiusY * 0.72)
        ..quadraticBezierTo(
          windowCenter.dx,
          windowCenter.dy + radiusY * 0.82,
          windowCenter.dx + radiusX * 0.75,
          windowCenter.dy + radiusY * 0.72,
        )
        ..quadraticBezierTo(
          windowCenter.dx,
          windowCenter.dy + radiusY * 0.98,
          windowCenter.dx - radiusX * 0.75,
          windowCenter.dy + radiusY * 0.72,
        )
        ..close();
      canvas.drawPath(snowPath, snowPaint);
    }
  }

  /// 4. Polished rosewood floorboards with radiating perspective joints.
  static void _paintFloorboards(Canvas canvas, AncientRoomPalette palette) {
    final floorRect = const Rect.fromLTWH(0, 640, 1500, 360);
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.floorBase, palette.floorHighlight],
      ).createShader(floorRect);
    canvas.drawRect(floorRect, floorPaint);

    // Perspective lines radiating from central vanishing point (750, 420)
    final vanishingPoint = const Offset(750, 420);
    final linePaint = Paint()
      ..color = palette.woodDark.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;

    for (double fx = -200; fx <= 1700; fx += 130) {
      final t = (640 - vanishingPoint.dy) / (1000 - vanishingPoint.dy);
      final startX = vanishingPoint.dx + (fx - vanishingPoint.dx) * t;
      canvas.drawLine(Offset(startX, 640), Offset(fx, 1000), linePaint);
    }

    // Horizontal plank joints
    final plankPaint = Paint()
      ..color = palette.woodDark.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (double fy = 690; fy <= 960; fy += 55) {
      canvas.drawLine(Offset(0, fy), Offset(1500, fy), plankPaint);
    }
  }

  /// 5. Right wall, wooden slats partition, alcove, and lantern mount.
  static void _paintRightPartition(Canvas canvas, AncientRoomPalette palette) {
    // Right perspective plaster wall
    final rightWallPath = Path()
      ..moveTo(1140, 160)
      ..lineTo(1500, 0)
      ..lineTo(1500, 1000)
      ..lineTo(1140, 640)
      ..close();

    final rightWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [palette.wallRight, palette.wallRight.withValues(alpha: 0.9)],
      ).createShader(const Rect.fromLTWH(1140, 0, 360, 1000));
    canvas.drawPath(rightWallPath, rightWallPaint);

    // Cyan silk alcove backdrop
    final alcovePaint = Paint()..color = const Color(0xFF1B3B3B);
    canvas.drawRect(const Rect.fromLTWH(1180, 220, 240, 380), alcovePaint);

    // Vertical wooden slats
    final slatPaint = Paint()
      ..color = palette.woodMid
      ..strokeWidth = 6.0;
    for (double sx = 1195; sx <= 1400; sx += 22) {
      canvas.drawLine(Offset(sx, 220), Offset(sx, 600), slatPaint);
    }

    // Octagonal wall lantern wooden mount
    final mountPaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(1260, 320, 36, 68), mountPaint);
  }

  /// 6. Central circular Moon Gate archway and partition wall.
  static void _paintMoonGate(Canvas canvas, AncientRoomPalette palette) {
    const gateCenter = Offset(750, 480);
    const gateRadius = 230.0;

    // Transom beam above Moon Gate
    final transomPaint = Paint()..color = palette.woodDark;
    canvas.drawRect(const Rect.fromLTWH(360, 160, 780, 50), transomPaint);

    // Lattice transom decoration
    final latticePaint = Paint()
      ..color = palette.woodHighlight.withValues(alpha: 0.5)
      ..strokeWidth = 1.8;
    for (double lx = 380; lx <= 1120; lx += 25) {
      canvas.drawLine(Offset(lx, 165), Offset(lx + 20, 205), latticePaint);
      canvas.drawLine(Offset(lx + 20, 165), Offset(lx, 205), latticePaint);
    }

    // Heavy circular Moon Gate rim
    final gateRimPaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26.0;
    canvas.drawCircle(gateCenter, gateRadius, gateRimPaint);

    // Gate rim highlight
    final gateHighlightPaint = Paint()
      ..color = palette.woodHighlight.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(gateCenter, gateRadius - 13, gateHighlightPaint);
  }

  /// 7. Rosewood tea table, celadon tea vessels, flowerpots, and cushions.
  static void _paintFurnitureAndVessels(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool hasSnow,
  }) {
    // Low foreground rosewood tea table (polygonal perspective)
    final tableTopPath = Path()
      ..moveTo(470, 810)
      ..lineTo(1030, 810)
      ..lineTo(1110, 880)
      ..lineTo(390, 880)
      ..close();

    final tablePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.woodMid, palette.woodDark],
      ).createShader(const Rect.fromLTWH(390, 810, 720, 70));
    canvas.drawPath(tableTopPath, tablePaint);

    // Table front apron and legs
    final apronPaint = Paint()..color = palette.woodDark;
    canvas.drawRect(const Rect.fromLTWH(390, 880, 720, 24), apronPaint);
    canvas.drawRect(const Rect.fromLTWH(420, 904, 38, 48), apronPaint);
    canvas.drawRect(const Rect.fromLTWH(1042, 904, 38, 48), apronPaint);

    // Brocade table runner
    final runnerPaint = Paint()..color = const Color(0xFF8B3A3A);
    canvas.drawRect(const Rect.fromLTWH(690, 810, 120, 70), runnerPaint);

    // Celadon tea set on wooden tray
    final trayPaint = Paint()..color = palette.woodDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(705, 825, 90, 44), const Radius.circular(4)),
      trayPaint,
    );

    // Celadon teapot
    final teapotPaint = Paint()..color = const Color(0xFF7FA396);
    canvas.drawCircle(const Offset(735, 842), 14, teapotPaint);
    canvas.drawCircle(const Offset(765, 840), 7, teapotPaint);
    canvas.drawCircle(const Offset(780, 846), 7, teapotPaint);

    // Conical ribbed terracotta incense burner
    final burnerPaint = Paint()..color = const Color(0xFF9E4733);
    final burnerPath = Path()
      ..moveTo(520, 850)
      ..lineTo(540, 816)
      ..lineTo(560, 850)
      ..close();
    canvas.drawPath(burnerPath, burnerPaint);

    // Miniature painted table lantern
    final lanternPaint = Paint()..color = const Color(0xFFFFECC4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(960, 804, 28, 42), const Radius.circular(4)),
      lanternPaint,
    );

    // Fluted porcelain flowerpots by Moon Gate
    _paintFlowerpot(canvas, const Offset(430, 620), palette, hasSnow: hasSnow);
    _paintFlowerpot(canvas, const Offset(1070, 620), palette, hasSnow: hasSnow);

    // Floor cushions
    _paintCushion(canvas, const Offset(470, 680), palette);
    _paintCushion(canvas, const Offset(1030, 680), palette);

    // Winter red-clay charcoal brazier (红泥小火炉)
    if (hasSnow) {
      _paintCharcoalBrazier(canvas, const Offset(330, 640), palette);
    }
  }

  static void _paintFlowerpot(
    Canvas canvas,
    Offset position,
    AncientRoomPalette palette, {
    required bool hasSnow,
  }) {
    final potPaint = Paint()..color = const Color(0xFFECEFF1);
    final potPath = Path()
      ..moveTo(position.dx - 22, position.dy)
      ..lineTo(position.dx + 22, position.dy)
      ..lineTo(position.dx + 16, position.dy + 34)
      ..lineTo(position.dx - 16, position.dy + 34)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Seasonal blooms & leaves
    final leafPaint = Paint()..color = palette.indoorPotLeaf;
    final flowerPaint = Paint()..color = palette.indoorPotFlower;

    canvas.drawCircle(Offset(position.dx - 12, position.dy - 12), 10, leafPaint);
    canvas.drawCircle(Offset(position.dx + 12, position.dy - 10), 11, leafPaint);
    canvas.drawCircle(Offset(position.dx, position.dy - 18), 12, leafPaint);

    canvas.drawCircle(Offset(position.dx - 6, position.dy - 16), 7, flowerPaint);
    canvas.drawCircle(Offset(position.dx + 8, position.dy - 14), 8, flowerPaint);
    canvas.drawCircle(Offset(position.dx, position.dy - 24), 7, flowerPaint);
  }

  static void _paintCushion(Canvas canvas, Offset position, AncientRoomPalette palette) {
    final cushionPaint = Paint()..color = const Color(0xFF4A3B32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: position, width: 90, height: 26),
        const Radius.circular(8),
      ),
      cushionPaint,
    );
  }

  static void _paintCharcoalBrazier(
    Canvas canvas,
    Offset position,
    AncientRoomPalette palette,
  ) {
    // Red-clay brazier body
    final brazierPaint = Paint()..color = const Color(0xFFB34A38);
    canvas.drawOval(
      Rect.fromCenter(center: position, width: 64, height: 32),
      brazierPaint,
    );
    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFF7E3224)
      ..strokeWidth = 6.0;
    canvas.drawLine(Offset(position.dx - 20, position.dy + 12), Offset(position.dx - 24, position.dy + 28), legPaint);
    canvas.drawLine(Offset(position.dx + 20, position.dy + 12), Offset(position.dx + 24, position.dy + 28), legPaint);
    canvas.drawLine(Offset(position.dx, position.dy + 14), Offset(position.dx, position.dy + 30), legPaint);
  }
}
