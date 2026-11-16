import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/bamboo_brush_painter.dart';
import 'package:memodiary/features/editor/ink_choreography/bamboo_brush_picture.dart';
import 'package:memodiary/features/editor/ink_choreography/brush_kinematics.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_timeline.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_glyph_frame.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_stroke_path.dart';
import 'package:memodiary/features/editor/ink_choreography/silk_trace_painter.dart';
import 'package:memodiary/features/editor/ink_choreography/wet_ink_painter.dart';

const _ink = Color(0xFF1E1D1B);
const _canvasSize = Size(200, 200);

/// The straight-alpha pixels a painter leaves on a transparent canvas.
class _Rendering {
  final ByteData _rgba;
  final int _width;

  _Rendering(this._rgba, this._width);

  /// Opacity (0..1) of the pixel at [point].
  double alphaAt(Offset point) => _rgba.getUint8((point.dy.round() * _width + point.dx.round()) * 4 + 3) / 255.0;

  bool get isBlank {
    for (var offset = 3; offset < _rgba.lengthInBytes; offset += 4) {
      if (_rgba.getUint8(offset) != 0) return false;
    }
    return true;
  }
}

Future<_Rendering> _render(CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _canvasSize);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(_canvasSize.width.toInt(), _canvasSize.height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  picture.dispose();
  image.dispose();
  return _Rendering(bytes!, _canvasSize.width.toInt());
}

/// 十 in a 100dp box at (50, 50): a horizontal, then a vertical.
final InkGlyphTimeline _cross = InkGlyphTimeline(
  plan: InkGlyphPlan.prepare(
    strokes: const [
      [Offset(10, 50), Offset(90, 50)],
      [Offset(50, 10), Offset(50, 90)],
    ],
    box: const Rect.fromLTWH(50, 50, 100, 100),
    isCjk: true,
  ),
  strokeDuration: const Duration(milliseconds: 200),
);

WetInkPainter _wetInkAt(int millis) => WetInkPainter(
      glyphs: [WetInkGlyph(frame: _cross.frameAt(Duration(milliseconds: millis)))],
      inkColor: _ink,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WetInkPainter', () {
    test('inks the active stroke up to the tip and no further', () async {
      // Half-way through the horizontal: the tip is 48% of the way from x=60 to x=140.
      final rendering = await _render(_wetInkAt(100));

      expect(rendering.alphaAt(const Offset(75, 100)), greaterThan(0.9), reason: 'core behind the tip');
      expect(rendering.alphaAt(const Offset(98, 100)), greaterThan(0.9), reason: 'ink pooled under the tip');
      expect(rendering.alphaAt(const Offset(125, 100)), 0.0, reason: 'paper ahead of the tip');
      expect(rendering.alphaAt(const Offset(100, 70)), 0.0, reason: 'the vertical has not started');
    });

    test('surrounds the saturated core with a wide translucent halo', () async {
      final rendering = await _render(_wetInkAt(100));

      // Core is 9.2 units wide, the live halo 15: 6 units off-axis is halo only.
      final halo = rendering.alphaAt(const Offset(75, 106));
      expect(halo, inExclusiveRange(0.15, 0.7));
      expect(rendering.alphaAt(const Offset(75, 112)), 0.0);
    });

    test('keeps earlier strokes down while a later stroke is written', () async {
      final rendering = await _render(_wetInkAt(300));

      expect(rendering.alphaAt(const Offset(130, 100)), greaterThan(0.9), reason: 'the finished horizontal');
      expect(rendering.alphaAt(const Offset(100, 70)), greaterThan(0.9), reason: 'the vertical so far');
      expect(rendering.alphaAt(const Offset(100, 135)), 0.0, reason: 'the vertical still to come');
    });

    test('fades the wet ink away through the settle and leaves nothing once settled', () async {
      const probe = Offset(130, 100);
      final written = (await _render(_wetInkAt(400))).alphaAt(probe);
      final settling = (await _render(_wetInkAt(560))).alphaAt(probe);
      final nearlyDone = (await _render(_wetInkAt(640))).alphaAt(probe);

      expect(written, greaterThan(0.9));
      expect(settling, lessThan(written));
      expect(nearlyDone, lessThan(settling));
      expect((await _render(_wetInkAt(660))).isBlank, isTrue);
    });

    test('a faster-moving tip, with stretched bristles, pools more ink', () async {
      WetInkPainter poolFor(double stretch) => WetInkPainter(
            glyphs: [WetInkGlyph(frame: _cross.frameAt(const Duration(milliseconds: 100)), bristleStretch: stretch)],
            inkColor: _ink,
          );
      // A pixel centred 5.2 units from the tip (98.6, 100): outside the relaxed
      // pool (radius 3.8), inside the stretched one (3.8 + 2.4).
      const probe = Offset(102, 103);

      final relaxed = (await _render(poolFor(0.0))).alphaAt(probe);
      final stretched = (await _render(poolFor(40.0))).alphaAt(probe);

      expect(stretched, greaterThan(relaxed + 0.2));
    });

    test('repaints for a new frame list or ink colour only', () {
      final glyphs = [WetInkGlyph(frame: _cross.frameAt(Duration.zero))];
      final painter = WetInkPainter(glyphs: glyphs, inkColor: _ink);

      expect(WetInkPainter(glyphs: glyphs, inkColor: _ink).shouldRepaint(painter), isFalse);
      expect(WetInkPainter(glyphs: [...glyphs], inkColor: _ink).shouldRepaint(painter), isTrue);
      expect(WetInkPainter(glyphs: glyphs, inkColor: const Color(0xFFA82E26)).shouldRepaint(painter), isTrue);
    });
  });

  group('BambooBrushPainter', () {
    final pose = BrushPose.resolve(
      handle: const Offset(104, 135),
      tip: const Offset(100, 150),
      isPressing: true,
      brushScale: 1.0,
    );

    test('stands a bamboo shaft over bristles that end on the ink tip', () async {
      final rendering = await _render(BambooBrushPainter(poses: [pose], inkColor: _ink));

      expect(rendering.alphaAt(const Offset(100.5, 147)), greaterThan(0.9), reason: 'inked bristle tip');
      // 60 units up the shaft, leaning 24 degrees clockwise from the handle.
      expect(rendering.alphaAt(const Offset(128, 80)), 1.0, reason: 'bamboo shaft');
      expect(rendering.alphaAt(const Offset(40, 40)), 0.0, reason: 'empty paper away from the brush');
    });

    test('draws nothing without a brush', () async {
      final rendering = await _render(const BambooBrushPainter(poses: [], inkColor: _ink));

      expect(rendering.isBlank, isTrue);
    });

    test('replays one recording of the rigid shaft for every brush and frame', () async {
      final before = BambooBrushPicture.picture;
      await _render(BambooBrushPainter(poses: [pose, pose], inkColor: _ink));
      await _render(BambooBrushPainter(poses: [pose], inkColor: const Color(0xFFA82E26)));

      expect(identical(BambooBrushPicture.picture, before), isTrue);
    });

    test('repaints for new poses, trace or ink colour only', () {
      final poses = [pose];
      final painter = BambooBrushPainter(poses: poses, inkColor: _ink);

      expect(BambooBrushPainter(poses: poses, inkColor: _ink).shouldRepaint(painter), isFalse);
      expect(BambooBrushPainter(poses: [pose], inkColor: _ink).shouldRepaint(painter), isTrue);
      expect(
        BambooBrushPainter(
          poses: poses,
          inkColor: _ink,
          silkTrace: InkTransit(from: Offset.zero, to: const Offset(50, 0)),
        ).shouldRepaint(painter),
        isTrue,
      );
    });
  });

  group('SilkTracePainter', () {
    test('dashes a faint filament along the lifted arc between two characters', () async {
      final transit = InkTransit(from: const Offset(40, 120), to: const Offset(160, 120));
      final rendering = await _render(SilkTracePainter(transit: transit, inkColor: _ink));

      // Dashes are 2 on, 3 off: sample the arc finely and expect both ink and gaps.
      var inked = 0;
      var gaps = 0;
      for (var step = 5; step < 395; step++) {
        final t = step / 400;
        final inverse = 1 - t;
        final onArc = transit.from * (inverse * inverse) + transit.control * (2 * inverse * t) + transit.to * (t * t);
        final alpha = rendering.alphaAt(onArc);
        expect(alpha, lessThan(0.3), reason: 'the trace is faint');
        alpha > 0.05 ? inked++ : gaps++;
      }
      expect(inked, greaterThan(60));
      expect(gaps, greaterThan(60));
      expect(rendering.alphaAt(const Offset(100, 120)), 0.0, reason: 'the filament arcs above the straight line');
    });

    test('is not drawn for a hop under 6dp or a leap over 180dp', () async {
      final hop = InkTransit(from: const Offset(40, 120), to: const Offset(44, 120));
      final leap = InkTransit(from: const Offset(5, 120), to: const Offset(195, 120));

      expect((await _render(SilkTracePainter(transit: hop, inkColor: _ink))).isBlank, isTrue);
      expect((await _render(SilkTracePainter(transit: leap, inkColor: _ink))).isBlank, isTrue);
    });

    test('the brush layer draws the trace it is given', () async {
      final transit = InkTransit(from: const Offset(40, 120), to: const Offset(160, 120));
      final rendering = await _render(BambooBrushPainter(poses: const [], inkColor: _ink, silkTrace: transit));

      expect(rendering.isBlank, isFalse);
    });
  });
}
