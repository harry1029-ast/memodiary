import 'package:flutter/material.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../editor/domain/sheet_media_item.dart';
import '../../../editor/widgets/fullscreen_media_lightbox.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import 'folio_leaf_model.dart';
import 'folio_polaroid_mini_card.dart';
import 'folio_reading_perspective.dart';

/// Overlay manager rendering smart-anchored, draggable Polaroid keepsakes
/// above the 14-row calligraphy substrate in the Thread-Bound Folio.
class FolioEphemeraOverlayLayer extends StatefulWidget {
  final List<FolioPhotoAttachment> photos;
  final FolioRulingLayout layout;
  final MediaSandboxService? mediaService;
  final ShanshuiRealm atmosphereRealm;
  final bool isHidden;
  final VoidCallback? onHide;
  final void Function(String photoId, double? xRatio, double? yRatio)? onPositionChanged;
  final double leafWidth;
  final double leafHeight;

  const FolioEphemeraOverlayLayer({
    super.key,
    required this.photos,
    required this.layout,
    this.mediaService,
    this.atmosphereRealm = ShanshuiRealm.nature,
    this.isHidden = false,
    this.onHide,
    this.onPositionChanged,
    this.leafWidth = 320.0,
    this.leafHeight = 448.0,
  });

  @override
  State<FolioEphemeraOverlayLayer> createState() => _FolioEphemeraOverlayLayerState();
}

class _FolioEphemeraOverlayLayerState extends State<FolioEphemeraOverlayLayer>
    with SingleTickerProviderStateMixin {
  Offset? _dragOffset;
  bool _hasCustomDrag = false;
  late AnimationController _springController;
  Animation<Offset>? _springAnimation;

  double get _maxDx => (widget.leafWidth - FolioPolaroidMiniCard.cardWidth).clamp(0.0, widget.leafWidth);
  double get _maxDy => (widget.leafHeight - FolioPolaroidMiniCard.cardHeight).clamp(0.0, widget.leafHeight);

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  Offset _computeDefaultOffset() {
    // Top-Left for vertical Right-to-Left scripts; Bottom-Left for horizontal scripts
    if (widget.layout.isVertical) {
      return const Offset(8.0, 8.0);
    } else {
      return Offset(8.0, (_maxDy - 10.0).clamp(0.0, _maxDy));
    }
  }

  Offset _resolveCurrentOffset() {
    if (_dragOffset != null) return _dragOffset!;

    final primary = widget.photos.firstOrNull;
    if (primary != null && primary.overlayXRatio != null && primary.overlayYRatio != null) {
      final dx = (primary.overlayXRatio! * _maxDx).clamp(0.0, _maxDx);
      final dy = (primary.overlayYRatio! * _maxDy).clamp(0.0, _maxDy);
      return Offset(dx, dy);
    }

    return _computeDefaultOffset();
  }

  bool _isCustomPositioned() {
    if (_hasCustomDrag) return true;
    final primary = widget.photos.firstOrNull;
    return primary != null && primary.overlayXRatio != null && primary.overlayYRatio != null;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    final current = _resolveCurrentOffset();
    final nextDx = (current.dx + details.delta.dx).clamp(0.0, _maxDx);
    final nextDy = (current.dy + details.delta.dy).clamp(0.0, _maxDy);
    setState(() {
      _dragOffset = Offset(nextDx, nextDy);
      _hasCustomDrag = true;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_dragOffset == null) return;
    final xRatio = (_dragOffset!.dx / _maxDx).clamp(0.0, 1.0);
    final yRatio = (_dragOffset!.dy / _maxDy).clamp(0.0, 1.0);

    for (final photo in widget.photos) {
      widget.onPositionChanged?.call(photo.id, xRatio, yRatio);
    }
  }

  void _handleReset() {
    final current = _resolveCurrentOffset();
    final target = _computeDefaultOffset();

    _springAnimation = Tween<Offset>(
      begin: current,
      end: target,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    ));

    void listener() {
      if (_springAnimation != null) {
        setState(() {
          _dragOffset = _springAnimation!.value;
        });
      }
    }

    _springAnimation!.addListener(listener);

    _springController.forward(from: 0.0).whenComplete(() {
      _springAnimation?.removeListener(listener);
      setState(() {
        _dragOffset = null;
        _hasCustomDrag = false;
      });

      for (final photo in widget.photos) {
        widget.onPositionChanged?.call(photo.id, null, null);
      }
    });
  }

  void _openLightbox() {
    if (widget.photos.isEmpty) return;
    final mediaService = widget.mediaService;
    if (mediaService == null) return;

    final mediaItems = widget.photos.map((photo) {
      return SheetMediaItem(
        id: photo.id,
        relativePath: photo.relativePath,
        mediaType: photo.mediaType,
        caption: photo.caption,
      );
    }).toList();

    FullscreenMediaLightbox.show(
      context,
      items: mediaItems,
      initialIndex: 0,
      mediaSandboxService: mediaService,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentOffset = _resolveCurrentOffset();

    return Positioned(
      left: currentOffset.dx,
      top: currentOffset.dy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: widget.isHidden
            ? const SizedBox.shrink()
            : FolioPolaroidMiniCard(
                key: const ValueKey('active_polaroid_card'),
                photos: widget.photos,
                mediaService: widget.mediaService,
                atmosphereRealm: widget.atmosphereRealm,
                hasCustomPosition: _isCustomPositioned(),
                onTap: _openLightbox,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                onReset: _handleReset,
                onHide: widget.onHide,
              ),
      ),
    );
  }
}
