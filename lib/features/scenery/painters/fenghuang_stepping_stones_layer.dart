import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';

typedef _SteppingVisitorSpec = ({
  int pierIndex,
  Color jacket,
  Color skirt,
  bool isMiao,
  bool hasUmbrella,
  bool showAtNight,
});

/// 17-pier double-row red-sandstone Tuojiang Stepping Stones (`跳岩`),
/// animated foaming white water rapids, and time-filtered visitors wearing
/// traditional Miao silver headdresses (`苗族银饰头冠`) & oiled-paper umbrellas.
class FenghuangSteppingStonesLayer {
  const FenghuangSteppingStonesLayer._();

  static const int steppingStoneCount = 17;

  static const List<_SteppingVisitorSpec> _steppingVisitors = [
    (
      pierIndex: 3,
      jacket: Color(0xFF3B4F78),
      skirt: Color(0xFF26334D),
      isMiao: true,
      hasUmbrella: true,
      showAtNight: false,
    ),
    (
      pierIndex: 5,
      jacket: Color(0xFFD95B43),
      skirt: Color(0xFF3D352E),
      isMiao: false,
      hasUmbrella: false,
      showAtNight: true,
    ),
    (
      pierIndex: 8,
      jacket: Color(0xFF4A7C59),
      skirt: Color(0xFF2E3830),
      isMiao: false,
      hasUmbrella: true,
      showAtNight: false,
    ),
    (
      pierIndex: 10,
      jacket: Color(0xFF52688F),
      skirt: Color(0xFF2E3A4F),
      isMiao: true,
      hasUmbrella: true,
      showAtNight: true,
    ),
    (
      pierIndex: 12,
      jacket: Color(0xFFE09F5A),
      skirt: Color(0xFF423832),
      isMiao: false,
      hasUmbrella: false,
      showAtNight: false,
    ),
    (
      pierIndex: 14,
      jacket: Color(0xFFC84B62),
      skirt: Color(0xFF382E32),
      isMiao: true,
      hasUmbrella: true,
      showAtNight: false,
    ),
  ];

  /// Returns active Stepping Stone visitor count for [timeOfDay]
  /// (`0` at Dawn, `6` at Day/Dusk, `2` at Night).
  static int visibleSteppingVisitorCount(ShanshuiTimeOfDay timeOfDay) {
    if (timeOfDay == ShanshuiTimeOfDay.dawn) return 0;
    if (timeOfDay == ShanshuiTimeOfDay.night) {
      return _steppingVisitors.where((visitor) => visitor.showAtNight).length;
    }
    return _steppingVisitors.length;
  }

  /// Paints the 17-pier double-row red-sandstone Tuojiang Stepping Stones (`跳岩`),
  /// foaming white rapids, and time-filtered visitors wearing Miao silver headdresses.
  static void paintSteppingStonesAndVisitors(
    Canvas canvas, {
    required ShanshuiTimeOfDay timeOfDay,
    required double animationTime,
    required bool hasSnowCover,
    required bool isWetWeather,
    required bool isSnowWeather,
  }) {
    const jumpY = 795.0;
    const leftStart = 285.0;
    const rightEnd = 1215.0;
    final isNight = timeOfDay == ShanshuiTimeOfDay.night;

    final foamPaint = Paint()
      ..color = const Color.fromRGBO(240, 248, 255, 0.42)
      ..strokeWidth = 3.0;
    final blockStroke = Paint()
      ..color = const Color(0xFF241612)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final rearFill = Paint()
      ..color = isNight ? const Color(0xFF4A3B36) : const Color(0xFF8C584C);
    final mainFill = Paint()
      ..color = isNight ? const Color(0xFF5C4740) : const Color(0xFFA66858);
    final capFill = Paint()
      ..color = hasSnowCover
          ? const Color(0xFFF8FAFC)
          : isNight
              ? const Color(0xFF755D54)
              : const Color(0xFFC98A78);

    for (int index = 0; index < steppingStoneCount; index++) {
      final frac = index / (steppingStoneCount - 1);
      final sx = leftStart + frac * (rightEnd - leftStart);
      final sy = jumpY + math.sin(frac * math.pi) * 22.0;

      final foamLen = 22.0 + math.sin(animationTime * 4.5 + index) * 8.0;
      canvas.drawLine(Offset(sx - 6, sy + 14), Offset(sx - 4, sy + 14 + foamLen), foamPaint);
      canvas.drawLine(
        Offset(sx + 6, sy + 14),
        Offset(sx + 8, sy + 14 + foamLen * 0.8),
        foamPaint,
      );

      final rearRect = Rect.fromLTWH(sx - 12, sy - 22, 20, 14);
      canvas.drawRect(rearRect, rearFill);
      canvas.drawRect(rearRect, blockStroke);

      final mainRect = Rect.fromLTWH(sx - 15, sy - 8, 30, 24);
      canvas.drawRect(mainRect, mainFill);
      canvas.drawRect(mainRect, blockStroke);

      final capRect = Rect.fromLTWH(sx - 15, sy - 12, 30, 7);
      canvas.drawRect(capRect, capFill);
      canvas.drawRect(capRect, blockStroke);
    }

    if (timeOfDay == ShanshuiTimeOfDay.dawn) return;

    final figureStroke = Paint()
      ..color = const Color(0xFF1F1612)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final hornStroke = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int index = 0; index < _steppingVisitors.length; index++) {
      final visitor = _steppingVisitors[index];
      if (isNight && !visitor.showAtNight) continue;

      final frac = visitor.pierIndex / (steppingStoneCount - 1);
      final wx = leftStart +
          frac * (rightEnd - leftStart) +
          math.sin(animationTime * 1.8 + index) * 4.0;
      final wy = jumpY +
          math.sin(frac * math.pi) * 22.0 -
          14.0 -
          math.sin(animationTime * 2.6 + index).abs() * 3.0;

      canvas.save();
      canvas.translate(wx, wy);

      canvas.drawRect(const Rect.fromLTWH(-7, -18, 14, 18), Paint()..color = visitor.skirt);
      final jacketRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -38, 18, 22),
        const Radius.circular(4),
      );
      canvas.drawRRect(jacketRRect, Paint()..color = visitor.jacket);
      canvas.drawRRect(jacketRRect, figureStroke);

      canvas.drawCircle(const Offset(0, -45), 6.5, Paint()..color = const Color(0xFFF2D2B6));

      if (visitor.isMiao) {
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(0, -49), radius: 7.5),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFFE2E8F0),
        );
        final hornsPath = Path()
          ..moveTo(-5, -52)
          ..quadraticBezierTo(-12, -62, -8, -66)
          ..moveTo(5, -52)
          ..quadraticBezierTo(12, -62, 8, -66);
        canvas.drawPath(hornsPath, hornStroke);
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(0, -47), radius: 6.8),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF26201D),
        );
      }

      if ((isWetWeather || isSnowWeather) && visitor.hasUmbrella) {
        final canopy = Path()
          ..addArc(Rect.fromCircle(center: const Offset(4, -56), radius: 20), math.pi, math.pi)
          ..close();
        canvas.drawPath(canopy, Paint()..color = const Color(0xFFD96B43));
        canvas.drawPath(canopy, figureStroke);
      }

      canvas.restore();
    }
  }
}
