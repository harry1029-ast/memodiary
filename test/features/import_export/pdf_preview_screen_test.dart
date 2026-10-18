import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/widgets/export_dialog.dart';
import 'package:memodiary/features/import_export/widgets/pdf_preview_screen.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:printing/printing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  final now = DateTime(2026, 10, 18, 10, 0);

  final testEntry1 = Entry(
    id: 'entry_preview_1',
    notebookId: 'default',
    templateId: 'template_minimalist_white',
    title: 'Autumn Walk in the Park',
    contentDelta: jsonEncode([
      {'insert': 'A gentle breeze rustled the golden leaves.\n'}
    ]),
    plainText: 'A gentle breeze rustled the golden leaves.',
    entryDate: now,
    mood: 5,
    weather: 'sunny',
    isWeeklyReview: false,
    weekNumber: 42,
    isLocked: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final testEntry2 = Entry(
    id: 'entry_preview_2',
    notebookId: 'default',
    templateId: 'template_lined_paper',
    title: 'Evening Coffee',
    contentDelta: jsonEncode([
      {'insert': 'Quiet thoughts with a warm cup of coffee.\n'}
    ]),
    plainText: 'Quiet thoughts with a warm cup of coffee.',
    entryDate: now.add(const Duration(hours: 6)),
    mood: 4,
    weather: 'cloudy',
    isWeeklyReview: false,
    weekNumber: 42,
    isLocked: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  setUpAll(() {
    // Mock net.nfet.printing platform channel to avoid MissingPluginException in headless testing
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('net.nfet.printing'), (call) async {
      if (call.method == 'printingInfo') {
        return <String, dynamic>{
          'canPrint': true,
          'canShare': true,
          'canRaster': false,
          'directPrint': false,
        };
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('net.nfet.printing'), null);
  });

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = await Directory.systemTemp.createTemp('pdf_preview_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfPreviewScreen & UI Integration Tests', () {
    testWidgets('renders single entry in PdfPreviewScreen with title and PdfPreview widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PdfPreviewScreen(
            singleEntry: testEntry1,
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Autumn Walk in the Park'), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });

    testWidgets('renders multi-entry journal book in PdfPreviewScreen with custom title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PdfPreviewScreen(
            entries: [testEntry1, testEntry2],
            database: db,
            mediaService: mediaService,
            documentTitle: 'Autumn 2026 Collection',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Autumn 2026 Collection'), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });

    testWidgets('ExportDialog allows selecting PDF and navigates to PdfPreviewScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportDialog(
              database: db,
              singleEntry: testEntry1,
              mediaService: mediaService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check PDF option is present
      expect(find.text('High-Fidelity PDF (.pdf)'), findsOneWidget);

      // Select PDF format
      await tester.tap(find.text('High-Fidelity PDF (.pdf)'));
      await tester.pumpAndSettle();

      // Button should now read 'Preview PDF'
      expect(find.text('Preview PDF'), findsOneWidget);

      // Tap Preview PDF to navigate
      await tester.tap(find.text('Preview PDF'));
      await tester.pumpAndSettle();

      // Verify navigated to PdfPreviewScreen
      expect(find.byType(PdfPreviewScreen), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });

    testWidgets('EntryDetailScreen has Export PDF action button that navigates to PdfPreviewScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryDetailScreen(
            entry: testEntry1,
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find PDF export icon button in AppBar
      final pdfButton = find.byIcon(Icons.picture_as_pdf_outlined);
      expect(pdfButton, findsOneWidget);

      // Tap PDF export button
      await tester.tap(pdfButton);
      await tester.pumpAndSettle();

      // Verify navigation to PdfPreviewScreen
      expect(find.byType(PdfPreviewScreen), findsOneWidget);
      expect(find.text('Autumn Walk in the Park'), findsOneWidget);
    });
  });
}

