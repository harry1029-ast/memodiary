import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/xuan_paper_card.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';

/// Card summarizing an active entry on the timeline feed,
/// styled with the Ink & Paper Journal Xuan paper slip aesthetic.
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
    final entry = item.entry;

    String dateFormatted;
    try {
      dateFormatted = DateFormat('yyyy年M月d日 · EEE', 'zh_CN').format(entry.entryDate);
    } catch (_) {
      dateFormatted = DateFormat('yyyy-MM-dd').format(entry.entryDate);
    }
    final timeFormatted = DateFormat('HH:mm').format(entry.entryDate);

    final moodEmoji = entry.mood != null ? moodEmojis[entry.mood!] : null;
    final weatherIcon =
        entry.weather != null ? weatherIcons[entry.weather!] : null;

    final isLocked = entry.isLocked;
    final titleText = isLocked
        ? ((entry.title?.trim().isNotEmpty ?? false)
            ? entry.title!.trim()
            : 'Private Reflection')
        : ((entry.title?.trim().isNotEmpty ?? false)
            ? entry.title!.trim()
            : '无题 · 偶感');
    final snippetText = isLocked ? '🔒 This entry is locked' : entry.plainText.trim();

    return XuanPaperCard(
      onTap: onTap,
      margin: customMargin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Date, Time, Mood & Weather Badges
          Row(
            children: [
              // Red dot indicator on date
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.cinnabar,
                ),
              ),
              Expanded(
                child: Text(
                  '$dateFormatted  $timeFormatted',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: tokens.danmo,
                  ),
                ),
              ),
              if (isLocked) ...[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: tokens.cinnabar,
                ),
                const SizedBox(width: 6),
              ],
              if (entry.isWeeklyReview) ...[
                CinnabarSealBadge.compact(
                  text: entry.weekNumber != null
                      ? 'W${entry.weekNumber}'
                      : '复盘',
                  size: 22,
                  isWashVariant: true,
                ),
                const SizedBox(width: 6),
              ],
              if (moodEmoji != null) ...[
                Text(moodEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
              ],
              if (weatherIcon != null) ...[
                Icon(
                  weatherIcon,
                  size: 15,
                  color: tokens.danmo,
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
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.jiaomo,
                        letterSpacing: 0.2,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (snippetText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        snippetText,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontLiterata,
                          fontSize: 13.5,
                          color: isLocked
                              ? tokens.cinnabar
                              : tokens.danmo,
                          fontStyle:
                              isLocked ? FontStyle.italic : FontStyle.normal,
                          height: 1.55,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLocked && item.primaryMedia != null) ...[
                const SizedBox(width: 12),
                _buildThumbnail(item.primaryMedia!.relativePath, tokens),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String relativePath, InkDiaryTokens tokens) {
    return FutureBuilder<File>(
      future: mediaService.getFileFromRelativePath(relativePath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.deckleBorder, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                snapshot.data!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(tokens),
              ),
            ),
          );
        }
        return _buildPlaceholder(tokens);
      },
    );
  }

  Widget _buildPlaceholder(InkDiaryTokens tokens) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: tokens.agedFiber,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.deckleBorder, width: 1),
      ),
      child: Icon(Icons.image_outlined, color: tokens.qingmo, size: 22),
    );
  }
}
