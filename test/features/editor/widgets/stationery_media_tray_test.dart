import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import 'package:memodiary/features/editor/widgets/stationery_media_tray.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_silk_corner_mounts_painter.dart';
import '../../../helpers/editor_test_harness.dart';

void main() {
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('media_tray_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    // Seed mock image and video fixture files
    final photo1File = File('${tempDirectory.path}/media_photo_1.webp');
    photo1File.writeAsBytesSync(kValid1x1PngBytes);

    final photo2File = File('${tempDirectory.path}/media_photo_2.webp');
    photo2File.writeAsBytesSync(kValid1x1PngBytes);

    final videoFile = File('${tempDirectory.path}/media_video_1.mp4');
    videoFile.writeAsBytesSync(kValidMp4FtypBytes);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Widget buildTestableTray({
    required List<SheetMediaItem> items,
    ValueChanged<SheetMediaItem>? onTapMedia,
    ValueChanged<String>? onDeleteItem,
    bool isPaperDark = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 220,
            child: StationeryMediaTray(
              items: items,
              mediaSandboxService: sandboxService,
              onTapMedia: onTapMedia,
              onDeleteItem: onDeleteItem,
              isPaperDark: isPaperDark,
            ),
          ),
        ),
      ),
    );
  }

  group('StationeryMediaTray Component Tests (Seam 1)', () {
    testWidgets('renders empty shrink widget when items list is empty', (tester) async {
      await tester.pumpWidget(buildTestableTray(items: const []));
      await tester.pumpAndSettle();

      expect(find.byType(StationeryMediaTray), findsOneWidget);
      expect(find.byKey(const Key('stationery_media_tray_content')), findsNothing);
    });

    testWidgets('renders single media item with paper-toned matte border and silk corners', (tester) async {
      final items = [
        const SheetMediaItem(
          id: 'item_1',
          mediaType: EphemeraMediaType.image,
          relativePath: 'media_photo_1.webp',
          caption: '西湖初雪',
        ),
      ];

      await tester.pumpWidget(buildTestableTray(items: items));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stationery_media_tray_content')), findsOneWidget);
      expect(find.text('西湖初雪'), findsOneWidget);

      // Silk corner mounts painter verification
      expect(find.byType(CustomPaint), findsWidgets);
      final hasSilkCorners = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).any(
            (paint) => paint.painter is FolioSilkCornerMountsPainter,
          );
      expect(hasSilkCorners, isTrue, reason: 'Media tray cards must feature classical silk corner mounts');

      // Zero pagination dots for single-item trays
      expect(find.byKey(const Key('media_tray_indicator_dots')), findsNothing);
    });

    testWidgets('renders horizontal snap deck with pagination dots for multiple items (up to 3)', (tester) async {
      final items = [
        const SheetMediaItem(
          id: 'item_1',
          mediaType: EphemeraMediaType.image,
          relativePath: 'media_photo_1.webp',
          caption: '断桥残雪',
        ),
        const SheetMediaItem(
          id: 'item_2',
          mediaType: EphemeraMediaType.image,
          relativePath: 'media_photo_2.webp',
          caption: '平湖秋月',
        ),
        const SheetMediaItem(
          id: 'item_3',
          mediaType: EphemeraMediaType.video,
          relativePath: 'media_video_1.mp4',
          caption: '柳浪闻莺 (短影)',
        ),
      ];

      await tester.pumpWidget(buildTestableTray(items: items));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stationery_media_tray_content')), findsOneWidget);
      expect(find.byKey(const Key('media_tray_indicator_dots')), findsOneWidget);
      expect(find.text('断桥残雪'), findsOneWidget);

      // Verify indicator dot count matches items length
      expect(find.byKey(const Key('media_tray_dot_0')), findsOneWidget);
      expect(find.byKey(const Key('media_tray_dot_1')), findsOneWidget);
      expect(find.byKey(const Key('media_tray_dot_2')), findsOneWidget);
    });

    testWidgets('tapping media triggers onTapMedia callback and opens Fullscreen Lightbox', (tester) async {
      SheetMediaItem? tappedItem;
      final items = [
        const SheetMediaItem(
          id: 'item_1',
          mediaType: EphemeraMediaType.image,
          relativePath: 'media_photo_1.webp',
          caption: '灵隐晨钟',
        ),
      ];

      await tester.pumpWidget(
        buildTestableTray(
          items: items,
          onTapMedia: (item) {
            tappedItem = item;
          },
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('media_tray_card_item_1'));
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(tappedItem, isNotNull);
      expect(tappedItem!.id, equals('item_1'));
      expect(tappedItem!.caption, equals('灵隐晨钟'));
    });

    testWidgets('tapping delete button fires onDeleteItem callback', (tester) async {
      String? deletedId;
      final items = [
        const SheetMediaItem(
          id: 'item_to_delete',
          mediaType: EphemeraMediaType.image,
          relativePath: 'media_photo_1.webp',
          caption: '待删影札',
        ),
      ];

      await tester.pumpWidget(
        buildTestableTray(
          items: items,
          onDeleteItem: (id) {
            deletedId = id;
          },
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.byKey(const Key('media_tray_delete_item_to_delete'));
      expect(deleteBtnFinder, findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(deletedId, equals('item_to_delete'));
    });

    testWidgets('shows caption read-only; captions are edited only in the lightbox', (tester) async {
      final items = [
        const SheetMediaItem(
          id: 'item_caption_read_only',
          mediaType: EphemeraMediaType.image,
          relativePath: 'media_photo_1.webp',
          caption: '初始题注',
        ),
      ];

      await tester.pumpWidget(buildTestableTray(items: items));
      await tester.pumpAndSettle();

      final captionFinder = find.byKey(const Key('media_tray_caption_item_caption_read_only'));
      expect(captionFinder, findsOneWidget);
      expect(find.text('初始题注'), findsOneWidget);

      await tester.tap(captionFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('FullscreenMediaLightbox Viewer Tests', () {
    testWidgets('renders distraction-free viewer with pinch-to-zoom interactive viewer and close button', (tester) async {
      const item = SheetMediaItem(
        id: 'lightbox_test_item',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media_photo_1.webp',
        caption: '钱塘江潮',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () {
                  FullscreenMediaLightbox.show(
                    innerContext,
                    item: item,
                    mediaSandboxService: sandboxService,
                  );
                },
                child: const Text('Open Lightbox'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Lightbox'));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
      expect(find.text('钱塘江潮'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Close button dismisses lightbox
      final closeButton = find.byKey(const Key('fullscreen_lightbox_close_button'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsNothing);
    });
  });
}
