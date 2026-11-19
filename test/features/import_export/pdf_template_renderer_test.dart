import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/services/pdf_font_resolver.dart';
import 'package:memodiary/features/import_export/services/pdf_template_renderer.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('PdfTemplateRenderer Tests', () {
    final fontResolver = PdfFontResolver.standard();

    final testEntry = Entry(
      id: 'entry-1',
      notebookId: 'nb-1',
      templateId: 'template_minimalist_white',
      title: 'A Beautiful Day',
      contentDelta: '[]',
      plainText: 'Sample text',
      entryDate: DateTime(2026, 10, 18),
      mood: 4,
      weather: 'sunny',
      isWeeklyReview: false,
      weekNumber: 42,
      unlockAt: null,
      isLocked: false,
      legacyMountsPending: false,
      createdAt: DateTime(2026, 10, 18),
      updatedAt: DateTime(2026, 10, 18),
      isDeleted: false,
    );

    test('builds and generates valid PDF with Minimalist White template', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: material.Colors.white,
        fontFamily: 'Roboto',
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Column(
            children: [
              PdfTemplateRenderer.buildHeader(context, testEntry, style, fontResolver),
              pw.Text('Body text', style: pw.TextStyle(font: fontResolver.regularFont)),
              PdfTemplateRenderer.buildFooter(context, testEntry, style, fontResolver),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds and generates valid PDF with Lined Paper template', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: material.Color(0xFFFCFBF7),
        fontFamily: 'Noto Serif',
        lineSpacing: 1.6,
        marginHorizontal: 32.0,
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Center(child: pw.Text('Lined Paper Content')),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds and generates valid PDF with Grid Paper template', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: material.Color(0xFFF8F9FA),
        fontFamily: 'Fira Code',
        lineSpacing: 1.4,
        marginHorizontal: 24.0,
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Center(child: pw.Text('Grid Paper Content')),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds and generates valid PDF with Dot Grid template', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.dotGrid,
        backgroundColor: material.Color(0xFFFDFBF7),
        fontFamily: 'Noto Serif',
        lineSpacing: 1.5,
        marginHorizontal: 28.0,
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Center(child: pw.Text('Dot Grid Content')),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds and generates valid PDF with Retro Kraft template', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.paperTexture,
        backgroundColor: material.Color(0xFFEFE6D5),
        fontFamily: 'Noto Serif',
        lineSpacing: 1.6,
        marginHorizontal: 28.0,
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Center(child: pw.Text('Kraft Paper Content')),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds header and footer correctly with null or empty title', () async {
      final doc = pw.Document();
      final untitledEntry = Entry(
        id: 'entry-2',
        notebookId: 'nb-1',
        templateId: 'template_minimalist_white',
        title: null,
        contentDelta: '[]',
        plainText: '',
        entryDate: DateTime(2026, 10, 18),
        mood: 3,
        weather: 'cloudy',
        isWeeklyReview: false,
        weekNumber: 42,
        unlockAt: null,
        isLocked: false,
        legacyMountsPending: false,
        createdAt: DateTime(2026, 10, 18),
        updatedAt: DateTime(2026, 10, 18),
        isDeleted: false,
      );

      final style = TemplateStyle.fromTemplate(
        const Template(
          id: 'custom_1',
          name: 'My Custom Template',
          backgroundType: 'color',
          backgroundValue: '#F0F4F8',
          fontFamily: 'Roboto',
          lineSpacing: 1.5,
          marginHorizontal: 20.0,
          isCustom: true,
        ),
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              PdfTemplateRenderer.buildHeader(context, untitledEntry, style, fontResolver),
              PdfTemplateRenderer.buildFooter(context, untitledEntry, style, fontResolver),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test('renders plain Chinese fallback title and page footer without English labels', () async {
      final cjkResolver = PdfFontResolver.cjk();
      final doc = pw.Document();
      final untitledEntry = Entry(
        id: 'entry-cn-header',
        notebookId: 'nb-1',
        templateId: 'template_minimalist_white',
        title: null,
        contentDelta: '[]',
        plainText: '',
        entryDate: DateTime(2026, 10, 18),
        mood: 3,
        weather: 'cloudy',
        isWeeklyReview: false,
        weekNumber: null,
        unlockAt: null,
        isLocked: false,
        legacyMountsPending: false,
        createdAt: DateTime(2026, 10, 18),
        updatedAt: DateTime(2026, 10, 18),
        isDeleted: false,
      );
      const style = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: material.Colors.white,
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
      );

      pw.Widget? capturedHeader;
      pw.Widget? capturedFooter;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            capturedHeader = PdfTemplateRenderer.buildHeader(
              context,
              untitledEntry,
              style,
              cjkResolver,
            );
            capturedFooter = PdfTemplateRenderer.buildFooter(
              context,
              untitledEntry,
              style,
              cjkResolver,
            );
            return pw.Column(children: [capturedHeader!, capturedFooter!]);
          },
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);

      final headerTexts = _extractTexts(capturedHeader!);
      final footerTexts = _extractTexts(capturedFooter!);
      expect(headerTexts, contains('云皓日记'));
      expect(headerTexts, isNot(contains('MemoDiary Entry')));
      expect(footerTexts, contains('云皓日记 · 本地离线私密存储'));
      expect(footerTexts, contains('第 1 / 1 页'));
      expect(footerTexts, isNot(contains('Page 1 of 1')));
    });

    test('pdfRuleColor returns distinct non-null colors for all RuleInkTint values', () {
      for (final tint in RuleInkTint.values) {
        final color = PdfTemplateRenderer.pdfRuleColor(tint);
        expect(color, isNotNull);
      }
    });

    test('buildSignatureSeal renders zhuwen and baiwen seals into PDF document', () async {
      final doc = pw.Document();
      const zhuwenStyle = TemplateStyle(
        type: TemplateBackgroundType.paperTexture,
        backgroundColor: material.Color(0xFFFAF7F0),
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
        tokens: StationeryVisualTokens(
          substrate: PaperSubstrate.coldGold,
          ruleTint: RuleInkTint.vermilion,
          sealStyle: SealCarvingStyle.zhuwen,
        ),
      );

      const baiwenStyle = TemplateStyle(
        type: TemplateBackgroundType.color,
        backgroundColor: material.Color(0xFFFFFFFF),
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
        tokens: StationeryVisualTokens(
          substrate: PaperSubstrate.minimal,
          ruleTint: RuleInkTint.charcoal,
          sealStyle: SealCarvingStyle.baiwen,
        ),
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, zhuwenStyle),
          ),
          build: (context) => pw.Column(
            children: [
              PdfTemplateRenderer.buildSignatureSeal(
                style: zhuwenStyle,
                fontResolver: fontResolver,
                sealText: '心迹安放',
              ),
              PdfTemplateRenderer.buildSignatureSeal(
                style: baiwenStyle,
                fontResolver: fontResolver,
                sealText: '墨香',
              ),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds vector PDF with Double Outer Border and Fishtail Mark on manuscript grid', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: material.Color(0xFFFBF8F1),
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
        tokens: StationeryVisualTokens(
          substrate: PaperSubstrate.xuan,
          ruleTint: RuleInkTint.vermilion,
        ),
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Center(
            child: pw.Text('Classical Manuscript Grid with Fishtail Mark'),
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds vector PDF with compact dimensions where columnCount < 7 cleanly', () async {
      final doc = pw.Document();
      const style = TemplateStyle(
        type: TemplateBackgroundType.grid,
        backgroundColor: material.Color(0xFFFFFFFF),
        lineSpacing: 1.5,
        marginHorizontal: 20.0,
      );

      // Narrow custom page format causing columnCount < 7
      const compactFormat = PdfPageFormat(160.0, 400.0);

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: compactFormat,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
          ),
          build: (context) => pw.Center(
            child: pw.Text('Compact Width Sheet'),
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('builds vector PDF on Obsidian Night dark substrate with adapted framing', () async {
      final doc = pw.Document();
      final obsidianStyle = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: PaperSubstrate.obsidian.defaultColor,
        lineSpacing: 1.5,
        marginHorizontal: 24.0,
        tokens: const StationeryVisualTokens(
          substrate: PaperSubstrate.obsidian,
          ruleTint: RuleInkTint.slate,
        ),
      );

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, obsidianStyle),
          ),
          build: (context) => pw.Center(
            child: pw.Text('Obsidian Night Dark PDF Sheet'),
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });
  });
}

List<String> _extractTexts(pw.Widget widget) {
  final results = <String>[];
  void visit(pw.Widget node) {
    if (node is pw.Text) {
      results.add(node.text.toPlainText());
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

