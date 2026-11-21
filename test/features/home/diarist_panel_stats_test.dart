import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/import_export/screens/import_backup_screen.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
import '../../helpers/home_shell_test_harness.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  final harness = HomeShellHarness.register();
  final panel = HomeShellHarness.panel;
  final diaryStat = find.byKey(const Key('diarist_panel_stat_diary'));
  final albumsStat = find.byKey(const Key('diarist_panel_stat_albums'));
  final favouritesStat = find.byKey(const Key('diarist_panel_stat_favourites'));
  final recycleBinRow = find.byKey(const Key('diarist_panel_recycle_bin_row'));

  /// Three active entries (one plain, a weekly review, a time capsule), one in
  /// the Recycle Bin, and two albums.
  Future<void> seedDiary() async {
    await harness.addEntry('plain');
    await harness.addEntry('weekly_review', isWeeklyReview: true);
    await harness.addEntry('time_capsule', unlockAt: DateTime(2030, 1, 1));
    await harness.addEntry('in_recycle_bin', isDeleted: true);
    await harness.addAlbum('album_1');
    await harness.addAlbum('album_2');
  }

  String statText(WidgetTester tester, Finder stat) => tester
      .widgetList<Text>(find.descendant(of: stat, matching: find.byType(Text)))
      .map((text) => text.data)
      .join(' ');

  group('Stats strip', () {
    testWidgets('shows active entries and albums; 收藏 is a dimmed — announced as unavailable', (tester) async {
      await seedDiary();
      final semanticsHandle = tester.ensureSemantics();
      try {
        await harness.pumpApp(tester);
        await harness.openPanel(tester);

        expect(statText(tester, diaryStat), '3 日记');
        expect(statText(tester, albumsStat), '2 相册');
        expect(statText(tester, favouritesStat), '— 收藏');

        expect(
          tester.getSemantics(diaryStat),
          matchesSemantics(label: '日记 3', isButton: true, hasTapAction: true),
        );
        expect(
          tester.getSemantics(albumsStat),
          matchesSemantics(label: '相册 2', isButton: true, hasTapAction: true),
        );
        final favourites = tester.getSemantics(favouritesStat).getSemanticsData();
        expect(favourites.label, '收藏 暂不可用');
        expect(favourites.hasAction(SemanticsAction.tap), isFalse);
        expect(favourites.flagsCollection.isButton, isFalse);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('counts are refetched each time the panel opens', (tester) async {
      await seedDiary();
      await harness.pumpApp(tester);
      await harness.openPanel(tester);
      expect(statText(tester, diaryStat), '3 日记');
      expect(statText(tester, albumsStat), '2 相册');
      expect(find.descendant(of: recycleBinRow, matching: find.text('回收站 (1)')), findsOneWidget);
      await tester.tapAt(const Offset(385, 400));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);

      await tester.runAsync(() async {
        await harness.addEntry('new_entry');
        await harness.addEntry('second_new_entry');
        await harness.db.entriesDao.softDeleteEntry('plain');
        await harness.addAlbum('album_3');
        await harness.db.albumsDao.deleteCollectionRecords('album_1');
        await harness.db.albumsDao.deleteCollectionRecords('album_2');
      });
      await harness.openPanel(tester);

      expect(statText(tester, diaryStat), '4 日记');
      expect(statText(tester, albumsStat), '1 相册');
      expect(find.descendant(of: recycleBinRow, matching: find.text('回收站 (2)')), findsOneWidget);
    });

    testWidgets('tapping 相册 or 日记 closes the panel on that tab; tapping 收藏 does nothing', (tester) async {
      await harness.pumpApp(tester);
      await harness.openPanel(tester);

      await tester.tap(favouritesStat);
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);

      await tester.tap(albumsStat);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.text('暂无旅行相册'), findsOneWidget);

      await harness.openPanel(tester, avatar: HomeShellHarness.albumsAvatar);
      await tester.tap(diaryStat);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.text('暂无旅行相册'), findsNothing);
      await harness.unmountApp(tester);
    });
  });

  group('Rows', () {
    final rows = {
      '写作统计': (key: 'diarist_panel_analytics_row', screen: AnalyticsDashboardScreen),
      '回收站 (0)': (key: 'diarist_panel_recycle_bin_row', screen: RecycleBinScreen),
      '导入与备份': (key: 'diarist_panel_import_backup_row', screen: ImportBackupScreen),
    };

    testWidgets('sit between the stats strip and 返回封面, in order', (tester) async {
      await harness.pumpApp(tester);
      await harness.openPanel(tester);

      final rowTops = [
        tester.getTopLeft(diaryStat).dy,
        for (final row in rows.values) tester.getTopLeft(find.byKey(Key(row.key))).dy,
        tester.getTopLeft(find.byKey(const Key('diarist_panel_return_to_cover_row'))).dy,
      ];
      expect(rowTops, orderedEquals([...rowTops]..sort()));
      for (final label in rows.keys) {
        expect(find.descendant(of: find.byKey(Key(rows[label]!.key)), matching: find.text(label)), findsOneWidget);
      }
    });

    for (final MapEntry(key: label, value: row) in rows.entries) {
      testWidgets('$label opens its screen, and returning keeps the 相册 tab', (tester) async {
        await harness.pumpApp(tester);
        await tester.tap(HomeShellHarness.albumsTab);
        await tester.pumpAndSettle();
        await harness.openPanel(tester, avatar: HomeShellHarness.albumsAvatar);

        await tester.tap(find.byKey(Key(row.key)));
        await tester.pumpAndSettle();
        expect(find.byType(row.screen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(row.screen), findsNothing);
        expect(panel, findsNothing);
        expect(find.text('暂无旅行相册'), findsOneWidget);
        await harness.unmountApp(tester);
      });
    }

    testWidgets('an entry restored from 回收站 is back on the 日记 tab on return', (tester) async {
      await harness.addEntry('restored_entry', isDeleted: true);
      await harness.pumpApp(tester);
      expect(find.text('暂无日记'), findsOneWidget);
      await harness.openPanel(tester);

      await tester.tap(find.byKey(const Key('diarist_panel_recycle_bin_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('恢复'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(RecycleBinScreen), findsNothing);
      expect(find.text('暂无日记'), findsNothing);
      expect(find.text('restored_entry'), findsWidgets);
    });

    group('returning to a 日记 tab paged deep into the timeline', () {
      final timeline = find.byType(CustomScrollView);
      ScrollPosition timelinePosition(WidgetTester tester) => tester
          .state<ScrollableState>(find.descendant(of: timeline, matching: find.byType(Scrollable)).first)
          .position;
      final deepEntry = find.text('Seed Entry 45');

      /// Scrolls until the third page of 20 is loaded and `Seed Entry 45`
      /// shows; returns the scroll offset there.
      Future<double> pageDeep(WidgetTester tester) async {
        await tester.scrollUntilVisible(
          deepEntry,
          400,
          scrollable: find.descendant(of: timeline, matching: find.byType(Scrollable)).first,
        );
        await tester.pumpAndSettle();
        return timelinePosition(tester).pixels;
      }

      Future<void> visitRecycleBin(WidgetTester tester, {bool restoreOne = false}) async {
        await harness.openPanel(tester);
        await tester.tap(find.byKey(const Key('diarist_panel_recycle_bin_row')));
        await tester.pumpAndSettle();
        if (restoreOne) {
          await tester.tap(find.byTooltip('恢复'));
          await tester.pumpAndSettle();
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(RecycleBinScreen), findsNothing);
      }

      testWidgets('closing 回收站 without changes keeps the loaded pages and scroll offset', (tester) async {
        await harness.seedEntries(60);
        await harness.addEntry('binned_entry', isDeleted: true);
        await harness.pumpApp(tester);
        final offset = await pageDeep(tester);

        await visitRecycleBin(tester);

        expect(timelinePosition(tester).pixels, offset);
        expect(deepEntry, findsOneWidget);
      });

      testWidgets('an entry restored there appears, and the loaded pages stay', (tester) async {
        await harness.seedEntries(60);
        await harness.addEntry('restored_entry', isDeleted: true, entryDate: DateTime(2026, 11, 21));
        await harness.pumpApp(tester);
        await pageDeep(tester);

        await visitRecycleBin(tester, restoreOne: true);

        expect(deepEntry, findsOneWidget);
        timelinePosition(tester).jumpTo(0);
        await tester.pumpAndSettle();
        expect(find.text('restored_entry'), findsWidgets);
      });
    });
  });

  testWidgets('the strip and rows fit 320dp at 1.3x text scale with tap targets of at least 44x44', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await seedDiary();
    final semanticsHandle = tester.ensureSemantics();
    try {
      await harness.pumpApp(tester, size: const Size(320, 640));
      await harness.openPanel(tester);

      expect(tester.takeException(), isNull);
      expect(statText(tester, diaryStat), '3 日记');
      for (final stat in [diaryStat, albumsStat]) {
        final size = tester.getSize(stat);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      await expectAccessibleTapTargets(tester, within: panel);
    } finally {
      semanticsHandle.dispose();
    }
  });
}
