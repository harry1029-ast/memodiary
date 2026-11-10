import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';
import 'writing_dock_collapse_tabs.dart';
import 'writing_dock_formatting_ribbon.dart';
import 'writing_dock_tool_button.dart';

/// Progressive two-tier bottom writing dock at the foot of the editor while
/// the software keyboard is closed; the KeyboardAccessoryRow stands in for it
/// while the diarist types.
/// Tier 1 presents 5 high-frequency tools: Aa Formatting, Photo, Video, Dictation, Spark.
/// Tier 2 smoothly unfolds on-demand as an inline formatting ribbon.
class WritingDock extends StatefulWidget {
  final QuillController controller;
  final QuillController Function()? onEnsureTextController;
  final VoidCallback onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback onToggleDictation;
  final VoidCallback? onHide;
  final VoidCallback? onShuffleSpark;
  final bool isDictating;
  final Color? backgroundColor;
  final Color? inkColor;
  final bool isPaperDark;

  const WritingDock({
    super.key,
    required this.controller,
    this.onEnsureTextController,
    required this.onPickImage,
    this.onPickVideo,
    required this.onToggleDictation,
    this.onHide,
    this.onShuffleSpark,
    this.isDictating = false,
    this.backgroundColor,
    this.inkColor,
    this.isPaperDark = false,
  });

  @override
  State<WritingDock> createState() => _WritingDockState();
}

class _WritingDockState extends State<WritingDock> {
  bool _isFormattingOpen = false;

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final effectiveBackground = widget.backgroundColor ??
        (widget.isPaperDark ? tokens.xuanGround.withValues(alpha: 0.96) : tokens.xuanPureLeaf.withValues(alpha: 0.96));

    final effectiveInkColor =
        widget.inkColor ?? (widget.isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF2D2D2D));

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveBackground,
          border: Border(
            top: BorderSide(
              color: tokens.agedFiber,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.jiaomo.withValues(alpha: 0.04),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: _buildExpandedContent(tokens, effectiveInkColor),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(InkDiaryTokens tokens, Color effectiveInkColor) {
    final onHide = widget.onHide;
    return Stack(
      children: [
        _buildColumn(tokens, effectiveInkColor),
        if (onHide != null) Positioned(top: 0, right: 0, child: WritingDockHideTab(onHide: onHide)),
      ],
    );
  }

  Widget _buildColumn(InkDiaryTokens tokens, Color effectiveInkColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8.0),
        FormattingRibbonReveal(
          isOpen: _isFormattingOpen,
          controller: widget.controller,
          onEnsureTextController: widget.onEnsureTextController,
          tokens: tokens,
          inkColor: effectiveInkColor,
          isPaperDark: widget.isPaperDark,
          // The hide tab hangs in the top-right corner, beside the ribbon.
          rightInset: widget.onHide != null ? WritingDockHideTab.kTargetSize : 0.0,
        ),
        _buildPrimaryToolbar(tokens, effectiveInkColor),
      ],
    );
  }

  Widget _buildPrimaryToolbar(InkDiaryTokens tokens, Color effectiveInkColor) {
    final activeBackdrop = tokens.agedFiber.withValues(alpha: widget.isPaperDark ? 0.65 : 0.85);

    return Container(
      height: 48,
      padding: EdgeInsets.only(left: 14, right: widget.onHide != null ? WritingDockHideTab.kTargetSize : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPrimaryToolBtn(
            key: const Key('writing_dock_format_btn'),
            icon: Icons.text_fields_rounded,
            tooltip: '字法排印 · Formatting',
            isActive: _isFormattingOpen,
            color: effectiveInkColor,
            activeBackground: activeBackdrop,
            onTap: () {
              HapticFeedback.lightImpact();
              if (!_isFormattingOpen) {
                widget.onEnsureTextController?.call();
              }
              setState(() => _isFormattingOpen = !_isFormattingOpen);
            },
          ),
          _buildPrimaryToolBtn(
            key: const Key('writing_dock_photo_btn'),
            icon: Icons.add_photo_alternate_outlined,
            tooltip: '插入图画 · Insert Photo',
            isActive: false,
            color: effectiveInkColor,
            onTap: widget.onPickImage,
          ),
          if (widget.onPickVideo != null)
            _buildPrimaryToolBtn(
              key: const Key('writing_dock_video_btn'),
              icon: Icons.videocam_outlined,
              tooltip: '插入短影 · Short Video (≤60s)',
              isActive: false,
              color: effectiveInkColor,
              onTap: widget.onPickVideo!,
            ),
          DictationToolButton(
            buttonKey: const Key('writing_dock_dictation_btn'),
            isDictating: widget.isDictating,
            onTap: widget.onToggleDictation,
          ),
          if (widget.onShuffleSpark != null)
            _buildPrimaryToolBtn(
              key: const Key('writing_dock_spark_btn'),
              icon: Icons.auto_awesome_outlined,
              tooltip: '灵感拾遗 · Thought Spark',
              isActive: false,
              color: const Color(0xFFD4AF37),
              onTap: widget.onShuffleSpark!,
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryToolBtn({
    required Key key,
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
    Color? activeBackground,
  }) {
    return WritingDockToolButton(
      buttonKey: key,
      icon: Icon(icon, size: 21, color: color),
      tooltip: tooltip,
      isActive: isActive,
      activeBackground: activeBackground,
      onTap: onTap,
    );
  }
}
