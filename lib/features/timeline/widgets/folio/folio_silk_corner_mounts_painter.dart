import 'package:flutter/material.dart';

/// Canvas painter rendering traditional silk corner mounts (四角绫绢护角)
/// on photo mounts and tipped-in ephemera leaves.
class FolioSilkCornerMountsPainter extends CustomPainter {
  final Color silkColor;
  final double size;

  const FolioSilkCornerMountsPainter({
    required this.silkColor,
    this.size = 14.0,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = silkColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFFAA823C).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final s = size;
    final w = canvasSize.width;
    final h = canvasSize.height;

    final corners = [
      (0.0, 0.0, s, 0.0, 0.0, s),
      (w, 0.0, w - s, 0.0, w, s),
      (0.0, h, s, h, 0.0, h - s),
      (w, h, w - s, h, w, h - s),
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner.$1, corner.$2)
        ..lineTo(corner.$3, corner.$4)
        ..lineTo(corner.$5, corner.$6)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(Offset(corner.$3, corner.$4), Offset(corner.$5, corner.$6), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FolioSilkCornerMountsPainter oldDelegate) =>
      oldDelegate.silkColor != silkColor || oldDelegate.size != size;
}
