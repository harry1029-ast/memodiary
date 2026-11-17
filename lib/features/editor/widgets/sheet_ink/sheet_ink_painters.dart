import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../templates/widgets/template_canvas_painter.dart';
import '../../ink_choreography/bamboo_brush_painter.dart';
import '../../ink_choreography/sheet_ink_choreographer.dart';
import '../../ink_choreography/silk_trace_painter.dart';
import '../../ink_choreography/wet_ink_painter.dart';

/// The sheet's own paper (substrate, texture and rulings), recorded once so
/// the mask can repaint it over characters every frame. Re-recorded only
/// when the paper or its size changes.
class SheetPaperPicture {
  TemplateCanvasPainter? _paper;
  Size? _size;
  ui.Picture? _picture;

  ui.Picture of(TemplateCanvasPainter paper, Size size) {
    final recordedPaper = _paper;
    final recorded = _picture;
    if (recorded != null && recordedPaper != null && _size == size && !paper.shouldRepaint(recordedPaper)) {
      return recorded;
    }
    recorded?.dispose();
    final recorder = ui.PictureRecorder();
    paper.paint(Canvas(recorder), size);
    _paper = paper;
    _size = size;
    return _picture = recorder.endRecording();
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
  }
}

/// The mask-and-ink layer of a Stationery Sheet's Ink Choreography overlay,
/// painted inside the sheet card above the editor.
///
/// Queued and writing characters are hidden by repainting the sheet's own
/// [paper] over their rects (never a flat fill, which would erase rulings
/// and texture); a settling character's mask fades with its wet ink so the
/// editor's printed glyph shows through. Queued characters carry a faint
/// cinnabar guide dot, written ones a guide box and their wet ink.
///
/// Locates the glyphs as it paints, when the editor's layout is the one
/// being shown.
class SheetInkMaskPainter extends CustomPainter {
  final SheetInkChoreographer ink;

  /// The card's own paper painter, with the card's arguments.
  final TemplateCanvasPainter paper;
  final SheetPaperPicture paperPicture;
  final Color inkColor;

  SheetInkMaskPainter({
    required this.ink,
    required this.paper,
    required this.paperPicture,
    required this.inkColor,
  }) : super(repaint: ink);

  static const Color cinnabar = Color(0xFFB83B2E);
  static const double _guideDotRadius = 1.0;
  static const double _guideDotAlpha = 0.25;
  static const double _guideBoxAlpha = 0.35;
  static const double _guideFillAlpha = 0.05;
  static const double _guideBoxInset = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    ink.resolveGeometry();
    final slots = ink.slots.where((slot) => slot.geometry != null).toList(growable: false);
    if (slots.isEmpty) return;
    final paperPicture = this.paperPicture.of(paper, size);

    final covered = <Rect>[
      for (final slot in slots)
        if (slot.isQueued || slot.isWriting) slot.geometry!.maskRect,
    ];
    if (covered.isNotEmpty) {
      canvas.save();
      canvas.clipPath(unionOfRows(covered));
      canvas.drawPicture(paperPicture);
      canvas.restore();
    }

    for (final slot in slots) {
      final frame = slot.performance?.frame;
      if (frame == null || frame.isWriting || frame.wetOpacity <= 0) continue;
      final rect = slot.geometry!.maskRect;
      canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, frame.wetOpacity));
      canvas.clipRect(rect);
      canvas.drawPicture(paperPicture);
      canvas.restore();
    }

    for (final slot in slots) {
      final rect = slot.geometry!.maskRect;
      final performance = slot.performance;
      if (performance == null) {
        canvas.drawCircle(rect.center, _guideDotRadius, Paint()..color = cinnabar.withValues(alpha: _guideDotAlpha));
        continue;
      }
      final frame = performance.frame;
      final guide = RRect.fromRectAndRadius(rect.deflate(_guideBoxInset), const Radius.circular(2));
      canvas.drawRRect(guide, Paint()..color = cinnabar.withValues(alpha: _guideFillAlpha * frame.wetOpacity));
      canvas.drawRRect(
        guide,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = cinnabar.withValues(alpha: _guideBoxAlpha * frame.wetOpacity),
      );
      WetInkPainter.paintGlyph(
        canvas,
        WetInkGlyph(frame: frame, bristleStretch: performance.bristleStretch),
        inkColor: inkColor,
      );
    }
  }

  /// One path covering [rects], with neighbours on the same row joined into
  /// a single run so no seam of printed glyph shows between them.
  static Path unionOfRows(List<Rect> rects) {
    final ordered = [...rects]..sort((first, second) {
        final byRow = first.top.compareTo(second.top);
        return byRow != 0 ? byRow : first.left.compareTo(second.left);
      });
    final path = Path();
    Rect? run;
    for (final rect in ordered) {
      final current = run;
      if (current != null &&
          (rect.top - current.top).abs() < 0.01 &&
          (rect.bottom - current.bottom).abs() < 0.01 &&
          rect.left <= current.right + 0.01) {
        run = current.expandToInclude(rect);
        continue;
      }
      if (current != null) path.addRect(current);
      run = rect;
    }
    if (run != null) path.addRect(run);
    return path;
  }

  @override
  bool shouldRepaint(SheetInkMaskPainter oldDelegate) =>
      !identical(oldDelegate.ink, ink) || oldDelegate.inkColor != inkColor || paper.shouldRepaint(oldDelegate.paper);
}

/// The brush layer of the overlay: an unclipped sibling above the sheet
/// card, so a shaft standing ~100dp over its tip reaches out over the desk
/// instead of being cut off on the top rows. Draws the Airborne Silk Trace
/// and every bamboo brush, shifted from the ink layer's coordinates into
/// its own.
class SheetInkBrushPainter extends CustomPainter {
  final SheetInkChoreographer ink;
  final Color inkColor;

  /// The ink layer's origin in this layer's coordinates.
  final Offset Function() inkLayerOrigin;

  SheetInkBrushPainter({
    required this.ink,
    required this.inkColor,
    required this.inkLayerOrigin,
  }) : super(repaint: ink);

  @override
  void paint(Canvas canvas, Size size) {
    final poses = ink.brushPoses();
    final trace = ink.silkTrace;
    if (poses.isEmpty && trace == null) return;
    final origin = inkLayerOrigin();
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (trace != null) SilkTracePainter.paintTrace(canvas, trace, inkColor: inkColor);
    for (final pose in poses) {
      BambooBrushPainter.paintBrush(canvas, pose, inkColor: inkColor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SheetInkBrushPainter oldDelegate) =>
      !identical(oldDelegate.ink, ink) || oldDelegate.inkColor != inkColor;
}
