import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/min_tap_target.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead_models.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'chronicle_desk_palette.dart';

/// Modal bottom sheet for filtering the `Chronicle Desk` timeline by
/// Mood (`心绪`), Weather (`天时`), With Media (`含图影`), and Weekly Review (`周志复盘`).
class ChronicleCharmFilterSheet extends StatefulWidget {
  final TimelineFilterState initialFilters;
  final ValueChanged<TimelineFilterState> onFiltersChanged;

  const ChronicleCharmFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  /// Presents the Charm & Tag Filter sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required TimelineFilterState initialFilters,
    required ValueChanged<TimelineFilterState> onFiltersChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChronicleCharmFilterSheet(
        initialFilters: initialFilters,
        onFiltersChanged: onFiltersChanged,
      ),
    );
  }

  @override
  State<ChronicleCharmFilterSheet> createState() =>
      _ChronicleCharmFilterSheetState();
}

class _ChronicleCharmFilterSheetState extends State<ChronicleCharmFilterSheet> {
  late TimelineFilterState _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _applyUpdate(TimelineFilterState nextFilters) {
    setState(() => _filters = nextFilters);
    widget.onFiltersChanged(nextFilters);
  }

  void _toggleMood(int value) {
    _applyUpdate(
      _filters.mood == value
          ? _filters.copyWith(clearMood: true)
          : _filters.copyWith(mood: value),
    );
  }

  void _toggleWeather(String value) {
    _applyUpdate(
      _filters.weather == value
          ? _filters.copyWith(clearWeather: true)
          : _filters.copyWith(weather: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChronicleDeskPalette.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final moodOptions = JournalLetterheadUtils.moodOptions.reversed.toList();

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: palette.deskMat,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: palette.deckleBorder, width: 1.0),
              left: BorderSide(color: palette.deckleBorder, width: 1.0),
              right: BorderSide(color: palette.deckleBorder, width: 1.0),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: palette.deckleBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _CharmSheetHeader(
                    palette: palette,
                    hasActiveCharms: _filters.hasActiveCharmFilters,
                    onReset: () => _applyUpdate(_filters.resetCharms()),
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: palette.brassGold.withValues(alpha: 0.22),
                  ),
                  const SizedBox(height: 14),
                  _CharmSection(
                    title: '心情',
                    palette: palette,
                    children: [
                      for (final option in moodOptions)
                        _CharmOptionChip(
                          key: Key('charm_filter_mood_${option.value}'),
                          label: option.label,
                          semanticLabel: '心情：${option.label}',
                          leadingEmoji: option.emoji,
                          isSelected: _filters.mood == option.value,
                          palette: palette,
                          onTap: () => _toggleMood(option.value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CharmSection(
                    title: '天气',
                    palette: palette,
                    children: [
                      for (final option
                          in JournalLetterheadUtils.weatherOptions)
                        _CharmOptionChip(
                          key: Key('charm_filter_weather_${option.value}'),
                          label: option.label,
                          semanticLabel: '天气：${option.label}',
                          leadingIcon: option.icon,
                          isSelected: _filters.weather == option.value,
                          palette: palette,
                          onTap: () => _toggleWeather(option.value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CharmSection(
                    title: '类型',
                    palette: palette,
                    children: [
                      _CharmOptionChip(
                        key: const Key('charm_filter_media_toggle'),
                        label: '含照片',
                        semanticLabel: '仅看含照片日记',
                        leadingIcon: Icons.photo_outlined,
                        isSelected: _filters.hasMediaOnly,
                        palette: palette,
                        onTap: () => _applyUpdate(
                          _filters.copyWith(hasMediaOnly: !_filters.hasMediaOnly),
                        ),
                      ),
                      _CharmOptionChip(
                        key: const Key('charm_filter_weekly_toggle'),
                        label: '每周复盘',
                        semanticLabel: '仅看每周复盘日记',
                        leadingIcon: Icons.auto_stories_outlined,
                        isSelected: _filters.weeklyReviewOnly,
                        palette: palette,
                        onTap: () => _applyUpdate(
                          _filters.copyWith(
                            weeklyReviewOnly: !_filters.weeklyReviewOnly,
                          ),
                        ),
                      ),
                    ],
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

class _CharmSection extends StatelessWidget {
  final String title;
  final ChronicleDeskPalette palette;
  final List<Widget> children;

  const _CharmSection({
    required this.title,
    required this.palette,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: palette.brassGold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _CharmSheetHeader extends StatelessWidget {
  final ChronicleDeskPalette palette;
  final bool hasActiveCharms;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const _CharmSheetHeader({
    required this.palette,
    required this.hasActiveCharms,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: palette.cinnabar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '筛选',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '按心情、天气和类型筛选（未选则显示全部）',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        MinTapTarget(
          inkWellKey: const Key('charm_filter_reset_button'),
          enabled: hasActiveCharms,
          semanticLabel: '清除筛选',
          onTap: onReset,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '清除筛选',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: hasActiveCharms
                    ? palette.cinnabar
                    : palette.textFaint,
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: '关闭筛选',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('charm_filter_close_button'),
              onTap: onClose,
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: palette.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CharmOptionChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final String? leadingEmoji;
  final IconData? leadingIcon;
  final bool isSelected;
  final ChronicleDeskPalette palette;
  final VoidCallback onTap;

  const _CharmOptionChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    this.leadingEmoji,
    this.leadingIcon,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final bgColor = isSelected
        ? palette.cinnabar.withValues(alpha: 0.16)
        : palette.agedChip;
    final borderColor = isSelected ? palette.cinnabar : palette.deckleBorder;
    final textColor = isSelected ? palette.cinnabar : palette.textPrimary;

    return MinTapTarget(
      selected: isSelected,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
                    if (leadingEmoji != null)
                      Text(leadingEmoji!, style: const TextStyle(fontSize: 15))
                    else if (leadingIcon != null)
                      Icon(
                        leadingIcon,
                        size: 16,
                        color: isSelected ? palette.cinnabar : tokens.danmo,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: palette.cinnabar,
                      ),
                    ],
          ],
        ),
      ),
    );
  }
}
