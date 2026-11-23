import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fenghuang_palette.dart';
import 'fenghuang_static_architecture.dart';

/// Immutable layout descriptor for a perspective wooden stilt house (`吊脚楼`).
@immutable
class FenghuangStiltHouseSpec {
  final double x;
  final double waterY;
  final double bankY;
  final double width;
  final int floors;
  final double floorHeight;
  final double scale;
  final bool isLeftBank;

  const FenghuangStiltHouseSpec({
    required this.x,
    required this.waterY,
    required this.bankY,
    required this.width,
    required this.floors,
    required this.floorHeight,
    required this.scale,
    required this.isLeftBank,
  });
}

/// Riverbank seasonal trees, 10 perspective multi-story wooden Stilt Houses
/// (`湘西吊脚楼群`), and their swaying corner red lanterns.
class FenghuangArchitectureLayers {
  const FenghuangArchitectureLayers._();

  static const List<FenghuangStiltHouseSpec> leftBankHouses = [
    FenghuangStiltHouseSpec(
      x: 475, waterY: 575, bankY: 530, width: 92, floors: 2, floorHeight: 42, scale: 0.68, isLeftBank: true,
    ),
    FenghuangStiltHouseSpec(
      x: 385, waterY: 625, bankY: 565, width: 108, floors: 3, floorHeight: 44, scale: 0.78, isLeftBank: true,
    ),
    FenghuangStiltHouseSpec(
      x: 275, waterY: 690, bankY: 615, width: 122, floors: 3, floorHeight: 48, scale: 0.90, isLeftBank: true,
    ),
    FenghuangStiltHouseSpec(
      x: 145, waterY: 775, bankY: 685, width: 138, floors: 3, floorHeight: 52, scale: 1.04, isLeftBank: true,
    ),
    FenghuangStiltHouseSpec(
      x: 15, waterY: 865, bankY: 760, width: 150, floors: 3, floorHeight: 56, scale: 1.18, isLeftBank: true,
    ),
  ];

  static const List<FenghuangStiltHouseSpec> rightBankHouses = [
    FenghuangStiltHouseSpec(
      x: 1035, waterY: 575, bankY: 530, width: 92, floors: 2, floorHeight: 42, scale: 0.68, isLeftBank: false,
    ),
    FenghuangStiltHouseSpec(
      x: 1130, waterY: 625, bankY: 565, width: 108, floors: 3, floorHeight: 44, scale: 0.78, isLeftBank: false,
    ),
    FenghuangStiltHouseSpec(
      x: 1245, waterY: 690, bankY: 615, width: 122, floors: 3, floorHeight: 48, scale: 0.90, isLeftBank: false,
    ),
    FenghuangStiltHouseSpec(
      x: 1375, waterY: 775, bankY: 685, width: 138, floors: 3, floorHeight: 52, scale: 1.04, isLeftBank: false,
    ),
    FenghuangStiltHouseSpec(
      x: 1495, waterY: 865, bankY: 760, width: 150, floors: 3, floorHeight: 56, scale: 1.18, isLeftBank: false,
    ),
  ];

  static List<FenghuangStiltHouseSpec> get allBankHouses =>
      const [...leftBankHouses, ...rightBankHouses];

  /// Paints riverbank seasonal trees and 10 perspective wooden stilt houses.
  static void paintBankTreesAndStiltHouses(
    Canvas canvas,
    FenghuangPalette palette, {
    required bool hasSnowCover,
    required double lanternLevel,
  }) {
    const bankTrees = [
      (440.0, 485.0, 36.0), (360.0, 505.0, 40.0), (240.0, 525.0, 44.0),
      (1010.0, 480.0, 36.0), (1120.0, 500.0, 42.0), (1260.0, 520.0, 45.0),
    ];
    for (int index = 0; index < bankTrees.length; index++) {
      final (tx, ty, tr) = bankTrees[index];
      final treeColor = index.isEven ? palette.foliagePrimary : palette.foliageSecondary;
      FenghuangStaticArchitecture.paintFoliageCluster(
        canvas, tx, ty, tr, treeColor, hasSnowCover,
      );
    }

    for (final house in allBankHouses) {
      _paintStiltHouse(
        canvas,
        house,
        hasSnowCover: hasSnowCover,
        lanternLevel: lanternLevel,
      );
    }
  }

  static void _paintStiltHouse(
    Canvas canvas,
    FenghuangStiltHouseSpec house, {
    required bool hasSnowCover,
    required double lanternLevel,
  }) {
    canvas.save();
    canvas.translate(house.x, house.bankY);
    canvas.scale(house.scale, house.scale);

    final stiltBottomY = (house.waterY - house.bankY) / house.scale;
    final houseWidth = house.width;
    const woodWall = Color(0xFF3A2417);
    const woodDark = Color(0xFF21130B);
    const roofColor = Color(0xFF2C2F33);

    canvas.drawRect(
      Rect.fromLTWH(
        -houseWidth * 0.48,
        0,
        houseWidth * 0.96,
        math.max(18.0, stiltBottomY * 0.45),
      ),
      Paint()..color = const Color(0xFF4A4640),
    );

    final stiltPaint = Paint()
      ..color = woodDark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.5;
    final bracePaint = Paint()
      ..color = woodDark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int stiltIndex = 0; stiltIndex < 4; stiltIndex++) {
      final sx = -houseWidth * 0.42 + (stiltIndex / 3.0) * (houseWidth * 0.84);
      canvas.drawLine(Offset(sx, -10), Offset(sx, stiltBottomY + 8), stiltPaint);
      canvas.drawLine(
        Offset(sx, stiltBottomY * 0.45),
        Offset(sx + (house.isLeftBank ? 16.0 : -16.0), -6),
        bracePaint,
      );
    }

    final chamberFill = Paint()..color = woodWall;
    final darkStroke = Paint()
      ..color = woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final latticeStroke = Paint()
      ..color = woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final balconyFill = Paint()..color = const Color(0xFF4F311F);

    for (int floorIndex = 0; floorIndex < house.floors; floorIndex++) {
      final yBot = -floorIndex * house.floorHeight;
      final yTop = -(floorIndex + 1) * house.floorHeight;
      final chamberW = houseWidth * (floorIndex == 0 ? 1.0 : 0.92);

      final chamberRect = Rect.fromLTWH(-chamberW / 2, yTop, chamberW, house.floorHeight);
      canvas.drawRect(chamberRect, chamberFill);
      canvas.drawRect(chamberRect, darkStroke);

      final winW = chamberW * 0.68;
      final winH = house.floorHeight * 0.58;
      final winRect = Rect.fromLTWH(-winW / 2, yTop + 8, winW, winH);
      if (lanternLevel > 0.22) {
        final glowAlpha = (0.5 + lanternLevel * 0.48).clamp(0.0, 1.0);
        canvas.drawRect(
          winRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(255, 232, 155, glowAlpha),
                Color.fromRGBO(242, 145, 45, glowAlpha),
              ],
            ).createShader(winRect),
        );
      } else {
        canvas.drawRect(winRect, Paint()..color = const Color(0xFF6E5A48));
      }

      for (double wx = -winW / 2; wx <= winW / 2; wx += 14) {
        canvas.drawLine(Offset(wx, yTop + 8), Offset(wx, yTop + 8 + winH), latticeStroke);
      }

      final balconyRect = Rect.fromLTWH(-chamberW * 0.55, yBot - 12, chamberW * 1.1, 12);
      canvas.drawRect(balconyRect, balconyFill);
      canvas.drawRect(balconyRect, latticeStroke);

      final isTopFloor = floorIndex == house.floors - 1;
      FenghuangStaticArchitecture.drawSweepingRoof(
        canvas,
        0,
        yTop - (isTopFloor ? 26 : 16),
        chamberW * (isTopFloor ? 0.55 : 0.88),
        chamberW * 1.32,
        isTopFloor ? 28 : 18,
        roofColor,
        hasSnowCover,
        lanternLevel,
      );
    }

    canvas.restore();
  }

  /// Paints swaying corner red lanterns under the eaves of all 10 stilt houses.
  static void paintStiltHouseCornerLanterns(
    Canvas canvas, {
    required double animationTime,
    required double wind,
    required double lanternLevel,
  }) {
    final bodyPaint = Paint()
      ..color =
          lanternLevel > 0.2 ? const Color(0xFFFF5733) : const Color(0xFFC83728);

    for (final house in allBankHouses) {
      canvas.save();
      canvas.translate(house.x, house.bankY);
      canvas.scale(house.scale, house.scale);

      for (int floorIndex = 0; floorIndex < house.floors; floorIndex++) {
        final yTop = -(floorIndex + 1) * house.floorHeight;
        final chamberW = house.width * (floorIndex == 0 ? 1.0 : 0.92);
        final sway =
            math.sin(animationTime * 1.8 * wind + house.x * 0.02 + floorIndex) *
                3.0 *
                wind;
        final lyCorner = yTop + 4.0;

        for (final cornerX in [-chamberW * 0.56, chamberW * 0.56]) {
          final center = Offset(cornerX + sway, lyCorner);
          if (lanternLevel > 0.2) {
            canvas.drawCircle(
              center,
              28.0,
              Paint()
                ..shader = RadialGradient(
                  colors: [
                    Color.fromRGBO(255, 210, 110, 0.75 * lanternLevel),
                    const Color.fromRGBO(235, 80, 30, 0),
                  ],
                  stops: const [0.06, 1.0],
                ).createShader(Rect.fromCircle(center: center, radius: 28.0)),
            );
          }
          canvas.drawOval(
            Rect.fromCenter(center: center, width: 16, height: 13),
            bodyPaint,
          );
        }
      }

      canvas.restore();
    }
  }
}
