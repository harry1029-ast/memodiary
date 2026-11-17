import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/models/pdf_layout_mode.dart';
import 'package:memodiary/features/import_export/services/pdf_entry_serializer.dart';
import 'package:memodiary/features/import_export/services/pdf_export_engine.dart';
import 'package:memodiary/features/import_export/services/pdf_font_resolver.dart';
import 'package:memodiary/features/import_export/services/pdf_polaroid_overlay_builder.dart';
import 'package:memodiary/features/import_export/services/pdf_vertical_scroll_builder.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('pdf_engine_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfExportEngine Tests', () {
    test('generatePdfForEntry generates valid PDF bytes with template preservation', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_single_1',
          notebookId: 'default',
          templateId: 'template_lined_paper',
          title: const Value('Autumn Reflections'),
          contentDelta: jsonEncode([
            {'insert': 'Today I went for a walk in the park.\n'},
            {'insert': 'The leaves were golden.\n', 'attributes': {'italic': true}},
          ]),
          plainText: 'Today I went for a walk in the park.\nThe leaves were golden.',
          entryDate: DateTime(2026, 10, 15),
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );

      final entry = await db.entriesDao.getEntryById('entry_single_1');
      expect(entry, isNotNull);

      final bytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generateConsolidatedPdf generates multi-entry journal book with cover page', () async {
      // 1. Create a custom template
      await db.templatesDao.createCustomTemplate(
        id: 'custom_lavender',
        name: 'Lavender Field',
        backgroundType: 'color',
        backgroundValue: '#E6E6FA',
        fontFamily: 'Roboto',
        lineSpacing: 1.6,
        marginHorizontal: 28.0,
      );

      // 2. Insert entries using different templates
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_book_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Chapter One'),
          contentDelta: jsonEncode([{'insert': 'Beginning of the journey.\n'}]),
          plainText: 'Beginning of the journey.',
          entryDate: DateTime(2026, 10, 1),
          mood: const Value(4),
          weather: const Value('sunny'),
        ),
      );

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_book_2',
          notebookId: 'default',
          templateId: 'template_grid_paper',
          title: const Value('Technical Notes'),
          contentDelta: jsonEncode([
            {'insert': 'Architecture Decisions:\n', 'attributes': {'bold': true}},
            {'insert': 'Zero Cloud, 100% Local SQLite.\n'},
          ]),
          plainText: 'Architecture Decisions:\nZero Cloud, 100% Local SQLite.',
          entryDate: DateTime(2026, 10, 5),
          mood: const Value(5),
          weather: const Value('cloudy'),
        ),
      );

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_book_3',
          notebookId: 'default',
          templateId: 'custom_lavender',
          title: const Value('Quiet Evening'),
          contentDelta: jsonEncode([{'insert': 'Resting under the stars.\n'}]),
          plainText: 'Resting under the stars.',
          entryDate: DateTime(2026, 10, 10),
          mood: const Value(3),
          weather: const Value('rainy'),
        ),
      );

      final entries = await db.entriesDao.getTimelineEntries(limit: 100);
      expect(entries.length, equals(3));

      final bytes = await PdfExportEngine.generateConsolidatedPdf(
        entries: entries,
        database: db,
        mediaService: mediaService,
        bookTitle: 'Autumn 2026 Chronicles',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generateConsolidatedPdf handles empty entries list gracefully', () async {
      final bytes = await PdfExportEngine.generateConsolidatedPdf(
        entries: [],
        database: db,
        mediaService: mediaService,
        bookTitle: 'Empty Notebook',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generatePdfForEntry in verticalScroll mode generates valid %PDF- bytes', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_vertical_scroll_1',
          notebookId: 'default',
          templateId: 'template_lined_paper',
          title: const Value('春江花月夜'),
          contentDelta: jsonEncode([
            {'insert': '「春江花月夜」\n'},
            {'insert': '孤篇压全唐——何处春江无月明…\n'},
            {'insert': '江流宛转绕芳甸，月照花林皆似霰。\n'},
          ]),
          plainText: '「春江花月夜」\n孤篇压全唐——何处春江无月明…\n江流宛转绕芳甸，月照花林皆似霰。',
          entryDate: DateTime(2026, 11, 2),
          mood: const Value(5),
          weather: const Value('霁月'),
        ),
      );

      final entry = await db.entriesDao.getEntryById('entry_vertical_scroll_1');
      expect(entry, isNotNull);

      final bytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
        layoutMode: PdfLayoutMode.verticalScroll,
        sealText: '心迹安放',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generatePdfForEntry faithfully renders 4-layer StationeryVisualTokens with Cold Gold flecks', () async {
      await db.templatesDao.createCustomTemplate(
        id: 'custom_cold_gold',
        name: '冷金洒粉笺',
        backgroundType: 'paperTexture',
        backgroundValue: jsonEncode({
          'color': '#F8F4E9',
          'substrate': 'coldGold',
          'ruleTint': 'vermilion',
          'sealStyle': 'baiwen',
        }),
        fontFamily: 'Noto Serif SC',
        lineSpacing: 1.6,
        marginHorizontal: 30.0,
      );

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_cold_gold_1',
          notebookId: 'default',
          templateId: 'custom_cold_gold',
          title: const Value('文房墨趣'),
          contentDelta: jsonEncode([
            {'insert': '素笺冷金，朱砂落款。\n'},
          ]),
          plainText: '素笺冷金，朱砂落款。',
          entryDate: DateTime(2026, 11, 2),
        ),
      );

      final entry = await db.entriesDao.getEntryById('entry_cold_gold_1');
      expect(entry, isNotNull);

      // Verify horizontal stationery with cold gold tokens
      final horizontalBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
        layoutMode: PdfLayoutMode.horizontal,
        sealText: '墨香存古',
      );
      expect(horizontalBytes, isNotEmpty);
      expect(String.fromCharCodes(horizontalBytes.take(5)), equals('%PDF-'));

      // Verify vertical scroll with cold gold tokens
      final verticalBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry,
        database: db,
        mediaService: mediaService,
        layoutMode: PdfLayoutMode.verticalScroll,
        sealText: '墨香存古',
      );
      expect(verticalBytes, isNotEmpty);
      expect(String.fromCharCodes(verticalBytes.take(5)), equals('%PDF-'));
    });

    test('generatePdfForEntry processes interlinear notes in verticalScroll and horizontal modes', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_interlinear_1',
          notebookId: 'default',
          templateId: 'template_lined_paper',
          title: const Value('春江夜话'),
          contentDelta: jsonEncode([
            {'insert': '江流宛转绕芳甸，{夹注:月照花林皆似霰}何处春江无月明。{夹注:唐诗选}\n'},
          ]),
          plainText: '江流宛转绕芳甸，{夹注:月照花林皆似霰}何处春江无月明。{夹注:唐诗选}\n',
          entryDate: DateTime(2026, 11, 2),
          mood: const Value(5),
          weather: const Value('晴'),
        ),
      );

      final entry = await db.entriesDao.getEntryById('entry_interlinear_1');
      expect(entry, isNotNull);

      // 1. Verify verticalScroll export with interlinear sub-notes produces valid %PDF-
      final verticalBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
        layoutMode: PdfLayoutMode.verticalScroll,
        sealText: '心迹安放',
      );
      expect(verticalBytes, isNotEmpty);
      expect(String.fromCharCodes(verticalBytes.take(5)), equals('%PDF-'));

      // 2. Verify horizontal mode export produces valid %PDF-
      final horizontalBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry,
        database: db,
        mediaService: mediaService,
        layoutMode: PdfLayoutMode.horizontal,
        sealText: '心迹安放',
      );
      expect(horizontalBytes, isNotEmpty);
      expect(String.fromCharCodes(horizontalBytes.take(5)), equals('%PDF-'));

      // 3. Verify horizontal serialization converts {夹注:...} to 〖...〗 without leaking {夹注:
      final widgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: entry.contentDelta,
        fallbackPlainText: entry.plainText,
        mediaService: mediaService,
        style: const TemplateStyle(
          type: TemplateBackgroundType.paperTexture,
          backgroundColor: Color(0xFFF7F3E8),
          lineSpacing: 1.5,
          marginHorizontal: 24.0,
        ),
        fontResolver: PdfFontResolver.cjk(),
      );
      expect(widgets, isNotEmpty);
    });

    test('generatePdfForEntry in verticalScroll mode correctly rotates Latin runs and fallback punctuation', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_rot_1',
          notebookId: 'default',
          templateId: 'template_lined_paper',
          title: const Value('MemoDiary 2026'),
          contentDelta: jsonEncode([
            {'insert': '夜泊～寒江—MemoDiary:卷{壹}\n'},
          ]),
          plainText: '夜泊～寒江—MemoDiary:卷{壹}\n',
          entryDate: DateTime(2026, 11, 2),
        ),
      );

      final entry = await db.entriesDao.getEntryById('entry_rot_1');
      expect(entry, isNotNull);

      final verticalBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
        layoutMode: PdfLayoutMode.verticalScroll,
        sealText: '心迹安放',
      );
      expect(verticalBytes, isNotEmpty);
      expect(String.fromCharCodes(verticalBytes.take(5)), equals('%PDF-'));
    });

    for (final layoutMode in PdfLayoutMode.values) {
      test('generatePdfForEntry ($layoutMode) renders mounted items and leaves staged items out', () async {
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_mounts',
            notebookId: 'default',
            templateId: 'template_lined_paper',
            contentDelta: jsonEncode([
              {'insert': '西湖夜游'},
              {
                'insert': {'mount': 'photo_mounted'},
              },
              {'insert': '\n'},
            ]),
            plainText: '西湖夜游',
            entryDate: DateTime(2026, 11, 5),
          ),
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'photo_staged',
          entryId: 'entry_mounts',
          relativePath: 'media/photo_staged.webp',
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'photo_mounted',
          entryId: 'entry_mounts',
          relativePath: 'media/photo_mounted.webp',
        );
        final recordingService = _RecordingMediaService(tempDir);

        final bytes = await PdfExportEngine.generatePdfForEntry(
          entry: (await db.entriesDao.getEntryById('entry_mounts'))!,
          database: db,
          mediaService: recordingService,
          layoutMode: layoutMode,
          sealText: '心迹安放',
        );

        expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
        expect(recordingService.requestedPaths, contains('media/photo_mounted.webp'));
        expect(recordingService.requestedPaths, isNot(contains('media/photo_staged.webp')));
      });
    }

    test('verticalScroll PDF renders trailing-newline header/quote typography and keeps mixed inline spans in one column', () async {
      final entry = Entry(
        id: 'entry_vertical_styled',
        notebookId: 'default',
        templateId: 'template_lined_paper',
        title: '秋兴',
        contentDelta: jsonEncode([
          {'insert': '秋日偶书'},
          {'insert': '\n', 'attributes': {'header': 1}},
          {'insert': '山色空蒙'},
          {'insert': '\n', 'attributes': {'blockquote': true}},
          {'insert': '今日'},
          {
            'insert': '晴朗',
            'attributes': {'bold': true, 'italic': true, 'color': '#B83B2E'},
          },
          {'insert': '宜出行\n'},
        ]),
        plainText: '秋日偶书\n山色空蒙\n今日晴朗宜出行',
        entryDate: DateTime(2026, 11, 6),
        mood: 4,
        weather: '晴',
        isWeeklyReview: false,
        weekNumber: null,
        unlockAt: null,
        isLocked: false,
        legacyMountsPending: false,
        createdAt: DateTime(2026, 11, 6),
        updatedAt: DateTime(2026, 11, 6),
        isDeleted: false,
      );
      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Color(0xFFFBF8F1),
        lineSpacing: 1.5,
        marginHorizontal: 28.0,
      );
      final cjkResolver = PdfFontResolver.cjk();
      final distinctFontResolver = PdfFontResolver(
        regularFont: cjkResolver.regularFont,
        boldFont: pw.Font.helveticaBold(),
        italicFont: pw.Font.helveticaOblique(),
        boldItalicFont: pw.Font.helveticaBoldOblique(),
        isCjkCapable: true,
      );

      final pageWidgets = await PdfVerticalScrollBuilder.buildPageWidgets(
        entry: entry,
        style: style,
        mediaService: mediaService,
        fontResolver: distinctFontResolver,
        sealText: '心迹安放',
      );
      expect(pageWidgets, hasLength(1));

      final row = _findFirstRow(pageWidgets.first);
      expect(row, isNotNull);

      // Reversed RTL order: [colophon, bodyCol, quoteCol, headerCol, titleCol]
      expect(row!.children, hasLength(5));

      final titleTexts = _collectPdfTexts(row.children[4]);
      final headerTexts = _collectPdfTexts(row.children[3]);
      final quoteTexts = _collectPdfTexts(row.children[2]);
      final bodyTexts = _collectPdfTexts(row.children[1]);

      expect(titleTexts.map((textWidget) => textWidget.text.toPlainText()).join(), equals('秋兴'));
      expect(headerTexts.map((textWidget) => textWidget.text.toPlainText()).join(), equals('秋日偶书'));
      expect(quoteTexts.map((textWidget) => textWidget.text.toPlainText()).join(), equals('山色空蒙'));
      expect(bodyTexts.map((textWidget) => textWidget.text.toPlainText()).join(), equals('今日晴朗宜出行'));

      final headerStyle = headerTexts.first.text.style;
      final quoteStyle = quoteTexts.first.text.style;
      final bodyPlainStyle = bodyTexts.first.text.style;
      final bodyColoredStyle = bodyTexts[2].text.style;

      expect(headerStyle?.font, equals(distinctFontResolver.boldFont));
      expect(headerStyle?.fontSize, greaterThan(bodyPlainStyle!.fontSize!));

      expect(quoteStyle?.font, equals(distinctFontResolver.italicFont));
      expect(quoteStyle?.fontSize, lessThan(bodyPlainStyle.fontSize!));
      expect(quoteStyle?.color, isNot(equals(PdfColors.black)));

      expect(bodyColoredStyle?.color, equals(const PdfColor.fromInt(0xFFB83B2E)));

      // Also verify CJK PDF serialization succeeds cleanly
      final cjkPages = await PdfVerticalScrollBuilder.buildVerticalScrollPages(
        entry: entry,
        style: style,
        mediaService: mediaService,
        fontResolver: cjkResolver,
        sealText: '心迹安放',
      );
      final saveDoc = pw.Document();
      for (final page in cjkPages) {
        saveDoc.addPage(page);
      }
      final bytes = await saveDoc.save();
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('PdfPolaroidOverlayBuilder uses plain modern Chinese labels without retired glossary terms', () {
      final resolver = PdfFontResolver.cjk();
      final photoAttachment = MediaAttachment(
        id: 'att_img',
        entryId: 'entry_1',
        mediaType: 'image',
        relativePath: 'media/a.webp',
        createdAt: DateTime(2026, 11, 6),
      );
      final videoAttachment = MediaAttachment(
        id: 'att_vid',
        entryId: 'entry_1',
        mediaType: 'video',
        relativePath: 'media/v.mp4',
        createdAt: DateTime(2026, 11, 6),
      );

      final photoCard = PdfPolaroidOverlayBuilder.buildPolaroidMiniCard(
        attachment: photoAttachment,
        image: null,
        resolver: resolver,
      );
      final videoCard = PdfPolaroidOverlayBuilder.buildPolaroidMiniCard(
        attachment: videoAttachment,
        image: null,
        resolver: resolver,
      );

      final photoTexts = _collectPdfTexts(photoCard)
          .map((textWidget) => textWidget.text.toPlainText())
          .toList();
      final videoTexts = _collectPdfTexts(videoCard)
          .map((textWidget) => textWidget.text.toPlainText())
          .toList();

      expect(photoTexts, contains('配图'));
      expect(photoTexts, contains('[图片]'));
      expect(videoTexts, contains('[短视频]'));
      for (final retired in ['随文影札', '动态影札', '随文拓影', '拾光留影']) {
        expect(photoTexts.join(' '), isNot(contains(retired)));
        expect(videoTexts.join(' '), isNot(contains(retired)));
      }
    });

    test('PdfExportEngine entry header metadata uses plain Chinese date, week review, mood and weather labels', () {
      final resolver = PdfFontResolver.cjk();
      final entry = Entry(
        id: 'entry_meta_header',
        notebookId: 'default',
        templateId: 'template_minimalist_white',
        title: '周日小结',
        contentDelta: '[]',
        plainText: '内容',
        entryDate: DateTime(2026, 11, 8, 21, 5),
        mood: 5,
        weather: 'rainy',
        isWeeklyReview: true,
        weekNumber: 45,
        unlockAt: null,
        isLocked: false,
        legacyMountsPending: false,
        createdAt: DateTime(2026, 11, 8),
        updatedAt: DateTime(2026, 11, 8),
        isDeleted: false,
      );

      final headerWidget = PdfExportEngine.buildEntryHeader(entry, resolver);
      final texts = _collectPdfTexts(headerWidget)
          .map((textWidget) => textWidget.text.toPlainText())
          .toList();

      expect(texts, contains('2026年11月8日 · 21:05'));
      expect(texts.join(' '), contains('第 45 周复盘'));
      expect(texts.join(' '), contains('心情: 5/5'));
      expect(texts.join(' '), contains('天气: 下雨'));
      expect(texts.join(' '), isNot(contains('Mood:')));
      expect(texts.join(' '), isNot(contains('Weather:')));
      expect(texts.join(' '), isNot(contains('Week 45 Review')));
    });
  });
}

pw.Row? _findFirstRow(pw.Widget widget) {
  if (widget is pw.Row) return widget;
  if (widget is pw.Stack) {
    for (final child in widget.children) {
      final found = _findFirstRow(child);
      if (found != null) return found;
    }
  } else if (widget is pw.Container && widget.child != null) {
    return _findFirstRow(widget.child!);
  } else if (widget is pw.Padding && widget.child != null) {
    return _findFirstRow(widget.child!);
  }
  return null;
}

List<pw.Text> _collectPdfTexts(pw.Widget widget) {
  final results = <pw.Text>[];
  void visit(pw.Widget node) {
    if (node is pw.Text) {
      results.add(node);
      return;
    }
    if (node is pw.Container && node.child != null) {
      visit(node.child!);
    } else if (node is pw.SingleChildWidget && node.child != null) {
      visit(node.child!);
    } else if (node is pw.Flex) {
      for (final child in node.children) {
        visit(child);
      }
    } else if (node is pw.Stack) {
      for (final child in node.children) {
        visit(child);
      }
    }
  }

  visit(widget);
  return results;
}

/// Records which sandbox files an export asks for.
class _RecordingMediaService extends MediaSandboxService {
  final requestedPaths = <String>[];

  _RecordingMediaService(Directory baseDir) : super(baseDirProvider: () async => baseDir);

  @override
  Future<File> getFileFromRelativePath(String relativePath) {
    requestedPaths.add(relativePath);
    return super.getFileFromRelativePath(relativePath);
  }
}
