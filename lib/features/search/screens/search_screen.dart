import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../../../core/services/ocr/ocr_queue_manager.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../settings/widgets/ocr_backfill_dialog.dart';
import '../../timeline/screens/entry_detail_screen.dart';
import '../models/search_filters.dart';
import '../services/event_suggestion_service.dart';
import '../services/natural_language_search_parser.dart';
import '../widgets/event_suggestion_chips.dart';
import '../widgets/search_empty_states.dart';
import '../widgets/search_filter_chips.dart';
import '../widgets/search_header_bars.dart';
import '../widgets/search_results_list.dart';
import 'ocr_photo_viewer_screen.dart';

export '../widgets/search_header_bars.dart' show SearchSegment;

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

      final entrySearchFuture =
          widget.database.entriesDao.searchEntriesWithFilters(
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
          ? widget.database.mediaOcrDao.searchPhotoText(
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
      final mediaMap =
          await widget.database.mediaOcrDao.getPrimaryMediaForEntries(ids);

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

  String _computeEffectiveQuery() {
    final rawQuery = _searchController.text.trim();
    final parsed = widget.parser.parse(
      rawQuery,
      now: widget.referenceNow,
      ignoredKinds: _dismissedKinds,
    );
    return parsed.keywords.isNotEmpty ? parsed.keywords : rawQuery;
  }

  void _onPhotoMatchTapped(PhotoTextMatch match) {
    if (widget.onPhotoMatchTap != null) {
      widget.onPhotoMatchTap!(match);
      return;
    }
    final effectiveQuery = _computeEffectiveQuery();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => OcrPhotoViewerScreen(
          match: match,
          query: effectiveQuery,
          mediaSandboxService: widget.mediaService,
          database: widget.database,
        ),
      ),
    );
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

  Future<void> _openBackfillDialog() async {
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

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: SearchQueryAppBar(
        controller: _searchController,
        onSubmitted: () {
          _debounceTimer?.cancel();
          _executeSearch();
        },
        onClear: () {
          _debounceTimer?.cancel();
          _searchController.clear();
          _dismissedKinds.clear();
          _lastRawQuery = '';
          _executeSearch();
        },
      ),
      body: Column(
        children: [
          SearchFilterChips(
            filters: _filters,
            onFiltersChanged: _onFiltersChanged,
          ),
          SearchSegmentBar(
            selectedSegment: _selectedSegment,
            hasSearched: _hasSearched,
            entryResultCount: _results.length,
            photoResultCount: _photoResults.length,
            onSegmentSelected: (segment) {
              setState(() {
                _selectedSegment = segment;
              });
            },
          ),
          if (widget.ocrQueueManager != null && _pendingBackfillCount > 0)
            SearchBackfillBanner(
              pendingCount: _pendingBackfillCount,
              onTap: _openBackfillDialog,
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _detectedConstraints.isEmpty
                ? const SizedBox.shrink()
                : SearchUnderstoodAsBar(
                    detectedConstraints: _detectedConstraints,
                    onDismissConstraint: _onDismissConstraint,
                  ),
          ),
          if (_eventSuggestions.isNotEmpty)
            EventSuggestionChips(
              suggestions: _eventSuggestions,
              activeTerm: _searchController.text.trim(),
              onSuggestionTapped: _onSuggestionTapped,
            ),
          if (_hasSearched && !_isLoading && _hasAnyResults())
            SearchResultsCounterBanner(
              selectedSegment: _selectedSegment,
              entryCount: _results.length,
              photoCount: _photoResults.length,
            ),
          Expanded(
            child: _buildMainContent(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(InkDiaryTokens tokens) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: tokens.cinnabar));
    }
    if (!_hasSearched) {
      return SearchInitialPrompt(
        quickInspirations: _quickInspirations,
        onInspirationTapped: (inspiration) {
          _searchController.text = inspiration;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: inspiration.length),
          );
          _executeSearch();
        },
      );
    }

    return SearchResultsList(
      selectedSegment: _selectedSegment,
      entries: _results,
      photoMatches: _photoResults,
      mediaMap: _mediaMap,
      mediaService: widget.mediaService,
      effectiveQuery: _computeEffectiveQuery(),
      onEntryTap: _navigateToDetail,
      onPhotoMatchTap: _onPhotoMatchTapped,
    );
  }
}
