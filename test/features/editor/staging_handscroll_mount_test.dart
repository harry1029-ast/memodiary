import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_workstation.dart';
import 'package:memodiary/features/editor/widgets/tucked_prints/tucked_prints_fan.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'handscroll_entry';
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
    tempDirectory = Directory.systemTemp.createTempSync('handscroll_mount_test_');
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
            title: const Value('西湖夜游'),
            contentDelta: jsonEncode((Delta()..insert('断桥残雪。\n')).toJson()),
            plainText: '断桥残雪。',
            entryDate: DateTime(2026, 11, 5, 20),
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

  Future<void> collectVideo(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('writing_dock_video_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相册选取短影 · Video Gallery (≤60s)'));
    await tester.pumpAndSettle();
  }

  Future<List<String>> attachmentIds() async =>
      (await database.getMediaForEntry(_entryId)).map((attachment) => attachment.id).toList();

  Future<void> mount(WidgetTester tester, String mediaId) async {
    await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
    await tester.pumpAndSettle();
  }

  Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));

  group('Staging Handscroll: Collect → Mount via 📌 → Reopen', () {
    testWidgets('picked photo and video are collected into the handscroll left to right in collect order', (tester) async {
      await openEditor(tester);
      expect(find.byKey(const Key('staging_handscroll')), findsNothing);

      await collectPhoto(tester);
      await collectVideo(tester);

      final ids = await attachmentIds();
      expect(ids, hasLength(2));
      expect(find.byKey(const Key('staging_handscroll')), findsOneWidget);
      expect(handscrollItem(ids[0]), findsOneWidget);
      expect(handscrollItem(ids[1]), findsOneWidget);
      expect(
        tester.getTopLeft(handscrollItem(ids[0])).dx,
        lessThan(tester.getTopLeft(handscrollItem(ids[1])).dx),
      );

      // Nothing is mounted until the diarist chooses to.
      expect(tuckedPrintsFan, findsNothing);
    });

    testWidgets('📌 mounts items onto the active sheet as Tucked Prints in mount order without changing line capacity', (tester) async {
      await openEditor(tester);
      await collectPhoto(tester);
      await collectPhoto(tester);
      final ids = await attachmentIds();

      await mount(tester, ids[1]);
      await mount(tester, ids[0]);

      expect(find.byKey(const Key('staging_handscroll')), findsNothing);
      expect(handscrollItem(ids[0]), findsNothing);
      expect(tuckedPrint(ids[0]), findsOneWidget);
      expect(tuckedPrint(ids[1]), findsOneWidget);
      expect(
        tester.getTopLeft(tuckedPrint(ids[1])).dx,
        lessThan(tester.getTopLeft(tuckedPrint(ids[0])).dx),
      );
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      expect(editor.controller.document.toPlainText(), startsWith('断桥残雪。'));
    });

    testWidgets('a newly mounted print slides down into the sheet edge', (tester) async {
      await openEditor(tester);
      await collectPhoto(tester);
      final mediaId = (await attachmentIds()).single;

      await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final arrivingTop = tester.getRect(tuckedPrint(mediaId)).top;

      await tester.pumpAndSettle();
      final restingTop = tester.getRect(tuckedPrint(mediaId)).top;
      expect(arrivingTop, lessThan(restingTop - 1.0));
    });

    testWidgets('mounting onto a full opening sheet never spills its 10 rows onto a new sheet', (tester) async {
      final tenLines = List.generate(10, (index) => '第$index行').join('\n');
      await database.updateEntryContent(
        _entryId,
        jsonEncode((Delta()..insert('$tenLines\n')).toJson()),
        tenLines,
      );
      await openEditor(tester);
      expect(find.text('第 1 / 1 页'), findsOneWidget);

      await collectPhoto(tester);
      final ids = await attachmentIds();
      await mount(tester, ids.single);

      expect(tuckedPrint(ids.single), findsOneWidget);
      expect(find.text('第 1 / 1 页'), findsOneWidget);
    });

    testWidgets('mounting on a full 14-row continuation sheet keeps it there across reopen', (tester) async {
      final openingLines = List.generate(10, (index) => '首页$index').join('\n');
      final continuationLines = List.generate(14, (index) => '次页$index').join('\n');
      await database.updateEntryContent(
        _entryId,
        jsonEncode((Delta()..insert('$openingLines\n$continuationLines\n')).toJson()),
        '$openingLines\n$continuationLines',
      );
      await openEditor(tester);
      expect(find.text('第 1 / 2 页'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
      await collectPhoto(tester);
      final ids = await attachmentIds();
      await mount(tester, ids.single);

      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(tuckedPrint(ids.single), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      await tester.pumpAndSettle();
      await reopenEditor(tester);

      expect(find.text('第 1 / 2 页'), findsOneWidget);
      expect(tuckedPrintsFan, findsNothing);
      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
      expect(tuckedPrint(ids.single), findsOneWidget);
      expect(find.byKey(const Key('staging_handscroll')), findsNothing);
    });

    testWidgets('save → leave → reopen preserves mounted placement and staged items', (tester) async {
      await openEditor(tester);
      await collectPhoto(tester);
      await collectVideo(tester);
      final ids = await attachmentIds();
      await mount(tester, ids[0]);

      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      await tester.pumpAndSettle();

      final savedEntry = await database.getEntryById(_entryId);
      final savedAttachments = await database.getMediaForEntry(_entryId);
      final savedOps = jsonDecode(savedEntry!.contentDelta) as List<dynamic>;
      expect(savedOps, [
        {'insert': '断桥残雪。'},
        {
          'insert': {'mount': ids[0]},
        },
        {'insert': '\n'},
      ]);
      expect(savedEntry.plainText, '断桥残雪。');

      await reopenEditor(tester);

      expect(tuckedPrint(ids[0]), findsOneWidget);
      expect(handscrollItem(ids[0]), findsNothing);
      expect(handscrollItem(ids[1]), findsOneWidget);

      // Reopening alone writes nothing: deep parity on Delta and attachment rows.
      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      await tester.pumpAndSettle();
      final reopenedEntry = await database.getEntryById(_entryId);
      expect(reopenedEntry!.contentDelta, savedEntry.contentDelta);
      expect(reopenedEntry.plainText, savedEntry.plainText);
      expect(await database.getMediaForEntry(_entryId), savedAttachments);
    });

    testWidgets('tapping a handscroll item or the Tucked Prints opens the fullscreen lightbox', (tester) async {
      await openEditor(tester);
      await collectPhoto(tester);
      await collectPhoto(tester);
      final ids = await attachmentIds();
      await mount(tester, ids[0]);

      await tester.tap(handscrollItem(ids[1]));
      await tester.pumpAndSettle();
      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
      await tester.tap(find.byKey(const Key('fullscreen_lightbox_close_button')));
      await tester.pumpAndSettle();
      expect(find.byType(FullscreenMediaLightbox), findsNothing);

      await tester.tap(tuckedPrintsFan);
      await tester.pumpAndSettle();
      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
    });

    testWidgets('📌 and the Tucked Prints are at least 44×44 with scoped semantic labels', (tester) async {
      final semantics = tester.ensureSemantics();
      await openEditor(tester);
      await collectPhoto(tester);
      await collectPhoto(tester);
      final ids = await attachmentIds();
      await mount(tester, ids[0]);

      await expectAccessibleTapTargets(tester, within: find.byWidgetPredicate((widget) => widget is TuckedPrintsFan || widget is DeskWorkstation));
      final pinSize = tester.getSize(find.byKey(Key('handscroll_mount_${ids[1]}')));
      expect(pinSize.width, greaterThanOrEqualTo(44));
      expect(pinSize.height, greaterThanOrEqualTo(44));
      final fanSize = tester.getSize(tuckedPrintsFan);
      expect(fanSize.width, greaterThanOrEqualTo(44));
      expect(fanSize.height, greaterThanOrEqualTo(44));

      expect(find.bySemanticsLabel(RegExp(r'贴至本页.*第 1 页')), findsOneWidget);
      expect(find.bySemanticsLabel('本页夹页影札 1 枚，轻触展开'), findsOneWidget);
      semantics.dispose();
    });
  });
}
