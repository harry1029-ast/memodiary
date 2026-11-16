import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'bamboo_brush_picture.dart';
import 'brush_kinematics.dart';
import 'ink_choreography_timeline.dart';
import 'silk_trace_painter.dart';

/// Paints the kinematic bamboo brushes of the brush layer: for each
/// [BrushPose] the contact shadow on the paper, the brush's soft drop shadow,
/// the rigid shaft (replayed from [BambooBrushPicture]) and the bending
/// bristle cone with its ink belly and hair filament. Optionally draws the
/// Airborne Silk Trace beneath them. Pure: everything comes from the poses.
class BambooBrushPainter extends CustomPainter {
  final List<BrushPose> poses;
  final Color inkColor;

  /// The transit whose silk trace is showing, if any.
  final InkTransit? silkTrace;

  const BambooBrushPainter({
    required this.poses,
    required this.inkColor,
    this.silkTrace,
    super.repaint,
  });

  static const Color _bristleRoot = Color(0xFFF5EFE2);
  static const Color _bristleBody = Color(0xFFC7B89E);
  static const Color _filament = Color(0x80FAF6EE);
  static const Color _dropShadow = Color(0x52000000);

  /// The drop shadow's offset and blur at full size, in logical pixels.
  static const Offset _dropShadowOffset = Offset(4, 12);
  static const double _dropShadowSigma = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final trace = silkTrace;
    if (trace != null) SilkTracePainter.paintTrace(canvas, trace, inkColor: inkColor);
    for (final pose in poses) {
      paintBrush(canvas, pose, inkColor: inkColor);
    }
  }

  @override
  bool shouldRepaint(BambooBrushPainter oldDelegate) =>
      !identical(oldDelegate.poses, poses) ||
      !identical(oldDelegate.silkTrace, silkTrace) ||
      oldDelegate.inkColor != inkColor;

  /// Paints one brush. Exposed so an overlay can compose its own brush layer.
  static void paintBrush(Canvas canvas, BrushPose pose, {required Color inkColor}) {
    _paintContactShadow(canvas, pose, inkColor);

    canvas.save();
    canvas.translate(pose.handle.dx, pose.handle.dy);
    canvas.rotate(pose.shaftRadians);
    canvas.scale(pose.pxPerUnit);

    final radius = pose.ferruleRadius;
    final tip = pose.localTip;
    final left = pose.leftControl;
    final right = pose.rightControl;
    final cone = Path()
      ..moveTo(-radius, 0)
      ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(right.dx, right.dy, radius, 0)
      ..close();

    _paintDropShadow(canvas, pose, cone);

    canvas.save();
    canvas.scale(pose.shaftScale);
    canvas.drawPicture(BambooBrushPicture.picture);
    canvas.restore();

    // Bristle cone: pale at the root, soaking into ink towards the tip.
    final top = math.min(0.0, _quadraticExtreme(0, left.dy, tip.dy, math.min));
    final bottom = math.max(
      math.max(0.0, tip.dy),
      math.max(_quadraticExtreme(0, left.dy, tip.dy, math.max), _quadraticExtreme(tip.dy, right.dy, 0, math.max)),
    );
    canvas.drawPath(
      cone,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, math.max(bottom, top + 0.01)),
          [_bristleRoot, _bristleBody, inkColor.withValues(alpha: inkColor.a * 0.92), inkColor],
          const [0.0, 0.38, 0.76, 1.0],
        ),
    );

    // Ink-saturated belly over the lower bristles.
    final bellyRadius = radius * 0.76;
    final bellyTop = tip.dy * 0.14;
    canvas.drawPath(
      Path()
        ..moveTo(-bellyRadius, bellyTop)
        ..quadraticBezierTo(left.dx * 0.82, left.dy * 0.82, tip.dx, tip.dy)
        ..quadraticBezierTo(right.dx * 0.82, right.dy * 0.82, bellyRadius, bellyTop)
        ..close(),
      Paint()..color = inkColor.withValues(alpha: inkColor.a * 0.92),
    );

    // Specular hair filament along the bent spine.
    final spine = left * 0.6 + right * 0.4;
    canvas.drawPath(
      Path()
        ..moveTo(-radius * 0.22, 0)
        ..quadraticBezierTo(spine.dx, spine.dy, tip.dx, tip.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.6
        ..color = _filament,
    );

    canvas.restore();
  }

  /// The small shadow the bristles cast where they meet the paper.
  static void _paintContactShadow(Canvas canvas, BrushPose pose, Color inkColor) {
    final radii = pose.shadowRadii;
    canvas.drawOval(
      Rect.fromCenter(center: pose.shadowCenter, width: radii.width * 2, height: radii.height * 2),
      Paint()..color = inkColor.withValues(alpha: inkColor.a * pose.shadowOpacity),
    );
  }

  /// One soft shadow under the whole brush (shaft, ferrule and bristles), so
  /// it reads as held above the paper.
  static void _paintDropShadow(Canvas canvas, BrushPose pose, Path cone) {
    // Drawn inside the brush's scaled space; a small Trial Rice-Grid brush
    // keeps a shadow no smaller than 80% of the sheet brush's.
    final toLocal = math.max(pose.pxPerUnit, 0.8) / pose.pxPerUnit;
    final scale = Float64List.fromList([
      pose.shaftScale, 0, 0, 0,
      0, pose.shaftScale, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
    final silhouette = Path()
      ..addPath(BambooBrushPicture.silhouette.transform(scale), Offset.zero)
      ..addPath(cone, Offset.zero);
    canvas.drawPath(
      silhouette.shift(_dropShadowOffset * toLocal),
      Paint()
        ..color = _dropShadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _dropShadowSigma * toLocal),
    );
  }

  /// The extreme `y` of the quadratic Bézier `start, control, end`.
  static double _quadraticExtreme(
    double start,
    double control,
    double end,
    double Function(double, double) pick,
  ) {
    var extreme = pick(start, end);
    final denominator = start - 2 * control + end;
    if (denominator.abs() > 1e-9) {
      final t = (start - control) / denominator;
      if (t > 0 && t < 1) {
        final inverse = 1 - t;
        extreme = pick(extreme, inverse * inverse * start + 2 * inverse * t * control + t * t * end);
      }
    }
    return extreme;
  }
}
