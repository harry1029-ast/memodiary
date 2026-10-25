import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../../core/theme/widgets/cinnabar_seal_badge.dart';
import '../../models/album_studio_models.dart';
import '../page_background_painter.dart';

/// Renders an individual [PageOverlayElement] (`sticker`, `text`, `datePill`, `sealStamp`)
/// on the scrapbook page canvas.
///
/// Enforces `HitTestBehavior.opaque` strictly within the overlay bounding box when
/// [isInteractive] is true so dragging an overlay never triggers underlying photo slots
/// or outer page swipes.
class DraggableOverlayItem extends StatefulWidget {
  final PageOverlayElement overlay;
  final Size canvasSize;
  final int defaultTextColorArgb;
  final bool isInteractive;
  final bool isSelected;
  final VoidCallback? onSelect;
  final ValueChanged<PageOverlayElement>? onUpdate;
  final VoidCallback? onDelete;

  const DraggableOverlayItem({
    super.key,
    required this.overlay,
    required this.canvasSize,
    required this.defaultTextColorArgb,
    this.isInteractive = true,
    this.isSelected = false,
    this.onSelect,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<DraggableOverlayItem> createState() => _DraggableOverlayItemState();
}

class _DraggableOverlayItemState extends State<DraggableOverlayItem> {
  Offset _dragOffset = Offset.zero;

  @override
  void didUpdateWidget(covariant DraggableOverlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay) {
      _dragOffset = Offset.zero;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isInteractive || widget.onUpdate == null) return;
    if (_dragOffset == Offset.zero) return;

    final width = math.max(1.0, widget.canvasSize.width);
    final height = math.max(1.0, widget.canvasSize.height);
    final nextDx =
        (widget.overlay.dx + (_dragOffset.dx / width)).clamp(0.06, 0.94);
    final nextDy =
        (widget.overlay.dy + (_dragOffset.dy / height)).clamp(0.06, 0.94);

    setState(() {
      _dragOffset = Offset.zero;
    });

    widget.onUpdate!(
      widget.overlay.copyWith(
        dx: nextDx,
        dy: nextDy,
      ),
    );
  }

  void _adjustScale(double delta) {
    if (widget.onUpdate == null) return;
    final nextScale = (widget.overlay.scale + delta).clamp(0.5, 2.5);
    widget.onUpdate!(widget.overlay.copyWith(scale: nextScale));
  }

  void _adjustRotation() {
    if (widget.onUpdate == null) return;
    final nextRotation = widget.overlay.rotation + (math.pi / 12);
    widget.onUpdate!(widget.overlay.copyWith(rotation: nextRotation));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final baseUnit = widget.canvasSize.shortestSide;
    final centerPx = Offset(
      widget.overlay.dx * widget.canvasSize.width + _dragOffset.dx,
      widget.overlay.dy * widget.canvasSize.height + _dragOffset.dy,
    );

    final contentWidget = Transform.rotate(
      angle: widget.overlay.rotation,
      child: Transform.scale(
        scale: widget.overlay.scale,
        child: _buildOverlayVisual(tokens, baseUnit),
      ),
    );

    if (!widget.isInteractive) {
      return Positioned(
        left: centerPx.dx - baseUnit * 0.22,
        top: centerPx.dy - baseUnit * 0.12,
        width: baseUnit * 0.44,
        height: baseUnit * 0.24,
        child: IgnorePointer(
          child: Center(child: contentWidget),
        ),
      );
    }

    final boxWidth = math.max(132.0, baseUnit * 0.48);
    final baseHeight = math.max(68.0, baseUnit * 0.28);
    final toolbarExtra = widget.isSelected ? 34.0 : 0.0;
    final boxHeight = baseHeight + toolbarExtra;

    return Positioned(
      left: centerPx.dx - boxWidth / 2,
      top: centerPx.dy - baseHeight / 2 - toolbarExtra,
      width: boxWidth,
      height: boxHeight,
      child: GestureDetector(
        key: Key('overlay_item_${widget.overlay.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: boxWidth,
              height: baseHeight,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: widget.isSelected
                      ? BoxDecoration(
                          border: Border.all(
                            color: tokens.cinnabar,
                            width: 1.4,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: tokens.xuanPureLeaf.withValues(alpha: 0.22),
                        )
                      : null,
                  child: contentWidget,
                ),
              ),
            ),
            if (widget.isSelected)
              Positioned(
                top: 0,
                child: Material(
                  color: tokens.jiaomo.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  elevation: 3,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniIconBtn(
                          buttonKey:
                              Key('overlay_scale_down_${widget.overlay.id}'),
                          icon: Icons.remove,
                          tooltip: '缩小',
                          onTap: () => _adjustScale(-0.15),
                        ),
                        _MiniIconBtn(
                          buttonKey:
                              Key('overlay_scale_up_${widget.overlay.id}'),
                          icon: Icons.add,
                          tooltip: '放大',
                          onTap: () => _adjustScale(0.15),
                        ),
                        _MiniIconBtn(
                          buttonKey:
                              Key('overlay_rotate_${widget.overlay.id}'),
                          icon: Icons.rotate_right,
                          tooltip: '旋转',
                          onTap: _adjustRotation,
                        ),
                        if (widget.onDelete != null)
                          _MiniIconBtn(
                            buttonKey:
                                Key('delete_overlay_${widget.overlay.id}'),
                            icon: Icons.close,
                            color: const Color(0xFFFF8A80),
                            tooltip: '移除元素',
                            onTap: widget.onDelete!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayVisual(InkDiaryTokens tokens, double baseUnit) {
    final effectiveColor = Color(
      widget.overlay.colorArgb ?? widget.defaultTextColorArgb,
    );

    switch (widget.overlay.type) {
      case OverlayElementType.sticker:
        final stickerSize = math.max(24.0, baseUnit * 0.15);
        return SizedBox(
          width: stickerSize,
          height: stickerSize,
          child: CustomPaint(
            painter: StickerElementPainter(
              stickerId: widget.overlay.content,
              colorOverrideArgb: widget.overlay.colorArgb,
            ),
          ),
        );

      case OverlayElementType.datePill:
        final fontSize = math.max(8.0, baseUnit * 0.034);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: math.max(6.0, baseUnit * 0.03),
            vertical: math.max(2.0, baseUnit * 0.01),
          ),
          decoration: BoxDecoration(
            color: tokens.xuanPureLeaf.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.55),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: fontSize,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.overlay.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: effectiveColor,
                  ),
                ),
              ),
            ],
          ),
        );

      case OverlayElementType.text:
        final fontSize = math.max(9.0, baseUnit * 0.042);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            widget.overlay.content,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: effectiveColor,
              height: 1.35,
            ),
          ),
        );

      case OverlayElementType.sealStamp:
        final sealSize = math.max(22.0, baseUnit * 0.11);
        return CinnabarSealBadge.compact(
          text: widget.overlay.content.isEmpty ? '拾光' : widget.overlay.content,
          size: sealSize,
        );
    }
  }
}

class _MiniIconBtn extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _MiniIconBtn({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
