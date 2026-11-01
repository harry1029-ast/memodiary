import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../import_export/models/pdf_layout_mode.dart';
import '../../import_export/widgets/pdf_preview_screen.dart';
import '../../templates/models/template_style.dart';
import '../../templates/widgets/template_canvas_painter.dart';
import '../models/media_embed_data.dart';
import '../services/vertical_typography_mapper.dart';
import 'keepsake/keepsake_colophon.dart';
import 'keepsake/keepsake_column.dart';
import 'keepsake/keepsake_media_card.dart';

sealed class _KeepsakeItem {}

class _KeepsakeTextItem extends _KeepsakeItem {
  final List<String> tokens;
  final bool isTitle;
  final bool isHeader;
  final bool isQuote;

  _KeepsakeTextItem({
    required this.tokens,
    this.isTitle = false,
    this.isHeader = false,
    this.isQuote = false,
  });
}

class _KeepsakeMediaItem extends _KeepsakeItem {
  final bool isVideo;
  final String path;
  final String? caption;
  final String? aspect;

  _KeepsakeMediaItem({
    required this.isVideo,
    required this.path,
    this.caption,
    this.aspect,
  });
}

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

  Widget _renderItem(_KeepsakeItem item) {
    switch (item) {
      case _KeepsakeTextItem textItem:
        return KeepsakeColumn(
          tokens: textItem.tokens,
          ruleTint: style.tokens.ruleTint,
          inkColor: _inkColor,
          fontFamily: style.fontFamily ?? InkDiaryTheme.fontKaiti,
          fontSize: 16.0,
          isTitle: textItem.isTitle,
          isHeader: textItem.isHeader,
          isQuote: textItem.isQuote,
        );

      case _KeepsakeMediaItem mediaItem:
        return KeepsakeMediaCard(
          path: mediaItem.path,
          isVideo: mediaItem.isVideo,
          caption: mediaItem.caption,
          aspect: mediaItem.aspect,
          mediaService: mediaService,
          style: style,
          inkColor: _inkColor,
        );
    }
  }

  List<_KeepsakeItem> _buildKeepsakeItems(double availableHeight) {
    final items = <_KeepsakeItem>[];

    // Compute character capacity per vertical column based on available viewport height
    final double cellPitch = 24.0;
    final int maxCharsPerCol = ((availableHeight - 64.0) / cellPitch).floor().clamp(6, 40);

    // 1. Entry Title Column (if provided)
    if (entry.title != null && entry.title!.trim().isNotEmpty) {
      final titleTokens = VerticalTypographyMapper.tokenizeForVertical(entry.title!.trim());
      items.add(
        _KeepsakeTextItem(
          tokens: titleTokens,
          isTitle: true,
        ),
      );
    }

    // 2. Parse Quill Delta or fallback plain text
    List<dynamic>? ops;
    if (entry.contentDelta.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(entry.contentDelta);
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
      // Fallback: partition plain text
      final lines = entry.plainText.split('\n');
      for (final line in lines) {
        final trimmed = line.trimRight();
        if (trimmed.isEmpty) continue;
        final tokens = VerticalTypographyMapper.tokenizeForVertical(trimmed);
        _partitionTokensIntoColumns(tokens, maxCharsPerCol, items);
      }
      return items;
    }

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = (op['attributes'] as Map?) ?? const {};

      // 2a. Image embed
      if (insert is Map && insert.containsKey('image')) {
        final rawSource = insert['image']?.toString() ?? '';
        final embedData = MediaEmbedData.fromRaw(rawSource);
        items.add(
          _KeepsakeMediaItem(
            isVideo: false,
            path: embedData.path.isNotEmpty ? embedData.path : rawSource,
            caption: embedData.caption,
            aspect: embedData.aspect,
          ),
        );
        continue;
      }

      // 2b. Video embed
      if (insert is Map && insert.containsKey('video')) {
        final rawSource = insert['video']?.toString() ?? '';
        final embedData = MediaEmbedData.fromRaw(rawSource);
        items.add(
          _KeepsakeMediaItem(
            isVideo: true,
            path: embedData.path.isNotEmpty ? embedData.path : rawSource,
            caption: embedData.caption,
            aspect: embedData.aspect,
          ),
        );
        continue;
      }

      // 2c. Text string
      if (insert is String) {
        final isHeader = attributes['header'] != null;
        final isQuote = attributes['blockquote'] == true;
        final paragraphs = insert.split('\n');

        for (final para in paragraphs) {
          final trimmed = para.trim();
          if (trimmed.isEmpty) continue;
          final tokens = VerticalTypographyMapper.tokenizeForVertical(trimmed);
          _partitionTokensIntoColumns(
            tokens,
            maxCharsPerCol,
            items,
            isHeader: isHeader,
            isQuote: isQuote,
          );
        }
      }
    }

    return items;
  }

  void _partitionTokensIntoColumns(
    List<String> tokens,
    int maxPerCol,
    List<_KeepsakeItem> out, {
    bool isHeader = false,
    bool isQuote = false,
  }) {
    if (tokens.isEmpty) return;

    for (int i = 0; i < tokens.length; i += maxPerCol) {
      final end = (i + maxPerCol < tokens.length) ? i + maxPerCol : tokens.length;
      final chunk = tokens.sublist(i, end);
      out.add(
        _KeepsakeTextItem(
          tokens: chunk,
          isHeader: isHeader,
          isQuote: isQuote,
        ),
      );
    }
  }
}
