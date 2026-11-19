import 'package:flutter/material.dart';

/// Helper Painter for Chinese Manuscript Grid (九宫方格).
class ManuscriptGridPainter extends CustomPainter {
  const ManuscriptGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFC5B69C).withValues(alpha: 0.35)
      ..strokeWidth = 0.6;

    const gridSize = 12.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper Painter for Hand-Painted Ink Bamboo on Manuscript Card.
class InkBambooPainter extends CustomPainter {
  const InkBambooPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF1E1D1A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()..color = const Color(0xFF1C1B18);

    final s1 = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.5, size.width * 0.50, size.height * 0.1);
    canvas.drawPath(s1, stemPaint);

    final s2 = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.6, size.width * 0.65, size.height * 0.3);
    canvas.drawPath(s2, stemPaint..strokeWidth = 1.3);

    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.68),
      Offset(size.width * 0.28, size.height * 0.69),
      stemPaint..strokeWidth = 2.2,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.40),
      Offset(size.width * 0.41, size.height * 0.41),
      stemPaint..strokeWidth = 2.0,
    );

    _drawLeaf(canvas, Offset(size.width * 0.38, size.height * 0.40), 22, -0.2, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.40, size.height * 0.40), 18, 0.3, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.48, size.height * 0.20), 20, -0.4, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.54, size.height * 0.50), 22, 0.2, leafPaint);
  }

  void _drawLeaf(Canvas canvas, Offset origin, double length, double angle, Paint paint) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -3, length, 0)
      ..quadraticBezierTo(length * 0.5, 3, 0, 0)
      ..close();
    canvas.drawPath(leafPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper Painter for Jiangnan Water-Ink Landscape & Sailboat on Travel Card.
class JiangnanLandscapePainter extends CustomPainter {
  const JiangnanLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final hill1 = Path()
      ..moveTo(0, height * 0.55)
      ..quadraticBezierTo(width * 0.20, height * 0.20, width * 0.40, height * 0.42)
      ..quadraticBezierTo(width * 0.65, height * 0.30, width, height * 0.45)
      ..lineTo(width, height * 0.70)
      ..lineTo(0, height * 0.70)
      ..close();
    canvas.drawPath(hill1, Paint()..color = const Color(0xFF8A968E).withValues(alpha: 0.45));

    final hill2 = Path()
      ..moveTo(0, height * 0.60)
      ..quadraticBezierTo(width * 0.18, height * 0.35, width * 0.35, height * 0.50)
      ..quadraticBezierTo(width * 0.60, height * 0.45, width, height * 0.58)
      ..lineTo(width, height * 0.75)
      ..lineTo(0, height * 0.75)
      ..close();
    canvas.drawPath(hill2, Paint()..color = const Color(0xFF52645B).withValues(alpha: 0.55));

    canvas.drawRect(
      Rect.fromLTWH(0, height * 0.60, width, height * 0.40),
      Paint()..color = const Color(0xFFF4EFE4).withValues(alpha: 0.85),
    );

    final promontory = Path()
      ..moveTo(0, height * 0.72)
      ..quadraticBezierTo(width * 0.15, height * 0.65, width * 0.28, height * 0.80)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(promontory, Paint()..color = const Color(0xFF2B3530).withValues(alpha: 0.80));

    final routePaint = Paint()
      ..color = const Color(0xFF9E7B56)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedCurve(
      canvas,
      Offset(width * 0.25, height * 0.85),
      Offset(width * 0.60, height * 0.65),
      routePaint,
    );

    _drawSailboat(canvas, Offset(width * 0.60, height * 0.38));
  }

  void _drawDashedCurve(Canvas canvas, Offset p0, Offset p2, Paint paint) {
    final p1 = Offset((p0.dx + p2.dx) / 2, p0.dy - 10);
    const segments = 10;
    for (int idx = 0; idx < segments; idx += 2) {
      final t1 = idx / segments;
      final t2 = (idx + 1) / segments;
      canvas.drawLine(
        _evalBezier(p0, p1, p2, t1),
        _evalBezier(p0, p1, p2, t2),
        paint,
      );
    }
  }

  Offset _evalBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  void _drawSailboat(Canvas canvas, Offset origin) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final sail1 = Path()
      ..moveTo(8, 2)
      ..lineTo(8, 22)
      ..lineTo(0, 20)
      ..lineTo(2, 5)
      ..close();
    canvas.drawPath(sail1, Paint()..color = const Color(0xFFEAE0CE));
    canvas.drawPath(
      sail1,
      Paint()
        ..color = const Color(0xFF3A3228)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    final sail2 = Path()
      ..moveTo(10, 0)
      ..lineTo(10, 22)
      ..lineTo(18, 19)
      ..lineTo(16, 3)
      ..close();
    canvas.drawPath(sail2, Paint()..color = const Color(0xFFDFD2BC));
    canvas.drawPath(
      sail2,
      Paint()
        ..color = const Color(0xFF3A3228)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    final hull = Path()
      ..moveTo(-3, 21)
      ..quadraticBezierTo(9, 26, 23, 20)
      ..lineTo(19, 24)
      ..lineTo(1, 24)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF3D3124));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
