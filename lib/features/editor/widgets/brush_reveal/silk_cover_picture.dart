import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// The opaque silk-paper cover laid over a freshly collected item, recorded
/// once per slot size into an immutable [ui.Picture] so the 60 FPS Brush
/// Reveal painter only replays it.
class SilkCoverPicture {
  final Size size;
  final ui.Picture picture;

  SilkCoverPicture._(this.size, this.picture);

  static const Color kSilk = Color(0xFFF1E8D6);
  static const Color kWeft = Color(0x14806A4A);
  static const Color kFibre = Color(0x22806A4A);
  static const Color kEdge = Color(0x33806A4A);

  factory SilkCoverPicture.record(Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    final bounds = Offset.zero & size;

    canvas.drawRect(bounds, Paint()..color = kSilk);

    // Fine horizontal weft of the mounting silk.
    final weft = Paint()
      ..color = kWeft
      ..strokeWidth = 0.6;
    for (var rowY = 2.0; rowY < size.height; rowY += 3.0) {
      canvas.drawLine(Offset(0, rowY), Offset(size.width, rowY), weft);
    }

    // A handful of deterministic paper fibres.
    final random = math.Random(size.width.round() * 31 + size.height.round());
    final fibre = Paint()
      ..color = kFibre
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 14; index++) {
      final start = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final angle = random.nextDouble() * math.pi;
      final length = 6.0 + random.nextDouble() * 10.0;
      final end = start + Offset(math.cos(angle), math.sin(angle)) * length;
      final bend = Offset.lerp(start, end, 0.5)! + Offset(random.nextDouble() * 3 - 1.5, random.nextDouble() * 3 - 1.5);
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy),
        fibre,
      );
    }

    canvas.drawRect(
      bounds.deflate(0.5),
      Paint()
        ..color = kEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    return SilkCoverPicture._(size, recorder.endRecording());
  }

  void dispose() => picture.dispose();
}
