import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/ink_metadata_pill.dart';
import 'package:memodiary/core/theme/widgets/xuan_paper_card.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/retrospection/widgets/on_this_day_banner.dart';
import 'package:memodiary/features/retrospection/widgets/serendipity_roulette_card.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';
import 'package:memodiary/features/timeline/widgets/notebook_selector_sheet.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/timeline/widgets/time_capsule_card.dart';
import 'package:memodiary/features/timeline/widgets/timeline_date_spine_item.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

/// Main screen displaying the reverse-chronological, lazy-paginated timeline feed of entries
/// styled in the Ink & Paper Journal (*墨记 · 水墨宣纸*) aesthetic.
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
  Notebook? _activeNotebook;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _errorMessage;

  // Thought Spark Inspiration Prompts
  int _sparkIndex = 0;
  static const List<String> _thoughtSparks = [
    '记录下一件让你觉得微小却真切的幸福，或许只是瓦檐下一滴落雨的声响。',
    '今天有没有一瞬间，让你想要停下来，多看一眼天边的云霞？',
    '如果用一种节气或草木来形容此刻的心境，那会是什么？',
    '最近读到或听到的一句话，哪一句久久停留在心头未曾散去？',
    '今日研墨提笔，最想对自己道一声怎样的闲语或慰藉？',
  ];

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

      final notebooks = await widget.database.getAllNotebooks();
      final activeNotebook = notebooks.isNotEmpty ? notebooks.first : null;

      if (mounted) {
        setState(() {
          _entries = entries;
          _onThisDayEntries = onThisDay;
          _mediaMap = mediaMap;
          _activeNotebook = activeNotebook;
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

  Future<void> _handleCreateEntry([String? initialPrompt]) async {
    final newId = const Uuid().v4();
    final notebookId =
        _activeNotebook?.id ?? 'notebook_default';
    final defaultTemplateId =
        _activeNotebook?.defaultTemplateId ?? 'template_minimalist_white';

    final initialDelta = initialPrompt != null && initialPrompt.isNotEmpty
        ? [
            {'insert': '【引子】$initialPrompt\n\n'},
            {'insert': '\n'}
          ]
        : [
            {'insert': '\n'}
          ];

    await widget.database.createEntry(
      EntriesCompanion.insert(
        id: newId,
        notebookId: notebookId,
        templateId: defaultTemplateId,
        title: const Value(''),
        contentDelta: jsonEncode(initialDelta),
        plainText: initialPrompt != null ? '【引子】$initialPrompt\n\n' : '',
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

  void _handleOpenNotebooks() {
    NotebookSelectorSheet.show(
      context: context,
      database: widget.database,
      currentNotebookId: _activeNotebook?.id ?? '',
      onNotebookSelected: (selected) {
        setState(() => _activeNotebook = selected);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CinnabarSealBadge.compact(
              text: '墨记',
              size: 28,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'MemoDiary',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '拾光日记',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 12,
                          color: tokens.danmo,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'INK DIARY · TIMELINE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: tokens.danmo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('timeline_weekly_review_button'),
            icon: const Icon(Icons.calendar_view_week_rounded),
            tooltip: '周志复盘',
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
            tooltip: '检索墨痕',
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
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置与私隐',
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
              ? _buildErrorState(tokens)
              : RefreshIndicator(
                  color: tokens.cinnabar,
                  onRefresh: _loadInitial,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 84),
                    itemCount: 2 + (_entries.isEmpty ? 1 : _entries.length) + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 1. Seasonal Epoch Header & Active Volume
                      if (index == 0) {
                        return _buildSeasonalHeader(tokens);
                      }

                      // 2. Retrospective OnThisDay banner
                      if (index == 1) {
                        return OnThisDayBanner(
                          entries: _onThisDayEntries,
                          onEntryTap: _navigateToDetail,
                          onOpenSerendipity: _handleOpenSerendipity,
                        );
                      }

                      // 3. Empty state
                      if (_entries.isEmpty && index == 2) {
                        return _buildEmptyState(tokens);
                      }

                      // 4. Loading indicator at bottom
                      final entryIndex = index - 2;
                      if (entryIndex == _entries.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      // 5. Timeline Entry Item with Continuous Date Spine
                      final entry = _entries[entryIndex];
                      final item = TimelineEntryItem(
                        entry: entry,
                        primaryMedia: _mediaMap[entry.id],
                      );

                      final isFirst = entryIndex == 0;
                      final isLast = entryIndex == _entries.length - 1 && !_hasMore;
                      final isHighlighted = isFirst || entry.isWeeklyReview;

                      final Widget card = item.isSealedTimeCapsule
                          ? TimeCapsuleCard(
                              item: item,
                              customMargin: EdgeInsets.zero,
                            )
                          : EntrySummaryCard(
                              item: item,
                              mediaService: widget.mediaService,
                              onTap: () => _navigateToDetail(entry),
                              customMargin: EdgeInsets.zero,
                            );

                      return TimelineDateSpineItem(
                        date: entry.entryDate,
                        isFirst: isFirst,
                        isLast: isLast,
                        isHighlighted: isHighlighted,
                        child: card,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleCreateEntry(),
        backgroundColor: tokens.cinnabar,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.brush_rounded, size: 20),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '挥毫落墨',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Write Diary',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalHeader(InkDiaryTokens tokens) {
    final activeVolumeTitle = _activeNotebook?.title ?? '默认册卷';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Seasonal solar term & lunar calendar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '岁月微澜',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.cinnabar,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '研墨静思',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.cinnabar,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '「纸寿千年，墨润万境。心迹随笔安放。」',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontLiterata,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Active Volume pill
              InkMetadataPill(
                label: activeVolumeTitle,
                leading: Icon(
                  Icons.auto_stories_outlined,
                  size: 14,
                  color: tokens.cinnabar,
                ),
                trailing: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: tokens.danmo,
                ),
                onTap: _handleOpenNotebooks,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Thought Spark Card (灵感火花)
          XuanPaperCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(12),
            backgroundColor: tokens.agedFiber.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.cinnabar,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '灵感火花 · THOUGHT SPARK',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: tokens.jiaomo,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _sparkIndex = (_sparkIndex + 1) % _thoughtSparks.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: tokens.danmo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '“${_thoughtSparks[_sparkIndex]}”',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontLiterata,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: tokens.nongmo,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _handleCreateEntry(_thoughtSparks[_sparkIndex]),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      foregroundColor: tokens.cinnabar,
                    ),
                    icon: const Icon(Icons.brush, size: 13),
                    label: const Text(
                      '由此题落墨',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(InkDiaryTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CinnabarSealBadge(
            text: '素宣\n待书',
            size: 64,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                '素宣待书',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'No Diary Entries Yet',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.danmo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '尚无墨痕存卷。记录当下的呼吸、微小的吉光、或沉潜的心绪。\n所有文字图影均安全封存于本地密匣。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontLiterata,
              fontSize: 13,
              height: 1.6,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _handleCreateEntry(),
            icon: const Icon(Icons.brush_rounded, size: 16),
            label: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: const [
                Text('写下第一卷'),
                Text('Write Your First Entry'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(InkDiaryTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: tokens.cinnabar,
            ),
            const SizedBox(height: 16),
            Text(
              '墨卷读取未畅',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '载入卷宗时发生未预料之异常。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontLiterata,
                fontSize: 12,
                color: tokens.danmo,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
