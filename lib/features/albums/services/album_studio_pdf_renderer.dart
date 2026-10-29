import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../import_export/services/pdf_font_resolver.dart';
import '../models/album_studio_models.dart';
import '../widgets/album_collection_card.dart';
import 'album_pdf_exporter.dart';
import 'page_layout_catalog.dart';
import 'pdf_vector_graphics_painter.dart';

/// Encapsulates shared rendering dependencies (photos, decoded images, fonts)
/// across photobook studio page builders.
class StudioPdfRenderContext {
  final Map<String, AlbumPhoto> photoById;
  final Map<String, pw.MemoryImage> imageCache;
  final PdfFontResolver resolver;

  const StudioPdfRenderContext({
    required this.photoById,
    required this.imageCache,
    required this.resolver,
  });
}

/// Compiles an [AlbumStudioDocument] directly into WYSIWYG vector PDF pages.
///
/// Enforces:
/// - **Watchpoint 3 (2-Page Bound Spread Math)**: Partitions facing spreads strictly
///   at `x = 0.5 * W` with a `0.03 * W` spine crease shadow centered at `0.5 * W`.
/// - **Watchpoint 4 (Single-Page Overflow Protection)**: Clamps all captions,
///   date headers, and overlay texts with `maxLines: 2, overflow: pw.TextOverflow.clip`
///   and renders photos inside `pw.ClipRRect` with `pw.BoxFit.cover`.
class AlbumStudioPdfRenderer {
  const AlbumStudioPdfRenderer._();

  static final PdfColor _xuanGround = PdfColor.fromInt(0xFFFCF9F2);
  static final PdfColor _xuanPureLeaf = PdfColor.fromInt(0xFFFFFFFF);
  static final PdfColor _agedFiber = PdfColor.fromInt(0xFFEFE9DC);
  static final PdfColor _deckleBorder = PdfColor.fromInt(0xFFD8D1C3);
  static final PdfColor _jiaomo = PdfColor.fromInt(0xFF1E1E1E);
  static final PdfColor _danmo = PdfColor.fromInt(0xFF68645E);
  static final PdfColor _qingmo = PdfColor.fromInt(0xFF9E998F);
  static final PdfColor _cinnabar = PdfColor.fromInt(0xFFB83B2E);

  /// Appends all pages (or 2-page facing spreads) for [studioDocument] into [document].
  static void addStudioPagesToDocument({
    required pw.Document document,
    required AlbumCollection collection,
    required AlbumStudioDocument studioDocument,
    required Map<String, AlbumPhoto> photoById,
    required Map<String, pw.MemoryImage> imageCache,
    required AlbumPdfPageFormat format,
    required PdfFontResolver resolver,
  }) {
    final pageFormat = format.pdfFormat;
    final pages = studioDocument.pages;
    final renderContext = StudioPdfRenderContext(
      photoById: photoById,
      imageCache: imageCache,
      resolver: resolver,
    );

    if (format == AlbumPdfPageFormat.boundSpread) {
      _addBoundSpreads(
        document: document,
        pageFormat: pageFormat,
        collection: collection,
        studioDocument: studioDocument,
        renderContext: renderContext,
      );
      return;
    }

    // Single-page formats (A4 Landscape & Square Keepsake):
    // Page 1 is Front Cover leaf, followed by each AlbumPageModel, concluding with Epilogue Colophon.
    final totalPdfPages = pages.length + 2;

    // 1. Front Cover Page
    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => _buildSinglePageFrame(
          pageNumber: 1,
          totalPages: totalPdfPages,
          resolver: resolver,
          child: _buildCoverLeafPdf(
            collection: collection,
            totalPhotos: photoById.length,
            imageCache: imageCache,
            resolver: resolver,
          ),
        ),
      ),
    );

    // 2. Studio Content Pages
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      final pdfPageNum = pageIndex + 2;
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => _buildSinglePageFrame(
            pageNumber: pdfPageNum,
            totalPages: totalPdfPages,
            resolver: resolver,
            child: buildStudioPageLeaf(
              page: page,
              renderContext: renderContext,
            ),
          ),
        ),
      );
    }

    // 3. Epilogue Colophon Page
    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => _buildSinglePageFrame(
          pageNumber: totalPdfPages,
          totalPages: totalPdfPages,
          resolver: resolver,
          child: _buildColophonLeafPdf(
            collection,
            resolver,
          ),
        ),
      ),
    );
  }

  static void _addBoundSpreads({
    required pw.Document document,
    required PdfPageFormat pageFormat,
    required AlbumCollection collection,
    required AlbumStudioDocument studioDocument,
    required StudioPdfRenderContext renderContext,
  }) {
    final spreads = List<BookSpreadData>.from(
      studioDocument.buildSpreads(includeBlankTrailing: false),
    );

    // Ensure every bound photobook concludes with an Epilogue Colophon leaf.
    // If the last spread's right leaf is already occupied by a content page,
    // append a dedicated closing spread with the Colophon on the right leaf.
    if (spreads.isNotEmpty && spreads.last.rightPage != null) {
      spreads.add(
        const BookSpreadData(
          leftPage: null,
          rightPage: null,
        ),
      );
    }

    for (var spreadIndex = 0; spreadIndex < spreads.length; spreadIndex++) {
      final spread = spreads[spreadIndex];
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                color: _xuanGround,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _deckleBorder, width: 1.1),
              ),
              child: pw.LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints?.maxWidth ?? 1140.0;
                  final totalHeight = constraints?.maxHeight ?? 550.0;
                  final halfWidth = totalWidth * 0.5;
                  final spineWidth = totalWidth * 0.03;

                  final leftWidget = spread.isCoverLeft
                      ? _buildCoverLeafPdf(
                          collection: collection,
                          totalPhotos: renderContext.photoById.length,
                          imageCache: renderContext.imageCache,
                          resolver: renderContext.resolver,
                        )
                      : (spread.leftPage != null
                          ? buildStudioPageLeaf(
                              page: spread.leftPage!,
                              renderContext: renderContext,
                            )
                          : _buildBlankLeafPdf());

                  final rightWidget = spread.rightPage != null
                      ? buildStudioPageLeaf(
                          page: spread.rightPage!,
                          renderContext: renderContext,
                        )
                      : _buildColophonLeafPdf(
                          collection,
                          renderContext.resolver,
                        );

                  // Watchpoint 3 Guard: Partition strictly at x = 0.5 * W
                  // and center the 0.03 * W spine crease shadow at 0.5 * W.
                  return pw.Stack(
                    children: [
                      pw.Positioned(
                        left: 0,
                        top: 0,
                        child: pw.SizedBox(
                          width: halfWidth,
                          height: totalHeight,
                          child: leftWidget,
                        ),
                      ),
                      pw.Positioned(
                        left: halfWidth,
                        top: 0,
                        child: pw.SizedBox(
                          width: halfWidth,
                          height: totalHeight,
                          child: rightWidget,
                        ),
                      ),
                      pw.Positioned(
                        left: halfWidth - (spineWidth * 0.5),
                        top: 0,
                        child: pw.SizedBox(
                          width: spineWidth,
                          height: totalHeight,
                          child: _buildSpineCreasePdf(spineWidth, totalHeight),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      );
    }
  }

  static pw.Widget _buildSpineCreasePdf(double width, double height) {
    return pw.CustomPaint(
      size: PdfPoint(width, height),
      painter: (canvas, size) {
        final w = size.x;
        final h = size.y;
        canvas.saveContext();
        // Subtle multi-band spine crease shadow + center binding seam
        canvas
          ..setFillColor(const PdfColor(0.12, 0.11, 0.10, 0.05))
          ..drawRect(0, 0, w, h)
          ..fillPath()
          ..setFillColor(const PdfColor(0.12, 0.11, 0.10, 0.11))
          ..drawRect(w * 0.30, 0, w * 0.40, h)
          ..fillPath()
          ..setStrokeColor(const PdfColor(0.12, 0.11, 0.10, 0.24))
          ..setLineWidth(0.8)
          ..moveTo(w * 0.5, 0)
          ..lineTo(w * 0.5, h)
          ..strokePath();
        canvas.restoreContext();
      },
    );
  }

  /// Renders a single [AlbumPageModel] leaf with normalized `0.0..1.0` photo
  /// slots, background graphic motif, optional date header, and sorted overlays.
  static pw.Widget buildStudioPageLeaf({
    required AlbumPageModel page,
    required StudioPdfRenderContext renderContext,
  }) {
    final template = PageLayoutCatalog.getById(page.layoutTemplateId);
    final textColor = PdfColor.fromInt(page.backgroundConfig.textColorArgb);
    final sortedOverlays = List<PageOverlayElement>.from(page.overlays)
      ..sort((overlayA, overlayB) => overlayA.zIndex.compareTo(overlayB.zIndex));

    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints?.maxWidth ?? 520.0;
        final canvasHeight = constraints?.maxHeight ?? 520.0;
        final baseUnit = math.min(canvasWidth, canvasHeight);

        return pw.Stack(
          children: [
            // 1. Page Background Color & Procedural Vector Graphic Pattern
            pw.Positioned(
              left: 0,
              top: 0,
              child: pw.SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: PdfVectorGraphicsPainter.buildPageBackground(
                  page.backgroundConfig,
                ),
              ),
            ),

            // 2. Optional Date Header Slot
            if (template.dateHeaderSlot != null &&
                page.dateHeaderText != null &&
                page.dateHeaderText!.trim().isNotEmpty)
              _buildDateHeaderPdfSlot(
                normRect: template.dateHeaderSlot!,
                canvasW: canvasWidth,
                canvasH: canvasHeight,
                text: page.dateHeaderText!.trim(),
                textColor: textColor,
                resolver: renderContext.resolver,
              ),

            // 3. Normalized 0.0..1.0 Photo Slots
            for (var slotIndex = 0; slotIndex < template.slots.length; slotIndex++)
              _buildNormalizedPhotoSlotPdf(
                slotIndex: slotIndex,
                normRect: template.slots[slotIndex],
                canvasW: canvasWidth,
                canvasH: canvasHeight,
                assignment: slotIndex < page.photoSlots.length
                    ? page.photoSlots[slotIndex]
                    : null,
                renderContext: renderContext,
              ),

            // 4. Sorted Overlays (Stickers, Date Pills, Text Notes, Seal Stamps)
            for (final overlay in sortedOverlays)
              _buildPositionedOverlayPdf(
                overlay: overlay,
                canvasW: canvasWidth,
                canvasH: canvasHeight,
                baseUnit: baseUnit,
                defaultTextColorArgb: page.backgroundConfig.textColorArgb,
                resolver: renderContext.resolver,
              ),
          ],
        );
      },
    );
  }

  static ({double left, double top, double width, double height})
      _computeSlotBounds({
    required Rect normRect,
    required double canvasW,
    required double canvasH,
  }) {
    return (
      left: normRect.left * canvasW,
      top: normRect.top * canvasH,
      width: normRect.width * canvasW,
      height: normRect.height * canvasH,
    );
  }

  static pw.Widget _buildDateHeaderPdfSlot({
    required Rect normRect,
    required double canvasW,
    required double canvasH,
    required String text,
    required PdfColor textColor,
    required PdfFontResolver resolver,
  }) {
    final bounds = _computeSlotBounds(
      normRect: normRect,
      canvasW: canvasW,
      canvasH: canvasH,
    );
    final fontSize = math.max(9.0, math.min(canvasW, canvasH) * 0.032);

    return pw.Positioned(
      left: bounds.left,
      top: bounds.top,
      child: pw.SizedBox(
        width: bounds.width,
        height: bounds.height,
        child: pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            resolver.sanitizeText(text),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.boldFont,
              fontSize: fontSize,
              color: textColor,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildNormalizedPhotoSlotPdf({
    required int slotIndex,
    required Rect normRect,
    required double canvasW,
    required double canvasH,
    required PhotoSlotAssignment? assignment,
    required StudioPdfRenderContext renderContext,
  }) {
    final bounds = _computeSlotBounds(
      normRect: normRect,
      canvasW: canvasW,
      canvasH: canvasH,
    );
    final width = bounds.width;
    final height = bounds.height;

    final photo =
        assignment != null ? renderContext.photoById[assignment.photoId] : null;
    final memoryImage =
        photo != null ? renderContext.imageCache[photo.relativeImagePath] : null;
    final caption = photo?.caption?.trim();
    final resolver = renderContext.resolver;

    return pw.Positioned(
      left: bounds.left,
      top: bounds.top,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            color: _agedFiber,
            borderRadius: pw.BorderRadius.circular(3.5),
            border: pw.Border.all(color: _deckleBorder, width: 0.6),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 3.0,
            verticalRadius: 3.0,
            child: pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                if (memoryImage != null)
                  pw.Transform.scale(
                    scale: (assignment?.zoomScale ?? 1.0).clamp(1.0, 4.0),
                    child: pw.Transform.translate(
                      offset: PdfPoint(
                        (assignment?.panOffsetX ?? 0.0) * width,
                        -(assignment?.panOffsetY ?? 0.0) * height,
                      ),
                      child: pw.Image(
                        memoryImage,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      resolver.sanitizeText(photo?.locationTag ?? '拾光影像'),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        font: resolver.regularFont,
                        fontSize: 9,
                        color: _qingmo,
                      ),
                    ),
                  ),
                if (caption != null && caption.isNotEmpty && height >= 70)
                  pw.Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      color: const PdfColor(0.10, 0.10, 0.10, 0.52),
                      child: pw.Text(
                        resolver.sanitizeText(caption),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          font: resolver.regularFont,
                          fontSize: 7.5,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildPositionedOverlayPdf({
    required PageOverlayElement overlay,
    required double canvasW,
    required double canvasH,
    required double baseUnit,
    required int defaultTextColorArgb,
    required PdfFontResolver resolver,
  }) {
    final boxW = math.max(90.0, baseUnit * 0.40);
    final boxH = math.max(44.0, baseUnit * 0.20);
    final left = (overlay.dx * canvasW - boxW / 2).clamp(0.0, canvasW - boxW);
    final top = (overlay.dy * canvasH - boxH / 2).clamp(0.0, canvasH - boxH);

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.SizedBox(
        width: boxW,
        height: boxH,
        child: pw.Center(
          child: pw.Transform.rotate(
            angle: -overlay.rotation,
            child: pw.Transform.scale(
              scale: overlay.scale.clamp(0.5, 2.5),
              child: PdfVectorGraphicsPainter.buildOverlayWidget(
                overlay: overlay,
                defaultTextColorArgb: defaultTextColorArgb,
                baseUnit: baseUnit,
                resolver: resolver,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSinglePageFrame({
    required int pageNumber,
    required int totalPages,
    required PdfFontResolver resolver,
    required pw.Widget child,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: _xuanGround,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _deckleBorder, width: 1.0),
      ),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: _xuanPureLeaf,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _deckleBorder, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(child: child),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  resolver.sanitizeText('拾光手账 · 珍藏印本'),
                  style: pw.TextStyle(
                    font: resolver.regularFont,
                    fontSize: 8,
                    color: _qingmo,
                  ),
                ),
                pw.Text(
                  resolver.sanitizeText('第 $pageNumber / $totalPages 页'),
                  style: pw.TextStyle(
                    font: resolver.regularFont,
                    fontSize: 8,
                    color: _danmo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildCoverLeafPdf({
    required AlbumCollection collection,
    required int totalPhotos,
    required Map<String, pw.MemoryImage> imageCache,
    required PdfFontResolver resolver,
  }) {
    final dateLabel = AlbumCollectionCard.formatDateRange(
      collection.startDate,
      collection.endDate,
    );
    final sealText = (collection.destinationTag != null &&
            collection.destinationTag!.trim().isNotEmpty)
        ? collection.destinationTag!.trim()
        : '拾光';
    final coverImg = collection.coverImagePath != null
        ? imageCache[collection.coverImagePath!]
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(color: _xuanGround),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: _cinnabar,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              resolver.sanitizeText(
                sealText.length > 4 ? sealText.substring(0, 4) : sealText,
              ),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: resolver.boldFont,
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            resolver.sanitizeText(collection.title),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: resolver.boldFont,
              fontSize: 22,
              color: _jiaomo,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            resolver.sanitizeText('$dateLabel · 共 $totalPhotos 帧影像'),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: 10,
              color: _danmo,
            ),
          ),
          if (coverImg != null) ...[
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(coverImg, fit: pw.BoxFit.cover),
              ),
            ),
          ],
          if (collection.routeSummary != null &&
              collection.routeSummary!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              resolver.sanitizeText(collection.routeSummary!.trim()),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: resolver.regularFont,
                fontSize: 9.5,
                color: _danmo,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildBlankLeafPdf() {
    return pw.Container(color: _xuanGround);
  }

  static pw.Widget _buildColophonLeafPdf(
    AlbumCollection collection,
    PdfFontResolver resolver,
  ) {
    return pw.Container(
      color: _xuanGround,
      child: pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              resolver.sanitizeText('拾光手账 · 卷尾留白'),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: resolver.boldFont,
                fontSize: 12,
                color: _danmo,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              resolver.sanitizeText(collection.title),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: resolver.regularFont,
                fontSize: 9.5,
                color: _qingmo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
