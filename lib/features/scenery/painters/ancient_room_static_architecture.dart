import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/shanshui_atmosphere.dart';
import 'ancient_room_alcove_layer.dart';
import 'ancient_room_furniture_layers.dart';
import 'ancient_room_window_layer.dart';

/// Static architectural geometry renderer for the Indoor Tea Hall (`室内`).
///
/// Records static elements (rear shoji doors, ceiling beams, Moon Window frame,
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

    final candleBoost = atmosphere.weather == ShanshuiWeather.rainy
        ? 0.25
        : atmosphere.weather == ShanshuiWeather.stormy
            ? 0.45
            : 0.0;
    final candleLevel = (roomPalette.candleIntensity + candleBoost).clamp(0.0, 1.0);
    final isBrightFloor =
        atmosphere.weather.indoorBeamMultiplier > 0.35 &&
        atmosphere.timeOfDay == ShanshuiTimeOfDay.day;

    _paintShojiDoors(canvas, roomPalette, isNight: isNight, candleLevel: candleLevel);
    _paintCeilingBeams(canvas, roomPalette);
    _paintWallsAndMoonWindowCasing(canvas, roomPalette, hasSnow: hasSnow);
    _paintFloorboards(canvas, roomPalette);
    _paintRightPartition(canvas, roomPalette, isNight: isNight, candleLevel: candleLevel);
    _paintMoonGate(canvas, roomPalette);
    _paintFurnitureAndVessels(
      canvas,
      roomPalette,
      isNight: isNight,
      isBrightFloor: isBrightFloor,
    );
  }

  /// 1. Rear Shoji lattice doors, foliage silhouettes, inner lantern, and altar table.
  static void _paintShojiDoors(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool isNight,
    required double candleLevel,
  }) {
    const shojiRect = Rect.fromLTWH(360, 180, 720, 460);
    final shojiPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 220),
        const Offset(0, 620),
        [palette.shojiTop, palette.shojiBottom],
      );
    canvas.drawRect(shojiRect, shojiPaint);

    // Diffused courtyard tree silhouettes behind translucent paper
    final silhouettePaint = Paint()
      ..color = isNight
          ? const Color.fromRGBO(15, 25, 35, 0.32)
          : const Color.fromRGBO(65, 85, 70, 0.14);
    canvas.drawCircle(const Offset(460, 440), 75, silhouettePaint);
    canvas.drawCircle(const Offset(520, 410), 90, silhouettePaint);
    canvas.drawCircle(const Offset(920, 430), 85, silhouettePaint);

    // Tall Shoji door frames with fine horizontal and vertical muntins
    final framePaint = Paint()
      ..color = palette.woodMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final muntinPaint = Paint()
      ..color = palette.woodMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (double sx = 410; sx <= 1010; sx += 100) {
      canvas.drawRect(Rect.fromLTWH(sx, 260, 100, 325), framePaint);
      for (double sy = 285; sy < 550; sy += 24) {
        canvas.drawLine(Offset(sx, sy), Offset(sx + 100, sy), muntinPaint);
      }
      canvas.drawLine(Offset(sx + 50, 260), Offset(sx + 50, 585), muntinPaint);
    }

    // Inner room hanging silk lantern behind Moon Gate (x=720, y=365)
    const innerLanternX = 720.0;
    const innerLanternY = 365.0;
    canvas.drawLine(
      const Offset(innerLanternX, 260),
      const Offset(innerLanternX, innerLanternY - 28),
      Paint()
        ..color = palette.woodDark
        ..strokeWidth = 2.0,
    );

    const innerLanternRect = Rect.fromLTWH(
      innerLanternX - 16,
      innerLanternY - 28,
      32,
      54,
    );
    canvas.drawRect(
      innerLanternRect,
      Paint()
        ..color = candleLevel > 0.3
            ? const Color(0xFFFFE0A3)
            : const Color(0xFFE6D7C3),
    );
    canvas.drawRect(
      innerLanternRect,
      Paint()
        ..color = palette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Inner room background altar table on the right
    final altarPaint = Paint()..color = palette.woodMid;
    canvas.drawRect(const Rect.fromLTWH(790, 520, 145, 8), altarPaint);
    canvas.drawRect(const Rect.fromLTWH(805, 528, 6, 56), altarPaint);
    canvas.drawRect(const Rect.fromLTWH(915, 528, 6, 56), altarPaint);
  }

  /// 2. Perspective ceiling dark timber beams.
  static void _paintCeilingBeams(Canvas canvas, AncientRoomPalette palette) {
    final ceilingPath = Path()
      ..moveTo(0, 0)
      ..lineTo(1500, 0)
      ..lineTo(1080, 60)
      ..lineTo(360, 60)
      ..close();
    canvas.drawPath(ceilingPath, Paint()..color = palette.woodDark);
  }

  /// 3. Perspective Xuan-plaster left wall (carved with Moon Window hole) and casing.
  static void _paintWallsAndMoonWindowCasing(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool hasSnow,
  }) {
    // Left perspective plaster wall with even-odd inverse Moon Window opening
    final leftWallPath = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(0, 0)
      ..lineTo(360, 60)
      ..lineTo(360, 640)
      ..lineTo(0, 860)
      ..close()
      ..addPath(AncientRoomWindowLayer.buildMoonWindowClipPath(), Offset.zero);

    final leftWallPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 300),
        const Offset(360, 450),
        [palette.wallLeft, palette.wallRight],
      );
    canvas.drawPath(leftWallPath, leftWallPaint);

    // Left wall heavy timber framing beams
    final beamPaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0;
    final beamPath = Path()
      ..moveTo(0, 0)
      ..lineTo(360, 60)
      ..moveTo(352, 55)
      ..lineTo(352, 645)
      ..moveTo(0, 855)
      ..lineTo(360, 640);
    canvas.drawPath(beamPath, beamPaint);

    // Heavy rosewood Moon Window casing, inner bevel highlight & winter sill snow
    AncientRoomWindowLayer.paintMoonWindowFrame(
      canvas,
      palette,
      hasSnow: hasSnow,
    );
  }

  /// 4. Polished rosewood floorboards with radiating perspective joints.
  static void _paintFloorboards(Canvas canvas, AncientRoomPalette palette) {
    final floorPath = Path()
      ..moveTo(360, 640)
      ..lineTo(1080, 640)
      ..lineTo(1500, 850)
      ..lineTo(1500, 1000)
      ..lineTo(0, 1000)
      ..lineTo(0, 860)
      ..close();

    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(720, 580),
        const Offset(720, 1000),
        [palette.floorHighlight, palette.floorBase, palette.woodDark],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawPath(floorPath, floorPaint);

    canvas.save();
    canvas.clipPath(floorPath);
    final linePaint = Paint()
      ..color = const Color.fromRGBO(20, 10, 5, 0.28)
      ..strokeWidth = 1.5;

    for (int i = -12; i <= 12; i++) {
      canvas.drawLine(
        Offset(720 + i * 28.0, 640),
        Offset(720 + i * 145.0, 1000),
        linePaint,
      );
    }
    for (final fy in const [668.0, 702.0, 745.0, 798.0, 860.0, 932.0]) {
      canvas.drawLine(Offset(0, fy), Offset(1500, fy), linePaint);
    }
    canvas.restore();
  }

  /// 5. Right wall, even-odd carved vertical slats partition, alcove, and Moon Archway.
  static void _paintRightPartition(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool isNight,
    required double candleLevel,
  }) {
    canvas.save();
    canvas.clipPath(AncientRoomAlcoveLayer.buildRightWallPath());

    // Static fallback alcove contents (dynamically swayed version overlays inside archway)
    AncientRoomAlcoveLayer.paintRightAlcoveContent(
      canvas,
      palette,
      isNight: isNight,
      candleLevel: candleLevel,
      curtainSway: 0.0,
      flicker: 0.0,
      includeGlow: false,
    );

    // Even-odd inverse clip carving circular Moon Archway (cx=1405, cy=515, r=235)
    canvas.save();
    final slatsClipPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(1080, 0, 420, 860))
      ..addOval(
        Rect.fromCircle(
          center: AncientRoomAlcoveLayer.rightArchCenter,
          radius: AncientRoomAlcoveLayer.rightArchRadius,
        ),
      );
    canvas.clipPath(slatsClipPath);

    // Backing plaster panel behind vertical slats
    canvas.drawRect(
      const Rect.fromLTWH(1080, 0, 420, 860),
      Paint()..color = palette.wallRight,
    );

    // Vertical wooden slats along the right wall in perspective
    final slatPaint = Paint()
      ..color = palette.woodMid
      ..strokeWidth = 8.0;
    for (double rx = 1090; rx <= 1495; rx += 20) {
      canvas.drawLine(Offset(rx, 0), Offset(rx, 850), slatPaint);
    }

    // Horizontal middle waist rail on right partition
    final waistRailPath = Path()
      ..moveTo(1080, 420)
      ..lineTo(1500, 385)
      ..lineTo(1500, 465)
      ..lineTo(1080, 475)
      ..close();
    canvas.drawPath(waistRailPath, Paint()..color = palette.woodDark);
    canvas.restore();

    // Right Circular Moon Archway Frame
    canvas.drawCircle(
      AncientRoomAlcoveLayer.rightArchCenter,
      AncientRoomAlcoveLayer.rightArchRadius,
      Paint()
        ..color = palette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22.0,
    );
    canvas.drawCircle(
      AncientRoomAlcoveLayer.rightArchCenter,
      AncientRoomAlcoveLayer.rightArchInnerRadius,
      Paint()
        ..color = palette.woodHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // Outer framing beams of right wall
    final beamPaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0;
    final beamPath = Path()
      ..moveTo(1080, 60)
      ..lineTo(1500, 0)
      ..moveTo(1080, 60)
      ..lineTo(1080, 640)
      ..moveTo(1080, 640)
      ..lineTo(1500, 850);
    canvas.drawPath(beamPath, beamPaint);
    canvas.restore();
  }

  /// 6. Center partition wall, upper geometric lattice transom, lintels,
  /// horizontal slat railings (`卧棂栏杆`), and circular Moon Gate ring (`cx=720, cy=478, r=158`).
  static void _paintMoonGate(Canvas canvas, AncientRoomPalette palette) {
    const gateCenter = Offset(720, 478);
    const gateRadius = 158.0;

    // Upper geometric lattice transom (y=65..147, x=360..1080)
    canvas.drawRect(
      const Rect.fromLTWH(360, 65, 720, 82),
      Paint()..color = palette.wallRight,
    );
    final latticePaint = Paint()
      ..color = palette.woodDark
      ..strokeWidth = 4.0;
    for (double tx = 380; tx < 1080; tx += 36) {
      canvas.drawLine(Offset(tx, 65), Offset(tx, 147), latticePaint);
    }
    for (double ty = 85; ty <= 130; ty += 22) {
      canvas.drawLine(Offset(360, ty), Offset(1080, ty), latticePaint);
    }

    // Heavy horizontal lintels
    final lintelPaint = Paint()..color = palette.woodDark;
    canvas.drawRect(const Rect.fromLTWH(352, 52, 736, 20), lintelPaint);
    canvas.drawRect(const Rect.fromLTWH(352, 144, 736, 28), lintelPaint);
    canvas.drawRect(const Rect.fromLTWH(352, 228, 736, 16), lintelPaint);

    // Side columns & horizontal slat railings (卧棂栏杆)
    canvas.drawRect(const Rect.fromLTWH(352, 60, 22, 585), lintelPaint);
    canvas.drawRect(const Rect.fromLTWH(552, 160, 14, 160), lintelPaint);
    final slatPaint = Paint()..color = palette.woodMid;
    for (double ry = 532; ry <= 622; ry += 15) {
      canvas.drawRect(Rect.fromLTWH(368, ry, 215, 7), slatPaint);
    }
    canvas.drawRect(const Rect.fromLTWH(365, 625, 238, 18), lintelPaint);

    canvas.drawRect(const Rect.fromLTWH(1066, 60, 22, 585), lintelPaint);
    canvas.drawRect(const Rect.fromLTWH(874, 160, 14, 160), lintelPaint);
    for (double ry = 532; ry <= 622; ry += 15) {
      canvas.drawRect(Rect.fromLTWH(855, ry, 215, 7), slatPaint);
    }
    canvas.drawRect(const Rect.fromLTWH(838, 625, 242, 18), lintelPaint);

    // Central circular Moon Gate ring (cx=720, cy=478, r=158)
    canvas.drawArc(
      Rect.fromCircle(center: gateCenter, radius: gateRadius),
      -3.70708,
      4.27257,
      false,
      Paint()
        ..color = palette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0,
    );
    canvas.drawArc(
      Rect.fromCircle(center: gateCenter, radius: gateRadius - 8.0),
      -3.61283,
      4.08407,
      false,
      Paint()
        ..color = palette.woodHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }

  /// 7. Static floor lantern stand, porcelain pots, magnolia vase, cushions,
  /// and full-perspective rosewood tea table with celadon set & twin burners.
  static void _paintFurnitureAndVessels(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool isNight,
    required bool isBrightFloor,
  }) {
    // Left floor palace lantern wooden stand & pedestal
    AncientRoomFurnitureLayers.paintFloorPalaceLanternStand(canvas, palette);

    // Fluted white porcelain bonsai pots below the Moon Window
    AncientRoomFurnitureLayers.paintPorcelainPot(
      canvas,
      const Offset(240, 725),
      0.92,
      palette,
    );
    AncientRoomFurnitureLayers.paintPorcelainPot(
      canvas,
      const Offset(18, 855),
      1.22,
      palette,
    );

    // Right tall dark ceramic vase with white magnolia/plum branches
    AncientRoomFurnitureLayers.paintMagnoliaVase(canvas, palette);

    // 3 perspective embroidered silk floor cushions on wooden plinths
    AncientRoomFurnitureLayers.paintFloorCushion(
      canvas,
      palette,
      cx: 385,
      cy: 755,
      wTop: 115,
      wBot: 130,
      height: 56,
      isLit: isBrightFloor,
    );
    AncientRoomFurnitureLayers.paintFloorCushion(
      canvas,
      palette,
      cx: 855,
      cy: 742,
      wTop: 135,
      wBot: 155,
      height: 68,
      isLit: isBrightFloor,
    );
    AncientRoomFurnitureLayers.paintFloorCushion(
      canvas,
      palette,
      cx: 915,
      cy: 845,
      wTop: 168,
      wBot: 205,
      height: 110,
      isLit: isBrightFloor,
    );

    // Full-perspective long rosewood tea table, runner, tea set & twin conical burners
    AncientRoomFurnitureLayers.paintTeaTableAndVessels(
      canvas,
      isNight: isNight,
    );
  }
}
