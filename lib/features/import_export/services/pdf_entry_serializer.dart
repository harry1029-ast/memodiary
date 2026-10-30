import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import 'image_format_transcoder.dart';
import 'pdf_font_resolver.dart';

class _InlineSpan {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrike;
  final PdfColor? color;

  const _InlineSpan({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrike = false,
    this.color,
  });
}

enum _BlockType {
  header1,
  header2,
  header3,
  blockquote,
  bulletList,
  orderedList,
  paragraph,
}

class _LineBlock {
  final List<_InlineSpan> spans;
  _BlockType type = _BlockType.paragraph;
  int? listIndex;

  _LineBlock({
    required this.spans,
  });
}

/// Converts Flutter Quill Delta JSON into a sequential list of flowable [pw.Widget] items
/// for multi-page PDF generation. Resolves sandboxed WebP photos into PNG [pw.MemoryImage].
class PdfEntrySerializer {
  const PdfEntrySerializer._();

  /// Converts Delta JSON or fallback plain text into PDF widgets.
  static Future<List<pw.Widget>> convertDeltaToWidgets({
    required String contentDeltaJson,
    required String fallbackPlainText,
    required MediaSandboxService mediaService,
    required TemplateStyle style,
    required PdfFontResolver fontResolver,
  }) async {
    final widgets = <pw.Widget>[];

    List<dynamic>? ops;
    if (contentDeltaJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentDeltaJson);
        if (decoded is List) {
          ops = decoded;
        } else if (decoded is Map && decoded['ops'] is List) {
          ops = decoded['ops'] as List;
        }
      } catch (_) {
        ops = null;
      }
    }

    if (ops == null || ops.isEmpty) {
      // Fallback: render plain text line by line
      final lines = fallbackPlainText.split('\n');
      for (final line in lines) {
        final sanitized = fontResolver.sanitizeText(line.trimRight());
        if (sanitized.isNotEmpty) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(
                sanitized,
                style: pw.TextStyle(
                  font: fontResolver.regularFont,
                  fontSize: 11,
                  lineSpacing: style.lineSpacing,
                ),
              ),
            ),
          );
        } else {
          widgets.add(pw.SizedBox(height: 6));
        }
      }
      return widgets;
    }

    // Process Delta operations into line blocks and image embeds
    final lineBlocks = <_LineBlock>[];
    var currentSpans = <_InlineSpan>[];
    int orderedListCounter = 1;

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = (op['attributes'] as Map?) ?? const {};

      // 1. Embedded Image Object
      if (insert is Map && insert.containsKey('image')) {
        // Flush any pending text before the image
        if (currentSpans.isNotEmpty) {
          lineBlocks.add(_LineBlock(spans: List.from(currentSpans)));
          currentSpans.clear();
        }

        // Flush line blocks collected so far into widgets
        _flushLineBlocks(lineBlocks, widgets, fontResolver, style);
        lineBlocks.clear();

        final imageSource = insert['image']?.toString() ?? '';
        final imageWidget = await _buildImageWidget(
          imageSource,
          mediaService,
          fontResolver,
        );
        widgets.add(imageWidget);
        continue;
      }

      // 1b. Embedded Video Object (Graceful Poster Fallback)
      if (insert is Map && insert.containsKey('video')) {
        // Flush any pending text before the video
        if (currentSpans.isNotEmpty) {
          lineBlocks.add(_LineBlock(spans: List.from(currentSpans)));
          currentSpans.clear();
        }

        // Flush line blocks collected so far into widgets
        _flushLineBlocks(lineBlocks, widgets, fontResolver, style);
        lineBlocks.clear();

        final videoSource = insert['video']?.toString() ?? '';
        final videoWidget = await _buildVideoWidget(
          videoSource,
          mediaService,
          fontResolver,
        );
        widgets.add(videoWidget);
        continue;
      }

      // 2. Text String
      if (insert is String) {
        final isBold = attributes['bold'] == true;
        final isItalic = attributes['italic'] == true;
        final isUnderline = attributes['underline'] == true;
        final isStrike = attributes['strike'] == true;

        PdfColor? textColor;
        final colorVal = attributes['color']?.toString();
        if (colorVal != null && colorVal.startsWith('#')) {
          textColor = PdfColor.fromInt(
            TemplateStyle.parseHexColor(colorVal).toARGB32(),
          );
        }

        final segments = insert.split('\n');
        for (int i = 0; i < segments.length; i++) {
          final seg = segments[i];
          if (seg.isNotEmpty) {
            currentSpans.add(
              _InlineSpan(
                text: fontResolver.sanitizeText(seg),
                isBold: isBold,
                isItalic: isItalic,
                isUnderline: isUnderline,
                isStrike: isStrike,
                color: textColor,
              ),
            );
          }

          if (i < segments.length - 1) {
            // Newline encountered: determine block format
            final block = _LineBlock(spans: List.from(currentSpans));
            currentSpans.clear();

            if (attributes['header'] == 1) {
              block.type = _BlockType.header1;
              orderedListCounter = 1;
            } else if (attributes['header'] == 2) {
              block.type = _BlockType.header2;
              orderedListCounter = 1;
            } else if (attributes['header'] == 3) {
              block.type = _BlockType.header3;
              orderedListCounter = 1;
            } else if (attributes['blockquote'] == true) {
              block.type = _BlockType.blockquote;
              orderedListCounter = 1;
            } else if (attributes['list'] == 'bullet') {
              block.type = _BlockType.bulletList;
              orderedListCounter = 1;
            } else if (attributes['list'] == 'ordered') {
              block.type = _BlockType.orderedList;
              block.listIndex = orderedListCounter++;
            } else {
              block.type = _BlockType.paragraph;
              orderedListCounter = 1;
            }
            lineBlocks.add(block);
          }
        }
      }
    }

    if (currentSpans.isNotEmpty) {
      lineBlocks.add(_LineBlock(spans: currentSpans));
    }

    _flushLineBlocks(lineBlocks, widgets, fontResolver, style);
    return widgets;
  }

  static void _flushLineBlocks(
    List<_LineBlock> blocks,
    List<pw.Widget> widgets,
    PdfFontResolver fontResolver,
    TemplateStyle style,
  ) {
    for (final block in blocks) {
      if (block.spans.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      final textSpans = block.spans.map((span) {
        pw.Font font;
        if (span.isBold && span.isItalic) {
          font = fontResolver.boldItalicFont;
        } else if (span.isBold) {
          font = fontResolver.boldFont;
        } else if (span.isItalic) {
          font = fontResolver.italicFont;
        } else {
          font = fontResolver.regularFont;
        }

        return pw.TextSpan(
          text: span.text,
          style: pw.TextStyle(
            font: font,
            color: span.color ?? PdfColors.black,
            decoration: span.isUnderline
                ? pw.TextDecoration.underline
                : (span.isStrike ? pw.TextDecoration.lineThrough : null),
          ),
        );
      }).toList();

      switch (block.type) {
        case _BlockType.header1:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: textSpans,
                  style: pw.TextStyle(
                    font: fontResolver.boldFont,
                    fontSize: 20,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),
          );
          break;

        case _BlockType.header2:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: textSpans,
                  style: pw.TextStyle(
                    font: fontResolver.boldFont,
                    fontSize: 16,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),
          );
          break;

        case _BlockType.header3:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: textSpans,
                  style: pw.TextStyle(
                    font: fontResolver.boldFont,
                    fontSize: 13,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),
          );
          break;

        case _BlockType.blockquote:
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.grey600, width: 3.5),
                ),
              ),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: textSpans,
                  style: pw.TextStyle(
                    font: fontResolver.italicFont,
                    fontSize: 11,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
            ),
          );
          break;

        case _BlockType.bulletList:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 4, left: 4, right: 6),
                    width: 3.5,
                    height: 3.5,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.black,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: textSpans,
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case _BlockType.orderedList:
          final idx = block.listIndex ?? 1;
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$idx. ',
                    style: pw.TextStyle(
                      font: fontResolver.boldFont,
                      fontSize: 11,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: textSpans,
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case _BlockType.paragraph:
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: textSpans,
                  style: pw.TextStyle(
                    font: fontResolver.regularFont,
                    fontSize: 11,
                    lineSpacing: style.lineSpacing,
                  ),
                ),
              ),
            ),
          );
          break;
      }
    }
  }

  static Future<pw.Widget> _buildImageWidget(
    String source,
    MediaSandboxService mediaService,
    PdfFontResolver fontResolver,
  ) async {
    try {
      final file = await mediaService.getFileFromRelativePath(source);
      if (await file.exists()) {
        final rawBytes = await file.readAsBytes();
        final pngBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(rawBytes);
        final memoryImage = pw.MemoryImage(pngBytes);

        // Constrained image to prevent page break overflows (Watchpoint 2)
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 8),
          alignment: pw.Alignment.center,
          constraints: const pw.BoxConstraints(maxHeight: 260.0),
          child: pw.ClipRRect(
            horizontalRadius: 6,
            verticalRadius: 6,
            child: pw.Image(
              memoryImage,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
      }
    } catch (_) {
      // Fallback on decode/transcode failure
    }

    return pw.Container(
      height: 40,
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Text(
        '[Image: $source]',
        style: pw.TextStyle(
          font: fontResolver.italicFont,
          fontSize: 9,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  static Future<pw.Widget> _buildVideoWidget(
    String source,
    MediaSandboxService mediaService,
    PdfFontResolver fontResolver,
  ) async {
    pw.MemoryImage? memoryImage;

    try {
      String thumbPath = source;
      if (source.endsWith('.mp4')) {
        thumbPath = '${source.substring(0, source.length - 4)}_thumb.webp';
      }
      final file = await mediaService.getFileFromRelativePath(thumbPath);
      if (await file.exists()) {
        final rawBytes = await file.readAsBytes();
        final pngBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(rawBytes);
        memoryImage = pw.MemoryImage(pngBytes);
      }
    } catch (_) {
      // Fallback if poster thumbnail is missing or fails to transcode
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      alignment: pw.Alignment.center,
      constraints: const pw.BoxConstraints(maxHeight: 220.0),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (memoryImage != null)
            pw.ClipRRect(
              horizontalRadius: 6,
              verticalRadius: 6,
              child: pw.Image(
                memoryImage,
                fit: pw.BoxFit.contain,
              ),
            )
          else
            pw.Container(
              height: 120,
              width: 220,
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey800,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '[Video Attachment]',
                style: pw.TextStyle(
                  font: fontResolver.italicFont,
                  fontSize: 10,
                  color: PdfColors.grey300,
                ),
              ),
            ),
          pw.Positioned(
            bottom: 8,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0, 0, 0, 0.75),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Video: Local playback only',
                style: pw.TextStyle(
                  font: fontResolver.regularFont,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
