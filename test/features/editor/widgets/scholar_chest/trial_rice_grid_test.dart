import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/models/stationery_sheet_configs.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/trial_rice_grid.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/trial_rice_grid_painter.dart';

void main() {
  group('TrialRiceGrid.centerStrokesInBox', () {
    test('shifts off-center stroke bounding box center to (50, 50) in 0..100 space', () {
      // Mirrors 永's bbox [11..93, 7..86] whose center is (52.0, 46.5).
      const rawStrokes = [
        [Offset(11, 7), Offset(93, 86)],
        [Offset(52, 20), Offset(52, 70)],
      ];

      final centered = TrialRiceGrid.centerStrokesInBox(rawStrokes);

      var minX = 100.0;
      var maxX = 0.0;
      var minY = 100.0;
      var maxY = 0.0;
      for (final stroke in centered) {
        for (final point in stroke) {
          if (point.dx < minX) minX = point.dx;
          if (point.dx > maxX) maxX = point.dx;
          if (point.dy < minY) minY = point.dy;
          if (point.dy > maxY) maxY = point.dy;
        }
      }
      expect((minX + maxX) / 2, closeTo(50.0, 0.01));
      expect((minY + maxY) / 2, closeTo(50.0, 0.01));
      expect(centered[0][0], const Offset(9.0, 10.5));
      expect(centered[0][1], const Offset(91.0, 89.5));
    });

    test('clamps shifted coordinates inside 0..100 bounds and handles empty strokes', () {
      expect(TrialRiceGrid.centerStrokesInBox(const []), isEmpty);

      const edgeStrokes = [
        [Offset(0, 0), Offset(20, 10)],
      ];
      final centered = TrialRiceGrid.centerStrokesInBox(edgeStrokes);
      for (final stroke in centered) {
        for (final point in stroke) {
          expect(point.dx, inInclusiveRange(0.0, 100.0));
          expect(point.dy, inInclusiveRange(0.0, 100.0));
        }
      }
    });
  });

  group('TrialRiceGridPainter.resolveGlyphOrigin', () {
    const glyphBox = Rect.fromLTWH(4, 4, 52, 52);
    const fontSize = 52 * 0.82;

    test('optically centers CJK visual ink box on glyphBox.center despite asymmetric descent', () {
      // Simulated Noto Sans CJK metrics: ascent ~0.88*em, descent ~0.28*em -> height = 1.16*em.
      final alphabeticBaseline = fontSize * 0.88;
      final glyphHeight = fontSize * 1.16;

      final origin = TrialRiceGridPainter.resolveGlyphOrigin(
        glyphBox: glyphBox,
        glyphWidth: fontSize,
        glyphHeight: glyphHeight,
        alphabeticBaseline: alphabeticBaseline,
        fontSize: fontSize,
        isCjk: true,
      );

      // Visual CJK ink center sits at (alphabeticBaseline - 0.38 * fontSize) below origin.dy.
      final visualCenterY = origin.dy + alphabeticBaseline - fontSize * 0.38;
      expect(origin.dx, closeTo(glyphBox.center.dx - fontSize / 2, 0.01));
      expect(visualCenterY, closeTo(glyphBox.center.dy, 0.01));
    });

    test('optically centers Latin cap height on glyphBox.center when isCjk is false', () {
      final alphabeticBaseline = fontSize * 0.85;
      final glyphHeight = fontSize * 1.12;

      final origin = TrialRiceGridPainter.resolveGlyphOrigin(
        glyphBox: glyphBox,
        glyphWidth: fontSize * 0.65,
        glyphHeight: glyphHeight,
        alphabeticBaseline: alphabeticBaseline,
        fontSize: fontSize,
        isCjk: false,
      );

      final visualCenterY = origin.dy + alphabeticBaseline - fontSize * 0.36;
      expect(origin.dx, closeTo(glyphBox.center.dx - (fontSize * 0.65) / 2, 0.01));
      expect(visualCenterY, closeTo(glyphBox.center.dy, 0.01));
    });

    test('falls back to bounding-box centering when alphabeticBaseline is non-positive', () {
      final origin = TrialRiceGridPainter.resolveGlyphOrigin(
        glyphBox: glyphBox,
        glyphWidth: 40,
        glyphHeight: 44,
        alphabeticBaseline: 0,
        fontSize: fontSize,
        isCjk: true,
      );

      expect(origin, equals(glyphBox.center - const Offset(20, 22)));
    });
  });

  group('TrialRiceGrid widget behavior', () {
    testWidgets('animates 永 and settles cleanly without exceptions', (tester) async {
      final audio = AudioSanctumService(enablePlatformAudio: false);
      addTearDown(audio.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrialRiceGrid(
              config: const InkChoreographyConfig(),
              replayToken: 0,
              ink: TrialInkStyle.fallback,
              audioSanctumService: audio,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('chest_trial_grid_caption')), findsOneWidget);
      expect(find.text('「永」书写中'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('「永」已完成'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
