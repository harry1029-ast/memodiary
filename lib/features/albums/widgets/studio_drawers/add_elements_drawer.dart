import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/album_studio_models.dart';
import '../../services/album_theme_catalog.dart';
import '../page_background_painter.dart';

/// Studio bottom drawer for inserting movable overlays onto the current page:
/// Date Stamp Pills, Custom Text Notes, Cinnabar Seal Stamps, and Vector Stickers.
///
/// Enforces Watchpoint 3 guard: the custom text note entry sheet pads with
/// `MediaQuery.of(context).viewInsets.bottom` so the soft keyboard never obscures
/// the input field or confirmation button.
class AddElementsDrawer extends StatefulWidget {
  final String defaultDateLabel;
  final int existingOverlayCount;
  final ValueChanged<PageOverlayElement> onAddOverlay;
  final VoidCallback? onImportPhoto;
  final VoidCallback onClose;

  const AddElementsDrawer({
    super.key,
    required this.defaultDateLabel,
    required this.existingOverlayCount,
    required this.onAddOverlay,
    this.onImportPhoto,
    required this.onClose,
  });

  @override
  State<AddElementsDrawer> createState() => _AddElementsDrawerState();
}

class _AddElementsDrawerState extends State<AddElementsDrawer> {
  StickerCategory _selectedCategory = StickerCategory.flora;

  String _nextOverlayId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${widget.existingOverlayCount + 1}';
  }

  void _handleInsertDatePill() {
    widget.onAddOverlay(
      PageOverlayElement(
        id: _nextOverlayId('date'),
        type: OverlayElementType.datePill,
        content: widget.defaultDateLabel,
        dx: 0.50,
        dy: 0.14,
        zIndex: widget.existingOverlayCount + 1,
      ),
    );
  }

  void _handleInsertSealStamp() {
    widget.onAddOverlay(
      PageOverlayElement(
        id: _nextOverlayId('seal'),
        type: OverlayElementType.sealStamp,
        content: '拾光',
        dx: 0.82,
        dy: 0.84,
        zIndex: widget.existingOverlayCount + 1,
      ),
    );
  }

  void _handleInsertSticker(StickerPreset preset) {
    widget.onAddOverlay(
      PageOverlayElement(
        id: _nextOverlayId('sticker'),
        type: OverlayElementType.sticker,
        content: preset.id,
        dx: 0.50,
        dy: 0.50,
        colorArgb: preset.defaultColorArgb,
        zIndex: widget.existingOverlayCount + 1,
      ),
    );
  }

  Future<void> _handleOpenTextNoteModal(BuildContext context) async {
    final textController = TextEditingController();
    final tokens = context.inkTokens;

    final enteredText = await showModalBottomSheet<String>(
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
                '添加手账文字批注',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('studio_text_overlay_input'),
                controller: textController,
                autofocus: true,
                maxLines: 2,
                maxLength: 60,
                decoration: InputDecoration(
                  hintText: '写下此刻的心境、地名或诗句…',
                  filled: true,
                  fillColor: tokens.agedFiber,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.deckleBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(modalContext).pop(),
                    child: Text(
                      '取消',
                      style: TextStyle(color: tokens.danmo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('studio_text_overlay_submit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.jiaomo,
                      foregroundColor: tokens.xuanPureLeaf,
                    ),
                    onPressed: () {
                      Navigator.of(modalContext)
                          .pop(textController.text.trim());
                    },
                    child: const Text('插入页面'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (enteredText == null || enteredText.isEmpty) return;

    widget.onAddOverlay(
      PageOverlayElement(
        id: _nextOverlayId('text'),
        type: OverlayElementType.text,
        content: enteredText,
        dx: 0.50,
        dy: 0.50,
        zIndex: widget.existingOverlayCount + 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final stickers = StickerCatalog.byCategory(_selectedCategory);

    return Container(
      key: const Key('studio_add_elements_drawer'),
      height: 256,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high_outlined,
                size: 18,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '添加手账元素 · Add Elements',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
              IconButton(
                key: const Key('close_add_drawer_button'),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.expand_more, color: tokens.danmo),
                tooltip: '收起面板',
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Quick-Insert Action Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickAddButton(
                  buttonKey: const Key('studio_add_date_pill'),
                  icon: Icons.event_note_outlined,
                  label: '日期胶囊',
                  tokens: tokens,
                  onTap: _handleInsertDatePill,
                ),
                const SizedBox(width: 8),
                _QuickAddButton(
                  buttonKey: const Key('studio_add_text_note'),
                  icon: Icons.text_fields,
                  label: '文字批注',
                  tokens: tokens,
                  onTap: () => _handleOpenTextNoteModal(context),
                ),
                const SizedBox(width: 8),
                _QuickAddButton(
                  buttonKey: const Key('studio_add_seal_stamp'),
                  icon: Icons.verified_outlined,
                  label: '朱印闲章',
                  tokens: tokens,
                  isAccent: true,
                  onTap: _handleInsertSealStamp,
                ),
                if (widget.onImportPhoto != null) ...[
                  const SizedBox(width: 8),
                  _QuickAddButton(
                    buttonKey: const Key('studio_add_import_photo'),
                    icon: Icons.add_photo_alternate_outlined,
                    label: '导入照片',
                    tokens: tokens,
                    onTap: widget.onImportPhoto!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Sticker Category Tabs
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: StickerCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final category = StickerCategory.values[index];
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  key: Key('sticker_cat_${category.name}'),
                  label: Text(
                    category.displayLabel,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11.5,
                      color: isSelected ? tokens.cinnabar : tokens.danmo,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: tokens.cinnabarWash,
                  backgroundColor: tokens.agedFiber,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Vector Stickers Row
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stickers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final preset = stickers[index];
                return InkWell(
                  key: Key('insert_sticker_${preset.id}'),
                  onTap: () => _handleInsertSticker(preset),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 82,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tokens.agedFiber,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.deckleBorder.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: CustomPaint(
                            painter: StickerElementPainter(
                              stickerId: preset.id,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 10.5,
                            color: tokens.nongmo,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String label;
  final InkDiaryTokens tokens;
  final bool isAccent;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.tokens,
    this.isAccent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isAccent ? tokens.cinnabarWash : tokens.agedFiber,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAccent
                ? tokens.cinnabar.withValues(alpha: 0.5)
                : tokens.deckleBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isAccent ? tokens.cinnabar : tokens.nongmo,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isAccent ? tokens.cinnabar : tokens.nongmo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
