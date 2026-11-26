import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_card.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_charm_filter_sheet.dart';
import 'package:memodiary/features/timeline/widgets/window_sill_ledge.dart';

import '../../helpers/timeline_test_harness.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedEntries(int count) async {
    final baseDate = DateTime(2026, 11, 20, 12, 0);
    for (int index = 0; index < count; index++) {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'tap_top_entry_$index',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: Value('Entry $index'),
          contentDelta: jsonEncode([
            {'insert': 'Body content for entry $index\n'},
          ]),
          plainText: 'Body content for entry $index',
          entryDate: baseDate.subtract(Duration(days: index)),
        ),
      );
    }
  }

  double currentScrollOffset(WidgetTester tester) {
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    return scrollable.position.pixels;
  }

  group('ChronicleDeskHeader Tap-to-Top', () {
    testWidgets(
      'tapping pinned title area when scrolled down returns timeline to offset 0 and reveals scenery',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await seedEntries(15);
          await pumpTimelineScreen(
            tester,
            database: db,
            mediaService: mediaService,
          );

          expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
          expect(find.byType(WindowSillLedge), findsOneWidget);
          expect(currentScrollOffset(tester), 0.0);

          await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
          await tester.pumpAndSettle();

          expect(currentScrollOffset(tester), greaterThan(0.0));
          expect(find.byType(ShanshuiSceneryCard), findsNothing);
          expect(find.bySemanticsLabel(RegExp('日记 · 共 15 篇')), findsOneWidget);
          expect(find.bySemanticsLabel(RegExp('点击返回顶部')), findsOneWidget);
          await expectAccessibleTapTargets(
            tester,
            within: find.byKey(const Key('timeline_tap_to_top_button')),
          );

          await tester.tap(find.byKey(const Key('timeline_tap_to_top_button')));
          await tester.pumpAndSettle();

          expect(currentScrollOffset(tester), 0.0);
          expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
          expect(find.byType(WindowSillLedge), findsOneWidget);
        } finally {
          semanticsHandle.dispose();
        }
      },
    );

    testWidgets(
      'tapping title or count badge at offset 0 is a harmless no-op without return-to-top semantics',
      (tester) async {
        await seedEntries(15);
        await pumpTimelineScreen(
          tester,
          database: db,
          mediaService: mediaService,
        );

        expect(currentScrollOffset(tester), 0.0);
        expect(find.bySemanticsLabel(RegExp('点击返回顶部')), findsNothing);

        await tester.tap(find.byKey(const Key('timeline_tap_to_top_button')));
        await tester.pumpAndSettle();

        expect(currentScrollOffset(tester), 0.0);
        expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'deep scroll far down pre-jumps closer to top and briskly animates to offset 0',
      (tester) async {
        await seedEntries(30);
        await pumpTimelineScreen(
          tester,
          database: db,
          mediaService: mediaService,
        );

        for (int swipe = 0; swipe < 5; swipe++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -600),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        final deepOffset = currentScrollOffset(tester);
        expect(deepOffset, greaterThan(1800.0));
        expect(find.bySemanticsLabel(RegExp('日记 · 共 30 篇')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('点击返回顶部')), findsOneWidget);

        await tester.tap(find.byKey(const Key('timeline_entry_count_badge')));
        await tester.pump();

        // Pre-jump moves immediately to the 1600px threshold before animating.
        expect(currentScrollOffset(tester), lessThanOrEqualTo(1600.0));

        await tester.pump(const Duration(milliseconds: 100));
        expect(currentScrollOffset(tester), lessThan(1600.0));

        await tester.pumpAndSettle();
        expect(currentScrollOffset(tester), 0.0);
        expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
      },
    );

    testWidgets(
      'reduced motion jumps immediately to offset 0 on a single frame',
      (tester) async {
        await seedEntries(15);
        await pumpTimelineScreen(
          tester,
          database: db,
          mediaService: mediaService,
          disableAnimations: true,
        );

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(currentScrollOffset(tester), greaterThan(0.0));

        await tester.tap(find.byKey(const Key('timeline_tap_to_top_button')));
        await tester.pump();

        expect(currentScrollOffset(tester), 0.0);
        expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
      },
    );

    testWidgets(
      'satisfies 44x44dp target, renders cleanly on 320dp at 1.3x scale, and does not interfere with filter controls',
      (tester) async {
        await seedEntries(15);
        await pumpTimelineScreen(
          tester,
          database: db,
          mediaService: mediaService,
          surfaceSize: const Size(320, 640),
          textScale: 1.3,
        );

        final tapToTopFinder = find.byKey(const Key('timeline_tap_to_top_button'));
        final tapSize = tester.getSize(tapToTopFinder);
        expect(tapSize.width, greaterThanOrEqualTo(44.0));
        expect(tapSize.height, greaterThanOrEqualTo(44.0));
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();

        final offsetAfterScroll = currentScrollOffset(tester);
        expect(offsetAfterScroll, greaterThan(0.0));

        // Tapping Begonia plaque filter opens filter sheet without scrolling to top.
        await tester.tap(find.byKey(const Key('timeline_charm_filter_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ChronicleCharmFilterSheet), findsOneWidget);

        await tester.tap(find.byKey(const Key('charm_filter_close_button')));
        await tester.pumpAndSettle();
        expect(currentScrollOffset(tester), offsetAfterScroll);

        // Tapping Date Index Tray sort and month chips never triggers Tap-to-Top.
        await tester.tap(find.byKey(const Key('timeline_sort_toggle_button')));
        await tester.pumpAndSettle();
        expect(find.text('最早'), findsOneWidget);
        expect(currentScrollOffset(tester), greaterThan(0.0));

        await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_11')));
        await tester.tap(find.byKey(const Key('timeline_month_chip_11')));
        await tester.pumpAndSettle();
        expect(currentScrollOffset(tester), greaterThan(0.0));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
