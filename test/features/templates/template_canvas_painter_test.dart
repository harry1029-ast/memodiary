import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_painter.dart';
import '../../helpers/recording_canvas.dart';

void main() {
  group('TemplateStyle & Hex Parsing Tests', () {
    test('parses 6-char and 8-char hex colors correctly', () {
      expect(TemplateStyle.parseHexColor('#FFFFFF'), const Color(0xFFFFFFFF));
      expect(TemplateStyle.parseHexColor('#EFE6D5'), const Color(0xFFEFE6D5));
      expect(TemplateStyle.parseHexColor('FDFBF7'), const Color(0xFFFDFBF7));
      expect(TemplateStyle.parseHexColor('invalid', fallback: Colors.red), Colors.red);
    });

    test('parses background types', () {
      expect(TemplateBackgroundType.fromString('color'), TemplateBackgroundType.color);
      expect(TemplateBackgroundType.fromString('lined'), TemplateBackgroundType.lined);
      expect(TemplateBackgroundType.fromString('grid'), TemplateBackgroundType.grid);
      expect(TemplateBackgroundType.fromString('dot_grid'), TemplateBackgroundType.dotGrid);
      expect(TemplateBackgroundType.fromString('dotgrid'), TemplateBackgroundType.dotGrid);
      expect(TemplateBackgroundType.fromString('paper_texture'), TemplateBackgroundType.paperTexture);
      expect(TemplateBackgroundType.fromString('unknown'), TemplateBackgroundType.color);
      expect(TemplateBackgroundType.dotGrid.toDbValue, 'dot_grid');
      expect(TemplateBackgroundType.dotGrid.label, 'Dot Grid');
    });
  });

  group('TemplateCanvasPainter Rendering Tests', () {
    test('paints all 4 template background types on canvas without throwing', () {
      const size = Size(400, 800);

      for (final type in TemplateBackgroundType.values) {
        final style = TemplateStyle(
          type: type,
          backgroundColor: const Color(0xFFFFFFFF),
          lineSpacing: 1.5,
          marginHorizontal: 20.0,
        );

        final painter = TemplateCanvasPainter(style: style);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => painter.paint(canvas, size), returnsNormally);
        final picture = recorder.endRecording();
        picture.dispose();
      }
    });

    test('shouldRepaint correctly detects property changes', () {
      const style1 = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      const styleSame = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      const styleDifferentType = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      const styleDifferentSpacing = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: Colors.white,
        lineSpacing: 1.8,
        marginHorizontal: 20.0,
      );

      final p1 = TemplateCanvasPainter(style: style1);
      final pSame = TemplateCanvasPainter(style: styleSame);
      final pDiffType = TemplateCanvasPainter(style: styleDifferentType);
      final pDiffSpacing = TemplateCanvasPainter(style: styleDifferentSpacing);

      expect(pSame.shouldRepaint(p1), isFalse);
      expect(pDiffType.shouldRepaint(p1), isTrue);
      expect(pDiffSpacing.shouldRepaint(p1), isTrue);
    });

    test('accepts typography, scrollOffset, headerHeight and triggers shouldRepaint on change', () {
      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      final basePainter = TemplateCanvasPainter(
        style: style,
        scrollOffset: 0.0,
        headerHeight: 90.0,
      );
      final scrolledPainter = TemplateCanvasPainter(
        style: style,
        scrollOffset: 50.0,
        headerHeight: 90.0,
      );
      final headerChangedPainter = TemplateCanvasPainter(
        style: style,
        scrollOffset: 0.0,
        headerHeight: 120.0,
      );
      final typographyChangedPainter = TemplateCanvasPainter(
        style: style,
        typography: const TypographySettings(fontSize: 18.0),
        scrollOffset: 0.0,
        headerHeight: 90.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => scrolledPainter.paint(canvas, const Size(400, 800)), returnsNormally);
      final pic = recorder.endRecording();
      pic.dispose();

      expect(scrolledPainter.shouldRepaint(basePainter), isTrue);
      expect(headerChangedPainter.shouldRepaint(basePainter), isTrue);
      expect(typographyChangedPainter.shouldRepaint(basePainter), isTrue);
    });

    test('paints grid paper with vertical lines anchored to marginX and uniform square cells', () {
      const margin = 24.0;
      const headerHeight = 90.0;
      const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);
      const rowHeight = 24.0; // 16.0 * 1.5

      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: margin,
      );

      final painter = TemplateCanvasPainter(
        style: style,
        typography: typography,
        headerHeight: headerHeight,
      );

      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(360, 640));

      // 1. Must NOT paint a duplicate header divider at y = headerHeight
      final hasDuplicateDivider = recordingCanvas.drawnLines.any((line) {
        final (p1, p2, _) = line;
        return p1.dy == headerHeight && p2.dy == headerHeight && p1.dx == 0 && p2.dx == 360;
      });
      expect(hasDuplicateDivider, isFalse, reason: 'Duplicate header divider should be removed');

      // 2. Must paint a vertical grid line passing through x = margin
      final verticalLines = recordingCanvas.drawnLines.where((line) {
        final (p1, p2, _) = line;
        return p1.dx == p2.dx;
      }).toList();

      final hasLineAtMarginX = verticalLines.any((line) => (line.$1.dx - margin).abs() < 0.01);
      expect(hasLineAtMarginX, isTrue, reason: 'Vertical grid line must align with text left margin');

      // 3. Horizontal grid lines must form uniform rowHeight cells starting from headerHeight
      final horizontalLines = recordingCanvas.drawnLines.where((line) {
        final (p1, p2, _) = line;
        return p1.dy == p2.dy;
      }).toList();

      final firstExpectedY = headerHeight + rowHeight; // 114.0
      final hasFirstGridRow = horizontalLines.any((line) => (line.$1.dy - firstExpectedY).abs() < 0.01);
      expect(hasFirstGridRow, isTrue, reason: 'Horizontal grid rule must be at headerHeight + rowHeight');
    });

    test('paints dot grid paper with dots anchored to marginX and uniform square intervals', () {
      const margin = 24.0;
      const headerHeight = 90.0;
      const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

      const style = TemplateStyle(
        type: TemplateBackgroundType.dotGrid,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: margin,
      );

      final painter = TemplateCanvasPainter(
        style: style,
        typography: typography,
        headerHeight: headerHeight,
      );

      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(360, 640));

      // Must NOT paint duplicate header divider
      final hasDuplicateDivider = recordingCanvas.drawnLines.any((line) {
        final (p1, p2, _) = line;
        return p1.dy == headerHeight && p2.dy == headerHeight;
      });
      expect(hasDuplicateDivider, isFalse);

      // Must have dots where x = margin
      final hasDotAtMargin = recordingCanvas.drawnCircles.any((circle) {
        final (center, _, _) = circle;
        return (center.dx - margin).abs() < 0.01;
      });
      expect(hasDotAtMargin, isTrue, reason: 'Dot grid must align with marginX');
    });

    test('paints lined paper without duplicate header divider', () {
      const margin = 24.0;
      const headerHeight = 90.0;
      const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: margin,
      );

      final painter = TemplateCanvasPainter(
        style: style,
        typography: typography,
        headerHeight: headerHeight,
      );

      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(360, 640));

      final hasDuplicateDivider = recordingCanvas.drawnLines.any((line) {
        final (p1, p2, _) = line;
        return p1.dy == headerHeight && p2.dy == headerHeight && p1.dx == 0 && p2.dx == 360;
      });
      expect(hasDuplicateDivider, isFalse);
    });
  });
}
