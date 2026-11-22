import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/documents/vertical_typography_mapper.dart';
import '../../editor/widgets/journal_letterhead_models.dart';
import '../../settings/services/signature_seal_service.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../timeline/services/folio_media_pairing.dart';
import '../models/pdf_layout_mode.dart';
import 'pdf_entry_serializer.dart';
import 'pdf_font_resolver.dart';
import 'pdf_polaroid_overlay_builder.dart';
import 'pdf_template_renderer.dart';
import 'pdf_vertical_scroll_builder.dart';

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
    PdfLayoutMode layoutMode = PdfLayoutMode.horizontal,
    String? sealText,
    SignatureSealService? sealService,
  }) async {
    final resolver = fontResolver ?? await PdfFontResolver.loadOfflineCjk();

    // 1. Resolve visual template
    final template = await database.templatesDao.getTemplateById(entry.templateId) ??
        (await database.templatesDao.getAllTemplates()).first;
    final style = TemplateStyle.fromTemplate(template);

    // 2. Resolve diarist colophon signature seal inscription
    final sealManager = sealService ?? SignatureSealService();
    final effectiveSealText = sealText ?? await sealManager.getSealText();

    // 2b. Pair mounted media with sheets exactly as the Thread-Bound Folio does;
    // staged (unmounted) attachments are left out.
    final mountPlan = FolioMediaPairing.pairLeaves(
      entry: entry,
      attachments: await database.mediaOcrDao.getMediaForEntry(entry.id),
      templateStyle: style,
    );

    final doc = pw.Document();

    // 3. Classical Right-to-Left Vertical Keepsake Scroll mode
    if (layoutMode == PdfLayoutMode.verticalScroll) {
      final pages = await PdfVerticalScrollBuilder.buildVerticalScrollPages(
        entry: entry,
        style: style,
        mediaService: mediaService,
        fontResolver: resolver,
        sealText: effectiveSealText,
        mountPlan: mountPlan,
        pageFormat: pageFormat,
      );
      for (final page in pages) {
        doc.addPage(page);
      }
      return doc.save();
    }

    // 4. Standard Horizontal Stationery mode (default): one section per sheet,
    // each carrying the overlay cards of the items mounted on it (at most three,
    // paired exactly as the Folio pairs leaves). An entry with nothing mounted
    // renders as one continuous flow.
    final sectionWidgets = <pw.Widget>[];
    if (!mountPlan.hasMounts) {
      sectionWidgets.addAll(await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: entry.contentDelta,
        fallbackPlainText: entry.plainText,
        mediaService: mediaService,
        style: style,
        fontResolver: resolver,
      ));
    }
    final sections = mountPlan.hasMounts ? mountPlan.sections : const <FolioSheetSection>[];
    final mountsBySheet = mountPlan.mountsByLeaf(mountPlan.textSheetMounts.length);
    var textSheetOrdinal = 0;
    for (final section in sections) {
      final widgets = await PdfEntrySerializer.convertOpsToWidgets(
        ops: section.deltaOps,
        fallbackPlainText: entry.plainText,
        mediaService: mediaService,
        style: style,
        fontResolver: resolver,
      );
      final mounted = section.isText ? mountsBySheet[textSheetOrdinal++] : const <MediaAttachment>[];
      if (mounted.isEmpty) {
        sectionWidgets.addAll(widgets);
        continue;
      }
      final overlayCards = await PdfPolaroidOverlayBuilder.buildOverlayCards(
        attachments: mounted,
        mediaService: mediaService,
        resolver: resolver,
        availableWidth: pageFormat.width - (style.marginHorizontal.clamp(20.0, 60.0) * 2),
        availableHeight: pageFormat.height - 72.0,
        isVertical: false,
      );
      sectionWidgets.add(pw.Stack(
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: widgets),
          ...overlayCards,
        ],
      ));
    }

    final horizontalMetrics = StationeryLayoutCalculator.calculateMetrics(
      canvasWidth: pageFormat.width,
      canvasHeight: pageFormat.height,
      backgroundType: style.type,
      horizontalMargin: style.resolvedHorizontalMargin,
      lineSpacing: style.lineSpacing,
    );
    final horizontalLeftMargin = horizontalMetrics.innerFrameRect.left +
        (style.type == TemplateBackgroundType.lined ? 20.0 : 12.0);
    final horizontalRightMargin =
        (pageFormat.width - horizontalMetrics.innerFrameRect.right) + 12.0;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.fromLTRB(
            horizontalLeftMargin,
            24.0,
            horizontalRightMargin,
            20.0,
          ),
          buildBackground: (context) =>
              PdfTemplateRenderer.buildBackground(context, style),
        ),
        header: (context) =>
            PdfTemplateRenderer.buildHeader(context, entry, style, resolver),
        footer: (context) =>
            PdfTemplateRenderer.buildFooter(context, entry, style, resolver),
        build: (context) => [
          buildEntryHeader(entry, resolver),
          pw.SizedBox(height: 10),
          ...sectionWidgets,
          _buildSealColophon(
            style: style,
            resolver: resolver,
            sealText: effectiveSealText,
          ),
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
    String? sealText,
    SignatureSealService? sealService,
  }) async {
    final resolver = fontResolver ?? await PdfFontResolver.loadOfflineCjk();
    final sealManager = sealService ?? SignatureSealService();
    final effectiveSealText = sealText ?? await sealManager.getSealText();
    final doc = pw.Document();

    if (entries.isEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) => pw.Center(
            child: pw.Text(
              resolver.sanitizeText('未选择要导出的日记。'),
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
      ..sort((first, second) => first.entryDate.compareTo(second.entryDate));

    final title = resolver.sanitizeText(bookTitle ?? '云皓日记合集');
    final startDateStr =
        DateFormat('yyyy年M月d日').format(sortedEntries.first.entryDate);
    final endDateStr =
        DateFormat('yyyy年M月d日').format(sortedEntries.last.entryDate);
    final dateRangeStr = resolver.sanitizeText('$startDateStr - $endDateStr');

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
                  resolver.sanitizeText('共 ${sortedEntries.length} 篇日记'),
                  style: pw.TextStyle(
                    font: resolver.italicFont,
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 60),
                pw.Text(
                  resolver.sanitizeText('云皓日记 · 本地离线私密存储'),
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
      final template = await database.templatesDao.getTemplateById(entry.templateId) ??
          (await database.templatesDao.getAllTemplates()).first;
      final style = TemplateStyle.fromTemplate(template);

      final contentWidgets = await PdfEntrySerializer.convertDeltaToWidgets(
        contentDeltaJson: entry.contentDelta,
        fallbackPlainText: entry.plainText,
        mediaService: mediaService,
        style: style,
        fontResolver: resolver,
      );

      final horizontalMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: pageFormat.width,
        canvasHeight: pageFormat.height,
        backgroundType: style.type,
        horizontalMargin: style.resolvedHorizontalMargin,
        lineSpacing: style.lineSpacing,
      );
      final horizontalLeftMargin = horizontalMetrics.innerFrameRect.left +
          (style.type == TemplateBackgroundType.lined ? 20.0 : 12.0);
      final horizontalRightMargin =
          (pageFormat.width - horizontalMetrics.innerFrameRect.right) + 12.0;

      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.fromLTRB(
              horizontalLeftMargin,
              24.0,
              horizontalRightMargin,
              20.0,
            ),
            buildBackground: (context) =>
                PdfTemplateRenderer.buildBackground(context, style),
          ),
          header: (context) =>
              PdfTemplateRenderer.buildHeader(context, entry, style, resolver),
          footer: (context) =>
              PdfTemplateRenderer.buildFooter(context, entry, style, resolver),
          build: (context) => [
            buildEntryHeader(entry, resolver),
            pw.SizedBox(height: 10),
            ...contentWidgets,
            _buildSealColophon(
              style: style,
              resolver: resolver,
              sealText: effectiveSealText,
            ),
          ],
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildSealColophon({
    required TemplateStyle style,
    required PdfFontResolver resolver,
    required String sealText,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      alignment: pw.Alignment.centerRight,
      child: PdfTemplateRenderer.buildSignatureSeal(
        style: style,
        fontResolver: resolver,
        sealText: sealText,
      ),
    );
  }

  /// Builds the top metadata banner for an entry (date, mood, weather, title, divider).
  @visibleForTesting
  static pw.Widget buildEntryHeader(Entry entry, PdfFontResolver fontResolver) {
    final dateFormatted = fontResolver.sanitizeText(
      DateFormat('yyyy年M月d日 · HH:mm').format(entry.entryDate),
    );

    final metadataBadges = <String>[];
    if (entry.isWeeklyReview) {
      metadataBadges.add(
        entry.weekNumber != null ? '第 ${entry.weekNumber} 周复盘' : '每周复盘',
      );
    }
    if (entry.mood != null) {
      metadataBadges.add('心情: ${entry.mood}/5');
    }
    final weatherLabel = JournalLetterheadUtils.resolveWeatherLabel(entry.weather);
    if (weatherLabel != null) {
      metadataBadges.add('天气: $weatherLabel');
    }

    final rawTitle = entry.title?.trim() ?? '';
    final cleanTitle = VerticalTypographyMapper.formatInterlinearAsInline(rawTitle);
    final title = fontResolver.sanitizeText(cleanTitle);

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
                fontResolver.sanitizeText(metadataBadges.join('  ·  ')),
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
