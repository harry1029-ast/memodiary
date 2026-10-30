import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_painter.dart';

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
  });
}
