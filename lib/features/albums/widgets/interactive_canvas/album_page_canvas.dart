import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/album_studio_models.dart';
import '../../services/page_layout_catalog.dart';
import '../page_background_painter.dart';
import 'draggable_overlay_item.dart';
import 'interactive_photo_slot.dart';

/// Shared WYSIWYG scrapbook page canvas renderer.
///
/// Used both as a non-interactive thumbnail preview in `BookSpreadTile` and
/// `LayoutPickerDrawer` (`isInteractive: false`, throttled to `cacheWidth: 240`
/// `_thumb.webp` files) and as the full interactive editor stage in
/// `AlbumPageEditorScreen` (`isInteractive: true`).
class AlbumPageCanvas extends StatefulWidget {
  final AlbumPageModel page;
  final Map<String, AlbumPhoto> photoById;
  final MediaSandboxService mediaService;
  final String? overrideLayoutTemplateId;
  final bool isInteractive;
  final void Function(int firstSlot, int secondSlot)? onSwapSlots;
  final ValueChanged<String>? onDropTrayPhoto;
  final void Function(
    int slotIndex, {
    double? panOffsetX,
    double? panOffsetY,
    double? zoomScale,
  })? onUpdatePanZoom;
  final ValueChanged<AlbumPhoto>? onEditPhotoAnnotation;
  final ValueChanged<int>? onRemovePhotoToTray;
  final ValueChanged<PageOverlayElement>? onUpdateOverlay;
  final ValueChanged<String>? onDeleteOverlay;
  final VoidCallback? onTapDateHeader;

  const AlbumPageCanvas({
    super.key,
    required this.page,
    required this.photoById,
    required this.mediaService,
    this.overrideLayoutTemplateId,
    this.isInteractive = false,
    this.onSwapSlots,
    this.onDropTrayPhoto,
    this.onUpdatePanZoom,
    this.onEditPhotoAnnotation,
    this.onRemovePhotoToTray,
    this.onUpdateOverlay,
    this.onDeleteOverlay,
    this.onTapDateHeader,
  });

  @override
  State<AlbumPageCanvas> createState() => _AlbumPageCanvasState();
}

class _AlbumPageCanvasState extends State<AlbumPageCanvas> {
  int? _selectedSlotIndex;
  String? _selectedOverlayId;

  @override
  void didUpdateWidget(covariant AlbumPageCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      _selectedSlotIndex = null;
      _selectedOverlayId = null;
    } else if (_selectedSlotIndex != null &&
        _selectedSlotIndex! >= widget.page.photoSlots.length) {
      _selectedSlotIndex = null;
    }
  }

  void _clearSelection() {
    if (_selectedSlotIndex != null || _selectedOverlayId != null) {
      setState(() {
        _selectedSlotIndex = null;
        _selectedOverlayId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final templateId =
        widget.overrideLayoutTemplateId ?? widget.page.layoutTemplateId;
    final template = PageLayoutCatalog.getById(templateId);
    final textColor = Color(widget.page.backgroundConfig.textColorArgb);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : width;
        final canvasSize = Size(width, height);

        final sortedOverlays = List<PageOverlayElement>.from(
          widget.page.overlays,
        )..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        final canvasStack = Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Procedural Background & Vector Motifs
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CustomPaint(
                  key: Key('page_bg_paint_${widget.page.id}'),
                  painter: PageBackgroundPainter(
                    config: widget.page.backgroundConfig,
                  ),
                ),
              ),
            ),

            // 2. Tap background to deselect active slot/overlay
            if (widget.isInteractive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _clearSelection,
                ),
              ),

            // 3. Optional Date Header Slot
            if (template.dateHeaderSlot != null)
              _buildDateHeaderSlot(
                headerNormRect: template.dateHeaderSlot!,
                canvasSize: canvasSize,
                textColor: textColor,
                tokens: tokens,
              ),

            // 4. Normalized Photo Slots
            for (var i = 0; i < template.slots.length; i++)
              _buildSlot(
                slotIndex: i,
                normRect: template.slots[i],
                canvasSize: canvasSize,
              ),

            // 5. Draggable Overlays (Stickers, Date Pills, Text, Seals)
            for (final overlay in sortedOverlays)
              DraggableOverlayItem(
                key: ValueKey('overlay_${overlay.id}'),
                overlay: overlay,
                canvasSize: canvasSize,
                defaultTextColorArgb:
                    widget.page.backgroundConfig.textColorArgb,
                isInteractive: widget.isInteractive,
                isSelected: _selectedOverlayId == overlay.id,
                onSelect: () {
                  setState(() {
                    _selectedOverlayId = overlay.id;
                    _selectedSlotIndex = null;
                  });
                },
                onUpdate: widget.onUpdateOverlay,
                onDelete: widget.onDeleteOverlay != null
                    ? () {
                        setState(() {
                          _selectedOverlayId = null;
                        });
                        widget.onDeleteOverlay!(overlay.id);
                      }
                    : null,
              ),
          ],
        );

        if (!widget.isInteractive) {
          return canvasStack;
        }

        // Allow dropping a photo from the Removed tray onto the general page canvas
        return DragTarget<String>(
          key: Key('page_canvas_tray_drop_${widget.page.id}'),
          onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
          onAcceptWithDetails: (details) {
            widget.onDropTrayPhoto?.call(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            return canvasStack;
          },
        );
      },
    );
  }

  Widget _buildDateHeaderSlot({
    required Rect headerNormRect,
    required Size canvasSize,
    required Color textColor,
    required InkDiaryTokens tokens,
  }) {
    final text = widget.page.dateHeaderText?.trim();
    if ((text == null || text.isEmpty) && !widget.isInteractive) {
      return const SizedBox.shrink();
    }

    final left = headerNormRect.left * canvasSize.width;
    final top = headerNormRect.top * canvasSize.height;
    final width = headerNormRect.width * canvasSize.width;
    final height = headerNormRect.height * canvasSize.height;
    final fontSize = math.max(8.0, canvasSize.shortestSide * 0.036);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: widget.isInteractive ? widget.onTapDateHeader : null,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            (text != null && text.isNotEmpty) ? text : '点击编辑日期标题',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: (text != null && text.isNotEmpty)
                  ? textColor
                  : textColor.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlot({
    required int slotIndex,
    required Rect normRect,
    required Size canvasSize,
  }) {
    final pixelRect = Rect.fromLTWH(
      normRect.left * canvasSize.width,
      normRect.top * canvasSize.height,
      normRect.width * canvasSize.width,
      normRect.height * canvasSize.height,
    );

    final assignment = slotIndex < widget.page.photoSlots.length
        ? widget.page.photoSlots[slotIndex]
        : null;
    final photo =
        assignment != null ? widget.photoById[assignment.photoId] : null;

    return InteractivePhotoSlot(
      key: ValueKey('page_${widget.page.id}_slot_$slotIndex'),
      slotIndex: slotIndex,
      pixelRect: pixelRect,
      assignment: assignment,
      photo: photo,
      mediaService: widget.mediaService,
      isInteractive: widget.isInteractive,
      isSelected: _selectedSlotIndex == slotIndex,
      onSelect: () {
        setState(() {
          _selectedSlotIndex =
              (_selectedSlotIndex == slotIndex) ? null : slotIndex;
          _selectedOverlayId = null;
        });
      },
      onSwapSlots: (fromSlot, toSlot) {
        setState(() {
          _selectedSlotIndex = null;
        });
        widget.onSwapSlots?.call(fromSlot, toSlot);
      },
      onDropTrayPhoto: (photoId) {
        setState(() {
          _selectedSlotIndex = null;
        });
        widget.onDropTrayPhoto?.call(photoId);
      },
      onUpdatePanZoom: widget.onUpdatePanZoom != null
          ? ({panOffsetX, panOffsetY, zoomScale}) {
              widget.onUpdatePanZoom!(
                slotIndex,
                panOffsetX: panOffsetX,
                panOffsetY: panOffsetY,
                zoomScale: zoomScale,
              );
            }
          : null,
      onEditAnnotation: (photo != null && widget.onEditPhotoAnnotation != null)
          ? () => widget.onEditPhotoAnnotation!(photo)
          : null,
      onRemoveToTray: widget.onRemovePhotoToTray != null
          ? () {
              setState(() {
                _selectedSlotIndex = null;
              });
              widget.onRemovePhotoToTray!(slotIndex);
            }
          : null,
    );
  }
}

