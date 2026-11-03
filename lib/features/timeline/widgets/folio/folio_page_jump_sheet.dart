import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import 'folio_leaf_model.dart';

/// Modal bottom sheet allowing users to jump directly to any leaf in the folio.
class FolioPageJumpSheet extends StatelessWidget {
  final List<FolioLeaf> leaves;
  final int currentIndex;
  final ValueChanged<int> onPageSelected;

  const FolioPageJumpSheet({
    super.key,
    required this.leaves,
    required this.currentIndex,
    required this.onPageSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<FolioLeaf> leaves,
    required int currentIndex,
    required ValueChanged<int> onPageSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FolioPageJumpSheet(
        leaves: leaves,
        currentIndex: currentIndex,
        onPageSelected: onPageSelected,
      ),
    );
  }

  String _leafLabel(FolioLeaf leaf, int index) {
    if (leaf is FolioFrontispieceCoverLeaf) {
      return '扉页 · 题跋与气象';
    }
    if (leaf is FolioTippedInEphemeraLeaf) {
      return leaf.mediaType == 'video' ? '插页 · 影像珍藏' : '插页 · 拓影图画';
    }
    if (leaf is FolioContentBodyLeaf) {
      return leaf.isConcludingLeaf ? '末卷 · 落款题印' : '正卷 · 第 ${leaf.pageIndexInContent} 节';
    }
    return '手稿第 ${index + 1} 页';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1D1B),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Color(0x33D4AF37), width: 1.0),
          ),
        ),
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40D4AF37),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Text(
                '展卷索引 · 翻转至特定页',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFAF7F0),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: leaves.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0x1AD4AF37), height: 1),
              itemBuilder: (context, index) {
                final isCurrent = index == currentIndex;
                final label = _leafLabel(leaves[index], index);

                return ListTile(
                  key: Key('folio_jump_page_tile_$index'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: isCurrent ? const Color(0xFFB83B2E) : const Color(0x26D4AF37),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? Colors.white : const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 14,
                      color: isCurrent ? const Color(0xFFFAF7F0) : const Color(0xFFB3ADA3),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFFD4AF37))
                      : const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0x40D4AF37)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    if (!isCurrent) {
                      onPageSelected(index);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}
