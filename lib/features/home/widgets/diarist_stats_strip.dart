import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/home/data/diarist_stats_repository.dart';

/// The Diarist Panel's `日记 · 相册 · 收藏` strip. `日记` and `相册` show their
/// counts and are tappable; `收藏` is a dimmed `—` with no action until
/// favourites exist. [stats] is null while the counts load.
class DiaristStatsStrip extends StatelessWidget {
  final DiaristStats? stats;
  final VoidCallback onDiaryTap;
  final VoidCallback onAlbumsTap;

  const DiaristStatsStrip({
    super.key,
    required this.stats,
    required this.onDiaryTap,
    required this.onAlbumsTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final divider = SizedBox(
      height: 28,
      child: VerticalDivider(width: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.14)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              key: const Key('diarist_panel_stat_diary'),
              label: '日记',
              value: stats == null ? '…' : '${stats!.entryCount}',
              palette: palette,
              onTap: onDiaryTap,
            ),
          ),
          divider,
          Expanded(
            child: _StatCell(
              key: const Key('diarist_panel_stat_albums'),
              label: '相册',
              value: stats == null ? '…' : '${stats!.albumCount}',
              palette: palette,
              onTap: onAlbumsTap,
            ),
          ),
          divider,
          Expanded(
            child: _StatCell(
              key: const Key('diarist_panel_stat_favourites'),
              label: '收藏',
              value: '—',
              palette: palette,
            ),
          ),
        ],
      ),
    );
  }
}

/// One stat: the count above its label, read as "label count". Without
/// [onTap] the cell is dimmed and announced as unavailable.
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final AtmospherePalette palette;
  final VoidCallback? onTap;

  const _StatCell({
    super.key,
    required this.label,
    required this.value,
    required this.palette,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = onTap != null;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.headerTitleText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: palette.headerSubText,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
    if (!isAvailable) {
      return Semantics(
        container: true,
        label: '$label 暂不可用',
        excludeSemantics: true,
        child: Opacity(opacity: 0.45, child: content),
      );
    }
    return Semantics(
      container: true,
      button: true,
      label: '$label $value',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
