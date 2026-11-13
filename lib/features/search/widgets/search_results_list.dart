import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../timeline/models/timeline_entry_item.dart';
import '../../timeline/widgets/entry_summary_card.dart';
import '../widgets/photo_text_match_card.dart';
import 'search_empty_states.dart';
import 'search_header_bars.dart';

/// Banner summarizing total matched diary entries and OCR photo matches.
class SearchResultsCounterBanner extends StatelessWidget {
  final SearchSegment selectedSegment;
  final int entryCount;
  final int photoCount;

  const SearchResultsCounterBanner({
    super.key,
    required this.selectedSegment,
    required this.entryCount,
    required this.photoCount,
  });

  String _getResultsCountLabel() {
    switch (selectedSegment) {
      case SearchSegment.all:
        if (photoCount > 0 && entryCount > 0) {
          return '寻得 $entryCount 篇墨卷 · $photoCount 处图中文字';
        } else if (photoCount > 0) {
          return '寻得 $photoCount 处图中文字';
        }
        return '寻得 $entryCount 篇墨卷';
      case SearchSegment.entries:
        return '寻得 $entryCount 篇墨卷';
      case SearchSegment.photos:
        return '寻得 $photoCount 处图中文字';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: tokens.jiaomo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '检索录存',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: tokens.ricePaper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.agedFiber),
                ),
                child: Text(
                  _getResultsCountLabel(),
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                ),
              ),
            ],
          ),
          const CinnabarSealBadge(text: '澄心印记', isRound: true),
        ],
      ),
    );
  }
}

/// Renders segmented search results (combined, entries-only, or photo OCR matches).
class SearchResultsList extends StatelessWidget {
  final SearchSegment selectedSegment;
  final List<Entry> entries;
  final List<PhotoTextMatch> photoMatches;
  final Map<String, MediaAttachment> mediaMap;
  final MediaSandboxService mediaService;
  final String effectiveQuery;
  final ValueChanged<Entry> onEntryTap;
  final ValueChanged<PhotoTextMatch> onPhotoMatchTap;

  const SearchResultsList({
    super.key,
    required this.selectedSegment,
    required this.entries,
    required this.photoMatches,
    required this.mediaMap,
    required this.mediaService,
    required this.effectiveQuery,
    required this.onEntryTap,
    required this.onPhotoMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    switch (selectedSegment) {
      case SearchSegment.all:
        if (entries.isEmpty && photoMatches.isEmpty) {
          return const SearchNoResultsView();
        }
        return _buildCombinedResultsList(tokens);
      case SearchSegment.entries:
        if (entries.isEmpty) {
          return const SearchNoResultsView();
        }
        return _buildEntriesList();
      case SearchSegment.photos:
        if (photoMatches.isEmpty) {
          return const SearchNoPhotoResultsView();
        }
        return _buildPhotosList();
    }
  }

  Widget _buildEntryCard(Entry entry) {
    final item = TimelineEntryItem(
      entry: entry,
      primaryMedia: mediaMap[entry.id],
    );
    return EntrySummaryCard(
      item: item,
      mediaService: mediaService,
      onTap: () => onEntryTap(entry),
    );
  }

  Widget _buildPhotoCard(PhotoTextMatch match) {
    return PhotoTextMatchCard(
      match: match,
      mediaService: mediaService,
      query: effectiveQuery,
      onTap: () => onPhotoMatchTap(match),
    );
  }

  Widget _buildCombinedResultsList(InkDiaryTokens tokens) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (entries.isNotEmpty) ...[
          _buildSectionHeader('墨卷篇章', entries.length, tokens),
          ...entries.map(_buildEntryCard),
        ],
        if (photoMatches.isNotEmpty) ...[
          _buildSectionHeader('图中文字', photoMatches.length, tokens),
          ...photoMatches.map(_buildPhotoCard),
        ],
      ],
    );
  }

  Widget _buildEntriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildEntryCard(entries[index]),
    );
  }

  Widget _buildPhotosList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: photoMatches.length,
      itemBuilder: (context, index) => _buildPhotoCard(photoMatches[index]),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    InkDiaryTokens tokens,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: tokens.cinnabar,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 12,
              color: tokens.danmo,
            ),
          ),
        ],
      ),
    );
  }
}
