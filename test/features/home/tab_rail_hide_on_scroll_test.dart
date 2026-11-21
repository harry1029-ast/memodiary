import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/features/albums/data/album_repository.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/main.dart';
import '../../helpers/mock_secure_storage.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('tab_rail_hide_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  const viewSize = Size(400, 800);
  final tabRail = find.byKey(const Key('home_tab_rail'));
  final timelineList = find.byType(CustomScrollView);
  final albumList = find.byType(ListView);
  final albumsTab = find.byKey(const Key('home_tab_albums'));

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = viewSize;
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

  Future<void> seedEntries(int count) async {
    for (var index = 0; index < count; index++) {
      final body = 'Body $index';
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'seed_entry_$index',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: Value('Seed Entry $index'),
          contentDelta: jsonEncode([
            {'insert': '$body\n'}
          ]),
          plainText: body,
          entryDate: DateTime(2026, 11, 20, 12).subtract(Duration(days: index)),
        ),
      );
    }
  }

  Future<List<String>> seedAlbums(int count) async {
    final repository = AlbumRepository(database: db, mediaService: mediaService);
    return [
      for (var index = 0; index < count; index++)
        (await repository.createCollection(title: '旅行 $index')).id,
    ];
  }

  Future<void> openAlbumsTab(WidgetTester tester) async {
    await tester.tap(albumsTab);
    await tester.pumpAndSettle();
  }

  /// Unmounts the app and drains Drift stream timers (the 相册 tab watches
  /// collections) so tearDown can close the database.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> scrollBy(WidgetTester tester, Finder list, double dy) async {
    await tester.drag(list, Offset(0, dy));
    await tester.pumpAndSettle();
  }

  /// The rail is shown while its top edge is inside the view, and hidden once
  /// it has slid fully below the bottom edge.
  void expectRailShown(WidgetTester tester, bool shown) {
    final top = tester.getRect(tabRail).top;
    expect(top < viewSize.height, shown, reason: 'rail top at $top');
  }

  group('Tab Rail hide on scroll', () {
    testWidgets('scrolling the timeline forward hides the rail; scrolling back reveals it', (tester) async {
      await seedEntries(12);
      await pumpApp(tester);
      expectRailShown(tester, true);

      await scrollBy(tester, timelineList, -300);
      expectRailShown(tester, false);

      await scrollBy(tester, timelineList, 100);
      expectRailShown(tester, true);
    });

    testWidgets('scrolling the 相册 list forward hides the rail; scrolling back reveals it', (tester) async {
      await seedAlbums(12);
      await pumpApp(tester);
      await openAlbumsTab(tester);

      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, false);

      await scrollBy(tester, albumList, 100);
      expectRailShown(tester, true);
      await unmountApp(tester);
    });

    testWidgets('switching tabs while the rail is hidden reveals it', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await seedAlbums(12);
      await pumpApp(tester);
      await openAlbumsTab(tester);
      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, false);

      // Android Back on 相册 switches to 日记: the one tab switch that can
      // happen while the rail is out of reach.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CustomScrollView), findsOneWidget);
      expectRailShown(tester, true);
      await unmountApp(tester);
    });

    testWidgets('a list too short to scroll never hides the rail', (tester) async {
      await seedAlbums(1);
      await pumpApp(tester);
      await openAlbumsTab(tester);

      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, true);
      await unmountApp(tester);
    });

    testWidgets('a list that shrinks below scrollable while the rail is hidden reveals it', (tester) async {
      final albumIds = await seedAlbums(12);
      await pumpApp(tester);
      await openAlbumsTab(tester);
      await scrollBy(tester, albumList, -300);
      expectRailShown(tester, false);

      final repository = AlbumRepository(database: db, mediaService: mediaService);
      for (final id in albumIds.skip(1)) {
        await repository.deleteCollection(id);
      }
      await tester.pumpAndSettle();
      expectRailShown(tester, true);
      await unmountApp(tester);
    });

    testWidgets('with reduced motion on, the rail stays shown', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await seedEntries(12);
      await pumpApp(tester);

      await scrollBy(tester, timelineList, -300);
      expectRailShown(tester, true);
    });

    testWidgets('horizontal Date Index Tray scrolls never toggle the rail', (tester) async {
      await seedEntries(12);
      await pumpApp(tester);
      final monthChips = find.ancestor(
        of: find.byKey(const Key('timeline_month_chip_6')),
        matching: find.byType(SingleChildScrollView),
      );

      await tester.drag(monthChips, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expectRailShown(tester, true);

      await scrollBy(tester, timelineList, -300);
      await tester.drag(monthChips, const Offset(200, 0));
      await tester.pumpAndSettle();
      expectRailShown(tester, false);
    });

    testWidgets('scrolls inside a pushed screen never toggle the rail', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('timeline_settings_button')));
      await tester.pumpAndSettle();
      final settings = find.byType(SettingsScreen);
      expect(tabRail, findsNothing);
      await tester.drag(
        find.descendant(of: settings, matching: find.byType(ListView)).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(settings)).pop();
      await tester.pumpAndSettle();
      expectRailShown(tester, true);
    });
  });
}
