import 'package:flutter/rendering.dart';

import 'ink_choreography_timeline.dart';

/// Paints the Airborne Silk Trace (提笔游丝): the faint dashed ink filament
/// along the lifted arc from one character's last stroke to the next
/// character's first. Draws nothing for transits outside the 6..180dp window.
class SilkTracePainter extends CustomPainter {
  final InkTransit transit;
  final Color inkColor;

  const SilkTracePainter({required this.transit, required this.inkColor, super.repaint});

  static const double _strokeWidth = 0.9;
  static const double _dashLength = 2.0;
  static const double _gapLength = 3.0;
  static const double _alpha = 0.26;

  @override
  void paint(Canvas canvas, Size size) => paintTrace(canvas, transit, inkColor: inkColor);

  @override
  bool shouldRepaint(SilkTracePainter oldDelegate) =>
      !identical(oldDelegate.transit, transit) || oldDelegate.inkColor != inkColor;

  static void paintTrace(Canvas canvas, InkTransit transit, {required Color inkColor}) {
    if (!transit.showsSilkTrace) return;
    final arc = Path()
      ..moveTo(transit.from.dx, transit.from.dy)
      ..quadraticBezierTo(transit.control.dx, transit.control.dy, transit.to.dx, transit.to.dy);

    final dashes = Path();
    for (final metric in arc.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dashLength + _gapLength) {
        dashes.addPath(metric.extractPath(start, start + _dashLength), Offset.zero);
      }
    }
    canvas.drawPath(
      dashes,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..color = inkColor.withValues(alpha: inkColor.a * _alpha),
    );
  }
}
