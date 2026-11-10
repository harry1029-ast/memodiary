import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../controllers/editor_autosave_manager.dart';

/// How an autosave status reads and the colour of its dot, shared by the app
/// bar's status line and the header band's save-state dot.
({String label, Color color}) autosaveStatusStyle(AutosaveStatus status, InkDiaryTokens tokens) => switch (status) {
      AutosaveStatus.saved => (label: '已保存', color: const Color(0xFF059669)),
      AutosaveStatus.saving => (label: '存墨中...', color: const Color(0xFFD97706)),
      AutosaveStatus.unsaved => (label: '草稿未存', color: tokens.danmo),
    };

/// A small dot mirroring the autosave status. With [showLabel] it is followed
/// by the status in words (the app bar); alone it stands in for the app bar in
/// the header band while the keyboard is open, and reads its status to screen
/// readers.
class AutosaveStatusDot extends StatelessWidget {
  final ValueListenable<AutosaveStatus> status;
  final bool showLabel;
  final Color? labelColor;

  static const double kDotSize = 7.0;

  const AutosaveStatusDot({super.key, required this.status, this.showLabel = false, this.labelColor});

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    return ValueListenableBuilder<AutosaveStatus>(
      valueListenable: status,
      builder: (statusContext, currentStatus, unusedChild) {
        final style = autosaveStatusStyle(currentStatus, tokens);
        final dot = Container(
          width: kDotSize,
          height: kDotSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: style.color),
        );
        if (!showLabel) return Semantics(label: style.label, child: dot);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot,
            const SizedBox(width: 6),
            Text(
              style.label,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}
