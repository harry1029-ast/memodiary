import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/begonia_plaque_button.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'chronicle_brass_grommet.dart';
import 'date_index_tray.dart';

/// Pinned `SliverPersistentHeaderDelegate` rendering the `Chronicle Desk` (`案头卷匣`)
/// title bar (`案头卷宗 · 共 N 卷`), top-right Begonia plaque slot,
/// 3-row `Date Index Tray`, top-scoped candlelight glow, and bottom `ChronicleBrassGrommet`.
class ChronicleDeskHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TimelineFilterState filters;
  final TimelineDateFacetSummary facetSummary;
  final int totalFilteredCount;
  final double xunExpandFactor;
  final double textScaleFactor;
  final bool hasEntriesBelow;
  final bool isDarkTheme;
  final String paletteId;
  final bool isCandleLit;
  final VoidCallback onOpenCharmFilter;
  final ValueChanged<int?> onSelectYear;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<TimelineXun> onSelectXun;
  final VoidCallback onToggleSort;

  const ChronicleDeskHeaderDelegate({
    required this.filters,
    required this.facetSummary,
    required this.totalFilteredCount,
    required this.xunExpandFactor,
    required this.textScaleFactor,
    required this.hasEntriesBelow,
    required this.isDarkTheme,
    this.paletteId = '',
    required this.isCandleLit,
    required this.onOpenCharmFilter,
    required this.onSelectYear,
    required this.onSelectMonth,
    required this.onSelectXun,
    required this.onToggleSort,
  });

  double get _clampedExtraScale => (textScaleFactor - 1.0).clamp(0.0, 0.3);

  double get _baseHeight => 176.0 + _clampedExtraScale * 6.0;
  double get _xunAdditionalHeight =>
      (47.0 + _clampedExtraScale * 4.0) * xunExpandFactor.clamp(0.0, 1.0);

  @override
  double get minExtent => _baseHeight + _xunAdditionalHeight;

  @override
  double get maxExtent => _baseHeight + _xunAdditionalHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Delegate themed content to a StatelessWidget so AnimatedTheme frames
    // (0 -> 1) rebuild via Element.didChangeDependencies even after discrete
    // brightness/paletteId switches flip mid-transition and shouldRebuild stops.
    return _ChronicleDeskHeaderBody(
      maxExtent: maxExtent,
      overlapsContent: overlapsContent,
      filters: filters,
      facetSummary: facetSummary,
      totalFilteredCount: totalFilteredCount,
      xunExpandFactor: xunExpandFactor,
      hasEntriesBelow: hasEntriesBelow,
      isCandleLit: isCandleLit,
      onOpenCharmFilter: onOpenCharmFilter,
      onSelectYear: onSelectYear,
      onSelectMonth: onSelectMonth,
      onSelectXun: onSelectXun,
      onToggleSort: onToggleSort,
    );
  }

  @override
  bool shouldRebuild(covariant ChronicleDeskHeaderDelegate oldDelegate) {
    return filters != oldDelegate.filters ||
        facetSummary.totalActiveEntries !=
            oldDelegate.facetSummary.totalActiveEntries ||
        facetSummary.years.length != oldDelegate.facetSummary.years.length ||
        facetSummary.activeMonths.length !=
            oldDelegate.facetSummary.activeMonths.length ||
        !facetSummary.activeMonths
            .containsAll(oldDelegate.facetSummary.activeMonths) ||
        totalFilteredCount != oldDelegate.totalFilteredCount ||
        xunExpandFactor != oldDelegate.xunExpandFactor ||
        textScaleFactor != oldDelegate.textScaleFactor ||
        hasEntriesBelow != oldDelegate.hasEntriesBelow ||
        isDarkTheme != oldDelegate.isDarkTheme ||
        paletteId != oldDelegate.paletteId ||
        isCandleLit != oldDelegate.isCandleLit;
  }
}

class _ChronicleDeskHeaderBody extends StatelessWidget {
  final double maxExtent;
  final bool overlapsContent;
  final TimelineFilterState filters;
  final TimelineDateFacetSummary facetSummary;
  final int totalFilteredCount;
  final double xunExpandFactor;
  final bool hasEntriesBelow;
  final bool isCandleLit;
  final VoidCallback onOpenCharmFilter;
  final ValueChanged<int?> onSelectYear;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<TimelineXun> onSelectXun;
  final VoidCallback onToggleSort;

  const _ChronicleDeskHeaderBody({
    required this.maxExtent,
    required this.overlapsContent,
    required this.filters,
    required this.facetSummary,
    required this.totalFilteredCount,
    required this.xunExpandFactor,
    required this.hasEntriesBelow,
    required this.isCandleLit,
    required this.onOpenCharmFilter,
    required this.onSelectYear,
    required this.onSelectMonth,
    required this.onSelectXun,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final tokens = context.inkTokens;
    final hasActiveCharms = filters.hasActiveCharmFilters;
    final charmSummary = filters.charmSummaryLabel();
    final isNarrowViewport = MediaQuery.sizeOf(context).width <= 340;

    return SizedBox(
      height: maxExtent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.deskSurroundTop, palette.deskSurroundBottom],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Container(
          decoration: BoxDecoration(
            color: palette.deskMat,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(
              top: BorderSide(color: palette.deckleBorder, width: 1.0),
              left: BorderSide(color: palette.deckleBorder, width: 1.0),
              right: BorderSide(color: palette.deckleBorder, width: 1.0),
              bottom: BorderSide.none,
            ),
            boxShadow: overlapsContent
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Desk Header Bar: Left Title + Live Count | Right Begonia Plaque
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _ChronicleDeskTapToTopTitle(
                                      totalFilteredCount: totalFilteredCount,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isNarrowViewport ? 136 : 180,
                                  ),
                                  child: BegoniaPlaqueButton(
                                    key: const Key('timeline_charm_filter_button'),
                                    label: charmSummary,
                                    semanticLabel: hasActiveCharms
                                        ? '筛选，当前已选：$charmSummary'
                                        : '筛选',
                                    isAccent: hasActiveCharms,
                                    ensureMinTapTarget: true,
                                    leading: Icon(
                                      hasActiveCharms
                                          ? Icons.local_offer_rounded
                                          : Icons.local_offer_outlined,
                                      size: 13,
                                      color: hasActiveCharms
                                          ? palette.tallyFeaturedText
                                          : tokens.cinnabar,
                                    ),
                                    trailing: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 15,
                                      color: hasActiveCharms
                                          ? palette.tallyFeaturedText
                                          : tokens.danmo,
                                    ),
                                    onTap: onOpenCharmFilter,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DateIndexTray(
                              filters: filters,
                              facetSummary: facetSummary,
                              xunExpandFactor: xunExpandFactor,
                              onSelectYear: onSelectYear,
                              onSelectMonth: onSelectMonth,
                              onSelectXun: onSelectXun,
                              onToggleSort: onToggleSort,
                            ),
                          ],
                        ),
                      ),
                      // Positioned flush inside deskMat (no horizontal padding) so
                      // its X-axis aligns identically with TimelineDateSpineItem.
                      Expanded(
                        child: ChronicleBrassGrommet(
                          hasEntriesBelow: hasEntriesBelow,
                        ),
                      ),
                    ],
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
                                    center: const Alignment(0.72, -0.95),
                                    radius: 0.95,
                                    colors: [
                                      palette.candleGlow,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  if (overlapsContent)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 1.0,
                      child: IgnorePointer(
                        child: ColoredBox(color: palette.deckleBorder),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive left title + entry-count region (`日记 · 共 N 篇`) of the pinned
/// Chronicle Desk header that briskly scrolls back to offset `0` on tap when
/// scrolled down.
class _ChronicleDeskTapToTopTitle extends StatefulWidget {
  final int totalFilteredCount;

  const _ChronicleDeskTapToTopTitle({
    required this.totalFilteredCount,
  });

  @override
  State<_ChronicleDeskTapToTopTitle> createState() =>
      _ChronicleDeskTapToTopTitleState();
}

class _ChronicleDeskTapToTopTitleState
    extends State<_ChronicleDeskTapToTopTitle> {
  static const double _preJumpThreshold = 1600.0;

  ScrollPosition? _scrollPosition;
  bool _isScrolledDown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    final nextPosition = scrollable != null &&
            axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical
        ? scrollable.position
        : null;
    if (nextPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_handleScrollChanged);
      _scrollPosition = nextPosition;
      _scrollPosition?.addListener(_handleScrollChanged);
    }
    _isScrolledDown = _computeIsScrolledDown();
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_handleScrollChanged);
    super.dispose();
  }

  bool _computeIsScrolledDown() {
    final position = _scrollPosition;
    return position != null && position.hasPixels && position.pixels > 0.0;
  }

  void _handleScrollChanged() {
    if (!mounted) return;
    final nextIsScrolledDown = _computeIsScrolledDown();
    if (nextIsScrolledDown != _isScrolledDown) {
      setState(() => _isScrolledDown = nextIsScrolledDown);
    }
  }

  void _handleTap() {
    final position = _scrollPosition;
    if (position == null || !position.hasPixels || position.pixels <= 0.0) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      position.jumpTo(0.0);
      return;
    }
    if (position.pixels > _preJumpThreshold) {
      position.jumpTo(_preJumpThreshold);
    }
    final durationMs =
        (position.pixels / _preJumpThreshold * 140 + 220).round().clamp(220, 360);
    position.animateTo(
      0.0,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    final Widget tapArea = Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('timeline_tap_to_top_button'),
        borderRadius: BorderRadius.circular(8),
        onTap: _isScrolledDown ? _handleTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 44.0,
            minHeight: 44.0,
          ),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: palette.accentPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '日记',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  key: const Key('timeline_entry_count_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.agedFiberChip,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.deckleBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    '共 ${widget.totalFilteredCount} 篇',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.accentSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_isScrolledDown) {
      return Semantics(
        button: true,
        enabled: true,
        label: '点击返回顶部',
        excludeSemantics: true,
        child: tapArea,
      );
    }
    return tapArea;
  }
}
