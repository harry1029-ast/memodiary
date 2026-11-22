import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'desk_palette.dart';

/// Compact tab attached to the centre top edge of the Desk Workstation's bamboo
/// mat (or peeking up from the desk's bottom edge while collapsed): a 44x44
/// touch target around a 40x18 mat-matched tab bearing [icon]. Taps never touch
/// focus, so the software keyboard stays as it is.
class _WorkstationTab extends StatelessWidget {
  final Key tabKey;
  final String semanticLabel;
  final IconData icon;
  final AlignmentGeometry alignment;
  final VoidCallback onTap;

  const _WorkstationTab({
    required this.tabKey,
    required this.semanticLabel,
    required this.icon,
    required this.alignment,
    required this.onTap,
  });

  static const double kTargetSize = 44.0;
  static const double kTabWidth = 40.0;
  static const double kTabHeight = 18.0;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: tabKey,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: kTargetSize,
          height: kTargetSize,
          child: Align(
            alignment: alignment,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.mat,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                border: Border(
                  top: BorderSide(color: palette.matRim),
                  left: BorderSide(color: palette.matRim),
                  right: BorderSide(color: palette.matRim),
                ),
                boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 4.0, offset: Offset(0, -1))],
              ),
              child: SizedBox(
                width: kTabWidth,
                height: kTabHeight,
                child: Icon(icon, size: 16.0, color: const Color(0xE6FDE68A)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The centred down-arrow tab attached to the top edge of the Desk
/// Workstation's bamboo mat that puts the workstation away.
class WorkstationCollapsePill extends StatelessWidget {
  final int stagedCount;
  final VoidCallback onCollapse;

  const WorkstationCollapsePill({super.key, required this.stagedCount, required this.onCollapse});

  static const String kSemanticLabel = '收起待选区';

  String get _semanticLabel => stagedCount == 0 ? kSemanticLabel : '$kSemanticLabel · $stagedCount 项';

  @override
  Widget build(BuildContext context) => _WorkstationTab(
        tabKey: const Key('workstation_collapse_pill'),
        semanticLabel: _semanticLabel,
        icon: Icons.keyboard_arrow_down_rounded,
        alignment: Alignment.center,
        onTap: onCollapse,
      );
}

/// The centred up-arrow tab resting at the foot of the Scholar's Desk while the
/// Desk Workstation is put away. Tapping it brings the workstation back.
class WorkstationRestorePill extends StatelessWidget {
  final int stagedCount;
  final VoidCallback onRestore;

  const WorkstationRestorePill({super.key, required this.stagedCount, required this.onRestore});

  static const String kSemanticLabel = '展开待选区';

  String get _semanticLabel => stagedCount == 0 ? kSemanticLabel : '$kSemanticLabel · $stagedCount 项';

  @override
  Widget build(BuildContext context) => _WorkstationTab(
        tabKey: const Key('workstation_restore_pill'),
        semanticLabel: _semanticLabel,
        icon: Icons.keyboard_arrow_up_rounded,
        alignment: Alignment.bottomCenter,
        onTap: onRestore,
      );
}
