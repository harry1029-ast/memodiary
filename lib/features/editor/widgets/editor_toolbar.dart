import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Clean diary toolbar providing rich-text formatting and multimodal entry tools
class EditorToolbar extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onPickImage;
  final VoidCallback onToggleDictation;
  final VoidCallback onOpenTypography;
  final VoidCallback onOpenTemplates;
  final bool isDictating;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onPickImage,
    required this.onToggleDictation,
    required this.onOpenTypography,
    required this.onOpenTemplates,
    this.isDictating = false,
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final style = controller.getSelectionStyle();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Bold
                _buildToolbarBtn(
                  icon: Icons.format_bold,
                  isActive: style.containsKey(Attribute.bold.key),
                  onTap: () => _toggleFormat(Attribute.bold),
                  tooltip: 'Bold',
                ),
                // Italic
                _buildToolbarBtn(
                  icon: Icons.format_italic,
                  isActive: style.containsKey(Attribute.italic.key),
                  onTap: () => _toggleFormat(Attribute.italic),
                  tooltip: 'Italic',
                ),
                // Underline
                _buildToolbarBtn(
                  icon: Icons.format_underlined,
                  isActive: style.containsKey(Attribute.underline.key),
                  onTap: () => _toggleFormat(Attribute.underline),
                  tooltip: 'Underline',
                ),
                // Strikethrough
                _buildToolbarBtn(
                  icon: Icons.strikethrough_s,
                  isActive: style.containsKey(Attribute.strikeThrough.key),
                  onTap: () => _toggleFormat(Attribute.strikeThrough),
                  tooltip: 'Strikethrough',
                ),
                const VerticalDivider(indent: 10, endIndent: 10, width: 16),

                // Heading 1
                _buildToolbarBtn(
                  icon: Icons.title,
                  isActive: style.containsKey(Attribute.h1.key),
                  onTap: () => _toggleFormat(Attribute.h1),
                  tooltip: 'Heading 1',
                ),
                // Heading 2
                _buildToolbarBtn(
                  icon: Icons.text_fields,
                  isActive: style.containsKey(Attribute.h2.key),
                  onTap: () => _toggleFormat(Attribute.h2),
                  tooltip: 'Heading 2',
                ),
                // Blockquote
                _buildToolbarBtn(
                  icon: Icons.format_quote,
                  isActive: style.containsKey(Attribute.blockQuote.key),
                  onTap: () => _toggleFormat(Attribute.blockQuote),
                  tooltip: 'Quote',
                ),
                // Bullet List
                _buildToolbarBtn(
                  icon: Icons.format_list_bulleted,
                  isActive: style.containsKey(Attribute.ul.key),
                  onTap: () => _toggleFormat(Attribute.ul),
                  tooltip: 'Bullet List',
                ),
                // Numbered List
                _buildToolbarBtn(
                  icon: Icons.format_list_numbered,
                  isActive: style.containsKey(Attribute.ol.key),
                  onTap: () => _toggleFormat(Attribute.ol),
                  tooltip: 'Numbered List',
                ),
                const VerticalDivider(indent: 10, endIndent: 10, width: 16),

                // Multimodal: Image Pick
                _buildToolbarBtn(
                  icon: Icons.add_photo_alternate_outlined,
                  isActive: false,
                  onTap: onPickImage,
                  tooltip: 'Insert Photo',
                  color: Colors.blue.shade700,
                ),
                // Multimodal: Speech to Text
                _buildToolbarBtn(
                  icon: isDictating ? Icons.mic : Icons.mic_none,
                  isActive: isDictating,
                  onTap: onToggleDictation,
                  tooltip: 'Voice Dictation',
                  color: isDictating ? Colors.white : Colors.deepPurple,
                  backgroundColor: isDictating ? Colors.deepPurple : null,
                ),
                // Typography Settings
                _buildToolbarBtn(
                  icon: Icons.font_download_outlined,
                  isActive: false,
                  onTap: onOpenTypography,
                  tooltip: 'Typography',
                ),
                // Template Switcher
                _buildToolbarBtn(
                  icon: Icons.style_outlined,
                  isActive: false,
                  onTap: onOpenTemplates,
                  tooltip: 'Templates',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbarBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isActive ? Colors.grey.shade200 : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: color ?? (isActive ? Colors.black87 : Colors.grey.shade700),
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

