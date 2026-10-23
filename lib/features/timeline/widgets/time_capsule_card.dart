import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/core/theme/widgets/xuan_paper_card.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';

/// Sealed countdown card for Time Capsule entries where DateTime.now() < unlockAt.
/// Styled according to the Ink & Paper Journal aesthetic (*“时光胶囊 · 封缄书”*).
/// Strictly conceals plain-text snippets, content delta, and images until unlock date.
class TimeCapsuleCard extends StatelessWidget {
  final TimelineEntryItem item;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? customMargin;

  const TimeCapsuleCard({
    super.key,
    required this.item,
    this.onTap,
    this.customMargin,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final unlockDate = item.entry.unlockAt;
    String unlockDateStr;
    try {
      unlockDateStr = unlockDate != null
          ? DateFormat('yyyy年M月d日 HH:mm', 'zh_CN').format(unlockDate)
          : '未指定时日';
    } catch (_) {
      unlockDateStr = unlockDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(unlockDate)
          : '未指定时日';
    }

    final now = DateTime.now();
    final remainingDays = unlockDate != null
        ? unlockDate.difference(now).inDays.clamp(0, 9999)
        : 0;

    return XuanPaperCard(
      margin: customMargin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      backgroundColor: tokens.agedFiber.withValues(alpha: 0.5),
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          _showSealedDialog(context, unlockDateStr);
        }
      },
      child: Row(
        children: [
          // Padlock in cinnabar wash container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.cinnabarWash,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tokens.cinnabar.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 20,
              color: tokens.cinnabar,
            ),
          ),
          const SizedBox(width: 12),

          // Titles & Countdown Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TIME CAPSULE',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tokens.cinnabar,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '时光胶囊 · 封缄书',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        color: tokens.danmo,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CinnabarSealBadge.compact(
                      text: '封存中',
                      size: 20,
                      isWashVariant: false,
                    ),
                  ],
                ),
                if (item.entry.title != null && item.entry.title!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.entry.title!,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: tokens.jiaomo,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  '封存至 $unlockDateStr · Unlocks in $remainingDays days (距启缄尚有 $remainingDays 天)',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11,
                    color: tokens.danmo,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Icon(
            Icons.visibility_off_outlined,
            size: 18,
            color: tokens.qingmo,
          ),
        ],
      ),
    );
  }

  void _showSealedDialog(BuildContext context, String unlockDateStr) {
    final tokens = context.inkTokens;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: tokens.cinnabar, size: 20),
            const SizedBox(width: 8),
            const Text('Time Capsule Sealed'),
          ],
        ),
        content: Text(
          '此墨稿已被时光密缄，需静候至 $unlockDateStr 方能启卷阅览。在此之前，笔墨均处于硬件级密匣封存，不可窥看。',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontLiterata,
            height: 1.6,
            color: tokens.nongmo,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Waiting'),
          ),
        ],
      ),
    );
  }
}
