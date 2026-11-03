import 'dart:async';
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
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/stationery_ephemera_sheet.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_pagination_engine.dart';

class _FakeVideoPlatform extends VideoPlayerPlatform {
  final StreamController<VideoEvent> _eventController = StreamController<VideoEvent>.broadcast();

  @override
  Future<void> init() async {}
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<int?> create(DataSource dataSource) async => 0;
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _eventController.stream;
  @override
  Widget buildView(int playerId) => const SizedBox(key: ValueKey('fake_video_view'));
}

class _TestImagePicker extends ImagePicker {
  final XFile? imageResult;

  _TestImagePicker({this.imageResult});

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => imageResult;

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async => null;
}

const _validPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class _SyncMediaSandboxService extends MediaSandboxService {
  final Directory tempDir;

  _SyncMediaSandboxService({required this.tempDir})
      : super(baseDirProvider: () async => tempDir);

  @override
  Future<String> copyAndCompressImage(File sourceFile) async {
    final mediaDir = Directory('${tempDir.path}/media');
    if (!mediaDir.existsSync()) {
      mediaDir.createSync(recursive: true);
    }
    final targetFileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.webp';
    final targetRelativePath = 'media/$targetFileName';
    final targetFile = File('${tempDir.path}/$targetRelativePath');
    if (sourceFile.existsSync()) {
      sourceFile.copySync(targetFile.path);
    } else {
      targetFile.writeAsBytesSync(_validPngBytes);
    }
    return targetRelativePath;
  }

  @override
  Future<VideoSandboxResult> copyAndSandboxVideo(
    File sourceFile, {
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    final mediaDir = Directory('${tempDir.path}/media');
    if (!mediaDir.existsSync()) {
      mediaDir.createSync(recursive: true);
    }
    final targetFileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final targetRelativePath = 'media/$targetFileName';
    final targetFile = File('${tempDir.path}/$targetRelativePath');
    if (sourceFile.existsSync()) {
      sourceFile.copySync(targetFile.path);
    } else {
      targetFile.writeAsBytesSync([0x00, 0x00, 0x00, 0x20]);
    }
    return VideoSandboxResult(
      relativePath: targetRelativePath,
      thumbnailPath: '',
      durationSeconds: 10,
    );
  }

  @override
  Future<File> getFileFromRelativePath(String relativePath) async {
    final file = File('${tempDir.path}/$relativePath');
    if (!file.existsSync()) {
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      file.writeAsBytesSync(_validPngBytes);
    }
    return file;
  }
}

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = _FakeVideoPlatform();
  });

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('ephemera_folio_test_');
    sandboxService = _SyncMediaSandboxService(tempDir: tempDirectory);

    await database.into(database.entries).insert(
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
    testWidgets('photo and video ephemera sheet insertion and deletion lifecycle', (tester) async {
      final sampleImageFile = File('${tempDirectory.path}/sample_photo.png');
      sampleImageFile.writeAsBytesSync(_validPngBytes);

      final testPicker = _TestImagePicker(
        imageResult: XFile(sampleImageFile.path),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'ephemera_folio_entry',
            imagePicker: testPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 1 页'), findsOneWidget);

      // Tap photo tool in WritingDock
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      await tester.pumpAndSettle();

      // Tap photo gallery option in bottom sheet
      expect(find.text('相册选撷 · Photo Gallery'), findsOneWidget);
      await tester.tap(find.text('相册选撷 · Photo Gallery'));
      await tester.pumpAndSettle();

      // Dedicated EphemeraSheet is allocated and PageView slides to 第 2 / 2 页
      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(find.byType(StationeryEphemeraSheet), findsOneWidget);
      expect(find.byKey(const Key('editor_remove_ephemera_btn')), findsOneWidget);

      // Delete the ephemera sheet
      await tester.tap(find.byKey(const Key('editor_remove_ephemera_btn')));
      await tester.pumpAndSettle();

      // Sheet collapses back to Sheet 1 (第 1 / 1 页)
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(find.byType(StationeryEphemeraSheet), findsNothing);
    });

    testWidgets('Scholar Chest template switch re-paginates live without delta loss', (tester) async {
      // Seed with 15 lines of content
      final initialDelta = Delta();
      for (int index = 1; index <= 15; index++) {
        initialDelta.insert('第${index.toString().padLeft(2, '0')}行测试文心素笺墨格内容\n');
      }

      await database.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode(initialDelta.toJson()),
        '15 lines text',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'ephemera_folio_entry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 2 页'), findsOneWidget);

      // Open Scholar's Stationery Chest
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();

      // Select Lined Paper template
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      // Dismiss drawer
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      // Database entry content must be 100% preserved
      final savedEntry = await database.getEntryById('ephemera_folio_entry');
      expect(savedEntry, isNotNull);
      expect(savedEntry!.templateId, equals('template_lined_paper'));
      expect(savedEntry.contentDelta, contains('第01行'));
      expect(savedEntry.contentDelta, contains('第15行'));
    });

    testWidgets('lossless round-trip parity between paginated editor and Thread-Bound Folio preview', (tester) async {
      // Build a multi-sheet entry with text and media embeds
      final unifiedDelta = Delta()
        ..insert('兰亭清话，暮春之初，修禊事也。\n')
        ..insert({'image': 'media/photo_autumn_mount.webp'})
        ..insert('\n')
        ..insert('后之视今，亦犹今之视昔，悲夫！故列叙时人，录其所谓。\n');

      final plainText = '兰亭清话，暮春之初，修禊事也。\n后之视今，亦犹今之视昔，悲夫！故列叙时人，录其所谓。';

      await database.updateEntryContent(
        'ephemera_folio_entry',
        jsonEncode(unifiedDelta.toJson()),
        plainText,
      );

      // Add corresponding MediaAttachment in SQLite
      await database.attachMediaToEntry(
        id: 'media_autumn_1',
        entryId: 'ephemera_folio_entry',
        relativePath: 'media/photo_autumn_mount.webp',
        mediaType: 'image',
      );

      // Open in EntryEditorScreen
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'ephemera_folio_entry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In editor: Sheet 1 is OpeningSheet, Sheet 2 is EphemeraSheet, Sheet 3 is ContinuationSheet
      expect(find.text('第 1 / 3 页'), findsOneWidget);
      expect(find.byType(JournalLetterhead), findsOneWidget);

      // Navigate to Sheet 2 (EphemeraSheet)
      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(find.byType(StationeryEphemeraSheet), findsOneWidget);

      // Navigate to Sheet 3 (ContinuationSheet)
      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第 3 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);

      // Verify Round-Trip Parity with FolioPaginationEngine
      final entryFromDatabase = await database.getEntryById('ephemera_folio_entry');
      final attachments = await database.getMediaForEntry('ephemera_folio_entry');

      final folioLeaves = FolioPaginationEngine.paginate(
        entry: entryFromDatabase!,
        attachments: attachments,
      );

      // Folio produces:
      // Leaf 0: Frontispiece Cover Leaf
      // Leaf 1: Content Body Leaf ('兰亭清话...')
      // Leaf 2: Tipped-In Ephemera Leaf ('media/photo_autumn_mount.webp')
      // Leaf 3: Content Body Leaf ('后之视今...')
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
  });
}
