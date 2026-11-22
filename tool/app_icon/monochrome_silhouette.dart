// The Android 13 themed-icon silhouette: a flat single-colour moon disc, two
// ruyi clouds and an open book (SPEC-023 Implementation Decision 6). Drawn in
// unit coordinates whose content stays inside the unit square's inscribed
// circle, so mapping that square onto the adaptive icon's 66dp safe zone keeps
// every shape unclipped under any launcher mask.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Gap cut between overlapping shapes so each reads as its own form.
const _shapeGap = 0.022;

/// Paints the silhouette in [color] so that the unit square maps onto
/// [safeZone] (the adaptive icon's 66dp safe-zone square).
void paintMonochromeSilhouette(Canvas canvas, Rect safeZone, Color color) {
  canvas.save();
  canvas.translate(safeZone.left, safeZone.top);
  canvas.scale(safeZone.width, safeZone.height);
  canvas.saveLayer(const Rect.fromLTWH(-0.1, -0.1, 1.2, 1.2), Paint());

  final fill = Paint()
    ..color = color
    ..isAntiAlias = true;
  final cut = Paint()
    ..blendMode = BlendMode.clear
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  canvas.drawCircle(const Offset(0.5, 0.34), 0.205, fill);

  for (final mirrored in [false, true]) {
    final cloud = _mirror(_ruyiCloud(), mirrored);
    canvas.drawPath(cloud, cut..strokeWidth = _shapeGap * 2);
    canvas.drawPath(cloud, fill);
    canvas.drawPath(_mirror(_cloudCurl(), mirrored), cut..strokeWidth = 0.022);
  }

  for (final mirrored in [false, true]) {
    canvas.drawPath(_mirror(_bookPage(), mirrored), fill);
    canvas.drawPath(_mirror(_bookCover(), mirrored), fill);
  }

  canvas.restore();
  canvas.restore();
}

// Left cloud anchor and lobe unit; the right cloud mirrors it about x = 0.5.
const _cloudX = 0.275;
const _cloudY = 0.535;
const _lobe = 0.072;

/// The left ruyi cloud: three lobes over a rounded base.
Path _ruyiCloud() {
  Path circle(double dx, double dy, double radius) => Path()
    ..addOval(
      Rect.fromCircle(center: Offset(_cloudX + dx * _lobe, _cloudY + dy * _lobe), radius: radius * _lobe),
    );
  final base = Path()
    ..addRRect(
      RRect.fromLTRBR(
        _cloudX - 1.55 * _lobe,
        _cloudY - 0.1 * _lobe,
        _cloudX + 1.85 * _lobe,
        _cloudY + 0.75 * _lobe,
        const Radius.circular(0.38 * _lobe),
      ),
    );
  var cloud = Path.combine(PathOperation.union, base, circle(-0.85, -0.05, 0.85));
  cloud = Path.combine(PathOperation.union, cloud, circle(0.15, -0.6, 1.05));
  return Path.combine(PathOperation.union, cloud, circle(1.15, 0.0, 0.8));
}

/// The ruyi curl carved into the left cloud's top lobe: a spiral that winds
/// out of the lobe and runs down through the base, like the painted outline.
Path _cloudCurl() {
  const centre = Offset(_cloudX + 0.15 * _lobe, _cloudY - 0.6 * _lobe);
  const turns = 1.2;
  const innerRadius = 0.1 * _lobe;
  const outerRadius = 0.6 * _lobe;
  final curl = Path();
  const steps = 48;
  for (var step = 0; step <= steps; step++) {
    final progress = step / steps;
    // Winds clockwise and ends pointing straight down from the centre.
    final angle = math.pi * 0.5 - (1 - progress) * turns * 2 * math.pi;
    final radius = innerRadius + (outerRadius - innerRadius) * progress;
    final point = centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    if (step == 0) {
      curl.moveTo(point.dx, point.dy);
    } else {
      curl.lineTo(point.dx, point.dy);
    }
  }
  final end = centre + const Offset(0, outerRadius);
  curl.quadraticBezierTo(
    end.dx - 0.45 * _lobe,
    end.dy + 0.1 * _lobe,
    end.dx - 0.5 * _lobe,
    _cloudY + 0.9 * _lobe,
  );
  return curl;
}

/// The left page of the open book, curling up from the spine.
Path _bookPage() => Path()
  ..moveTo(0.486, 0.705)
  ..quadraticBezierTo(0.35, 0.645, 0.205, 0.662)
  ..lineTo(0.188, 0.828)
  ..quadraticBezierTo(0.34, 0.818, 0.486, 0.858)
  ..close();

/// The left half of the book cover's thickness under the page block.
Path _bookCover() => Path()
  ..moveTo(0.18, 0.846)
  ..quadraticBezierTo(0.34, 0.838, 0.5, 0.878)
  ..lineTo(0.5, 0.904)
  ..quadraticBezierTo(0.34, 0.866, 0.176, 0.87)
  ..close();

Path _mirror(Path path, bool mirrored) {
  if (!mirrored) return path;
  final flip = Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1]);
  return path.transform(flip);
}
