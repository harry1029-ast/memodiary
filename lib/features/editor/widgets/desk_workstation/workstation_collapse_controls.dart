import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The brass pull tab (拉手) centred on the Desk Workstation's top edge that
/// puts the workstation away. A 44x44 target around a slim brass plate.
///
/// Taps never touch focus, so the software keyboard stays as it is.
class WorkstationPullTab extends StatelessWidget {
  final VoidCallback onCollapse;

  const WorkstationPullTab({super.key, required this.onCollapse});

  static const double kTargetSize = 44.0;
  static const String kSemanticLabel = '收起画案';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: kSemanticLabel,
      onTap: onCollapse,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('workstation_pull_tab'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onCollapse();
        },
        child: const SizedBox(
          width: kTargetSize,
          height: kTargetSize,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                border: Border.fromBorderSide(BorderSide(color: Color(0xFF6B4F1D), width: 0.8)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE6C877), Color(0xFFB8913A)],
                ),
                boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 4.0, offset: Offset(0, 1))],
              ),
              child: SizedBox(
                width: 36.0,
                height: 18.0,
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 16.0, color: Color(0xFF3B2A0C)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Restore Pill (展案签) resting at the foot of the Scholar's Desk while the
/// Desk Workstation is put away: a dark walnut tab with an amber border and
/// text, showing how many items wait in the Staging Handscroll. Tapping it
/// brings the workstation back.
class WorkstationRestorePill extends StatelessWidget {
  final int stagedCount;
  final VoidCallback onRestore;

  const WorkstationRestorePill({super.key, required this.stagedCount, required this.onRestore});

  static const String kSemanticLabel = '展开画案';

  String get _label => stagedCount == 0 ? '锦袱合卷' : '待贴画卷已收起 · 待贴 $stagedCount 影';

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        button: true,
        label: kSemanticLabel,
        onTap: onRestore,
        excludeSemantics: true,
        child: GestureDetector(
          key: const Key('workstation_restore_pill'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            onRestore();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44.0, minWidth: 44.0),
            child: Center(
              widthFactor: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xF22B221A),
                  borderRadius: BorderRadius.circular(999.0),
                  border: Border.all(color: const Color(0x73F59E0B)),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8.0, offset: Offset(0, 3))],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.0, letterSpacing: 1.5, color: Color(0xFFFDE68A)),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Icon(Icons.keyboard_arrow_up_rounded, size: 16.0, color: Color(0xFFFDE68A)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
