import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';

/// Shared architectural, botanical, and tabletop vector helpers for the
/// Indoor Tea Hall (`室内`).
class AncientRoomFurnitureLayers {
  const AncientRoomFurnitureLayers._();

  /// Paints a multi-lobed organic foliage or blossom cluster, optionally snow-capped.
  static void paintFoliageCluster(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    bool isSnowCapped = false,
  }) {
    final fillPaint = Paint()..color = color.withValues(alpha: 0.90);
    final offsets = [
      Offset.zero,
      Offset(-radius * 0.55, radius * 0.15),
      Offset(radius * 0.55, radius * 0.18),
      Offset(0.0, -radius * 0.45),
      Offset(-radius * 0.35, -radius * 0.28),
    ];
    final radii = [
      radius,
      radius * 0.76,
      radius * 0.72,
      radius * 0.68,
      radius * 0.62,
    ];
    for (int index = 0; index < offsets.length; index++) {
      canvas.drawCircle(center + offsets[index], radii[index], fillPaint);
    }

    if (isSnowCapped) {
      final snowPaint = Paint()
        ..color = const Color(0xFFF8FAFC).withValues(alpha: 0.92);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx, center.dy - radius * 0.32),
          radius: radius * 0.65,
        ),
        math.pi,
        math.pi,
        true,
        snowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.45, center.dy - radius * 0.05),
          radius: radius * 0.48,
        ),
        math.pi,
        math.pi,
        true,
        snowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx + radius * 0.45, center.dy),
          radius: radius * 0.48,
        ),
        math.pi,
        math.pi,
        true,
        snowPaint,
      );
    }
  }

  /// Paints a fluted white porcelain bonsai pot with seasonal flowering boughs.
  static void paintPorcelainPot(
    Canvas canvas,
    Offset position,
    double scale,
    AncientRoomPalette palette,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale, scale);

    final branchPaint = Paint()
      ..color = const Color(0xFF3A2618)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final branchPath = Path()
      ..moveTo(0, -45)
      ..quadraticBezierTo(-25, -110, -45, -165)
      ..moveTo(0, -45)
      ..quadraticBezierTo(20, -120, 42, -175)
      ..moveTo(-10, -85)
      ..quadraticBezierTo(15, -135, 5, -190);
    canvas.drawPath(branchPath, branchPaint);

    paintFoliageCluster(canvas, const Offset(-38, -155), 36, palette.indoorPotFlower);
    paintFoliageCluster(canvas, const Offset(35, -165), 38, palette.foliageSecondary);
    paintFoliageCluster(canvas, const Offset(2, -185), 34, palette.indoorPotFlower);
    paintFoliageCluster(canvas, const Offset(-12, -120), 32, palette.indoorPotLeaf);
    paintFoliageCluster(canvas, const Offset(22, -115), 30, palette.indoorPotFlower);

    final bodyPath = Path()
      ..moveTo(-48, -48)
      ..lineTo(48, -48)
      ..quadraticBezierTo(44, 15, 30, 58)
      ..lineTo(-30, 58)
      ..quadraticBezierTo(-44, 15, -48, -48)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-48, 0),
          const Offset(48, 0),
          const [Color(0xFFD8D4CC), Color(0xFFF7F5F0), Color(0xFFABA59B)],
          const [0.0, 0.35, 1.0],
        ),
    );
    final rimStrokePaint = Paint()
      ..color = const Color(0xFF8C857B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(bodyPath, rimStrokePaint);

    final rimRect = Rect.fromCenter(
      center: const Offset(0, -48),
      width: 104,
      height: 20,
    );
    canvas.drawOval(rimRect, Paint()..color = const Color(0xFFF0EDE6));
    canvas.drawOval(rimRect, rimStrokePaint);

    canvas.restore();
  }

  /// Paints the right partition tall dark ceramic vase with magnolia/plum branches.
  static void paintMagnoliaVase(Canvas canvas, AncientRoomPalette palette) {
    final vasePath = Path()
      ..moveTo(962, 575)
      ..lineTo(1008, 575)
      ..lineTo(998, 675)
      ..lineTo(972, 675)
      ..close();
    canvas.drawPath(vasePath, Paint()..color = const Color(0xFF36261B));

    final branchPath = Path()
      ..moveTo(985, 575)
      ..quadraticBezierTo(965, 505, 978, 445)
      ..moveTo(985, 575)
      ..quadraticBezierTo(1010, 515, 1002, 460);
    canvas.drawPath(
      branchPath,
      Paint()
        ..color = const Color(0xFF2B1B12)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke,
    );

    paintFoliageCluster(canvas, const Offset(978, 455), 24.0, const Color(0xFFF8F6F0));
    paintFoliageCluster(canvas, const Offset(1002, 475), 22.0, palette.indoorPotFlower);
  }

  /// Paints the static wooden pedestal, poles, and crossbar for the left floor palace lantern.
  static void paintFloorPalaceLanternStand(
    Canvas canvas,
    AncientRoomPalette palette,
  ) {
    const flX = 335.0;
    const pedestalRect = Rect.fromLTWH(flX - 42, 665, 84, 48);
    canvas.drawRect(pedestalRect, Paint()..color = palette.woodDark);
    canvas.drawRect(
      const Rect.fromLTWH(flX - 36, 673, 72, 32),
      Paint()
        ..color = const Color(0xFF8C6239)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final standPath = Path()
      ..moveTo(flX - 28, 665)
      ..lineTo(flX - 28, 405)
      ..moveTo(flX + 28, 665)
      ..lineTo(flX + 28, 412)
      ..moveTo(flX - 42, 398)
      ..quadraticBezierTo(flX, 412, flX + 42, 406);
    canvas.drawPath(
      standPath,
      Paint()
        ..color = palette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );
  }

  /// Paints a perspective embroidered silk floor cushion (`锦缎蒲团`) on a wooden plinth.
  static void paintFloorCushion(
    Canvas canvas,
    AncientRoomPalette palette, {
    required double cx,
    required double cy,
    required double wTop,
    required double wBot,
    required double height,
    required bool isLit,
  }) {
    final plinthPath = Path()
      ..moveTo(cx - wTop / 2 - 4, cy + 8)
      ..lineTo(cx + wTop / 2 + 4, cy + 8)
      ..lineTo(cx + wBot / 2 + 6, cy + height + 18)
      ..lineTo(cx - wBot / 2 - 6, cy + height + 18)
      ..close();
    canvas.drawPath(plinthPath, Paint()..color = palette.woodDark);

    final cushionPath = Path()
      ..moveTo(cx - wTop / 2, cy)
      ..lineTo(cx + wTop / 2, cy)
      ..lineTo(cx + wBot / 2, cy + height)
      ..lineTo(cx - wBot / 2, cy + height)
      ..close();
    canvas.drawPath(
      cushionPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - wTop / 2, cy),
          Offset(cx + wBot / 2, cy + height),
          isLit
              ? const [Color(0xFFFFF3D1), Color(0xFFF2D594), Color(0xFF9E7E46)]
              : const [Color(0xFFDFC38B), Color(0xFFC4A468), Color(0xFF9E7E46)],
          const [0.0, 0.6, 1.0],
        ),
    );
    canvas.drawPath(
      cushionPath,
      Paint()
        ..color = const Color(0xFF8C6B38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final medallionRect = Rect.fromCenter(
      center: Offset(cx, cy + height * 0.5),
      width: wTop * 0.56,
      height: height * 0.56,
    );
    canvas.drawOval(
      medallionRect,
      Paint()..color = const Color.fromRGBO(184, 59, 46, 0.25),
    );
    canvas.drawOval(
      medallionRect,
      Paint()
        ..color = const Color.fromRGBO(140, 95, 50, 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// Builds the perspective trapezoid path for the long foreground rosewood tea table.
  static Path buildTeaTableSurfacePath() {
    return Path()
      ..moveTo(575, 632)
      ..lineTo(715, 632)
      ..lineTo(645, 1000)
      ..lineTo(210, 1000)
      ..close();
  }

  /// Paints the full-perspective long rosewood tea table, brocade runner,
  /// celadon tea vessels, tea tray & cups, and twin ribbed conical incense burners.
  static void paintTeaTableAndVessels(
    Canvas canvas, {
    required bool isNight,
  }) {
    final tableSurfacePath = buildTeaTableSurfacePath();
    canvas.drawPath(
      tableSurfacePath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(250, 1000),
          const Offset(680, 630),
          const [
            Color(0xFF422515),
            Color(0xFF633920),
            Color(0xFF8A5432),
            Color(0xFFA66B44),
          ],
          const [0.0, 0.5, 0.85, 1.0],
        ),
    );

    // Rosewood right side thickness edge
    final sideEdgePath = Path()
      ..moveTo(715, 632)
      ..lineTo(724, 645)
      ..lineTo(662, 1000)
      ..lineTo(645, 1000)
      ..close();
    canvas.drawPath(sideEdgePath, Paint()..color = const Color(0xFF26140B));

    // Wood grain lines along table length
    final grainPaint = Paint()
      ..color = const Color.fromRGBO(30, 14, 6, 0.32)
      ..strokeWidth = 1.5;
    for (double ratio = 0.15; ratio <= 0.851; ratio += 0.14) {
      canvas.drawLine(
        Offset(575 + 140 * ratio, 632),
        Offset(210 + 435 * ratio, 1000),
        grainPaint,
      );
    }

    // White & Gold Brocade Table Runner (茶席织锦桌旗)
    final runnerPath = Path()
      ..moveTo(618, 634)
      ..lineTo(675, 634)
      ..lineTo(515, 1000)
      ..lineTo(355, 1000)
      ..close();
    canvas.drawPath(
      runnerPath,
      Paint()
        ..color = isNight ? const Color(0xFFC9C2B4) : const Color(0xFFF5F0E6),
    );
    canvas.drawPath(
      runnerPath,
      Paint()
        ..color = const Color(0xFFC2A675)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Celadon vase (青瓷胆瓶) & twin blue-and-white tea caddies
    canvas.drawOval(
      const Rect.fromLTWH(692 - 10, 618 - 22, 20, 44),
      Paint()..color = const Color(0xFF8AA899),
    );
    canvas.drawRect(
      const Rect.fromLTWH(689, 582, 6, 20),
      Paint()..color = const Color(0xFF8AA899),
    );
    for (final caddyCenter in const [Offset(605, 628), Offset(658, 632)]) {
      final caddyRect = Rect.fromCenter(center: caddyCenter, width: 36, height: 24);
      canvas.drawOval(caddyRect, Paint()..color = const Color(0xFFE8EEF2));
      canvas.drawOval(
        caddyRect,
        Paint()
          ..color = const Color(0xFF2B547E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Mid-table Wooden Tea Tray & Celadon Tea Set
    final trayPath = Path()
      ..moveTo(558, 692)
      ..lineTo(648, 692)
      ..lineTo(628, 748)
      ..lineTo(525, 748)
      ..close();
    canvas.drawPath(trayPath, Paint()..color = const Color(0xFF2E1A0F));
    canvas.drawPath(
      trayPath,
      Paint()
        ..color = const Color(0xFF8C6239)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final teaWarePaint = Paint()..color = const Color(0xFFD8E6DF);
    canvas.drawCircle(const Offset(595, 712), 13.0, teaWarePaint);
    for (final cupCenter in const [
      Offset(555, 730),
      Offset(576, 732),
      Offset(598, 733),
      Offset(618, 734),
    ]) {
      canvas.drawCircle(cupCenter, 6.5, teaWarePaint);
    }

    // Twin Ribbed Conical Ceramic Incense Burners (螺纹塔香炉)
    _paintConicalBurner(canvas, const Offset(542, 832), 0.86);
    _paintConicalBurner(canvas, const Offset(612, 855), 1.0);
  }

  static void _paintConicalBurner(
    Canvas canvas,
    Offset center,
    double scale,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    canvas.drawOval(
      const Rect.fromLTWH(4 - 40, 6 - 14, 80, 28),
      Paint()..color = const Color.fromRGBO(15, 8, 4, 0.38),
    );

    final conePath = Path()
      ..moveTo(-38, 4)
      ..quadraticBezierTo(0, 18, 38, 4)
      ..lineTo(8, -48)
      ..lineTo(-8, -48)
      ..close();
    canvas.drawPath(
      conePath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-36, 0),
          const Offset(36, 0),
          const [Color(0xFFDE9C68), Color(0xFFF5C396), Color(0xFF8C522B)],
          const [0.0, 0.5, 1.0],
        ),
    );

    final ridgePaint = Paint()
      ..color = const Color(0xFF754221)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (double ry = -40; ry <= 0; ry += 8) {
      final halfWidth = 8.0 + ((ry + 48.0) / 52.0) * 29.0;
      final ridgePath = Path()
        ..moveTo(-halfWidth, ry)
        ..quadraticBezierTo(0, ry + 5, halfWidth, ry);
      canvas.drawPath(ridgePath, ridgePaint);
    }

    canvas.drawOval(
      const Rect.fromLTWH(-9, -52, 18, 8),
      Paint()..color = const Color(0xFF2B1D14),
    );
    canvas.restore();
  }
}

