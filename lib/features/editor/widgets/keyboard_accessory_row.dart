import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';
import 'writing_dock_formatting_ribbon.dart';
import 'writing_dock_tool_button.dart';

/// The slim row resting on the software keyboard in place of the Writing Dock
/// while the diarist types: Tt formatting (unfolding the formatting ribbon
/// above it), 🎙 dictation and 收起键盘, which ends writing and puts the
/// keyboard away. Photo, video and ambiance tools wait in the dock: collecting
/// closes the keyboard anyway.
///
/// Tt and 🎙 never touch focus, so the keyboard stays open.
class KeyboardAccessoryRow extends StatefulWidget {
  final QuillController controller;
  final QuillController Function()? onEnsureTextController;
  final VoidCallback onToggleDictation;
  final VoidCallback onDismissKeyboard;
  final bool isDictating;
  final Color backgroundColor;
  final Color inkColor;
  final bool isPaperDark;

  static const double kRowHeight = 44.0;
  static const String kDismissLabel = '收起键盘';

  const KeyboardAccessoryRow({
    super.key,
    required this.controller,
    this.onEnsureTextController,
    required this.onToggleDictation,
    required this.onDismissKeyboard,
    this.isDictating = false,
    required this.backgroundColor,
    required this.inkColor,
    this.isPaperDark = false,
  });

  @override
  State<KeyboardAccessoryRow> createState() => _KeyboardAccessoryRowState();
}

class _KeyboardAccessoryRowState extends State<KeyboardAccessoryRow> {
  static const _cinnabar = Color(0xFFB83B2E);
  bool _isFormattingOpen = false;

  void _toggleFormatting() {
    HapticFeedback.lightImpact();
    if (!_isFormattingOpen) widget.onEnsureTextController?.call();
    setState(() => _isFormattingOpen = !_isFormattingOpen);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        key: const Key('keyboard_accessory_row'),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border(top: BorderSide(color: tokens.agedFiber, width: 1.0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.bottomCenter,
                child: _isFormattingOpen
                    ? WritingDockFormattingRibbon(
                        controller: widget.controller,
                        onEnsureTextController: widget.onEnsureTextController,
                        tokens: tokens,
                        inkColor: widget.inkColor,
                        isPaperDark: widget.isPaperDark,
                      )
                    : const SizedBox.shrink(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          WritingDockToolButton(
            buttonKey: const Key('keyboard_accessory_format_btn'),
            icon: _TtGlyph(color: widget.inkColor),
            tooltip: '字法排印 · Formatting',
            isActive: _isFormattingOpen,
            activeBackground: tokens.agedFiber.withValues(alpha: widget.isPaperDark ? 0.65 : 0.85),
            minHeight: KeyboardAccessoryRow.kRowHeight,
            onTap: _toggleFormatting,
          ),
          const SizedBox(width: 6.0),
          WritingDockToolButton(
            buttonKey: const Key('keyboard_accessory_dictation_btn'),
            icon: Icon(widget.isDictating ? Icons.mic : Icons.mic_none,
                size: 21, color: widget.isDictating ? Colors.white : _cinnabar),
            tooltip: '原声听写 · Voice Dictation',
            isActive: widget.isDictating,
            activeBackground: _cinnabar,
            minHeight: KeyboardAccessoryRow.kRowHeight,
            onTap: widget.onToggleDictation,
          ),
          const Spacer(),
          _DismissKeyboardButton(inkColor: widget.inkColor, onTap: widget.onDismissKeyboard),
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

/// 收起键盘: a labelled 44dp target that ends writing. It holds no focus of
/// its own, so the keyboard closes only because writing focus is released.
class _DismissKeyboardButton extends StatelessWidget {
  final Color inkColor;
  final VoidCallback onTap;

  const _DismissKeyboardButton({required this.inkColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: KeyboardAccessoryRow.kDismissLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('keyboard_accessory_dismiss_btn'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44.0, minHeight: KeyboardAccessoryRow.kRowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_hide_outlined, size: 18, color: inkColor),
                const SizedBox(width: 4.0),
                Text(
                  KeyboardAccessoryRow.kDismissLabel,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
