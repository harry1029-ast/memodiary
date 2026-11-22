import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';
import 'writing_dock_collapse_tabs.dart';
import 'writing_dock_formatting_ribbon.dart';
import 'writing_dock_tool_button.dart';

/// The slim row resting on the software keyboard in place of the Writing Dock
/// while the diarist types: Tt formatting (unfolding the formatting ribbon
/// above it), 🎙 dictation and the [WritingDockHideTab] (收起工具栏), which
/// hides the toolbar until restored via the floating tab on the desk. Photo,
/// video and ambiance tools wait in the dock: collecting closes the keyboard
/// anyway.
///
/// None of the three touch focus, so the keyboard stays open.
class KeyboardAccessoryRow extends StatelessWidget {
  final QuillController controller;
  final QuillController Function()? onEnsureTextController;
  final bool isFormattingOpen;
  final VoidCallback? onToggleFormatting;
  final VoidCallback onToggleDictation;
  final VoidCallback onHide;
  final bool isDictating;
  final Color backgroundColor;
  final Color inkColor;
  final Color? borderColor;
  final bool isPaperDark;

  static const double kRowHeight = 44.0;

  const KeyboardAccessoryRow({
    super.key,
    required this.controller,
    this.onEnsureTextController,
    this.isFormattingOpen = false,
    this.onToggleFormatting,
    required this.onToggleDictation,
    required this.onHide,
    this.isDictating = false,
    required this.backgroundColor,
    required this.inkColor,
    this.borderColor,
    this.isPaperDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        key: const Key('keyboard_accessory_row'),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor ?? tokens.agedFiber, width: 1.0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormattingRibbonReveal(
                isOpen: isFormattingOpen,
                controller: controller,
                onEnsureTextController: onEnsureTextController,
                tokens: tokens,
                inkColor: inkColor,
                isPaperDark: isPaperDark,
              ),
              SizedBox(height: KeyboardAccessoryRow.kRowHeight, child: _buildTools(tokens)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTools(InkDiaryTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Row(
        children: [
          WritingDockToolButton(
            buttonKey: const Key('keyboard_accessory_format_btn'),
            icon: _TtGlyph(color: inkColor),
            tooltip: '字体排版',
            isActive: isFormattingOpen,
            activeBackground:
                isPaperDark ? const Color(0x38D4AF37) : tokens.agedFiber.withValues(alpha: 0.85),
            minHeight: KeyboardAccessoryRow.kRowHeight,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleFormatting?.call();
            },
          ),
          const SizedBox(width: 6.0),
          DictationToolButton(
            buttonKey: const Key('keyboard_accessory_dictation_btn'),
            isDictating: isDictating,
            minHeight: KeyboardAccessoryRow.kRowHeight,
            onTap: onToggleDictation,
          ),
          const Spacer(),
          WritingDockHideTab(onHide: onHide),
        ],
      ),
    );
  }
}

/// The prototype's "Tt" mark: a bold capital with a smaller lowercase twin.
class _TtGlyph extends StatelessWidget {
  final Color color;

  const _TtGlyph({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'T',
        style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 16, fontWeight: FontWeight.bold, color: color),
        children: const [TextSpan(text: 't', style: TextStyle(fontSize: 12))],
      ),
    );
  }
}
