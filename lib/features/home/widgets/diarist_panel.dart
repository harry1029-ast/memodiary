import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/home/widgets/cloud_avatar.dart';

/// The Diarist Panel (`我的`): a casement-woodwork screen in the active
/// Atmosphere Palette holding the placeholder profile, any [sections], and the
/// `返回封面` row last.
class DiaristPanel extends StatelessWidget {
  /// Placeholder profile copy, fixed until a profile spec replaces it.
  static const String placeholderName = '云皓主人';
  static const String placeholderMotto = '记录今日，也收藏远方';

  /// Content between the profile and `返回封面` (stats strip, rows).
  final List<Widget> sections;
  final VoidCallback onReturnToCover;

  const DiaristPanel({
    super.key,
    this.sections = const [],
    required this.onReturnToCover,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        key: const Key('diarist_panel'),
        decoration: BoxDecoration(
          gradient: palette.woodworkGradient(),
          border: Border(
            right: BorderSide(color: palette.woodFrameHighlight, width: 6),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(4, 0)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            right: false,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: _CasementInset(
                palette: palette,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _PlaceholderProfile(palette: palette),
                    const SizedBox(height: 20),
                    ...sections,
                    DiaristPanelRow(
                      key: const Key('diarist_panel_return_to_cover_row'),
                      icon: Icons.auto_stories_outlined,
                      label: '返回封面',
                      onTap: onReturnToCover,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable Diarist Panel row: icon, label and a trailing chevron.
class DiaristPanelRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DiaristPanelRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: palette.accentPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.headerTitleText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.headerSubText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The casement's inner frame: a hairline-bordered panel inset from the wood.
class _CasementInset extends StatelessWidget {
  final AtmospherePalette palette;
  final Widget child;

  const _CasementInset({required this.palette, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: child,
      ),
    );
  }
}

/// Display-only placeholder profile: no tap, no edit, nothing persisted.
class _PlaceholderProfile extends StatelessWidget {
  final AtmospherePalette palette;

  const _PlaceholderProfile({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('diarist_panel_profile'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CloudAvatar(diameter: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DiaristPanel.placeholderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.headerTitleText,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DiaristPanel.placeholderMotto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.headerSubText,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
