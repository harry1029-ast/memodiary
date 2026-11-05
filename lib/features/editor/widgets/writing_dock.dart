import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';
import 'writing_dock_formatting_ribbon.dart';

/// Progressive two-tier bottom writing dock anchored above the soft keyboard.
/// Tier 1 presents 5 high-frequency tools: Aa Formatting, Photo, Video, Dictation, Spark.
/// Tier 2 smoothly unfolds on-demand as an inline formatting ribbon.
/// Its footer handle collapses and restores the Desk Workstation above it.
class WritingDock extends StatefulWidget {
  final QuillController controller;
  final QuillController Function()? onEnsureTextController;
  final VoidCallback onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback onToggleDictation;
  final VoidCallback? onShuffleSpark;
  final bool isDictating;
  final Color? backgroundColor;
  final Color? inkColor;
  final bool isPaperDark;
  final bool isWorkstationCollapsed;
  final VoidCallback? onToggleWorkstation;

  const WritingDock({
    super.key,
    required this.controller,
    this.onEnsureTextController,
    required this.onPickImage,
    this.onPickVideo,
    required this.onToggleDictation,
    this.onShuffleSpark,
    this.isDictating = false,
    this.backgroundColor,
    this.inkColor,
    this.isPaperDark = false,
    this.isWorkstationCollapsed = false,
    this.onToggleWorkstation,
  });

  @override
  State<WritingDock> createState() => _WritingDockState();
}

class _WritingDockState extends State<WritingDock> {
  bool _isFormattingOpen = false;
  bool _hasToggledThisDrag = false;

  /// With the keyboard open the workstation is already stepped aside, so the
  /// handle first dismisses the keyboard and only then restores a collapsed one.
  void _toggleWorkstation() {
    HapticFeedback.lightImpact();
    // The Scaffold strips the keyboard inset from its body, so read the view's.
    final isKeyboardOpen = View.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen) {
      FocusScope.of(context).unfocus();
      if (!widget.isWorkstationCollapsed) return;
    }
    widget.onToggleWorkstation?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final effectiveBackground = widget.backgroundColor ??
        (widget.isPaperDark
            ? tokens.xuanGround.withValues(alpha: 0.96)
            : tokens.xuanPureLeaf.withValues(alpha: 0.96));

    final effectiveInkColor = widget.inkColor ??
        (widget.isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF2D2D2D));

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

  Widget _buildWorkstationHandle(InkDiaryTokens tokens, Color effectiveInkColor) {
    final isCollapsed = widget.isWorkstationCollapsed;
    return Semantics(
      button: true,
      label: isCollapsed ? '展开画案' : '收起画案',
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('writing_dock_workstation_handle'),
        behavior: HitTestBehavior.opaque,
        onTap: _toggleWorkstation,
        onVerticalDragStart: (_) => _hasToggledThisDrag = false,
        onVerticalDragUpdate: (dragDetails) {
          final delta = dragDetails.primaryDelta;
          if (delta == null || _hasToggledThisDrag) return;
          // Pull up to raise the workstation, push down to put it away.
          if ((isCollapsed && delta < -6) || (!isCollapsed && delta > 6)) {
            _hasToggledThisDrag = true;
            _toggleWorkstation();
          }
        },
        child: Container(
          height: 22,
          width: double.infinity,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3.5,
                decoration: BoxDecoration(
                  color: tokens.deckleBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: isCollapsed ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: effectiveInkColor.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(InkDiaryTokens tokens, Color effectiveInkColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWorkstationHandle(tokens, effectiveInkColor),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.bottomCenter,
          child: _isFormattingOpen
              ? WritingDockFormattingRibbon(
                  controller: widget.controller,
                  onEnsureTextController: widget.onEnsureTextController,
                  tokens: tokens,
                  inkColor: effectiveInkColor,
                  isPaperDark: widget.isPaperDark,
                )
              : const SizedBox.shrink(),
        ),
        _buildPrimaryToolbar(tokens, effectiveInkColor),
      ],
    );
  }

  Widget _buildPrimaryToolbar(InkDiaryTokens tokens, Color effectiveInkColor) {
    final activeBackdrop = tokens.agedFiber.withValues(alpha: widget.isPaperDark ? 0.65 : 0.85);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
          _buildPrimaryToolBtn(
            key: const Key('writing_dock_dictation_btn'),
            icon: widget.isDictating ? Icons.mic : Icons.mic_none,
            tooltip: '原声听写 · Voice Dictation',
            isActive: widget.isDictating,
            color: widget.isDictating ? Colors.white : const Color(0xFFB83B2E),
            activeBackground: const Color(0xFFB83B2E),
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
    return Container(
      decoration: BoxDecoration(
        color: isActive ? (activeBackground ?? Colors.transparent) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        key: key,
        icon: Icon(
          icon,
          size: 21,
          color: color,
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
