import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';
import 'package:memodiary/features/templates/widgets/stationery_canvas_framing.dart';
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
      final legacyTokens = StationeryVisualTokens.fromBackgroundValue('#FFFFFF');
      expect(legacyTokens.substrate, PaperSubstrate.xuan);
      expect(legacyTokens.customBgColor, const Color(0xFFFFFFFF));

      final darkTokens = StationeryVisualTokens.fromBackgroundValue('#1E2022');
      expect(darkTokens.substrate, PaperSubstrate.obsidian);
      expect(darkTokens.ruleTint, RuleInkTint.slate);

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
      const canvasSize = Size(400, 800);

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

        expect(() => painter.paint(canvas, canvasSize), returnsNormally);
        final picture = recorder.endRecording();
        picture.dispose();
      }
    });

    test('shouldRepaint correctly detects property changes', () {
      const styleFirst = TemplateStyle(
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

      final painterBase = TemplateCanvasPainter(style: styleFirst);
      final painterSame = TemplateCanvasPainter(style: styleSame);
      final painterDiffType = TemplateCanvasPainter(style: styleDifferentType);
      final painterDiffSpacing = TemplateCanvasPainter(style: styleDifferentSpacing);

      expect(painterSame.shouldRepaint(painterBase), isFalse);
      expect(painterDiffType.shouldRepaint(painterBase), isTrue);
      expect(painterDiffSpacing.shouldRepaint(painterBase), isTrue);
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
      final picture = recorder.endRecording();
      picture.dispose();

      expect(scrolledPainter.shouldRepaint(basePainter), isTrue);
      expect(headerChangedPainter.shouldRepaint(basePainter), isTrue);
      expect(typographyChangedPainter.shouldRepaint(basePainter), isTrue);
    });

    test('enforces Heaven and Earth Margins and zero line bleed to screen edges', () {
      const canvasSize = Size(360, 640);
      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
      );

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: canvasSize,
        style: style,
      );

      expect(metrics.heavenMarginPx, greaterThanOrEqualTo(52.0));
      expect(metrics.earthMarginPx, greaterThanOrEqualTo(44.0));
      expect(metrics.heavenMarginPx, greaterThanOrEqualTo(metrics.earthMarginPx));

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, canvasSize);

      // Verify ZERO ruling lines bleed to screen edge X = 0 or X = 360
      for (final line in recordingCanvas.drawnLines) {
        final (startPoint, endPoint, _) = line;
        expect(
          startPoint.dx,
          greaterThanOrEqualTo(metrics.innerFrameRect.left),
          reason: 'Line must not bleed left of innerFrameRect',
        );
        expect(
          endPoint.dx,
          lessThanOrEqualTo(metrics.innerFrameRect.right),
          reason: 'Line must not bleed right of innerFrameRect',
        );
      }
    });

    test('paints Double Outer Border with 2.0px outer stroke and 0.9px inner stroke', () {
      const canvasSize = Size(360, 640);
      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
      );

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: canvasSize,
        style: style,
      );

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, canvasSize);

      // Expect background rect + outer border rect + inner border rect
      final borderRects = recordingCanvas.drawnRects.where((rectEntry) {
        final (rect, paint) = rectEntry;
        return paint.style == PaintingStyle.stroke;
      }).toList();

      expect(borderRects.length, equals(2));

      final outerBorder = borderRects.firstWhere(
        (entry) => (entry.$2.strokeWidth - 2.0).abs() < 0.01,
      );
      final innerBorder = borderRects.firstWhere(
        (entry) => (entry.$2.strokeWidth - 0.9).abs() < 0.01,
      );

      final expectedOuterRect = metrics.innerFrameRect.inflate(4.0);
      expect(outerBorder.$1, equals(expectedOuterRect));
      expect(innerBorder.$1, equals(metrics.innerFrameRect));
    });

    test('renders central folding column and Fishtail Mark when columnCount >= 7', () {
      const canvasSize = Size(360, 640);
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
      );

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: canvasSize,
        style: style,
      );
      expect(metrics.columnCount, greaterThanOrEqualTo(7));

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, canvasSize);

      // 1. Must draw Fishtail Mark path
      expect(recordingCanvas.drawnPaths, isNotEmpty);
      final fishtailPath = recordingCanvas.drawnPaths.first;
      expect(fishtailPath.$2.style, equals(PaintingStyle.fill));

      // 2. Central folding column must be unruled horizontally
      final midCol = metrics.columnCount ~/ 2;
      final midColLeft = metrics.innerFrameRect.left + midCol * metrics.cellAdvancePx;
      final midColRight = midColLeft + metrics.cellAdvancePx;

      for (final line in recordingCanvas.drawnLines) {
        final (startPoint, endPoint, _) = line;
        if (startPoint.dy == endPoint.dy) {
          // Horizontal line must not cross through central column (midColLeft to midColRight)
          final crossesCenter = startPoint.dx < midColRight && endPoint.dx > midColLeft;
          expect(crossesCenter, isFalse, reason: 'Horizontal rules must not cross central folding column');
        }
      }
    });

    test('omits central folding column and Fishtail Mark when columnCount < 7', () {
      // Narrow width causing columnCount < 7
      const narrowCanvasSize = Size(180, 640);
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: narrowCanvasSize,
        style: style,
      );
      expect(metrics.columnCount, lessThan(7));

      final painter = TemplateCanvasPainter(style: style);
      final recordingCanvas = RecordingCanvas();
      painter.paint(recordingCanvas, narrowCanvasSize);

      // Fishtail Mark must NOT be drawn
      expect(recordingCanvas.drawnPaths, isEmpty);

      // Horizontal lines must span full innerFrameRect width without central gap
      final horizontalLines = recordingCanvas.drawnLines.where((line) {
        return line.$1.dy == line.$2.dy;
      }).toList();

      expect(horizontalLines, isNotEmpty);
      for (final line in horizontalLines) {
        expect(line.$1.dx, equals(metrics.innerFrameRect.left));
        expect(line.$2.dx, equals(metrics.innerFrameRect.right));
      }
    });

    test('adapts Double Outer Border and Fishtail colors for low-glare contrast on Obsidian substrate', () {
      final obsidianStyle = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: PaperSubstrate.obsidian.defaultColor,
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
        tokens: const StationeryVisualTokens(
          substrate: PaperSubstrate.obsidian,
          ruleTint: RuleInkTint.slate,
        ),
      );

      final outerColor = StationeryCanvasFraming.resolveBorderColor(
        style: obsidianStyle,
        isOuter: true,
      );
      final innerColor = StationeryCanvasFraming.resolveBorderColor(
        style: obsidianStyle,
        isOuter: false,
      );
      final fishtailColor = StationeryCanvasFraming.resolveFishtailColor(
        style: obsidianStyle,
        isDark: true,
      );

      // Low glare: muted translucency on dark background
      expect(outerColor, equals(const Color(0x3DFFFFFF)));
      expect(innerColor, equals(const Color(0x26FFFFFF)));
      expect(fishtailColor, equals(const Color(0x4AFFFFFF)));
    });

    test('paints Cold Gold flecks and Xuan paper fibers without throwing', () {
      const substrates = [PaperSubstrate.coldGold, PaperSubstrate.xuan, PaperSubstrate.obsidian];
      for (final substrate in substrates) {
        final style = TemplateStyle(
          type: TemplateBackgroundType.lined,
          backgroundColor: substrate.defaultColor,
          lineSpacing: 1.5,
          marginHorizontal: 24.0,
          tokens: StationeryVisualTokens(
            substrate: substrate,
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
      const width = 375.0;
      const rowHeight = 24.0;
      const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: margin,
      );

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(width, 640),
        style: style,
        typography: typography,
      );

      expect(metrics.columnCount, equals(13));
      expect(metrics.innerFrameRect.width, equals(13 * rowHeight));
      expect(metrics.innerFrameRect.left, equals(32.0));
      expect(metrics.innerFrameRect.right, equals(344.0));
    });
  });
}
