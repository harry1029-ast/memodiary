import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../../templates/widgets/stationery_canvas_framing.dart';
import 'pdf_font_resolver.dart';

/// Procedural vector canvas background renderer for PDF documents.
/// Draws bounded Paper Heart framing, Double Outer Border (文武双栏),
/// Fishtail Mark (版心黑鱼尾), and substrate textures in PDF vector coordinate space.
class PdfTemplateRenderer {
  const PdfTemplateRenderer._();

  /// Builds a full-bleed vector background layer for [pw.MultiPage] or [pw.Page].
  static pw.Widget buildBackground(pw.Context context, TemplateStyle style) {
    final pdfBgColor = PdfColor.fromInt(style.backgroundColor.toARGB32());

    return pw.FullPage(
      ignoreMargins: true,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          canvas
            ..setFillColor(pdfBgColor)
            ..drawRect(0, 0, size.x, size.y)
            ..fillPath();

          if (style.tokens.substrate == PaperSubstrate.coldGold) {
            _paintColdGoldFlecks(canvas, size);
          }

          final metrics = StationeryLayoutCalculator.calculateMetrics(
            canvasWidth: size.x,
            canvasHeight: size.y,
            backgroundType: style.type,
            horizontalMargin: style.resolvedHorizontalMargin,
            lineSpacing: style.lineSpacing,
          );

          _paintFraming(canvas, size, style, metrics);

          switch (style.type) {
            case TemplateBackgroundType.color:
              break;
            case TemplateBackgroundType.lined:
              _paintLinedPaper(canvas, size, style, metrics);
              break;
            case TemplateBackgroundType.grid:
              _paintGridPaper(canvas, size, style, metrics);
              break;
            case TemplateBackgroundType.dotGrid:
              _paintDotGridPaper(canvas, size, style, metrics);
              break;
            case TemplateBackgroundType.paperTexture:
              _paintPaperTexture(canvas, size, style, metrics);
              break;
          }
        },
      ),
    );
  }

  /// Maps [RuleInkTint] to vector PDF stroke colors.
  static PdfColor pdfRuleColor(RuleInkTint tint, {double? alphaMultiplier}) {
    final (red, green, blue, baseAlpha) = switch (tint) {
      RuleInkTint.vermilion => (0.75, 0.22, 0.17, 0.30),
      RuleInkTint.charcoal => (0.18, 0.24, 0.30, 0.22),
      RuleInkTint.jade => (0.18, 0.42, 0.34, 0.25),
      RuleInkTint.slate => (0.29, 0.40, 0.45, 0.18),
    };
    final alpha = alphaMultiplier != null
        ? (baseAlpha * alphaMultiplier / 0.3).clamp(0.1, 0.95)
        : baseAlpha;
    return PdfColor(red, green, blue, alpha);
  }

  /// Procedural Cold Gold flecks scattered across the paper.
  static void _paintColdGoldFlecks(PdfGraphics canvas, PdfPoint size) {
    final random = math.Random(1337);
    final count = (size.x * size.y / 7000.0).clamp(60, 240).toInt();
    canvas.setFillColor(const PdfColor(0.85, 0.70, 0.22, 0.40));

    for (int index = 0; index < count; index++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * size.y;
      final rx = 0.5 + random.nextDouble() * 1.6;
      final ry = 0.5 + random.nextDouble() * 1.6;
      canvas.drawEllipse(x, y, rx, ry);
    }
    canvas.fillPath();
  }

  /// Paints Double Outer Border and conditional Fishtail Mark in PDF vector coordinates.
  static void _paintFraming(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    if (!StationeryCanvasFraming.shouldDrawDoubleBorder(style)) return;

    final frameLeft = metrics.innerFrameRect.left;
    final frameBottom = metrics.earthMarginPx;
    final frameWidth = metrics.innerFrameRect.width;
    final frameHeight = metrics.innerFrameRect.height;
    final frameTop = frameBottom + frameHeight;

    final outerColor = pdfRuleColor(style.tokens.ruleTint, alphaMultiplier: 0.85);
    final innerColor = pdfRuleColor(style.tokens.ruleTint, alphaMultiplier: 0.70);

    // Outer stroke (2.0px inflated by 4.0px) and inner stroke (0.9px)
    canvas
      ..setStrokeColor(outerColor)
      ..setLineWidth(2.0)
      ..drawRect(frameLeft - 4.0, frameBottom - 4.0, frameWidth + 8.0, frameHeight + 8.0)
      ..strokePath()
      ..setStrokeColor(innerColor)
      ..setLineWidth(0.9)
      ..drawRect(frameLeft, frameBottom, frameWidth, frameHeight)
      ..strokePath();

    // Fishtail Mark on manuscript grid with columnCount >= 7
    if (StationeryCanvasFraming.shouldRenderFishtail(style: style, columnCount: metrics.columnCount)) {
      final midCol = metrics.columnCount ~/ 2;
      final colLeft = frameLeft + midCol * metrics.cellAdvancePx;
      final colRight = colLeft + metrics.cellAdvancePx;
      final midX = (colLeft + colRight) / 2.0;

      final tailTopY = frameTop - metrics.lineStridePx * 0.2;
      final tailHeight = metrics.lineStridePx * 0.75;
      final tailBottomY = tailTopY - tailHeight;
      final tailLeft = colLeft + 2.0;
      final tailRight = colRight - 2.0;

      final fishtailColor = style.tokens.ruleTint == RuleInkTint.vermilion
          ? const PdfColor(0.75, 0.22, 0.17, 0.85)
          : const PdfColor(0.25, 0.26, 0.27, 0.85);

      canvas
        ..moveTo(tailLeft, tailTopY)
        ..lineTo(midX, tailTopY - tailHeight * 0.45)
        ..lineTo(tailRight, tailTopY)
        ..lineTo(tailRight, tailBottomY + tailHeight * 0.15)
        ..lineTo(midX, tailBottomY)
        ..lineTo(tailLeft, tailBottomY + tailHeight * 0.15)
        ..closePath()
        ..setFillColor(fishtailColor)
        ..fillPath();
    }
  }

  /// Ruled notebook lines strictly bounded within innerFrameRect
  static void _paintLinedPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    final frameLeft = metrics.innerFrameRect.left;
    final frameRight = metrics.innerFrameRect.right;
    final frameBottom = metrics.earthMarginPx;
    final frameTop = frameBottom + metrics.innerFrameRect.height;

    canvas
      ..setStrokeColor(pdfRuleColor(style.tokens.ruleTint))
      ..setLineWidth(0.6);
    for (int rowIndex = 1; rowIndex < metrics.rowCount; rowIndex++) {
      final y = frameTop - rowIndex * metrics.lineStridePx;
      canvas.drawLine(frameLeft, y, frameRight, y);
    }
    canvas.strokePath();

    final marginX = frameLeft + 12.0;
    canvas
      ..setStrokeColor(style.tokens.ruleTint == RuleInkTint.vermilion
          ? const PdfColor(0.85, 0.30, 0.25, 0.45)
          : const PdfColor(0.90, 0.45, 0.45, 0.25))
      ..setLineWidth(1.0)
      ..drawLine(marginX, frameBottom, marginX, frameTop)
      ..strokePath();
  }

  /// Orthogonal manuscript grid strictly bounded within innerFrameRect
  static void _paintGridPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    final frameLeft = metrics.innerFrameRect.left;
    final frameRight = metrics.innerFrameRect.right;
    final frameBottom = metrics.earthMarginPx;
    final frameTop = frameBottom + metrics.innerFrameRect.height;

    canvas
      ..setStrokeColor(pdfRuleColor(style.tokens.ruleTint))
      ..setLineWidth(0.5);

    for (int colIndex = 1; colIndex < metrics.columnCount; colIndex++) {
      final x = frameLeft + colIndex * metrics.cellAdvancePx;
      canvas.drawLine(x, frameBottom, x, frameTop);
    }

    final isManuscript = StationeryCanvasFraming.shouldRenderFishtail(
      style: style,
      columnCount: metrics.columnCount,
    );
    final midCol = metrics.columnCount ~/ 2;
    final midColLeft = frameLeft + midCol * metrics.cellAdvancePx;
    final midColRight = midColLeft + metrics.cellAdvancePx;

    for (int rowIndex = 1; rowIndex < metrics.rowCount; rowIndex++) {
      final y = frameTop - rowIndex * metrics.lineStridePx;
      if (isManuscript) {
        canvas.drawLine(frameLeft, y, midColLeft, y);
        canvas.drawLine(midColRight, y, frameRight, y);
      } else {
        canvas.drawLine(frameLeft, y, frameRight, y);
      }
    }
    canvas.strokePath();
  }

  /// Minimalist dot grid in PDF vector coordinates strictly bounded within innerFrameRect
  static void _paintDotGridPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    final frameLeft = metrics.innerFrameRect.left;
    final frameBottom = metrics.earthMarginPx;
    final frameTop = frameBottom + metrics.innerFrameRect.height;

    canvas.setFillColor(pdfRuleColor(style.tokens.ruleTint));
    for (int colIndex = 1; colIndex < metrics.columnCount; colIndex++) {
      final x = frameLeft + colIndex * metrics.cellAdvancePx;
      for (int rowIndex = 1; rowIndex < metrics.rowCount; rowIndex++) {
        final y = frameTop - rowIndex * metrics.lineStridePx;
        canvas.drawEllipse(x, y, 0.8, 0.8);
      }
    }
    canvas.fillPath();
  }

  /// Vintage kraft paper with guidelines strictly bounded within innerFrameRect
  static void _paintPaperTexture(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    canvas
      ..setFillColor(const PdfColor(0.31, 0.20, 0.18, 0.08))
      ..drawRect(0, size.y - 8, size.x, 8)
      ..drawRect(0, 0, size.x, 8)
      ..fillPath();

    final frameLeft = metrics.innerFrameRect.left;
    final frameRight = metrics.innerFrameRect.right;
    final frameBottom = metrics.earthMarginPx;
    final frameTop = frameBottom + metrics.innerFrameRect.height;

    canvas
      ..setStrokeColor(pdfRuleColor(style.tokens.ruleTint))
      ..setLineWidth(0.6);
    for (int rowIndex = 1; rowIndex < metrics.rowCount; rowIndex++) {
      final y = frameTop - rowIndex * metrics.lineStridePx;
      canvas.drawLine(frameLeft, y, frameRight, y);
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
        border: pw.Border.all(color: cinnabar, width: size * 0.05),
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
    if (chars.length == 2) return ([chars[0]], [chars[1]]);
    if (chars.length == 3) return ([chars[0], chars[1]], [chars[2], '印']);
    if (chars.length >= 4) return ([chars[0], chars[1]], [chars[2], chars[3]]);
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
            (char) => pw.Text(
              resolver.sanitizeText(char),
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
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
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
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
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
