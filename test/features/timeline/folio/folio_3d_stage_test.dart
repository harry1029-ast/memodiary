import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_3d_stage.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_chassis_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_corner_curl_widget.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_frontispiece_page.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_silk_bookmark_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_substrate_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/thread_bound_folio_screen.dart';
import '../../../helpers/editor_test_harness.dart';

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

  group('Folio3DStage & ThreadBoundFolioScreen Atmosphere Backdrop Tests', () {
    testWidgets(
      'backdrop adopts AtmospherePalette woodFrameDark/woodFrameMid across yunhaoDay, yunhaoNight, and classicEbony without altering ReadingPerspective',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final now = DateTime(2026, 11, 19, 21, 0);
        final entry = Entry(
          id: 'folio_backdrop_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: '夜读随笔',
          contentDelta: jsonEncode([
            {'insert': '案头微光，书卷如初。\n'}
          ]),
          plainText: '案头微光，书卷如初。',
          entryDate: now,
          isWeeklyReview: false,
          createdAt: now,
          updatedAt: now,
          isLocked: false,
          legacyMountsPending: false,
          isDeleted: false,
        );

        for (final palette in [
          AtmospherePalettes.yunhaoDay,
          AtmospherePalettes.yunhaoNight,
          AtmospherePalettes.classicEbony,
        ]) {
          final expectedScaffoldBg = Color.lerp(palette.woodFrameDark, Colors.black, 0.55)!;

          await tester.pumpWidget(
            MaterialApp(
              theme: InkDiaryTheme.forAtmosphere(palette),
              home: ThreadBoundFolioScreen(
                entry: entry,
                enableAmbientAnimation: false,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final scaffold = tester.widget<Scaffold>(
            find.descendant(
              of: find.byType(ThreadBoundFolioScreen),
              matching: find.byType(Scaffold),
            ),
          );
          expect(scaffold.backgroundColor, equals(expectedScaffoldBg), reason: palette.id);

          final stageBackdrop = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(Folio3DStage),
                  matching: find.byType(Container),
                )
                .first,
          );
          final backdropDec = stageBackdrop.decoration! as BoxDecoration;
          expect(backdropDec.color, equals(expectedScaffoldBg), reason: palette.id);
          final gradient = backdropDec.gradient! as RadialGradient;
          expect(
            gradient.colors,
            equals([palette.woodFrameMid, palette.woodFrameDark, expectedScaffoldBg]),
            reason: palette.id,
          );

          // ReadingPerspective & frontispiece leaf substrate stay untouched.
          final stageWidget = tester.widget<Folio3DStage>(find.byType(Folio3DStage));
          expect(stageWidget.theme, equals(FolioSubstrateTheme.xuan), reason: palette.id);
          final frontispiece = tester.widget<FolioFrontispiecePage>(
            find.byType(FolioFrontispiecePage),
          );
          expect(frontispiece.theme, equals(FolioSubstrateTheme.xuan), reason: palette.id);
        }

        // Switching ReadingPerspective stays independent of AtmospherePalette backdrop.
        await tester.tap(find.byKey(const Key('folio_reading_perspective_btn')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(Key('folio_perspective_option_${ReadingPerspective.obsidianNight.name}')),
        );
        await tester.pumpAndSettle();

        final stageAfterSwitch = tester.widget<Folio3DStage>(find.byType(Folio3DStage));
        expect(stageAfterSwitch.theme, equals(FolioSubstrateTheme.obsidian));
        final ebonyBackdrop = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(Folio3DStage),
                matching: find.byType(Container),
              )
              .first,
        );
        final ebonyExpectedBg = Color.lerp(
          AtmospherePalettes.classicEbony.woodFrameDark,
          Colors.black,
          0.55,
        )!;
        expect((ebonyBackdrop.decoration! as BoxDecoration).color, equals(ebonyExpectedBg));
      },
    );

    Future<void> pumpPhoneViewport(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: home));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'cover page with image does not rebuild leafBuilder per flip tick, shows zero loading spinner, and animates 3D flip via footer button',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('folio_flip_flicker_');
        addTearDown(() {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });
        final mediaDir = Directory('${tempDir.path}/media')..createSync(recursive: true);
        final coverFile = File('${mediaDir.path}/cover_1.png')..writeAsBytesSync(kValid1x1PngBytes);
        expect(coverFile.existsSync(), isTrue);

        final mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
        await mediaService.getBaseDirectory();

        final now = DateTime(2026, 11, 20, 21, 0);
        final entry = Entry(
          id: 'folio_cover_flip_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: '封面图测试',
          contentDelta: jsonEncode([
            {'insert': '微风轻拂。\n'},
            {'insert': {'mount': 'att_cover_1'}},
            {'insert': '\n'},
          ]),
          plainText: '微风轻拂。',
          entryDate: now,
          isWeeklyReview: false,
          createdAt: now,
          updatedAt: now,
          isLocked: false,
          legacyMountsPending: false,
          isDeleted: false,
        );
        final attachment = MediaAttachment(
          id: 'att_cover_1',
          entryId: entry.id,
          mediaType: 'image',
          relativePath: 'media/cover_1.png',
          createdAt: now,
        );

        await pumpPhoneViewport(
          tester,
          ThreadBoundFolioScreen(
            entry: entry,
            attachments: [attachment],
            mediaService: mediaService,
            enableAmbientAnimation: false,
          ),
        );

        // Cover image renders synchronously with gaplessPlayback and zero loading spinners.
        final coverImage = tester.widget<Image>(find.byType(Image).first);
        expect(coverImage.gaplessPlayback, isTrue);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Tapping '翻到正文 ›' must run the 3D flip animation instead of hard-cutting.
        await tester.tap(find.text('翻到正文 ›'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final stageState = tester.state<Folio3DStageState>(find.byType(Folio3DStage));
        expect(stageState.isFlipping, isTrue);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Mid-flip past 0.5 should show reverse bleed-through without spinner flash.
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byKey(const Key('folio_reverse_bleed_through')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pumpAndSettle();
        expect(stageState.isFlipping, isFalse);
      },
    );

    testWidgets(
      'Folio3DStage caches leafBuilder widgets across flip animation frames instead of rebuilding every tick',
      (tester) async {
        final stageKey = GlobalKey<Folio3DStageState>();
        var buildCalls = 0;

        await pumpPhoneViewport(
          tester,
          Scaffold(
            body: Folio3DStage(
              key: stageKey,
              leaves: createTestLeaves(),
              theme: FolioSubstrateTheme.xuan,
              enableAmbientAnimation: false,
              leafBuilder: (context, leaf, isTurningLeaf) {
                buildCalls++;
                return testLeafBuilder(context, leaf, isTurningLeaf);
              },
            ),
          ),
        );
        buildCalls = 0;

        stageKey.currentState!.flipPage(1);
        await tester.pump();
        final callsAtFlipStart = buildCalls;

        // Pumping multiple frames during the flip must not invoke leafBuilder again.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 150));
        expect(buildCalls, equals(callsAtFlipStart));

        await tester.pumpAndSettle();
      },
    );
  });
}
