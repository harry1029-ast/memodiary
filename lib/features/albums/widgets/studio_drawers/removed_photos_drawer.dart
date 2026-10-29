import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/media_sandbox_service.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../constants/album_studio_strings.dart';
import '../sandboxed_album_image.dart';

/// Studio bottom drawer displaying unassigned photos and decorative elements
/// placed in the Collection Box (`removedPhotoIds`).
///
/// Features two view modes:
/// 1. Compact horizontal strip (~210px) keeping the canvas fully visible.
/// 2. Expanded vertical grid (~55% screen height) for easily browsing large batches.
///
/// Tapping or dragging any photo onto the page canvas places it on the active page
/// and automatically upgrades the layout from `N` to `N + 1` slots.
class RemovedPhotosDrawer extends StatefulWidget {
  final List<String> removedPhotoIds;
  final Map<String, AlbumPhoto> photoById;
  final MediaSandboxService mediaService;
  final ValueChanged<String> onRestorePhoto;
  final VoidCallback onClose;

  const RemovedPhotosDrawer({
    super.key,
    required this.removedPhotoIds,
    required this.photoById,
    required this.mediaService,
    required this.onRestorePhoto,
    required this.onClose,
  });

  @override
  State<RemovedPhotosDrawer> createState() => _RemovedPhotosDrawerState();
}

class _RemovedPhotosDrawerState extends State<RemovedPhotosDrawer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final screenHeight = MediaQuery.of(context).size.height;
    final targetHeight = _isExpanded
        ? math.min(screenHeight * 0.85, math.max(380.0, screenHeight * 0.55))
        : 210.0;

    return AnimatedContainer(
      key: const Key('studio_removed_photos_drawer'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: targetHeight,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        color: tokens.xuanPureLeaf,
        border: Border(
          top: BorderSide(color: tokens.deckleBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.jiaomo.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle bar to toggle compact / expanded view
          Center(
            child: Semantics(
              button: true,
              label: _isExpanded ? '收起收集箱为横栏' : '展开收集箱为多列网格',
              child: GestureDetector(
                key: const Key('collection_box_drag_handle'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -80 && !_isExpanded) {
                      setState(() => _isExpanded = true);
                    } else if (details.primaryVelocity! > 80 && _isExpanded) {
                      setState(() => _isExpanded = false);
                    }
                  }
                },
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.danmo.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Header Row
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: tokens.cinnabar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AlbumStudioStrings.collectionBoxTitle} (${widget.removedPhotoIds.length})',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.jiaomo,
                  ),
                ),
              ),
              // Expand / Collapse Grid Toggle
              IconButton(
                key: const Key('collection_box_toggle_expand_button'),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                  color: tokens.danmo,
                  size: 20,
                ),
                tooltip: _isExpanded ? '收起为横栏' : '展开多列网格',
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
              // Close Drawer
              IconButton(
                key: const Key('collection_box_close_button'),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: tokens.danmo, size: 20),
                tooltip: '收起面板',
                onPressed: widget.onClose,
              ),
            ],
          ),
          Text(
            AlbumStudioStrings.collectionBoxDrawerSub,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 11.5,
              color: tokens.danmo,
            ),
          ),
          const SizedBox(height: 10),

          // Content: Horizontal ListView vs Vertical Multi-Column GridView
          Expanded(
            child: widget.removedPhotoIds.isEmpty
                ? Center(
                    child: Text(
                      '收集箱为空，所有素材已排入画册中',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 13,
                        color: tokens.qingmo,
                      ),
                    ),
                  )
                : _isExpanded
                    ? GridView.builder(
                        key: const Key('collection_box_vertical_grid'),
                        padding: const EdgeInsets.only(bottom: 6),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: widget.removedPhotoIds.length,
                        itemBuilder: (context, index) {
                          final photoId = widget.removedPhotoIds[index];
                          final photo = widget.photoById[photoId];
                          return _buildTrayThumbnail(
                            tokens,
                            photoId,
                            photo,
                            isGrid: true,
                          );
                        },
                      )
                    : ListView.separated(
                        key: const Key('collection_box_horizontal_list'),
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.removedPhotoIds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final photoId = widget.removedPhotoIds[index];
                          final photo = widget.photoById[photoId];
                          return _buildTrayThumbnail(
                            tokens,
                            photoId,
                            photo,
                            isGrid: false,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrayThumbnail(
    InkDiaryTokens tokens,
    String photoId,
    AlbumPhoto? photo, {
    required bool isGrid,
  }) {
    final card = InkWell(
      key: Key('removed_tray_item_$photoId'),
      onTap: () => widget.onRestorePhoto(photoId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isGrid ? double.infinity : 96,
        decoration: BoxDecoration(
          color: tokens.agedFiber,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.deckleBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SandboxedAlbumImage(
                relativePath: photo?.relativeThumbnailPath,
                mediaService: widget.mediaService,
                cacheWidth: 240,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.jiaomo.withValues(alpha: 0.76),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(7),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      AlbumStudioStrings.collectionBoxBadge,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 10.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return LongPressDraggable<String>(
      data: photoId,
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: SizedBox(
          width: 84,
          height: 84,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SandboxedAlbumImage(
              relativePath: photo?.relativeThumbnailPath,
              mediaService: widget.mediaService,
              cacheWidth: 240,
              borderRadius: 8,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      child: card,
    );
  }
}
