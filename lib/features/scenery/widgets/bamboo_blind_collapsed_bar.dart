import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/shanshui_atmosphere.dart';
import 'xiangfei_bamboo_blind.dart';

/// Compact `44dp` slatted bamboo bar displayed when the window is folded.
/// Exposes a full `44dp`-tall semantic tap target (`scenery_collapsed_blind_bar`)
/// while preserving independent tapping on the embedded [realmBadge].
class BambooBlindCollapsedBar extends StatelessWidget {
  final ShanshuiAtmosphereState atmosphere;
  final InkDiaryTokens tokens;
  final Widget realmBadge;
  final VoidCallback onExpand;

  const BambooBlindCollapsedBar({
    super.key,
    required this.atmosphere,
    required this.tokens,
    required this.realmBadge,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('scenery_card_collapsed'),
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x66B5924C),
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
          painter: const XiangfeiBambooSlatPainter(compact: true),
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
                  final titleWidget = Text(
                    '竹帘低垂 · ${atmosphere.titleZh}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: isCompact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF5EDE0),
                      shadows: const [
                        Shadow(
                          color: Color(0xAA000000),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  );
                  final weatherWidget = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x8C000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0x26FFFFFF),
                      ),
                    ),
                    child: Text(
                      atmosphere.timeWeatherBadgeZh,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFFE6C786),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                  final realmWidget = ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 68 : 90,
                    ),
                    child: realmBadge,
                  );

                  return Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        // Left pull-up pill
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xA6000000),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0x99C8A96E),
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
                                  color: const Color(0xFF68B09C),
                                  border: Border.all(
                                    color: const Color(0x66FFFFFF),
                                    width: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '拽绳卷帘 ↑',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: isCompact ? 9.5 : 10,
                                  color: const Color(0xFFE6C786),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          flex: isCompact ? 1 : 1,
                          child: titleWidget,
                        ),
                        const SizedBox(width: 4),
                        if (isCompact) ...[
                          Flexible(flex: 2, child: weatherWidget),
                          const SizedBox(width: 4),
                          Flexible(flex: 2, child: realmWidget),
                        ] else ...[
                          weatherWidget,
                          const SizedBox(width: 4),
                          realmWidget,
                        ],
                        const SizedBox(width: 4),
                        // Seasonal seal
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.cinnabar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            atmosphere.sealBadgeZh,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
