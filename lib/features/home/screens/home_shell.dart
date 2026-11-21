import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/features/albums/screens/album_collections_screen.dart';
import 'package:memodiary/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:memodiary/features/home/data/diarist_stats_repository.dart';
import 'package:memodiary/features/home/models/home_tab.dart';
import 'package:memodiary/features/home/widgets/diarist_panel.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_controller.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_edge_band.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_overlay.dart';
import 'package:memodiary/features/home/widgets/diarist_stats_strip.dart';
import 'package:memodiary/features/home/widgets/tab_rail.dart';
import 'package:memodiary/features/home/widgets/tab_rail_scroll_hider.dart';
import 'package:memodiary/features/import_export/screens/import_backup_screen.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';

/// The root screen once the cover is passed: the 日记 and 相册 tabs held in an
/// indexed stack (both keep their state; 相册 is built on first selection),
/// switched by tapping the [TabRail]. The rail hides while the active tab's
/// list scrolls forward ([TabRailVisibility]) and returns on a tab switch.
/// The Diarist Panel is laid over the whole shell, rail included, and is
/// dragged out from the left edge's upper band ([DiaristPanelEdgeBand]).
///
/// Every screen opened from a tab is pushed on the single root Navigator, so it
/// covers the shell and its rail. Android Back walks panel open → close it;
/// 相册 → 日记; 日记 → exit.
class HomeShell extends StatefulWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final OcrQueueManager? ocrQueueManager;
  final HomeTab initialTab;

  const HomeShell({
    super.key,
    required this.database,
    required this.mediaService,
    this.ocrQueueManager,
    this.initialTab = HomeTab.diary,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final DiaristPanelController _panel = DiaristPanelController(vsync: this);
  bool _isPanelOpen = false;
  late final DiaristStatsRepository _statsRepository = DiaristStatsRepository(database: widget.database);
  DiaristStats? _stats;

  /// Bumped when a panel screen that can change entries (回收站, 导入与备份)
  /// closes, so the 日记 tab reloads.
  final ValueNotifier<int> _diaryChanged = ValueNotifier(0);
  final Map<HomeTab, HomeTabPrimaryAction> _primaryActions = {
    for (final tab in HomeTab.values) tab: HomeTabPrimaryAction(),
  };
  final Set<HomeTab> _builtTabs = {};
  final TabRailVisibility _railVisibility = TabRailVisibility();
  late HomeTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _builtTabs.add(_selectedTab);
    _panel.animation.addListener(_syncPanelOpen);
  }

  /// Rebuilds the Back interception only when the panel opens or closes, and
  /// refetches the stats strip's counts each time it opens.
  void _syncPanelOpen() {
    if (_panel.isOpen == _isPanelOpen) return;
    setState(() => _isPanelOpen = _panel.isOpen);
    if (_isPanelOpen) _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _statsRepository.load();
    if (mounted) setState(() => _stats = stats);
  }

  /// A stats-strip tap: close the panel and show [tab].
  void _showTabFromPanel(HomeTab tab) {
    _panel.close();
    _selectTab(tab);
  }

  @override
  void dispose() {
    _panel.dispose();
    _railVisibility.dispose();
    _diaryChanged.dispose();
    super.dispose();
  }

  void _selectTab(HomeTab tab) {
    if (tab == _selectedTab) return;
    _railVisibility.reveal();
    setState(() {
      _selectedTab = tab;
      _builtTabs.add(tab);
    });
  }

  void _handlePopBlocked(bool didPop, Object? _) {
    if (didPop) return;
    if (_panel.isOpen) {
      _panel.close();
    } else if (_selectedTab != HomeTab.diary) {
      _selectTab(HomeTab.diary);
    }
  }

  /// A panel row: close the panel and push [screen] over the whole shell.
  /// When [changesDiary], the 日记 tab reloads once the screen closes.
  Future<void> _openFromPanel(WidgetBuilder screen, {bool changesDiary = false}) async {
    _panel.close();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: screen));
    if (mounted && changesDiary) _diaryChanged.value++;
  }

  /// Replaces the Home Shell with the cover (the cover is never kept below it).
  void _returnToCover() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookIntroScreen(
          database: widget.database,
          mediaService: widget.mediaService,
          ocrQueueManager: widget.ocrQueueManager,
        ),
      ),
    );
  }

  Widget _buildTab(HomeTab tab) {
    if (!_builtTabs.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      HomeTab.diary => TimelineScreen(
          database: widget.database,
          mediaService: widget.mediaService,
          ocrQueueManager: widget.ocrQueueManager,
          primaryAction: _primaryActions[HomeTab.diary],
          diaryChanged: _diaryChanged,
        ),
      HomeTab.albums => AlbumCollectionsScreen(
          database: widget.database,
          mediaService: widget.mediaService,
          primaryAction: _primaryActions[HomeTab.albums],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final shell = PopScope(
      canPop: _selectedTab == HomeTab.diary && !_isPanelOpen,
      onPopInvokedWithResult: _handlePopBlocked,
      child: Scaffold(
        extendBody: true,
        body: NotificationListener<Notification>(
          onNotification: _railVisibility.handleScrollNotification,
          child: IndexedStack(
            index: _selectedTab.index,
            children: [for (final tab in HomeTab.values) _buildTab(tab)],
          ),
        ),
        bottomNavigationBar: TabRailScrollHider(
          visibility: _railVisibility,
          child: TabRail(
            key: const Key('home_tab_rail'),
            selectedTab: _selectedTab,
            onTabSelected: _selectTab,
            onCentrePressed: () => _primaryActions[_selectedTab]!.run(),
          ),
        ),
      ),
    );
    return DiaristPanelScope(
      controller: _panel,
      child: DiaristPanelOverlay(
        controller: _panel,
        panel: DiaristPanel(
          sections: [
            DiaristStatsStrip(
              stats: _stats,
              onDiaryTap: () => _showTabFromPanel(HomeTab.diary),
              onAlbumsTap: () => _showTabFromPanel(HomeTab.albums),
            ),
            DiaristPanelRow(
              key: const Key('diarist_panel_analytics_row'),
              icon: Icons.insights_rounded,
              label: '写作统计',
              onTap: () => _openFromPanel(
                (_) => AnalyticsDashboardScreen(database: widget.database),
              ),
            ),
            DiaristPanelRow(
              key: const Key('diarist_panel_recycle_bin_row'),
              icon: Icons.delete_outline_rounded,
              label: '回收站',
              onTap: () => _openFromPanel(
                (_) => RecycleBinScreen(database: widget.database, mediaService: widget.mediaService),
                changesDiary: true,
              ),
            ),
            DiaristPanelRow(
              key: const Key('diarist_panel_import_backup_row'),
              icon: Icons.inventory_2_outlined,
              label: '导入与备份',
              onTap: () => _openFromPanel(
                (_) => ImportBackupScreen(database: widget.database, mediaService: widget.mediaService),
                changesDiary: true,
              ),
            ),
          ],
          onReturnToCover: _returnToCover,
        ),
        child: DiaristPanelEdgeBand(controller: _panel, child: shell),
      ),
    );
  }
}
