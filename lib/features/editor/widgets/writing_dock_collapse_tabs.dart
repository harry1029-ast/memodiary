import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _brassBorder = Color(0xFF6B4F1D);
const _brassGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFE6C877), Color(0xFFB8913A)],
);
const _brassShadow = [BoxShadow(color: Color(0x66000000), blurRadius: 4.0, offset: Offset(0, 1))];

/// A 44x44 target around a slim brass plate bearing [icon], in the style of
/// the Desk Workstation's pull tab. Taps never touch focus, so the software
/// keyboard stays as it is.
class _BrassDockTab extends StatelessWidget {
  final Key tabKey;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _BrassDockTab({required this.tabKey, required this.semanticLabel, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          width: 44.0,
          height: 44.0,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                border: Border.all(color: _brassBorder, width: 0.8),
                gradient: _brassGradient,
                boxShadow: _brassShadow,
              ),
              child: SizedBox(
                width: 36.0,
                height: 18.0,
                child: Icon(icon, size: 16.0, color: const Color(0xFF3B2A0C)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tab (收起文房) at the right of the Writing Dock's top edge that hides it.
class WritingDockHideTab extends StatelessWidget {
  final VoidCallback onHide;

  const WritingDockHideTab({super.key, required this.onHide});

  static const double kTargetSize = 44.0;
  static const String kSemanticLabel = '收起文房';

  @override
  Widget build(BuildContext context) => _BrassDockTab(
        tabKey: const Key('writing_dock_hide_tab'),
        semanticLabel: kSemanticLabel,
        icon: Icons.keyboard_arrow_down_rounded,
        onTap: onHide,
      );
}

/// The tab (展开文房) resting at the bottom-right of the screen while the
/// Writing Dock is hidden; tapping it brings the dock back.
class WritingDockRestoreTab extends StatelessWidget {
  final VoidCallback onRestore;

  const WritingDockRestoreTab({super.key, required this.onRestore});

  static const String kSemanticLabel = '展开文房';

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.centerRight,
          child: _BrassDockTab(
            tabKey: const Key('writing_dock_restore_tab'),
            semanticLabel: kSemanticLabel,
            icon: Icons.keyboard_arrow_up_rounded,
            onTap: onRestore,
          ),
        ),
      );
}
