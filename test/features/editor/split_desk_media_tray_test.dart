import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/paper_heart_metrics.dart';
import 'package:memodiary/features/editor/widgets/stationery_media_tray.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('split_desk_tray_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    // Seed test media files in sandbox
    final photo1 = File('${tempDirectory.path}/media_photo_1.webp');
    photo1.writeAsBytesSync(kValid1x1PngBytes);

    final photo2 = File('${tempDirectory.path}/media_photo_2.webp');
    photo2.writeAsBytesSync(kValid1x1PngBytes);

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: 'split_desk_entry_with_photo',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('江南雨景'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 4, 21, 30),
            mood: const Value(4),
            weather: const Value('雨'),
          ),
        );

    await database.attachMediaToEntry(
      id: 'photo_attachment_1',
      entryId: 'split_desk_entry_with_photo',
      relativePath: 'media_photo_1.webp',
      mediaType: 'image',
    );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Split Desk Media Tray & Auto-Collapsing Keyboard Dynamics (Seam 2)', () {
    testWidgets('attaching photo to sheet shifts 14-row card to top dock and mounts StationeryMediaTray', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'split_desk_entry_with_photo',
        viewportSize: const Size(360.0, 780.0),
      );

      final canvasRect = tester.getRect(find.byType(EditorPaperCanvas));

      // Card must be docked near the top (<= 20.0px inside canvas) because Sheet 1 has an attached photo
      final cardFinder = find.byType(TemplateCanvasContainer);
      expect(cardFinder, findsOneWidget);
      final cardRect = tester.getRect(cardFinder);
      expect(cardRect.top - canvasRect.top, lessThanOrEqualTo(20.0));

      // Lower StationeryMediaTray is mounted beneath the card
      final trayFinder = find.byType(StationeryMediaTray);
      expect(trayFinder, findsOneWidget);
      final trayRect = tester.getRect(trayFinder);
      expect(trayRect.top, greaterThanOrEqualTo(cardRect.bottom));

      // Cinnabar Seal should not be taking desk mat space when media tray is mounted
      expect(find.byType(BoundedCinnabarSeal), findsNothing);
    });

    testWidgets('software keyboard appearance collapses lower tray downward while writing card stays stationary', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'split_desk_entry_with_photo',
        viewportSize: const Size(360.0, 780.0),
      );

      final initialCardRect = tester.getRect(find.byType(TemplateCanvasContainer));
      final initialTrayRect = tester.getRect(find.byType(StationeryMediaTray));

      // Simulate software keyboard opening with 300px bottom viewInsets
      final binding = tester.view;
      binding.viewInsets = const FakeViewPadding(bottom: 300.0);
      await tester.pump(const Duration(milliseconds: 100));

      // Intermediate animation check: card position must remain rock-solid stationary
      final duringAnimCardRect = tester.getRect(find.byType(TemplateCanvasContainer));
      expect(duringAnimCardRect.top, closeTo(initialCardRect.top, 1.0));

      // Complete 250ms ease-out animation
      await tester.pumpAndSettle();

      final postKeyboardCardRect = tester.getRect(find.byType(TemplateCanvasContainer));
      // Writing card is 100% stationary and non-scrolling
      expect(
        postKeyboardCardRect.top,
        closeTo(initialCardRect.top, 1.0),
        reason: '14-row writing card must stay 100% stationary without vertical jumping when keyboard appears',
      );

      // Dismiss software keyboard
      binding.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      final restoredCardRect = tester.getRect(find.byType(TemplateCanvasContainer));
      expect(restoredCardRect.top, closeTo(initialCardRect.top, 1.0));

      final restoredTrayRect = tester.getRect(find.byType(StationeryMediaTray));
      expect(restoredTrayRect.top, closeTo(initialTrayRect.top, 2.0));
    });
  });

  group('Sheet-Paired Ephemera Auto-Spill Invariant (Seam 3)', () {
    testWidgets('typing past row 14 auto-spills onto Sheet 2, retaining Sheet 1 photos bound to Sheet 1', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'split_desk_entry_with_photo',
        viewportSize: const Size(360.0, 780.0),
      );

      final coordinator = tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).coordinator;
      expect(coordinator.sheets.length, equals(1));
      final sheet1 = coordinator.sheets[0] as TextStationerySheet;
      expect(sheet1.mediaAttachments.length, equals(1));
      expect(sheet1.mediaAttachments.first.relativePath, equals('media_photo_1.webp'));

      // Rapidly type enough rows to trigger Auto-Spill past row 14
      final longProse = List.generate(16, (index) => '第 $index 行细雨蒙蒙落入青石古巷。').join('\n');
      sheet1.controller.document = Document()..insert(0, '$longProse\n');
      sheet1.controller.updateSelection(
        TextSelection.collapsed(offset: sheet1.controller.document.length - 1),
        ChangeSource.local,
      );

      coordinator.checkAndPerformAutoSpill(0);
      await tester.pumpAndSettle();

      // Auto-Spill has created Sheet 2
      expect(coordinator.sheets.length, greaterThanOrEqualTo(2));
      final sheet1PostSpill = coordinator.sheets[0] as TextStationerySheet;
      final sheet2PostSpill = coordinator.sheets[1] as TextStationerySheet;

      // Invariant: Sheet 1 retains photo 1 ($Sheet 1 <-> Photo 1$)
      expect(sheet1PostSpill.mediaAttachments.length, equals(1));
      expect(sheet1PostSpill.mediaAttachments.first.relativePath, equals('media_photo_1.webp'));

      // Invariant: Sheet 2 starts fresh in text-only scholar-centered layout (zero attachments)
      expect(sheet2PostSpill.mediaAttachments, isEmpty);
    });
  });
}
