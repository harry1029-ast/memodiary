import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import 'ancient_room_furniture_layers.dart';
import 'ancient_room_lighting_layers.dart';

/// Right wall circular Moon Archway (`cx=1405, cy=515, r=235`) and cyan silk
/// alcove renderer for the Indoor Tea Hall (`室内`).
class AncientRoomAlcoveLayer {
  const AncientRoomAlcoveLayer._();

  static const Offset rightArchCenter = Offset(1405.0, 515.0);
  static const double rightArchRadius = 235.0;
  static const double rightArchInnerRadius = 224.0;

  /// Builds the right perspective wall trapezoid boundary.
  static Path buildRightWallPath() {
    return Path()
      ..moveTo(1080, 60)
      ..lineTo(1500, 0)
      ..lineTo(1500, 850)
      ..lineTo(1080, 640)
      ..close();
  }

  /// Paints the interior of the right circular Moon Archway (`青碧纱幔`, emerald
  /// banner, alcove pillar, octagonal wall lantern, and corner potted flowers).
  static void paintRightAlcoveContent(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool isNight,
    required double candleLevel,
    required double curtainSway,
    required double flicker,
    required bool includeGlow,
  }) {
    canvas.drawPath(
      buildRightWallPath(),
      Paint()..color = const Color(0xFF18242C),
    );

    // Flowing Cyan/Turquoise Silk Drapes (青碧纱幔)
    final drapePath = Path()
      ..moveTo(1320, 180)
      ..quadraticBezierTo(
        1350 + curtainSway,
        420,
        1330 + curtainSway * 1.2,
        680,
      )
      ..lineTo(1500, 680)
      ..lineTo(1500, 180)
      ..close();
    canvas.drawPath(
      drapePath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(1250, 150),
          const Offset(1480, 680),
          isNight
              ? const [Color(0xFF124E5E), Color(0xFF1B697D), Color(0xFF0D333D)]
              : const [Color(0xFF1E88A8), Color(0xFF38B2CE), Color(0xFF16657D)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Emerald Silk Hanging Banner with Circular Medallion (翠绿团花垂幡)
    final bannerX = 1345.0 + curtainSway * 0.4;
    final bannerRect = Rect.fromLTWH(bannerX, 210, 82, 145);
    canvas.drawRect(
      bannerRect,
      Paint()..color = isNight ? const Color(0xFF194D33) : const Color(0xFF26734D),
    );
    canvas.drawRect(
      bannerRect,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset(1386.0 + curtainSway * 0.4, 282.0),
      22.0,
      Paint()
        ..color = const Color.fromRGBO(220, 245, 230, 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Alcove Pillar & Octagonal Wall Lantern (偏厅八角宫灯)
    canvas.drawRect(
      const Rect.fromLTWH(1265, 160, 42, 540),
      Paint()..color = palette.woodDark,
    );

    const lanternX = 1286.0;
    const lanternY = 415.0;
    const lanternRect = Rect.fromLTWH(lanternX - 24, lanternY - 42, 48, 84);
    canvas.drawRect(
      lanternRect,
      Paint()
        ..color = candleLevel > 0.25
            ? const Color(0xFFFFF3C4)
            : const Color(0xFFE8DEC8),
    );
    final framePaint = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRect(lanternRect, framePaint);

    final diamondPath = Path()
      ..moveTo(lanternX, lanternY - 42)
      ..lineTo(lanternX + 24, lanternY)
      ..lineTo(lanternX, lanternY + 42)
      ..lineTo(lanternX - 24, lanternY)
      ..close();
    canvas.drawPath(diamondPath, framePaint);

    if (includeGlow) {
      AncientRoomLightingLayers.paintCandleGlow(
        canvas,
        const Offset(lanternX, lanternY),
        130.0,
        candleLevel * 0.9,
        flicker,
        showFlame: false,
      );
    }

    // Potted flowers inside right alcove corner
    canvas.drawRect(
      const Rect.fromLTWH(1395, 610, 65, 55),
      Paint()..color = const Color(0xFF5C3A21),
    );
    AncientRoomFurnitureLayers.paintFoliageCluster(
      canvas,
      const Offset(1425, 580),
      32.0,
      palette.indoorPotFlower,
    );
  }
}
