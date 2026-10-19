import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/search/models/search_filters.dart';
import 'package:memodiary/features/search/services/event_suggestion_service.dart';
import 'package:memodiary/features/search/services/natural_language_search_parser.dart';
import 'package:memodiary/features/search/widgets/event_suggestion_chips.dart';
import 'package:memodiary/features/search/widgets/search_filter_chips.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';

/// Offline Full-Text Search (FTS5), Natural Language Event Search & Multi-Condition Filter screen.
/// Branches queries cleanly and conceals sealed Time Capsules for strict privacy.
class SearchScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final NaturalLanguageSearchParser parser;
  final EventSuggestionService? suggestionService;
  final DateTime? referenceNow;

  const SearchScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.parser = const NaturalLanguageSearchParser(),
    this.suggestionService,
    this.referenceNow,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  SearchFilters _filters = const SearchFilters();
  List<Entry> _results = [];
  Map<String, MediaAttachment> _mediaMap = {};
  List<EventSuggestion> _eventSuggestions = [];
  List<DetectedConstraint> _detectedConstraints = [];
  final Set<ConstraintKind> _dismissedKinds = {};
  String _lastRawQuery = '';
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
    _loadEventSuggestions();
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
    } catch (e) {
      debugPrint('Error loading event suggestions: $e');
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
      final results = await widget.database.searchEntriesWithFilters(
        query: parsed.keywords,
        startDate: effectiveFilters.resolvedStartDate,
        endDate: effectiveFilters.resolvedEndDate,
        mood: effectiveFilters.mood,
        weather: effectiveFilters.weather,
        hasImage: effectiveFilters.hasImage,
        weeklyReviewOnly: effectiveFilters.weeklyReviewOnly,
        excludeSealedTimeCapsules: true, // Privacy invariant
      );

      final ids = results.map((e) => e.id).toList();
      final mediaMap = await widget.database.getPrimaryMediaForEntries(ids);

      if (mounted) {
        setState(() {
          _results = results;
          _mediaMap = mediaMap;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error executing search: $e\n$st');
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const Key('search_text_field'),
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search diaries, memories, keywords...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _debounceTimer?.cancel();
                      _searchController.clear();
                      _dismissedKinds.clear();
                      _lastRawQuery = '';
                      _executeSearch();
                    },
                  )
                : null,
          ),
          onSubmitted: (_) {
            _debounceTimer?.cancel();
            _executeSearch();
          },
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SearchFilterChips(
            filters: _filters,
            onFiltersChanged: _onFiltersChanged,
          ),

          // Natural Language "Understood as" Removable Chips
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _detectedConstraints.isEmpty
                ? const SizedBox.shrink()
                : _buildUnderstoodAsBar(theme),
          ),

          // Smart Event Association Suggestions
          if (_eventSuggestions.isNotEmpty)
            EventSuggestionChips(
              suggestions: _eventSuggestions,
              activeTerm: _searchController.text.trim(),
              onSuggestionTapped: _onSuggestionTapped,
            ),

          const Divider(height: 1),

          // Main Search Results Feed
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? _buildInitialPrompt(theme)
                    : _results.isEmpty
                        ? _buildNoResults(theme)
                        : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderstoodAsBar(ThemeData theme) {
    return Container(
      key: const Key('nl_understood_as_bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
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
                  Tooltip(
                    message: 'Understood as',
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Understood as:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ..._detectedConstraints.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Semantics(
                        label: 'Remove ${c.label} filter',
                        child: InputChip(
                          key: Key('nl_constraint_chip_${c.kind.name}'),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              c.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => _onDismissConstraint(c.kind),
                        ),
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

  Widget _buildInitialPrompt(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Your Diary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a keyword or select filters above to find entries.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.find_in_page_outlined,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching entries found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try checking for spelling, broadening your date range, or resetting filters.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
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
}

