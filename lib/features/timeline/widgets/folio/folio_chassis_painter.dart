import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints the physical Thread-Bound Folio chassis resting on the walnut desk.
///
/// Visual elements:
/// 1. Walnut book block backing with soft depth drop shadow.
/// 2. Stacked paper page depth edges on right fore-edge and bottom.
/// 3. Traditional 6-hole indigo silk cord binding (`古法六眼线装`) on left spine.
/// 4. Antique brass corner protectors (`古铜包角`) on left spine and right fore-edge.
///
/// Static vector geometry is cached into an immutable [ui.Picture] layer.
class FolioChassisPainter extends CustomPainter {
  /// Cached picture of the recorded chassis vector geometry.
  ui.Picture? cachedPicture;
  Size? _lastSize;

  FolioChassisPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (cachedPicture == null || _lastSize != size) {
      final recorder = ui.PictureRecorder();
      final recordingCanvas = Canvas(recorder, Offset.zero & size);
      _drawChassis(recordingCanvas, size);
      cachedPicture?.dispose();
      cachedPicture = recorder.endRecording();
      _lastSize = size;
    }
    canvas.drawPicture(cachedPicture!);
  }

  void _drawChassis(Canvas canvas, Size size) {
    // 1. Stacked Paper-Block Edges on Right (x: 42..52) and Bottom (y: 12..21)
    for (int depthIndex = 5; depthIndex >= 1; depthIndex--) {
      final edgeColor = depthIndex.isEven
          ? const Color(0xFFDCD3C2)
          : const Color(0xFFC7BDA9);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            42.0 + depthIndex * 2.0,
            12.0 + depthIndex * 1.8,
            360,
            596,
          ),
          topRight: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        ),
        Paint()..color = edgeColor,
      );
    }

    // 2. Hardcover Indigo Silk Brocade Backing (left: 8..412, top: 4..620)
    final coverRect = RRect.fromRectAndCorners(
      const Rect.fromLTWH(8, 4, 404, 616),
      topLeft: const Radius.circular(6),
      bottomLeft: const Radius.circular(6),
      topRight: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );

    // Book backing drop shadow
    canvas.drawRRect(
      coverRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Dark walnut / indigo silk gradient backing
    canvas.drawRRect(
      coverRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1E2631),
            Color(0xFF151B24),
            Color(0xFF0F131A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(8, 4, 404, 616)),
    );

    // Fine gold filament border stroke
    canvas.drawRRect(
      coverRect,
      Paint()
        ..color = const Color(0xFF8C7355).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 3. Left Thread-Bound Spine Strip (古法六眼线装书脊 x: 8..42, y: 12..608)
    const spineRect = Rect.fromLTWH(8, 12, 34, 596);
    canvas.drawRect(
      spineRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF283342),
            Color(0xFF19212B),
            Color(0xFF10161E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(spineRect),
    );

    // Spine gutter crease seam
    canvas.drawLine(
      const Offset(42, 12),
      const Offset(42, 608),
      Paint()
        ..color = const Color(0xFFC8AC78).withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );

    // 4. Antique Brass Corner Protectors (古铜包角)
    // Spine corner caps
    final spineBrassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4B572), Color(0xFF8C6B32), Color(0xFF533D18)],
      ).createShader(const Rect.fromLTWH(8, 12, 34, 40));
    canvas.drawRect(const Rect.fromLTWH(8, 12, 34, 20), spineBrassPaint);
    canvas.drawRect(const Rect.fromLTWH(8, 588, 34, 20), spineBrassPaint);

    // Fore-edge brass corner protectors (top-right and bottom-right)
    final foreEdgeBrassTop = Path()
      ..moveTo(392, 4)
      ..lineTo(412, 4)
      ..lineTo(412, 24)
      ..close();
    canvas.drawPath(
      foreEdgeBrassTop,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD4B572), Color(0xFF8C6B32), Color(0xFF533D18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(392, 4, 20, 20)),
    );

    final foreEdgeBrassBottom = Path()
      ..moveTo(412, 600)
      ..lineTo(412, 620)
      ..lineTo(392, 620)
      ..close();
    canvas.drawPath(
      foreEdgeBrassBottom,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD4B572), Color(0xFF8C6B32), Color(0xFF533D18)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(const Rect.fromLTWH(392, 600, 20, 20)),
    );

    // 5. Traditional 6-Hole Indigo Silk Cord Binding (六眼线装丝线)
    const holeYCoordinates = [62.0, 156.0, 256.0, 356.0, 456.0, 550.0];
    final cordShadowPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final cordPaint = Paint()
      ..color = const Color(0xFFEAE3D2)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int holeIndex = 0; holeIndex < holeYCoordinates.length; holeIndex++) {
      final yCoordinate = holeYCoordinates[holeIndex];

      // Horizontal wrap loop around left spine edge
      canvas.drawLine(
        Offset(8, yCoordinate),
        Offset(28, yCoordinate),
        cordShadowPaint,
      );
      canvas.drawLine(
        Offset(8, yCoordinate),
        Offset(28, yCoordinate),
        cordPaint,
      );

      // Vertical spine thread segment to next eyelet
      if (holeIndex < holeYCoordinates.length - 1) {
        final nextYCoordinate = holeYCoordinates[holeIndex + 1];
        canvas.drawLine(
          Offset(28, yCoordinate),
          Offset(28, nextYCoordinate),
          cordShadowPaint,
        );
        canvas.drawLine(
          Offset(28, yCoordinate),
          Offset(28, nextYCoordinate),
          cordPaint,
        );
      }
    }

    // Eyelets and knot rivets
    for (final yCoordinate in holeYCoordinates) {
      canvas.drawCircle(
        Offset(28, yCoordinate),
        3.6,
        Paint()..color = const Color(0xFF0B0E12),
      );
      canvas.drawCircle(
        Offset(28, yCoordinate),
        3.6,
        Paint()
          ..color = const Color(0xFFD4B572)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        Offset(28, yCoordinate),
        1.7,
        Paint()..color = const Color(0xFFEAE3D2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FolioChassisPainter oldDelegate) => false;
}
