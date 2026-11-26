import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/home/models/home_tab.dart';
import 'package:memodiary/features/timeline/models/timeline_date_index_entry.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/services/timeline_feed_loader.dart';
import 'package:memodiary/features/timeline/services/timeline_scenery_inference.dart';
import 'package:memodiary/features/timeline/services/timeline_scrubber_jump_controller.dart';
import 'package:memodiary/features/timeline/services/timeline_viewport_tracker.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_charm_filter_sheet.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_feed.dart';
import 'package:memodiary/features/timeline/widgets/timeline_app_bar.dart';
import 'package:memodiary/features/timeline/widgets/timeline_empty_states.dart';
import '../../editor/services/audio_sanctum_service.dart';
import '../../scenery/models/shanshui_atmosphere.dart';
import '../../scenery/services/scenery_settings_service.dart';

/// Main screen displaying the upper Jiangnan window (`Shanshui Scenery Card`),
/// the merged `Window Sill Ledge`, and the sticky `Chronicle Desk` timeline feed.
class TimelineScreen extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final ScenerySettingsService? scenerySettingsService;
  final AudioSanctumService? audioSanctumService;
  final bool? enableSceneryAnimation;
  final OcrQueueManager? ocrQueueManager;

  /// Home Shell seam: the timeline attaches its 写日记 flow here so the
  /// Scroll Roller Button can trigger it.
  final HomeTabPrimaryAction? primaryAction;

  /// Home Shell seam: fires when a screen opened outside this tab (回收站,
  /// 导入与备份) may have changed entries, so the timeline reloads.
  final Listenable? diaryChanged;

  const TimelineScreen({
    super.key,
    required this.database,
    required this.mediaService,
    this.scenerySettingsService,
    this.audioSanctumService,
    this.enableSceneryAnimation,
    this.ocrQueueManager,
    this.primaryAction,
    this.diaryChanged,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin, HomeTabPrimaryActionBinding<TimelineScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TimelineViewportTracker _viewportTracker = TimelineViewportTracker();
  final TimelineScrubberJumpController _jumpController =
      TimelineScrubberJumpController();
  late final ScenerySettingsService _scenerySettings;
  late final AnimationController _xunExpandController;
  late final Animation<double> _xunExpandAnimation;

  ShanshuiAtmosphereState? _pinnedAtmosphere;
  SceneryRealmPreference _realmPreference = SceneryRealmPreference.auto;
  TimelineFilterState _filters = const TimelineFilterState();
  TimelineDateFacetSummary _facetSummary = TimelineDateFacetSummary.empty();
  List<TimelineEntrySummary> _entries = [];
  List<TimelineDateIndexEntry> _dateIndex = [];
  List<TimelineEntrySummary> _recentEntriesForScenery = [];
  Map<String, MediaAttachment> _mediaMap = {};
  Notebook? _activeNotebook;
  int _totalFilteredCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _errorMessage;
  bool _isSceneryVisible = true;
  bool _isCandleLit = true;

  @override
  void initState() {
    super.initState();
    _scenerySettings = widget.scenerySettingsService ?? ScenerySettingsService();
    _xunExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _xunExpandAnimation = CurvedAnimation(
      parent: _xunExpandController,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
    _scrollController.addListener(_onScroll);
    widget.diaryChanged?.addListener(_handleDiaryChanged);
    unawaited(_warmMediaSandbox());
    _loadInitial();
    _loadScenerySettings();
  }

  Future<void> _warmMediaSandbox() async {
    try {
      await widget.mediaService.getBaseDirectory();
    } catch (error, stackTrace) {
      debugPrint('Error warming media sandbox base directory: $error\n$stackTrace');
    }
  }

  Future<void> _loadScenerySettings() async {
    final pinned = await _scenerySettings.getPinnedAtmosphere();
    final realmPref = await _scenerySettings.getRealmPreference();
    if (!mounted) return;
    setState(() {
      _pinnedAtmosphere = pinned;
      _realmPreference = realmPref;
    });
  }

  @override
  void didUpdateWidget(covariant TimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diaryChanged != widget.diaryChanged) {
      oldWidget.diaryChanged?.removeListener(_handleDiaryChanged);
      widget.diaryChanged?.addListener(_handleDiaryChanged);
    }
    if (oldWidget.mediaService != widget.mediaService) {
      unawaited(_warmMediaSandbox());
    }
  }

  /// Reloads as many entries as were loaded, so the scroll position and the
  /// pages paged in so far survive the refresh.
  void _handleDiaryChanged() => _loadInitial(keepLoadedPages: true);

  @override
  HomeTabPrimaryAction? primaryActionOf(TimelineScreen widget) => widget.primaryAction;

  @override
  Future<void> runPrimaryAction() => _handleCreateEntry();

  @override
  void dispose() {
    widget.diaryChanged?.removeListener(_handleDiaryChanged);
    _xunExpandController.dispose();
    _scrollController.dispose();
    _viewportTracker.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isVisible = _scrollController.offset <= 280.0;
      if (isVisible != _isSceneryVisible) {
        setState(() => _isSceneryVisible = isVisible);
      }
    }
    if (_jumpController.isJumping) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
    unawaited(
      _jumpController.backfillVisibleMedia(
        database: widget.database,
        currentEntries: _entries,
        viewportTracker: _viewportTracker,
        isMounted: () => mounted,
        onMergeMedia: (fetchedMedia) {
          setState(() => _mediaMap.addAll(fetchedMedia));
        },
      ),
    );
  }

  Future<void> _loadInitial({bool refreshSceneryEntries = true, bool keepLoadedPages = false}) async {
    final limit = keepLoadedPages && _offset > _pageSize ? _offset : _pageSize;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await loadTimelineFeedSnapshot(
        database: widget.database,
        filters: _filters,
        limit: limit,
        refreshSceneryEntries: refreshSceneryEntries,
        onResetQueriedMedia: _jumpController.resetQueriedMedia,
      );

      if (mounted) {
        setState(() {
          _entries = snapshot.entries;
          _dateIndex = snapshot.dateIndex;
          if (snapshot.recentSceneryEntries != null) {
            _recentEntriesForScenery = snapshot.recentSceneryEntries!;
          }
          _facetSummary = snapshot.facetSummary;
          _totalFilteredCount = snapshot.totalFilteredCount;
          _mediaMap = snapshot.mediaMap;
          _activeNotebook = snapshot.activeNotebook;
          _offset = snapshot.entries.length;
          _hasMore = snapshot.entries.length >= limit;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error loading timeline entries: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
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
      final nextBatch =
          await widget.database.entriesDao.getFilteredTimelineSummaries(
        filters: _filters,
        limit: _pageSize,
        offset: _offset,
      );
      final ids = nextBatch.map((entry) => entry.id).toList();
      _jumpController.markMediaQueried(ids);
      final nextMediaMap =
          await widget.database.mediaOcrDao.getPrimaryMediaForEntries(ids);

      if (mounted) {
        setState(() {
          _entries.addAll(nextBatch);
          _mediaMap.addAll(nextMediaMap);
          _offset += nextBatch.length;
          _hasMore = nextBatch.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error loading more timeline entries: $error\n$stackTrace');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _applyFilterUpdate(TimelineFilterState nextFilters) {
    final hadMonth = _filters.month != null;
    final hasMonth = nextFilters.month != null;
    setState(() => _filters = nextFilters);

    if (hadMonth != hasMonth) {
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (disableAnimations) {
        _xunExpandController.value = hasMonth ? 1.0 : 0.0;
      } else if (hasMonth) {
        _xunExpandController.forward();
      } else {
        _xunExpandController.reverse();
      }
    }
    _loadInitial(refreshSceneryEntries: false);
  }

  Future<void> _handleCreateEntry() async {
    final newId = await createBlankTimelineEntry(
      database: widget.database,
      activeNotebook: _activeNotebook,
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
      if (mounted && _scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  void _navigateToDetail(TimelineEntrySummary summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailScreen(
          entryId: summary.id,
          database: widget.database,
          mediaService: widget.mediaService,
        ),
      ),
    ).then((_) {
      if (mounted) _loadInitial(keepLoadedPages: true);
    });
  }

  Future<void> _handleScrubberJump(int targetIndex) {
    return _jumpController.jumpToIndex(
      TimelineScrubberJumpRequest(
        rawTargetIndex: targetIndex,
        database: widget.database,
        filters: _filters,
        totalFilteredCount: _totalFilteredCount,
        currentEntries: _entries,
        currentMediaMap: _mediaMap,
        scrollController: _scrollController,
        viewportTracker: _viewportTracker,
        isMounted: () => mounted,
        onApplyLoadedState: ({
          required entries,
          required mediaMap,
          required offset,
          required hasMore,
        }) {
          setState(() {
            _entries = entries;
            _mediaMap = mediaMap;
            _offset = offset;
            _hasMore = hasMore;
          });
        },
      ),
    );
  }

  void _handleOpenCharmFilter() {
    ChronicleCharmFilterSheet.show(
      context: context,
      initialFilters: _filters,
      onFiltersChanged: _applyFilterUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final realTimeAtmosphere = resolveTimelineAtmosphere(
      recentEntriesForScenery: _recentEntriesForScenery,
      fallbackEntries: _entries,
      realmPreference: _realmPreference,
    );
    final activeAtmosphere = _pinnedAtmosphere != null
        ? _pinnedAtmosphere!.copyWith(
            realm: realTimeAtmosphere.realm,
            isJournalInferred: realTimeAtmosphere.isJournalInferred,
          )
        : realTimeAtmosphere;

    return Scaffold(
      backgroundColor: tokens.xuanGround,
      appBar: TimelineAppBar(
        database: widget.database,
        mediaService: widget.mediaService,
        ocrQueueManager: widget.ocrQueueManager,
        scenerySettings: _scenerySettings,
        onReturnFromSubscreen: () {
          if (mounted) _loadInitial();
        },
        onReturnFromSettings: () {
          if (mounted) {
            _loadInitial();
            _loadScenerySettings();
          }
        },
      ),
      body: _isLoading &&
              _entries.isEmpty &&
              _facetSummary.totalActiveEntries == 0
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _entries.isEmpty
              ? TimelineErrorState(
                  errorMessage: _errorMessage ?? '加载日记时发生未知错误。',
                  onRetry: _loadInitial,
                )
              : ChronicleDeskScrollBody(
                  scrollController: _scrollController,
                  sceneryConfig: TimelineSceneryHeaderConfig(
                    activeAtmosphere: activeAtmosphere,
                    realTimeAtmosphere: realTimeAtmosphere,
                    scenerySettings: _scenerySettings,
                    audioSanctumService: widget.audioSanctumService,
                    enableAmbientAnimation: widget.enableSceneryAnimation,
                    isVisible: _isSceneryVisible,
                    isCandleLit: _isCandleLit,
                    onRealmPreferenceChanged: (pref) {
                      setState(() => _realmPreference = pref);
                    },
                    onToggleCandle: () {
                      setState(() => _isCandleLit = !_isCandleLit);
                    },
                  ),
                  filterData: ChronicleDeskFilterData(
                    filters: _filters,
                    facetSummary: _facetSummary,
                    totalFilteredCount: _totalFilteredCount,
                    xunExpandAnimation: _xunExpandAnimation,
                  ),
                  feedData: ChronicleDeskFeedData(
                    entries: _entries,
                    dateIndex: _dateIndex,
                    mediaMap: _mediaMap,
                    mediaService: widget.mediaService,
                    hasMore: _hasMore,
                  ),
                  viewportTracker: _viewportTracker,
                  callbacks: ChronicleDeskFeedCallbacks(
                    onRefresh: _loadInitial,
                    onOpenCharmFilter: _handleOpenCharmFilter,
                    onSelectYear: (year) => _applyFilterUpdate(
                      _filters.selectYear(year),
                    ),
                    onSelectMonth: (month) => _applyFilterUpdate(
                      _filters.selectMonth(
                        month,
                        availableYears: _facetSummary.years,
                      ),
                    ),
                    onSelectXun: (xun) => _applyFilterUpdate(
                      _filters.selectXun(xun),
                    ),
                    onToggleSort: () => _applyFilterUpdate(
                      _filters.toggleSortOrder(),
                    ),
                    onCreateEntry: _handleCreateEntry,
                    onClearFilters: () =>
                        _applyFilterUpdate(_filters.resetAll()),
                    onEntryTap: _navigateToDetail,
                    onScrubberJump: _handleScrubberJump,
                  ),
                ),
    );
  }
}
