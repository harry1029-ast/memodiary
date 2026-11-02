import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/ink_diary_theme.dart';

/// Progressive inline formatting ribbon for WritingDock Tier 2.
/// Harmonized with paper-adaptive ink colors and scholar stationery styling.
class WritingDockFormattingRibbon extends StatelessWidget {
  final QuillController controller;
  final InkDiaryTokens tokens;
  final Color inkColor;
  final bool isPaperDark;

  const WritingDockFormattingRibbon({
    super.key,
    required this.controller,
    required this.tokens,
    required this.inkColor,
    required this.isPaperDark,
  });

  void _toggleFormat(Attribute attribute) {
    HapticFeedback.selectionClick();
    final isToggled = controller.getSelectionStyle().containsKey(attribute.key);
    if (isToggled) {
      controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      controller.formatSelection(attribute);
    }
  }

  void _insertInterlinearNote() {
    HapticFeedback.selectionClick();
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      final int offset = (selection.isValid && selection.baseOffset >= 0)
          ? selection.baseOffset
          : 0;
      controller.replaceText(offset, 0, '{夹注:}', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: offset + 4),
        ChangeSource.local,
      );
    } else {
      final plainText = controller.document.toPlainText();
      final startIndex = selection.start.clamp(0, plainText.length);
      final endIndex = selection.end.clamp(0, plainText.length);
      final selectedSubstring = plainText.substring(startIndex, endIndex);
      final replacementText = '{夹注:$selectedSubstring}';
      controller.replaceText(startIndex, endIndex - startIndex, replacementText, null);
      controller.updateSelection(
        TextSelection.collapsed(offset: startIndex + replacementText.length),
        ChangeSource.local,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: tokens.agedFiber.withValues(alpha: isPaperDark ? 0.25 : 0.40),
        border: Border(
          bottom: BorderSide(
            color: tokens.deckleBorder.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (ribbonContext, _) {
          final style = controller.getSelectionStyle();

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
                ),
                // Italic
                _buildFormatTextBtn(
                  label: 'I',
                  isItalic: true,
                  isActive: style.containsKey(Attribute.italic.key),
                  onTap: () => _toggleFormat(Attribute.italic),
                  tooltip: '斜体 · Italic',
                ),
                // Underline
                _buildFormatTextBtn(
                  label: 'U',
                  isUnderline: true,
                  isActive: style.containsKey(Attribute.underline.key),
                  onTap: () => _toggleFormat(Attribute.underline),
                  tooltip: '下划线 · Underline',
                ),

                _buildDivider(),

                // Heading 1
                _buildFormatTextBtn(
                  label: 'T',
                  isHeading: true,
                  isActive: style.containsKey(Attribute.h1.key),
                  onTap: () => _toggleFormat(Attribute.h1),
                  tooltip: '大标题 · Heading 1',
                ),
                // Heading 2
                _buildFormatTextBtn(
                  label: 'Tt',
                  isHeading: false,
                  isActive: style.containsKey(Attribute.h2.key),
                  onTap: () => _toggleFormat(Attribute.h2),
                  tooltip: '次标题 · Heading 2',
                ),
                // Blockquote
                _buildFormatIconBtn(
                  icon: Icons.format_quote,
                  isActive: style.containsKey(Attribute.blockQuote.key),
                  onTap: () => _toggleFormat(Attribute.blockQuote),
                  tooltip: '引用 · Quote',
                ),

                _buildDivider(),

                // Bullet List
                _buildFormatIconBtn(
                  icon: Icons.format_list_bulleted,
                  isActive: style.containsKey(Attribute.ul.key),
                  onTap: () => _toggleFormat(Attribute.ul),
                  tooltip: '无序列表 · Bullet List',
                ),
                // Numbered List
                _buildFormatIconBtn(
                  icon: Icons.format_list_numbered,
                  isActive: style.containsKey(Attribute.ol.key),
                  onTap: () => _toggleFormat(Attribute.ol),
                  tooltip: '有序列表 · Numbered List',
                ),

                _buildDivider(),

                // Interlinear Note (双行夹注)
                _buildFormatTextBtn(
                  buttonKey: const Key('writing_dock_interlinear_note_btn'),
                  label: '〘注〙',
                  isActive: false,
                  onTap: _insertInterlinearNote,
                  tooltip: '双行夹注 · Interlinear Note',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: tokens.deckleBorder.withValues(alpha: 0.6),
    );
  }

  Widget _buildFormatTextBtn({
    Key? buttonKey,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isHeading = false,
  }) {
    final activeBg = tokens.agedFiber.withValues(alpha: isPaperDark ? 0.75 : 0.95);
    final activeFg = isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        key: buttonKey,
        icon: Text(
          label,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: isHeading ? 15 : (label.length > 2 ? 11.5 : 13.5),
            fontWeight: isBold || isHeading ? FontWeight.bold : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            color: isActive ? activeFg : inkColor,
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
  }) {
    final activeBg = tokens.agedFiber.withValues(alpha: isPaperDark ? 0.75 : 0.95);
    final activeFg = isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isActive ? activeFg : inkColor,
        ),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

