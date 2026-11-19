import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/shanshui_atmosphere.dart';
import 'xiangfei_bamboo_blind.dart';

/// Compact `44dp` slatted bamboo bar displayed when the window is folded.
/// Exposes a full `44dp`-tall semantic tap target (`scenery_collapsed_blind_bar`)
/// showing only the pull-up trigger pill and the active time/weather badge.
class BambooBlindCollapsedBar extends StatelessWidget {
  final ShanshuiAtmosphereState atmosphere;
  final VoidCallback onExpand;

  const BambooBlindCollapsedBar({
    super.key,
    required this.atmosphere,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    return Container(
      key: const Key('scenery_card_collapsed'),
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: palette.blindCordSecondary.withValues(alpha: 0.42),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: CustomPaint(
          painter: XiangfeiBambooSlatPainter(compact: true, palette: palette),
          child: Material(
            type: MaterialType.transparency,
            child: Semantics(
              label: '展开山水画卷',
              button: true,
              child: InkWell(
                key: const Key('scenery_collapsed_blind_bar'),
                onTap: onExpand,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 380;
                    final pullUpPill = Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 7 : 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.woodFrameDark.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.accentPrimary.withValues(alpha: 0.65),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.accentSecondary,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.40),
                                width: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '拽绳卷帘 ↑',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: InkDiaryTheme.fontNotoSerif,
                                fontSize: isCompact ? 10 : 10.5,
                                color: palette.blindTagAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    final weatherPill = Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 7 : 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.woodFrameDark.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        atmosphere.timeWeatherBadgeZh,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: palette.headerTitleText,
                          fontSize: isCompact ? 10 : 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );

                    return Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: pullUpPill),
                          const SizedBox(width: 8),
                          Flexible(child: weatherPill),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
