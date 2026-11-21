import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/features/albums/screens/album_collections_screen.dart';
import 'package:memodiary/features/home/models/home_tab.dart';
import 'package:memodiary/features/home/widgets/tab_rail.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';

/// The root screen once the cover is passed: the 日记 and 相册 tabs held in an
/// indexed stack (both keep their state; 相册 is built on first selection),
/// switched by tapping the [TabRail].
///
/// Every screen opened from a tab is pushed on the single root Navigator, so it
/// covers the shell and its rail. Android Back walks 相册 → 日记 → exit.
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

class _HomeShellState extends State<HomeShell> {
  final Map<HomeTab, HomeTabPrimaryAction> _primaryActions = {
    for (final tab in HomeTab.values) tab: HomeTabPrimaryAction(),
  };
  final Set<HomeTab> _builtTabs = {};
  late HomeTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _builtTabs.add(_selectedTab);
  }

  void _selectTab(HomeTab tab) {
    if (tab == _selectedTab) return;
    setState(() {
      _selectedTab = tab;
      _builtTabs.add(tab);
    });
  }

  void _handlePopBlocked(bool didPop, Object? _) {
    if (didPop) return;
    if (_selectedTab != HomeTab.diary) _selectTab(HomeTab.diary);
  }

  Widget _buildTab(HomeTab tab) {
    if (!_builtTabs.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      HomeTab.diary => TimelineScreen(
          database: widget.database,
          mediaService: widget.mediaService,
          ocrQueueManager: widget.ocrQueueManager,
          primaryAction: _primaryActions[HomeTab.diary],
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
    return PopScope(
      canPop: _selectedTab == HomeTab.diary,
      onPopInvokedWithResult: _handlePopBlocked,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedTab.index,
          children: [for (final tab in HomeTab.values) _buildTab(tab)],
        ),
        bottomNavigationBar: TabRail(
          key: const Key('home_tab_rail'),
          selectedTab: _selectedTab,
          onTabSelected: _selectTab,
          onCentrePressed: () => _primaryActions[_selectedTab]!.run(),
        ),
      ),
    );
  }
}
