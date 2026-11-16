import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead_models.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/widgets/folded_xuan_slip.dart';
import 'package:memodiary/features/timeline/widgets/wet_mounted_thumbnail.dart';

/// Card summarizing an active entry on the timeline feed,
/// styled as a two-tier folded Xuan-paper slip (*折笺影札*).
class EntrySummaryCard extends StatelessWidget {
  final TimelineEntryItem item;
  final MediaSandboxService mediaService;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? customMargin;

  const EntrySummaryCard({
    super.key,
    required this.item,
    required this.mediaService,
    required this.onTap,
    this.customMargin,
  });

  static const Map<int, String> moodEmojis = {
    1: '😢',
    2: '🙁',
    3: '😐',
    4: '🙂',
    5: '😄',
  };

  static const Map<String, IconData> weatherIcons = {
    'sunny': Icons.wb_sunny_outlined,
    'cloudy': Icons.cloud_outlined,
    'rainy': Icons.water_drop_outlined,
    'windy': Icons.air_outlined,
    'snowy': Icons.ac_unit_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final palette = FoldedXuanSlipPalette.of(context);
    final entry = item.entry;

    final timestampText = DateFormat('yyyy-MM-dd HH:mm').format(entry.entryDate);
    final moodOption = entry.mood == null
        ? null
        : JournalLetterheadUtils.moodOptions
            .where((option) => option.value == entry.mood)
            .firstOrNull;
    final weatherOption = entry.weather == null
        ? null
        : JournalLetterheadUtils.weatherOptions
            .where((option) => option.value == entry.weather)
            .firstOrNull;

    final isLocked = entry.isLocked;
    final trimmedTitle = entry.title?.trim() ?? '';
    final titleText = isLocked
        ? (trimmedTitle.isNotEmpty ? trimmedTitle : 'Private Reflection')
        : (trimmedTitle.isNotEmpty ? trimmedTitle : '无题 · 偶感');
    final snippetText = isLocked ? '🔒 This entry is locked' : entry.plainText.trim();
    final hasThumbnail = !isLocked && item.primaryMedia != null;
    final hasTier2 = snippetText.isNotEmpty || hasThumbnail;

    return FoldedXuanSlip(
      onTap: onTap,
      margin: customMargin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier 1: Full-width top header (Title on left without cinnabar dot, metadata on right)
          _EntryCardHeader(
            titleText: titleText,
            timestampText: timestampText,
            isLocked: isLocked,
            isWeeklyReview: entry.isWeeklyReview,
            weekNumber: entry.weekNumber,
            moodOption: moodOption,
            weatherOption: weatherOption,
            tokens: tokens,
          ),

          if (hasTier2) ...[
            Container(
              height: 1.0,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: palette.dividerColor,
            ),

            // Tier 2: Snippet on left + Thumbnail on right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: snippetText.isNotEmpty
                      ? Text(
                          snippetText,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: isLocked ? tokens.cinnabar : tokens.danmo,
                            fontStyle: isLocked ? FontStyle.italic : FontStyle.normal,
                            height: 1.55,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
                ),
                if (hasThumbnail) ...[
                  const SizedBox(width: 12),
                  WetMountedThumbnail(
                    relativePath: item.primaryMedia!.relativePath,
                    mediaService: mediaService,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCardHeader extends StatelessWidget {
  final String titleText;
  final String timestampText;
  final bool isLocked;
  final bool isWeeklyReview;
  final int? weekNumber;
  final MoodOption? moodOption;
  final WeatherOption? weatherOption;
  final InkDiaryTokens tokens;

  const _EntryCardHeader({
    required this.titleText,
    required this.timestampText,
    required this.isLocked,
    required this.isWeeklyReview,
    required this.weekNumber,
    required this.moodOption,
    required this.weatherOption,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metadataMaxWidth = constraints.maxWidth * 0.5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                titleText,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                  letterSpacing: 0.2,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: metadataMaxWidth),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.25,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          timestampText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: tokens.danmo,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (isLocked)
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: tokens.cinnabar,
                        ),
                      if (isWeeklyReview)
                        CinnabarSealBadge.compact(
                          text: weekNumber != null ? 'W$weekNumber' : '复盘',
                          size: 22,
                          isWashVariant: true,
                        ),
                      if (weatherOption != null)
                        _EntryMetadataCharm(
                          key: const Key('entry_weather_charm'),
                          emoji: weatherOption!.emoji,
                          label: weatherOption!.label,
                          semanticsLabel: '天象 ${weatherOption!.label}',
                          tokens: tokens,
                        ),
                      if (moodOption != null)
                        _EntryMetadataCharm(
                          key: const Key('entry_mood_charm'),
                          emoji: moodOption!.emoji,
                          label: moodOption!.label,
                          semanticsLabel: '心绪 ${moodOption!.label}',
                          tokens: tokens,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact horizontal Xuan-paper charm matching the editor's `LetterheadCharm`.
class _EntryMetadataCharm extends StatelessWidget {
  final String emoji;
  final String label;
  final String semanticsLabel;
  final InkDiaryTokens tokens;

  const _EntryMetadataCharm({
    super.key,
    required this.emoji,
    required this.label,
    required this.semanticsLabel,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: tokens.ricePaper.withValues(alpha: 0.9),
          border: Border.all(color: tokens.cinnabar.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(1, 1.5),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11.5, height: 1.1)),
            const SizedBox(width: 2.5),
            Text(
              label,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 10.5,
                height: 1.15,
                color: tokens.danmo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
