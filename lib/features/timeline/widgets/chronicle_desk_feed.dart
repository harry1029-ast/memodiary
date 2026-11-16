import 'package:flutter/material.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/screens/contemplation_view_screen.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_card.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_header.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_desk_palette.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';
import 'package:memodiary/features/timeline/widgets/filtered_chronicle_empty_card.dart';
import 'package:memodiary/features/timeline/widgets/time_capsule_card.dart';
import 'package:memodiary/features/timeline/widgets/timeline_date_spine_item.dart';
import 'package:memodiary/features/timeline/widgets/timeline_empty_states.dart';
import 'package:memodiary/features/timeline/widgets/window_sill_ledge.dart';

/// Composite scrollable body for [TimelineScreen], combining the upper
/// window + sill, pinned `Chronicle Desk` header, entry feed, and candlelight glow.
class ChronicleDeskScrollBody extends StatelessWidget {
  final ScrollController scrollController;
  final Animation<double> xunExpandAnimation;
  final ShanshuiAtmosphereState activeAtmosphere;
  final ShanshuiAtmosphereState realTimeAtmosphere;
  final ScenerySettingsService scenerySettings;
  final AudioSanctumService? audioSanctumService;
  final bool? enableAmbientAnimation;
  final bool isSceneryVisible;
  final bool isCandleLit;
  final TimelineFilterState filters;
  final TimelineDateFacetSummary facetSummary;
  final int totalFilteredCount;
  final List<Entry> entries;
  final Map<String, MediaAttachment> mediaMap;
  final MediaSandboxService mediaService;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final ValueChanged<SceneryRealmPreference> onRealmPreferenceChanged;
  final VoidCallback onToggleCandle;
  final VoidCallback onOpenCharmFilter;
  final ValueChanged<int?> onSelectYear;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<TimelineXun> onSelectXun;
  final VoidCallback onToggleSort;
  final VoidCallback onCreateEntry;
  final VoidCallback onClearFilters;
  final ValueChanged<Entry> onEntryTap;

  const ChronicleDeskScrollBody({
    super.key,
    required this.scrollController,
    required this.xunExpandAnimation,
    required this.activeAtmosphere,
    required this.realTimeAtmosphere,
    required this.scenerySettings,
    required this.audioSanctumService,
    required this.enableAmbientAnimation,
    required this.isSceneryVisible,
    required this.isCandleLit,
    required this.filters,
    required this.facetSummary,
    required this.totalFilteredCount,
    required this.entries,
    required this.mediaMap,
    required this.mediaService,
    required this.hasMore,
    required this.onRefresh,
    required this.onRealmPreferenceChanged,
    required this.onToggleCandle,
    required this.onOpenCharmFilter,
    required this.onSelectYear,
    required this.onSelectMonth,
    required this.onSelectXun,
    required this.onToggleSort,
    required this.onCreateEntry,
    required this.onClearFilters,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final palette = ChronicleDeskPalette.of(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textScale =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);

    return Stack(
      children: [
        RefreshIndicator(
          color: tokens.cinnabar,
          onRefresh: onRefresh,
          child: AnimatedBuilder(
            animation: xunExpandAnimation,
            builder: (context, _) {
              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => UpperWindowAndSill(
                        scrollController: scrollController,
                        activeAtmosphere: activeAtmosphere,
                        realTimeAtmosphere: realTimeAtmosphere,
                        scenerySettings: scenerySettings,
                        audioSanctumService: audioSanctumService,
                        enableAmbientAnimation: enableAmbientAnimation,
                        isVisible: isSceneryVisible,
                        isCandleLit: isCandleLit,
                        onRealmPreferenceChanged: onRealmPreferenceChanged,
                        onToggleCandle: onToggleCandle,
                      ),
                      childCount: 1,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: ChronicleDeskHeaderDelegate(
                      filters: filters,
                      facetSummary: facetSummary,
                      totalFilteredCount: totalFilteredCount,
                      xunExpandFactor: xunExpandAnimation.value,
                      textScaleFactor: textScale,
                      hasEntriesBelow: entries.isNotEmpty,
                      isDarkTheme: isDarkTheme,
                      onOpenCharmFilter: onOpenCharmFilter,
                      onSelectYear: onSelectYear,
                      onSelectMonth: onSelectMonth,
                      onSelectXun: onSelectXun,
                      onToggleSort: onToggleSort,
                    ),
                  ),
                  ChronicleDeskFeedSliver(
                    entries: entries,
                    mediaMap: mediaMap,
                    mediaService: mediaService,
                    totalActiveInDb: facetSummary.totalActiveEntries,
                    hasMore: hasMore,
                    onCreateEntry: onCreateEntry,
                    onClearFilters: onClearFilters,
                    onEntryTap: onEntryTap,
                  ),
                ],
              );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: isCandleLit
                  ? Container(
                      key: const Key('timeline_candle_glow_overlay'),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.65, -0.35),
                          radius: 0.95,
                          colors: [palette.candleGlow, Colors.transparent],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Upper Jiangnan living window (`Shanshui Scenery Card`) merged with the
/// carved `Window Sill Ledge`, fading smoothly on downward scroll.
class UpperWindowAndSill extends StatelessWidget {
  final ScrollController scrollController;
  final ShanshuiAtmosphereState activeAtmosphere;
  final ShanshuiAtmosphereState realTimeAtmosphere;
  final ScenerySettingsService scenerySettings;
  final AudioSanctumService? audioSanctumService;
  final bool? enableAmbientAnimation;
  final bool isVisible;
  final bool isCandleLit;
  final ValueChanged<SceneryRealmPreference> onRealmPreferenceChanged;
  final VoidCallback onToggleCandle;

  const UpperWindowAndSill({
    super.key,
    required this.scrollController,
    required this.activeAtmosphere,
    required this.realTimeAtmosphere,
    required this.scenerySettings,
    required this.audioSanctumService,
    required this.enableAmbientAnimation,
    required this.isVisible,
    required this.isCandleLit,
    required this.onRealmPreferenceChanged,
    required this.onToggleCandle,
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
            atmosphere: activeAtmosphere,
            realTimeAtmosphere: realTimeAtmosphere,
            onRealmPreferenceChanged: onRealmPreferenceChanged,
            onOpenContemplation: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContemplationViewScreen(
                    initialAtmosphere: activeAtmosphere,
                    realTimeAtmosphere: realTimeAtmosphere,
                    audioService:
                        audioSanctumService ?? AudioSanctumService(),
                    enableAmbientAnimation: enableAmbientAnimation,
                  ),
                ),
              );
            },
            settingsService: scenerySettings,
            enableAmbientAnimation: enableAmbientAnimation,
            isVisible: isVisible,
          ),
          WindowSillLedge(
            isCandleLit: isCandleLit,
            onToggleCandle: onToggleCandle,
            enableAmbientAnimation: enableAmbientAnimation,
            isVisible: isVisible,
          ),
        ],
      ),
    );
  }
}

/// Sliver feed rendering diary slips, empty states, and bottom desk-mat cap
/// inside the walnut/ebony `Chronicle Desk` surround.
class ChronicleDeskFeedSliver extends StatelessWidget {
  final List<Entry> entries;
  final Map<String, MediaAttachment> mediaMap;
  final MediaSandboxService mediaService;
  final int totalActiveInDb;
  final bool hasMore;
  final VoidCallback onCreateEntry;
  final VoidCallback onClearFilters;
  final ValueChanged<Entry> onEntryTap;

  const ChronicleDeskFeedSliver({
    super.key,
    required this.entries,
    required this.mediaMap,
    required this.mediaService,
    required this.totalActiveInDb,
    required this.hasMore,
    required this.onCreateEntry,
    required this.onClearFilters,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChronicleDeskPalette.of(context);
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

          final entry = entries[index];
          final item = TimelineEntryItem(
            entry: entry,
            primaryMedia: mediaMap[entry.id],
          );
          final isFirst = index == 0;
          final isLast = index == entries.length - 1 && !hasMore;
          final isHighlighted = isFirst || entry.isWeeklyReview;

          final Widget card = item.isSealedTimeCapsule
              ? TimeCapsuleCard(item: item, customMargin: EdgeInsets.zero)
              : EntrySummaryCard(
                  item: item,
                  mediaService: mediaService,
                  onTap: () => onEntryTap(entry),
                  customMargin: EdgeInsets.zero,
                );

          return _wrapInDeskMat(
            palette: palette,
            child: TimelineDateSpineItem(
              date: entry.entryDate,
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
    required ChronicleDeskPalette palette,
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
