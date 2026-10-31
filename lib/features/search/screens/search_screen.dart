import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/services/ocr/ocr_queue_manager.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../timeline/models/timeline_entry_item.dart';
import '../../timeline/screens/entry_detail_screen.dart';
import '../../timeline/widgets/entry_summary_card.dart';
import '../models/search_filters.dart';
import '../services/event_suggestion_service.dart';
import '../services/natural_language_search_parser.dart';
import '../widgets/event_suggestion_chips.dart';
import '../widgets/photo_text_match_card.dart';
import '../widgets/search_filter_chips.dart';
import '../../settings/widgets/ocr_backfill_dialog.dart';

/// Available segmented view modes for search results.
enum SearchSegment {
  all,
  entries,
  photos,
}

/// Offline Full-Text Search (FTS5), Natural Language Event Search & Multi-Condition Filter screen
/// crafted in literati Ink & Paper aesthetic.
class SearchScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final NaturalLanguageSearchParser parser;
  final EventSuggestionService? suggestionService;
  final DateTime? referenceNow;
  final OcrQueueManager? ocrQueueManager;
  final void Function(PhotoTextMatch match)? onPhotoMatchTap;

  const SearchScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.parser = const NaturalLanguageSearchParser(),
    this.suggestionService,
    this.referenceNow,
    this.ocrQueueManager,
    this.onPhotoMatchTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  SearchFilters _filters = const SearchFilters();
  List<Entry> _results = [];
  List<PhotoTextMatch> _photoResults = [];
  Map<String, MediaAttachment> _mediaMap = {};
  List<EventSuggestion> _eventSuggestions = [];
  List<DetectedConstraint> _detectedConstraints = [];
  final Set<ConstraintKind> _dismissedKinds = {};
  String _lastRawQuery = '';
  bool _isLoading = false;
  bool _hasSearched = false;
  SearchSegment _selectedSegment = SearchSegment.all;
  int _pendingBackfillCount = 0;

  static const List<String> _quickInspirations = [
    '听雨',
    '霜降手札',
    '案头偶得',
    '静心随笔',
    '旧友煮茶',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
    _loadEventSuggestions();
    _loadBackfillCount();
  }

  Future<void> _loadBackfillCount() async {
    if (widget.ocrQueueManager == null) return;
    try {
      final count = await widget.ocrQueueManager!.pendingBackfillCount();
      if (mounted) {
        setState(() {
          _pendingBackfillCount = count;
        });
      }
    } catch (error) {
      debugPrint('Error loading OCR backfill count: $error');
    }
  }

  Future<void> _loadEventSuggestions() async {
    try {
      final service =
          widget.suggestionService ?? EventSuggestionService(widget.database);
      final suggestions = await service.getSuggestions(
        now: widget.referenceNow,
      );
      if (mounted) {
        setState(() {
          _eventSuggestions = suggestions;
        });
      }
    } catch (error) {
      debugPrint('Error loading event suggestions: $error');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    final currentText = _searchController.text.trim();
    if (currentText != _lastRawQuery) {
      _dismissedKinds.clear();
      _lastRawQuery = currentText;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch();
    });
  }

  void _onFiltersChanged(SearchFilters newFilters) {
    setState(() => _filters = newFilters);
    _executeSearch();
  }

  void _onSuggestionTapped(EventSuggestion suggestion) {
    _debounceTimer?.cancel();
    final currentText = _searchController.text.trim();
    if (currentText.toLowerCase() == suggestion.term.toLowerCase()) {
      _searchController.clear();
    } else {
      _searchController.text = suggestion.term;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
    _dismissedKinds.clear();
    _lastRawQuery = _searchController.text.trim();
    _executeSearch();
  }

  void _onDismissConstraint(ConstraintKind kind) {
    setState(() {
      _dismissedKinds.add(kind);
    });
    _executeSearch();
  }

  Future<void> _executeSearch() async {
    final rawQuery = _searchController.text.trim();
    if (rawQuery.isEmpty && !_filters.hasActiveFilters) {
      if (mounted) {
        setState(() {
          _results = [];
          _photoResults = [];
          _mediaMap = {};
          _detectedConstraints = [];
          _isLoading = false;
          _hasSearched = false;
        });
      }
      return;
    }

    final parsed = widget.parser.parse(
      rawQuery,
      now: widget.referenceNow,
      ignoredKinds: _dismissedKinds,
    );
    final effectiveFilters = parsed.applyTo(_filters);

    setState(() {
      _detectedConstraints = parsed.detected;
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final queryKeywords = parsed.keywords.trim();
      final effectivePhotoQuery =
          queryKeywords.isNotEmpty ? queryKeywords : rawQuery;

      final entrySearchFuture = widget.database.searchEntriesWithFilters(
        query: parsed.keywords,
        startDate: effectiveFilters.resolvedStartDate,
        endDate: effectiveFilters.resolvedEndDate,
        mood: effectiveFilters.mood,
        weather: effectiveFilters.weather,
        hasImage: effectiveFilters.hasImage,
        weeklyReviewOnly: effectiveFilters.weeklyReviewOnly,
        excludeSealedTimeCapsules: true, // Privacy invariant
      );

      final photoSearchFuture = effectivePhotoQuery.isNotEmpty
          ? widget.database.searchPhotoText(
              effectivePhotoQuery,
              now: widget.referenceNow,
            )
          : Future.value(<PhotoTextMatch>[]);

      final searchResults = await Future.wait([
        entrySearchFuture,
        photoSearchFuture,
      ]);

      final results = searchResults[0] as List<Entry>;
      final photoResults = searchResults[1] as List<PhotoTextMatch>;

      final ids = results.map((entry) => entry.id).toList();
      final mediaMap = await widget.database.getPrimaryMediaForEntries(ids);

      if (mounted) {
        setState(() {
          _results = results;
          _photoResults = photoResults;
          _mediaMap = mediaMap;
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error executing search: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _results = [];
          _photoResults = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onPhotoMatchTapped(PhotoTextMatch match) {
    if (widget.onPhotoMatchTap != null) {
      widget.onPhotoMatchTap!(match);
      return;
    }
  }

  void _navigateToDetail(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailScreen(
          entry: entry,
          database: widget.database,
          mediaService: widget.mediaService,
        ),
      ),
    ).then((_) {
      _loadEventSuggestions();
      _executeSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
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
                  controller: _searchController,
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
                  onSubmitted: (_) {
                    _debounceTimer?.cancel();
                    _executeSearch();
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _debounceTimer?.cancel();
                    _searchController.clear();
                    _dismissedKinds.clear();
                    _lastRawQuery = '';
                    _executeSearch();
                  },
                  child: Icon(Icons.close, size: 16, color: tokens.danmo),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SearchFilterChips(
            filters: _filters,
            onFiltersChanged: _onFiltersChanged,
          ),

          // Segmented Filter Bar: 全部 / 日记 / 图中文字
          _buildSegmentBar(tokens),

          // OCR Backfill Prompt Banner (if unindexed photos exist)
          _buildBackfillBanner(tokens),

          // Natural Language "Understood as" Removable Chips
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _detectedConstraints.isEmpty
                ? const SizedBox.shrink()
                : _buildUnderstoodAsBar(tokens),
          ),

          // Smart Event Association Suggestions
          if (_eventSuggestions.isNotEmpty)
            EventSuggestionChips(
              suggestions: _eventSuggestions,
              activeTerm: _searchController.text.trim(),
              onSuggestionTapped: _onSuggestionTapped,
            ),

          // Search Results Counter Banner (when results available)
          if (_hasSearched && !_isLoading && _hasAnyResults())
            _buildResultsCounterBanner(tokens),

          // Main Search Results Feed or Poetic Empty State
          Expanded(
            child: _buildMainContent(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBar(InkDiaryTokens tokens) {
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
              isSelected: _selectedSegment == SearchSegment.all,
              onTap: () {
                setState(() {
                  _selectedSegment = SearchSegment.all;
                });
              },
              tokens: tokens,
            ),
            const SizedBox(width: 8),
            _buildSegmentChip(
              key: const Key('search_segment_entries'),
              label: '日记',
              count: _hasSearched ? _results.length : null,
              isSelected: _selectedSegment == SearchSegment.entries,
              onTap: () {
                setState(() {
                  _selectedSegment = SearchSegment.entries;
                });
              },
              tokens: tokens,
            ),
            const SizedBox(width: 8),
            _buildSegmentChip(
              key: const Key('search_segment_photos'),
              label: '图中文字',
              count: _hasSearched ? _photoResults.length : null,
              isSelected: _selectedSegment == SearchSegment.photos,
              onTap: () {
                setState(() {
                  _selectedSegment = SearchSegment.photos;
                });
              },
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

  Widget _buildBackfillBanner(InkDiaryTokens tokens) {
    if (widget.ocrQueueManager == null || _pendingBackfillCount <= 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      key: const Key('search_ocr_backfill_banner'),
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => OcrBackfillDialog(
            ocrQueueManager: widget.ocrQueueManager!,
          ),
        );
        if (mounted) {
          await _loadBackfillCount();
          if (_searchController.text.trim().isNotEmpty) {
            _executeSearch();
          }
        }
      },
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
                '发现 $_pendingBackfillCount 张照片尚未建立文字索引',
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

  bool _hasAnyResults() {
    switch (_selectedSegment) {
      case SearchSegment.all:
        return _results.isNotEmpty || _photoResults.isNotEmpty;
      case SearchSegment.entries:
        return _results.isNotEmpty;
      case SearchSegment.photos:
        return _photoResults.isNotEmpty;
    }
  }

  String _getResultsCountLabel() {
    switch (_selectedSegment) {
      case SearchSegment.all:
        if (_photoResults.isNotEmpty && _results.isNotEmpty) {
          return '寻得 ${_results.length} 篇墨卷 · ${_photoResults.length} 处图中文字';
        } else if (_photoResults.isNotEmpty) {
          return '寻得 ${_photoResults.length} 处图中文字';
        }
        return '寻得 ${_results.length} 篇墨卷';
      case SearchSegment.entries:
        return '寻得 ${_results.length} 篇墨卷';
      case SearchSegment.photos:
        return '寻得 ${_photoResults.length} 处图中文字';
    }
  }

  Widget _buildResultsCounterBanner(InkDiaryTokens tokens) {
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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

  Widget _buildMainContent(InkDiaryTokens tokens) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: tokens.cinnabar));
    }
    if (!_hasSearched) {
      return _buildInitialPrompt(tokens);
    }

    switch (_selectedSegment) {
      case SearchSegment.all:
        if (_results.isEmpty && _photoResults.isEmpty) {
          return _buildNoResults(tokens);
        }
        return _buildCombinedResultsList(tokens);

      case SearchSegment.entries:
        if (_results.isEmpty) {
          return _buildNoResults(tokens);
        }
        return _buildEntriesList();

      case SearchSegment.photos:
        if (_photoResults.isEmpty) {
          return _buildNoPhotoResults(tokens);
        }
        return _buildPhotosList();
    }
  }

  Widget _buildCombinedResultsList(InkDiaryTokens tokens) {
    final query = _searchController.text.trim();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_results.isNotEmpty) ...[
          _buildSectionHeader('墨卷篇章', _results.length, tokens),
          ..._results.map((entry) {
            final item = TimelineEntryItem(
              entry: entry,
              primaryMedia: _mediaMap[entry.id],
            );
            return EntrySummaryCard(
              item: item,
              mediaService: widget.mediaService,
              onTap: () => _navigateToDetail(entry),
            );
          }),
        ],
        if (_photoResults.isNotEmpty) ...[
          _buildSectionHeader('图中文字', _photoResults.length, tokens),
          ..._photoResults.map((match) {
            return PhotoTextMatchCard(
              match: match,
              mediaService: widget.mediaService,
              query: query,
              onTap: () => _onPhotoMatchTapped(match),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEntriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final entry = _results[index];
        final item = TimelineEntryItem(
          entry: entry,
          primaryMedia: _mediaMap[entry.id],
        );
        return EntrySummaryCard(
          item: item,
          mediaService: widget.mediaService,
          onTap: () => _navigateToDetail(entry),
        );
      },
    );
  }

  Widget _buildPhotosList() {
    final query = _searchController.text.trim();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _photoResults.length,
      itemBuilder: (context, index) {
        final match = _photoResults[index];
        return PhotoTextMatchCard(
          match: match,
          mediaService: widget.mediaService,
          query: query,
          onTap: () => _onPhotoMatchTapped(match),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, InkDiaryTokens tokens) {
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

  Widget _buildNoPhotoResults(InkDiaryTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 52,
              color: tokens.danmo.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '图中文字杳然 · 暂无匹配照片',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '未在照片题字或路标存照中检索到匹配内容。\n可尝试更简短的字词，或确认照片已建立文字索引。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 13,
                color: tokens.danmo,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderstoodAsBar(InkDiaryTokens tokens) {
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
                  ..._detectedConstraints.map((constraint) {
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
                          child: Icon(Icons.close, size: 14, color: tokens.cinnabar),
                        ),
                        backgroundColor: tokens.ricePaper,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => _onDismissConstraint(constraint.kind),
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

  Widget _buildInitialPrompt(InkDiaryTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Literati Loupe Graphic with Seal
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.ricePaper,
                  border: Border.all(color: tokens.agedFiber),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.jiaomo.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pageview_outlined,
                  size: 44,
                  color: tokens.nongmo,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tokens.cinnabarWash,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Text(
                    '印',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: tokens.cinnabar,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            '墨海探微 · 静候落字',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '输入字句、年份或叩问心境，\n在泛黄宣纸深处翻寻旧日回响。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 13,
              height: 1.45,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 28),

          // Quick Inspiration Cloud
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.cinnabar)),
              const SizedBox(width: 6),
              Text(
                '案头灵犀 · 快捷索引',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.nongmo,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.cinnabar)),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickInspirations.map((inspiration) {
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _searchController.text = inspiration;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: inspiration.length),
                  );
                  _executeSearch();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: tokens.ricePaper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.agedFiber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('「', style: TextStyle(color: tokens.cinnabar, fontSize: 11)),
                      Text(
                        inspiration,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontKaiti,
                          fontSize: 12,
                          color: tokens.jiaomo,
                        ),
                      ),
                      Text('」', style: TextStyle(color: tokens.cinnabar, fontSize: 11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(InkDiaryTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.find_in_page_outlined,
              size: 52,
              color: tokens.danmo.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '墨痕杳然 · 暂无匹配记录',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '试探更换关键词、放宽时日范围，或重置筛选条件重新翻阅。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 13,
                color: tokens.danmo,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
