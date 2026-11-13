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
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/stationery_ephemera_sheet.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_pagination_engine.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('ephemera_folio_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'ephemera_folio_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('暮秋兰亭记'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 4, 16, 20),
            mood: const Value(5),
            weather: const Value('晴 · 晚霞'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Paginated Editor - Ephemera Lifecycle, Chest & Folio Parity Tests', () {
    testWidgets('deleted photo keepsake removes SQLite attachment and never resurrects on reload or Folio paginate', (tester) async {
      final sampleImageFile = File('${tempDirectory.path}/sample_photo.png')
        ..writeAsBytesSync(kValid1x1PngBytes);

      final stubPicker = StubEditorImagePicker(
        imageResult: XFile(sampleImageFile.path),
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
        imagePicker: stubPicker,
        viewportSize: const Size(360.0, 780.0),
      );

      expect(find.text('第 1 / 1 页'), findsOneWidget);

      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('相册选撷 · Photo Gallery'));
      await tester.pumpAndSettle();

      // The picked photo is collected into the Staging Handscroll, not onto a sheet
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(find.byKey(const Key('staging_handscroll')), findsOneWidget);

      final attachmentsBeforeDelete = await database.mediaOcrDao.getMediaForEntry('ephemera_folio_entry');
      expect(attachmentsBeforeDelete, hasLength(1));

      // Erase the photo from the Staging Handscroll
      final eraseBtnFinder = find.byKey(Key('handscroll_erase_${attachmentsBeforeDelete.first.id}'));
      expect(eraseBtnFinder, findsOneWidget);
      await tester.tap(eraseBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staging_handscroll')), findsNothing);

      // The record is purged once the erase undo window lapses
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      // Verify SQLite media_attachments row is deleted
      final attachmentsAfterDelete = await database.mediaOcrDao.getMediaForEntry('ephemera_folio_entry');
      expect(attachmentsAfterDelete, isEmpty);

      // Verify FolioPaginationEngine does NOT resurrect deleted ephemera
      final updatedEntry = await database.entriesDao.getEntryById('ephemera_folio_entry');
      final folioLeaves = FolioPaginationEngine.paginate(
        entry: updatedEntry!,
        attachments: attachmentsAfterDelete,
      );
      expect(folioLeaves.whereType<FolioTippedInEphemeraLeaf>(), isEmpty);

      // Reload EntryEditorScreen fresh and verify deleted ephemera stays gone
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
        viewportSize: const Size(360.0, 780.0),
      );
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(find.byKey(const Key('staging_handscroll')), findsNothing);
    });

    testWidgets('collecting a photo mid-sheet preserves uninterrupted prose and fills the handscroll', (tester) async {
      final initialDelta = Delta()..insert('上卷春风十里。\n下卷秋水人家。\n');
      await database.entriesDao.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode(initialDelta.toJson()),
        '上卷春风十里。\n下卷秋水人家。',
      );

      final sampleImageFile = File('${tempDirectory.path}/mid_photo.png')
        ..writeAsBytesSync(kValid1x1PngBytes);
      final stubPicker = StubEditorImagePicker(
        imageResult: XFile(sampleImageFile.path),
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
        imagePicker: stubPicker,
        viewportSize: const Size(360.0, 780.0),
      );

      expect(find.text('第 1 / 1 页'), findsOneWidget);

      final openingEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      openingEditor.controller.updateSelection(
        const TextSelection.collapsed(offset: 8), // right after '上卷春风十里。\n'
        ChangeSource.local,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('相册选撷 · Photo Gallery'));
      await tester.pumpAndSettle();

      // Preserves uninterrupted prose on Sheet 1 while the photo waits in the handscroll
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(find.byKey(const Key('staging_handscroll')), findsOneWidget);

      final editorAfterAttach = tester.widget<QuillEditor>(find.byType(QuillEditor));
      expect(editorAfterAttach.controller.document.toPlainText().trim(), equals('上卷春风十里。\n下卷秋水人家。'));
    });

    testWidgets('invoking WritingDock sub-note action on EphemeraSheet allocates following text sheet', (tester) async {
      final initialDelta = Delta()
        ..insert('开篇首段墨迹。\n')
        ..insert({'image': 'media/existing_mount.webp'})
        ..insert('\n');

      await database.entriesDao.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode(initialDelta.toJson()),
        '开篇首段墨迹。',
      );
      await database.mediaOcrDao.attachMediaToEntry(
        id: 'media_existing_1',
        entryId: 'ephemera_folio_entry',
        relativePath: 'media/existing_mount.webp',
        mediaType: 'image',
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
      );

      expect(find.text('第 1 / 2 页'), findsOneWidget);

      // Open formatting ribbon while on Sheet 1, then navigate to Sheet 2 (EphemeraSheet)
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(find.byType(StationeryEphemeraSheet), findsOneWidget);

      // Tap interlinear sub-note button while viewing EphemeraSheet
      await tester.tap(find.byKey(const Key('writing_dock_interlinear_note_btn')));
      await tester.pumpAndSettle();

      // Must allocate and advance to Sheet 3 (following text sheet) rather than mutating Sheet 1
      expect(find.text('第 3 / 3 页'), findsOneWidget);
      final sheet3Editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      expect(sheet3Editor.controller.document.toPlainText(), contains('{夹注:}'));

      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      await tester.pumpAndSettle();

      final savedEntry = await database.entriesDao.getEntryById('ephemera_folio_entry');
      expect(savedEntry!.contentDelta, contains('{夹注:}'));
      // Verify '{夹注:}' was placed AFTER the image embed, leaving Sheet 1 prose intact
      final ops = jsonDecode(savedEntry.contentDelta) as List<dynamic>;
      expect(ops.first['insert'].toString().startsWith('开篇首段墨迹。'), isTrue);
    });

    testWidgets('Scholar Chest template switch re-paginates live without delta loss', (tester) async {
      final initialDelta = Delta();
      for (int index = 1; index <= 15; index++) {
        initialDelta.insert('第${index.toString().padLeft(2, '0')}行测试文心素笺墨格内容\n');
      }

      await database.entriesDao.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode(initialDelta.toJson()),
        '15 lines text',
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
      );

      expect(find.text('第 1 / 2 页'), findsOneWidget);

      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      final savedEntry = await database.entriesDao.getEntryById('ephemera_folio_entry');
      expect(savedEntry, isNotNull);
      expect(savedEntry!.templateId, equals('template_lined_paper'));
      expect(savedEntry.contentDelta, contains('第01行'));
      expect(savedEntry.contentDelta, contains('第15行'));
    });

    testWidgets('lossless round-trip parity between paginated editor and Thread-Bound Folio preview', (tester) async {
      final unifiedDelta = Delta()
        ..insert('兰亭清话，暮春之初，修禊事也。\n')
        ..insert({'image': 'media/photo_autumn_mount.webp'})
        ..insert('\n')
        ..insert('后之视今，亦犹今之视昔，悲夫！故列叙时人，录其所谓。\n');

      const plainText = '兰亭清话，暮春之初，修禊事也。\n后之视今，亦犹今之视昔，悲夫！故列叙时人，录其所谓。';

      await database.entriesDao.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode(unifiedDelta.toJson()),
        plainText,
      );

      await database.mediaOcrDao.attachMediaToEntry(
        id: 'media_autumn_1',
        entryId: 'ephemera_folio_entry',
        relativePath: 'media/photo_autumn_mount.webp',
        mediaType: 'image',
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
      );

      expect(find.text('第 1 / 3 页'), findsOneWidget);
      expect(find.byType(JournalLetterhead), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(find.byType(StationeryEphemeraSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
      expect(find.text('第 3 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);

      final entryFromDatabase = await database.entriesDao.getEntryById('ephemera_folio_entry');
      final attachments = await database.mediaOcrDao.getMediaForEntry('ephemera_folio_entry');

      final folioLeaves = FolioPaginationEngine.paginate(
        entry: entryFromDatabase!,
        attachments: attachments,
      );

      expect(folioLeaves.length, equals(4));
      expect(folioLeaves[0], isA<FolioFrontispieceCoverLeaf>());
      expect(folioLeaves[1], isA<FolioContentBodyLeaf>());
      expect(folioLeaves[2], isA<FolioTippedInEphemeraLeaf>());
      expect(folioLeaves[3], isA<FolioContentBodyLeaf>());

      final ephemeraLeaf = folioLeaves[2] as FolioTippedInEphemeraLeaf;
      expect(ephemeraLeaf.sandboxedRelativePath, equals('media/photo_autumn_mount.webp'));
      expect(ephemeraLeaf.mediaType, equals('image'));

      final concludingLeaf = folioLeaves[3] as FolioContentBodyLeaf;
      expect(concludingLeaf.isConcludingLeaf, isTrue);
    });

    testWidgets('Folio leaves carry exactly the items each editor sheet mounts; staged items stay out', (tester) async {
      final lines = List.generate(30, (index) => '第${index + 1}行墨迹').join('\n');
      await database.entriesDao.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode((Delta()..insert('$lines\n')).toJson()),
        lines,
      );
      final sampleImageFile = File('${tempDirectory.path}/parity_photo.png')
        ..writeAsBytesSync(kValid1x1PngBytes);

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'ephemera_folio_entry',
        imagePicker: StubEditorImagePicker(imageResult: XFile(sampleImageFile.path)),
        viewportSize: const Size(360.0, 780.0),
      );
      expect(find.text('第 1 / 3 页'), findsOneWidget);

      for (int pick = 0; pick < 3; pick++) {
        await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('相册选撷 · Photo Gallery'));
        await tester.pumpAndSettle();
      }
      final ids = (await database.mediaOcrDao.getMediaForEntry('ephemera_folio_entry')).map((media) => media.id).toList();
      expect(ids, hasLength(3));

      await tester.tap(find.byKey(Key('handscroll_mount_${ids[0]}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('handscroll_mount_${ids[1]}')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(tuckedPrint(ids[1]), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      await tester.pumpAndSettle();

      final savedEntry = await database.entriesDao.getEntryById('ephemera_folio_entry');
      final folioLeaves = FolioPaginationEngine.paginate(
        entry: savedEntry!,
        attachments: await database.mediaOcrDao.getMediaForEntry('ephemera_folio_entry'),
      );

      final cover = folioLeaves.first as FolioFrontispieceCoverLeaf;
      expect(cover.photos.map((photo) => photo.id), [ids[0]]);
      expect(
        folioLeaves.whereType<FolioContentBodyLeaf>().map((leaf) => leaf.photos.map((photo) => photo.id).toList()),
        [
          [ids[0]],
          [ids[1]],
          <String>[],
        ],
      );
      expect(folioLeaves.whereType<FolioTippedInEphemeraLeaf>(), isEmpty);
    });
  });
}
