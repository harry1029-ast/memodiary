import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../models/pdf_layout_mode.dart';
import '../services/pdf_export_engine.dart';
import '../services/pdf_font_resolver.dart';

/// Screen hosting interactive [PdfPreview] with direct PDF printing,
/// file saving, sharing, and template-preserving page layout rendering
/// in either Horizontal Stationery or Vertical Keepsake Scroll modes.
class PdfPreviewScreen extends StatefulWidget {
  final Entry? singleEntry;
  final List<Entry>? entries;
  final AppDatabase database;
  final MediaSandboxService? mediaService;
  final String? documentTitle;
  final PdfFontResolver? fontResolver;
  final PdfLayoutMode initialLayoutMode;

  const PdfPreviewScreen({
    super.key,
    this.singleEntry,
    this.entries,
    required this.database,
    this.mediaService,
    this.documentTitle,
    this.fontResolver,
    this.initialLayoutMode = PdfLayoutMode.horizontal,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfLayoutMode _layoutMode;

  @override
  void initState() {
    super.initState();
    _layoutMode = widget.initialLayoutMode;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.documentTitle ??
        (widget.singleEntry != null
            ? (widget.singleEntry!.title?.trim().isNotEmpty ?? false
                ? widget.singleEntry!.title!.trim()
                : 'MemoDiary Entry')
            : 'MemoDiary Journal Book');

    final effectiveMediaService = widget.mediaService ?? MediaSandboxService();

    final pdfFileName = widget.singleEntry != null
        ? 'memodiary_${widget.singleEntry!.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.pdf'
        : 'memodiary_journal.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.singleEntry != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: SegmentedButton<PdfLayoutMode>(
                key: const Key('pdf_layout_mode_toggle'),
                segments: const [
                  ButtonSegment(
                    value: PdfLayoutMode.horizontal,
                    label: Text('横排素笺', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: PdfLayoutMode.verticalScroll,
                    label: Text('卷轴竖排', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_layoutMode},
                onSelectionChanged: (val) {
                  setState(() => _layoutMode = val.first);
                },
              ),
            ),
        ],
      ),
      body: PdfPreview(
        key: ValueKey(_layoutMode),
        build: (format) async {
          if (widget.singleEntry != null) {
            return PdfExportEngine.generatePdfForEntry(
              entry: widget.singleEntry!,
              database: widget.database,
              mediaService: effectiveMediaService,
              pageFormat: _layoutMode == PdfLayoutMode.verticalScroll
                  ? format.landscape
                  : format,
              fontResolver: widget.fontResolver,
              layoutMode: _layoutMode,
            );
          } else {
            final list = widget.entries ??
                await widget.database.entriesDao.getTimelineEntries(limit: 100);
            return PdfExportEngine.generateConsolidatedPdf(
              entries: list,
              database: widget.database,
              mediaService: effectiveMediaService,
              pageFormat: format,
              bookTitle: title,
              fontResolver: widget.fontResolver,
            );
          }
        },
        initialPageFormat: _layoutMode == PdfLayoutMode.verticalScroll
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4,
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
