import 'package:flutter/material.dart';
import 'package:memodiary/core/calendar/lunar_calendar.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'date_index_chips.dart';

/// Three-row chronological index and sorter tray (`案头岁时检目`):
/// - Row 1 (`纪年` + Sort): `[全部]`, active years with lunar stem-branch, and `最新 ↓` / `最早 ↑`
/// - Row 2 (`月令`): scrollable `1月`–`12月` chips with cinnabar presence dots (`•`)
/// - Row 3 (`三旬`): progressively disclosed `上旬` / `中旬` / `下旬` segments
class DateIndexTray extends StatefulWidget {
  final TimelineFilterState filters;
  final TimelineDateFacetSummary facetSummary;
  final double xunExpandFactor;
  final bool useLunarDates;
  final ValueChanged<int?> onSelectYear;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<TimelineXun> onSelectXun;
  final VoidCallback onToggleSort;

  const DateIndexTray({
    super.key,
    required this.filters,
    required this.facetSummary,
    required this.xunExpandFactor,
    this.useLunarDates = false,
    required this.onSelectYear,
    required this.onSelectMonth,
    required this.onSelectXun,
    required this.onToggleSort,
  });

  static const List<({TimelineXun xun, String label, String rangeLabel})>
      gregorianXunConfigs = [
    (xun: TimelineXun.shang, label: '上旬', rangeLabel: '1–10日'),
    (xun: TimelineXun.zhong, label: '中旬', rangeLabel: '11–20日'),
    (xun: TimelineXun.xia, label: '下旬', rangeLabel: '21日–月底'),
  ];

  static const List<({TimelineXun xun, String label, String rangeLabel})>
      lunarXunConfigs = [
    (xun: TimelineXun.shang, label: '上旬', rangeLabel: '初一–初十'),
    (xun: TimelineXun.zhong, label: '中旬', rangeLabel: '十一–二十'),
    (xun: TimelineXun.xia, label: '下旬', rangeLabel: '廿一–晦日'),
  ];

  @override
  State<DateIndexTray> createState() => _DateIndexTrayState();
}

class _DateIndexTrayState extends State<DateIndexTray> {
  final ScrollController _monthScrollController = ScrollController();
  final Map<int, GlobalKey> _monthChipKeys = {
    for (int month = 1; month <= 12; month++) month: GlobalKey(),
  };

  @override
  void didUpdateWidget(DateIndexTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedMonth = widget.filters.month;
    if (selectedMonth != null && selectedMonth != oldWidget.filters.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollMonthIntoView(selectedMonth);
      });
    }
  }

  void _scrollMonthIntoView(int month) {
    if (!mounted) return;
    final chipContext = _monthChipKeys[month]?.currentContext;
    if (chipContext == null) return;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Scrollable.ensureVisible(
      chipContext,
      alignment: 0.5,
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final isNewestFirst =
        widget.filters.sortOrder == TimelineSortOrder.newestFirst;
    final dividerColor = palette.accentSecondary.withValues(alpha: 0.16);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        key: const Key('timeline_date_index_tray'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: palette.deskTray,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: palette.deckleBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: 纪年 (Year chips) + Sort Toggle
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TrayFilterChip(
                          key: const Key('timeline_year_chip_all'),
                          label: '全部',
                          semanticLabel: '全部年份',
                          isActive: widget.filters.year == null,
                          palette: palette,
                          onTap: () => widget.onSelectYear(null),
                        ),
                        for (final year in widget.facetSummary.years) ...[
                          const SizedBox(width: 5),
                          TrayFilterChip(
                            key: Key('timeline_year_chip_$year'),
                            label:
                                '$year ${LunarCalendar.fromSolar(DateTime(year, 6, 15)).stemBranchYear}',
                            semanticLabel: '$year年',
                            isActive: widget.filters.year == year,
                            palette: palette,
                            onTap: () => widget.onSelectYear(year),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TraySortToggleButton(
                  key: const Key('timeline_sort_toggle_button'),
                  isNewestFirst: isNewestFirst,
                  palette: palette,
                  onTap: widget.onToggleSort,
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Container(height: 1.0, color: dividerColor),
            ),

            // Row 2: 月令 (Scrollable 1月–12月 with cinnabar presence dots)
            SingleChildScrollView(
              controller: _monthScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int month = 1; month <= 12; month++) ...[
                    if (month > 1) const SizedBox(width: 4),
                    MonthIndexChip(
                      key: Key('timeline_month_chip_$month'),
                      containerKey: _monthChipKeys[month],
                      month: month,
                      isActive: widget.filters.month == month,
                      hasEntries:
                          widget.facetSummary.activeMonths.contains(month),
                      palette: palette,
                      onTap: () => widget.onSelectMonth(month),
                    ),
                  ],
                ],
              ),
            ),

            // Row 3: 三旬 (Progressive disclosure when a month is selected)
            if (widget.xunExpandFactor > 0.0)
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: widget.xunExpandFactor.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: widget.xunExpandFactor.clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: widget.xunExpandFactor < 0.05,
                      child: ExcludeSemantics(
                        excluding: widget.xunExpandFactor < 0.05,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Container(height: 1.0, color: dividerColor),
                            ),
                            Row(
                              children: [
                                for (final (idx, config) in (widget.useLunarDates
                                        ? DateIndexTray.lunarXunConfigs
                                        : DateIndexTray.gregorianXunConfigs)
                                    .indexed) ...[
                                  if (idx > 0) const SizedBox(width: 6),
                                  Expanded(
                                    child: XunSegmentChip(
                                      key: Key(
                                        'timeline_xun_chip_${config.xun.name}',
                                      ),
                                      label: config.label,
                                      rangeLabel: config.rangeLabel,
                                      isActive: widget.filters.xun == config.xun,
                                      palette: palette,
                                      onTap: () => widget.onSelectXun(config.xun),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
