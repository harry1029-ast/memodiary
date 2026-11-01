import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import 'pdf_font_resolver.dart';

/// Procedural vector canvas background renderer for PDF documents.
/// Draws full-bleed ruled notebook lines, graph paper grids, kraft textures,
/// substrate textures (cold gold flecks), and custom template styling
/// in PDF vector coordinate space at zero asset cost.
class PdfTemplateRenderer {
  const PdfTemplateRenderer._();

  /// Builds a full-bleed vector background layer for [pw.MultiPage] or [pw.Page].
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

          // 2. Procedural substrate texture (Cold Gold Flecks)
          if (style.tokens.substrate == PaperSubstrate.coldGold) {
            _paintColdGoldFlecks(canvas, size);
          }

          // 3. Draw vector pattern matching TemplateBackgroundType
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

  /// Maps [RuleInkTint] to vector PDF stroke colors.
  static PdfColor pdfRuleColor(RuleInkTint tint) {
    switch (tint) {
      case RuleInkTint.vermilion:
        return const PdfColor(0.75, 0.22, 0.17, 0.30);
      case RuleInkTint.charcoal:
        return const PdfColor(0.18, 0.24, 0.30, 0.22);
      case RuleInkTint.jade:
        return const PdfColor(0.18, 0.42, 0.34, 0.25);
      case RuleInkTint.slate:
        return const PdfColor(0.29, 0.40, 0.45, 0.18);
    }
  }

  /// Procedural Cold Gold flecks scattered across the paper.
  static void _paintColdGoldFlecks(PdfGraphics canvas, PdfPoint size) {
    final random = math.Random(1337);
    final count = (size.x * size.y / 7000.0).clamp(60, 240).toInt();
    final goldColor = const PdfColor(0.85, 0.70, 0.22, 0.40);
    canvas.setFillColor(goldColor);

    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * size.y;
      final rx = 0.5 + random.nextDouble() * 1.6;
      final ry = 0.5 + random.nextDouble() * 1.6;
      canvas.drawEllipse(x, y, rx, ry);
    }
    canvas.fillPath();
  }

  /// Ruled notebook lines with left red margin rule
  static void _paintLinedPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
  ) {
    final rowHeight = 24.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);
    final ruleColor = pdfRuleColor(style.tokens.ruleTint);

    // Horizontal notebook rules
    canvas.setStrokeColor(ruleColor);
    canvas.setLineWidth(0.6);
    for (double y = 40.0; y < size.y - 40.0; y += rowHeight) {
      canvas.drawLine(0, y, size.x, y);
    }
    canvas.strokePath();

    // Classic notebook vertical margin line
    final marginX = style.marginHorizontal.clamp(20.0, 60.0);
    canvas.setStrokeColor(
      style.tokens.ruleTint == RuleInkTint.vermilion
          ? const PdfColor(0.85, 0.30, 0.25, 0.45)
          : const PdfColor(0.90, 0.45, 0.45, 0.25),
    );
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
    final ruleColor = pdfRuleColor(style.tokens.ruleTint);

    canvas.setStrokeColor(ruleColor);
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
    final dotColor = pdfRuleColor(style.tokens.ruleTint);

    canvas.setFillColor(dotColor);

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
    final ruleColor = pdfRuleColor(style.tokens.ruleTint);
    canvas.setStrokeColor(ruleColor);
    canvas.setLineWidth(0.6);

    for (double y = 40.0; y < size.y - 40.0; y += rowHeight) {
      canvas.drawLine(marginX, y, size.x - marginX, y);
    }
    canvas.strokePath();
  }

  /// Builds a high-fidelity vector Cinnabar Signature Seal for PDF colophons.
  static pw.Widget buildSignatureSeal({
    required TemplateStyle style,
    required PdfFontResolver fontResolver,
    String sealText = '心迹安放',
    double size = 42.0,
  }) {
    if (style.tokens.sealStyle == SealCarvingStyle.hidden) {
      return pw.SizedBox.shrink();
    }

    final isBaiwen = style.tokens.sealStyle == SealCarvingStyle.baiwen;
    final cinnabar = const PdfColor(0.73, 0.15, 0.10);
    final text = sealText.trim().isEmpty ? '心迹安放' : sealText.trim();

    final (colRight, colLeft) = _partitionSealText(text);

    return pw.Container(
      width: size,
      height: size,
      padding: pw.EdgeInsets.all(size * 0.08),
      decoration: pw.BoxDecoration(
        color: isBaiwen ? cinnabar : null,
        border: pw.Border.all(
          color: cinnabar,
          width: size * 0.05,
        ),
        borderRadius: pw.BorderRadius.circular(size * 0.08),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildSealCol(colLeft, isBaiwen, fontResolver, size),
          _buildSealCol(colRight, isBaiwen, fontResolver, size),
        ],
      ),
    );
  }

  static (List<String>, List<String>) _partitionSealText(String text) {
    final chars = text.runes.map((rune) => String.fromCharCode(rune)).toList();
    if (chars.length == 2) {
      return ([chars[0]], [chars[1]]);
    }
    if (chars.length == 3) {
      return ([chars[0], chars[1]], [chars[2], '印']);
    }
    if (chars.length >= 4) {
      return ([chars[0], chars[1]], [chars[2], chars[3]]);
    }
    return ([chars.first], ['印']);
  }

  static pw.Widget _buildSealCol(
    List<String> chars,
    bool isBaiwen,
    PdfFontResolver resolver,
    double size,
  ) {
    final textColor = isBaiwen ? PdfColors.white : const PdfColor(0.73, 0.15, 0.10);
    final fontSize = size * 0.32;

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: chars
          .map(
            (ch) => pw.Text(
              resolver.sanitizeText(ch),
              style: pw.TextStyle(
                font: resolver.boldFont,
                fontSize: fontSize,
                color: textColor,
              ),
            ),
          )
          .toList(),
    );
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
