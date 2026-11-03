import 'package:flutter/material.dart';

/// Paints the crimson silk bookmark ribbon (`朱红绫绢书签带`) hanging from the top spine.
///
/// Supports rotational sway physics during 3D page turning gestures via [swayAngle].
class FolioSilkBookmarkPainter extends CustomPainter {
  /// Rotational angle in radians applied at the top anchor of the ribbon.
  final double swayAngle;

  const FolioSilkBookmarkPainter({
    this.swayAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (swayAngle != 0.0) {
      canvas.translate(size.width * 0.5, 0);
      canvas.rotate(swayAngle);
      canvas.translate(-size.width * 0.5, 0);
    }

    final ribbonPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.5, size.height - 10)
      ..lineTo(0, size.height)
      ..close();

    // Subtle drop shadow cast onto the book block
    canvas.drawPath(
      ribbonPath.shift(const Offset(1.5, 2.0)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Crimson silk gradient with sheen
    canvas.drawPath(
      ribbonPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF9E2B20),
            Color(0xFFB83B2E),
            Color(0xFF7D1F16),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FolioSilkBookmarkPainter oldDelegate) =>
      oldDelegate.swayAngle != swayAngle;
}
