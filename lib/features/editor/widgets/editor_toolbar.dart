import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';

/// Clean literati diary toolbar providing rich-text formatting and multimodal entry tools
class EditorToolbar extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback onToggleDictation;
  final VoidCallback onOpenTypography;
  final VoidCallback onOpenTemplates;
  final VoidCallback? onOpenSoundscapes;
  final bool isDictating;
  final bool isSoundscapePlaying;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onPickImage,
    this.onPickVideo,
    required this.onToggleDictation,
    required this.onOpenTypography,
    required this.onOpenTemplates,
    this.onOpenSoundscapes,
    this.isDictating = false,
    this.isSoundscapePlaying = false,
  });

  void _toggleFormat(Attribute attribute) {
    final isToggled = controller.getSelectionStyle().containsKey(attribute.key);
    if (isToggled) {
      controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      controller.formatSelection(attribute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: tokens.xuanGround.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: tokens.agedFiber,
            width: 1.0,
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final style = controller.getSelectionStyle();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // Bold (B)
                _buildTextBtn(
                  label: 'B',
                  isBold: true,
                  isActive: style.containsKey(Attribute.bold.key),
                  onTap: () => _toggleFormat(Attribute.bold),
                  tooltip: '加粗 · Bold',
                  tokens: tokens,
                ),
                // Italic (I)
                _buildTextBtn(
                  label: 'I',
                  isItalic: true,
                  isActive: style.containsKey(Attribute.italic.key),
                  onTap: () => _toggleFormat(Attribute.italic),
                  tooltip: '斜体 · Italic',
                  tokens: tokens,
                ),
                // Underline (U)
                _buildTextBtn(
                  label: 'U',
                  isUnderline: true,
                  isActive: style.containsKey(Attribute.underline.key),
                  onTap: () => _toggleFormat(Attribute.underline),
                  tooltip: '下划线 · Underline',
                  tokens: tokens,
                ),
                // Strikethrough (S)
                _buildIconBtn(
                  icon: Icons.strikethrough_s,
                  isActive: style.containsKey(Attribute.strikeThrough.key),
                  onTap: () => _toggleFormat(Attribute.strikeThrough),
                  tooltip: '删除线 · Strikethrough',
                  tokens: tokens,
                ),
                _buildDivider(tokens),

                // Heading 1 (T)
                _buildTextBtn(
                  label: 'T',
                  isHeading: true,
                  isActive: style.containsKey(Attribute.h1.key),
                  onTap: () => _toggleFormat(Attribute.h1),
                  tooltip: '大标题 · Heading 1',
                  tokens: tokens,
                ),
                // Heading 2 (Tt)
                _buildTextBtn(
                  label: 'Tt',
                  isHeading: false,
                  isActive: style.containsKey(Attribute.h2.key),
                  onTap: () => _toggleFormat(Attribute.h2),
                  tooltip: '次标题 · Heading 2',
                  tokens: tokens,
                ),
                // Blockquote ("")
                _buildIconBtn(
                  icon: Icons.format_quote,
                  isActive: style.containsKey(Attribute.blockQuote.key),
                  onTap: () => _toggleFormat(Attribute.blockQuote),
                  tooltip: '引用 · Quote',
                  tokens: tokens,
                ),
                // Bullet List
                _buildIconBtn(
                  icon: Icons.format_list_bulleted,
                  isActive: style.containsKey(Attribute.ul.key),
                  onTap: () => _toggleFormat(Attribute.ul),
                  tooltip: '无序列表 · Bullet List',
                  tokens: tokens,
                ),
                // Numbered List
                _buildIconBtn(
                  icon: Icons.format_list_numbered,
                  isActive: style.containsKey(Attribute.ol.key),
                  onTap: () => _toggleFormat(Attribute.ol),
                  tooltip: '有序列表 · Numbered List',
                  tokens: tokens,
                ),
                _buildDivider(tokens),

                // Multimodal: Image Pick
                _buildIconBtn(
                  icon: Icons.add_photo_alternate_outlined,
                  isActive: false,
                  onTap: onPickImage,
                  tooltip: '插入图画 · Insert Photo',
                  tokens: tokens,
                  color: tokens.nongmo,
                ),
                // Multimodal: Video Pick
                if (onPickVideo != null)
                  _buildIconBtn(
                    icon: Icons.videocam_outlined,
                    isActive: false,
                    onTap: onPickVideo!,
                    tooltip: '插入短视频 · Short Video (≤60s)',
                    tokens: tokens,
                    color: tokens.nongmo,
                  ),
                // Multimodal: Speech Dictation
                _buildIconBtn(
                  icon: isDictating ? Icons.mic : Icons.mic_none,
                  isActive: isDictating,
                  onTap: onToggleDictation,
                  tooltip: '原声听写 · Voice Dictation',
                  tokens: tokens,
                  color: isDictating ? Colors.white : tokens.cinnabar,
                  backgroundColor: isDictating ? tokens.cinnabar : null,
                ),
                // Typography Settings
                _buildIconBtn(
                  icon: Icons.font_download_outlined,
                  isActive: false,
                  onTap: onOpenTypography,
                  tooltip: '字法排印 · Typography',
                  tokens: tokens,
                ),
                // Template Switcher
                _buildIconBtn(
                  icon: Icons.style_outlined,
                  isActive: false,
                  onTap: onOpenTemplates,
                  tooltip: '素笺信札 · Templates',
                  tokens: tokens,
                ),
                // Writing Sanctum Soundscapes
                if (onOpenSoundscapes != null)
                  _buildIconBtn(
                    icon: isSoundscapePlaying
                        ? Icons.headphones_rounded
                        : Icons.headphones_outlined,
                    isActive: isSoundscapePlaying,
                    onTap: onOpenSoundscapes!,
                    tooltip: '砚边清韵 · Soundscapes',
                    tokens: tokens,
                    color: isSoundscapePlaying ? tokens.cinnabar : null,
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
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: tokens.agedFiber,
    );
  }

  Widget _buildTextBtn({
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Text(
          label,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: isHeading ? 16 : 14,
            fontWeight: isBold || isHeading ? FontWeight.bold : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            color: isActive ? tokens.jiaomo : tokens.nongmo,
          ),
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
    required InkDiaryTokens tokens,
    Color? color,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isActive ? tokens.agedFiber : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 19,
          color: color ?? (isActive ? tokens.jiaomo : tokens.nongmo),
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
