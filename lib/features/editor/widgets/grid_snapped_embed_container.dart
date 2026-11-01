import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Wraps embedded photos and short videos in an Integer-Row Height Snapper
/// and Tipped-In Ephemera Card (贴片拓影), ensuring text below never drifts off ruled baselines.
class GridSnappedEmbedContainer extends StatefulWidget {
  final double rowHeight;
  final String aspect; // 'auto', '4:3', '1:1'
  final String caption;
  final bool readOnly;
  final VoidCallback? onRemove;
  final ValueChanged<String>? onCaptionChanged;
  final ValueChanged<String>? onAspectChanged;
  final Widget child;

  const GridSnappedEmbedContainer({
    super.key,
    this.rowHeight = 28.0,
    this.aspect = 'auto',
    this.caption = '',
    this.readOnly = false,
    this.onRemove,
    this.onCaptionChanged,
    this.onAspectChanged,
    required this.child,
  });

  @override
  State<GridSnappedEmbedContainer> createState() => _GridSnappedEmbedContainerState();
}

class _GridSnappedEmbedContainerState extends State<GridSnappedEmbedContainer> {
  bool _isActionActive = false;

  double _resolveAspectRatio(double defaultRatio) {
    switch (widget.aspect) {
      case '4:3':
        return 4.0 / 3.0;
      case '1:1':
        return 1.0;
      case 'auto':
      default:
        return defaultRatio.clamp(4.0 / 5.0, 16.0 / 9.0);
    }
  }

  void _cycleAspectRatio() {
    String nextAspect;
    switch (widget.aspect) {
      case 'auto':
        nextAspect = '4:3';
        break;
      case '4:3':
        nextAspect = '1:1';
        break;
      case '1:1':
      default:
        nextAspect = 'auto';
        break;
    }
    widget.onAspectChanged?.call(nextAspect);
  }

  Future<void> _showCaptionDialog(BuildContext context, InkDiaryTokens tokens) async {
    final controller = TextEditingController(text: widget.caption);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: tokens.ricePaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.agedFiber),
        ),
        title: Text(
          '题跋批注 · Caption',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
          ),
        ),
        content: TextField(
          key: const Key('media_card_caption_input'),
          controller: controller,
          maxLength: 60,
          autofocus: true,
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontKaiti,
            color: tokens.jiaomo,
          ),
          decoration: InputDecoration(
            hintText: '写下画幅题跋...',
            filled: true,
            fillColor: tokens.xuanGround,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.agedFiber),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('取消', style: TextStyle(color: tokens.danmo)),
          ),
          FilledButton(
            key: const Key('media_card_caption_save_button'),
            style: FilledButton.styleFrom(backgroundColor: tokens.cinnabar),
            onPressed: () {
              widget.onCaptionChanged?.call(controller.text.trim());
              Navigator.pop(dialogCtx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final rowHeight = widget.rowHeight > 0 ? widget.rowHeight : 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 320.0;

        final ar = _resolveAspectRatio(16.0 / 9.0);
        final hasCaption = widget.caption.trim().isNotEmpty;
        final captionHeight = hasCaption ? 28.0 : 0.0;

        // Raw inner media content height
        final rawHeight = contentWidth / ar + captionHeight;

        // Snapped integer rows: N = max(3, ceil((rawHeight + 24.0) / rowHeight))
        final n = math.max(3, ((rawHeight + 24.0) / rowHeight).ceil());
        final totalHeight = n * rowHeight;
        final surplus = math.max(0.0, totalHeight - rawHeight);
        final padVertical = surplus / 2.0;

        return Semantics(
          container: true,
          label: '贴片拓影: ${hasCaption ? widget.caption : "无题跋"}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contextual floating action bar directly above card
              if (!widget.readOnly && _isActionActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: _buildActionBar(tokens),
                ),

              // Integer-snapped outer container
              GestureDetector(
                key: const Key('grid_snapped_media_card'),
                onTap: widget.readOnly
                    ? null
                    : () {
                        setState(() {
                          _isActionActive = !_isActionActive;
                        });
                      },
                child: Container(
                  height: totalHeight,
                  width: contentWidth,
                  padding: EdgeInsets.symmetric(vertical: padVertical, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: tokens.ricePaper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isActionActive ? tokens.cinnabar : tokens.agedFiber,
                      width: _isActionActive ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.jiaomo.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Media child inside rounded print border
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.child,
                        ),
                      ),

                      // Optional caption text
                      if (hasCaption) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 12,
                            color: tokens.danmo,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionBar(InkDiaryTokens tokens) {
    return Container(
      key: const Key('media_card_action_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.xuanGround,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.agedFiber),
        boxShadow: [
          BoxShadow(
            color: tokens.jiaomo.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Caption button
            TextButton.icon(
              key: const Key('media_card_caption_button'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.jiaomo,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.edit_note_outlined, size: 16, color: tokens.cinnabar),
              label: const Text('题跋', style: TextStyle(fontSize: 12)),
              onPressed: () => _showCaptionDialog(context, tokens),
            ),
            const SizedBox(width: 4),
            Container(width: 1, height: 12, color: tokens.agedFiber),
            const SizedBox(width: 4),

            // Aspect button
            TextButton.icon(
              key: const Key('media_card_aspect_button'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.jiaomo,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.aspect_ratio_outlined, size: 16, color: tokens.cinnabar),
              label: Text(
                widget.aspect == 'auto'
                    ? '画幅: 自动'
                    : (widget.aspect == '4:3' ? '画幅: 4:3' : '画幅: 1:1'),
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: _cycleAspectRatio,
            ),
            const SizedBox(width: 4),
            Container(width: 1, height: 12, color: tokens.agedFiber),
            const SizedBox(width: 4),

            // Remove button
            TextButton.icon(
              key: const Key('media_card_remove_button'),
              style: TextButton.styleFrom(
                foregroundColor: tokens.cinnabar,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.delete_outline, size: 16, color: tokens.cinnabar),
              label: const Text('移除', style: TextStyle(fontSize: 12)),
              onPressed: widget.onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
