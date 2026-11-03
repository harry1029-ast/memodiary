import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/widgets/paper_heart_metrics.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';

void main() {
  group('PaperHeartMetrics Unit Tests', () {
    const sampleFrame = Rect.fromLTWH(24.0, 48.0, 312.0, 600.0);

    test('computeSealRect calculates 12px inset from right and bottom of innerFrameRect', () {
      final sealRect = PaperHeartMetrics.computeSealRect(
        innerFrameRect: sampleFrame,
        sealSize: 48.0,
        inset: 12.0,
      );

      expect(sealRect.width, equals(48.0));
      expect(sealRect.height, equals(48.0));
      expect(sealRect.right, equals(sampleFrame.right - 12.0));
      expect(sealRect.bottom, equals(sampleFrame.bottom - 12.0));
      expect(sealRect.left, equals(sampleFrame.right - 12.0 - 48.0));
      expect(sealRect.top, equals(sampleFrame.bottom - 12.0 - 48.0));
    });

    test('isContainedInside verifies 100% containment within innerFrameRect', () {
      final sealRect = PaperHeartMetrics.computeSealRect(
        innerFrameRect: sampleFrame,
        sealSize: 48.0,
        inset: 12.0,
      );

      expect(
        PaperHeartMetrics.isContainedInside(
          innerFrameRect: sampleFrame,
          targetRect: sealRect,
        ),
        isTrue,
      );

      // Mutated rect poking outside right edge
      final protrudingRect = Rect.fromLTWH(sampleFrame.right - 10.0, 100.0, 48.0, 48.0);
      expect(
        PaperHeartMetrics.isContainedInside(
          innerFrameRect: sampleFrame,
          targetRect: protrudingRect,
        ),
        isFalse,
      );
    });

    test('isInsideDoubleOuterBorder confirms containment inside outer border line', () {
      final sealRect = PaperHeartMetrics.computeSealRect(
        innerFrameRect: sampleFrame,
        sealSize: 48.0,
        inset: 12.0,
      );

      expect(
        PaperHeartMetrics.isInsideDoubleOuterBorder(
          innerFrameRect: sampleFrame,
          targetRect: sealRect,
        ),
        isTrue,
      );
    });

    test('computeSealStackOffsets produces accurate right and bottom offsets for Stack', () {
      const containerSize = Size(360.0, 700.0);
      final offsets = PaperHeartMetrics.computeSealStackOffsets(
        containerSize: containerSize,
        innerFrameRect: sampleFrame,
        sealSize: 48.0,
        inset: 12.0,
      );

      final expectedRight = (containerSize.width - sampleFrame.right) + 12.0;
      final expectedBottom = (containerSize.height - sampleFrame.bottom) + 12.0;

      expect(offsets.right, equals(expectedRight));
      expect(offsets.bottom, equals(expectedBottom));
      expect(offsets.width, equals(48.0));
      expect(offsets.height, equals(48.0));
    });
  });

  group('BoundedCinnabarSeal Widget Geometry Tests', () {
    const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);
    const linedStyle = TemplateStyle(
      type: TemplateBackgroundType.lined,
      backgroundColor: Colors.white,
      lineSpacing: 1.5,
      marginHorizontal: 24.0,
    );

    testWidgets('anchors CinnabarSignatureSeal 100% inside innerFrameRect on 360px viewport', (tester) async {
      const viewportSize = Size(360.0, 640.0);
      tester.view.physicalSize = Size(viewportSize.width * 2.0, viewportSize.height * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: viewportSize,
        style: linedStyle,
        typography: typography,
        compactMargins: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: viewportSize.width,
              height: viewportSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BoundedCinnabarSeal(
                    innerFrameRect: metrics.innerFrameRect,
                    containerSize: viewportSize,
                    sealStyle: SealCarvingStyle.zhuwen,
                    overrideText: '心迹安放',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sealFinder = find.byKey(const Key('cinnabar_signature_seal'));
      expect(sealFinder, findsOneWidget);

      final sealRect = tester.getRect(sealFinder);

      // Verify seal is completely inside innerFrameRect
      expect(
        PaperHeartMetrics.isContainedInside(
          innerFrameRect: metrics.innerFrameRect,
          targetRect: sealRect,
        ),
        isTrue,
        reason: 'Seal rect $sealRect must sit entirely inside innerFrameRect ${metrics.innerFrameRect}',
      );

      // Verify exact 12px inset clearance from right and bottom edges
      expect(sealRect.right, closeTo(metrics.innerFrameRect.right - 12.0, 0.5));
      expect(sealRect.bottom, closeTo(metrics.innerFrameRect.bottom - 12.0, 0.5));

      // Verify seal does not protrude outside Double Outer Border (which is inflated by 4px)
      final outerBorderRect = metrics.innerFrameRect.inflate(4.0);
      expect(sealRect.right, lessThan(outerBorderRect.right));
      expect(sealRect.bottom, lessThan(outerBorderRect.bottom));
      expect(sealRect.left, greaterThan(outerBorderRect.left));
      expect(sealRect.top, greaterThan(outerBorderRect.top));
    });

    testWidgets('anchors CinnabarSignatureSeal 100% inside innerFrameRect on standard 390px viewport', (tester) async {
      const viewportSize = Size(390.0, 844.0);
      tester.view.physicalSize = Size(viewportSize.width * 3.0, viewportSize.height * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: viewportSize,
        style: linedStyle,
        typography: typography,
        compactMargins: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: viewportSize.width,
              height: viewportSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BoundedCinnabarSeal(
                    innerFrameRect: metrics.innerFrameRect,
                    containerSize: viewportSize,
                    sealStyle: SealCarvingStyle.baiwen,
                    overrideText: '澄心',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sealFinder = find.byKey(const Key('cinnabar_signature_seal'));
      expect(sealFinder, findsOneWidget);

      final sealRect = tester.getRect(sealFinder);
      expect(
        PaperHeartMetrics.isContainedInside(
          innerFrameRect: metrics.innerFrameRect,
          targetRect: sealRect,
        ),
        isTrue,
      );
      expect(sealRect.right, closeTo(metrics.innerFrameRect.right - 12.0, 0.5));
      expect(sealRect.bottom, closeTo(metrics.innerFrameRect.bottom - 12.0, 0.5));
    });

    testWidgets('renders SizedBox.shrink when sealStyle is hidden', (tester) async {
      const viewportSize = Size(360.0, 640.0);
      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: viewportSize,
        style: linedStyle,
        typography: typography,
        compactMargins: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BoundedCinnabarSeal(
                  innerFrameRect: metrics.innerFrameRect,
                  containerSize: viewportSize,
                  sealStyle: SealCarvingStyle.hidden,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cinnabar_signature_seal')), findsNothing);
    });
  });
}
