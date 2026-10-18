import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
import 'package:memodiary/features/retrospection/widgets/on_this_day_banner.dart';
import 'package:memodiary/features/retrospection/widgets/serendipity_roulette_card.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/timeline/widgets/time_capsule_card.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

/// Main screen displaying the reverse-chronological, lazy-paginated timeline feed of entries.
class TimelineScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;

  const TimelineScreen({
    super.key,
    required this.database,
    required this.mediaService,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  List<Entry> _entries = [];
  List<Entry> _onThisDayEntries = [];
  Map<String, MediaAttachment> _mediaMap = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await widget.database.getTimelineEntries(
        limit: _pageSize,
        offset: 0,
      );

      final ids = entries.map((e) => e.id).toList();
      final mediaMap = await widget.database.getPrimaryMediaForEntries(ids);
      final onThisDay =
          await widget.database.getEntriesOnThisDay(DateTime.now());

      if (mounted) {
        setState(() {
          _entries = entries;
          _onThisDayEntries = onThisDay;
          _mediaMap = mediaMap;
          _offset = entries.length;
          _hasMore = entries.length >= _pageSize;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading timeline entries: $e\n$st');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextBatch = await widget.database.getTimelineEntries(
        limit: _pageSize,
        offset: _offset,
      );

      final ids = nextBatch.map((e) => e.id).toList();
      final nextMediaMap = await widget.database.getPrimaryMediaForEntries(ids);

      if (mounted) {
        setState(() {
          _entries.addAll(nextBatch);
          _mediaMap.addAll(nextMediaMap);
          _offset += nextBatch.length;
          _hasMore = nextBatch.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading more timeline entries: $e\n$st');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleCreateEntry() async {
    final newId = const Uuid().v4();
    final notebooks = await widget.database.getAllNotebooks();
    final notebookId =
        notebooks.isNotEmpty ? notebooks.first.id : 'notebook_default';
    final defaultTemplateId = notebooks.isNotEmpty
        ? notebooks.first.defaultTemplateId
        : 'template_minimalist_white';

    await widget.database.createEntry(
      EntriesCompanion.insert(
        id: newId,
        notebookId: notebookId,
        templateId: defaultTemplateId,
        title: const Value(''),
        contentDelta: jsonEncode([
          {'insert': '\n'}
        ]),
        plainText: '',
        entryDate: DateTime.now(),
      ),
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(
          database: widget.database,
          mediaSandboxService: widget.mediaService,
          entryId: newId,
        ),
      ),
    );

    if (mounted) {
      await _loadInitial();
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
      if (mounted) _loadInitial();
    });
  }

  void _handleOpenSerendipity() {
    SerendipityRouletteCard.show(
      context: context,
      database: widget.database,
      onOpenEntry: _navigateToDetail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MemoDiary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const Key('timeline_analytics_button'),
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Writing Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsDashboardScreen(
                    database: widget.database,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('timeline_weekly_review_button'),
            icon: const Icon(Icons.calendar_view_week_rounded),
            tooltip: 'Weekly Review',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyReviewScreen(
                    database: widget.database,
                    mediaService: widget.mediaService,
                  ),
                ),
              ).then((_) {
                if (mounted) _loadInitial();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    database: widget.database,
                    mediaService: widget.mediaService,
                  ),
                ),
              ).then((_) {
                if (mounted) _loadInitial();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Recycle Bin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecycleBinScreen(
                    database: widget.database,
                    mediaService: widget.mediaService,
                  ),
                ),
              ).then((_) {
                if (mounted) _loadInitial();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & Privacy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    database: widget.database,
                    mediaService: widget.mediaService,
                  ),
                ),
              ).then((_) {
                if (mounted) _loadInitial();
              });
            },
          ),
        ],
      ),
      body: _isLoading && _entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _entries.isEmpty
              ? _buildErrorState(theme)
              : _entries.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: 1 + _entries.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return OnThisDayBanner(
                              entries: _onThisDayEntries,
                              onEntryTap: _navigateToDetail,
                              onOpenSerendipity: _handleOpenSerendipity,
                            );
                          }

                          final entryIndex = index - 1;
                          if (entryIndex == _entries.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          final entry = _entries[entryIndex];
                          final item = TimelineEntryItem(
                            entry: entry,
                            primaryMedia: _mediaMap[entry.id],
                          );

                          if (item.isSealedTimeCapsule) {
                            return TimeCapsuleCard(item: item);
                          }

                          return EntrySummaryCard(
                            item: item,
                            mediaService: widget.mediaService,
                            onTap: () => _navigateToDetail(entry),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreateEntry,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Write Diary'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 72,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              'No Diary Entries Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your thoughts, daily moments, or a weekly review. Everything stays 100% private on your device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _handleCreateEntry,
              icon: const Icon(Icons.add),
              label: const Text('Write Your First Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Diary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred while loading entries.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
