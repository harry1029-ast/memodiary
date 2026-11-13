import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../services/natural_language_search_parser.dart';

/// Available segmented view modes for search results.
enum SearchSegment {
  all,
  entries,
  photos,
}

/// Horizontal segmented bar switching between all results, entries, and photo text matches.
class SearchSegmentBar extends StatelessWidget {
  final SearchSegment selectedSegment;
  final bool hasSearched;
  final int entryResultCount;
  final int photoResultCount;
  final ValueChanged<SearchSegment> onSegmentSelected;

  const SearchSegmentBar({
    super.key,
    required this.selectedSegment,
    required this.hasSearched,
    required this.entryResultCount,
    required this.photoResultCount,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentChip(
              key: const Key('search_segment_all'),
              label: '全部',
              isSelected: selectedSegment == SearchSegment.all,
              onTap: () => onSegmentSelected(SearchSegment.all),
              tokens: tokens,
            ),
            const SizedBox(width: 8),
            _buildSegmentChip(
              key: const Key('search_segment_entries'),
              label: '日记',
              count: hasSearched ? entryResultCount : null,
              isSelected: selectedSegment == SearchSegment.entries,
              onTap: () => onSegmentSelected(SearchSegment.entries),
              tokens: tokens,
            ),
            const SizedBox(width: 8),
            _buildSegmentChip(
              key: const Key('search_segment_photos'),
              label: '图中文字',
              count: hasSearched ? photoResultCount : null,
              isSelected: selectedSegment == SearchSegment.photos,
              onTap: () => onSegmentSelected(SearchSegment.photos),
              tokens: tokens,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentChip({
    required Key key,
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required InkDiaryTokens tokens,
  }) {
    final displayText = count != null ? '$label ($count)' : label;
    return InkWell(
      key: key,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? tokens.jiaomo : tokens.ricePaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tokens.jiaomo : tokens.agedFiber,
            width: 1.0,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? tokens.xuanGround : tokens.danmo,
          ),
        ),
      ),
    );
  }
}

/// Banner prompting the user to index historical photos that lack OCR text.
class SearchBackfillBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const SearchBackfillBanner({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return InkWell(
      key: const Key('search_ocr_backfill_banner'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.ricePaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.agedFiber),
        ),
        child: Row(
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 16,
              color: tokens.cinnabar,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '发现 $pendingCount 张照片尚未建立文字索引',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontKaiti,
                  fontSize: 12,
                  color: tokens.jiaomo,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: tokens.danmo,
            ),
          ],
        ),
      ),
    );
  }
}

/// Removable chips displaying constraints extracted from natural language queries.
class SearchUnderstoodAsBar extends StatelessWidget {
  final List<DetectedConstraint> detectedConstraints;
  final ValueChanged<ConstraintKind> onDismissConstraint;

  const SearchUnderstoodAsBar({
    super.key,
    required this.detectedConstraints,
    required this.onDismissConstraint,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Container(
      key: const Key('nl_understood_as_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: tokens.cinnabarWash,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: tokens.cinnabar,
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 6),
                    Text(
                      '笔意解析:',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tokens.cinnabar,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ...detectedConstraints.map((constraint) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        key: Key('nl_constraint_chip_${constraint.kind.name}'),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            constraint.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontKaiti,
                              fontSize: 12,
                              color: tokens.cinnabar,
                            ),
                          ),
                        ),
                        deleteIcon: Semantics(
                          label: 'Remove ${constraint.label} filter',
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: tokens.cinnabar,
                          ),
                        ),
                        backgroundColor: tokens.ricePaper,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => onDismissConstraint(constraint.kind),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Top search bar with back navigation, search input field, and clear action.
class SearchQueryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  const SearchQueryAppBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return AppBar(
      backgroundColor: tokens.xuanGround,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: tokens.agedFiber,
          width: 1.0,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: tokens.jiaomo),
        tooltip: '返回',
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Container(
        height: 40,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.ricePaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.agedFiber),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: tokens.danmo),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('search_text_field'),
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 14,
                  color: tokens.jiaomo,
                ),
                decoration: InputDecoration(
                  hintText: '搜寻手札、心境、旧忆...',
                  hintStyle: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 13,
                    color: tokens.danmo,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (query) => onSubmitted(),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: tokens.danmo),
              ),
          ],
        ),
      ),
    );
  }
}
