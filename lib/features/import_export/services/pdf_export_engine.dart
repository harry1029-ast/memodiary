import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import 'pdf_entry_serializer.dart';
import 'pdf_font_resolver.dart';
import 'pdf_template_renderer.dart';

/// Core high-fidelity PDF export engine.
/// Compiles entries into single-entry or consolidated multi-entry journal books
/// faithfully preserving procedural vector template backgrounds, Quill Delta rich text,
/// and sandboxed media embeds with 100% offline network quarantine.
class PdfExportEngine {
  const PdfExportEngine._();

  /// Generates a PDF byte array for a single diary entry preserving its active visual template.
  static Future<Uint8List> generatePdfForEntry({
    required Entry entry,
    required AppDatabase database,
    required MediaSandboxService mediaService,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    PdfFontResolver? fontResolver,
  }) async {
    final resolver = fontResolver ?? PdfFontResolver.cjk();

    // 1. Resolve visual template
    final template = await database.getTemplateById(entry.templateId) ??
        (await database.getAllTemplates()).first;
    final style = TemplateStyle.fromTemplate(template);

    // 2. Convert Quill Delta into flowable PDF widgets
    final contentWidgets = await PdfEntrySerializer.convertDeltaToWidgets(
      contentDeltaJson: entry.contentDelta,
      fallbackPlainText: entry.plainText,
      mediaService: mediaService,
      style: style,
      fontResolver: resolver,
    );

    // 3. Build Document
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.symmetric(
            horizontal: style.marginHorizontal.clamp(20.0, 60.0),
            vertical: 36.0,
          ),
          buildBackground: (context) =>
              PdfTemplateRenderer.buildBackground(context, style),
        ),
        header: (context) =>
            PdfTemplateRenderer.buildHeader(context, entry, style, resolver),
        footer: (context) =>
            PdfTemplateRenderer.buildFooter(context, entry, style, resolver),
        build: (context) => [
          _buildEntryHeader(entry, resolver),
          pw.SizedBox(height: 10),
          ...contentWidgets,
        ],
      ),
    );

    return doc.save();
  }

  /// Generates a consolidated multi-entry PDF document (Journal Book) with an archive cover page
  /// where each entry preserves its individual visual template canvas background.
  static Future<Uint8List> generateConsolidatedPdf({
    required List<Entry> entries,
    required AppDatabase database,
    required MediaSandboxService mediaService,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    String? bookTitle,
    PdfFontResolver? fontResolver,
  }) async {
    final resolver = fontResolver ?? PdfFontResolver.cjk();
    final doc = pw.Document();

    if (entries.isEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) => pw.Center(
            child: pw.Text(
              'No entries selected for export.',
              style: pw.TextStyle(
                font: resolver.regularFont,
                fontSize: 14,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
      );
      return doc.save();
    }

    // Sort entries chronologically for book format
    final sortedEntries = List<Entry>.from(entries)
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

    final title = resolver.sanitizeText(bookTitle ?? 'MemoDiary Journal Archive');
    final startDateStr =
        DateFormat('MMM d, y').format(sortedEntries.first.entryDate);
    final endDateStr =
        DateFormat('MMM d, y').format(sortedEntries.last.entryDate);
    final dateRangeStr = '$startDateStr - $endDateStr';

    // 1. Archive Cover Page
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: resolver.boldFont,
                    fontSize: 26,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: 80,
                  height: 2,
                  color: PdfColors.grey700,
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  dateRangeStr,
                  style: pw.TextStyle(
                    font: resolver.regularFont,
                    fontSize: 13,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '${sortedEntries.length} ${sortedEntries.length == 1 ? "Entry" : "Entries"}',
                  style: pw.TextStyle(
                    font: resolver.italicFont,
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 60),
                pw.Text(
                  'MemoDiary · 100% Private, Sandboxed & Local-First',
                  style: pw.TextStyle(
                    font: resolver.regularFont,
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 2. Sequential Entry MultiPages preserving individual visual templates
    for (final entry in sortedEntries) {
      final template = await database.getTemplateById(entry.templateId) ??
          (await database.getAllTemplates()).first;
      final style = TemplateStyle.fromTemplate(template);

      final contentWidgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: entry.contentDelta,
        fallbackPlainText: entry.plainText,
        mediaService: mediaService,
        style: style,
        fontResolver: resolver,
      );

      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.symmetric(
              horizontal: style.marginHorizontal.clamp(20.0, 60.0),
              vertical: 36.0,
            ),
            buildBackground: (context) =>
                PdfTemplateRenderer.buildBackground(context, style),
          ),
          header: (context) =>
              PdfTemplateRenderer.buildHeader(context, entry, style, resolver),
          footer: (context) =>
              PdfTemplateRenderer.buildFooter(context, entry, style, resolver),
          build: (context) => [
            _buildEntryHeader(entry, resolver),
            pw.SizedBox(height: 10),
            ...contentWidgets,
          ],
        ),
      );
    }

    return doc.save();
  }

  /// Builds the top metadata banner for an entry (date, mood, weather, title, divider).
  static pw.Widget _buildEntryHeader(Entry entry, PdfFontResolver fontResolver) {
    final dateFormatted =
        DateFormat('EEEE, MMMM d, y · h:mm a').format(entry.entryDate);

    final metadataBadges = <String>[];
    if (entry.isWeeklyReview) {
      metadataBadges.add('Week ${entry.weekNumber ?? ""} Review');
    }
    if (entry.mood != null) {
      metadataBadges.add('Mood: ${entry.mood}/5');
    }
    if (entry.weather != null && entry.weather!.isNotEmpty) {
      metadataBadges.add('Weather: ${entry.weather}');
    }

    final rawTitle = entry.title?.trim() ?? '';
    final title = fontResolver.sanitizeText(rawTitle);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              dateFormatted,
              style: pw.TextStyle(
                font: fontResolver.regularFont,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            if (metadataBadges.isNotEmpty)
              pw.Text(
                metadataBadges.join('  ·  '),
                style: pw.TextStyle(
                  font: fontResolver.boldFont,
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
          ],
        ),
        if (title.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontResolver.boldFont,
              fontSize: 20,
              color: PdfColors.black,
            ),
          ),
        ],
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.8, color: PdfColors.grey300),
      ],
    );
  }
}
