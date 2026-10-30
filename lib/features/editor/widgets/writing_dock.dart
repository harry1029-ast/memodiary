import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';

/// Progressive two-tier bottom writing dock anchored above the soft keyboard.
/// Tier 1 presents 5 high-frequency tools: Aa Formatting, Photo, Video, Dictation, Spark.
/// Tier 2 smoothly unfolds on-demand as an inline formatting ribbon.
class WritingDock extends StatefulWidget {
  final QuillController controller;
  final VoidCallback onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback onToggleDictation;
  final VoidCallback? onShuffleSpark;
  final bool isDictating;
  final Color? backgroundColor;

  const WritingDock({
    super.key,
    required this.controller,
    required this.onPickImage,
    this.onPickVideo,
    required this.onToggleDictation,
    this.onShuffleSpark,
    this.isDictating = false,
    this.backgroundColor,
  });

  @override
  State<WritingDock> createState() => _WritingDockState();
}

class _WritingDockState extends State<WritingDock> {
  bool _isFormattingOpen = false;

  void _toggleFormat(Attribute attribute) {
    HapticFeedback.selectionClick();
    final isToggled = widget.controller.getSelectionStyle().containsKey(attribute.key);
    if (isToggled) {
      widget.controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      widget.controller.formatSelection(attribute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final effectiveBackground = widget.backgroundColor ?? tokens.xuanGround.withValues(alpha: 0.96);

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tier 2: Inline Formatting Ribbon (Expands on demand)
            if (_isFormattingOpen) _buildFormattingRibbon(tokens),

            // Tier 1: 5 Primary High-Frequency Tools
            _buildPrimaryToolbar(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryToolbar(InkDiaryTokens tokens) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. [Aa 字法] (Formatting Drawer Toggle)
          _buildPrimaryToolBtn(
            key: const Key('writing_dock_format_btn'),
            icon: Icons.text_fields_rounded,
            tooltip: '字法排印 · Formatting',
            isActive: _isFormattingOpen,
            tokens: tokens,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isFormattingOpen = !_isFormattingOpen);
            },
          ),

          // 2. [📷 拓影] (Sandboxed Photo)
          _buildPrimaryToolBtn(
            key: const Key('writing_dock_photo_btn'),
            icon: Icons.add_photo_alternate_outlined,
            tooltip: '插入图画 · Insert Photo',
            isActive: false,
            tokens: tokens,
            onTap: widget.onPickImage,
          ),

          // 3. [🎥 短影] (Sandboxed Video)
          if (widget.onPickVideo != null)
            _buildPrimaryToolBtn(
              key: const Key('writing_dock_video_btn'),
              icon: Icons.videocam_outlined,
              tooltip: '插入短影 · Short Video (≤60s)',
              isActive: false,
              tokens: tokens,
              onTap: widget.onPickVideo!,
            ),

          // 4. [🎙️ 听写] (Speech Dictation)
          _buildPrimaryToolBtn(
            key: const Key('writing_dock_dictation_btn'),
            icon: widget.isDictating ? Icons.mic : Icons.mic_none,
            tooltip: '原声听写 · Voice Dictation',
            isActive: widget.isDictating,
            activeColor: Colors.white,
            activeBackground: tokens.cinnabar,
            tokens: tokens,
            onTap: widget.onToggleDictation,
          ),

          // 5. [✨ 灵感] (Thought Spark Prompt)
          if (widget.onShuffleSpark != null)
            _buildPrimaryToolBtn(
              key: const Key('writing_dock_spark_btn'),
              icon: Icons.auto_awesome_outlined,
              tooltip: '灵感拾遗 · Thought Spark',
              isActive: false,
              tokens: tokens,
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
    required InkDiaryTokens tokens,
    required VoidCallback onTap,
    Color? activeColor,
    Color? activeBackground,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? (activeBackground ?? tokens.agedFiber)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        key: key,
        icon: Icon(
          icon,
          size: 21,
          color: isActive
              ? (activeColor ?? tokens.jiaomo)
              : tokens.nongmo,
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFormattingRibbon(InkDiaryTokens tokens) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: tokens.agedFiber.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: tokens.agedFiber,
            width: 0.8,
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final style = widget.controller.getSelectionStyle();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Bold
                _buildFormatTextBtn(
                  label: 'B',
                  isBold: true,
                  isActive: style.containsKey(Attribute.bold.key),
                  onTap: () => _toggleFormat(Attribute.bold),
                  tooltip: '加粗 · Bold',
                  tokens: tokens,
                ),
                // Italic
                _buildFormatTextBtn(
                  label: 'I',
                  isItalic: true,
                  isActive: style.containsKey(Attribute.italic.key),
                  onTap: () => _toggleFormat(Attribute.italic),
                  tooltip: '斜体 · Italic',
                  tokens: tokens,
                ),
                // Underline
                _buildFormatTextBtn(
                  label: 'U',
                  isUnderline: true,
                  isActive: style.containsKey(Attribute.underline.key),
                  onTap: () => _toggleFormat(Attribute.underline),
                  tooltip: '下划线 · Underline',
                  tokens: tokens,
                ),
                // Strikethrough
                _buildFormatIconBtn(
                  icon: Icons.strikethrough_s,
                  isActive: style.containsKey(Attribute.strikeThrough.key),
                  onTap: () => _toggleFormat(Attribute.strikeThrough),
                  tooltip: '删除线 · Strikethrough',
                  tokens: tokens,
                ),

                _buildDivider(tokens),

                // Heading 1
                _buildFormatTextBtn(
                  label: 'T',
                  isHeading: true,
                  isActive: style.containsKey(Attribute.h1.key),
                  onTap: () => _toggleFormat(Attribute.h1),
                  tooltip: '大标题 · Heading 1',
                  tokens: tokens,
                ),
                // Heading 2
                _buildFormatTextBtn(
                  label: 'Tt',
                  isHeading: false,
                  isActive: style.containsKey(Attribute.h2.key),
                  onTap: () => _toggleFormat(Attribute.h2),
                  tooltip: '次标题 · Heading 2',
                  tokens: tokens,
                ),
                // Blockquote
                _buildFormatIconBtn(
                  icon: Icons.format_quote,
                  isActive: style.containsKey(Attribute.blockQuote.key),
                  onTap: () => _toggleFormat(Attribute.blockQuote),
                  tooltip: '引用 · Quote',
                  tokens: tokens,
                ),

                _buildDivider(tokens),

                // Bullet List
                _buildFormatIconBtn(
                  icon: Icons.format_list_bulleted,
                  isActive: style.containsKey(Attribute.ul.key),
                  onTap: () => _toggleFormat(Attribute.ul),
                  tooltip: '无序列表 · Bullet List',
                  tokens: tokens,
                ),
                // Numbered List
                _buildFormatIconBtn(
                  icon: Icons.format_list_numbered,
                  isActive: style.containsKey(Attribute.ol.key),
                  onTap: () => _toggleFormat(Attribute.ol),
                  tooltip: '有序列表 · Numbered List',
                  tokens: tokens,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider(InkDiaryTokens tokens) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: tokens.agedFiber,
    );
  }

  Widget _buildFormatTextBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
    required InkDiaryTokens tokens,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isHeading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? tokens.agedFiber : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Text(
          label,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: isHeading ? 15 : 13.5,
            fontWeight: isBold || isHeading ? FontWeight.bold : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            color: isActive ? tokens.jiaomo : tokens.nongmo,
          ),
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFormatIconBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
    required InkDiaryTokens tokens,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? tokens.agedFiber : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isActive ? tokens.jiaomo : tokens.nongmo,
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
