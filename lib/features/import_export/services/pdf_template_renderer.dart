import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import '../../templates/services/stationery_geometry.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import 'pdf_font_resolver.dart';

/// Procedural vector canvas background renderer for PDF documents.
/// Draws bounded Paper Heart framing, Double Outer Border (文武双栏),
/// Fishtail Mark (版心黑鱼尾), and substrate textures in PDF vector coordinate space.
class PdfTemplateRenderer {
  const PdfTemplateRenderer._();

  /// Uniform column pitch for vertical keepsake PDF stationery panes (28pt).
  static const double kVerticalColumnStride = 28.0;

  /// Builds a full-bleed vector background layer for [pw.MultiPage] or [pw.Page].
  static pw.Widget buildBackground(
    pw.Context context,
    TemplateStyle style, {
    bool isVertical = false,
    StationeryLayoutMetrics? metrics,
  }) {
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

          final resolvedMetrics = metrics ??
              StationeryLayoutCalculator.calculateMetrics(
                canvasWidth: size.x,
                canvasHeight: size.y,
                backgroundType: style.type,
                horizontalMargin: style.resolvedHorizontalMargin,
                lineSpacing: style.lineSpacing,
              );

          _paintFraming(canvas, size, style, resolvedMetrics);

          if (isVertical &&
              (style.type == TemplateBackgroundType.lined ||
                  style.type == TemplateBackgroundType.paperTexture)) {
            if (style.type == TemplateBackgroundType.paperTexture) {
              _paintKraftBands(canvas, size);
            }
            _paintVerticalColumnPaper(canvas, size, style, resolvedMetrics);
            return;
          }

          switch (style.type) {
            case TemplateBackgroundType.color:
              break;
            case TemplateBackgroundType.lined:
              _paintLinedPaper(canvas, size, style, resolvedMetrics);
              break;
            case TemplateBackgroundType.grid:
              _paintGridPaper(canvas, size, style, resolvedMetrics);
              break;
            case TemplateBackgroundType.dotGrid:
              _paintDotGridPaper(canvas, size, style, resolvedMetrics);
              break;
            case TemplateBackgroundType.paperTexture:
              _paintPaperTexture(canvas, size, style, resolvedMetrics);
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
    final frame = StationeryGeometry.buildFrame(metrics: metrics, style: style);
    if (!frame.drawDoubleBorder) return;

    final outerColor = pdfRuleColor(style.tokens.ruleTint, alphaMultiplier: 0.85);
    final innerColor = pdfRuleColor(style.tokens.ruleTint, alphaMultiplier: 0.70);

    // Outer stroke (2.0px inflated by 4.0px) and inner stroke (0.9px)
    canvas
      ..setStrokeColor(outerColor)
      ..setLineWidth(frame.outerStrokeWidth)
      ..drawRect(
        frame.outerRect.left,
        size.y - frame.outerRect.bottom,
        frame.outerRect.width,
        frame.outerRect.height,
      )
      ..strokePath()
      ..setStrokeColor(innerColor)
      ..setLineWidth(frame.innerStrokeWidth)
      ..drawRect(
        frame.innerRect.left,
        size.y - frame.innerRect.bottom,
        frame.innerRect.width,
        frame.innerRect.height,
      )
      ..strokePath();

    // Fishtail Mark on manuscript grid with columnCount >= 7
    final fishtail = frame.fishtailPolygon;
    if (fishtail != null && fishtail.isNotEmpty) {
      final fishtailColor = style.tokens.ruleTint == RuleInkTint.vermilion
          ? const PdfColor(0.75, 0.22, 0.17, 0.85)
          : const PdfColor(0.25, 0.26, 0.27, 0.85);

      canvas.moveTo(fishtail.first.dx, size.y - fishtail.first.dy);
      for (int index = 1; index < fishtail.length; index++) {
        canvas.lineTo(fishtail[index].dx, size.y - fishtail[index].dy);
      }
      canvas
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
    final rulings = StationeryGeometry.buildRulings(
      metrics: metrics,
      style: style,
      leftMarginInset: 12.0,
    );
    _drawPdfLines(
      canvas,
      size,
      rulings.primaryLines,
      color: pdfRuleColor(style.tokens.ruleTint),
      lineWidth: 0.6,
    );

    if (rulings.leftMarginRule case final marginRule?) {
      canvas
        ..setStrokeColor(style.tokens.ruleTint == RuleInkTint.vermilion
            ? const PdfColor(0.85, 0.30, 0.25, 0.45)
            : const PdfColor(0.90, 0.45, 0.45, 0.25))
        ..setLineWidth(1.0)
        ..drawLine(
          marginRule.start.dx,
          size.y - marginRule.start.dy,
          marginRule.end.dx,
          size.y - marginRule.end.dy,
        )
        ..strokePath();
    }
  }

  /// Orthogonal manuscript grid strictly bounded within innerFrameRect
  static void _paintGridPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    final rulings = StationeryGeometry.buildRulings(
      metrics: metrics,
      style: style,
    );
    final ruleColor = pdfRuleColor(style.tokens.ruleTint);
    _drawPdfLines(
      canvas,
      size,
      [...rulings.secondaryLines, ...rulings.primaryLines],
      color: ruleColor,
      lineWidth: 0.5,
    );
  }

  /// Minimalist dot grid in PDF vector coordinates strictly bounded within innerFrameRect
  static void _paintDotGridPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    final rulings = StationeryGeometry.buildRulings(
      metrics: metrics,
      style: style,
    );
    canvas.setFillColor(pdfRuleColor(style.tokens.ruleTint));
    for (final dot in rulings.dots) {
      canvas.drawEllipse(dot.dx, size.y - dot.dy, 0.8, 0.8);
    }
    canvas.fillPath();
  }

  static void _paintKraftBands(PdfGraphics canvas, PdfPoint size) {
    canvas
      ..setFillColor(const PdfColor(0.31, 0.20, 0.18, 0.08))
      ..drawRect(0, size.y - 8, size.x, 8)
      ..drawRect(0, 0, size.x, 8)
      ..fillPath();
  }

  /// Vertical column silk rulings (朱丝栏/乌丝栏) bounded within innerFrameRect.
  static void _paintVerticalColumnPaper(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    final rulings = StationeryGeometry.buildRulings(
      metrics: metrics,
      style: style,
      isVertical: true,
      verticalColumnStride: kVerticalColumnStride,
    );
    _drawPdfLines(
      canvas,
      size,
      rulings.primaryLines,
      color: pdfRuleColor(style.tokens.ruleTint),
      lineWidth: 0.5,
    );
  }

  /// Vintage kraft paper with guidelines strictly bounded within innerFrameRect
  static void _paintPaperTexture(
    PdfGraphics canvas,
    PdfPoint size,
    TemplateStyle style,
    StationeryLayoutMetrics metrics,
  ) {
    _paintKraftBands(canvas, size);

    final rulings = StationeryGeometry.buildRulings(
      metrics: metrics,
      style: style,
    );
    _drawPdfLines(
      canvas,
      size,
      rulings.primaryLines,
      color: pdfRuleColor(style.tokens.ruleTint),
      lineWidth: 0.6,
    );
  }

  static void _drawPdfLines(
    PdfGraphics canvas,
    PdfPoint size,
    List<StationeryLineSegment> lines, {
    required PdfColor color,
    required double lineWidth,
  }) {
    if (lines.isEmpty) return;
    canvas
      ..setStrokeColor(color)
      ..setLineWidth(lineWidth);
    for (final line in lines) {
      canvas.drawLine(
        line.start.dx,
        size.y - line.start.dy,
        line.end.dx,
        size.y - line.end.dy,
      );
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
    final layout = StationeryGeometry.buildSealLayout(
      text: sealText,
      sealStyle: style.tokens.sealStyle,
    );
    if (!layout.isVisible) {
      return pw.SizedBox.shrink();
    }

    const cinnabar = PdfColor(0.73, 0.15, 0.10);

    return pw.Container(
      width: size,
      height: size,
      padding: pw.EdgeInsets.all(size * 0.06),
      decoration: pw.BoxDecoration(
        color: layout.isBaiwen ? cinnabar : null,
        border: pw.Border.all(color: cinnabar, width: size * 0.05),
        borderRadius: pw.BorderRadius.circular(size * 0.08),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildSealCol(layout.colLeft, layout.isBaiwen, fontResolver, size),
          _buildSealCol(layout.colRight, layout.isBaiwen, fontResolver, size),
        ],
      ),
    );
  }

  static pw.Widget _buildSealCol(
    List<String> chars,
    bool isBaiwen,
    PdfFontResolver resolver,
    double size,
  ) {
    final textColor = isBaiwen ? PdfColors.white : const PdfColor(0.73, 0.15, 0.10);
    final fontSize = size * 0.23;

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: chars
          .map(
            (char) => pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  resolver.sanitizeText(char),
                  style: pw.TextStyle(
                    font: resolver.boldFont,
                    fontSize: fontSize,
                    color: textColor,
                  ),
                ),
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
    PdfFontResolver fontResolver, {
    StationeryLayoutMetrics? metrics,
  }) {
    final dateStr = DateFormat('yyyy-MM-dd').format(entry.entryDate);
    final rawTitle = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : '云皓日记';
    final title = fontResolver.sanitizeText(rawTitle);

    final resolvedMetrics = metrics ??
        StationeryLayoutCalculator.calculateMetrics(
          canvasWidth: context.page.pageFormat.width,
          canvasHeight: context.page.pageFormat.height,
          backgroundType: style.type,
          horizontalMargin: style.resolvedHorizontalMargin,
          lineSpacing: style.lineSpacing,
        );
    final bottomGap = math.max(12.0, resolvedMetrics.heavenMarginPx - 34.0);

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: bottomGap),
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
    PdfFontResolver fontResolver, {
    StationeryLayoutMetrics? metrics,
  }) {
    final resolvedMetrics = metrics ??
        StationeryLayoutCalculator.calculateMetrics(
          canvasWidth: context.page.pageFormat.width,
          canvasHeight: context.page.pageFormat.height,
          backgroundType: style.type,
          horizontalMargin: style.resolvedHorizontalMargin,
          lineSpacing: style.lineSpacing,
        );
    final topGap = math.max(12.0, resolvedMetrics.earthMarginPx - 28.0);

    return pw.Container(
      margin: pw.EdgeInsets.only(top: topGap),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            fontResolver.sanitizeText('云皓日记 · 本地离线私密存储'),
            style: pw.TextStyle(
              font: fontResolver.regularFont,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            fontResolver.sanitizeText('第 ${context.pageNumber} / ${context.pagesCount} 页'),
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
