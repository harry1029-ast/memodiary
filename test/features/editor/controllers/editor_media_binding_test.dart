import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/controllers/editor_media_binding.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

import '../../../helpers/editor_test_harness.dart';

class _FailingBatchMediaOcrDao extends MediaOcrDao {
  _FailingBatchMediaOcrDao(super.attachedDatabase);

  @override
  Future<void> attachMediaBatch({
    required String entryId,
    required List<MediaAttachmentDraft> attachments,
  }) async {
    throw StateError('Simulated SQLite batch failure');
  }
}

class _FailingDeleteMediaOcrDao extends MediaOcrDao {
  _FailingDeleteMediaOcrDao(super.attachedDatabase);

  @override
  Future<List<String>> deleteMediaForEntryByPath({
    required String entryId,
    required String relativePath,
  }) async {
    throw StateError('Simulated SQLite delete failure');
  }
}

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late EditorPaginationCoordinator coordinator;
  late EditorAutosaveManager autosaveManager;
  late EditorMediaBinding binding;
  late int stateChangedCount;

  const entryId = 'media_binding_entry';
  const stagedMediaId = 'staged_photo';
  const mountedMediaId = 'mounted_photo';

  EditorMediaBinding createBinding({
    MediaOcrDao? mediaOcrDao,
    MediaSandboxService? mediaSandboxService,
  }) {
    return EditorMediaBinding(
      mediaOcrDao: mediaOcrDao ?? database.mediaOcrDao,
      mediaSandboxService: mediaSandboxService ?? sandboxService,
      entryId: entryId,
      coordinator: coordinator,
      autosaveManager: autosaveManager,
      onStateChanged: () => stateChangedCount++,
    );
  }

  List<XFile> writeSourceImages(int count, {String prefix = 'src_img'}) {
    return [
      for (var index = 0; index < count; index++)
        XFile(
          (File('${tempDirectory.path}/${prefix}_$index.png')
                ..writeAsBytesSync(kValid1x1PngBytes))
              .path,
        ),
    ];
  }

  XFile writeSourceVideo({String name = 'src_video.mp4'}) {
    return XFile(
      (File('${tempDirectory.path}/$name')..writeAsBytesSync(kValidMp4FtypBytes))
          .path,
    );
  }

  List<String> listSandboxMediaRelativePaths() {
    final mediaDir = Directory('${tempDirectory.path}/media');
    if (!mediaDir.existsSync()) return const [];
    return mediaDir
        .listSync()
        .whereType<File>()
        .map((file) => 'media/${file.uri.pathSegments.last}')
        .toList()
      ..sort();
  }

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('media_binding_test_');
    sandboxService = SyncTestMediaSandboxService(
      tempDir: tempDirectory,
      generateVideoThumbnail: true,
    );
    stateChangedCount = 0;

    await database.entriesDao.createEntry(
      EntriesCompanion.insert(
        id: entryId,
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        contentDelta: jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
        plainText: '春江花月夜\n',
        entryDate: DateTime(2026, 11, 14, 10),
      ),
    );
    await database.mediaOcrDao.attachMediaToEntry(
      id: stagedMediaId,
      entryId: entryId,
      relativePath: 'media/staged.webp',
    );
    await database.mediaOcrDao.attachMediaToEntry(
      id: mountedMediaId,
      entryId: entryId,
      relativePath: 'media/mounted.webp',
    );

    final attachments = await database.mediaOcrDao.getMediaForEntry(entryId);
    coordinator = EditorPaginationCoordinator()
      ..initializeFromDelta(
        jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
        attachments: attachments,
      );
    expect(coordinator.mountOnActiveSheet(mountedMediaId), isTrue);

    autosaveManager = EditorAutosaveManager(
      database: database,
      entryId: entryId,
      coordinator: coordinator,
    );
    binding = createBinding();
  });

  tearDown(() async {
    binding.dispose();
    autosaveManager.dispose();
    coordinator.dispose();
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  group('EditorMediaBinding.updateCaption', () {
    test('updates staged item in coordinator, triggers onStateChanged, and persists to SQLite', () async {
      await binding.updateCaption(stagedMediaId, '画卷新题');

      expect(stateChangedCount, 1);
      expect(
        coordinator.stagedItems.firstWhere((item) => item.id == stagedMediaId).caption,
        equals('画卷新题'),
      );
      final persisted = (await database.mediaOcrDao.getMediaForEntry(entryId))
          .firstWhere((row) => row.id == stagedMediaId);
      expect(persisted.caption, equals('画卷新题'));
    });

    test('updates mounted item in coordinator, triggers onStateChanged, and persists to SQLite', () async {
      await binding.updateCaption(mountedMediaId, '已贴影札题跋');

      expect(stateChangedCount, 1);
      final opening = coordinator.sheets.first as OpeningSheet;
      expect(
        opening.mediaAttachments.firstWhere((item) => item.id == mountedMediaId).caption,
        equals('已贴影札题跋'),
      );
      final persisted = (await database.mediaOcrDao.getMediaForEntry(entryId))
          .firstWhere((row) => row.id == mountedMediaId);
      expect(persisted.caption, equals('已贴影札题跋'));
    });

    test('does not invoke onStateChanged when mediaId is absent from coordinator', () async {
      await binding.updateCaption('nonexistent_id', '无此影札');

      expect(stateChangedCount, 0);
    });
  });

  group('EditorMediaBinding.collectImages', () {
    test('returns empty result without side effects when picks is empty', () async {
      final outcome = await binding.collectImages(const []);
      expect(outcome, equals(const MediaCollectResult(collectedCount: 0, rejectedByCapacity: 0)));
      expect(stateChangedCount, 0);
      expect(listSandboxMediaRelativePaths(), isEmpty);
    });

    test('sandboxes, persists atomically, stages in input order, queues BrushReveals, and saves draft', () async {
      final picks = writeSourceImages(2);
      final outcome = await binding.collectImages(picks);

      expect(outcome.collectedCount, 2);
      expect(outcome.rejectedByCapacity, 0);
      expect(stateChangedCount, 1);
      expect(autosaveManager.statusNotifier.value, AutosaveStatus.saved);

      expect(coordinator.stagedItems, hasLength(3));
      final collectedItems = coordinator.stagedItems.sublist(1);
      expect(collectedItems.every((item) => item.mediaType == EphemeraMediaType.image), isTrue);
      for (final item in collectedItems) {
        expect(binding.brushReveals.isPending(item.id), isTrue);
        expect(File('${tempDirectory.path}/${item.relativePath}').existsSync(), isTrue);
      }

      final dbRows = await database.mediaOcrDao.getMediaForEntry(entryId);
      expect(dbRows.map((row) => row.id), containsAll(collectedItems.map((item) => item.id)));
    });

    test('truncates picks at kHandscrollCapacity and reports rejectedByCapacity', () async {
      // 1 item already staged; fill 13 more so room == 1.
      final fillOutcome = await binding.collectImages(writeSourceImages(13, prefix: 'fill'));
      expect(fillOutcome.collectedCount, 13);
      expect(coordinator.handscrollRoom, 1);

      final overflowOutcome = await binding.collectImages(writeSourceImages(4, prefix: 'over'));
      expect(overflowOutcome.collectedCount, 1);
      expect(overflowOutcome.rejectedByCapacity, 3);
      expect(coordinator.stagedItems, hasLength(EditorPaginationCoordinator.kHandscrollCapacity));
      expect(coordinator.handscrollRoom, 0);

      // Full handscroll rejects all without touching disk, SQLite, or state.
      final callsBefore = stateChangedCount;
      final filesBefore = listSandboxMediaRelativePaths();
      final fullOutcome = await binding.collectImages(writeSourceImages(2, prefix: 'full'));
      expect(fullOutcome.collectedCount, 0);
      expect(fullOutcome.rejectedByCapacity, 2);
      expect(stateChangedCount, callsBefore);
      expect(listSandboxMediaRelativePaths(), equals(filesBefore));
    });

    test('rolls back newly sandboxed files when SQLite batch insert throws', () async {
      final failingBinding = createBinding(
        mediaOcrDao: _FailingBatchMediaOcrDao(database),
      );
      addTearDown(failingBinding.dispose);

      final filesBefore = listSandboxMediaRelativePaths();
      await expectLater(
        () => failingBinding.collectImages(writeSourceImages(2, prefix: 'fail')),
        throwsStateError,
      );

      expect(listSandboxMediaRelativePaths(), equals(filesBefore));
      expect(coordinator.stagedItems.map((item) => item.id), equals([stagedMediaId]));
      expect(stateChangedCount, 0);
    });
  });

  group('EditorMediaBinding.collectVideo', () {
    test('sandboxes video and companion thumbnail, persists row, stages item, and queues reveal', () async {
      final outcome = await binding.collectVideo(writeSourceVideo());

      expect(outcome.collectedCount, 1);
      expect(outcome.rejectedByCapacity, 0);
      expect(stateChangedCount, 1);
      expect(autosaveManager.statusNotifier.value, AutosaveStatus.saved);

      final videoItem = coordinator.stagedItems.last;
      expect(videoItem.mediaType, EphemeraMediaType.video);
      expect(videoItem.thumbnailPath, isNotNull);
      expect(videoItem.thumbnailPath, isNotEmpty);
      expect(File('${tempDirectory.path}/${videoItem.relativePath}').existsSync(), isTrue);
      expect(File('${tempDirectory.path}/${videoItem.thumbnailPath}').existsSync(), isTrue);
      expect(binding.brushReveals.isPending(videoItem.id), isTrue);

      final persisted = await database.mediaOcrDao.getMediaAttachmentById(videoItem.id);
      expect(persisted?.mediaType, equals('video'));
      expect(persisted?.thumbnailPath, equals(videoItem.thumbnailPath));
    });

    test('returns rejectedByCapacity: 1 when handscroll is full without touching disk', () async {
      await binding.collectImages(writeSourceImages(14, prefix: 'fill_vid'));
      expect(coordinator.handscrollRoom, 0);
      final filesBefore = listSandboxMediaRelativePaths();

      final outcome = await binding.collectVideo(writeSourceVideo(name: 'full_vid.mp4'));
      expect(outcome.collectedCount, 0);
      expect(outcome.rejectedByCapacity, 1);
      expect(listSandboxMediaRelativePaths(), equals(filesBefore));
    });

    test('rolls back both video and companion thumbnail when SQLite insert throws', () async {
      final failingBinding = createBinding(
        mediaOcrDao: _FailingBatchMediaOcrDao(database),
      );
      addTearDown(failingBinding.dispose);

      final filesBefore = listSandboxMediaRelativePaths();
      await expectLater(
        () => failingBinding.collectVideo(writeSourceVideo(name: 'rollback_vid.mp4')),
        throwsStateError,
      );

      expect(listSandboxMediaRelativePaths(), equals(filesBefore));
      expect(coordinator.stagedItems.map((item) => item.id), equals([stagedMediaId]));
    });

    test('rethrows VideoDurationExceededException without writing files or rows', () async {
      final longSandbox = SyncTestMediaSandboxService(
        tempDir: tempDirectory,
        generateVideoThumbnail: true,
        videoDuration: const Duration(seconds: 75),
      );
      final longBinding = createBinding(mediaSandboxService: longSandbox);
      addTearDown(longBinding.dispose);

      final filesBefore = listSandboxMediaRelativePaths();
      await expectLater(
        () => longBinding.collectVideo(writeSourceVideo(name: 'long_vid.mp4')),
        throwsA(isA<VideoDurationExceededException>()),
      );
      expect(listSandboxMediaRelativePaths(), equals(filesBefore));
    });
  });

  group('EditorMediaBinding mount & unmount', () {
    test('mounts up to 3 items, refuses 4th with mountRefusals tick, and unmounts back to collect order', () async {
      await binding.collectImages(writeSourceImages(3, prefix: 'mount_test'));
      final ids = coordinator.stagedItems.map((item) => item.id).toList();
      expect(ids, hasLength(4));

      // mountedMediaId is already mounted (slot 1 of 3). Mount 2 more.
      expect(await binding.mountMedia(ids[0]), isTrue);
      expect(await binding.mountMedia(ids[1]), isTrue);
      expect(binding.mountRefusals.value, 0);

      // 4th mount is refused without unstaging.
      expect(await binding.mountMedia(ids[2]), isFalse);
      expect(binding.mountRefusals.value, 1);
      expect(coordinator.stagedItems.map((item) => item.id), equals([ids[2], ids[3]]));

      // Unmounting ids[0] returns it before ids[2] (collect order).
      await binding.unmountMedia(ids[0]);
      expect(coordinator.stagedItems.map((item) => item.id), equals([ids[0], ids[2], ids[3]]));
    });
  });

  group('EditorMediaBinding erase-undo internal timer & thumbnail purge', () {
    testWidgets('purges SQLite row, primary file, and video thumbnail automatically after 4s without a Scaffold', (tester) async {
      final videoFile = File('${tempDirectory.path}/media/erased_vid.mp4')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValidMp4FtypBytes);
      final thumbFile = File('${tempDirectory.path}/media/erased_vid_thumb.webp')
        ..writeAsBytesSync(kValid1x1PngBytes);
      await tester.runAsync(() async {
        await database.mediaOcrDao.attachMediaToEntry(
          id: 'vid_to_erase',
          entryId: entryId,
          relativePath: 'media/erased_vid.mp4',
          mediaType: 'video',
          thumbnailPath: 'media/erased_vid_thumb.webp',
        );
        final freshAttachments = await database.mediaOcrDao.getMediaForEntry(entryId);
        coordinator.initializeFromDelta(
          jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
          attachments: freshAttachments,
        );
      });

      expect(binding.eraseStagedMedia('vid_to_erase'), isTrue);
      expect(coordinator.stagedItems.any((item) => item.id == 'vid_to_erase'), isFalse);

      await tester.pump(const Duration(milliseconds: 3999));
      expect(videoFile.existsSync(), isTrue);
      expect(thumbFile.existsSync(), isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(videoFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);

      final remaining = await tester.runAsync(
        () => database.mediaOcrDao.getMediaAttachmentById('vid_to_erase'),
      );
      expect(remaining, isNull);
    });

    testWidgets('undoErase before 4s cancels internal timer and preserves SQLite row and files', (tester) async {
      final photoFile = File('${tempDirectory.path}/media/staged.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      expect(binding.eraseStagedMedia(stagedMediaId), isTrue);
      await tester.pump(const Duration(seconds: 2));
      binding.undoErase(stagedMediaId);
      expect(coordinator.stagedItems.map((item) => item.id), contains(stagedMediaId));

      await tester.pump(const Duration(seconds: 5));
      expect(photoFile.existsSync(), isTrue);
      expect(coordinator.stagedItems.map((item) => item.id), contains(stagedMediaId));

      final row = await tester.runAsync(
        () => database.mediaOcrDao.getMediaAttachmentById(stagedMediaId),
      );
      expect(row, isNotNull);
    });

    test('discardAllStaged cancels timers and purges all staged items including video thumbnails', () async {
      final stagedPhoto = File('${tempDirectory.path}/media/staged.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      final mountedPhoto = File('${tempDirectory.path}/media/mounted.webp')
        ..writeAsBytesSync(kValid1x1PngBytes);
      final vidFile = File('${tempDirectory.path}/media/discard_vid.mp4')
        ..writeAsBytesSync(kValidMp4FtypBytes);
      final thumbFile = File('${tempDirectory.path}/media/discard_vid_thumb.webp')
        ..writeAsBytesSync(kValid1x1PngBytes);
      await database.mediaOcrDao.attachMediaToEntry(
        id: 'discard_vid',
        entryId: entryId,
        relativePath: 'media/discard_vid.mp4',
        mediaType: 'video',
        thumbnailPath: 'media/discard_vid_thumb.webp',
      );
      final attachments = await database.mediaOcrDao.getMediaForEntry(entryId);
      coordinator.initializeFromDelta(
        jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
        attachments: attachments,
      );
      expect(coordinator.mountOnActiveSheet(mountedMediaId), isTrue);

      await binding.discardAllStaged();

      expect(coordinator.stagedItems, isEmpty);
      expect(stagedPhoto.existsSync(), isFalse);
      expect(vidFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);
      expect(mountedPhoto.existsSync(), isTrue);
      expect(
        (await database.mediaOcrDao.getMediaForEntry(entryId)).map((row) => row.id),
        equals([mountedMediaId]),
      );
    });

    testWidgets('dispose cancels active timers and purges pending erasures cleanly', (tester) async {
      final stagedPhoto = File('${tempDirectory.path}/media/staged.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      expect(binding.eraseStagedMedia(stagedMediaId), isTrue);
      binding.dispose();
      await tester.pump(const Duration(seconds: 5));
      expect(stagedPhoto.existsSync(), isFalse);

      final row = await tester.runAsync(
        () => database.mediaOcrDao.getMediaAttachmentById(stagedMediaId),
      );
      expect(row, isNull);
    });

    testWidgets('maintains independent 4s timers per erased item', (tester) async {
      final firstFile = File('${tempDirectory.path}/media/staged.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      final secondFile = File('${tempDirectory.path}/media/staged_2.webp')
        ..writeAsBytesSync(kValid1x1PngBytes);
      await tester.runAsync(() async {
        await database.mediaOcrDao.attachMediaToEntry(
          id: 'staged_photo_2',
          entryId: entryId,
          relativePath: 'media/staged_2.webp',
        );
        final fresh = await database.mediaOcrDao.getMediaForEntry(entryId);
        coordinator.initializeFromDelta(
          jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
          attachments: fresh,
        );
      });

      expect(binding.eraseStagedMedia(stagedMediaId), isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(binding.eraseStagedMedia('staged_photo_2'), isTrue);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(firstFile.existsSync(), isFalse);
      expect(secondFile.existsSync(), isTrue);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(secondFile.existsSync(), isFalse);
    });

    test('purgeErased deletes SQLite before sandbox files (ADR-0010)', () async {
      final failingDeleteBinding = createBinding(
        mediaOcrDao: _FailingDeleteMediaOcrDao(database),
      );
      addTearDown(failingDeleteBinding.dispose);

      final stagedPhoto = File('${tempDirectory.path}/media/staged.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      expect(failingDeleteBinding.eraseStagedMedia(stagedMediaId), isTrue);
      await expectLater(
        () => failingDeleteBinding.purgeErased(stagedMediaId),
        throwsStateError,
      );
      expect(stagedPhoto.existsSync(), isTrue);
    });
  });

  group('EditorMediaBinding.deleteLegacyEphemera', () {
    test('removes EphemeraSheet, deletes SQLite row first, deletes video and thumbnail files, and forces draft save', () async {
      final legacyDelta = Delta()
        ..insert('首段正文。\n')
        ..insert({'video': 'media/legacy_vid.mp4'})
        ..insert('\n')
        ..insert('末段结语。\n');
      final legacyDeltaJson = jsonEncode(legacyDelta.toJson());
      await database.entriesDao.updateEntryContent(entryId, legacyDeltaJson, '首段正文。\n末段结语。');
      await database.mediaOcrDao.attachMediaToEntry(
        id: 'legacy_vid_id',
        entryId: entryId,
        relativePath: 'media/legacy_vid.mp4',
        mediaType: 'video',
        thumbnailPath: 'media/legacy_vid_thumb.webp',
      );
      final vidFile = File('${tempDirectory.path}/media/legacy_vid.mp4')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValidMp4FtypBytes);
      final thumbFile = File('${tempDirectory.path}/media/legacy_vid_thumb.webp')
        ..writeAsBytesSync(kValid1x1PngBytes);

      final attachments = await database.mediaOcrDao.getMediaForEntry(entryId);
      coordinator.initializeFromDelta(legacyDeltaJson, attachments: attachments);
      expect(coordinator.sheets, hasLength(3));
      expect(coordinator.sheets[1], isA<EphemeraSheet>());
      stateChangedCount = 0;

      await binding.deleteLegacyEphemera(1);

      expect(stateChangedCount, 1);
      expect(coordinator.sheets, hasLength(2));
      expect(coordinator.sheets[0], isA<OpeningSheet>());
      expect(coordinator.sheets[1], isA<ContinuationSheet>());
      expect(coordinator.sheets[0].sheetIndex, 0);
      expect(coordinator.sheets[1].sheetIndex, 1);
      expect(await database.mediaOcrDao.getMediaAttachmentById('legacy_vid_id'), isNull);
      expect(vidFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);
      expect(autosaveManager.statusNotifier.value, AutosaveStatus.saved);
      final savedEntry = await database.entriesDao.getEntryById(entryId);
      expect(savedEntry!.contentDelta, isNot(contains('legacy_vid.mp4')));
    });

    test('ignores out-of-range indices and non-EphemeraSheet targets', () async {
      await binding.deleteLegacyEphemera(0); // OpeningSheet
      await binding.deleteLegacyEphemera(-1);
      await binding.deleteLegacyEphemera(99);

      expect(stateChangedCount, 0);
      expect(coordinator.sheets, hasLength(1));
    });

    test('preserves sandbox files when SQLite deletion throws (ADR-0010)', () async {
      final legacyDeltaJson = jsonEncode(
        (Delta()
              ..insert('正文\n')
              ..insert({'image': 'media/legacy_img.webp'})
              ..insert('\n'))
            .toJson(),
      );
      await database.entriesDao.updateEntryContent(entryId, legacyDeltaJson, '正文');
      await database.mediaOcrDao.attachMediaToEntry(
        id: 'legacy_img_id',
        entryId: entryId,
        relativePath: 'media/legacy_img.webp',
      );
      final imgFile = File('${tempDirectory.path}/media/legacy_img.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      final attachments = await database.mediaOcrDao.getMediaForEntry(entryId);
      coordinator.initializeFromDelta(legacyDeltaJson, attachments: attachments);

      final failingBinding = createBinding(
        mediaOcrDao: _FailingDeleteMediaOcrDao(database),
      );
      addTearDown(failingBinding.dispose);

      await expectLater(
        () => failingBinding.deleteLegacyEphemera(1),
        throwsStateError,
      );
      expect(imgFile.existsSync(), isTrue);
    });
  });
}
