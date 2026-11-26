import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/screens/contemplation_view_screen.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_card.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_header.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';
import 'package:memodiary/features/timeline/widgets/filtered_chronicle_empty_card.dart';
import 'package:memodiary/features/timeline/widgets/time_capsule_card.dart';
import 'package:memodiary/features/timeline/widgets/timeline_date_spine_item.dart';
import 'package:memodiary/features/timeline/widgets/timeline_empty_states.dart';
import 'package:memodiary/features/timeline/widgets/window_sill_ledge.dart';

/// Configuration for the upper Jiangnan window (`Shanshui Scenery Card`) and
/// merged `Window Sill Ledge`.
@immutable
class TimelineSceneryHeaderConfig {
  final ShanshuiAtmosphereState activeAtmosphere;
  final ShanshuiAtmosphereState realTimeAtmosphere;
  final ScenerySettingsService scenerySettings;
  final AudioSanctumService? audioSanctumService;
  final bool? enableAmbientAnimation;
  final bool isVisible;
  final bool isCandleLit;
  final ValueChanged<SceneryRealmPreference> onRealmPreferenceChanged;
  final VoidCallback onToggleCandle;

  const TimelineSceneryHeaderConfig({
    required this.activeAtmosphere,
    required this.realTimeAtmosphere,
    required this.scenerySettings,
    this.audioSanctumService,
    this.enableAmbientAnimation,
    required this.isVisible,
    required this.isCandleLit,
    required this.onRealmPreferenceChanged,
    required this.onToggleCandle,
  });
}

/// Filter and count state powering the pinned `Chronicle Desk` header.
@immutable
class ChronicleDeskFilterData {
  final TimelineFilterState filters;
  final TimelineDateFacetSummary facetSummary;
  final int totalFilteredCount;
  final Animation<double> xunExpandAnimation;

  const ChronicleDeskFilterData({
    required this.filters,
    required this.facetSummary,
    required this.totalFilteredCount,
    required this.xunExpandAnimation,
  });
}

/// Paginated entry and media payload rendered in `ChronicleDeskFeedSliver`.
@immutable
class ChronicleDeskFeedData {
  final List<TimelineEntrySummary> entries;
  final Map<String, MediaAttachment> mediaMap;
  final MediaSandboxService mediaService;
  final bool hasMore;

  const ChronicleDeskFeedData({
    required this.entries,
    required this.mediaMap,
    required this.mediaService,
    required this.hasMore,
  });
}

/// Interaction callbacks dispatched from the `Chronicle Desk` header and feed.
@immutable
class ChronicleDeskFeedCallbacks {
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenCharmFilter;
  final ValueChanged<int?> onSelectYear;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<TimelineXun> onSelectXun;
  final VoidCallback onToggleSort;
  final VoidCallback onCreateEntry;
  final VoidCallback onClearFilters;
  final ValueChanged<TimelineEntrySummary> onEntryTap;

  const ChronicleDeskFeedCallbacks({
    required this.onRefresh,
    required this.onOpenCharmFilter,
    required this.onSelectYear,
    required this.onSelectMonth,
    required this.onSelectXun,
    required this.onToggleSort,
    required this.onCreateEntry,
    required this.onClearFilters,
    required this.onEntryTap,
  });
}

/// Composite scrollable body for [TimelineScreen], combining the upper
/// window + sill, pinned `Chronicle Desk` header, and entry feed.
class ChronicleDeskScrollBody extends StatelessWidget {
  final ScrollController scrollController;
  final TimelineSceneryHeaderConfig sceneryConfig;
  final ChronicleDeskFilterData filterData;
  final ChronicleDeskFeedData feedData;
  final ChronicleDeskFeedCallbacks callbacks;

  const ChronicleDeskScrollBody({
    super.key,
    required this.scrollController,
    required this.sceneryConfig,
    required this.filterData,
    required this.feedData,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textScale =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);

    return RefreshIndicator(
      color: tokens.cinnabar,
      onRefresh: callbacks.onRefresh,
      child: AnimatedBuilder(
        animation: filterData.xunExpandAnimation,
        builder: (context, _) {
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => UpperWindowAndSill(
                    scrollController: scrollController,
                    sceneryConfig: sceneryConfig,
                  ),
                  childCount: 1,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: ChronicleDeskHeaderDelegate(
                  filters: filterData.filters,
                  facetSummary: filterData.facetSummary,
                  totalFilteredCount: filterData.totalFilteredCount,
                  xunExpandFactor: filterData.xunExpandAnimation.value,
                  textScaleFactor: textScale,
                  hasEntriesBelow: feedData.entries.isNotEmpty,
                  isDarkTheme: isDarkTheme,
                  paletteId: context.atmospherePalette.id,
                  isCandleLit: sceneryConfig.isCandleLit,
                  onOpenCharmFilter: callbacks.onOpenCharmFilter,
                  onSelectYear: callbacks.onSelectYear,
                  onSelectMonth: callbacks.onSelectMonth,
                  onSelectXun: callbacks.onSelectXun,
                  onToggleSort: callbacks.onToggleSort,
                ),
              ),
              ChronicleDeskFeedSliver(
                feedData: feedData,
                totalActiveInDb: filterData.facetSummary.totalActiveEntries,
                onCreateEntry: callbacks.onCreateEntry,
                onClearFilters: callbacks.onClearFilters,
                onEntryTap: callbacks.onEntryTap,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Upper Jiangnan living window (`Shanshui Scenery Card`) merged with the
/// carved `Window Sill Ledge`, fading smoothly on downward scroll.
class UpperWindowAndSill extends StatelessWidget {
  final ScrollController scrollController;
  final TimelineSceneryHeaderConfig sceneryConfig;

  const UpperWindowAndSill({
    super.key,
    required this.scrollController,
    required this.sceneryConfig,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset =
            scrollController.hasClients ? scrollController.offset : 0.0;
        final opacity = (1.0 - (offset / 220.0) * 0.65).clamp(0.35, 1.0);
        return Opacity(opacity: opacity, child: child);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShanshuiSceneryCard(
            atmosphere: sceneryConfig.activeAtmosphere,
            realTimeAtmosphere: sceneryConfig.realTimeAtmosphere,
            onRealmPreferenceChanged: sceneryConfig.onRealmPreferenceChanged,
            onOpenContemplation: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContemplationViewScreen(
                    initialAtmosphere: sceneryConfig.activeAtmosphere,
                    realTimeAtmosphere: sceneryConfig.realTimeAtmosphere,
                    audioService:
                        sceneryConfig.audioSanctumService ?? AudioSanctumService(),
                    enableAmbientAnimation: sceneryConfig.enableAmbientAnimation,
                  ),
                ),
              );
            },
            settingsService: sceneryConfig.scenerySettings,
            enableAmbientAnimation: sceneryConfig.enableAmbientAnimation,
            isVisible: sceneryConfig.isVisible,
          ),
          WindowSillLedge(
            isCandleLit: sceneryConfig.isCandleLit,
            onToggleCandle: sceneryConfig.onToggleCandle,
            enableAmbientAnimation: sceneryConfig.enableAmbientAnimation,
            isVisible: sceneryConfig.isVisible,
          ),
        ],
      ),
    );
  }
}

/// Sliver feed rendering diary slips, empty states, and bottom desk-mat cap
/// inside the walnut/ebony `Chronicle Desk` surround.
class ChronicleDeskFeedSliver extends StatelessWidget {
  final ChronicleDeskFeedData feedData;
  final int totalActiveInDb;
  final VoidCallback onCreateEntry;
  final VoidCallback onClearFilters;
  final ValueChanged<TimelineEntrySummary> onEntryTap;

  const ChronicleDeskFeedSliver({
    super.key,
    required this.feedData,
    required this.totalActiveInDb,
    required this.onCreateEntry,
    required this.onClearFilters,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final entries = feedData.entries;
    final hasMore = feedData.hasMore;
    final isEmpty = entries.isEmpty;
    final itemCount = isEmpty ? 2 : entries.length + (hasMore ? 2 : 1);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == itemCount - 1) {
            return _wrapInDeskMat(
              palette: palette,
              isBottomCap: true,
              child: const SizedBox(height: 84),
            );
          }

          if (isEmpty) {
            final Widget emptyChild = totalActiveInDb == 0
                ? TimelineOnboardingEmptyState(onCreateEntry: onCreateEntry)
                : FilteredChronicleEmptyCard(
                    totalActiveInDb: totalActiveInDb,
                    onClearFilters: onClearFilters,
                  );
            return _wrapInDeskMat(palette: palette, child: emptyChild);
          }

          if (index == entries.length) {
            return _wrapInDeskMat(
              palette: palette,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            );
          }

          final summary = entries[index];
          final item = TimelineEntryItem(
            summary: summary,
            primaryMedia: feedData.mediaMap[summary.id],
          );
          final isFirst = index == 0;
          final isLast = index == entries.length - 1 && !hasMore;
          final isHighlighted = isFirst || summary.isWeeklyReview;

          final Widget card = item.isSealedTimeCapsule
              ? TimeCapsuleCard(item: item, customMargin: EdgeInsets.zero)
              : EntrySummaryCard(
                  item: item,
                  mediaService: feedData.mediaService,
                  onTap: () => onEntryTap(summary),
                  customMargin: EdgeInsets.zero,
                );

          return _wrapInDeskMat(
            palette: palette,
            child: TimelineDateSpineItem(
              date: summary.entryDate,
              isFirst: isFirst,
              isLast: isLast,
              isHighlighted: isHighlighted,
              connectFromTop: isFirst,
              child: card,
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }

  Widget _wrapInDeskMat({
    required AtmospherePalette palette,
    required Widget child,
    bool isBottomCap = false,
  }) {
    return Container(
      color: palette.deskSurroundBottom,
      padding: EdgeInsets.fromLTRB(8, 0, 8, isBottomCap ? 10 : 0),
      child: Container(
        decoration: BoxDecoration(
          color: palette.deskMat,
          borderRadius: isBottomCap
              ? const BorderRadius.vertical(bottom: Radius.circular(14))
              : null,
          border: Border(
            left: BorderSide(color: palette.deckleBorder, width: 1.0),
            right: BorderSide(color: palette.deckleBorder, width: 1.0),
            bottom: isBottomCap
                ? BorderSide(color: palette.deckleBorder, width: 1.0)
                : BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }
}
