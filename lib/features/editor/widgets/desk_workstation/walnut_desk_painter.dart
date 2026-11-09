import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints the dark walnut desk top and, when [matInsets] is given, the woven
/// bamboo mat runner with its antique brass corner inlays. The editor canvas
/// paints the desk surface once beneath everything; the Desk Workstation paints
/// only its mat on top ([paintsDesk] false) so the two read as one desk. The
/// geometry is static, so it is recorded once per size into an immutable
/// [ui.Picture] and replayed on every frame.
class WalnutDeskPainter extends CustomPainter {
  /// Inset of the bamboo mat from the edges; its top leaves room for the
  /// workstation header. No mat when null.
  final EdgeInsets? matInsets;

  /// Whether to paint the walnut surface and its grain beneath the mat.
  final bool paintsDesk;

  WalnutDeskPainter({this.matInsets, this.paintsDesk = true});

  static const Color kWalnut = Color(0xFF211A14);
  static const Color kMat = Color(0xFF241D16);
  static const Color kBrass = Color(0x8CD4AF37);

  ui.Picture? _picture;
  Size? _recordedSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (_picture == null || _recordedSize != size) {
      final recorder = ui.PictureRecorder();
      _record(Canvas(recorder, Offset.zero & size), size);
      _picture?.dispose();
      _picture = recorder.endRecording();
      _recordedSize = size;
    }
    canvas.drawPicture(_picture!);
  }

  void _record(Canvas canvas, Size size) {
    final deskRect = Offset.zero & size;
    if (paintsDesk) _recordDesk(canvas, deskRect);
    final insets = matInsets;
    if (insets != null) _recordBambooMat(canvas, insets.deflateRect(deskRect));
  }

  void _recordDesk(Canvas canvas, Rect deskRect) {
    final size = deskRect.size;
    canvas.drawRect(deskRect, Paint()..color = kWalnut);
    canvas.drawRect(
      deskRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.0, -0.3),
          radius: 1.1,
          colors: [Color(0x17FFE8B9), Color(0xB80F0B08)],
        ).createShader(deskRect),
    );

    // Long walnut grain running the width of the desk.
    final grainPaint = Paint()
      ..color = const Color(0x29000000)
      ..strokeWidth = 1.0;
    for (double grainY = 6.0; grainY < size.height; grainY += 13.0) {
      canvas.drawLine(Offset(0, grainY), Offset(size.width, grainY + 1.5), grainPaint);
    }
  }

  void _recordBambooMat(Canvas canvas, Rect matRect) {
    if (matRect.width <= 0 || matRect.height <= 0) return;
    final matShape = RRect.fromRectAndRadius(matRect, const Radius.circular(8.0));
    canvas.drawRRect(
      matShape.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );
    canvas.drawRRect(matShape, Paint()..color = kMat);

    canvas.save();
    canvas.clipRRect(matShape);
    // Horizontal bamboo slats.
    final slatLight = Paint()..color = const Color(0x0DD4AF37);
    final slatShadow = Paint()..color = const Color(0x38000000);
    for (double slatY = matRect.top; slatY < matRect.bottom; slatY += 6.0) {
      canvas.drawRect(Rect.fromLTWH(matRect.left, slatY, matRect.width, 3.0), slatLight);
      canvas.drawRect(Rect.fromLTWH(matRect.left, slatY + 3.0, matRect.width, 3.0), slatShadow);
    }
    // Vertical binding threads.
    final threadPaint = Paint()..color = const Color(0x40000000);
    for (double threadX = matRect.left + 18.0; threadX < matRect.right; threadX += 20.0) {
      canvas.drawRect(Rect.fromLTWH(threadX, matRect.top, 2.0, matRect.height), threadPaint);
    }
    canvas.restore();

    canvas.drawRRect(
      matShape,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x598C6D46)
        ..strokeWidth = 1.0,
    );
    _recordBrassCorners(canvas, matRect.deflate(4.0));
  }

  void _recordBrassCorners(Canvas canvas, Rect cornerRect) {
    const arm = 10.0;
    final brassPaint = Paint()
      ..color = kBrass
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final corners = [
      (cornerRect.topLeft, 1.0, 1.0),
      (cornerRect.topRight, -1.0, 1.0),
      (cornerRect.bottomLeft, 1.0, -1.0),
      (cornerRect.bottomRight, -1.0, -1.0),
    ];
    for (final (corner, directionX, directionY) in corners) {
      final cornerPath = Path()
        ..moveTo(corner.dx + arm * directionX, corner.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(corner.dx, corner.dy + arm * directionY);
      canvas.drawPath(cornerPath, brassPaint);
    }
  }

  @override
  bool shouldRepaint(WalnutDeskPainter oldDelegate) =>
      oldDelegate.matInsets != matInsets || oldDelegate.paintsDesk != paintsDesk;
}
