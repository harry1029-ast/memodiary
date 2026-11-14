import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/documents/entry_content_decoder.dart';
import '../../../core/documents/media_embed_data.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../templates/models/template_style.dart';
import 'image_format_transcoder.dart';
import 'pdf_font_resolver.dart';

/// Converts canonical diary content blocks into a sequential list of flowable
/// [pw.Widget] items for multi-page horizontal PDF generation.
class PdfEntrySerializer {
  const PdfEntrySerializer._();

  /// Converts persisted Quill Delta JSON (or [fallbackPlainText]) into PDF widgets.
  static Future<List<pw.Widget>> convertDeltaToWidgets({
    required String contentDeltaJson,
    required String fallbackPlainText,
    required MediaSandboxService mediaService,
    required TemplateStyle style,
    required PdfFontResolver fontResolver,
  }) => _blocksToWidgets(
        blocks: EntryContentDecoder.decode(
          contentDeltaJson: contentDeltaJson,
          fallbackPlainText: fallbackPlainText,
        ),
        mediaService: mediaService,
        style: style,
        fontResolver: fontResolver,
      );

  /// Converts pre-parsed Delta [ops] (or [fallbackPlainText] when empty) into PDF widgets.
  static Future<List<pw.Widget>> convertOpsToWidgets({
    required List<dynamic>? ops,
    required String fallbackPlainText,
    required MediaSandboxService mediaService,
    required TemplateStyle style,
    required PdfFontResolver fontResolver,
  }) => _blocksToWidgets(
        blocks: EntryContentDecoder.decodeOps(
          ops: ops,
          fallbackPlainText: fallbackPlainText,
        ),
        mediaService: mediaService,
        style: style,
        fontResolver: fontResolver,
      );

  static Future<List<pw.Widget>> _blocksToWidgets({
    required List<EntryContentBlock> blocks,
    required MediaSandboxService mediaService,
    required TemplateStyle style,
    required PdfFontResolver fontResolver,
  }) async {
    final widgets = <pw.Widget>[];

    for (final block in blocks) {
      switch (block) {
        case EntryMediaBlock mediaBlock:
          widgets.add(
            mediaBlock.isVideo
                ? await _buildVideoWidget(mediaBlock.media, mediaService, fontResolver)
                : await _buildImageWidget(mediaBlock.media, mediaService, fontResolver),
          );
        case EntryTextBlock textBlock:
          widgets.add(_buildTextBlockWidget(textBlock, fontResolver, style));
      }
    }

    return widgets;
  }

  static pw.Widget _buildTextBlockWidget(
    EntryTextBlock block,
    PdfFontResolver fontResolver,
    TemplateStyle style,
  ) {
    if (block.runs.isEmpty) {
      return pw.SizedBox(height: 6);
    }

    final isCheckedTodo = block.kind == EntryBlockKind.checkedList;
    final defaultColor = isCheckedTodo ? PdfColors.grey600 : PdfColors.black;
    final textSpans = _buildTextSpans(
      runs: block.runs,
      fontResolver: fontResolver,
      defaultColor: defaultColor,
      forceStrikeThrough: isCheckedTodo,
    );

    switch (block.kind) {
      case EntryBlockKind.header1:
        return _buildHeadingWidget(textSpans, fontResolver, fontSize: 20, top: 14, bottom: 8);
      case EntryBlockKind.header2:
        return _buildHeadingWidget(textSpans, fontResolver, fontSize: 16, top: 10, bottom: 6);
      case EntryBlockKind.header3:
        return _buildHeadingWidget(textSpans, fontResolver, fontSize: 13, top: 8, bottom: 4);
      case EntryBlockKind.blockquote:
        return pw.Container(
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
        );
      case EntryBlockKind.bulletList:
        return _buildListRow(
          leading: pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, left: 4, right: 6),
            width: 3.5,
            height: 3.5,
            decoration: const pw.BoxDecoration(
              color: PdfColors.black,
              shape: pw.BoxShape.circle,
            ),
          ),
          textSpans: textSpans,
        );
      case EntryBlockKind.orderedList:
        final ordinal = block.orderedIndex ?? 1;
        return _buildListRow(
          leading: pw.Text(
            '$ordinal. ',
            style: pw.TextStyle(
              font: fontResolver.boldFont,
              fontSize: 11,
            ),
          ),
          textSpans: textSpans,
        );
      case EntryBlockKind.checkedList:
      case EntryBlockKind.uncheckedList:
        return _buildListRow(
          leading: _buildCheckboxIndicator(isChecked: isCheckedTodo),
          textSpans: textSpans,
          baseTextColor: defaultColor,
        );
      case EntryBlockKind.paragraph:
        return pw.Padding(
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
        );
    }
  }

  static List<pw.TextSpan> _buildTextSpans({
    required List<EntryInlineRun> runs,
    required PdfFontResolver fontResolver,
    required PdfColor defaultColor,
    bool forceStrikeThrough = false,
  }) {
    return runs.map((run) {
      final rawText = run.isInterlinearNote ? '〖${run.text}〗' : run.text;
      final sanitizedText = fontResolver.sanitizeText(rawText);
      final parsedColor = TemplateStyle.tryParseHexColor(run.colorHex);
      final spanColor = parsedColor != null
          ? PdfColor.fromInt(parsedColor.toARGB32())
          : defaultColor;

      return pw.TextSpan(
        text: sanitizedText,
        style: pw.TextStyle(
          font: _resolveRunFont(run, fontResolver),
          color: spanColor,
          decoration: _resolveDecoration(
            isUnderline: run.isUnderline,
            isStrike: run.isStrike || forceStrikeThrough,
          ),
        ),
      );
    }).toList();
  }

  static pw.Font _resolveRunFont(EntryInlineRun run, PdfFontResolver resolver) {
    if (run.isBold && run.isItalic) return resolver.boldItalicFont;
    if (run.isBold) return resolver.boldFont;
    if (run.isItalic) return resolver.italicFont;
    return resolver.regularFont;
  }

  static pw.TextDecoration? _resolveDecoration({
    required bool isUnderline,
    required bool isStrike,
  }) {
    final decorations = <pw.TextDecoration>[
      if (isUnderline) pw.TextDecoration.underline,
      if (isStrike) pw.TextDecoration.lineThrough,
    ];
    if (decorations.isEmpty) return null;
    if (decorations.length == 1) return decorations.single;
    return pw.TextDecoration.combine(decorations);
  }

  static pw.Widget _buildHeadingWidget(
    List<pw.TextSpan> textSpans,
    PdfFontResolver fontResolver, {
    required double fontSize,
    required double top,
    required double bottom,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: top, bottom: bottom),
      child: pw.RichText(
        text: pw.TextSpan(
          children: textSpans,
          style: pw.TextStyle(
            font: fontResolver.boldFont,
            fontSize: fontSize,
            color: PdfColors.black,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildListRow({
    required pw.Widget leading,
    required List<pw.TextSpan> textSpans,
    PdfColor baseTextColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          leading,
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: textSpans,
                style: pw.TextStyle(fontSize: 11, color: baseTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckboxIndicator({required bool isChecked}) {
    return pw.Container(
      width: 9,
      height: 9,
      margin: const pw.EdgeInsets.only(top: 2.5, left: 2, right: 6),
      decoration: pw.BoxDecoration(
        color: isChecked ? PdfColors.grey800 : null,
        border: pw.Border.all(color: PdfColors.grey800, width: 0.9),
        borderRadius: pw.BorderRadius.circular(1.5),
      ),
      child: isChecked
          ? pw.CustomPaint(
              size: const PdfPoint(9, 9),
              painter: (canvas, size) {
                canvas
                  ..setStrokeColor(PdfColors.white)
                  ..setLineWidth(1.2)
                  ..moveTo(1.8, 4.5)
                  ..lineTo(3.8, 2.3)
                  ..lineTo(7.3, 6.7)
                  ..strokePath();
              },
            )
          : null,
    );
  }

  static Future<pw.MemoryImage?> _loadMemoryImage(
    String relativePath,
    MediaSandboxService mediaService,
  ) async {
    try {
      if (!MediaSandboxService.isStrictlyRelative(relativePath)) {
        return null;
      }
      final file = await mediaService.getFileFromRelativePath(relativePath);
      if (await file.exists()) {
        final rawBytes = await file.readAsBytes();
        final pngBytes = await ImageFormatTranscoder.ensurePdfCompatibleBytes(rawBytes);
        return pw.MemoryImage(pngBytes);
      }
    } catch (_) {
      // Fallback on decode/transcode failure
    }
    return null;
  }

  static pw.Widget _roundedImage(pw.MemoryImage memoryImage) {
    return pw.ClipRRect(
      horizontalRadius: 6,
      verticalRadius: 6,
      child: pw.Image(memoryImage, fit: pw.BoxFit.contain),
    );
  }

  static Future<pw.Widget> _buildImageWidget(
    MediaEmbedData media,
    MediaSandboxService mediaService,
    PdfFontResolver fontResolver,
  ) async {
    final memoryImage = await _loadMemoryImage(media.path, mediaService);
    final mediaWidget = memoryImage != null
        ? pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            alignment: pw.Alignment.center,
            constraints: const pw.BoxConstraints(maxHeight: 260.0),
            child: _roundedImage(memoryImage),
          )
        : pw.Container(
            height: 40,
            margin: const pw.EdgeInsets.symmetric(vertical: 6),
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Text(
              '[Image: ${fontResolver.sanitizeText(media.path)}]',
              style: pw.TextStyle(font: fontResolver.italicFont, fontSize: 9, color: PdfColors.grey600),
            ),
          );

    return _wrapWithOptionalCaption(mediaWidget: mediaWidget, caption: media.caption, fontResolver: fontResolver);
  }

  static Future<pw.Widget> _buildVideoWidget(
    MediaEmbedData media,
    MediaSandboxService mediaService,
    PdfFontResolver fontResolver,
  ) async {
    final thumbPath = media.thumbnailPath(isVideo: true);
    final memoryImage = await _loadMemoryImage(thumbPath, mediaService);

    final videoWidget = pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      alignment: pw.Alignment.center,
      constraints: const pw.BoxConstraints(maxHeight: 220.0),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (memoryImage != null)
            _roundedImage(memoryImage)
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
                style: pw.TextStyle(font: fontResolver.italicFont, fontSize: 10, color: PdfColors.grey300),
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
                style: pw.TextStyle(font: fontResolver.regularFont, fontSize: 8, color: PdfColors.white),
              ),
            ),
          ),
        ],
      ),
    );

    return _wrapWithOptionalCaption(mediaWidget: videoWidget, caption: media.caption, fontResolver: fontResolver);
  }

  static pw.Widget _wrapWithOptionalCaption({
    required pw.Widget mediaWidget,
    required String caption,
    required PdfFontResolver fontResolver,
  }) {
    final trimmedCaption = caption.trim();
    if (trimmedCaption.isEmpty) return mediaWidget;

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        mediaWidget,
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            fontResolver.sanitizeText(trimmedCaption),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: fontResolver.italicFont, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }
}
