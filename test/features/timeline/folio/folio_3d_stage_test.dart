import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_3d_stage.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_chassis_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_corner_curl_widget.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_silk_bookmark_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_substrate_painter.dart';

void main() {
  List<FolioLeaf> createTestLeaves() => const [
        FolioContentBodyLeaf(
          leafIndex: 0,
          totalLeaves: 3,
          pageIndexInContent: 1,
          totalContentPages: 3,
          layout: FolioRulingLayout.faithfulHorizontal,
          title: '叶零',
          lunarDate: '冬月廿三',
        ),
        FolioContentBodyLeaf(
          leafIndex: 1,
          totalLeaves: 3,
          pageIndexInContent: 2,
          totalContentPages: 3,
          layout: FolioRulingLayout.faithfulHorizontal,
          title: '叶一',
          lunarDate: '冬月廿四',
        ),
        FolioContentBodyLeaf(
          leafIndex: 2,
          totalLeaves: 3,
          pageIndexInContent: 3,
          totalContentPages: 3,
          layout: FolioRulingLayout.faithfulHorizontal,
          title: '叶二',
          lunarDate: '冬月廿五',
        ),
      ];

  Widget testLeafBuilder(
    BuildContext context,
    FolioLeaf leaf,
    bool isTurningLeaf,
  ) {
    return Container(
      key: Key('leaf_${leaf.leafIndex}_$isTurningLeaf'),
      color: Colors.amber.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          'Leaf ${leaf.leafIndex} (turning: $isTurningLeaf)',
          key: Key('leaf_text_${leaf.leafIndex}'),
        ),
      ),
    );
  }

  group('Folio Custom Painters Unit & Caching Tests', () {
    test('FolioChassisPainter records and caches ui.Picture', () {
      final painter = FolioChassisPainter();
      expect(painter.cachedPicture, isNull);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const testSize = Size(416, 628);

      painter.paint(canvas, testSize);
      expect(painter.cachedPicture, isNotNull);
      final initialPicture = painter.cachedPicture;

      // Painting again with same size reuses cached Picture
      painter.paint(canvas, testSize);
      expect(painter.cachedPicture, same(initialPicture));

      // shouldRepaint returns false (static immutable layer)
      expect(painter.shouldRepaint(FolioChassisPainter()), isFalse);
    });

    test('FolioSilkBookmarkPainter handles sway rotation and repaint', () {
      const painterDefault = FolioSilkBookmarkPainter();
      const painterSway = FolioSilkBookmarkPainter(swayAngle: 0.15);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painterDefault.paint(canvas, const Size(16, 62));
      painterSway.paint(canvas, const Size(16, 62));

      expect(painterDefault.shouldRepaint(painterSway), isTrue);
      expect(painterDefault.shouldRepaint(const FolioSilkBookmarkPainter()), isFalse);
    });

    test('FolioSubstratePainter respects gold flecks, shimmer and shadow', () {
      final painterGold = FolioSubstratePainter(
        showGoldFlecks: true,
        shimmerProgress: 0.5,
        isDark: false,
        enableShimmer: true,
        drawGutterShadow: true,
      );
      final painterPlain = FolioSubstratePainter(
        showGoldFlecks: false,
        isDark: false,
        enableShimmer: false,
        drawGutterShadow: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painterGold.paint(canvas, const Size(360, 596));
      painterPlain.paint(canvas, const Size(360, 596));

      expect(painterGold.shouldRepaint(painterPlain), isTrue);
    });

    test('FolioDogEarCurlPainter paints next and prev curls', () {
      const rightCurl = FolioDogEarCurlPainter(isRight: true);
      const leftCurl = FolioDogEarCurlPainter(isRight: false);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      rightCurl.paint(canvas, const Size(40, 40));
      leftCurl.paint(canvas, const Size(40, 40));

      expect(rightCurl.shouldRepaint(leftCurl), isTrue);
      expect(rightCurl.shouldRepaint(const FolioDogEarCurlPainter(isRight: true)), isFalse);
    });
  });

  group('Folio3DStage Responsive Scaling & Semantics Tests', () {
    testWidgets('scales responsively on 360px viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Folio3DStage(
              leaves: createTestLeaves(),
              theme: FolioSubstrateTheme.xuan,
              leafBuilder: testLeafBuilder,
              enableAmbientAnimation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Folio3DStage), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('scales cleanly on standard handset viewports (390px & 412px)', (tester) async {
      for (final handsetSize in const [Size(390, 844), Size(412, 915)]) {
        tester.view.physicalSize = handsetSize;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Folio3DStage(
                leaves: createTestLeaves(),
                theme: FolioSubstrateTheme.coldGold,
                leafBuilder: testLeafBuilder,
                enableAmbientAnimation: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows correct corner curl buttons and semantics on each page', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int currentPage = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Folio3DStage(
                  leaves: createTestLeaves(),
                  theme: FolioSubstrateTheme.xuan,
                  currentPageIndex: currentPage,
                  onPageChanged: (newPage) => setState(() => currentPage = newPage),
                  leafBuilder: testLeafBuilder,
                  enableAmbientAnimation: false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 0: Next curl present, prev curl absent
      expect(find.byKey(const Key('folio_corner_curl_next')), findsOneWidget);
      expect(find.byKey(const Key('folio_corner_curl_prev')), findsNothing);

      expect(
        tester.getSemantics(find.byKey(const Key('folio_corner_curl_next'))),
        matchesSemantics(
          isButton: true,
          label: '下一页',
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasScrollLeftAction: true,
          hasScrollRightAction: true,
        ),
      );

      // Tap Next -> advance to Page 1
      await tester.tap(find.byKey(const Key('folio_corner_curl_next')));
      await tester.pumpAndSettle();
      expect(currentPage, equals(1));

      // Page 1: Both Next and Prev curls present
      expect(find.byKey(const Key('folio_corner_curl_next')), findsOneWidget);
      expect(find.byKey(const Key('folio_corner_curl_prev')), findsOneWidget);

      expect(
        tester.getSemantics(find.byKey(const Key('folio_corner_curl_prev'))),
        matchesSemantics(
          isButton: true,
          label: '上一页',
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasScrollLeftAction: true,
          hasScrollRightAction: true,
        ),
      );

      // Tap Next -> advance to Page 2 (last page)
      await tester.tap(find.byKey(const Key('folio_corner_curl_next')));
      await tester.pumpAndSettle();
      expect(currentPage, equals(2));

      // Page 2: Prev curl present, next curl absent
      expect(find.byKey(const Key('folio_corner_curl_next')), findsNothing);
      expect(find.byKey(const Key('folio_corner_curl_prev')), findsOneWidget);

      // Tap Prev -> return to Page 1
      await tester.tap(find.byKey(const Key('folio_corner_curl_prev')));
      await tester.pumpAndSettle();
      expect(currentPage, equals(1));
    });
  });

  group('Folio3DStage 3D Flip Progression & Bleed-Through Tests', () {
    testWidgets('bleed-through switchover past 0.5 flip progress', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stageKey = GlobalKey<Folio3DStageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Folio3DStage(
              key: stageKey,
              leaves: createTestLeaves(),
              theme: FolioSubstrateTheme.xuan,
              leafBuilder: testLeafBuilder,
              enableAmbientAnimation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger forward page turn
      stageKey.currentState!.flipPage(1);
      await tester.pump(); // Start animation frame

      // Pump 120ms into 450ms animation (progress < 0.5)
      await tester.pump(const Duration(milliseconds: 120));
      expect(stageKey.currentState!.flipController.value, lessThan(0.5));
      expect(find.byKey(const Key('folio_reverse_bleed_through')), findsNothing);
      expect(find.byKey(const Key('leaf_0_true')), findsOneWidget);

      // Pump to 320ms into 450ms animation (progress > 0.5)
      await tester.pump(const Duration(milliseconds: 200));
      expect(stageKey.currentState!.flipController.value, greaterThan(0.5));
      expect(find.byKey(const Key('folio_reverse_bleed_through')), findsOneWidget);

      // Finish flip animation
      await tester.pumpAndSettle();
      expect(stageKey.currentState!.isFlipping, isFalse);
    });

    testWidgets('interactive corner drag scrubbing commits past threshold', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int currentPage = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Folio3DStage(
                  leaves: createTestLeaves(),
                  theme: FolioSubstrateTheme.obsidian,
                  currentPageIndex: currentPage,
                  onPageChanged: (newPage) => setState(() => currentPage = newPage),
                  leafBuilder: testLeafBuilder,
                  enableAmbientAnimation: false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag next corner curl left by steps to exceed slop and reach > 0.35 threshold (160px / 280px = 0.57)
      final nextCornerFinder = find.byKey(const Key('folio_corner_curl_next'));
      final gesture = await tester.startGesture(tester.getCenter(nextCornerFinder));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-130, 0));
      await tester.pump();

      // Release drag -> should commit to next page
      await gesture.up();
      await tester.pumpAndSettle();

      expect(currentPage, equals(1));
    });

    testWidgets('interactive corner drag springs back if released before threshold', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int currentPage = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Folio3DStage(
                  leaves: createTestLeaves(),
                  theme: FolioSubstrateTheme.coldGold,
                  currentPageIndex: currentPage,
                  onPageChanged: (newPage) => setState(() => currentPage = newPage),
                  leafBuilder: testLeafBuilder,
                  enableAmbientAnimation: false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag next corner curl slightly (25px then 15px, total 40px / 280px = 0.14 < 0.35 threshold)
      final nextCornerFinder = find.byKey(const Key('folio_corner_curl_next'));
      final gesture = await tester.startGesture(tester.getCenter(nextCornerFinder));
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump();

      // Release drag -> should cancel and spring back to page 0
      await gesture.up();
      await tester.pumpAndSettle();

      expect(currentPage, equals(0));
    });
  });
}
