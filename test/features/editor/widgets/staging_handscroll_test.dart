import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/desk_media_handlers.dart';
import 'package:memodiary/features/editor/widgets/sheet_mount_strip.dart';
import 'package:memodiary/features/editor/widgets/staging_handscroll.dart';
import '../../../helpers/editor_test_harness.dart';

const _items = [
  SheetMediaItem(id: 'item_1', mediaType: EphemeraMediaType.image, relativePath: 'media_photo_1.webp'),
  SheetMediaItem(id: 'item_2', mediaType: EphemeraMediaType.image, relativePath: 'media_photo_2.webp'),
  SheetMediaItem(id: 'item_3', mediaType: EphemeraMediaType.video, relativePath: 'media_video_1.mp4'),
  SheetMediaItem(id: 'item_4', mediaType: EphemeraMediaType.image, relativePath: 'media_photo_1.webp'),
];

void main() {
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('handscroll_widget_test_');
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

  Widget host(Widget child) => MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 360, height: 160, child: child)),
        ),
      );

  group('StagingHandscroll', () {
    testWidgets('renders nothing when no item is staged', (tester) async {
      await tester.pumpWidget(host(StagingHandscroll(
        items: const [],
        mediaSandboxService: sandboxService,
        activeSheetNumber: 1,
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staging_handscroll')), findsNothing);
    });

    testWidgets('shows about three slots at once and scrolls sideways to the rest', (tester) async {
      await tester.pumpWidget(host(StagingHandscroll(
        items: _items,
        mediaSandboxService: sandboxService,
        activeSheetNumber: 1,
      )));
      await tester.pumpAndSettle();

      final handscrollRect = tester.getRect(find.byKey(const Key('staging_handscroll')));
      bool isVisible(String id) {
        final finder = find.byKey(Key('handscroll_item_$id'));
        return finder.evaluate().isNotEmpty &&
            tester.getRect(finder).left < handscrollRect.right &&
            tester.getRect(finder).right <= handscrollRect.right + 0.5;
      }

      expect(['item_1', 'item_2', 'item_3'].every(isVisible), isTrue);
      expect(isVisible('item_4'), isFalse);

      await tester.drag(find.byKey(const Key('staging_handscroll')), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(isVisible('item_4'), isTrue);
    });

    testWidgets('tap, 📌 and ✕ report the item they belong to', (tester) async {
      final tapped = <String>[];
      final mounted = <String>[];
      final erased = <String>[];
      await tester.pumpWidget(host(StagingHandscroll(
        items: _items.take(2).toList(),
        mediaSandboxService: sandboxService,
        activeSheetNumber: 2,
        onTapItem: (item) => tapped.add(item.id),
        handlers: DeskMediaHandlers(onMount: mounted.add, onErase: erased.add),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('handscroll_item_item_2')));
      await tester.tap(find.byKey(const Key('handscroll_mount_item_1')));
      await tester.tap(find.byKey(const Key('handscroll_erase_item_2')));
      // ✕ reports the erase once the ink-wash dissolve has played.
      expect(erased, isEmpty);
      await tester.pumpAndSettle();

      expect(tapped, ['item_2']);
      expect(mounted, ['item_1']);
      expect(erased, ['item_2']);
    });

    testWidgets('📌 names the item and the target sheet for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(StagingHandscroll(
        items: _items.take(2).toList(),
        mediaSandboxService: sandboxService,
        activeSheetNumber: 3,
      )));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('贴至本页：待贴第 2 影 → 第 3 页'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('SheetMountStrip', () {
    testWidgets('renders nothing when the sheet has no mounted items', (tester) async {
      await tester.pumpWidget(host(SheetMountStrip(
        items: const [],
        mediaSandboxService: sandboxService,
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sheet_mount_strip')), findsNothing);
    });

    testWidgets('shows mounted items in order and has no delete control', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(host(SheetMountStrip(
        items: _items.take(3).toList(),
        mediaSandboxService: sandboxService,
        onTapItem: (item) => tapped.add(item.id),
      )));
      await tester.pumpAndSettle();

      final lefts = ['item_1', 'item_2', 'item_3']
          .map((id) => tester.getTopLeft(find.byKey(Key('mount_strip_item_$id'))).dx)
          .toList();
      expect(lefts, orderedEquals([...lefts]..sort()));
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      await tester.tap(find.byKey(const Key('mount_strip_item_item_3')));
      expect(tapped, ['item_3']);
    });
  });
}
