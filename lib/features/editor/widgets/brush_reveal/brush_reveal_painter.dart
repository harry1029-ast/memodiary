import 'package:flutter/rendering.dart';

import 'brush_reveal_choreography.dart';
import 'silk_cover_picture.dart';

/// The dynamic 60 FPS layer of the Brush Reveal: erases the pre-recorded
/// silk-paper cover along the painted sweeps (`BlendMode.dstOut` inside a
/// saved layer, edged with a wet-ink halo), fades what remains, and draws the
/// bamboo brush with lagging, bent bristles. The static cover lives in
/// [SilkCoverPicture].
class BrushRevealPainter extends CustomPainter {
  final BrushRevealFrame frame;
  final List<BrushSweep> sweeps;
  final SilkCoverPicture cover;

  static const Color kWetInk = Color(0x47231F1C);
  static const Color kBristleInk = Color(0xFF1F1B18);
  static const Color kFerrule = Color(0xFF6B4F35);
  static const Color kBamboo = Color(0xFFC9A66B);
  static const Color kBambooNode = Color(0xFF8C6A3C);

  const BrushRevealPainter({
    required this.frame,
    required this.sweeps,
    required this.cover,
  });

  double _progressOf(int index) => (frame.sweepsPainted - index).clamp(0.0, 1.0);

  Path _sweepPath(BrushSweep sweep) => Path()
    ..moveTo(sweep.start.dx, sweep.start.dy)
    ..quadraticBezierTo(sweep.control.dx, sweep.control.dy, sweep.end.dx, sweep.end.dy);

  Paint _stroke(double width, {Color color = const Color(0xFF000000), BlendMode blendMode = BlendMode.srcOver}) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color
        ..blendMode = blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.coverOpacity > 0.0) _paintCover(canvas, size);
    if (frame.isBrushVisible) _paintBrush(canvas);
  }

  void _paintCover(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, frame.coverOpacity));
    canvas.drawPicture(cover.picture);

    final painted = [
      for (var index = 0; index < sweeps.length; index++)
        if (_progressOf(index) > 0.0) sweeps[index].partial(_progressOf(index)),
    ];
    // Halos first, so a later sweep's wet edge never stains an earlier opening.
    for (final sweep in painted) {
      canvas.drawPath(_sweepPath(sweep), _stroke(sweep.radius * 2 + 5.0, color: kWetInk));
    }
    for (final sweep in painted) {
      canvas.drawPath(_sweepPath(sweep), _stroke(sweep.radius * 2, blendMode: BlendMode.dstOut));
    }
    canvas.restore();
  }

  void _paintBrush(Canvas canvas) {
    final index = frame.sweepsPainted.floor().clamp(0, sweeps.length - 1);
    final sweep = sweeps[index];
    final pose = BrushPose.at(sweep, _progressOf(index));
    final radius = sweep.radius;
    final bristleLength = radius * 1.4;
    final bristleWidth = radius * 0.5;
    final bend = ((pose.trail.dx - pose.tip.dx) / radius).clamp(-1.0, 1.0) * radius * 0.35;

    canvas.save();
    canvas.translate(pose.tip.dx, pose.tip.dy);
    canvas.rotate(pose.tilt);

    // Bristles: a tapered tuft bent by the drag of travel.
    final bristles = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-bristleWidth * 0.6 + bend, -bristleLength * 0.45, -bristleWidth / 2, -bristleLength)
      ..lineTo(bristleWidth / 2, -bristleLength)
      ..quadraticBezierTo(bristleWidth * 0.6 + bend, -bristleLength * 0.45, 0, 0)
      ..close();
    canvas.drawPath(bristles, Paint()..color = kBristleInk);

    // Ferrule and bamboo handle with two nodes.
    final handleWidth = radius * 0.32;
    final ferruleTop = -bristleLength - radius * 0.3;
    canvas.drawRect(
      Rect.fromLTRB(-handleWidth * 0.65, ferruleTop, handleWidth * 0.65, -bristleLength),
      Paint()..color = kFerrule,
    );
    final handleTop = ferruleTop - radius * 2.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-handleWidth / 2, handleTop, handleWidth / 2, ferruleTop),
        Radius.circular(handleWidth / 2),
      ),
      Paint()..color = kBamboo,
    );
    final node = _stroke(1.2, color: kBambooNode);
    for (final fraction in const [0.35, 0.75]) {
      final nodeY = ferruleTop + (handleTop - ferruleTop) * fraction;
      canvas.drawLine(Offset(-handleWidth / 2, nodeY), Offset(handleWidth / 2, nodeY), node);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrushRevealPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.cover != cover || oldDelegate.sweeps != sweeps;
}
