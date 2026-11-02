import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/screens/custom_template_editor_screen.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_painter.dart';
import '../../helpers/recording_canvas.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Template Preview Cards in Scholar Chest / Carousel (Issue 1)', () {
    test('Lined Paper card (86x116) renders multiple horizontal lines, not 0 lines', () {
      final style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: const Color(0xFFFDFBF7),
        lineSpacing: 1.8,
        marginHorizontal: 24.0,
      );

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(86, 116));

      // Count horizontal lines across the card (y1 == y2)
      final horizontalLines = recordingCanvas.drawnLines.where((entry) {
        final p1 = entry.$1;
        final p2 = entry.$2;
        return (p1.dy - p2.dy).abs() < 0.001 && (p1.dx - p2.dx).abs() > 20;
      }).toList();

      // In a 116px tall thumbnail card, there should be at least 4 horizontal ruled lines
      expect(horizontalLines.length, greaterThanOrEqualTo(4),
          reason: 'Lined paper thumbnail must render visible ruled lines across the card');
    });

    test('Solid Color card (86x116) does not draw a miniature double outer border', () {
      final style = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: const Color(0xFFFFFFFF),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(86, 116));

      final rectDraws = recordingCanvas.drawnRects.where((entry) {
        final paint = entry.$2;
        return paint.style == PaintingStyle.stroke;
      }).toList();

      expect(rectDraws, isEmpty,
          reason: 'Solid color card thumbnail should NOT draw a miniature double outer border');
    });

    test('Grid Paper card (86x116) renders a visible grid, not empty miniature frame', () {
      final style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: const Color(0xFFF4F5F7),
        lineSpacing: 1.5,
        marginHorizontal: 16.0,
      );

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(86, 116));

      final horizontalLines = recordingCanvas.drawnLines.where((entry) {
        final p1 = entry.$1;
        final p2 = entry.$2;
        return (p1.dy - p2.dy).abs() < 0.001 && (p1.dx - p2.dx).abs() > 20;
      }).toList();

      expect(horizontalLines.length, greaterThanOrEqualTo(4),
          reason: 'Grid paper thumbnail must render visible grid lines across the card');
    });
  });

  group('CustomTemplateEditorScreen Live Preview Text (Issue 2)', () {
    testWidgets('Live preview text contrast does not use white text on light paper in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [InkDiaryTokens.dark],
          ),
          home: CustomTemplateEditorScreen(database: db),
        ),
      );
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('秋山晚眺 · 随笔起兴'));
      final textColor = titleWidget.style?.color;

      // In dark theme, tokens.jiaomo is 0xFFF0ECE3 (nearly white).
      // On light paper (#FBF8F1), text MUST be dark ink (luminance < 0.3), NOT nearly white.
      expect(textColor, isNotNull);
      expect(textColor!.computeLuminance(), lessThan(0.3),
          reason: 'Text on light paper must be dark ink for readable contrast');
    });
  });
}
