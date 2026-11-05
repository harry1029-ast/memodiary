import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import '../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  const entryId = 'lightbox_caption_entry';
  const mediaId = 'lightbox_caption_photo';

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('lightbox_caption_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    File('${tempDirectory.path}/media_ticket.webp').writeAsBytesSync(kValid1x1PngBytes);

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 5, 10),
          ),
        );
    await database.into(database.mediaAttachments).insert(
          MediaAttachmentsCompanion.insert(
            id: mediaId,
            entryId: entryId,
            mediaType: 'image',
            relativePath: 'media_ticket.webp',
            ocrText: const Value('灵隐门票'),
            ocrBlocksJson: const Value('[{"text":"灵隐门票"}]'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> openEditorAndLightbox(WidgetTester tester) async {
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: entryId,
      viewportSize: const Size(360.0, 780.0),
    );
    await tester.tap(find.byKey(const Key('media_tray_card_$mediaId')));
    await tester.pumpAndSettle();
    expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
  }

  Finder inLightbox(Finder finder) =>
      find.descendant(of: find.byType(FullscreenMediaLightbox), matching: finder);

  testWidgets('caption edited in the lightbox shows immediately and persists across reopen', (tester) async {
    await openEditorAndLightbox(tester);

    // OCR-recognised text is never presented as the diarist's caption.
    expect(inLightbox(find.text('灵隐门票')), findsNothing);

    await tester.tap(find.byKey(const Key('lightbox_caption_edit_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('lightbox_caption_input')), '雨后西湖');
    await tester.tap(find.byKey(const Key('lightbox_caption_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lightbox_caption_input')), findsNothing);
    expect(inLightbox(find.text('雨后西湖')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fullscreen_lightbox_close_button')));
    await tester.pumpAndSettle();

    // Reopen the entry from scratch.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditorAndLightbox(tester);

    expect(inLightbox(find.text('雨后西湖')), findsOneWidget);
    expect(inLightbox(find.text('灵隐门票')), findsNothing);
  });

  testWidgets('lightbox opened without a caption handler stays read-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenMediaLightbox(
          items: const [
            SheetMediaItem(
              id: 'read_only_photo',
              mediaType: EphemeraMediaType.image,
              relativePath: 'media_ticket.webp',
              caption: '钱塘江潮',
            ),
          ],
          mediaSandboxService: sandboxService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('钱塘江潮'), findsOneWidget);
    expect(find.byKey(const Key('lightbox_caption_edit_button')), findsNothing);
  });
}
