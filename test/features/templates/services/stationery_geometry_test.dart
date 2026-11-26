import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_geometry.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';

void main() {
  group('StationeryGeometry.buildFrame & buildFolioFrame', () {
    test('builds Double Outer Border and 6-vertex Fishtail Mark when grid has >= 7 columns', () {
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );
      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360, 640),
        style: style,
      );
      expect(metrics.columnCount, greaterThanOrEqualTo(7));

      final frame = StationeryGeometry.buildFrame(
        metrics: metrics,
        style: style,
        scrollOffsetY: 12.0,
      );

      expect(frame.drawDoubleBorder, isTrue);
      expect(frame.innerRect, equals(metrics.innerFrameRect.translate(0.0, -12.0)));
      expect(frame.outerRect, equals(frame.innerRect.inflate(4.0)));
      expect(frame.fishtailPolygon, hasLength(6));

      final poly = frame.fishtailPolygon!;
      expect(poly[1].dy, greaterThan(poly[0].dy));
      expect(poly[4].dy, greaterThan(poly[3].dy));
    });

    test('omits Fishtail Mark when grid has fewer than 7 columns', () {
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
      );
      final metrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 160,
        canvasHeight: 320,
        backgroundType: TemplateBackgroundType.grid,
        fontSize: 20.0,
      );
      expect(metrics.columnCount, lessThan(7));

      final frame = StationeryGeometry.buildFrame(metrics: metrics, style: style);
      expect(frame.drawDoubleBorder, isTrue);
      expect(frame.fishtailPolygon, isNull);
    });

    test('omits Double Outer Border only on minimal slate color/dotGrid templates', () {
      const minimalColor = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
        tokens: StationeryVisualTokens(
          substrate: PaperSubstrate.minimal,
          ruleTint: RuleInkTint.slate,
        ),
      );
      const xuanColor = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
        tokens: StationeryVisualTokens(
          substrate: PaperSubstrate.xuan,
          ruleTint: RuleInkTint.slate,
        ),
      );

      expect(StationeryGeometry.shouldDrawDoubleBorder(minimalColor), isFalse);
      expect(StationeryGeometry.shouldDrawDoubleBorder(xuanColor), isTrue);
    });

    test('buildFolioFrame inflates by 3px and conditionally adds 6-vertex fishtail', () {
      final withFishtail = StationeryGeometry.buildFolioFrame(
        size: const Size(320, 448),
        showFishtail: true,
      );
      expect(withFishtail.outerRect, equals(const Rect.fromLTRB(-3, -3, 323, 451)));
      expect(withFishtail.fishtailPolygon, hasLength(6));

      final withoutFishtail = StationeryGeometry.buildFolioFrame(
        size: const Size(320, 448),
        showFishtail: false,
      );
      expect(withoutFishtail.fishtailPolygon, isNull);
    });
  });

  group('StationeryGeometry.buildRulings & buildFolioRulings', () {
    test('lined rulings clip above headerHeight and include left margin rule', () {
      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );
      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360, 640),
        style: style,
      );

      final headerHeight = metrics.lineStridePx * 4;
      final rulings = StationeryGeometry.buildRulings(
        metrics: metrics,
        style: style,
        headerHeight: headerHeight,
        viewportHeight: 640,
      );

      expect(rulings.leftMarginRule, isNotNull);
      expect(rulings.leftMarginRule!.start.dy, greaterThanOrEqualTo(metrics.innerFrameRect.top + headerHeight));
      for (final line in rulings.primaryLines) {
        expect(line.start.dy, greaterThanOrEqualTo(metrics.innerFrameRect.top + headerHeight));
        expect(line.start.dy, lessThanOrEqualTo(metrics.innerFrameRect.bottom));
      }
    });

    test('manuscript grid splits horizontal rules around central Fishtail column', () {
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );
      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360, 640),
        style: style,
      );
      expect(metrics.columnCount, greaterThanOrEqualTo(7));

      final rulings = StationeryGeometry.buildRulings(
        metrics: metrics,
        style: style,
      );

      expect(rulings.secondaryLines, hasLength(metrics.columnCount - 1));
      expect(rulings.primaryLines, hasLength((metrics.rowCount - 1) * 2));
    });

    test('dotGrid and vertical silk columns produce expected counts', () {
      const dotStyle = TemplateStyle(
        type: TemplateBackgroundType.dotGrid,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );
      final dotMetrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360, 640),
        style: dotStyle,
      );
      final dotRulings = StationeryGeometry.buildRulings(
        metrics: dotMetrics,
        style: dotStyle,
      );
      expect(
        dotRulings.dots,
        hasLength((dotMetrics.rowCount - 1) * (dotMetrics.columnCount - 1)),
      );

      const linedStyle = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Color(0xFFFDFBF7),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );
      final vMetrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360, 640),
        style: linedStyle,
      );
      final vRulings = StationeryGeometry.buildRulings(
        metrics: vMetrics,
        style: linedStyle,
        isVertical: true,
        verticalColumnStride: 36.0,
      );
      expect(vRulings.primaryLines, isNotEmpty);
      for (final col in vRulings.primaryLines) {
        expect(col.start.dx, equals(col.end.dx));
      }
    });

    test('buildFolioRulings matches 320x448 Folio counts', () {
      const folioSize = Size(320, 448);

      final genko = StationeryGeometry.buildFolioRulings(
        size: folioSize,
        isVerticalColumns: false,
        isGenkoVertical: true,
        backgroundType: TemplateBackgroundType.grid,
        showLeftMarginRule: false,
      );
      expect(genko.primaryLines, hasLength(9));
      expect(genko.secondaryLines, hasLength(15));

      final dots = StationeryGeometry.buildFolioRulings(
        size: folioSize,
        isVerticalColumns: false,
        isGenkoVertical: false,
        backgroundType: TemplateBackgroundType.dotGrid,
        showLeftMarginRule: false,
      );
      expect(dots.dots, hasLength(117));
    });
  });

  group('StationeryGeometry.buildSealLayout', () {
    test('uses traditional R-to-L columns and pads only odd lengths (1 and 3)', () {
      final oneChar = StationeryGeometry.buildSealLayout(text: '松');
      expect(oneChar.colRight, equals(['松']));
      expect(oneChar.colLeft, equals(['印']));
      expect(oneChar.semanticText, equals('松'));

      final twoChar = StationeryGeometry.buildSealLayout(text: '拾光');
      expect(twoChar.colRight, equals(['拾']));
      expect(twoChar.colLeft, equals(['光']));
      expect(twoChar.semanticText, equals('拾光'));

      final threeChar = StationeryGeometry.buildSealLayout(text: '拾光存');
      expect(threeChar.colRight, equals(['拾', '光']));
      expect(threeChar.colLeft, equals(['存', '印']));
      expect(threeChar.semanticText, equals('拾光存'));

      final fourChar = StationeryGeometry.buildSealLayout(text: '心迹安放');
      expect(fourChar.colRight, equals(['心', '迹']));
      expect(fourChar.colLeft, equals(['安', '放']));
      expect(fourChar.semanticText, equals('心迹安放'));
    });

    test('strips whitespace, truncates at 4, defaults blank, and honors hidden style', () {
      final blank = StationeryGeometry.buildSealLayout(text: '   ');
      expect(blank.semanticText, equals('心迹安放'));
      expect(blank.colRight, equals(['心', '迹']));
      expect(blank.colLeft, equals(['安', '放']));

      final longText = StationeryGeometry.buildSealLayout(text: '诗 书 自 娱 斋');
      expect(longText.colRight, equals(['诗', '书']));
      expect(longText.colLeft, equals(['自', '娱']));

      final hidden = StationeryGeometry.buildSealLayout(
        text: '拾光',
        sealStyle: SealCarvingStyle.hidden,
      );
      expect(hidden.isVisible, isFalse);

      final baiwen = StationeryGeometry.buildSealLayout(
        text: '拾光',
        sealStyle: SealCarvingStyle.baiwen,
      );
      expect(baiwen.isVisible, isTrue);
      expect(baiwen.isBaiwen, isTrue);
    });
  });

  group('StationeryGeometry.buildColophon', () {
    test('formats date, weekday, weekly review, mood, and weather uniformly', () {
      final entry = Entry(
        id: 'e1',
        notebookId: 'nb1',
        templateId: 't1',
        title: '秋日随笔',
        contentDelta: '[]',
        plainText: '秋风起。',
        entryDate: DateTime(2026, 11, 23, 21, 15),
        mood: 4,
        weather: '晴天',
        isWeeklyReview: true,
        weekNumber: 47,
        createdAt: DateTime(2026, 11, 23),
        updatedAt: DateTime(2026, 11, 23),
        isDeleted: false,
        isLocked: false,
        legacyMountsPending: false,
      );

      final colophon = StationeryGeometry.buildColophon(entry);
      expect(colophon.dateLine, equals('2026年11月23日 星期一'));
      expect(colophon.detailParts, equals(['第47周复盘', '心情 4/5', '天气 晴天']));
      expect(colophon.detailLine, equals('第47周复盘 心情 4/5 天气 晴天'));
      expect(
        colophon.fullLabel,
        equals('2026年11月23日 星期一 第47周复盘 · 心情 4/5 · 天气 晴天'),
      );
    });

    test('omits optional colophon details when unset', () {
      final entry = Entry(
        id: 'e2',
        notebookId: 'nb1',
        templateId: 't1',
        title: null,
        contentDelta: '[]',
        plainText: '',
        entryDate: DateTime(2026, 11, 26),
        mood: null,
        weather: '  ',
        isWeeklyReview: false,
        weekNumber: null,
        createdAt: DateTime(2026, 11, 26),
        updatedAt: DateTime(2026, 11, 26),
        isDeleted: false,
        isLocked: false,
        legacyMountsPending: false,
      );

      final colophon = StationeryGeometry.buildColophon(entry);
      expect(colophon.dateLine, equals('2026年11月26日 星期四'));
      expect(colophon.detailParts, isEmpty);
      expect(colophon.fullLabel, equals('2026年11月26日 星期四'));
    });
  });
}
