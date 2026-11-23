import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/west_lake_palette.dart';
import 'west_lake_static_architecture.dart';

typedef _BridgeVisitorSpec = ({
  double offset,
  Color robe,
  Color cape,
  Color umbrellaCol,
  bool showAtNight,
});

/// Causeway, lakeside pavilion, Broken Bridge masonry, and strolling Hanfu
/// visitor painters for the Hangzhou West Lake (`西湖`) realm.
class WestLakeBridges {
  const WestLakeBridges._();

  static const List<_BridgeVisitorSpec> _bridgeVisitors = [
    (
      offset: 135,
      robe: Color(0xFF5B7FA6),
      cape: Color(0xFFD9E2EC),
      umbrellaCol: Color(0xFFE57383),
      showAtNight: true,
    ),
    (
      offset: 172,
      robe: Color(0xFFE8D8C8),
      cape: Color(0xFF4A6984),
      umbrellaCol: Color(0xFF5FA8D3),
      showAtNight: false,
    ),
    (
      offset: 245,
      robe: Color(0xFFD96B78),
      cape: Color(0xFFF7E6E8),
      umbrellaCol: Color(0xFFF2A6B0),
      showAtNight: true,
    ),
    (
      offset: 315,
      robe: Color(0xFF588163),
      cape: Color(0xFFD8E6DC),
      umbrellaCol: Color(0xFFE89B3C),
      showAtNight: false,
    ),
    (
      offset: 385,
      robe: Color(0xFF8C584C),
      cape: Color(0xFFE6D2C8),
      umbrellaCol: Color(0xFFC84B31),
      showAtNight: false,
    ),
  ];

  /// Returns active visitor count on Broken Bridge for [timeOfDay]
  /// (`0` at Dawn, `5` at Day/Dusk, `2` at Night).
  static int visibleVisitorCount(ShanshuiTimeOfDay timeOfDay) {
    if (timeOfDay == ShanshuiTimeOfDay.dawn) return 0;
    if (timeOfDay == ShanshuiTimeOfDay.night) {
      return _bridgeVisitors.where((visitor) => visitor.showAtNight).length;
    }
    return _bridgeVisitors.length;
  }

  /// Paints Su Causeway (`苏堤春晓`) arch embankment, alternating willow/peach
  /// trees, and Pinghu Qiuyue (`平湖秋月`) waterside pavilion above lake reflections.
  static void paintCausewayAndPinghuPavilion(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
  }) {
    final hasSnowCover = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final lanternLevel = WestLakeStaticArchitecture.effectiveLanternLevel(
      westLakePalette,
      atmosphere.weather,
    );

    final causewayPath = Path()
      ..moveTo(0, 526)
      ..lineTo(745, 522)
      ..lineTo(745, 536)
      ..arcTo(
        Rect.fromCircle(center: const Offset(385, 536), radius: 26),
        0,
        -math.pi,
        false,
      )
      ..lineTo(0, 540)
      ..close();
    canvas.drawPath(
      causewayPath,
      Paint()
        ..color = hasSnowCover
            ? const Color(0xFFE2E8F0)
            : isNight
                ? const Color(0xFF2B363B)
                : const Color(0xFF5E6B64),
    );

    for (int index = 0; index <= 10; index++) {
      final sx = 65.0 + index * 62.0;
      final treeColor = index.isEven
          ? westLakePalette.foliageSecondary
          : westLakePalette.foliagePrimary;
      WestLakeStaticArchitecture.paintFoliageCluster(
        canvas,
        sx,
        508,
        22,
        treeColor,
        hasSnowCover,
      );
    }

    // Pinghu Qiuyue Waterside Pavilion (平湖秋月临水书榭)
    const phX = 165.0;
    const phY = 588.0;
    canvas.drawRect(
      const Rect.fromLTWH(phX - 85, phY - 10, 175, 16),
      Paint()..color = const Color(0xFF4A4E52),
    );
    final stiltPaint = Paint()
      ..color = const Color(0xFF261C16)
      ..strokeWidth = 3.0;
    for (final stX in const [-72.0, -36.0, 0.0, 36.0, 72.0]) {
      canvas.drawLine(Offset(phX + stX, phY + 6), Offset(phX + stX, phY + 32), stiltPaint);
    }

    canvas.drawRect(
      const Rect.fromLTWH(phX - 62, phY - 52, 124, 42),
      Paint()
        ..color = lanternLevel > 0.2
            ? const Color(0xFFFFE39E)
            : const Color(0xFFD9CFC0),
    );
    final latticePaint = Paint()
      ..color = const Color(0xFF3B2416)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (double wx = -62; wx <= 62; wx += 20) {
      canvas.drawLine(Offset(phX + wx, phY - 52), Offset(phX + wx, phY - 10), latticePaint);
    }
    canvas.drawRect(const Rect.fromLTWH(phX - 78, phY - 18, 162, 8), latticePaint);

    WestLakeStaticArchitecture.drawSweepingRoof(
      canvas, phX, phY - 76, 98, 172, 26, const Color(0xFF282C30), hasSnowCover, lanternLevel,
    );
    WestLakeStaticArchitecture.drawSweepingRoof(
      canvas, phX, phY - 98, 48, 122, 22, const Color(0xFF282C30), hasSnowCover, lanternLevel,
    );
  }

  /// Paints Broken Bridge (`断桥残雪`) stone masonry, winter melting-snow
  /// slopes, carved balustrade posts, and lakeside stele pavilion.
  static void paintBrokenBridgeAndStelePavilion(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
  }) {
    final hasSnowCover = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final lanternLevel = WestLakeStaticArchitecture.effectiveLanternLevel(
      westLakePalette,
      atmosphere.weather,
    );

    const brLeftX = 875.0;
    const brRightX = 1520.0;
    const brWaterY = 742.0;

    final bridgeBody = Path()
      ..moveTo(brLeftX, brWaterY)
      ..lineTo(brLeftX + 65, brWaterY - 38)
      ..quadraticBezierTo(brLeftX + 245, brWaterY - 98, brLeftX + 430, brWaterY - 42)
      ..lineTo(brRightX, brWaterY - 28)
      ..lineTo(brRightX, brWaterY + 25)
      ..lineTo(brLeftX + 345, brWaterY + 12)
      ..arcTo(
        Rect.fromCircle(center: const Offset(brLeftX + 245, brWaterY + 8), radius: 78),
        0,
        -math.pi,
        false,
      )
      ..lineTo(brLeftX, brWaterY + 6)
      ..close();

    canvas.drawPath(
      bridgeBody,
      Paint()..color = isNight ? const Color(0xFF474D54) : const Color(0xFF8C8982),
    );
    canvas.drawPath(
      bridgeBody,
      Paint()
        ..color = const Color(0xFF2B2927)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final archShadow = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(brLeftX + 245, brWaterY + 8), radius: 74),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(
      archShadow,
      Paint()
        ..color = isNight
            ? const Color.fromRGBO(8, 14, 20, 0.7)
            : const Color.fromRGBO(22, 42, 38, 0.55),
    );

    if (hasSnowCover) {
      final snowPaint = Paint()..color = const Color(0xFFF8FAFC);
      final leftSlopeSnow = Path()
        ..moveTo(brLeftX, brWaterY)
        ..lineTo(brLeftX + 185, brWaterY - 68)
        ..lineTo(brLeftX + 215, brWaterY - 58)
        ..lineTo(brLeftX + 10, brWaterY + 4)
        ..close();
      canvas.drawPath(leftSlopeSnow, snowPaint);

      final rightSlopeSnow = Path()
        ..moveTo(brLeftX + 285, brWaterY - 66)
        ..lineTo(brRightX, brWaterY - 28)
        ..lineTo(brRightX, brWaterY - 14)
        ..lineTo(brLeftX + 275, brWaterY - 54)
        ..close();
      canvas.drawPath(rightSlopeSnow, snowPaint);
    }

    final postFill = Paint()
      ..color = hasSnowCover ? const Color(0xFFF1F5F9) : const Color(0xFFB8B4AC);
    final postStroke = Paint()
      ..color = const Color(0xFF33302C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (double bx = 20; bx <= 580; bx += 38) {
      final archFrac = math.max(0.0, 1.0 - math.pow((bx - 245) / 220, 2));
      final postX = brLeftX + bx;
      final postY = brWaterY - 28 - archFrac * 44;
      final rect = Rect.fromLTWH(postX - 3, postY - 18, 6, 18);
      canvas.drawRect(rect, postFill);
      canvas.drawRect(rect, postStroke);
    }

    // Broken Bridge Lakeside Stele Pavilion (断桥云水光中碑亭)
    const pavX = brLeftX + 58;
    const pavY = brWaterY - 34;
    final pillarPaint = Paint()..color = const Color(0xFF4A2C1B);
    canvas.drawRect(const Rect.fromLTWH(pavX - 28, pavY - 46, 6, 46), pillarPaint);
    canvas.drawRect(const Rect.fromLTWH(pavX + 22, pavY - 46, 6, 46), pillarPaint);
    WestLakeStaticArchitecture.drawSweepingRoof(
      canvas, pavX, pavY - 68, 42, 86, 24, const Color(0xFF2B2E33), hasSnowCover, lanternLevel,
    );
  }

  /// Paints Hanfu visitors carrying silk umbrellas (`西湖绸伞`) along Broken Bridge.
  static void paintBrokenBridgeVisitors(
    Canvas canvas, {
    required ShanshuiTimeOfDay timeOfDay,
    required double animationTime,
    required bool isWetWeather,
    required bool isSnowWeather,
  }) {
    if (timeOfDay == ShanshuiTimeOfDay.dawn) return;
    final isNight = timeOfDay == ShanshuiTimeOfDay.night;
    const brLeftX = 875.0;
    const brWaterY = 742.0;

    final outline = Paint()
      ..color = const Color(0xFF231B16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int index = 0; index < _bridgeVisitors.length; index++) {
      final visitor = _bridgeVisitors[index];
      if (isNight && !visitor.showAtNight) continue;

      final bx = visitor.offset + math.sin(animationTime * 1.2 + index) * 6;
      final archFrac = math.max(0.0, 1.0 - math.pow((bx - 245) / 220, 2));
      final vx = brLeftX + bx;
      final vy = brWaterY - 30 - archFrac * 44;

      canvas.save();
      canvas.translate(vx, vy);

      final robePath = Path()
        ..moveTo(-8, -32)
        ..lineTo(8, -32)
        ..lineTo(11, 0)
        ..lineTo(-11, 0)
        ..close();
      canvas.drawPath(robePath, Paint()..color = visitor.robe);
      canvas.drawPath(robePath, outline);

      final capeRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -34, 18, 14),
        const Radius.circular(3),
      );
      canvas.drawRRect(capeRRect, Paint()..color = visitor.cape);
      canvas.drawRRect(capeRRect, outline);

      canvas.drawCircle(const Offset(0, -41), 6, Paint()..color = const Color(0xFFF2D2B6));
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0, -44), radius: 6.2),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFF231D1A),
      );

      if (isWetWeather || isSnowWeather || index.isEven) {
        final canopy = Path()
          ..addArc(Rect.fromCircle(center: const Offset(4, -52), radius: 19), math.pi, math.pi)
          ..close();
        canvas.drawPath(canopy, Paint()..color = visitor.umbrellaCol);
        canvas.drawPath(
          canopy,
          Paint()
            ..color = const Color(0xFF2B1B12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }

      canvas.restore();
    }
  }
}
