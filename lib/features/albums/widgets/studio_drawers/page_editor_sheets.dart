import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../constants/album_studio_strings.dart';

/// Active bottom drawer tab in [AlbumPageEditorScreen].
enum StudioDrawerTab {
  removed,
  add,
  background,
  layout,
}

/// Opens a modal sheet to edit a page's custom date header string.
Future<String?> showPageDateHeaderSheet({
  required BuildContext context,
  String? initialText,
}) async {
  final tokens = context.inkTokens;
  final textController = TextEditingController(text: initialText ?? '');

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.xuanPureLeaf,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (modalContext) {
      final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '编辑书页日期标题',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.jiaomo,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('page_date_header_input'),
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '例如：2026.10.02 · 西湖秋日',
                filled: true,
                fillColor: tokens.agedFiber,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(modalContext).pop(),
                  child: Text('取消', style: TextStyle(color: tokens.danmo)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('page_date_header_submit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.jiaomo,
                    foregroundColor: tokens.xuanPureLeaf,
                  ),
                  onPressed: () =>
                      Navigator.of(modalContext).pop(textController.text),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  textController.dispose();
  return result;
}

/// Bottom tool dock for [AlbumPageEditorScreen] presenting Collection Box,
/// Add, Background, and Layout drawer tabs.
class StudioBottomDock extends StatelessWidget {
  final int removedCount;
  final StudioDrawerTab? activeTab;
  final ValueChanged<StudioDrawerTab> onToggleTab;

  const StudioBottomDock({
    super.key,
    required this.removedCount,
    required this.activeTab,
    required this.onToggleTab,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.xuanPureLeaf,
          border: Border(
            top: BorderSide(color: tokens.deckleBorder, width: 0.9),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _DockTabItem(
                tabKey: const Key('studio_tab_removed'),
                icon: Icons.inventory_2_outlined,
                label:
                    '${AlbumStudioStrings.collectionBoxDockTab} ($removedCount)',
                isSelected: activeTab == StudioDrawerTab.removed,
                tokens: tokens,
                onTap: () => onToggleTab(StudioDrawerTab.removed),
              ),
            ),
            Expanded(
              child: _DockTabItem(
                tabKey: const Key('studio_tab_add'),
                icon: Icons.add_circle_outline,
                label: 'Add',
                isSelected: activeTab == StudioDrawerTab.add,
                tokens: tokens,
                onTap: () => onToggleTab(StudioDrawerTab.add),
              ),
            ),
            Expanded(
              child: _DockTabItem(
                tabKey: const Key('studio_tab_background'),
                icon: Icons.palette_outlined,
                label: 'Background',
                isSelected: activeTab == StudioDrawerTab.background,
                tokens: tokens,
                onTap: () => onToggleTab(StudioDrawerTab.background),
              ),
            ),
            Expanded(
              child: _DockTabItem(
                tabKey: const Key('studio_tab_layout'),
                icon: Icons.dashboard_customize_outlined,
                label: 'Layout',
                isSelected: activeTab == StudioDrawerTab.layout,
                tokens: tokens,
                onTap: () => onToggleTab(StudioDrawerTab.layout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockTabItem extends StatelessWidget {
  final Key tabKey;
  final IconData icon;
  final String label;
  final bool isSelected;
  final InkDiaryTokens tokens;
  final VoidCallback onTap;

  const _DockTabItem({
    required this.tabKey,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isSelected ? tokens.cinnabar : tokens.nongmo;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        key: tabKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? tokens.cinnabarWash : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fgColor),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
