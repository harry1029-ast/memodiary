import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/album_studio_models.dart';
import '../sandboxed_album_image.dart';

/// Renders an individual normalized photo slot inside `AlbumPageCanvas`.
///
/// Guards:
/// 1. **Gesture Disambiguation**: Uses `LongPressDraggable<int>` with
///    `hapticFeedbackOnStart: true` so single-finger swipes and taps are never
///    intercepted as photo drag gestures.
/// 2. **Memory Throttling**: When [isInteractive] is false (in mini-previews and
///    spread overview), strictly resolves `photo.relativeThumbnailPath` with
///    `cacheWidth: 240`.
class InteractivePhotoSlot extends StatefulWidget {
  final int slotIndex;
  final Rect pixelRect;
  final PhotoSlotAssignment? assignment;
  final AlbumPhoto? photo;
  final MediaSandboxService mediaService;
  final bool isInteractive;
  final bool isSelected;
  final VoidCallback? onSelect;
  final void Function(int fromSlot, int toSlot)? onSwapSlots;
  final ValueChanged<String>? onDropTrayPhoto;
  final void Function({
    double? panOffsetX,
    double? panOffsetY,
    double? zoomScale,
  })? onUpdatePanZoom;
  final VoidCallback? onEditAnnotation;
  final VoidCallback? onRemoveToTray;

  const InteractivePhotoSlot({
    super.key,
    required this.slotIndex,
    required this.pixelRect,
    required this.assignment,
    required this.photo,
    required this.mediaService,
    this.isInteractive = true,
    this.isSelected = false,
    this.onSelect,
    this.onSwapSlots,
    this.onDropTrayPhoto,
    this.onUpdatePanZoom,
    this.onEditAnnotation,
    this.onRemoveToTray,
  });

  @override
  State<InteractivePhotoSlot> createState() => _InteractivePhotoSlotState();
}

class _InteractivePhotoSlotState extends State<InteractivePhotoSlot> {
  bool _isPanCropActive = false;

  @override
  void didUpdateWidget(covariant InteractivePhotoSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && _isPanCropActive) {
      _isPanCropActive = false;
    }
  }

  void _handleZoomDelta(double delta) {
    final currentZoom = widget.assignment?.zoomScale ?? 1.0;
    final nextZoom = (currentZoom + delta).clamp(1.0, 4.0);
    widget.onUpdatePanZoom?.call(zoomScale: nextZoom);
  }

  void _handleCropPanUpdate(DragUpdateDetails details) {
    if (!_isPanCropActive || widget.assignment == null) return;
    final w = math.max(1.0, widget.pixelRect.width);
    final h = math.max(1.0, widget.pixelRect.height);
    final nextPanX =
        (widget.assignment!.panOffsetX + details.delta.dx / w).clamp(-0.5, 0.5);
    final nextPanY =
        (widget.assignment!.panOffsetY + details.delta.dy / h).clamp(-0.5, 0.5);
    widget.onUpdatePanZoom?.call(
      panOffsetX: nextPanX,
      panOffsetY: nextPanY,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final rect = widget.pixelRect;

    if (!widget.isInteractive) {
      return Positioned(
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: _buildSlotVisual(
          tokens: tokens,
          isHovering: false,
          isDragging: false,
          useThumbnail: true,
        ),
      );
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: DragTarget<Object>(
        key: Key('photo_slot_target_${widget.slotIndex}'),
        onWillAcceptWithDetails: (details) {
          final data = details.data;
          if (data is int) {
            return data != widget.slotIndex;
          }
          if (data is String) {
            return data.isNotEmpty;
          }
          return false;
        },
        onAcceptWithDetails: (details) {
          final data = details.data;
          if (data is int && data != widget.slotIndex) {
            widget.onSwapSlots?.call(data, widget.slotIndex);
          } else if (data is String) {
            widget.onDropTrayPhoto?.call(data);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final slotContent = GestureDetector(
            key: Key('interactive_photo_slot_${widget.slotIndex}'),
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSelect,
            onPanUpdate: _isPanCropActive ? _handleCropPanUpdate : null,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                _buildSlotVisual(
                  tokens: tokens,
                  isHovering: isHovering,
                  isDragging: false,
                  useThumbnail: false,
                ),
                if (widget.isSelected && widget.assignment != null)
                  _buildContextualToolbar(tokens),
              ],
            ),
          );

          if (widget.assignment == null || _isPanCropActive) {
            return slotContent;
          }

          return LongPressDraggable<int>(
            key: Key('photo_slot_draggable_${widget.slotIndex}'),
            data: widget.slotIndex,
            hapticFeedbackOnStart: true,
            feedback: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: rect.width * 0.92,
                height: rect.height * 0.92,
                child: _buildSlotVisual(
                  tokens: tokens,
                  isHovering: true,
                  isDragging: true,
                  useThumbnail: true,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: _buildSlotVisual(
                tokens: tokens,
                isHovering: false,
                isDragging: true,
                useThumbnail: true,
              ),
            ),
            child: slotContent,
          );
        },
      ),
    );
  }

  Widget _buildSlotVisual({
    required InkDiaryTokens tokens,
    required bool isHovering,
    required bool isDragging,
    required bool useThumbnail,
  }) {
    final photo = widget.photo;
    final assignment = widget.assignment;
    final borderColor = isHovering || widget.isSelected
        ? tokens.cinnabar
        : tokens.deckleBorder.withValues(alpha: 0.65);
    final borderWidth = isHovering || widget.isSelected ? 2.0 : 0.7;

    if (photo == null || assignment == null) {
      return Container(
        decoration: BoxDecoration(
          color: tokens.agedFiber.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Center(
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: math.min(24.0, widget.pixelRect.shortestSide * 0.35),
            color: tokens.qingmo,
          ),
        ),
      );
    }

    final resolvedPath = useThumbnail
        ? photo.relativeThumbnailPath
        : photo.relativeImagePath;
    final resolvedCacheWidth = useThumbnail ? 240 : 900;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.2),
        child: Transform.scale(
          scale: assignment.zoomScale.clamp(1.0, 4.0),
          child: FractionalTranslation(
            translation: Offset(assignment.panOffsetX, assignment.panOffsetY),
            child: SandboxedAlbumImage(
              relativePath: resolvedPath,
              mediaService: widget.mediaService,
              cacheWidth: resolvedCacheWidth,
              borderRadius: 0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextualToolbar(InkDiaryTokens tokens) {
    final index = widget.slotIndex;

    return Positioned(
      top: 6,
      left: 4,
      right: 4,
      child: Center(
        child: Material(
          key: Key('slot_context_menu_$index'),
          color: tokens.jiaomo.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SlotActionBtn(
                  buttonKey: Key('slot_crop_button_$index'),
                  icon: _isPanCropActive ? Icons.check : Icons.crop_rotate,
                  color:
                      _isPanCropActive ? const Color(0xFF81C784) : Colors.white,
                  tooltip: _isPanCropActive ? '完成移动裁切' : '裁切与缩放',
                  onTap: () {
                    setState(() {
                      _isPanCropActive = !_isPanCropActive;
                    });
                  },
                ),
                _SlotActionBtn(
                  buttonKey: Key('slot_zoom_in_$index'),
                  icon: Icons.zoom_in,
                  tooltip: '放大画面',
                  onTap: () => _handleZoomDelta(0.25),
                ),
                _SlotActionBtn(
                  buttonKey: Key('slot_zoom_out_$index'),
                  icon: Icons.zoom_out,
                  tooltip: '缩小画面',
                  onTap: () => _handleZoomDelta(-0.25),
                ),
                if (widget.onEditAnnotation != null)
                  _SlotActionBtn(
                    buttonKey: Key('slot_annotate_button_$index'),
                    icon: Icons.edit_note,
                    tooltip: '写影札',
                    onTap: widget.onEditAnnotation!,
                  ),
                if (widget.onRemoveToTray != null)
                  _SlotActionBtn(
                    buttonKey: Key('slot_remove_to_tray_$index'),
                    icon: Icons.remove_circle_outline,
                    color: const Color(0xFFFF8A80),
                    tooltip: '移至暂存栏',
                    onTap: widget.onRemoveToTray!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotActionBtn extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _SlotActionBtn({
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
