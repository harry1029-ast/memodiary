import 'package:flutter/rendering.dart';

/// The Yunhao Cloud-Moon emblem: a moon disc above two drifting cloud strokes.
///
/// Drawn on a 24×24 design grid scaled to the paint size. The closed book
/// cover embosses it faintly; the Diarist Panel's cloud avatar draws it in the
/// active palette's header and accent colours.
class CloudMoonEmblemPainter extends CustomPainter {
  /// Moon outline and upper cloud stroke.
  final Color primaryColor;

  /// Lower cloud stroke.
  final Color accentColor;

  /// Moon disc fill, or none.
  final Color? moonFillColor;

  /// Multiplies the design stroke widths (1.0 suits a ~24dp emblem; larger
  /// emblems use a smaller weight to keep hairline strokes).
  final double strokeWeight;

  const CloudMoonEmblemPainter({
    required this.primaryColor,
    required this.accentColor,
    this.moonFillColor,
    this.strokeWeight = 1.0,
  });

  static const Offset _moonCentre = Offset(13.0, 9.5);
  static const double _moonRadius = 4.6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    final moonFill = moonFillColor;
    if (moonFill != null) {
      canvas.drawCircle(_moonCentre, _moonRadius, Paint()..color = moonFill);
    }

    final primaryStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3 * strokeWeight;
    canvas.drawCircle(_moonCentre, _moonRadius, primaryStroke);

    canvas.drawPath(
      Path()
        ..moveTo(4.0, 15.0)
        ..quadraticBezierTo(9.8, 12.2, 15.6, 14.6)
        ..quadraticBezierTo(18.6, 15.8, 21.0, 13.6),
      primaryStroke..strokeWidth = 1.45 * strokeWeight,
    );

    canvas.drawPath(
      Path()
        ..moveTo(6.2, 17.6)
        ..quadraticBezierTo(12.2, 15.6, 18.4, 17.6),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.2 * strokeWeight,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CloudMoonEmblemPainter oldDelegate) {
    return primaryColor != oldDelegate.primaryColor ||
        accentColor != oldDelegate.accentColor ||
        moonFillColor != oldDelegate.moonFillColor ||
        strokeWeight != oldDelegate.strokeWeight;
  }
}
