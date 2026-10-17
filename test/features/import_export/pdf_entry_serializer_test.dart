import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/pdf_entry_serializer.dart';
import 'package:memodiary/features/import_export/services/pdf_font_resolver.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MediaSandboxService mediaService;
  final fontResolver = PdfFontResolver.standard();

  const style = TemplateStyle(
    type: TemplateBackgroundType.color,
    backgroundColor: material.Colors.white,
    fontFamily: 'Roboto',
    lineSpacing: 1.5,
    marginHorizontal: 24.0,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_serializer_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfEntrySerializer Tests', () {
    test('serializes fallback plain text when delta is empty or invalid', () async {
      final widgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: '',
        fallbackPlainText: 'Line 1\n\nLine 2',
        mediaService: mediaService,
        style: style,
        fontResolver: fontResolver,
      );

      expect(widgets, isNotEmpty);
      expect(widgets.length, equals(3)); // Line 1, empty line (SizedBox), Line 2
    });

    test('serializes rich Quill Delta with headers, styling, blockquotes, and lists', () async {
      final deltaOps = [
        {'insert': 'Heading 1 Title'},
        {'insert': '\n', 'attributes': {'header': 1}},
        {'insert': 'Heading 2 Subtitle'},
        {'insert': '\n', 'attributes': {'header': 2}},
        {'insert': 'This is '},
        {'insert': 'bold', 'attributes': {'bold': true}},
        {'insert': ' and '},
        {'insert': 'italic', 'attributes': {'italic': true}},
        {'insert': ' and '},
        {'insert': 'underlined', 'attributes': {'underline': true}},
        {'insert': '.\n'},
        {'insert': 'A wise quote from a book.'},
        {'insert': '\n', 'attributes': {'blockquote': true}},
        {'insert': 'First bullet item'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Second bullet item'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Step 1'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Step 2'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': {'divider': true}},
        {'insert': '\n'},
      ];

      final widgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: jsonEncode(deltaOps),
        fallbackPlainText: '',
        mediaService: mediaService,
        style: style,
        fontResolver: fontResolver,
      );

      expect(widgets, isNotEmpty);

      // Verify that document can render into PDF without error
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => widgets,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('embeds sandboxed image from relative path and transcodes for PDF', () async {
      // Create a dummy PNG in sandbox directory
      final mediaSubdir = Directory('${tempDir.path}/media');
      await mediaSubdir.create(recursive: true);

      // 1x1 transparent PNG byte array
      final png1x1 = <int>[
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
      final imageFile = File('${mediaSubdir.path}/test_image.png');
      await imageFile.writeAsBytes(png1x1);

      final deltaOps = [
        {'insert': 'Text before image\n'},
        {
          'insert': {
            'image': 'media/test_image.png',
          }
        },
        {'insert': '\nText after image\n'},
      ];

      final widgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: jsonEncode(deltaOps),
        fallbackPlainText: '',
        mediaService: mediaService,
        style: style,
        fontResolver: fontResolver,
      );

      expect(widgets, isNotEmpty);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => widgets,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('handles missing or invalid sandboxed image gracefully with placeholder', () async {
      final deltaOps = [
        {
          'insert': {
            'image': 'media/non_existent.webp',
          }
        },
        {'insert': '\n'},
      ];

      final widgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: jsonEncode(deltaOps),
        fallbackPlainText: '',
        mediaService: mediaService,
        style: style,
        fontResolver: fontResolver,
      );

      expect(widgets, isNotEmpty);
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => widgets,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });
}

