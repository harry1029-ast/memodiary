import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:uuid/uuid.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/scroll_roller_fab.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_charm_filter_sheet.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_feed.dart';
import 'package:memodiary/features/timeline/widgets/timeline_app_bar.dart';
import 'package:memodiary/features/timeline/widgets/timeline_empty_states.dart';
import '../../editor/services/audio_sanctum_service.dart';
import '../../scenery/models/shanshui_atmosphere.dart';
import '../../scenery/services/scenery_settings_service.dart';
import '../../scenery/services/shanshui_atmosphere_resolver.dart';

/// Main screen displaying the upper Jiangnan window (`Shanshui Scenery Card`),
/// the merged `Window Sill Ledge`, and the sticky `Chronicle Desk` timeline feed.
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

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  late final ScenerySettingsService _scenerySettings;
  late final AnimationController _xunExpandController;
  late final Animation<double> _xunExpandAnimation;

  ShanshuiAtmosphereState? _pinnedAtmosphere;
  SceneryRealmPreference _realmPreference = SceneryRealmPreference.auto;
  TimelineFilterState _filters = const TimelineFilterState();
  TimelineDateFacetSummary _facetSummary = TimelineDateFacetSummary.empty();
  List<Entry> _entries = [];
  List<Entry> _recentEntriesForScenery = [];
  Map<String, MediaAttachment> _mediaMap = {};
  Notebook? _activeNotebook;
  int _totalFilteredCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _errorMessage;
  bool _isSceneryVisible = true;
  bool _isFabRolledUp = false;
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
    _loadInitial();
    _loadScenerySettings();
  }

  Future<void> _loadScenerySettings() async {
    final pinned = await _scenerySettings.getPinnedAtmosphere();
    final realmPref = await _scenerySettings.getRealmPreference();
    if (mounted) {
      setState(() {
        _pinnedAtmosphere = pinned;
        _realmPreference = realmPref;
      });
    }
  }

  @override
  void dispose() {
    _xunExpandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isVisible = _scrollController.offset <= 280.0;
      if (isVisible != _isSceneryVisible) {
        setState(() => _isSceneryVisible = isVisible);
      }

      final userDirection = _scrollController.position.userScrollDirection;
      if (userDirection == ScrollDirection.reverse && !_isFabRolledUp) {
        setState(() => _isFabRolledUp = true);
      } else if ((userDirection == ScrollDirection.forward ||
              _scrollController.offset <= 12) &&
          _isFabRolledUp) {
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
    final now = DateTime.now();
    final sourceEntries = _recentEntriesForScenery.isNotEmpty
        ? _recentEntriesForScenery
        : _entries;
    Entry? eligibleEntry;
    for (final entry in sourceEntries) {
      if (ShanshuiAtmosphereResolver.isEntryEligibleForInference(
        isDeleted: entry.isDeleted,
        isLocked: entry.isLocked,
        unlockAt: entry.unlockAt,
        now: now,
      )) {
        eligibleEntry = entry;
        break;
      }
    }
    final latestWeather =
        sourceEntries.isNotEmpty ? sourceEntries.first.weather : null;
    return ShanshuiAtmosphereResolver.resolve(
      now: now,
      latestEntryWeather: latestWeather,
      entryTimestamp: eligibleEntry?.entryDate,
      entryTitle: eligibleEntry?.title,
      entryPlainText: eligibleEntry?.plainText,
      realmPreference: _realmPreference,
    );
  }

  Future<void> _loadInitial({bool refreshSceneryEntries = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dao = widget.database.entriesDao;
      final entries = await dao.getFilteredTimelineEntries(
        filters: _filters,
        limit: _pageSize,
        offset: 0,
      );
      final filteredCount = await dao.countFilteredTimelineEntries(
        filters: _filters,
      );
      final facetSummary = await dao.getTimelineDateFacetSummary(
        year: _filters.year,
        mood: _filters.mood,
        weather: _filters.weather,
        hasMediaOnly: _filters.hasMediaOnly,
        weeklyReviewOnly: _filters.weeklyReviewOnly,
      );

      final ids = entries.map((entry) => entry.id).toList();
      final mediaMap =
          await widget.database.mediaOcrDao.getPrimaryMediaForEntries(ids);

      List<Entry>? recentSceneryEntries;
      if (refreshSceneryEntries) {
        if (!_filters.hasActiveFilters &&
            _filters.sortOrder == TimelineSortOrder.newestFirst) {
          recentSceneryEntries = entries;
        } else {
          recentSceneryEntries = await dao.getTimelineEntries(limit: 5);
        }
      }

      final notebooks = await widget.database.templatesDao.getAllNotebooks();
      final activeNotebook = notebooks.isNotEmpty ? notebooks.first : null;

      if (mounted) {
        setState(() {
          _entries = entries;
          if (recentSceneryEntries != null) {
            _recentEntriesForScenery = recentSceneryEntries;
          }
          _facetSummary = facetSummary;
          _totalFilteredCount = filteredCount;
          _mediaMap = mediaMap;
          _activeNotebook = activeNotebook;
          _offset = entries.length;
          _hasMore = entries.length >= _pageSize;
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
          await widget.database.entriesDao.getFilteredTimelineEntries(
        filters: _filters,
        limit: _pageSize,
        offset: _offset,
      );
      final ids = nextBatch.map((entry) => entry.id).toList();
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
    final newId = const Uuid().v4();
    final notebookId = _activeNotebook?.id ?? 'notebook_default';
    final defaultTemplateId =
        _activeNotebook?.defaultTemplateId ?? 'template_minimalist_white';

    await widget.database.entriesDao.createEntry(
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
    final realTimeAtmosphere = _resolveRealTimeAtmosphere();
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
                  errorMessage: _errorMessage ?? '载入卷宗时发生未预料之异常。',
                  onRetry: _loadInitial,
                )
              : ChronicleDeskScrollBody(
                  scrollController: _scrollController,
                  xunExpandAnimation: _xunExpandAnimation,
                  activeAtmosphere: activeAtmosphere,
                  realTimeAtmosphere: realTimeAtmosphere,
                  scenerySettings: _scenerySettings,
                  audioSanctumService: widget.audioSanctumService,
                  enableAmbientAnimation: widget.enableSceneryAnimation,
                  isSceneryVisible: _isSceneryVisible,
                  isCandleLit: _isCandleLit,
                  filters: _filters,
                  facetSummary: _facetSummary,
                  totalFilteredCount: _totalFilteredCount,
                  entries: _entries,
                  mediaMap: _mediaMap,
                  mediaService: widget.mediaService,
                  hasMore: _hasMore,
                  onRefresh: _loadInitial,
                  onRealmPreferenceChanged: (pref) {
                    setState(() => _realmPreference = pref);
                  },
                  onToggleCandle: () {
                    setState(() => _isCandleLit = !_isCandleLit);
                  },
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
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ScrollRollerFab(
        key: const Key('timeline_write_fab'),
        isRolledUp: _isFabRolledUp,
        onPressed: _handleCreateEntry,
      ),
    );
  }
}
