import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../import_export/services/pdf_font_resolver.dart';
import '../models/album_studio_models.dart';
import 'album_theme_catalog.dart';

/// Vector PDF painter for `PageBackgroundConfig` procedural motifs and
/// `PageOverlayElement` stickers, date pills, text notes, and Cinnabar seals.
class PdfVectorGraphicsPainter {
  const PdfVectorGraphicsPainter._();

  static PdfColor _colorWithAlpha(int argb, double opacityMultiplier) {
    final baseAlpha = ((argb >> 24) & 0xFF) / 255.0;
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    final a = (baseAlpha * opacityMultiplier).clamp(0.0, 1.0);
    return PdfColor(r, g, b, a);
  }

  /// Builds a full-bleed vector background widget for [config].
  static pw.Widget buildPageBackground(PageBackgroundConfig config) {
    final bgColor = PdfColor.fromInt(config.backgroundColorArgb);
    final patternId = config.graphicPatternId;

    return pw.Container(
      decoration: pw.BoxDecoration(color: bgColor),
      child: (patternId == null || patternId == 'none' || patternId.isEmpty)
          ? pw.SizedBox.expand()
          : pw.CustomPaint(
              painter: (canvas, size) {
                _paintGraphicPattern(
                  canvas: canvas,
                  size: size,
                  patternId: patternId,
                  accentArgb: config.textColorArgb,
                );
              },
            ),
    );
  }

  static void _paintGraphicPattern({
    required PdfGraphics canvas,
    required PdfPoint size,
    required String patternId,
    required int accentArgb,
  }) {
    final canvasWidth = size.x;
    final canvasHeight = size.y;
    if (canvasWidth <= 0 || canvasHeight <= 0) return;

    final strokeSoft = _colorWithAlpha(accentArgb, 0.26);
    final fillSoft = _colorWithAlpha(accentArgb, 0.14);

    canvas.saveContext();
    switch (patternId) {
      case 'ink_bamboo_mountains':
        // Distant mist mountains along bottom (Note: PDF y=0 is bottom)
        canvas
          ..setFillColor(fillSoft)
          ..moveTo(0, 0)
          ..lineTo(0, canvasHeight * 0.18)
          ..curveTo(
            canvasWidth * 0.25,
            canvasHeight * 0.28,
            canvasWidth * 0.45,
            canvasHeight * 0.12,
            canvasWidth * 0.7,
            canvasHeight * 0.22,
          )
          ..curveTo(
            canvasWidth * 0.85,
            canvasHeight * 0.27,
            canvasWidth * 0.95,
            canvasHeight * 0.16,
            canvasWidth,
            canvasHeight * 0.20,
          )
          ..lineTo(canvasWidth, 0)
          ..closePath()
          ..fillPath();
        // Bamboo stalks at top-right (high y in PDF coords)
        canvas
          ..setStrokeColor(strokeSoft)
          ..setLineWidth(1.2)
          ..moveTo(canvasWidth * 0.88, canvasHeight * 0.62)
          ..lineTo(canvasWidth * 0.88, canvasHeight * 0.96)
          ..moveTo(canvasWidth * 0.93, canvasHeight * 0.70)
          ..lineTo(canvasWidth * 0.93, canvasHeight * 0.96)
          ..strokePath();
      case 'floral_allover':
        canvas
          ..setStrokeColor(strokeSoft)
          ..setLineWidth(0.8);
        const cols = 4;
        const rows = 4;
        for (var row = 0; row < rows; row++) {
          for (var col = 0; col < cols; col++) {
            final centerX = canvasWidth * ((col + 0.5) / cols);
            final centerY = canvasHeight * ((row + 0.5) / rows);
            final radius = math.min(canvasWidth, canvasHeight) * 0.032;
            canvas
              ..drawEllipse(centerX, centerY, radius, radius * 0.55)
              ..drawEllipse(centerX, centerY, radius * 0.55, radius)
              ..strokePath();
          }
        }
      case 'corner_vines':
        canvas
          ..setStrokeColor(strokeSoft)
          ..setLineWidth(1.2)
          // Top-left vine (y near canvasHeight)
          ..moveTo(0, canvasHeight * 0.78)
          ..curveTo(
            canvasWidth * 0.08,
            canvasHeight * 0.84,
            canvasWidth * 0.14,
            canvasHeight * 0.92,
            canvasWidth * 0.24,
            canvasHeight,
          )
          // Bottom-right vine (y near 0)
          ..moveTo(canvasWidth * 0.76, 0)
          ..curveTo(
            canvasWidth * 0.86,
            canvasHeight * 0.08,
            canvasWidth * 0.92,
            canvasHeight * 0.16,
            canvasWidth,
            canvasHeight * 0.22,
          )
          ..strokePath();
        canvas
          ..setFillColor(fillSoft)
          ..drawEllipse(canvasWidth * 0.10, canvasHeight * 0.88, 6, 3)
          ..drawEllipse(canvasWidth * 0.88, canvasHeight * 0.12, 6, 3)
          ..fillPath();
      case 'bottom_left_sprig':
        canvas
          ..setStrokeColor(strokeSoft)
          ..setLineWidth(1.3)
          ..moveTo(canvasWidth * 0.03, canvasHeight * 0.03)
          ..curveTo(
            canvasWidth * 0.10,
            canvasHeight * 0.12,
            canvasWidth * 0.18,
            canvasHeight * 0.18,
            canvasWidth * 0.26,
            canvasHeight * 0.24,
          )
          ..strokePath();
        canvas
          ..setFillColor(fillSoft)
          ..drawEllipse(canvasWidth * 0.12, canvasHeight * 0.14, 7, 3.5)
          ..drawEllipse(canvasWidth * 0.20, canvasHeight * 0.20, 6, 3)
          ..fillPath();
      case 'bottom_right_bloom':
        canvas
          ..setFillColor(fillSoft)
          ..drawEllipse(canvasWidth * 0.86, canvasHeight * 0.14, 14, 7)
          ..drawEllipse(canvasWidth * 0.86, canvasHeight * 0.14, 7, 14)
          ..fillPath();
      case 'abstract_fluid':
        canvas
          ..setFillColor(fillSoft)
          ..moveTo(0, canvasHeight)
          ..lineTo(canvasWidth * 0.34, canvasHeight)
          ..curveTo(
            canvasWidth * 0.28,
            canvasHeight * 0.82,
            canvasWidth * 0.14,
            canvasHeight * 0.76,
            0,
            canvasHeight * 0.70,
          )
          ..closePath()
          ..fillPath()
          ..moveTo(canvasWidth, 0)
          ..lineTo(canvasWidth * 0.66, 0)
          ..curveTo(
            canvasWidth * 0.72,
            canvasHeight * 0.18,
            canvasWidth * 0.86,
            canvasHeight * 0.24,
            canvasWidth,
            canvasHeight * 0.30,
          )
          ..closePath()
          ..fillPath();
      case 'beach_lemon_palm':
        canvas
          ..setStrokeColor(strokeSoft)
          ..setLineWidth(1.2)
          ..drawEllipse(canvasWidth * 0.12, canvasHeight * 0.88, 14, 14)
          ..drawEllipse(canvasWidth * 0.88, canvasHeight * 0.12, 16, 16)
          ..strokePath();
      case 'rainbow_paper_plane':
        for (var arcIndex = 0; arcIndex < 3; arcIndex++) {
          final ringRadius = math.min(canvasWidth, canvasHeight) *
              (0.14 + arcIndex * 0.03);
          canvas
            ..setStrokeColor(strokeSoft)
            ..setLineWidth(1.5)
            ..drawEllipse(
              canvasWidth * 0.86,
              canvasHeight * 0.12,
              ringRadius,
              ringRadius * 0.65,
            )
            ..strokePath();
        }
    }
    canvas.restoreContext();
  }

  /// Builds a vector PDF widget for an individual [PageOverlayElement].
  ///
  /// Enforces Technical Watchpoint 4 (single-page overflow protection) by
  /// clamping text lines and wrapping inside fixed-size bounds.
  static pw.Widget buildOverlayWidget({
    required PageOverlayElement overlay,
    required int defaultTextColorArgb,
    required double baseUnit,
    required PdfFontResolver resolver,
  }) {
    final effectiveArgb = overlay.colorArgb ?? defaultTextColorArgb;
    final effectiveColor = PdfColor.fromInt(effectiveArgb);

    switch (overlay.type) {
      case OverlayElementType.sticker:
        final stickerPreset = StickerCatalog.getById(overlay.content);
        final stickerColor = PdfColor.fromInt(
          overlay.colorArgb ?? stickerPreset.defaultColorArgb,
        );
        final dim = math.max(18.0, baseUnit * 0.13);
        return pw.SizedBox(
          width: dim,
          height: dim,
          child: pw.CustomPaint(
            painter: (canvas, size) {
              _paintVectorSticker(
                canvas: canvas,
                size: size,
                stickerId: overlay.content,
                color: stickerColor,
              );
            },
          ),
        );

      case OverlayElementType.datePill:
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.99, 0.98, 0.95),
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: effectiveColor, width: 0.9),
          ),
          child: pw.Text(
            resolver.sanitizeText(overlay.content),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              font: resolver.boldFont,
              fontSize: math.max(7.5, baseUnit * 0.032),
              color: effectiveColor,
              letterSpacing: 0.6,
            ),
          ),
        );

      case OverlayElementType.text:
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: pw.Text(
            resolver.sanitizeText(overlay.content),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: resolver.regularFont,
              fontSize: math.max(8.0, baseUnit * 0.038),
              color: effectiveColor,
              lineSpacing: 1.5,
            ),
          ),
        );

      case OverlayElementType.sealStamp:
        final rawText = overlay.content.trim().isEmpty
            ? '拾光'
            : overlay.content.trim();
        final sealChars =
            rawText.length > 4 ? rawText.substring(0, 4) : rawText;
        final sealColor = PdfColor.fromInt(0xFFB83B2E);
        final sealSize = math.max(22.0, baseUnit * 0.11);

        return pw.Container(
          width: sealSize,
          height: sealSize,
          padding: const pw.EdgeInsets.all(2),
          decoration: pw.BoxDecoration(
            color: sealColor,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Container(
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.white, width: 0.7),
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
            child: pw.Text(
              resolver.sanitizeText(sealChars),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: resolver.boldFont,
                fontSize: sealSize * 0.34,
                color: PdfColors.white,
              ),
            ),
          ),
        );
    }
  }

  static void _paintVectorSticker({
    required PdfGraphics canvas,
    required PdfPoint size,
    required String stickerId,
    required PdfColor color,
  }) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;
    final r = math.min(w, h) * 0.42;

    canvas.saveContext();
    canvas
      ..setStrokeColor(color)
      ..setFillColor(color)
      ..setLineWidth(1.3);

    if (stickerId.contains('washi')) {
      canvas
        ..drawRect(w * 0.08, h * 0.32, w * 0.84, h * 0.36)
        ..fillPath();
    } else if (stickerId.contains('seal') || stickerId.contains('postmark')) {
      canvas
        ..drawEllipse(cx, cy, r, r)
        ..drawEllipse(cx, cy, r * 0.74, r * 0.74)
        ..strokePath();
    } else if (stickerId.contains('date_pill')) {
      canvas
        ..drawRRect(w * 0.06, h * 0.25, w * 0.88, h * 0.50, 6, 6)
        ..strokePath();
    } else {
      // Ornamental medallion + diamond star for travel/flora/weather stickers
      canvas
        ..drawEllipse(cx, cy, r, r)
        ..moveTo(cx, cy + r * 0.65)
        ..lineTo(cx + r * 0.65, cy)
        ..lineTo(cx, cy - r * 0.65)
        ..lineTo(cx - r * 0.65, cy)
        ..closePath()
        ..strokePath();
    }
    canvas.restoreContext();
  }
}
