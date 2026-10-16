import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/search/models/search_filters.dart';
import 'package:memodiary/features/search/widgets/search_filter_chips.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';

/// Offline Full-Text Search (FTS5) & Multi-Condition Filter screen.
/// Branches queries cleanly and conceals sealed Time Capsules for strict privacy.
class SearchScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;

  const SearchScreen({
    super.key,
    required this.database,
    required this.mediaService,
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
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch();
    });
  }

  void _onFiltersChanged(SearchFilters newFilters) {
    setState(() => _filters = newFilters);
    _executeSearch();
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && !_filters.hasActiveFilters) {
      if (mounted) {
        setState(() {
          _results = [];
          _mediaMap = {};
          _isLoading = false;
          _hasSearched = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await widget.database.searchEntriesWithFilters(
      query: query,
      startDate: _filters.resolvedStartDate,
      endDate: _filters.resolvedEndDate,
      mood: _filters.mood,
      weather: _filters.weather,
      hasImage: _filters.hasImage,
      weeklyReviewOnly: _filters.weeklyReviewOnly,
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
    ).then((_) => _executeSearch());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
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
                      _searchController.clear();
                      _executeSearch();
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _executeSearch(),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SearchFilterChips(
            filters: _filters,
            onFiltersChanged: _onFiltersChanged,
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

