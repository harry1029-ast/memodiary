import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

const _entryId = 'unmount_erase_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late StubEditorImagePicker picker;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('handscroll_unmount_erase_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    final photo = File('${tempDirectory.path}/picked_photo.png')..writeAsBytesSync(kValid1x1PngBytes);
    final video = File('${tempDirectory.path}/picked_video.mp4')..writeAsBytesSync(kValidMp4FtypBytes);
    picker = StubEditorImagePicker(
      imageResult: XFile(photo.path),
      videoResult: XFile(video.path),
    );

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('孤山访梅'),
            contentDelta: jsonEncode((Delta()..insert('疏影横斜。\n')).toJson()),
            plainText: '疏影横斜。',
            entryDate: DateTime(2026, 11, 6, 9),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        imagePicker: picker,
        viewportSize: _viewport,
      );

  Future<void> reopenEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditor(tester);
  }

  Future<void> collectPhoto(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相册选撷 · Photo Gallery'));
    await tester.pumpAndSettle();
  }

  /// Seeds [count] staged photos (attachments without mount markers) before opening.
  Future<void> seedStagedPhotos(int count) async {
    for (var index = 0; index < count; index++) {
      final relativePath = 'media/seeded_$index.webp';
      File('${tempDirectory.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      await database.attachMediaToEntry(
        id: 'seeded_$index',
        entryId: _entryId,
        relativePath: relativePath,
      );
    }
  }

  Future<List<MediaAttachment>> attachments() => database.getMediaForEntry(_entryId);
  Future<List<String>> attachmentIds() async => (await attachments()).map((row) => row.id).toList();

  Future<void> mount(WidgetTester tester, String mediaId) async {
    await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester, String mediaId) async {
    unmountTuckedPrint(tester, mediaId);
    await tester.pumpAndSettle();
  }

  Future<void> erase(WidgetTester tester, String mediaId) async {
    await tester.tap(find.byKey(Key('handscroll_erase_$mediaId')));
    await tester.pumpAndSettle();
  }

  /// Lets the erase undo window lapse so the deferred purge runs.
  Future<void> letUndoWindowLapse(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));
  Finder snackBarText(Pattern pattern) => find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(pattern),
      );

  group('Unmount ↩', () {
    testWidgets('returns a mounted item to the handscroll and removes its marker; the Tucked Prints have no delete', (tester) async {
      await openEditor(tester);
      await collectPhoto(tester);
      final mediaId = (await attachmentIds()).single;
      await mount(tester, mediaId);

      expect(find.descendant(of: tuckedPrintsFan, matching: find.byIcon(Icons.close)), findsNothing);

      await unmount(tester, mediaId);

      expect(tuckedPrint(mediaId), findsNothing);
      expect(tuckedPrintsFan, findsNothing);
      expect(handscrollItem(mediaId), findsOneWidget);

      await reopenEditor(tester);
      final savedEntry = await database.getEntryById(_entryId);
      expect(jsonDecode(savedEntry!.contentDelta), [
        {'insert': '疏影横斜。\n'},
      ]);
      expect(handscrollItem(mediaId), findsOneWidget);
      expect(await attachmentIds(), [mediaId]);
    });

    testWidgets('an unmounted item rejoins the handscroll in collect order', (tester) async {
      await openEditor(tester);
      await collectPhoto(tester);
      await collectPhoto(tester);
      final ids = await attachmentIds();
      await mount(tester, ids[0]);
      await unmount(tester, ids[0]);

      expect(
        tester.getTopLeft(handscrollItem(ids[0])).dx,
        lessThan(tester.getTopLeft(handscrollItem(ids[1])).dx),
      );
    });
  });

  group('Erase ✕ with undo', () {
    testWidgets('dissolves the item in place, leaves the others still, and offers undo', (tester) async {
      await seedStagedPhotos(3);
      await openEditor(tester);
      final firstLeft = tester.getTopLeft(handscrollItem('seeded_0'));

      await tester.tap(find.byKey(const Key('handscroll_erase_seeded_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-dissolve: the item is still in its slot, fading out as ink wash.
      expect(handscrollItem('seeded_1'), findsOneWidget);
      final fading = tester.widget<Opacity>(
        find.ancestor(of: handscrollItem('seeded_1'), matching: find.byKey(const Key('handscroll_dissolve_seeded_1'))).first,
      );
      expect(fading.opacity, lessThan(1.0));
      expect(fading.opacity, greaterThan(0.0));

      await tester.pumpAndSettle();
      expect(handscrollItem('seeded_1'), findsNothing);
      expect(tester.getTopLeft(handscrollItem('seeded_0')), firstLeft);
      expect(snackBarText('撤销'), findsOneWidget);
      // The record stays until the undo window passes.
      expect(await attachmentIds(), ['seeded_0', 'seeded_1', 'seeded_2']);
    });

    testWidgets('undo restores the item in place and keeps its record and file', (tester) async {
      await seedStagedPhotos(3);
      await openEditor(tester);
      await erase(tester, 'seeded_1');

      await tester.tap(find.widgetWithText(SnackBarAction, '撤销'));
      await tester.pumpAndSettle();
      await letUndoWindowLapse(tester);

      expect(handscrollItem('seeded_1'), findsOneWidget);
      final middle = tester.getTopLeft(handscrollItem('seeded_1')).dx;
      expect(tester.getTopLeft(handscrollItem('seeded_0')).dx, lessThan(middle));
      expect(tester.getTopLeft(handscrollItem('seeded_2')).dx, greaterThan(middle));
      expect(await attachmentIds(), ['seeded_0', 'seeded_1', 'seeded_2']);
      expect(File('${tempDirectory.path}/media/seeded_1.webp').existsSync(), isTrue);
    });

    testWidgets('after the undo window the record and sandbox file are purged and never resurface', (tester) async {
      await seedStagedPhotos(2);
      await openEditor(tester);
      await erase(tester, 'seeded_0');
      await letUndoWindowLapse(tester);

      expect(await attachmentIds(), ['seeded_1']);
      expect(File('${tempDirectory.path}/media/seeded_0.webp').existsSync(), isFalse);

      await reopenEditor(tester);
      expect(handscrollItem('seeded_0'), findsNothing);
      expect(handscrollItem('seeded_1'), findsOneWidget);
    });

    testWidgets('a second erase hides the first snackbar and both are purged', (tester) async {
      await seedStagedPhotos(3);
      await openEditor(tester);
      await erase(tester, 'seeded_0');
      await erase(tester, 'seeded_1');

      expect(find.byType(SnackBar), findsOneWidget);
      await letUndoWindowLapse(tester);

      expect(await attachmentIds(), ['seeded_2']);
    });
  });

  group('Capacity limits', () {
    testWidgets('collecting into a full handscroll is refused with 画卷已满 15 影', (tester) async {
      await seedStagedPhotos(15);
      await openEditor(tester);

      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      await tester.pumpAndSettle();

      expect(find.text('相册选撷 · Photo Gallery'), findsNothing);
      expect(snackBarText('画卷已满 15 影'), findsOneWidget);
      expect(await attachmentIds(), hasLength(15));

      await tester.tap(find.byKey(const Key('writing_dock_video_btn')));
      await tester.pumpAndSettle();
      expect(find.text('相册选取短影 · Video Gallery (≤60s)'), findsNothing);
      expect(snackBarText('画卷已满 15 影'), findsOneWidget);
      expect(await attachmentIds(), hasLength(15));
    });

    testWidgets('a multi-pick beyond the remaining room collects what fits and reports the rest', (tester) async {
      await seedStagedPhotos(13);
      final picks = [
        for (var index = 0; index < 4; index++)
          XFile((File('${tempDirectory.path}/multi_$index.png')..writeAsBytesSync(kValid1x1PngBytes)).path),
      ];
      picker = StubEditorImagePicker(multiImageResults: picks);
      await openEditor(tester);

      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('相册选撷 · Photo Gallery'));
      // Bounded pumps: the collected items are still being painted in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await attachmentIds(), hasLength(15));
      expect(snackBarText('2 影未入卷'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('mounting onto a sheet with three items is refused with a shake and the item stays staged', (tester) async {
      await seedStagedPhotos(4);
      await openEditor(tester);
      for (var index = 0; index < 3; index++) {
        await mount(tester, 'seeded_$index');
      }
      final restingLeft = tester.getTopLeft(tuckedPrint('seeded_0')).dx;

      await tester.tap(find.byKey(const Key('handscroll_mount_seeded_3')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(tuckedPrint('seeded_0')).dx, isNot(restingLeft));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(tuckedPrint('seeded_0')).dx, restingLeft);
      expect(snackBarText('本页已满三影'), findsOneWidget);
      expect(handscrollItem('seeded_3'), findsOneWidget);
      expect(tuckedPrint('seeded_3'), findsNothing);
    });
  });

  // The ↩ 揭回 control's target and label are covered with the fanned overlay (SPEC-011 ticket 07).
  testWidgets('✕ is at least 44×44 with a scoped label naming the item', (tester) async {
    final semantics = tester.ensureSemantics();
    await seedStagedPhotos(2);
    await openEditor(tester);
    await mount(tester, 'seeded_0');

    final size = tester.getSize(find.byKey(const Key('handscroll_erase_seeded_1')));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel(RegExp(r'^舍弃待贴第 1 影 · 影札$')), findsOneWidget);
    semantics.dispose();
  });
}
