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

    test('StationeryVisualTokens parses legacy hex and structured JSON round-trip', () {
      // Legacy hex
      final legacyTokens = StationeryVisualTokens.fromBackgroundValue('#FFFFFF');
      expect(legacyTokens.substrate, PaperSubstrate.xuan);
      expect(legacyTokens.customBgColor, const Color(0xFFFFFFFF));

      final darkTokens = StationeryVisualTokens.fromBackgroundValue('#1E2022');
      expect(darkTokens.substrate, PaperSubstrate.obsidian);
      expect(darkTokens.ruleTint, RuleInkTint.slate);

      // JSON tokens
      const original = StationeryVisualTokens(
        substrate: PaperSubstrate.coldGold,
        ruleTint: RuleInkTint.charcoal,
        sealStyle: SealCarvingStyle.baiwen,
      );
      final encoded = original.toBackgroundValue();
      final decoded = StationeryVisualTokens.fromBackgroundValue(encoded);
      expect(decoded.substrate, PaperSubstrate.coldGold);
      expect(decoded.ruleTint, RuleInkTint.charcoal);
      expect(decoded.sealStyle, SealCarvingStyle.baiwen);
      expect(decoded.customBgColor, isNull);
    });

    test('StationerySuites exposes curated presets with 4 distinct styles', () {
      expect(StationerySuites.all.length, 4);
      expect(StationerySuites.wenfang.substrate, PaperSubstrate.xuan);
      expect(StationerySuites.lengjin.substrate, PaperSubstrate.coldGold);
      expect(StationerySuites.zhuqing.substrate, PaperSubstrate.minimal);
      expect(StationerySuites.songyan.substrate, PaperSubstrate.obsidian);
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

    test('paints Cold Gold flecks and Xuan paper fibers without throwing', () {
      const substrates = [PaperSubstrate.coldGold, PaperSubstrate.xuan, PaperSubstrate.obsidian];
      for (final sub in substrates) {
        final style = TemplateStyle(
          type: TemplateBackgroundType.lined,
          backgroundColor: sub.defaultColor,
          lineSpacing: 1.5,
          marginHorizontal: 24.0,
          tokens: StationeryVisualTokens(
            substrate: sub,
            ruleTint: RuleInkTint.charcoal,
          ),
        );
        final painter = TemplateCanvasPainter(style: style);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        expect(() => painter.paint(canvas, const Size(360, 640)), returnsNormally);
        recorder.endRecording().dispose();
      }
    });

    test('snapped grid centers symmetrically when available width is not exact multiple of rowHeight', () {
      const margin = 20.0;
      const width = 375.0; // availWidth = 335. 335 / 24 = 13.95 -> 13 cols = 312px. Remainder = 23px.
      const rowHeight = 24.0;
      const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);
      expect(typography.fontSize * typography.lineSpacing, equals(rowHeight));

      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: margin,
      );

      final painter = TemplateCanvasPainter(
        style: style,
        typography: typography,
      );

      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, const Size(width, 640));

      // Symmetrically centered: inset = 20 + 23/2 = 31.5. xStart = 31.5, xEnd = 343.5.
      final verticalLines = recordingCanvas.drawnLines.where((line) => line.$1.dx == line.$2.dx).toList();
      expect(verticalLines, isNotEmpty);
      final firstX = verticalLines.map((line) => line.$1.dx).reduce((a, b) => a < b ? a : b);
      final lastX = verticalLines.map((line) => line.$1.dx).reduce((a, b) => a > b ? a : b);

      expect((firstX - 31.5).abs() < 0.01, isTrue, reason: 'First vertical line snapped symmetrically');
      expect((lastX - 343.5).abs() < 0.01, isTrue, reason: 'Last vertical line snapped symmetrically');
      expect((lastX - firstX - 312.0).abs() < 0.01, isTrue, reason: 'Total grid span is exactly 13 * 24px');
    });
  });
}
