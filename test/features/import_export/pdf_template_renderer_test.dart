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
  });
}

