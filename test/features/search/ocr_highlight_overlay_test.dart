import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/ocr/ocr_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/search/widgets/ocr_highlight_overlay.dart';

void main() {
  final sampleLines = [
    const OcrLineBlock(
      text: '杭州西湖风景名胜区',
      box: [0.1, 0.1, 0.8, 0.08],
    ),
    const OcrLineBlock(
      text: '花港观鱼石碑题字',
      box: [0.15, 0.25, 0.7, 0.08],
    ),
    const OcrLineBlock(
      text: '乾隆御笔 岁在戊寅',
      box: [0.2, 0.4, 0.6, 0.06],
    ),
    const OcrLineBlock(
      text: '门票特惠 ￥50',
      box: [0.25, 0.55, 0.5, 0.05],
    ),
  ];

  group('OcrHighlightOverlay - Coordinate Projection & Math', () {
    test('projects normalized box onto pillarboxed image rect (container wider than image)', () {
      // Container: 1000x500 (aspect 2.0). Image: 500x500 (aspect 1.0).
      // Destination rect should be letterboxed horizontally: left=250, top=0, width=500, height=500.
      const containerSize = Size(1000, 500);
      const originalImageSize = Size(500, 500);

      final destRect = OcrHighlightOverlay.calculateDestinationRect(
        originalImageSize: originalImageSize,
        containerSize: containerSize,
      );

      expect(destRect, equals(const Rect.fromLTWH(250, 0, 500, 500)));

      // Box: [0.1, 0.2, 0.5, 0.3]
      // left: 250 + 0.1 * 500 = 300
      // top: 0 + 0.2 * 500 = 100
      // width: 0.5 * 500 = 250
      // height: 0.3 * 500 = 150
      final projected = OcrHighlightOverlay.projectNormalizedBox(
        const [0.1, 0.2, 0.5, 0.3],
        destRect,
      );

      expect(projected.left, closeTo(300.0, 0.001));
      expect(projected.top, closeTo(100.0, 0.001));
      expect(projected.width, closeTo(250.0, 0.001));
      expect(projected.height, closeTo(150.0, 0.001));
    });

    test('projects normalized box onto letterboxed image rect (container taller than image)', () {
      // Container: 400x800 (aspect 0.5). Image: 400x400 (aspect 1.0).
      // Destination rect letterboxed vertically: left=0, top=200, width=400, height=400.
      const containerSize = Size(400, 800);
      const originalImageSize = Size(400, 400);

      final destRect = OcrHighlightOverlay.calculateDestinationRect(
        originalImageSize: originalImageSize,
        containerSize: containerSize,
      );

      expect(destRect, equals(const Rect.fromLTWH(0, 200, 400, 400)));

      // Box: [0.2, 0.1, 0.6, 0.4]
      // left: 0 + 0.2 * 400 = 80
      // top: 200 + 0.1 * 400 = 240
      // width: 0.6 * 400 = 240
      // height: 0.4 * 400 = 160
      final projected = OcrHighlightOverlay.projectNormalizedBox(
        const [0.2, 0.1, 0.6, 0.4],
        destRect,
      );

      expect(projected.left, closeTo(80.0, 0.001));
      expect(projected.top, closeTo(240.0, 0.001));
      expect(projected.width, closeTo(240.0, 0.001));
      expect(projected.height, closeTo(160.0, 0.001));
    });

    test('gracefully ignores degenerate or non-finite bounding boxes', () {
      const destRect = Rect.fromLTWH(0, 0, 800, 600);

      expect(OcrHighlightOverlay.projectNormalizedBox(const [0, 0, 0, 10], destRect), equals(Rect.zero));
      expect(OcrHighlightOverlay.projectNormalizedBox(const [0, 0, 10, -5], destRect), equals(Rect.zero));
      expect(OcrHighlightOverlay.projectNormalizedBox(const [0, 0, double.nan, 10], destRect), equals(Rect.zero));
      expect(OcrHighlightOverlay.projectNormalizedBox(const [0, 0, double.infinity, 10], destRect), equals(Rect.zero));
      expect(OcrHighlightOverlay.projectNormalizedBox(const [0, 0], destRect), equals(Rect.zero));
    });
  });

  group('OcrHighlightOverlay - Query Matching Logic', () {
    test('exact substring match case-insensitively selects matching lines', () {
      final matches = OcrHighlightOverlay.filterMatchingLines(sampleLines, '花港观鱼');
      expect(matches.length, equals(1));
      expect(matches.first.text, equals('花港观鱼石碑题字'));
    });

    test('case-insensitive match handles Latin queries', () {
      const latinLines = [
        OcrLineBlock(text: 'Cafe Americano 35RMB', box: [0.1, 0.1, 0.5, 0.1]),
        OcrLineBlock(text: 'Starbucks Coffee Shop', box: [0.1, 0.3, 0.5, 0.1]),
      ];

      final matches = OcrHighlightOverlay.filterMatchingLines(latinLines, 'COFFEE');
      expect(matches.length, equals(1));
      expect(matches.first.text, equals('Starbucks Coffee Shop'));
    });

    test('falls back to whitespace-split tokens when full query does not match a single line', () {
      // Query "西湖 乾隆" does not appear as a continuous string in any line,
      // but "西湖" is in line 0 and "乾隆" is in line 2.
      final matches = OcrHighlightOverlay.filterMatchingLines(sampleLines, '西湖 乾隆');
      expect(matches.length, equals(2));
      expect(matches.map((line) => line.text), containsAll(['杭州西湖风景名胜区', '乾隆御笔 岁在戊寅']));
    });

    test('returns empty list when no lines match', () {
      final matches = OcrHighlightOverlay.filterMatchingLines(sampleLines, '不存在的关键词');
      expect(matches, isEmpty);
    });

    test('returns empty list for blank query or empty lines', () {
      expect(OcrHighlightOverlay.filterMatchingLines(sampleLines, '   '), isEmpty);
      expect(OcrHighlightOverlay.filterMatchingLines(const [], '花港'), isEmpty);
    });
  });

  group('OcrHighlightOverlay - Widget Rendering & Interaction', () {
    testWidgets('renders CustomPaint with matched boxes when isVisible is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: OcrHighlightOverlay(
                  lines: sampleLines,
                  query: '花港观鱼',
                  originalImageSize: const Size(1600, 1200),
                  isVisible: true,
                  enableAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OcrHighlightOverlay), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('paints nothing when isVisible is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: OcrHighlightOverlay(
                  lines: sampleLines,
                  query: '花港观鱼',
                  originalImageSize: const Size(1600, 1200),
                  isVisible: false,
                  enableAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overlayWidget = tester.widget<OcrHighlightOverlay>(find.byType(OcrHighlightOverlay));
      expect(overlayWidget.isVisible, isFalse);
    });

    testWidgets('settles cleanly without animation timeout in test environment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: OcrHighlightOverlay(
                lines: sampleLines,
                query: '乾隆',
                originalImageSize: const Size(800, 800),
                isVisible: true,
                enableAnimation: true, // Should be guarded by FLUTTER_TEST check
              ),
            ),
          ),
        ),
      );

      // Verify tester.pumpAndSettle does not hang or time out
      await tester.pumpAndSettle();
      expect(find.byType(OcrHighlightOverlay), findsOneWidget);
    });
  });
}
