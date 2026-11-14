import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/documents/entry_content_decoder.dart';
import '../../../core/documents/entry_vertical_packer.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../import_export/models/pdf_layout_mode.dart';
import '../../import_export/widgets/pdf_preview_screen.dart';
import '../../templates/models/template_style.dart';
import '../../templates/widgets/template_canvas_painter.dart';
import 'keepsake/keepsake_colophon.dart';
import 'keepsake/keepsake_column.dart';
import 'keepsake/keepsake_media_card.dart';

/// Fullscreen read-only Keepsake Scroll View (卷轴赏鉴) rendering diary entries
/// in classical right-to-left vertical columns with authentic typography,
/// tipped-in ephemera media cards, and the user's Cinnabar Signature Seal.
class KeepsakeScrollView extends StatelessWidget {
  final Entry entry;
  final TemplateStyle style;
  final MediaSandboxService? mediaService;
  final AppDatabase? database;

  const KeepsakeScrollView({
    super.key,
    required this.entry,
    required this.style,
    this.mediaService,
    this.database,
  });

  static Future<void> show({
    required BuildContext context,
    required Entry entry,
    required TemplateStyle style,
    MediaSandboxService? mediaService,
    AppDatabase? database,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => KeepsakeScrollView(
          entry: entry,
          style: style,
          mediaService: mediaService,
          database: database,
        ),
      ),
    );
  }

  bool get _isDark =>
      ThemeData.estimateBrightnessForColor(style.backgroundColor) == Brightness.dark;

  Color get _inkColor => _isDark ? const Color(0xFFF0ECE3) : const Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Scaffold(
        backgroundColor: style.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            key: const Key('keepsake_close_button'),
            icon: Icon(Icons.arrow_back, color: _inkColor, size: 22.0),
            tooltip: '返回 · Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '卷轴赏鉴 · ${(entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : "无题"}',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: _inkColor,
            ),
          ),
          actions: [
            if (database != null)
              IconButton(
                key: const Key('keepsake_export_pdf_button'),
                icon: Icon(Icons.picture_as_pdf_outlined, color: tokens.cinnabar, size: 22.0),
                tooltip: '导出墨卷 PDF',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => PdfPreviewScreen(
                        singleEntry: entry,
                        database: database!,
                        mediaService: mediaService,
                        initialLayoutMode: PdfLayoutMode.verticalScroll,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: CustomPaint(
          painter: TemplateCanvasPainter(style: style),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final items = _buildKeepsakeItems(constraints.maxHeight);

              return Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  key: const Key('keepsake_horizontal_scroll_view'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Render columns and ephemera cards right-to-left
                      ...items.map((item) => _renderItem(item)),

                      // Terminal colophon column and Cinnabar Signature Seal
                      KeepsakeColophon(
                        entry: entry,
                        style: style,
                        inkColor: _inkColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _renderItem(VerticalColumnItem item) {
    switch (item) {
      case VerticalTextColumn textItem:
        return KeepsakeColumn(
          styledTokens: textItem.styledTokens,
          ruleTint: style.tokens.ruleTint,
          inkColor: _inkColor,
          fontFamily: style.fontFamily ?? InkDiaryTheme.fontKaiti,
          fontSize: 16.0,
          isTitle: textItem.isTitle,
          isHeader: textItem.isHeader,
          isQuote: textItem.isQuote,
        );

      case VerticalMediaColumn mediaItem:
        return KeepsakeMediaCard(
          path: mediaItem.media.path,
          isVideo: mediaItem.isVideo,
          caption: mediaItem.media.caption,
          aspect: mediaItem.media.aspect,
          mediaService: mediaService,
          style: style,
          inkColor: _inkColor,
        );
    }
  }

  List<VerticalColumnItem> _buildKeepsakeItems(double availableHeight) {
    const double cellPitch = 24.0;
    final int maxCharsPerCol = ((availableHeight - 64.0) / cellPitch).floor().clamp(6, 40);

    final blocks = EntryContentDecoder.decode(
      contentDeltaJson: entry.contentDelta,
      fallbackPlainText: entry.plainText,
    );

    return EntryVerticalPacker.pack(
      blocks: blocks,
      maxTokensPerColumn: maxCharsPerCol,
      entryTitle: entry.title,
    );
  }
}
