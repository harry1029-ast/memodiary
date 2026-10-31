import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:uuid/uuid.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/begonia_plaque_button.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/octagonal_medallion_button.dart';
import 'package:memodiary/core/theme/widgets/scroll_roller_fab.dart';
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
import '../../editor/services/audio_sanctum_service.dart';
import '../../scenery/models/shanshui_atmosphere.dart';
import '../../scenery/screens/contemplation_view_screen.dart';
import '../../scenery/services/scenery_settings_service.dart';
import '../../scenery/services/shanshui_atmosphere_resolver.dart';
import '../../scenery/widgets/shanshui_scenery_card.dart';

/// Main screen displaying the reverse-chronological, lazy-paginated timeline feed of entries
/// styled in the Ink & Paper Journal (*墨记 · 水墨宣纸*) aesthetic.
class TimelineScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final ScenerySettingsService? scenerySettingsService;
  final AudioSanctumService? audioSanctumService;
  final bool? enableSceneryAnimation;
  final OcrQueueManager? ocrQueueManager;

  const TimelineScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.scenerySettingsService,
    this.audioSanctumService,
    this.enableSceneryAnimation,
    this.ocrQueueManager,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  late final ScenerySettingsService _scenerySettings;
  ShanshuiAtmosphereState? _pinnedAtmosphere;
  List<Entry> _entries = [];
  List<Entry> _onThisDayEntries = [];
  Map<String, MediaAttachment> _mediaMap = {};
  Notebook? _activeNotebook;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _errorMessage;
  bool _isSceneryVisible = true;
  bool _isFabRolledUp = false;

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
    _scenerySettings = widget.scenerySettingsService ?? ScenerySettingsService();
    _scrollController.addListener(_onScroll);
    _loadInitial();
    _loadScenerySettings();
  }

  Future<void> _loadScenerySettings() async {
    final pinned = await _scenerySettings.getPinnedAtmosphere();
    if (mounted && pinned != _pinnedAtmosphere) {
      setState(() => _pinnedAtmosphere = pinned);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isVisible = _scrollController.offset <= 240.0;
      if (isVisible != _isSceneryVisible) {
        setState(() => _isSceneryVisible = isVisible);
      }

      // Dynamic rolling physics for Scroll-Roller FAB
      final userDirection = _scrollController.position.userScrollDirection;
      if (userDirection == ScrollDirection.reverse && !_isFabRolledUp) {
        setState(() => _isFabRolledUp = true);
      } else if ((userDirection == ScrollDirection.forward || _scrollController.offset <= 12) && _isFabRolledUp) {
        setState(() => _isFabRolledUp = false);
      }
    }
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  ShanshuiAtmosphereState _resolveRealTimeAtmosphere() {
    final latestWeather = _entries.isNotEmpty ? _entries.first.weather : null;
    return ShanshuiAtmosphereResolver.resolve(
      now: DateTime.now(),
      latestEntryWeather: latestWeather,
    );
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
        automaticallyImplyLeading: false,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tokens.jiaomo,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '拾光日记',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OctagonalMedallionButton(
              key: const Key('timeline_weekly_review_button'),
              icon: Icons.calendar_view_week_rounded,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OctagonalMedallionButton(
              key: const Key('timeline_search_button'),
              icon: Icons.search_rounded,
              tooltip: '检索墨痕',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(
                      database: widget.database,
                      mediaService: widget.mediaService,
                      ocrQueueManager: widget.ocrQueueManager,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _loadInitial();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: OctagonalMedallionButton(
              key: const Key('timeline_settings_button'),
              icon: Icons.settings_outlined,
              tooltip: '设置与私隐',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      database: widget.database,
                      mediaService: widget.mediaService,
                      ocrQueueManager: widget.ocrQueueManager,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _loadInitial();
                });
              },
            ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ScrollRollerFab(
        key: const Key('timeline_write_fab'),
        isRolledUp: _isFabRolledUp,
        onPressed: () => _handleCreateEntry(),
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
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: tokens.danmo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Active Volume Begonia Plaque Button
              BegoniaPlaqueButton(
                key: const Key('timeline_notebook_selector_button'),
                label: activeVolumeTitle,
                leading: Icon(
                  Icons.auto_stories_outlined,
                  size: 13,
                  color: tokens.cinnabar,
                ),
                trailing: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: tokens.danmo,
                ),
                onTap: _handleOpenNotebooks,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Shanshui Scenery Card with Embedded Thought Spark Dock
          Builder(
            builder: (context) {
              final realTimeAtmosphere = _resolveRealTimeAtmosphere();
              final activeAtmosphere = _pinnedAtmosphere ?? realTimeAtmosphere;

              return ShanshuiSceneryCard(
                atmosphere: activeAtmosphere,
                activePrompt: _thoughtSparks[_sparkIndex],
                onRefreshPrompt: () {
                  setState(() {
                    _sparkIndex = (_sparkIndex + 1) % _thoughtSparks.length;
                  });
                },
                onWritePrompt: (prompt) => _handleCreateEntry(prompt),
                onOpenContemplation: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContemplationViewScreen(
                        initialAtmosphere: activeAtmosphere,
                        realTimeAtmosphere: realTimeAtmosphere,
                        audioService: widget.audioSanctumService ??
                            AudioSanctumService(),
                        enableAmbientAnimation: widget.enableSceneryAnimation,
                      ),
                    ),
                  );
                },
                settingsService: _scenerySettings,
                enableAmbientAnimation: widget.enableSceneryAnimation,
                isVisible: _isSceneryVisible,
              );
            },
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
