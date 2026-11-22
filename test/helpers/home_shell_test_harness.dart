import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/features/albums/data/album_repository.dart';
import 'package:memodiary/features/intro/widgets/bottom_seal_slider.dart';
import 'package:memodiary/main.dart';

import 'mock_secure_storage.dart';

/// Shared app-seam harness for the Home Shell suites: an in-memory database
/// and a temp media sandbox per test, [MemoDiaryApp] pumped at a fixed phone
/// size, and seeding helpers for entries and albums.
///
/// Create it once at the top of `main()` with [HomeShellHarness.register],
/// which wires `setUp` / `tearDown`. Tests that build the 相册 tab must call
/// [unmountApp] before the test ends, so tearDown can close the database.
class HomeShellHarness {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory _tempDir;

  HomeShellHarness._();

  /// Registers per-test setUp / tearDown and returns the harness.
  factory HomeShellHarness.register() {
    final harness = HomeShellHarness._();
    setUp(() {
      harness.db = AppDatabase.memory();
      harness._tempDir = Directory.systemTemp.createTempSync('home_shell_harness_');
      harness.mediaService = MediaSandboxService(baseDirProvider: () async => harness._tempDir);
    });
    tearDown(() async {
      await harness.db.close();
      if (harness._tempDir.existsSync()) harness._tempDir.deleteSync(recursive: true);
    });
    return harness;
  }

  static final Finder tabRail = find.byKey(const Key('tab_rail'));
  static final Finder diaryTab = find.byKey(const Key('tab_rail_tab_diary'));
  static final Finder albumsTab = find.byKey(const Key('tab_rail_tab_albums'));
  static final Finder centreButton = find.byKey(const Key('tab_rail_centre_button'));
  static final Finder panel = find.byKey(const Key('diarist_panel'));
  static final Finder timelineAvatar = find.byKey(const Key('timeline_avatar_button'));
  static final Finder albumsAvatar = find.byKey(const Key('albums_avatar_button'));

  /// Pumps [MemoDiaryApp] at [size] (1.0 DPR, with an optional status-bar
  /// [topPadding]) and returns its theme settings. With the cover on, only a
  /// bounded pump runs, since the cover's ambient animation never settles.
  Future<ThemeSettingsService> pumpApp(
    WidgetTester tester, {
    bool showIntroOnLaunch = false,
    Size size = const Size(400, 800),
    double? topPadding,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    if (topPadding != null) tester.view.padding = FakeViewPadding(top: topPadding);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });
    final themeSettings = ThemeSettingsService(storage: MockSecureStorage());
    await tester.pumpWidget(
      MemoDiaryApp(
        database: db,
        mediaService: mediaService,
        showIntroOnLaunch: showIntroOnLaunch,
        themeSettings: themeSettings,
      ),
    );
    if (showIntroOnLaunch) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
    return themeSettings;
  }

  /// Unmounts the app and drains Drift stream timers (the 相册 tab watches
  /// collections) so tearDown can close the database.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  /// Opens the cover's seal and taps the [door] (`私人日记`, `旅行相册`).
  Future<void> openCoverAndTap(WidgetTester tester, String door) async {
    await tester.tap(find.byType(BottomSealSlider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text(door));
    await tester.pumpAndSettle();
  }

  Future<void> selectTab(WidgetTester tester, Finder tab) async {
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  /// Opens the Diarist Panel from the [avatar] button (the 日记 header's by
  /// default).
  Future<void> openPanel(WidgetTester tester, {Finder? avatar}) async {
    await tester.tap(avatar ?? timelineAvatar);
    await tester.pumpAndSettle();
  }

  /// Inserts one entry titled [title] (defaults to [id]), whose body is
  /// [body] (defaults to [id]).
  Future<void> addEntry(
    String id, {
    String? title,
    String? body,
    DateTime? entryDate,
    bool isWeeklyReview = false,
    DateTime? unlockAt,
    bool isDeleted = false,
  }) {
    final text = body ?? id;
    return db.entriesDao.createEntry(
      EntriesCompanion.insert(
        id: id,
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: Value(title ?? id),
        contentDelta: jsonEncode([
          {'insert': '$text\n'}
        ]),
        plainText: text,
        entryDate: entryDate ?? DateTime(2026, 11, 20),
        isWeeklyReview: Value(isWeeklyReview),
        unlockAt: Value(unlockAt),
        isDeleted: Value(isDeleted),
      ),
    );
  }

  /// [count] entries titled `Seed Entry <n>`, one a day back from
  /// 2026-11-20, so `Seed Entry 0` is the newest.
  Future<void> seedEntries(int count) async {
    for (var index = 0; index < count; index++) {
      await addEntry(
        'seed_entry_$index',
        title: 'Seed Entry $index',
        body: 'Body $index',
        entryDate: DateTime(2026, 11, 20, 12).subtract(Duration(days: index)),
      );
    }
  }

  Future<void> addAlbum(String id) {
    return db.albumsDao.insertCollection(
      AlbumCollectionsCompanion.insert(id: id, title: id),
    );
  }

  /// [count] albums titled `旅行 <n>`, created through the album repository;
  /// returns their ids.
  Future<List<String>> seedAlbums(int count) async {
    final repository = AlbumRepository(database: db, mediaService: mediaService);
    return [
      for (var index = 0; index < count; index++)
        (await repository.createCollection(title: '旅行 $index')).id,
    ];
  }
}
