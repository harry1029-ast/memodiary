import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';
import '../../../core/documents/entry_content_decoder.dart';
import '../../../core/documents/entry_vertical_packer.dart';
import '../../../core/documents/media_embed_data.dart';
import '../../../core/documents/vertical_typography_mapper.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import '../../timeline/services/folio_media_pairing.dart';
import 'image_format_transcoder.dart';
import 'pdf_font_resolver.dart';
import 'pdf_polaroid_overlay_builder.dart';
import 'pdf_template_renderer.dart';

sealed class _PdfKeepsakeItem {
  double get estimatedWidth;
}

class _PdfKeepsakeColumnItem extends _PdfKeepsakeItem {
  final List<VerticalStyledToken> styledTokens;
  final bool isTitle;
  final bool isHeader;
  final bool isQuote;

  _PdfKeepsakeColumnItem({
    required this.styledTokens,
    this.isTitle = false,
    this.isHeader = false,
    this.isQuote = false,
  });

  @override
  double get estimatedWidth => isTitle ? 32.0 : (isHeader ? 28.0 : 26.0);
}

class _PdfKeepsakeMediaItem extends _PdfKeepsakeItem {
  final pw.MemoryImage? image;
  final String caption;
  final bool isVideo;

  _PdfKeepsakeMediaItem({
    this.image,
    this.caption = '',
    this.isVideo = false,
  });

  @override
  double get estimatedWidth => 160.0;
}

class _PdfKeepsakeColophonItem extends _PdfKeepsakeItem {
  final Entry entry;
  final String sealText;

  _PdfKeepsakeColophonItem({
    required this.entry,
    required this.sealText,
  });

  @override
  double get estimatedWidth => 58.0;
}

/// Builds classical right-to-left vertical columnar scroll pages (卷轴竖排) for PDF export.
class PdfVerticalScrollBuilder {
  const PdfVerticalScrollBuilder._();

  /// Compiles entry content into landscape vector PDF pages in authentic right-to-left vertical flow.
  static Future<List<pw.Page>> buildVerticalScrollPages({
    required Entry entry,
    required TemplateStyle style,
    required MediaSandboxService mediaService,
    required PdfFontResolver fontResolver,
    required String sealText,
    FolioMountPlan mountPlan = const FolioMountPlan([]),
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final landscapeFormat = pageFormat.landscape;
    final marginX = style.marginHorizontal.clamp(24.0, 48.0);
    const marginY = 32.0;

    final pageWidgets = await buildPageWidgets(
      entry: entry,
      style: style,
      mediaService: mediaService,
      fontResolver: fontResolver,
      sealText: sealText,
      mountPlan: mountPlan,
      pageFormat: pageFormat,
    );

    return pageWidgets
        .map(
          (pageWidget) => pw.Page(
            pageTheme: pw.PageTheme(
              pageFormat: landscapeFormat,
              margin: pw.EdgeInsets.symmetric(horizontal: marginX, vertical: marginY),
              buildBackground: (context) => PdfTemplateRenderer.buildBackground(context, style),
            ),
            build: (context) => pageWidget,
          ),
        )
        .toList();
  }

  /// Compiles entry content into per-page vertical scroll [pw.Widget] trees.
  static Future<List<pw.Widget>> buildPageWidgets({
    required Entry entry,
    required TemplateStyle style,
    required MediaSandboxService mediaService,
    required PdfFontResolver fontResolver,
    required String sealText,
    FolioMountPlan mountPlan = const FolioMountPlan([]),
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final landscapeFormat = pageFormat.landscape;
    final marginX = style.marginHorizontal.clamp(24.0, 48.0);
    const marginY = 32.0;

    final availableHeight = landscapeFormat.height - (marginY * 2);
    final availableWidth = landscapeFormat.width - (marginX * 2);

    // Collect all vertical items (title, columns, media cards, terminal colophon)
    final items = await _parseEntryItems(
      entry: entry,
      availableHeight: availableHeight,
      mediaService: mediaService,
      sealText: sealText,
    );

    // Group items into pages based on available horizontal width
    final pagesItems = <List<_PdfKeepsakeItem>>[];
    var currentPage = <_PdfKeepsakeItem>[];
    double currentWidth = 0.0;

    for (final item in items) {
      if (currentWidth + item.estimatedWidth > availableWidth && currentPage.isNotEmpty) {
        pagesItems.add(currentPage);
        currentPage = <_PdfKeepsakeItem>[];
        currentWidth = 0.0;
      }
      currentPage.add(item);
      currentWidth += item.estimatedWidth;
    }
    if (currentPage.isNotEmpty) {
      pagesItems.add(currentPage);
    }

    // Pair mounted items with pages exactly as the Folio pairs them with leaves.
    final overlayCardsByPage = <List<pw.Widget>>[];
    final mountsByPage = mountPlan.mountsByLeaf(pagesItems.length);
    for (final mounted in mountsByPage) {
      overlayCardsByPage.add(mounted.isEmpty
          ? const <pw.Widget>[]
          : await PdfPolaroidOverlayBuilder.buildOverlayCards(
              attachments: mounted,
              mediaService: mediaService,
              resolver: fontResolver,
              availableWidth: availableWidth,
              availableHeight: availableHeight,
              isVertical: true,
            ));
    }

    // Build widget for each slice (reversed to flow right-to-left in standard LTR coordinate space)
    final widgets = <pw.Widget>[];
    for (int pageIndex = 0; pageIndex < pagesItems.length; pageIndex++) {
      final pageSlice = pagesItems[pageIndex];
      widgets.add(
        pw.Stack(
          children: [
            pw.Container(
              height: availableHeight,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: pageSlice.reversed
                    .map((item) => _renderPdfItem(item, style, fontResolver))
                    .toList(),
              ),
            ),
            ...overlayCardsByPage[pageIndex],
          ],
        ),
      );
    }

    return widgets;
  }

  static pw.Widget _renderPdfItem(
    _PdfKeepsakeItem item,
    TemplateStyle style,
    PdfFontResolver resolver,
  ) {
    final ruleColor = PdfTemplateRenderer.pdfRuleColor(style.tokens.ruleTint);

    switch (item) {
      case _PdfKeepsakeColumnItem col:
        final fontSize = col.isTitle
            ? 14.0
            : (col.isHeader ? 12.0 : (col.isQuote ? 10.0 : 10.5));
        final font = (col.isTitle || col.isHeader)
            ? resolver.boldFont
            : (col.isQuote ? resolver.italicFont : resolver.regularFont);
        final defaultColor = col.isQuote ? PdfColors.grey700 : PdfColors.black;

        return pw.Container(
          width: col.estimatedWidth,
          margin: const pw.EdgeInsets.symmetric(horizontal: 1.5),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              right: pw.BorderSide(color: ruleColor, width: 0.5),
              left: pw.BorderSide(color: ruleColor, width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          child: pw.Column(
            mainAxisAlignment: col.isTitle ? pw.MainAxisAlignment.center : pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: col.styledTokens.map((styledToken) {
              final token = styledToken.token;
              if (token is VerticalInterlinearPairToken) {
                final noteStyle = pw.TextStyle(
                  font: resolver.regularFont,
                  fontSize: (fontSize * 0.58).clamp(6.0, 9.0),
                  color: PdfColors.grey700,
                );
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                  child: pw.Row(
                    children: [token.leftChar, token.rightChar]
                        .map(
                          (charText) => pw.Expanded(
                            child: pw.Text(
                              resolver.sanitizeText(charText),
                              textAlign: pw.TextAlign.center,
                              style: noteStyle,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              }

              if (token is VerticalGlyphToken) {
                final sanitized = resolver.sanitizeText(token.glyph);
                final parsedColor = TemplateStyle.tryParseHexColor(styledToken.colorHex);
                final glyphColor = parsedColor != null
                    ? PdfColor.fromInt(parsedColor.toARGB32())
                    : defaultColor;
                final glyphStyle = pw.TextStyle(
                  font: font,
                  fontSize: fontSize,
                  color: glyphColor,
                );

                if (token.isCornerPunctuation) {
                  return pw.Container(
                    width: col.estimatedWidth,
                    alignment: pw.Alignment.topRight,
                    padding: const pw.EdgeInsets.only(right: 2.0),
                    child: pw.Text(sanitized, style: glyphStyle),
                  );
                }

                if (token.requiresQuarterTurnRotation) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
                    child: pw.Transform.rotate(
                      angle: math.pi / 2,
                      child: pw.Text(sanitized, style: glyphStyle),
                    ),
                  );
                }

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                  child: pw.Text(sanitized, style: glyphStyle),
                );
              }

              return pw.SizedBox();
            }).toList(),
          ),
        );

      case _PdfKeepsakeMediaItem media:
        return pw.Container(
          width: media.estimatedWidth,
          margin: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          padding: const pw.EdgeInsets.all(6.0),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.98, 0.96, 0.93),
            border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
            borderRadius: pw.BorderRadius.circular(4.0),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: media.image != null
                    ? pw.Image(media.image!, fit: pw.BoxFit.cover)
                    : pw.Center(
                        child: pw.Text(
                          media.isVideo ? '[短视频]' : '[图像]',
                          style: pw.TextStyle(font: resolver.italicFont, fontSize: 9),
                        ),
                      ),
              ),
              if (media.caption.isNotEmpty) ...[
                pw.SizedBox(height: 4.0),
                pw.Text(
                  resolver.sanitizeText(media.caption),
                  maxLines: 2,
                  style: pw.TextStyle(
                    font: resolver.italicFont,
                    fontSize: 8.0,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ],
          ),
        );

      case _PdfKeepsakeColophonItem colophon:
        final dateStr = DateFormat('yyyy年M月d日').format(colophon.entry.entryDate);
        const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
        final colophonText = '$dateStr 星期${weekdays[colophon.entry.entryDate.weekday - 1]}';
        final dateStyle = pw.TextStyle(font: resolver.regularFont, fontSize: 8.0, color: PdfColors.grey700);

        return pw.Container(
          width: colophon.estimatedWidth,
          margin: const pw.EdgeInsets.only(right: 6.0, left: 12.0),
          padding: const pw.EdgeInsets.symmetric(vertical: 12.0),
          decoration: pw.BoxDecoration(
            border: pw.Border(right: pw.BorderSide(color: ruleColor, width: 0.5)),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: colophonText
                    .split('')
                    .map(
                      (character) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                        child: pw.Text(resolver.sanitizeText(character), style: dateStyle),
                      ),
                    )
                    .toList(),
              ),
              PdfTemplateRenderer.buildSignatureSeal(
                style: style,
                fontResolver: resolver,
                sealText: colophon.sealText,
                size: 38.0,
              ),
            ],
          ),
        );
    }
  }

  static Future<List<_PdfKeepsakeItem>> _parseEntryItems({
    required Entry entry,
    required double availableHeight,
    required MediaSandboxService mediaService,
    required String sealText,
  }) async {
    final items = <_PdfKeepsakeItem>[];
    const double pitch = 14.0;
    final int maxCharsPerCol = ((availableHeight - 32.0) / pitch).floor().clamp(10, 36);

    final blocks = EntryContentDecoder.decode(
      contentDeltaJson: entry.contentDelta,
      fallbackPlainText: entry.plainText,
    );
    final packedColumns = EntryVerticalPacker.pack(
      blocks: blocks,
      maxTokensPerColumn: maxCharsPerCol,
      entryTitle: entry.title,
    );

    for (final packed in packedColumns) {
      switch (packed) {
        case VerticalTextColumn textCol:
          items.add(_PdfKeepsakeColumnItem(
            styledTokens: textCol.styledTokens,
            isTitle: textCol.isTitle,
            isHeader: textCol.isHeader,
            isQuote: textCol.isQuote,
          ));
        case VerticalMediaColumn mediaCol:
          final img = await _loadTranscodedImage(
            mediaCol.media,
            mediaService,
            isVideo: mediaCol.isVideo,
          );
          items.add(_PdfKeepsakeMediaItem(
            image: img,
            caption: mediaCol.media.caption,
            isVideo: mediaCol.isVideo,
          ));
      }
    }

    items.add(_PdfKeepsakeColophonItem(entry: entry, sealText: sealText));
    return items;
  }

  static Future<pw.MemoryImage?> _loadTranscodedImage(
    MediaEmbedData media,
    MediaSandboxService mediaService, {
    bool isVideo = false,
  }) async {
    try {
      final resolvedPath = media.thumbnailPath(isVideo: isVideo);
      final file = MediaSandboxService.isStrictlyRelative(resolvedPath)
          ? await mediaService.getFileFromRelativePath(resolvedPath)
          : null;
      if (file != null && await file.exists()) {
        final rawBytes = await file.readAsBytes();
        final pngBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(rawBytes);
        return pw.MemoryImage(pngBytes);
      }
    } catch (_) {}
    return null;
  }
}
