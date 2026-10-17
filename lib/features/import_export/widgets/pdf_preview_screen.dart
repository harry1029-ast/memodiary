import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../services/pdf_export_engine.dart';
import '../services/pdf_font_resolver.dart';

/// Screen hosting interactive [PdfPreview] with direct PDF printing,
/// file saving, sharing, and template-preserving page layout rendering.
class PdfPreviewScreen extends StatelessWidget {
  final Entry? singleEntry;
  final List<Entry>? entries;
  final AppDatabase database;
  final MediaSandboxService? mediaService;
  final String? documentTitle;
  final PdfFontResolver? fontResolver;

  const PdfPreviewScreen({
    super.key,
    this.singleEntry,
    this.entries,
    required this.database,
    this.mediaService,
    this.documentTitle,
    this.fontResolver,
  });

  @override
  Widget build(BuildContext context) {
    final title = documentTitle ??
        (singleEntry != null
            ? (singleEntry!.title?.trim().isNotEmpty ?? false
                ? singleEntry!.title!.trim()
                : 'MemoDiary Entry')
            : 'MemoDiary Journal Book');

    final effectiveMediaService = mediaService ?? MediaSandboxService();

    final pdfFileName = singleEntry != null
        ? 'memodiary_${singleEntry!.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.pdf'
        : 'memodiary_journal.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          if (singleEntry != null) {
            return PdfExportEngine.generatePdfForEntry(
              entry: singleEntry!,
              database: database,
              mediaService: effectiveMediaService,
              pageFormat: format,
              fontResolver: fontResolver,
            );
          } else {
            final list = entries ?? await database.getTimelineEntries(limit: 100);
            return PdfExportEngine.generateConsolidatedPdf(
              entries: list,
              database: database,
              mediaService: effectiveMediaService,
              pageFormat: format,
              bookTitle: title,
              fontResolver: fontResolver,
            );
          }
        },
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: true,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: pdfFileName,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Generating vector PDF...'),
            ],
          ),
        ),
      ),
    );
  }
}

