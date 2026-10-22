import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/xuan_paper_card.dart';

/// Retrospective banner displayed at the top of the Timeline when past years
/// contain diary entries written on the same calendar month and day.
class OnThisDayBanner extends StatelessWidget {
  final List<Entry> entries;
  final ValueChanged<Entry> onEntryTap;
  final VoidCallback? onOpenSerendipity;

  const OnThisDayBanner({
    super.key,
    required this.entries,
    required this.onEntryTap,
    this.onOpenSerendipity,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty && onOpenSerendipity == null) {
      return const SizedBox.shrink();
    }

    final tokens = context.inkTokens;
    final currentYear = DateTime.now().year;

    return XuanPaperCard(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      backgroundColor: tokens.agedFiber.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CinnabarSealBadge.compact(
                text: '忆昔',
                size: 22,
                isWashVariant: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      entries.isNotEmpty
                          ? '岁时忆昔 · 往年今日存留 ${entries.length} 篇'
                          : '岁时忆昔 · 岁月吉光',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: tokens.jiaomo,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (entries.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        'On This Day · ${entries.length} ${entries.length == 1 ? "Memory" : "Memories"}',
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 11,
                          color: tokens.danmo,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onOpenSerendipity != null)
                TextButton.icon(
                  key: const Key('open_serendipity_roulette_btn'),
                  onPressed: onOpenSerendipity,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    foregroundColor: tokens.cinnabar,
                  ),
                  icon: const Icon(Icons.casino_outlined, size: 15),
                  label: const Text(
                    '漫步偶遇',
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entries.map((entry) {
                  final yearsAgo = currentYear - entry.entryDate.year;
                  final title = (entry.title?.trim().isNotEmpty ?? false)
                      ? entry.title!.trim()
                      : DateFormat('h:mm a').format(entry.entryDate);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: tokens.xuanPureLeaf,
                      side: BorderSide(color: tokens.deckleBorder, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      avatar: CircleAvatar(
                        radius: 9,
                        backgroundColor: tokens.cinnabarWash,
                        child: Text(
                          '$yearsAgo',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: tokens.cinnabar,
                          ),
                        ),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 11,
                              color: tokens.nongmo,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${yearsAgo == 1 ? '1年前' : '$yearsAgo年前'})',
                            style: TextStyle(
                              fontFamily: InkDiaryTheme.fontNotoSerif,
                              fontSize: 10,
                              color: tokens.danmo,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => onEntryTap(entry),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
