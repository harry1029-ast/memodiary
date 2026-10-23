import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/screens/album_collections_screen.dart';
import 'album_test_harness.dart';

void main() {
  late AlbumTestHarness harness;

  setUp(() async {
    harness = await AlbumTestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('AlbumCollectionsScreen Widget Tests', () {
    testWidgets('renders empty state and creates a collection via modal sheet', (tester) async {
      await pumpAlbumScreen(
        tester,
        AlbumCollectionsScreen(
          database: harness.database,
          mediaService: harness.mediaService,
          repository: harness.repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('尚无旅行影集'), findsOneWidget);
      expect(find.byKey(const Key('albums_empty_create_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('albums_empty_create_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('album_form_title')),
        '江南春行纪',
      );
      await tester.enterText(
        find.byKey(const Key('album_form_destination')),
        '江南',
      );
      await tester.enterText(
        find.byKey(const Key('album_form_route')),
        '杭州 → 乌镇 → 苏州',
      );
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pumpAndSettle();

      expect(find.text('江南春行纪'), findsOneWidget);
      expect(find.text('江南'), findsOneWidget);
      expect(find.text('杭州 → 乌镇 → 苏州'), findsOneWidget);
      expect(find.text('0 张'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders collection card with photo count and handles delete cancel vs confirm', (tester) async {
      final collection = await harness.repository.createCollection(
        title: '川西秘境录',
        destinationTag: '川西',
        routeSummary: '康定 → 新都桥 → 稻城',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 7),
      );
      final fullResFile = File('${harness.tempDir.path}/media/snow_mountain.webp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(kDeterministic1x1Png);
      final thumbFile = File('${harness.tempDir.path}/media/snow_mountain_thumb.webp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(kDeterministic1x1Png);

      await harness.repository.addPhoto(
        collectionId: collection.id,
        relativeImagePath: 'media/snow_mountain.webp',
        relativeThumbnailPath: 'media/snow_mountain_thumb.webp',
      );
      expect(fullResFile.existsSync(), isTrue);
      expect(thumbFile.existsSync(), isTrue);

      await pumpAlbumScreen(
        tester,
        AlbumCollectionsScreen(
          database: harness.database,
          mediaService: harness.mediaService,
          repository: harness.repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('album_card_${collection.id}')), findsOneWidget);
      expect(find.text('川西秘境录'), findsOneWidget);
      expect(find.text('川西'), findsOneWidget);
      expect(find.text('康定 → 新都桥 → 稻城'), findsOneWidget);
      expect(find.text('2026.10.01 – 10.07'), findsOneWidget);
      expect(find.text('1 张'), findsOneWidget);

      // Open contextual menu -> Delete -> Cancel
      await tester.tap(find.byKey(Key('album_card_menu_${collection.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除影集'));
      await tester.pumpAndSettle();

      expect(find.text('删除「川西秘境录」？'), findsOneWidget);
      await tester.tap(find.byKey(const Key('album_delete_cancel')));
      await tester.pumpAndSettle();

      // Collection and physical files still exist
      expect(find.text('川西秘境录'), findsOneWidget);
      expect(fullResFile.existsSync(), isTrue);

      // Open contextual menu -> Delete -> Confirm
      await tester.tap(find.byKey(Key('album_card_menu_${collection.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除影集'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('album_delete_confirm')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('尚无旅行影集'), findsOneWidget);
      expect(fullResFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
