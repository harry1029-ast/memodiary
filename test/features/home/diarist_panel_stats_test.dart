import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/import_export/screens/import_backup_screen.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
import 'package:memodiary/main.dart';
import '../../helpers/mock_secure_storage.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('diarist_panel_stats_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  final panel = find.byKey(const Key('diarist_panel'));
  final diaryStat = find.byKey(const Key('diarist_panel_stat_diary'));
  final albumsStat = find.byKey(const Key('diarist_panel_stat_albums'));
  final favouritesStat = find.byKey(const Key('diarist_panel_stat_favourites'));

  Future<void> pumpApp(WidgetTester tester, {Size size = const Size(400, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MemoDiaryApp(
        database: db,
        mediaService: mediaService,
        showIntroOnLaunch: false,
        themeSettings: ThemeSettingsService(storage: MockSecureStorage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unmounts the app and drains Drift stream timers (the 相册 tab watches
  /// collections) so tearDown can close the database.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openPanel(WidgetTester tester, {String avatarKey = 'timeline_avatar_button'}) async {
    await tester.tap(find.byKey(Key(avatarKey)));
    await tester.pumpAndSettle();
  }

  Future<void> addEntry(
    String id, {
    bool isWeeklyReview = false,
    DateTime? unlockAt,
    bool isDeleted = false,
  }) {
    return db.entriesDao.createEntry(
      EntriesCompanion.insert(
        id: id,
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: Value(id),
        contentDelta: '[{"insert":"$id\\n"}]',
        plainText: id,
        entryDate: DateTime(2026, 11, 20),
        isWeeklyReview: Value(isWeeklyReview),
        unlockAt: Value(unlockAt),
        isDeleted: Value(isDeleted),
      ),
    );
  }

  Future<void> addAlbum(String id) {
    return db.albumsDao.insertCollection(
      AlbumCollectionsCompanion.insert(id: id, title: id),
    );
  }

  /// Three active entries (one plain, a weekly review, a time capsule), one in
  /// the Recycle Bin, and two albums.
  Future<void> seedDiary() async {
    await addEntry('plain');
    await addEntry('weekly_review', isWeeklyReview: true);
    await addEntry('time_capsule', unlockAt: DateTime(2030, 1, 1));
    await addEntry('in_recycle_bin', isDeleted: true);
    await addAlbum('album_1');
    await addAlbum('album_2');
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
        await pumpApp(tester);
        await openPanel(tester);

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
      await pumpApp(tester);
      await openPanel(tester);
      expect(statText(tester, diaryStat), '3 日记');
      expect(statText(tester, albumsStat), '2 相册');
      await tester.tapAt(const Offset(385, 400));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);

      await tester.runAsync(() async {
        await addEntry('new_entry');
        await addEntry('second_new_entry');
        await db.entriesDao.softDeleteEntry('plain');
        await addAlbum('album_3');
        await db.albumsDao.deleteCollectionRecords('album_1');
        await db.albumsDao.deleteCollectionRecords('album_2');
      });
      await openPanel(tester);

      expect(statText(tester, diaryStat), '4 日记');
      expect(statText(tester, albumsStat), '1 相册');
    });

    testWidgets('tapping 相册 or 日记 closes the panel on that tab; tapping 收藏 does nothing', (tester) async {
      await pumpApp(tester);
      await openPanel(tester);

      await tester.tap(favouritesStat);
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);

      await tester.tap(albumsStat);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.text('暂无旅行相册'), findsOneWidget);

      await openPanel(tester, avatarKey: 'albums_avatar_button');
      await tester.tap(diaryStat);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.text('暂无旅行相册'), findsNothing);
      await unmountApp(tester);
    });
  });

  group('Rows', () {
    final rows = {
      '写作统计': (key: 'diarist_panel_analytics_row', screen: AnalyticsDashboardScreen),
      '回收站': (key: 'diarist_panel_recycle_bin_row', screen: RecycleBinScreen),
      '导入与备份': (key: 'diarist_panel_import_backup_row', screen: ImportBackupScreen),
    };

    testWidgets('sit between the stats strip and 返回封面, in order', (tester) async {
      await pumpApp(tester);
      await openPanel(tester);

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
        await pumpApp(tester);
        await tester.tap(find.byKey(const Key('home_tab_albums')));
        await tester.pumpAndSettle();
        await openPanel(tester, avatarKey: 'albums_avatar_button');

        await tester.tap(find.byKey(Key(row.key)));
        await tester.pumpAndSettle();
        expect(find.byType(row.screen), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(row.screen), findsNothing);
        expect(panel, findsNothing);
        expect(find.text('暂无旅行相册'), findsOneWidget);
        await unmountApp(tester);
      });
    }

    testWidgets('an entry restored from 回收站 is back on the 日记 tab on return', (tester) async {
      await addEntry('restored_entry', isDeleted: true);
      await pumpApp(tester);
      expect(find.text('暂无日记'), findsOneWidget);
      await openPanel(tester);

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
  });

  testWidgets('the strip and rows fit 320dp at 1.3x text scale with tap targets of at least 44x44', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await seedDiary();
    final semanticsHandle = tester.ensureSemantics();
    try {
      await pumpApp(tester, size: const Size(320, 640));
      await openPanel(tester);

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
