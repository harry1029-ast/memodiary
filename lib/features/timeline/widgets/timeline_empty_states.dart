import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';

/// First-run empty state (`素宣待书`) shown only when the database has 0 active entries.
class TimelineOnboardingEmptyState extends StatelessWidget {
  final VoidCallback onCreateEntry;

  const TimelineOnboardingEmptyState({
    super.key,
    required this.onCreateEntry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CinnabarSealBadge(
            text: '暂无\n日记',
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            '暂无日记',
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tokens.jiaomo,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '还没有写过日记。记录当下的生活与心情，所有内容均保存在本地设备。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontLiterata,
              fontSize: 13,
              height: 1.6,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateEntry,
            icon: const Icon(Icons.brush_rounded, size: 16),
            label: const Text('写第一篇日记'),
          ),
        ],
      ),
    );
  }
}

/// Error state displayed when loading timeline entries fails.
class TimelineErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const TimelineErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: tokens.cinnabar,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontLiterata,
                fontSize: 12,
                color: tokens.danmo,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
