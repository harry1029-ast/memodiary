import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import 'pdf_font_resolver.dart';

/// Procedural vector canvas background renderer for PDF documents.
/// Draws full-bleed ruled notebook lines, graph paper grids, kraft textures,
/// and custom template styling in PDF vector coordinate space at zero asset cost.
class PdfTemplateRenderer {
  const PdfTemplateRenderer._();

  /// Builds a full-bleed vector background layer for [pw.MultiPage].
  static pw.Widget buildBackground(pw.Context context, TemplateStyle style) {
    final pdfBgColor = PdfColor.fromInt(style.backgroundColor.toARGB32());

    return pw.FullPage(
      ignoreMargins: true,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          // 1. Draw base page rectangle
          canvas.setFillColor(pdfBgColor);
          canvas.drawRect(0, 0, size.x, size.y);
          canvas.fillPath();

          // 2. Draw vector pattern matching TemplateBackgroundType
          switch (style.type) {
            case TemplateBackgroundType.color:
              // Clean solid background fill
              break;

            case TemplateBackgroundType.lined:
              _paintLinedPaper(canvas, size, style);
              break;

            case TemplateBackgroundType.grid:
              _paintGridPaper(canvas, size, style);
              break;

            case TemplateBackgroundType.dotGrid:
              _paintDotGridPaper(canvas, size, style);
              break;

            case TemplateBackgroundType.paperTexture:
              _paintPaperTexture(canvas, size, style);
              break;
          }
        },
      ),
    );
  }

  /// Ruled notebook lines with left red margin rule
  static void _paintLinedPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
  ) {
    final rowHeight = 24.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);

    // Horizontal notebook rules
    canvas.setStrokeColor(const PdfColor(0.29, 0.40, 0.45, 0.15));
    canvas.setLineWidth(0.6);
    for (double y = 40.0; y < size.y - 40.0; y += rowHeight) {
      canvas.drawLine(0, y, size.x, y);
    }
    canvas.strokePath();

    // Classic notebook vertical margin line
    final marginX = style.marginHorizontal.clamp(20.0, 60.0);
    canvas.setStrokeColor(const PdfColor(0.90, 0.45, 0.45, 0.25));
    canvas.setLineWidth(1.0);
    canvas.drawLine(marginX, 0, marginX, size.y);
    canvas.strokePath();
  }

  static List<double> _computeMarginAnchoredX(double width, double marginX, double step) {
    final xCoords = <double>[];
    for (double x = marginX - step; x >= 0; x -= step) {
      xCoords.add(x);
    }
    for (double x = marginX; x <= width; x += step) {
      xCoords.add(x);
    }
    xCoords.sort();
    return xCoords;
  }

  /// Orthogonal millimeter vector grid anchored to marginX
  static void _paintGridPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
  ) {
    final gridSize = 20.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.0);
    final marginX = style.resolvedHorizontalMargin;

    canvas.setStrokeColor(const PdfColor(0.47, 0.56, 0.61, 0.15));
    canvas.setLineWidth(0.5);

    final xCoords = _computeMarginAnchoredX(size.x, marginX, gridSize);
    for (final x in xCoords) {
      canvas.drawLine(x, 0, x, size.y);
    }

    // Horizontal grid lines
    for (double y = 0; y < size.y; y += gridSize) {
      canvas.drawLine(0, y, size.x, y);
    }
    canvas.strokePath();
  }

  /// Minimalist dot grid in PDF vector coordinates anchored to marginX
  static void _paintDotGridPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
  ) {
    final dotSize = 20.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.0);
    final marginX = style.resolvedHorizontalMargin;
    final xCoords = _computeMarginAnchoredX(size.x, marginX, dotSize);

    canvas.setFillColor(const PdfColor(0.47, 0.56, 0.61, 0.25));

    for (final x in xCoords) {
      for (double y = 0; y < size.y; y += dotSize) {
        canvas.drawEllipse(x, y, 0.8, 0.8);
      }
    }
    canvas.fillPath();
  }

  /// Vintage kraft paper with top and bottom decorative accent bars
  static void _paintPaperTexture(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
  ) {
    // 1. Top and bottom warm kraft accent bars
    canvas.setFillColor(const PdfColor(0.31, 0.20, 0.18, 0.08));
    canvas.drawRect(0, size.y - 8, size.x, 8);
    canvas.drawRect(0, 0, size.x, 8);
    canvas.fillPath();

    // 2. Faint kraft horizontal guidelines
    final rowHeight = 28.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);
    final marginX = style.marginHorizontal.clamp(16.0, 48.0);
    canvas.setStrokeColor(const PdfColor(0.55, 0.43, 0.39, 0.12));
    canvas.setLineWidth(0.6);

    for (double y = 40.0; y < size.y - 40.0; y += rowHeight) {
      canvas.drawLine(marginX, y, size.x - marginX, y);
    }
    canvas.strokePath();
  }

  /// Running page header
  static pw.Widget buildHeader(
    pw.Context context,
    Entry entry,
    TemplateStyle style,
    PdfFontResolver fontResolver,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(entry.entryDate);
    final rawTitle = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : 'MemoDiary Entry';
    final title = fontResolver.sanitizeText(rawTitle);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontResolver.regularFont,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            dateStr,
            style: pw.TextStyle(
              font: fontResolver.regularFont,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Running page footer
  static pw.Widget buildFooter(
    pw.Context context,
    Entry entry,
    TemplateStyle style,
    PdfFontResolver fontResolver,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MemoDiary · 100% Private & Sandboxed',
            style: pw.TextStyle(
              font: fontResolver.regularFont,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: fontResolver.regularFont,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

