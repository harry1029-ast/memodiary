import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_models.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/settings/widgets/ocr_backfill_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../helpers/fake_ocr_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late FakeOcrService fakeOcr;
  late OcrQueueManager queueManager;

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('ocr_backfill_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
    fakeOcr = FakeOcrService();
    queueManager = OcrQueueManager(
      database: db,
      mediaSandboxService: mediaService,
      ocrService: fakeOcr,
    );

    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_test',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: const Value('测试日记'),
        contentDelta: '[{"insert":"测试内容\\n"}]',
        plainText: '测试内容',
        entryDate: DateTime(2026, 10, 20),
      ),
    );
  });

  tearDown(() async {
    await queueManager.dispose();
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> createDummyPhoto({
    required String id,
    required String relativePath,
    String? ocrText,
  }) async {
    final file = File('${tempDir.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync([0x01, 0x02, 0x03]);

    await db.into(db.mediaAttachments).insert(
          MediaAttachmentsCompanion.insert(
            id: id,
            entryId: 'entry_test',
            mediaType: 'image',
            relativePath: relativePath,
            ocrText: Value(ocrText),
            createdAt: Value(DateTime(2026, 10, 20)),
          ),
        );
  }

  Future<Map<String, PermissionStatus>> mockPermissionChecker() async {
    return {
      'camera': PermissionStatus.granted,
      'microphone': PermissionStatus.granted,
      'photos': PermissionStatus.granted,
    };
  }

  group('OcrBackfillDialog and Settings Integration Tests', () {
    testWidgets('SettingsScreen displays settings_ocr_backfill_tile with unindexed count',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await createDummyPhoto(id: 'photo_1', relativePath: 'media/p1.webp');
      await createDummyPhoto(id: 'photo_2', relativePath: 'media/p2.webp');

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: queueManager,
            permissionChecker: mockPermissionChecker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_tile')), findsOneWidget);
      expect(find.textContaining('发现 2 张照片尚未建立索引'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays "已建立全部文字索引" when count is zero',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await createDummyPhoto(
        id: 'photo_1',
        relativePath: 'media/p1.webp',
        ocrText: '已识别文字',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: queueManager,
            permissionChecker: mockPermissionChecker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_tile')), findsOneWidget);
      expect(find.textContaining('已建立全部文字索引'), findsOneWidget);
    });

    testWidgets('Tapping backfill tile opens dialog, indexes all photos, and updates status',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await createDummyPhoto(id: 'photo_1', relativePath: 'media/p1.webp');
      await createDummyPhoto(id: 'photo_2', relativePath: 'media/p2.webp');

      fakeOcr.defaultResult = const OcrResult(
        plainText: '测试识别内容',
        lines: [
          OcrLineBlock(text: '测试识别内容', box: [0.1, 0.1, 0.8, 0.2]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: queueManager,
            permissionChecker: mockPermissionChecker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_ocr_backfill_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsOneWidget);
      expect(find.text('识图索引已完成'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_ocr_backfill_done_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsNothing);
      expect(find.textContaining('已建立全部文字索引'), findsOneWidget);

      final unindexed = await queueManager.pendingBackfillCount();
      expect(unindexed, equals(0));
    });

    testWidgets('Cancellation halts backfill cleanly and reopening resumes scanning',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await createDummyPhoto(id: 'photo_1', relativePath: 'media/p1.webp');
      await createDummyPhoto(id: 'photo_2', relativePath: 'media/p2.webp');
      await createDummyPhoto(id: 'photo_3', relativePath: 'media/p3.webp');

      final completer = Completer<void>();
      fakeOcr.onRecognize = (path) async {
        if (path.contains('p1.webp')) {
          await completer.future;
        }
        return const OcrResult(
          plainText: '文字',
          lines: [],
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: queueManager,
            permissionChecker: mockPermissionChecker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_ocr_backfill_tile')));
      // Pump frame to show dialog while first recognition is waiting on completer
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsOneWidget);
      expect(find.byKey(const Key('settings_ocr_backfill_cancel_button')), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.byKey(const Key('settings_ocr_backfill_cancel_button')));
      // Complete the pending photo recognize future
      completer.complete();
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsNothing);

      // Remaining items are not all indexed yet
      final remainingAfterCancel = await queueManager.pendingBackfillCount();
      expect(remainingAfterCancel, greaterThan(0));

      // Re-opening the dialog resumes scanning remaining photos
      fakeOcr.onRecognize = null;
      fakeOcr.defaultResult = const OcrResult(plainText: '已恢复文字', lines: []);

      await tester.tap(find.byKey(const Key('settings_ocr_backfill_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsOneWidget);
      expect(find.text('识图索引已完成'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_ocr_backfill_done_button')));
      await tester.pumpAndSettle();

      final remainingFinal = await queueManager.pendingBackfillCount();
      expect(remainingFinal, equals(0));
    });

    testWidgets('Tapping search_ocr_backfill_banner in SearchScreen triggers backfill dialog',
        (tester) async {
      await createDummyPhoto(id: 'photo_1', relativePath: 'media/p1.webp');

      fakeOcr.defaultResult = const OcrResult(
        plainText: '检索用画卷',
        lines: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: queueManager,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_ocr_backfill_banner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('search_ocr_backfill_banner')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsOneWidget);
      expect(find.text('识图索引已完成'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_ocr_backfill_done_button')));
      await tester.pumpAndSettle();

      // Banner should disappear because pending count became 0
      expect(find.byKey(const Key('search_ocr_backfill_banner')), findsNothing);
    });

    testWidgets('OcrBackfillDialog standalone renders correctly and completes',
        (tester) async {
      await createDummyPhoto(id: 'photo_standalone', relativePath: 'media/ps.webp');
      fakeOcr.defaultResult = const OcrResult(plainText: '独立弹窗测试', lines: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrBackfillDialog(ocrQueueManager: queueManager),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_ocr_backfill_dialog')), findsOneWidget);
      expect(find.text('识图索引已完成'), findsOneWidget);
    });
  });
}
