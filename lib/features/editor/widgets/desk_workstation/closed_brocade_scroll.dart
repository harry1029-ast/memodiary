import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The closed, brocade-wrapped Staging Handscroll (锦袱束绦) resting diagonally on
/// the Desk Workstation while nothing waits to be mounted. Tapping it starts
/// collecting a keepsake.
class ClosedBrocadeScroll extends StatefulWidget {
  final VoidCallback? onTap;

  const ClosedBrocadeScroll({super.key, this.onTap});

  static const String kSemanticLabel = '待贴画卷已空 · 点按收集影札';

  @override
  State<ClosedBrocadeScroll> createState() => _ClosedBrocadeScrollState();
}

class _ClosedBrocadeScrollState extends State<ClosedBrocadeScroll> {
  final _painter = ClosedBrocadeScrollPainter();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: ClosedBrocadeScroll.kSemanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
          child: CustomPaint(painter: _painter, child: const SizedBox.expand()),
        ),
      ),
    );
  }
}

/// Static geometry of the closed scroll, recorded once per size into a
/// [ui.Picture]: a celadon brocade cylinder tilted 66°, its title slip, silk
/// cord, jade pin and the spiral of rolled silk at its end.
class ClosedBrocadeScrollPainter extends CustomPainter {
  static const double kTiltRadians = -66.0 * math.pi / 180.0;
  static const String kSlipTitle = '拾光待贴画卷';
  static const double kSlipFontSize = 12.0;

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
    // A tilted cylinder of length L and width 0.24L spans about 1.01L × 0.63L.
    final length = math.min(size.width / 1.01, size.height / 0.63) * 0.92;
    if (length <= 0) return;
    final width = length * 0.24;

    canvas.save();
    canvas.translate(size.width / 2.0, size.height / 2.0);
    canvas.rotate(kTiltRadians);
    final body = Rect.fromCenter(center: Offset.zero, width: width, height: length);
    final bodyShape = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(width / 2.0),
      topRight: Radius.circular(width / 2.0),
      bottomLeft: Radius.circular(width / 4.0),
      bottomRight: Radius.circular(width / 4.0),
    );

    canvas.drawRRect(
      bodyShape.shift(Offset(-width * 0.25, width * 0.3)),
      Paint()
        ..color = const Color(0xC7000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.3),
    );
    canvas.drawRRect(bodyShape, Paint()..color = const Color(0xFF6B8B8E));

    canvas.save();
    canvas.clipRRect(bodyShape);
    _recordBrocadeWeave(canvas, body);
    canvas.drawRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x8C120F0C), Color(0x47FFFAEB), Color(0x38D4AF37), Color(0xAD0F0C0A)],
          stops: [0.0, 0.28, 0.55, 1.0],
        ).createShader(body),
    );
    canvas.restore();

    _recordTitleSlip(canvas, body, width);
    _recordJadePinAndCord(canvas, body, width, length);
    _recordEndSpiral(canvas, body, width);
    canvas.restore();
  }

  void _recordBrocadeWeave(Canvas canvas, Rect body) {
    final goldThread = Paint()
      ..color = const Color(0x59D4AF37)
      ..strokeWidth = 1.5;
    final tealThread = Paint()
      ..color = const Color(0x802D4E56)
      ..strokeWidth = 1.5;
    for (double offset = -body.height; offset < body.height; offset += 8.0) {
      canvas.drawLine(
        Offset(body.left, body.top + offset),
        Offset(body.right, body.top + offset + body.width),
        goldThread,
      );
      canvas.drawLine(
        Offset(body.right, body.top + offset),
        Offset(body.left, body.top + offset + body.width),
        tealThread,
      );
    }
  }

  void _recordTitleSlip(Canvas canvas, Rect body, double width) {
    final slip = Rect.fromLTWH(
      -width * 0.2,
      body.top + body.height * 0.07,
      width * 0.4,
      body.height * 0.63,
    );
    canvas.drawRect(
      slip,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8D5B5), Color(0xFFDFC69E)],
        ).createShader(slip),
    );
    canvas.drawRect(
      slip,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x80785830)
        ..strokeWidth = 0.75,
    );

    // The slip title reads top to bottom, drawn only when every glyph fits legibly.
    final glyphStride = slip.height / kSlipTitle.length;
    if (glyphStride < kSlipFontSize + 1.0 || slip.width < kSlipFontSize) return;
    for (final (glyphIndex, glyph) in kSlipTitle.characters.indexed) {
      final glyphPainter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: const TextStyle(fontSize: kSlipFontSize, color: Color(0xFF2B2118), height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      glyphPainter.paint(
        canvas,
        Offset(
          slip.center.dx - glyphPainter.width / 2.0,
          slip.top + glyphStride * glyphIndex + (glyphStride - glyphPainter.height) / 2.0,
        ),
      );
      glyphPainter.dispose();
    }
  }

  void _recordJadePinAndCord(Canvas canvas, Rect body, double width, double length) {
    final cordTop = body.top + length * 0.43;
    final pin = Rect.fromLTWH(body.left + width * 0.06, cordTop - length * 0.1, width * 0.14, length * 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pin, Radius.circular(width * 0.07)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF76967E), Color(0xFFA8C4AE), Color(0xFF56735D)],
        ).createShader(pin),
    );
    final cord = Rect.fromLTWH(body.left - 2.0, cordTop, width + 4.0, math.max(4.0, length * 0.05));
    canvas.drawRect(
      cord,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5C4E38), Color(0xFF9E8866), Color(0xFF4A3E2B)],
          stops: [0.0, 0.45, 1.0],
        ).createShader(cord),
    );
  }

  void _recordEndSpiral(Canvas canvas, Rect body, double width) {
    final spiral = Rect.fromCenter(
      center: Offset(0.0, body.bottom),
      width: width - 2.0,
      height: width * 0.5,
    );
    canvas.drawOval(spiral, Paint()..color = const Color(0xFF3B2B18));
    const silkTones = [Color(0xFFE8D5B5), Color(0xFF735634), Color(0xFFD8C09A), Color(0xFF6E5233)];
    for (int ringIndex = 0; ringIndex < 4; ringIndex++) {
      final ringScale = 0.85 - ringIndex * 0.18;
      canvas.drawOval(
        Rect.fromCenter(
          center: spiral.center,
          width: spiral.width * ringScale,
          height: spiral.height * ringScale,
        ),
        Paint()..color = silkTones[ringIndex],
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: spiral.center, width: spiral.width * 0.15, height: spiral.height * 0.15),
      Paint()..color = const Color(0xFF4A5559),
    );
  }

  @override
  bool shouldRepaint(ClosedBrocadeScrollPainter oldDelegate) => false;
}
