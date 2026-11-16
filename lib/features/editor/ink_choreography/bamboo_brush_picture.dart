import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// The rigid parts of the spotted-bamboo brush (斑竹笔): red silk tassel,
/// mottled shaft with its node ridge and gold inscription dots, ox-horn
/// ferrule and gold ring. They never change, so they are recorded once into
/// an immutable [ui.Picture] that the 60 FPS brush painter only replays.
///
/// Drawn in brush units with the ferrule base at the origin and the shaft
/// rising along negative `y`.
abstract final class BambooBrushPicture {
  static const Rect shaftRect = Rect.fromLTWH(-5.8, -136, 11.6, 114);
  static const Radius shaftCorner = Radius.circular(2.4);

  static ui.Picture? _picture;
  static Path? _silhouette;

  /// The shared recording, made on first use and kept for the app's lifetime.
  static ui.Picture get picture => _picture ??= _record();

  /// The outline of the shaft and ferrule, for the brush's drop shadow.
  static Path get silhouette => _silhouette ??= (Path()
    ..addRRect(RRect.fromRectAndRadius(shaftRect, shaftCorner))
    ..addPath(_ferrulePath(), Offset.zero));

  static Path _ferrulePath() => Path()
    ..moveTo(-6.0, -22)
    ..lineTo(6.0, -22)
    ..lineTo(7.4, 0)
    ..lineTo(-7.4, 0)
    ..close();

  static Paint _line(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width
    ..color = color;

  static ui.Picture _record() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTRB(-12, -152, 24, 4));

    // Red silk hanging loop at the top of the shaft.
    canvas.drawPath(
      Path()
        ..moveTo(0, -138)
        ..quadraticBezierTo(14, -148, 18, -132)
        ..quadraticBezierTo(19, -122, 8, -118),
      _line(const Color(0xFFB83B2E), 2.1),
    );

    // Bamboo shaft, lit from the upper left.
    final shaft = RRect.fromRectAndRadius(shaftRect, shaftCorner);
    canvas.drawRRect(
      shaft,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4A3520), Color(0xFF8C6840), Color(0xFFC8A26A), Color(0xFF6B4E2E), Color(0xFF332312)],
          stops: [0.0, 0.28, 0.58, 0.85, 1.0],
        ).createShader(shaftRect),
    );
    _paintMottling(canvas, shaft);
    canvas.drawRRect(shaft, _line(const Color(0xFF2B1D0E), 0.7));

    // Node ridge (竹节) with its highlight.
    canvas.drawPath(
      Path()
        ..moveTo(-5.8, -78)
        ..quadraticBezierTo(0, -75, 5.8, -78),
      _line(const Color(0xFF3B2814), 2.0)..strokeCap = StrokeCap.butt,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-5.5, -76.5)
        ..quadraticBezierTo(0, -73.5, 5.5, -76.5),
      _line(const Color(0xB3E2C38B), 0.8)..strokeCap = StrokeCap.butt,
    );

    // Gold inscription dots.
    final gold = Paint()..color = const Color(0xD9E8C574);
    canvas.drawCircle(const Offset(0, -58), 1.1, gold);
    canvas.drawCircle(const Offset(0, -51), 1.0, gold);
    canvas.drawCircle(const Offset(0, -44), 1.1, gold);

    // Ox-horn ferrule (牛角笔斗) and its gold ring.
    final ferrule = _ferrulePath();
    canvas.drawPath(
      ferrule,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF141210), Color(0xFF3A332C), Color(0xFF0D0B0A)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(const Rect.fromLTRB(-7.4, -22, 7.4, 0)),
    );
    canvas.drawPath(ferrule, _line(const Color(0xFF12100E), 0.6)..strokeJoin = StrokeJoin.miter);
    canvas.drawLine(
      const Offset(-6.1, -20),
      const Offset(6.1, -20),
      _line(const Color(0xFFD4AF37), 1.3)..strokeCap = StrokeCap.butt,
    );

    return recorder.endRecording();
  }

  /// The faint tear-stain spots that give spotted bamboo (斑竹) its name.
  static void _paintMottling(Canvas canvas, RRect shaft) {
    const spots = [
      (Offset(-2.6, -126), Size(2.2, 3.6)),
      (Offset(2.2, -112), Size(1.8, 3.0)),
      (Offset(-1.2, -98), Size(2.4, 4.2)),
      (Offset(3.0, -88), Size(1.6, 2.6)),
      (Offset(-3.0, -66), Size(1.8, 3.2)),
      (Offset(2.4, -36), Size(2.0, 3.4)),
      (Offset(-1.8, -28), Size(1.6, 2.4)),
    ];
    canvas.save();
    canvas.clipRRect(shaft);
    final spot = Paint()
      ..color = const Color(0x383B2412)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    for (final (center, size) in spots) {
      canvas.drawOval(Rect.fromCenter(center: center, width: size.width, height: size.height), spot);
    }
    canvas.restore();
  }
}
