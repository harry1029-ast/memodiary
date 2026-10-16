import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';

/// Card summarizing an active entry on the timeline feed.
class EntrySummaryCard extends StatelessWidget {
  final TimelineEntryItem item;
  final MediaSandboxService mediaService;
  final VoidCallback onTap;

  const EntrySummaryCard({
    super.key,
    required this.item,
    required this.mediaService,
    required this.onTap,
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
    final theme = Theme.of(context);
    final entry = item.entry;
    final dateFormatted = DateFormat('MMM d, y · EEE').format(entry.entryDate);
    final timeFormatted = DateFormat('h:mm a').format(entry.entryDate);

    final moodEmoji = entry.mood != null ? moodEmojis[entry.mood!] : null;
    final weatherIcon =
        entry.weather != null ? weatherIcons[entry.weather!] : null;

    final titleText =
        (entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : 'Untitled';
    final snippetText = entry.plainText.trim();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Date, Time, Mood & Weather Badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$dateFormatted  $timeFormatted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (entry.isWeeklyReview) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.weekNumber != null
                            ? 'W${entry.weekNumber} Review'
                            : 'Weekly Review',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (moodEmoji != null) ...[
                    Text(moodEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                  ],
                  if (weatherIcon != null) ...[
                    Icon(
                      weatherIcon,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // 2. Middle Row: Title + Snippet on left, Thumbnail on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (snippetText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            snippetText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.primaryMedia != null) ...[
                    const SizedBox(width: 12),
                    _buildThumbnail(item.primaryMedia!.relativePath),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String relativePath) {
    return FutureBuilder<File>(
      future: mediaService.getFileFromRelativePath(relativePath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              snapshot.data!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            ),
          );
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }
}
