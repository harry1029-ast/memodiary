import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/timeline/widgets/wet_mounted_thumbnail.dart';

import '../../helpers/editor_test_harness.dart';
import '../../helpers/mock_secure_storage.dart';
import '../../helpers/timeline_test_harness.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('wet_mounted_thumb_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpThumbnail(
    WidgetTester tester, {
    required String relativePath,
    required MediaSandboxService mediaService,
    double devicePixelRatio = 1.0,
    double width = 82.0,
    double height = 62.0,
  }) async {
    tester.view.physicalSize = Size(360 * devicePixelRatio, 780 * devicePixelRatio);
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: WetMountedThumbnail(
            relativePath: relativePath,
            mediaService: mediaService,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }

  group('WetMountedThumbnail synchronous resolution & bounded decoding', () {
    testWidgets('renders Image.file synchronously on frame 1 when base directory is warm without FutureBuilder flicker', (tester) async {
      const relativePath = 'media/warm_thumb.webp';
      File('${tempDir.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      final mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
      await mediaService.getBaseDirectory();

      await pumpThumbnail(
        tester,
        relativePath: relativePath,
        mediaService: mediaService,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FutureBuilder<File>), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets('falls back to async resolution when cold without flashing on parent rebuild', (tester) async {
      const relativePath = 'media/cold_thumb.webp';
      File('${tempDir.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      var baseDirLookups = 0;
      final mediaService = MediaSandboxService(
        baseDirProvider: () async {
          baseDirLookups++;
          return tempDir;
        },
      );

      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (context, value, _) => WetMountedThumbnail(
                relativePath: relativePath,
                mediaService: mediaService,
              ),
            ),
          ),
        ),
      );

      // Frame 1 while cold: FutureBuilder shows placeholder
      expect(find.byType(FutureBuilder<File>), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);

      // Pump to let async resolution complete; now base directory is warm
      await tester.pump();
      expect(baseDirLookups, 1);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNothing);

      // Trigger parent rebuild: switches to synchronous Image with zero FutureBuilder or extra lookups
      tick.value = 1;
      await tester.pump();
      expect(baseDirLookups, 1);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(FutureBuilder<File>), findsNothing);
    });

    testWidgets('mounts Image.file without UI-thread existsSync and uses errorBuilder for missing files', (tester) async {
      final mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
      await mediaService.getBaseDirectory();

      await pumpThumbnail(
        tester,
        relativePath: 'media/does_not_exist.webp',
        mediaService: mediaService,
      );

      // On frame 1, Image.file is mounted directly (not short-circuited by existsSync())
      expect(find.byType(Image), findsOneWidget);

      // Allow FileImage async read failure to invoke errorBuilder
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('renders placeholder directly when relativePath is empty', (tester) async {
      final mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
      await mediaService.getBaseDirectory();

      await pumpThumbnail(
        tester,
        relativePath: '',
        mediaService: mediaService,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(FutureBuilder<File>), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('decodes Image.file with device-pixel-ratio-scaled cacheWidth and cacheHeight bounds', (tester) async {
      const relativePath = 'media/bounded_thumb.webp';
      File('${tempDir.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      final mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
      await mediaService.getBaseDirectory();

      await pumpThumbnail(
        tester,
        relativePath: relativePath,
        mediaService: mediaService,
        devicePixelRatio: 2.0,
      );

      final imageAt2x = tester.widget<Image>(find.byType(Image)).image;
      expect(imageAt2x, isA<ResizeImage>());
      final resizedAt2x = imageAt2x as ResizeImage;
      expect(resizedAt2x.width, 164);
      expect(resizedAt2x.height, 124);
      expect(resizedAt2x.imageProvider, isA<FileImage>());

      await pumpThumbnail(
        tester,
        relativePath: relativePath,
        mediaService: mediaService,
        devicePixelRatio: 1.5,
        width: 100.0,
        height: 75.0,
      );

      final imageAt15x = tester.widget<Image>(find.byType(Image)).image;
      expect(imageAt15x, isA<ResizeImage>());
      final resizedAt15x = imageAt15x as ResizeImage;
      expect(resizedAt15x.width, 150);
      expect(resizedAt15x.height, 113);
    });
  });

  group('TimelineScreen media sandbox warmup', () {
    testWidgets('warms MediaSandboxService.getBaseDirectory once during init before WetMountedThumbnail mounts', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async => db.close());

      const relativePath = 'media/timeline_warm.webp';
      File('${tempDir.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      final now = DateTime(2026, 11, 20, 10, 30);
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_warm_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('西湖晨行'),
          contentDelta: jsonEncode([
            {'insert': '清晨沿苏堤漫步，湖面薄雾未散。\n'}
          ]),
          plainText: '清晨沿苏堤漫步，湖面薄雾未散。',
          entryDate: now,
        ),
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'media_warm_1',
        entryId: 'entry_warm_1',
        relativePath: relativePath,
      );

      var baseDirLookups = 0;
      final mediaService = MediaSandboxService(
        baseDirProvider: () async {
          baseDirLookups++;
          return tempDir;
        },
      );
      final diaryChanged = ChangeNotifier();
      addTearDown(diaryChanged.dispose);

      await pumpTimelineScreen(
        tester,
        database: db,
        mediaService: mediaService,
        scenerySettingsService: ScenerySettingsService(
          storage: MockSecureStorage(),
        ),
        enableSceneryAnimation: false,
        diaryChanged: diaryChanged,
        theme: InkDiaryTheme.light,
        surfaceSize: const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
      expect(baseDirLookups, 1);
      expect(mediaService.resolveFileSync(relativePath), isNotNull);

      final thumbFinder = find.byType(WetMountedThumbnail);
      expect(thumbFinder, findsOneWidget);
      expect(
        find.descendant(
          of: thumbFinder,
          matching: find.byType(FutureBuilder<File>),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: thumbFinder, matching: find.byType(Image)),
        findsOneWidget,
      );

      // Subsequent timeline reload does not warm getBaseDirectory again.
      diaryChanged.notifyListeners();
      await tester.pumpAndSettle();
      expect(baseDirLookups, 1);
    });
  });
}
