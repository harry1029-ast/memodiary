import 'package:flutter/material.dart';

/// Decorative vector painter rendering a tactile antique brass paperclip (古铜回形针).
class AntiqueBrassPaperclipPainter extends CustomPainter {
  final bool isDark;

  const AntiqueBrassPaperclipPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final brassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE5C158),
          Color(0xFFC59B27),
          Color(0xFF8A6417),
          Color(0xFF5A3D0A),
        ],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Paperclip path: outer loop -> inner loop
    final path = Path();
    // Start at inner tip
    path.moveTo(w * 0.40, h * 0.70);
    path.lineTo(w * 0.40, h * 0.35);
    // Inner top bend
    path.arcToPoint(
      Offset(w * 0.70, h * 0.35),
      radius: Radius.circular(w * 0.15),
      clockwise: true,
    );
    path.lineTo(w * 0.70, h * 0.80);
    // Outer bottom bend
    path.arcToPoint(
      Offset(w * 0.15, h * 0.80),
      radius: Radius.circular(w * 0.275),
      clockwise: true,
    );
    path.lineTo(w * 0.15, h * 0.20);
    // Outer top bend
    path.arcToPoint(
      Offset(w * 0.85, h * 0.20),
      radius: Radius.circular(w * 0.35),
      clockwise: true,
    );
    // Outer right leg
    path.lineTo(w * 0.85, h * 0.65);

    // Draw drop shadow
    canvas.save();
    canvas.translate(1.0, 1.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw brass metallic clip
    canvas.drawPath(path, brassPaint);
  }

  @override
  bool shouldRepaint(covariant AntiqueBrassPaperclipPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Gold washi tape strip (泥金和纸胶带) pinned at the card corner.
class GoldWashiTapeWidget extends StatelessWidget {
  final double width;
  final double height;
  final double rotationAngle;

  const GoldWashiTapeWidget({
    super.key,
    this.width = 38.0,
    this.height = 10.0,
    this.rotationAngle = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1.5),
          gradient: const LinearGradient(
            colors: [
              Color(0xB3D4AF37),
              Color(0xCCE6CA65),
              Color(0x99B8860B),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: const Color(0x66FDE68A),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

