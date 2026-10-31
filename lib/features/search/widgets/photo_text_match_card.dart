import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/database/models/photo_text_match.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';

/// Card displaying an OCR text match within an entry photo or album photo.
///
/// Highlights matching query keywords in [InkDiaryTokens.cinnabar] and displays
/// an ink badge "图中文字匹配".
class PhotoTextMatchCard extends StatelessWidget {
  final PhotoTextMatch match;
  final MediaSandboxService mediaService;
  final String query;
  final VoidCallback? onTap;

  const PhotoTextMatchCard({
    super.key,
    required this.match,
    required this.mediaService,
    this.query = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    final title = (match.parentTitle?.trim().isNotEmpty ?? false)
        ? match.parentTitle!.trim()
        : (match.sourceType == PhotoTextMatch.sourceAlbumPhoto ? '旅行相册' : '无题手札');

    final dateText = match.parentDate != null
        ? '${match.parentDate!.year}年${match.parentDate!.month}月${match.parentDate!.day}日'
        : '';

    final sourceLabel = match.sourceType == PhotoTextMatch.sourceAlbumPhoto ? '相册' : '日记';

    final snippetLine = _extractMatchingSnippet(match.ocrText, query);

    return XuanPaperCard(
      key: Key('search_photo_match_card_${match.id}'),
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thumbnail Image Preview
          _buildThumbnail(tokens),
          const SizedBox(width: 12),

          // 2. Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title & "图中文字匹配" Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tokens.jiaomo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildMatchBadge(tokens),
                  ],
                ),
                const SizedBox(height: 6),

                // Snippet with Keyword Highlighting
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: _buildSnippetSpans(
                      snippetLine,
                      query,
                      tokens,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Footer: Date and Source
                Row(
                  children: [
                    if (dateText.isNotEmpty) ...[
                      Text(
                        dateText,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 11,
                          color: tokens.danmo,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tokens.ricePaper,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: tokens.agedFiber, width: 0.5),
                      ),
                      child: Text(
                        sourceLabel,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 10,
                          color: tokens.nongmo,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(InkDiaryTokens tokens) {
    final relPath = match.thumbnailPath ?? match.relativePath;
    return FutureBuilder<String>(
      future: mediaService.resolveAbsolutePath(relPath),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.deckleBorder, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.file(
                  file,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(tokens),
                ),
              ),
            );
          }
        }
        return _buildPlaceholder(tokens);
      },
    );
  }

  Widget _buildPlaceholder(InkDiaryTokens tokens) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: tokens.agedFiber,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.deckleBorder, width: 1),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 26,
        color: tokens.danmo.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildMatchBadge(InkDiaryTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.cinnabarWash,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tokens.cinnabar.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        '图中文字匹配',
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: tokens.cinnabar,
        ),
      ),
    );
  }

  /// Extracts the line from OCR text most relevant to the search query.
  String _extractMatchingSnippet(String ocrText, String rawQuery) {
    final lines = ocrText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ocrText.trim();
    }

    final trimmedQuery = rawQuery.trim().toLowerCase();
    if (trimmedQuery.isNotEmpty) {
      // 1. Direct line substring match
      for (final line in lines) {
        if (line.toLowerCase().contains(trimmedQuery)) {
          return line;
        }
      }

      // 2. Any keyword token match
      final tokens = trimmedQuery
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();

      for (final line in lines) {
        final lower = line.toLowerCase();
        for (final token in tokens) {
          if (lower.contains(token)) {
            return line;
          }
        }
      }
    }

    return lines.first;
  }

  /// Builds a list of [TextSpan]s with matching query substrings bolded in cinnabar.
  List<TextSpan> _buildSnippetSpans(
    String text,
    String rawQuery,
    InkDiaryTokens tokens,
  ) {
    final baseStyle = TextStyle(
      fontFamily: InkDiaryTheme.fontKaiti,
      fontSize: 13,
      color: tokens.jiaomo,
      height: 1.35,
    );

    final highlightStyle = baseStyle.copyWith(
      color: tokens.cinnabar,
      fontWeight: FontWeight.bold,
    );

    final trimmedQuery = rawQuery.trim();
    if (trimmedQuery.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    // Collect query terms to highlight
    final terms = <String>[];
    terms.add(trimmedQuery);
    for (final part in trimmedQuery.split(RegExp(r'\s+'))) {
      if (part.isNotEmpty && !terms.contains(part)) {
        terms.add(part);
      }
    }

    // Sort terms longest to shortest for greedy match
    terms.sort((first, second) => second.length.compareTo(first.length));

    final pattern = terms.map(RegExp.escape).join('|');
    final regExp = RegExp(pattern, caseSensitive: false);

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: highlightStyle,
      ));
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(
        text: text.substring(cursor),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
