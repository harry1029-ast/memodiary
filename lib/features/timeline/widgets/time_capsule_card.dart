import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/widgets/folded_xuan_slip.dart';

/// Sealed countdown card for Time Capsule entries where DateTime.now() < unlockAt.
/// Styled on the folded Xuan-paper slip (*折笺影札*) with a two-tier header alignment.
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
    final palette = FoldedXuanSlipPalette.of(context);
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
    final trimmedTitle = item.entry.title?.trim() ?? '';

    return FoldedXuanSlip(
      margin: customMargin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      onTap: () {
        final callback = onTap;
        if (callback != null) {
          callback();
        } else {
          _showSealedDialog(context, unlockDateStr);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier 1: Full-width Capsule Header (Padlock + Label/Title on left, Seal on right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tokens.cinnabarWash,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tokens.cinnabar.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: tokens.cinnabar,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif),
                        children: [
                          TextSpan(
                            text: 'TIME CAPSULE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tokens.cinnabar,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 4)),
                          TextSpan(
                            text: '时光胶囊 · 封缄书',
                            style: TextStyle(fontSize: 11, color: tokens.danmo),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (trimmedTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        trimmedTitle,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: tokens.jiaomo,
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.25,
                child: CinnabarSealBadge.compact(
                  text: '封存中',
                  size: 22,
                  isWashVariant: false,
                ),
              ),
            ],
          ),

          Container(
            height: 1.0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: palette.dividerColor,
          ),

          // Tier 2: Sealed Countdown Row (Never renders plainText)
          Row(
            children: [
              Expanded(
                child: Text(
                  '封存至 $unlockDateStr · Unlocks in $remainingDays days (距启缄尚有 $remainingDays 天)',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11.5,
                    color: tokens.danmo,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.visibility_off_outlined,
                size: 16,
                color: tokens.qingmo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSealedDialog(BuildContext context, String unlockDateStr) {
    final tokens = context.inkTokens;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: tokens.cinnabar, size: 20),
            const SizedBox(width: 8),
            const Flexible(child: Text('Time Capsule Sealed')),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Waiting'),
          ),
        ],
      ),
    );
  }
}
