import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import 'image_format_transcoder.dart';
import 'pdf_font_resolver.dart';

/// Helper for rendering tactile Polaroid Mini-Card overlays in vector PDF export
/// positioned at the diarist's custom saved coordinates with 100% parity.
class PdfPolaroidOverlayBuilder {
  const PdfPolaroidOverlayBuilder._();

  static const double cardWidth = 72.0;
  static const double cardHeight = 94.0;

  /// Resolves the top-left offset (dx, dy) within [availableWidth] and [availableHeight]
  /// for a card given its normalized coordinates [xRatio] and [yRatio].
  static (double dx, double dy) resolvePlacement({
    required double? xRatio,
    required double? yRatio,
    required double availableWidth,
    required double availableHeight,
    required bool isVertical,
  }) {
    final maxDx = (availableWidth - cardWidth).clamp(0.0, availableWidth);
    final maxDy = (availableHeight - cardHeight).clamp(0.0, availableHeight);

    if (xRatio != null && yRatio != null) {
      final dx = (xRatio * maxDx).clamp(0.0, maxDx);
      final dy = (yRatio * maxDy).clamp(0.0, maxDy);
      return (dx, dy);
    }

    // Smart default corner: Top-Left for vertical script; Bottom-Left for horizontal script
    if (isVertical) {
      return (8.0, 8.0);
    } else {
      return (8.0, (maxDy - 10.0).clamp(0.0, maxDy));
    }
  }

  /// Builds a background card shell for fanned stacks.
  static pw.Widget _buildBackgroundCardShell() {
    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      decoration: pw.BoxDecoration(
        color: const PdfColor(0.97, 0.96, 0.94),
        borderRadius: pw.BorderRadius.circular(3.0),
        border: pw.Border.all(
          color: const PdfColor(0.55, 0.45, 0.33, 0.6),
          width: 0.8,
        ),
      ),
    );
  }

  /// Builds a standalone vector [pw.Widget] representing the Polaroid mini-card.
  static pw.Widget buildPolaroidMiniCard({
    required MediaAttachment attachment,
    required pw.MemoryImage? image,
    required PdfFontResolver resolver,
    int? stackIndex,
    int? totalStackCount,
  }) {
    final title = attachment.ocrText?.trim().isNotEmpty == true
        ? attachment.ocrText!.trim().split('\n').first
        : '随文影札';

    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      child: pw.Stack(
        children: [
          // Polaroid aged paper shell
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(4, 5, 4, 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.99, 0.98, 0.97),
              borderRadius: pw.BorderRadius.circular(3.0),
              border: pw.Border.all(
                color: const PdfColor(0.55, 0.45, 0.33),
                width: 0.8,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  child: pw.ClipRRect(
                    horizontalRadius: 2.0,
                    verticalRadius: 2.0,
                    child: image != null
                        ? pw.Image(image, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: pw.Text(
                              attachment.mediaType == 'video' ? '[动态影札]' : '[随文拓影]',
                              style: pw.TextStyle(font: resolver.italicFont, fontSize: 8.0),
                            ),
                          ),
                  ),
                ),
                pw.SizedBox(height: 3.0),
                pw.Text(
                  resolver.sanitizeText(title),
                  maxLines: 1,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: resolver.regularFont,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor(0.17, 0.14, 0.11),
                  ),
                ),
                pw.Text(
                  '随文影札 · 拾光留影',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: resolver.italicFont,
                    fontSize: 5.5,
                    color: const PdfColor(0.55, 0.48, 0.42),
                  ),
                ),
              ],
            ),
          ),
          // Gold washi tape corner accent
          pw.Positioned(
            top: -4.0,
            left: 18.0,
            child: pw.Container(
              width: 32.0,
              height: 7.0,
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.83, 0.69, 0.22, 0.85),
                borderRadius: pw.BorderRadius.circular(1.0),
                border: pw.Border.all(
                  color: const PdfColor(0.95, 0.85, 0.45),
                  width: 0.5,
                ),
              ),
            ),
          ),
          // Antique brass paperclip at top edge
          pw.Positioned(
            top: -7.0,
            left: 10.0,
            child: pw.Container(
              width: 8.0,
              height: 18.0,
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.70, 0.55, 0.20),
                borderRadius: pw.BorderRadius.circular(4.0),
                border: pw.Border.all(
                  color: const PdfColor(0.45, 0.32, 0.10),
                  width: 1.0,
                ),
              ),
            ),
          ),
          // Counter pill for multi-photo stack (e.g. 1/3)
          if (totalStackCount != null && totalStackCount > 1)
            pw.Positioned(
              right: 3.0,
              bottom: 18.0,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 3.0, vertical: 0.5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.16, 0.15, 0.14, 0.9),
                  borderRadius: pw.BorderRadius.circular(2.0),
                  border: pw.Border.all(
                    color: const PdfColor(0.83, 0.69, 0.22),
                    width: 0.6,
                  ),
                ),
                child: pw.Text(
                  '${(stackIndex ?? 0) + 1}/$totalStackCount',
                  style: const pw.TextStyle(
                    fontSize: 6.5,
                    color: PdfColor(0.99, 0.90, 0.54),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Loads and transcodes sandboxed photo image bytes into PDF-compatible [pw.MemoryImage].
  static Future<pw.MemoryImage?> loadCompatibleImage(
    String relativePath,
    MediaSandboxService mediaService,
  ) async {
    try {
      final file = await mediaService.getFileFromRelativePath(relativePath);
      if (await file.exists()) {
        final rawBytes = await file.readAsBytes();
        final pngBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(rawBytes);
        return pw.MemoryImage(pngBytes);
      }
    } catch (_) {
      // Graceful fallback if image cannot be read or transcoded
    }
    return null;
  }

  /// Pre-loads and positions [attachments] into tactile Polaroid overlay widgets.
  static Future<List<pw.Widget>> buildOverlayCards({
    required List<MediaAttachment> attachments,
    required MediaSandboxService mediaService,
    required PdfFontResolver resolver,
    required double availableWidth,
    required double availableHeight,
    required bool isVertical,
  }) async {
    if (attachments.isEmpty) return const [];

    final primary = attachments.first;
    final (dx, dy) = resolvePlacement(
      xRatio: primary.overlayXRatio,
      yRatio: primary.overlayYRatio,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      isVertical: isVertical,
    );

    final image = await loadCompatibleImage(primary.relativePath, mediaService);
    final count = attachments.length;

    final stackWidgets = <pw.Widget>[];

    // Background card 2 (N >= 3)
    if (count >= 3) {
      stackWidgets.add(
        pw.Positioned(
          left: 6.0,
          top: 4.0,
          child: pw.Transform.rotate(
            angle: 0.08,
            child: _buildBackgroundCardShell(),
          ),
        ),
      );
    }

    // Background card 1 (N >= 2)
    if (count >= 2) {
      stackWidgets.add(
        pw.Positioned(
          left: 3.0,
          top: 2.0,
          child: pw.Transform.rotate(
            angle: -0.025,
            child: _buildBackgroundCardShell(),
          ),
        ),
      );
    }

    // Top card with rotation -0.055 rad
    stackWidgets.add(
      pw.Positioned(
        left: 0.0,
        top: 0.0,
        child: pw.Transform.rotate(
          angle: -0.055,
          child: buildPolaroidMiniCard(
            attachment: primary,
            image: image,
            resolver: resolver,
            stackIndex: 0,
            totalStackCount: count,
          ),
        ),
      ),
    );

    return [
      pw.Positioned(
        left: dx,
        top: dy,
        child: pw.Container(
          width: cardWidth + 12.0,
          height: cardHeight + 12.0,
          child: pw.Stack(
            children: stackWidgets,
          ),
        ),
      ),
    ];
  }
}
