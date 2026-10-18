import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';

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

    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(140),
            theme.colorScheme.secondaryContainer.withAlpha(110),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entries.isNotEmpty
                      ? 'On This Day · ${entries.length} ${entries.length == 1 ? 'Memory' : 'Memories'}'
                      : 'Memory Retrospection',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (onOpenSerendipity != null)
                TextButton.icon(
                  key: const Key('open_serendipity_roulette_btn'),
                  onPressed: onOpenSerendipity,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.casino_outlined, size: 16),
                  label: const Text(
                    'Memory Roulette',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final yearsAgo = (currentYear - entry.entryDate.year).clamp(1, 99);
                  final yearBadge =
                      '$yearsAgo ${yearsAgo == 1 ? 'Year' : 'Years'} Ago · ${entry.entryDate.year}';
                  final titleText = (entry.title?.trim().isNotEmpty ?? false)
                      ? entry.title!.trim()
                      : DateFormat('MMM d, y').format(entry.entryDate);
                  final preview = entry.isLocked
                      ? '🔒 Locked memory'
                      : entry.plainText.trim().isEmpty
                          ? 'No text preview'
                          : entry.plainText.trim();

                  return InkWell(
                    key: Key('on_this_day_card_${entry.id}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onEntryTap(entry),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(235),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(100),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            yearBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

