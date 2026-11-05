import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'drag_mount_entry';
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
    tempDirectory = Directory.systemTemp.createTempSync('handscroll_drag_mount_test_');
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

  Future<void> mount(WidgetTester tester, String mediaId) async {
    await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
    await tester.pumpAndSettle();
  }

  Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));
  Finder stripItem(String mediaId) => find.byKey(Key('mount_strip_item_$mediaId'));
  Finder snackBarText(Pattern pattern) => find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(pattern),
      );

  /// Long-presses [mediaId]'s print and drags it to [target], returning the
  /// still-held gesture so a test can inspect the hover state before release.
  Future<TestGesture> dragItemTo(WidgetTester tester, String mediaId, Offset target) async {
    final gesture = await tester.startGesture(tester.getCenter(handscrollItem(mediaId)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 50));
    return gesture;
  }

  Offset sheetCenter(WidgetTester tester) => tester.getCenter(find.byKey(const Key('sheet_drop_target_0')));

  group('Long-press drag mount', () {
    testWidgets('hovering highlights the sheet; dropping mounts the item exactly as 📌 does and survives reopen',
        (tester) async {
      await seedStagedPhotos(2);
      await openEditor(tester);
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);

      final gesture = await dragItemTo(tester, 'seeded_0', sheetCenter(tester));
      expect(find.byKey(const Key('sheet_drop_highlight')), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);
      expect(stripItem('seeded_0'), findsOneWidget);
      expect(handscrollItem('seeded_0'), findsNothing);
      expect(handscrollItem('seeded_1'), findsOneWidget);

      await reopenEditor(tester);
      expect(stripItem('seeded_0'), findsOneWidget);
    });

    testWidgets('dropping onto a full sheet is refused with a shake and SnackBar; the item stays staged',
        (tester) async {
      await seedStagedPhotos(4);
      await openEditor(tester);
      for (var index = 0; index < 3; index++) {
        await mount(tester, 'seeded_$index');
      }
      final restingLeft = tester.getTopLeft(stripItem('seeded_0')).dx;

      final gesture = await dragItemTo(tester, 'seeded_3', sheetCenter(tester));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(stripItem('seeded_0')).dx, isNot(restingLeft));

      await tester.pumpAndSettle();
      expect(snackBarText('本页已满三影'), findsOneWidget);
      expect(handscrollItem('seeded_3'), findsOneWidget);
      expect(stripItem('seeded_3'), findsNothing);
    });

    testWidgets('dropping outside the sheet cancels with no change', (tester) async {
      await seedStagedPhotos(1);
      await openEditor(tester);

      final gesture = await dragItemTo(tester, 'seeded_0', const Offset(180.0, 4.0));
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(handscrollItem('seeded_0'), findsOneWidget);
      expect(stripItem('seeded_0'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a plain tap still opens the lightbox', (tester) async {
      await seedStagedPhotos(1);
      await openEditor(tester);

      await tester.tap(handscrollItem('seeded_0'));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
    });

    testWidgets('a horizontal swipe scrolls the handscroll instead of dragging', (tester) async {
      await seedStagedPhotos(6);
      await openEditor(tester);
      final restingLeft = tester.getTopLeft(handscrollItem('seeded_1')).dx;

      await tester.drag(handscrollItem('seeded_1'), const Offset(-200.0, 0.0));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(handscrollItem('seeded_1')).dx, lessThan(restingLeft));
      expect(find.byKey(const Key('sheet_drop_highlight')), findsNothing);
      expect(stripItem('seeded_1'), findsNothing);
    });

    testWidgets('📌 stays the accessible equivalent at 44px', (tester) async {
      final semantics = tester.ensureSemantics();
      await seedStagedPhotos(1);
      await openEditor(tester);

      await expectAccessibleTapTargets(tester, within: find.byKey(const Key('handscroll_mount_seeded_0')));
      await mount(tester, 'seeded_0');
      expect(stripItem('seeded_0'), findsOneWidget);
      semantics.dispose();
    });
  });
}
